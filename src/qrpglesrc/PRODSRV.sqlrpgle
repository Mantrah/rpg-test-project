**free
// ============================================================
// PRODSRV - Product Service Module
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Read-only operations for Product and Guarantee catalog.
// Products match DAS.be offerings (Classic, Connect, Comfort, etc.)
// ============================================================

ctl-opt nomain option(*srcstmt:*nodebugio);

// SQL Options - COMMIT(*NONE) required for PUB400 (no journaling)
exec sql SET OPTION COMMIT = *NONE, CLOSQLCSR = *ENDMOD;

/copy MRS1/QRPGLESRC,PRODSRV_H
/copy MRS1/QRPGLESRC,ERRUTIL_H

//==============================================================
// GetProduct : Retrieve product by ID
//
//  Returns: Product DS (empty on error)
//
//==============================================================
dcl-proc PRODSRV_GetProduct export;
    dcl-pi *n likeds(Product_t);
        pProductId packed(10:0) const;
    end-pi;

    dcl-ds product likeds(Product_t) inz;

    monitor;
        // Business logic
        exec sql
            SELECT PRODUCT_ID, PRODUCT_CODE, PRODUCT_NAME, PRODUCT_TYPE,
                   BASE_PREMIUM, COVERAGE_LIMIT, MIN_THRESHOLD, TAX_BENEFIT,
                   WAITING_MONTHS, STATUS, CREATED_AT, UPDATED_AT
            INTO :product
            FROM PRODUCT
            WHERE PRODUCT_ID = :pProductId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            clear product;
            if sqlcode = 100;
                ERRUTIL_addErrorCode('DB001');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        clear product;
        ERRUTIL_addExecutionError();
    endmon;

    return product;
end-proc;

//==============================================================
// GetProductByCode : Retrieve product by code
//
//  Returns: Product DS (empty on error)
//
//==============================================================
dcl-proc PRODSRV_GetProductByCode export;
    dcl-pi *n likeds(Product_t);
        pProductCode char(10) const;
    end-pi;

    dcl-ds product likeds(Product_t) inz;

    monitor;
        // Business logic
        exec sql
            SELECT PRODUCT_ID, PRODUCT_CODE, PRODUCT_NAME, PRODUCT_TYPE,
                   BASE_PREMIUM, COVERAGE_LIMIT, MIN_THRESHOLD, TAX_BENEFIT,
                   WAITING_MONTHS, STATUS, CREATED_AT, UPDATED_AT
            INTO :product
            FROM PRODUCT
            WHERE PRODUCT_CODE = :pProductCode;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            clear product;
            if sqlcode = 100;
                ERRUTIL_addErrorCode('DB001');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        clear product;
        ERRUTIL_addExecutionError();
    endmon;

    return product;
end-proc;

//==============================================================
// ListProducts : List active products
//
//  Returns: Result count
//
//==============================================================
dcl-proc PRODSRV_ListProducts export;
    dcl-pi *n int(10);
        pProductType char(3) const options(*nopass);
    end-pi;

    dcl-s resultCount int(10) inz(0);
    dcl-s productType char(3);

    // Initialization
    if %parms >= 1;
        productType = pProductType;
    else;
        productType = '';
    endif;

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM PRODUCT
            WHERE STATUS = 'ACT'
              AND (:productType = '' OR PRODUCT_TYPE = :productType);

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// GetProductGuarantees : Get coverage types for product
//
//  Returns: Result count
//
//==============================================================
dcl-proc PRODSRV_GetProductGuarantees export;
    dcl-pi *n int(10);
        pProductId packed(10:0) const;
    end-pi;

    dcl-s resultCount int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM GUARANTEE
            WHERE PRODUCT_ID = :pProductId
              AND STATUS = 'ACT';

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// CalculateBasePremium : Calculate premium based on vehicles
//
//  Returns: Premium amount
//
//==============================================================
dcl-proc PRODSRV_CalculateBasePremium export;
    dcl-pi *n packed(9:2);
        pProductCode char(10) const;
        pVehiclesCount packed(2:0) const;
    end-pi;

    dcl-s basePremium packed(9:2) inz(0);
    dcl-s vehicleAddon packed(9:2) inz(0);
    dcl-c VEHICLE_ADDON 25.00;  // €25 per additional vehicle

    monitor;
        // Business logic - Get base premium
        exec sql
            SELECT BASE_PREMIUM INTO :basePremium
            FROM MRS1.PRODUCT
            WHERE PRODUCT_CODE = :pProductCode
              AND STATUS = 'ACT';

        // SQLCODE 8013 = PUB400 licensing - ignore and continue
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            // Add vehicle surcharge
            if pVehiclesCount > 0;
                vehicleAddon = pVehiclesCount * VEHICLE_ADDON;
                basePremium = basePremium + vehicleAddon;
            endif;
        else;
            ERRUTIL_addErrorCode('BUS010');
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return basePremium;
end-proc;

//==============================================================
// IsProductAvailable : Check if product is available
//
//  Returns: Available indicator
//
//==============================================================
dcl-proc PRODSRV_IsProductAvailable export;
    dcl-pi *n ind;
        pProductCode char(10) const;
    end-pi;

    dcl-s count int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :count
            FROM PRODUCT
            WHERE PRODUCT_CODE = :pProductCode
              AND STATUS = 'ACT';

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return (count > 0);
end-proc;

//==============================================================
// HasGuarantee : Check if product includes guarantee
//
//  Returns: Has guarantee indicator
//
//==============================================================
dcl-proc PRODSRV_HasGuarantee export;
    dcl-pi *n ind;
        pProductId packed(10:0) const;
        pGuaranteeCode char(10) const;
    end-pi;

    dcl-s count int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :count
            FROM GUARANTEE
            WHERE PRODUCT_ID = :pProductId
              AND GUARANTEE_CODE = :pGuaranteeCode
              AND STATUS = 'ACT';

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return (count > 0);
end-proc;

//==============================================================
// GetGuaranteeWaitingPeriod : Get waiting period for guarantee
//
//  Returns: Waiting period in months
//
//==============================================================
dcl-proc PRODSRV_GetGuaranteeWaitingPeriod export;
    dcl-pi *n packed(2:0);
        pProductId packed(10:0) const;
        pGuaranteeCode char(10) const;
    end-pi;

    dcl-s waitingMonths packed(2:0) inz(0);
    dcl-s productWaiting packed(2:0) inz(0);

    monitor;
        // Business logic - Get guarantee-specific waiting period
        exec sql
            SELECT COALESCE(G.WAITING_MONTHS, P.WAITING_MONTHS)
            INTO :waitingMonths
            FROM GUARANTEE G
            JOIN PRODUCT P ON G.PRODUCT_ID = P.PRODUCT_ID
            WHERE G.PRODUCT_ID = :pProductId
              AND G.GUARANTEE_CODE = :pGuaranteeCode;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            waitingMonths = 3;  // Default 3 months
        endif;

    on-error;
        ERRUTIL_addExecutionError();
        waitingMonths = 3;
    endmon;

    return waitingMonths;
end-proc;

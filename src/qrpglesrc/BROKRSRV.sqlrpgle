**free
// ============================================================
// BROKRSRV - Broker Service Module
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// CRUD operations for Broker (insurance brokers).
// Brokers are the exclusive sales channel for DAS.
// TELEBIB2 alignment: AgencyCode, Address segments (X002-X008)
// ============================================================

ctl-opt nomain option(*srcstmt:*nodebugio);

/copy qrpglesrc/BROKRSRV_H

//==============================================================
// CreateBroker : Insert new broker
//
//  Returns: Broker ID (0 on error)
//
//==============================================================
dcl-proc BROKRSRV_CreateBroker export;
    dcl-pi *n packed(10:0);
        pBroker likeds(Broker_t) const;
    end-pi;

    dcl-s newBrokerId packed(10:0) inz(0);

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not IsValidBroker(pBroker);
            return 0;
        endif;

        // Business logic
        exec sql
            INSERT INTO BROKER (
                BROKER_CODE, COMPANY_NAME, VAT_NUMBER, FSMA_NUMBER,
                STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY,
                COUNTRY_CODE, PHONE, EMAIL, CONTACT_NAME, STATUS
            ) VALUES (
                :pBroker.brokerCode, :pBroker.companyName, :pBroker.vatNumber,
                :pBroker.fsmaNumber, :pBroker.street, :pBroker.houseNbr,
                :pBroker.boxNbr, :pBroker.postalCode, :pBroker.city,
                :pBroker.countryCode, :pBroker.phone, :pBroker.email,
                :pBroker.contactName, 'ACT'
            );

        if sqlcode = 0;
            exec sql
                SELECT IDENTITY_VAL_LOCAL() INTO :newBrokerId FROM SYSIBM.SYSDUMMY1;
        else;
            if sqlcode = -803;
                ERRUTIL_addErrorCode('DB002');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return newBrokerId;
end-proc;

//==============================================================
// GetBroker : Retrieve broker by ID
//
//  Returns: Broker DS (empty on error)
//
//==============================================================
dcl-proc BROKRSRV_GetBroker export;
    dcl-pi *n likeds(Broker_t);
        pBrokerId packed(10:0) const;
    end-pi;

    dcl-ds broker likeds(Broker_t) inz;

    monitor;
        // Business logic
        exec sql
            SELECT BROKER_ID, BROKER_CODE, COMPANY_NAME, VAT_NUMBER,
                   FSMA_NUMBER, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
                   CITY, COUNTRY_CODE, PHONE, EMAIL, CONTACT_NAME,
                   STATUS, CREATED_AT, UPDATED_AT
            INTO :broker
            FROM BROKER
            WHERE BROKER_ID = :pBrokerId;

        if sqlcode <> 0;
            clear broker;
            if sqlcode = 100;
                ERRUTIL_addErrorCode('DB001');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        clear broker;
        ERRUTIL_addExecutionError();
    endmon;

    return broker;
end-proc;

//==============================================================
// GetBrokerByCode : Retrieve broker by code
//
//  Returns: Broker DS (empty on error)
//
//==============================================================
dcl-proc BROKRSRV_GetBrokerByCode export;
    dcl-pi *n likeds(Broker_t);
        pBrokerCode char(10) const;
    end-pi;

    dcl-ds broker likeds(Broker_t) inz;

    monitor;
        // Business logic
        exec sql
            SELECT BROKER_ID, BROKER_CODE, COMPANY_NAME, VAT_NUMBER,
                   FSMA_NUMBER, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
                   CITY, COUNTRY_CODE, PHONE, EMAIL, CONTACT_NAME,
                   STATUS, CREATED_AT, UPDATED_AT
            INTO :broker
            FROM BROKER
            WHERE BROKER_CODE = :pBrokerCode;

        if sqlcode <> 0;
            clear broker;
            if sqlcode = 100;
                ERRUTIL_addErrorCode('DB001');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        clear broker;
        ERRUTIL_addExecutionError();
    endmon;

    return broker;
end-proc;

//==============================================================
// UpdateBroker : Update existing broker
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc BROKRSRV_UpdateBroker export;
    dcl-pi *n ind;
        pBroker likeds(Broker_t) const;
    end-pi;

    dcl-s success ind inz(*off);

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not IsValidBroker(pBroker);
            return *off;
        endif;

        // Business logic
        exec sql
            UPDATE BROKER SET
                BROKER_CODE = :pBroker.brokerCode,
                COMPANY_NAME = :pBroker.companyName,
                VAT_NUMBER = :pBroker.vatNumber,
                FSMA_NUMBER = :pBroker.fsmaNumber,
                STREET = :pBroker.street,
                HOUSE_NBR = :pBroker.houseNbr,
                BOX_NBR = :pBroker.boxNbr,
                POSTAL_CODE = :pBroker.postalCode,
                CITY = :pBroker.city,
                COUNTRY_CODE = :pBroker.countryCode,
                PHONE = :pBroker.phone,
                EMAIL = :pBroker.email,
                CONTACT_NAME = :pBroker.contactName,
                STATUS = :pBroker.status,
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE BROKER_ID = :pBroker.brokerId;

        success = (sqlcode = 0);
        if not success;
            ERRUTIL_addErrorCode('DB004');
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return success;
end-proc;

//==============================================================
// DeleteBroker : Soft delete (set inactive)
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc BROKRSRV_DeleteBroker export;
    dcl-pi *n ind;
        pBrokerId packed(10:0) const;
    end-pi;

    dcl-s success ind inz(*off);

    monitor;
        // Business logic - soft delete
        exec sql
            UPDATE BROKER SET
                STATUS = 'INA',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE BROKER_ID = :pBrokerId;

        success = (sqlcode = 0);
        if not success;
            ERRUTIL_addErrorCode('DB004');
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return success;
end-proc;

//==============================================================
// ListBrokers : Search with filters
//
//  Returns: Result count
//
//==============================================================
dcl-proc BROKRSRV_ListBrokers export;
    dcl-pi *n int(10);
        pFilter likeds(BrokerFilter_t) const;
    end-pi;

    dcl-s resultCount int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM BROKER
            WHERE (:pFilter.brokerCode = '' OR BROKER_CODE = :pFilter.brokerCode)
              AND (:pFilter.companyName = '' OR COMPANY_NAME LIKE :pFilter.companyName || '%')
              AND (:pFilter.city = '' OR CITY = :pFilter.city)
              AND (:pFilter.status = '' OR STATUS = :pFilter.status);

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// IsValidBroker : Validate broker data
//
//  Returns: Validation indicator
//
//==============================================================
dcl-proc BROKRSRV_IsValidBroker export;
    dcl-pi *n ind;
        pBroker likeds(Broker_t) const;
    end-pi;

    // Validation - Required fields
    if pBroker.brokerCode = '';
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    if pBroker.companyName = '';
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    // Validation - FSMA number
    if pBroker.fsmaNumber <> '' and not IsValidFsmaNumber(pBroker.fsmaNumber);
        return *off;
    endif;

    return *on;
end-proc;

//==============================================================
// IsValidFsmaNumber : Validate FSMA registration number
//
//  Returns: Valid indicator
//
//==============================================================
dcl-proc BROKRSRV_IsValidFsmaNumber export;
    dcl-pi *n ind;
        pFsmaNumber char(10) const;
    end-pi;

    dcl-s fsma char(10);

    fsma = %trim(pFsmaNumber);

    // Validation - FSMA number must not be empty if provided
    if %len(fsma) = 0;
        return *on;  // Empty is valid (optional field)
    endif;

    // Basic validation - should have some length
    if %len(fsma) < 5;
        ERRUTIL_addErrorCode('VAL005');
        return *off;
    endif;

    return *on;
end-proc;

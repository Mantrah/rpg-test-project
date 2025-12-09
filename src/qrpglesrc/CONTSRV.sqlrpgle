**free
// ============================================================
// CONTSRV - Contract Service Module
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// CRUD operations for Contract (insurance policies).
// Business rules:
// - 1 year duration, auto-renewal
// - Cancellation: 2 months before expiration
// TELEBIB2 alignment: BrokerPolicyReference
// ============================================================

ctl-opt nomain option(*srcstmt:*nodebugio);

// SQL Options - COMMIT(*NONE) required for PUB400 (no journaling)
exec sql SET OPTION COMMIT = *NONE, CLOSQLCSR = *ENDMOD;

/copy MRS1/QRPGLESRC,CONTSRV_H
/copy MRS1/QRPGLESRC,ERRUTIL_H
/copy MRS1/QRPGLESRC,PRODSRV_H

//==============================================================
// CreateContract : Insert new contract
//
//  Returns: Contract ID (0 on error)
//
//==============================================================
dcl-proc CONTSRV_CreateContract export;
    dcl-pi *n packed(10:0);
        pContract likeds(Contract_t) const;
    end-pi;

    dcl-s newContId packed(10:0) inz(0);
    dcl-ds contract likeds(Contract_t);

    // Initialization
    ERRUTIL_init();
    contract = pContract;

    monitor;
        // Validation
        if not CONTSRV_IsValidContract(contract);
            return 0;
        endif;

        // Generate reference if not provided
        if contract.contReference = '';
            contract.contReference = CONTSRV_GenerateContractRef(contract.brokerId);
        endif;

        // Set default end date (1 year) if not provided
        if contract.endDate = *loval;
            contract.endDate = contract.startDate + %years(1);
        endif;

        // Business logic
        exec sql
            INSERT INTO CONTRACT (
                CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
                START_DATE, END_DATE, PREMIUM_AMT, PAY_FREQUENCY,
                VEHICLES_COUNT, AUTO_RENEW, STATUS
            ) VALUES (
                :contract.contReference, :contract.brokerId, :contract.custId,
                :contract.productId, :contract.startDate, :contract.endDate,
                :contract.premiumAmt, :contract.payFrequency,
                :contract.vehiclesCount, :contract.autoRenew, 'ACT'
            );

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            exec sql
                SELECT IDENTITY_VAL_LOCAL() INTO :newContId FROM SYSIBM.SYSDUMMY1;
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

    return newContId;
end-proc;

//==============================================================
// GetContract : Retrieve contract by ID
//
//  Returns: Contract DS (empty on error)
//
//==============================================================
dcl-proc CONTSRV_GetContract export;
    dcl-pi *n likeds(Contract_t);
        pContId packed(10:0) const;
    end-pi;

    dcl-ds contract likeds(Contract_t) inz;

    monitor;
        // Business logic
        exec sql
            SELECT CONT_ID, CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
                   START_DATE, END_DATE, PREMIUM_AMT, PAY_FREQUENCY,
                   VEHICLES_COUNT, AUTO_RENEW, STATUS, CREATED_AT, UPDATED_AT
            INTO :contract
            FROM CONTRACT
            WHERE CONT_ID = :pContId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            clear contract;
            if sqlcode = 100;
                ERRUTIL_addErrorCode('DB001');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        clear contract;
        ERRUTIL_addExecutionError();
    endmon;

    return contract;
end-proc;

//==============================================================
// GetContractByRef : Retrieve contract by reference
//
//  Returns: Contract DS (empty on error)
//
//==============================================================
dcl-proc CONTSRV_GetContractByRef export;
    dcl-pi *n likeds(Contract_t);
        pContReference char(20) const;
    end-pi;

    dcl-ds contract likeds(Contract_t) inz;

    monitor;
        // Business logic
        exec sql
            SELECT CONT_ID, CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
                   START_DATE, END_DATE, PREMIUM_AMT, PAY_FREQUENCY,
                   VEHICLES_COUNT, AUTO_RENEW, STATUS, CREATED_AT, UPDATED_AT
            INTO :contract
            FROM CONTRACT
            WHERE CONT_REFERENCE = :pContReference;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            clear contract;
        endif;

    on-error;
        clear contract;
        ERRUTIL_addExecutionError();
    endmon;

    return contract;
end-proc;

//==============================================================
// UpdateContract : Update existing contract
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc CONTSRV_UpdateContract export;
    dcl-pi *n ind;
        pContract likeds(Contract_t) const;
    end-pi;

    dcl-s success ind inz(*off);

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not CONTSRV_IsValidContract(pContract);
            return *off;
        endif;

        // Business logic
        exec sql
            UPDATE CONTRACT SET
                CONT_REFERENCE = :pContract.contReference,
                BROKER_ID = :pContract.brokerId,
                CUST_ID = :pContract.custId,
                PRODUCT_ID = :pContract.productId,
                START_DATE = :pContract.startDate,
                END_DATE = :pContract.endDate,
                PREMIUM_AMT = :pContract.premiumAmt,
                PAY_FREQUENCY = :pContract.payFrequency,
                VEHICLES_COUNT = :pContract.vehiclesCount,
                AUTO_RENEW = :pContract.autoRenew,
                STATUS = :pContract.status,
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CONT_ID = :pContract.contId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        success = (sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013);
        if not success;
            ERRUTIL_addErrorCode('DB004');
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return success;
end-proc;

//==============================================================
// CancelContract : Cancel contract
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc CONTSRV_CancelContract export;
    dcl-pi *n ind;
        pContId packed(10:0) const;
    end-pi;

    dcl-s success ind inz(*off);

    monitor;
        // Business logic
        exec sql
            UPDATE CONTRACT SET
                STATUS = 'CAN',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CONT_ID = :pContId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        success = (sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013);
        if not success;
            ERRUTIL_addErrorCode('DB004');
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return success;
end-proc;

//==============================================================
// ListContracts : Search with filters
//
//  Returns: Result count
//
//==============================================================
dcl-proc CONTSRV_ListContracts export;
    dcl-pi *n int(10);
        pFilter likeds(ContractFilter_t) const;
    end-pi;

    dcl-s resultCount int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM CONTRACT
            WHERE (:pFilter.brokerId = 0 OR BROKER_ID = :pFilter.brokerId)
              AND (:pFilter.custId = 0 OR CUST_ID = :pFilter.custId)
              AND (:pFilter.productId = 0 OR PRODUCT_ID = :pFilter.productId)
              AND (:pFilter.status = '' OR STATUS = :pFilter.status);

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// ListContractsJson : List contracts and return JSON array
//
//  Returns: Result count
//
//==============================================================
dcl-proc CONTSRV_ListContractsJson export;
    dcl-pi *n int(10);
        pStatusFilter   char(3) const;
        pJsonData       varchar(32000);
    end-pi;

    dcl-s jsonRow varchar(500);
    dcl-s contId packed(10:0);
    dcl-s contReference char(20);
    dcl-s custId packed(10:0);
    dcl-s brokerId packed(10:0);
    dcl-s productId packed(10:0);
    dcl-s startDate date;
    dcl-s endDate date;
    dcl-s vehiclesCount packed(2:0);
    dcl-s payFrequency char(1);
    dcl-s premiumAmt packed(9:2);
    dcl-s autoRenew char(1);
    dcl-s contStatus char(3);
    dcl-s resultCount int(10) inz(0);
    dcl-s firstRow ind inz(*on);
    dcl-s statusFilter char(3);
    dcl-s startDateStr char(10);
    dcl-s endDateStr char(10);

    exec sql
        DECLARE C_LISTCONTRACTS CURSOR FOR
        SELECT CONT_ID, CONT_REFERENCE, CUST_ID, BROKER_ID,
               PRODUCT_ID, START_DATE, END_DATE, VEHICLES_COUNT,
               PAY_FREQUENCY, PREMIUM_AMT, AUTO_RENEW, STATUS
        FROM MRS1.CONTRACT
        WHERE :statusFilter = '' OR STATUS = :statusFilter
        ORDER BY START_DATE DESC;

    monitor;
        statusFilter = %trim(pStatusFilter);
        pJsonData = '[';

        exec sql OPEN C_LISTCONTRACTS;

        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            pJsonData = '[]';
            return 0;
        endif;

        exec sql
            FETCH C_LISTCONTRACTS INTO :contId, :contReference, :custId,
                :brokerId, :productId, :startDate, :endDate,
                :vehiclesCount, :payFrequency, :premiumAmt, :autoRenew, :contStatus;

        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                pJsonData = %trim(pJsonData) + ',';
            endif;
            firstRow = *off;

            startDateStr = %char(startDate:*iso);
            if endDate <> d'0001-01-01';
                endDateStr = %char(endDate:*iso);
            else;
                endDateStr = '';
            endif;

            jsonRow = '{"CONT_ID":' + %char(contId) +
                ',"CONT_REFERENCE":"' + %trim(contReference) +
                '","CUST_ID":' + %char(custId) +
                ',"BROKER_ID":' + %char(brokerId) +
                ',"PRODUCT_ID":' + %char(productId) +
                ',"START_DATE":"' + startDateStr +
                '","END_DATE":"' + endDateStr +
                '","VEHICLES_COUNT":' + %char(vehiclesCount) +
                ',"PAY_FREQUENCY":"' + %trim(payFrequency) +
                '","PREMIUM_AMT":' + %char(premiumAmt) +
                ',"AUTO_RENEW":"' + %trim(autoRenew) +
                '","STATUS":"' + %trim(contStatus) + '"}';

            pJsonData = %trim(pJsonData) + jsonRow;
            resultCount += 1;

            exec sql
                FETCH C_LISTCONTRACTS INTO :contId, :contReference, :custId,
                    :brokerId, :productId, :startDate, :endDate,
                    :vehiclesCount, :payFrequency, :premiumAmt, :autoRenew, :contStatus;
        enddo;

        exec sql CLOSE C_LISTCONTRACTS;

        pJsonData = %trim(pJsonData) + ']';

    on-error;
        pJsonData = '[]';
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// GetCustomerContracts : Get contracts for customer
//
//  Returns: Result count
//
//==============================================================
dcl-proc CONTSRV_GetCustomerContracts export;
    dcl-pi *n int(10);
        pCustId packed(10:0) const;
    end-pi;

    dcl-s resultCount int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM CONTRACT
            WHERE CUST_ID = :pCustId;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// GetCustomerContractsJson : Get contracts for customer as JSON
//
//  Returns: Result count
//
//==============================================================
dcl-proc CONTSRV_GetCustomerContractsJson export;
    dcl-pi *n int(10);
        pCustId         packed(10:0) const;
        pJsonData       varchar(32000);
    end-pi;

    dcl-s jsonRow varchar(500);
    dcl-s contId packed(10:0);
    dcl-s contReference char(25);
    dcl-s brokerId packed(10:0);
    dcl-s productId packed(10:0);
    dcl-s startDate date;
    dcl-s endDate date;
    dcl-s premiumAmt packed(9:2);
    dcl-s contStatus char(3);
    dcl-s resultCount int(10) inz(0);
    dcl-s firstRow ind inz(*on);
    dcl-s startDateStr char(10);
    dcl-s endDateStr char(10);

    exec sql
        DECLARE C_CUSTCONTRACTS CURSOR FOR
        SELECT CONT_ID, CONT_REFERENCE, BROKER_ID, PRODUCT_ID,
               START_DATE, END_DATE, PREMIUM_AMT, STATUS
        FROM MRS1.CONTRACT
        WHERE CUST_ID = :pCustId
        ORDER BY START_DATE DESC;

    monitor;
        pJsonData = '[';

        exec sql OPEN C_CUSTCONTRACTS;

        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            pJsonData = '[]';
            return 0;
        endif;

        exec sql
            FETCH C_CUSTCONTRACTS INTO :contId, :contReference, :brokerId,
                :productId, :startDate, :endDate, :premiumAmt, :contStatus;

        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                pJsonData = %trim(pJsonData) + ',';
            endif;
            firstRow = *off;

            startDateStr = %char(startDate:*iso);
            if endDate <> d'0001-01-01';
                endDateStr = %char(endDate:*iso);
            else;
                endDateStr = '';
            endif;

            jsonRow = '{"CONT_ID":' + %char(contId) +
                ',"CONT_REFERENCE":"' + %trim(contReference) +
                '","CUST_ID":' + %char(pCustId) +
                ',"BROKER_ID":' + %char(brokerId) +
                ',"PRODUCT_ID":' + %char(productId) +
                ',"START_DATE":"' + startDateStr +
                '","END_DATE":"' + endDateStr +
                '","PREMIUM_AMT":' + %char(premiumAmt) +
                ',"STATUS":"' + %trim(contStatus) + '"}';

            pJsonData = %trim(pJsonData) + jsonRow;
            resultCount += 1;

            exec sql
                FETCH C_CUSTCONTRACTS INTO :contId, :contReference, :brokerId,
                    :productId, :startDate, :endDate, :premiumAmt, :contStatus;
        enddo;

        exec sql CLOSE C_CUSTCONTRACTS;

        pJsonData = %trim(pJsonData) + ']';

    on-error;
        pJsonData = '[]';
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// GetBrokerContracts : Get contracts for broker
//
//  Returns: Result count
//
//==============================================================
dcl-proc CONTSRV_GetBrokerContracts export;
    dcl-pi *n int(10);
        pBrokerId packed(10:0) const;
    end-pi;

    dcl-s resultCount int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM CONTRACT
            WHERE BROKER_ID = :pBrokerId;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// IsValidContract : Validate contract data
//
//  Returns: Validation indicator
//
//==============================================================
dcl-proc CONTSRV_IsValidContract export;
    dcl-pi *n ind;
        pContract likeds(Contract_t) const;
    end-pi;

    // Validation - Required fields
    if pContract.brokerId = 0;
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    if pContract.custId = 0;
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    if pContract.productId = 0;
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    // Validation - Dates
    if pContract.startDate = *loval;
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    if pContract.endDate <> *loval and pContract.endDate <= pContract.startDate;
        ERRUTIL_addErrorCode('VAL007');
        return *off;
    endif;

    // Validation - Payment frequency (M=Monthly, Q=Quarterly, A=Annual)
    if pContract.payFrequency <> 'M' and
       pContract.payFrequency <> 'Q' and
       pContract.payFrequency <> 'A' and
       pContract.payFrequency <> '';
        ERRUTIL_addErrorCode('VAL008');
        return *off;
    endif;

    return *on;
end-proc;

//==============================================================
// CalculatePremium : Calculate total premium
//
//  Returns: Premium amount
//
//==============================================================
dcl-proc CONTSRV_CalculatePremium export;
    dcl-pi *n packed(9:2);
        pProductCode char(10) const;
        pVehiclesCount packed(2:0) const;
        pPayFrequency char(1) const;
    end-pi;

    dcl-s premium packed(9:2) inz(0);
    dcl-s multiplier packed(5:2) inz(1);

    // Business logic - Get base premium with vehicles
    premium = PRODSRV_CalculateBasePremium(pProductCode: pVehiclesCount);

    // Apply payment frequency adjustment
    select;
        when pPayFrequency = 'M';
            multiplier = 1.05;  // 5% surcharge for monthly
        when pPayFrequency = 'Q';
            multiplier = 1.02;  // 2% surcharge for quarterly
        other;
            multiplier = 1.00;  // No surcharge for annual
    endsl;

    premium = premium * multiplier;

    return premium;
end-proc;

//==============================================================
// CanRenewContract : Check renewal eligibility
//
//  Returns: Can renew indicator
//
//==============================================================
dcl-proc CONTSRV_CanRenewContract export;
    dcl-pi *n ind;
        pContId packed(10:0) const;
    end-pi;

    dcl-ds contract likeds(Contract_t);
    dcl-s daysToExpiry int(10);

    contract = CONTSRV_GetContract(pContId);

    // Business logic - Check if contract is active and near expiry
    if contract.status <> 'ACT';
        ERRUTIL_addErrorCode('BUS003');
        return *off;
    endif;

    if contract.autoRenew = 'N';
        ERRUTIL_addErrorCode('BUS008');
        return *off;
    endif;

    // Check if within 2 months of expiry
    daysToExpiry = %diff(contract.endDate: %date(): *days);
    if daysToExpiry > 60;
        return *off;  // Too early to renew
    endif;

    return *on;
end-proc;

//==============================================================
// RenewContract : Create renewal contract
//
//  Returns: New contract ID
//
//==============================================================
dcl-proc CONTSRV_RenewContract export;
    dcl-pi *n packed(10:0);
        pContId packed(10:0) const;
    end-pi;

    dcl-ds oldContract likeds(Contract_t);
    dcl-ds newContract likeds(Contract_t);

    // Business logic
    if not CONTSRV_CanRenewContract(pContId);
        return 0;
    endif;

    oldContract = CONTSRV_GetContract(pContId);

    // Create new contract based on old
    newContract = oldContract;
    newContract.contId = 0;
    newContract.contReference = CONTSRV_GenerateContractRef(oldContract.brokerId);
    newContract.startDate = oldContract.endDate;
    newContract.endDate = newContract.startDate + %years(1);
    newContract.status = 'ACT';

    return CONTSRV_CreateContract(newContract);
end-proc;

//==============================================================
// IsContractActive : Check if contract is active
//
//  Returns: Active indicator
//
//==============================================================
dcl-proc CONTSRV_IsContractActive export;
    dcl-pi *n ind;
        pContId packed(10:0) const;
    end-pi;

    dcl-s status char(3);
    dcl-s startDate date;
    dcl-s endDate date;
    dcl-s today date;

    today = %date();

    monitor;
        // Business logic
        exec sql
            SELECT STATUS, START_DATE, END_DATE
            INTO :status, :startDate, :endDate
            FROM CONTRACT
            WHERE CONT_ID = :pContId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            return (status = 'ACT' and today >= startDate and today <= endDate);
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return *off;
end-proc;

//==============================================================
// GenerateContractRef : Generate policy number
//
//  Returns: Reference string
//
//==============================================================
dcl-proc CONTSRV_GenerateContractRef export;
    dcl-pi *n char(20);
        pBrokerId packed(10:0) const;
    end-pi;

    dcl-s reference char(20);
    dcl-s sequence packed(10:0);
    dcl-s year char(4);

    // Business logic - Generate unique reference
    // Format: DAS-YYYY-BBBBB-NNNNNN
    year = %char(%subdt(%date(): *years));

    monitor;
        exec sql
            SELECT COALESCE(MAX(CONT_ID), 0) + 1 INTO :sequence
            FROM CONTRACT;

    on-error;
        sequence = 1;
    endmon;

    reference = 'DAS-' + year + '-' +
                %trim(%editc(pBrokerId: 'Z')) + '-' +
                %trim(%editc(sequence: 'Z'));

    return reference;
end-proc;

//==============================================================
// CountStats : Get contract counts for dashboard
//
//  Returns total and active contract counts
//
//==============================================================
dcl-proc CONTSRV_CountStats export;
    dcl-pi *n;
        oTotal          packed(10:0);
        oActive         packed(10:0);
    end-pi;

    oTotal = 0;
    oActive = 0;

    monitor;
        exec sql
            SELECT COUNT(*), SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END)
            INTO :oTotal, :oActive
            FROM MRS1.CONTRACT;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;
end-proc;

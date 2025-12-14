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

// SQL Options - COMMIT(*NONE) required for PUB400 (no journaling)
exec sql SET OPTION COMMIT = *NONE, CLOSQLCSR = *ENDMOD;

/copy MRS1/QRPGLESRC,BROKRSRV_H
/copy MRS1/QRPGLESRC,ERRUTIL_H

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
    dcl-s saveSqlCode int(10);
    dcl-s saveSqlState char(5);

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not BROKRSRV_IsValidBroker(pBroker);
            return 0;
        endif;

        // Business logic
        exec sql
            INSERT INTO MRS1.BROKER (
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

        // Check INSERT result - treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            // Get the new broker ID using MAX (more reliable than IDENTITY_VAL_LOCAL)
            exec sql
                SELECT MAX(BROKER_ID) INTO :newBrokerId FROM MRS1.BROKER;
        else;
            ERRUTIL_addErrorCode('DB004');
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
            FROM MRS1.BROKER
            WHERE BROKER_ID = :pBrokerId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
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
            FROM MRS1.BROKER
            WHERE BROKER_CODE = :pBrokerCode;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
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
        if not BROKRSRV_IsValidBroker(pBroker);
            return *off;
        endif;

        // Business logic
        exec sql
            UPDATE MRS1.BROKER SET
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
            UPDATE MRS1.BROKER SET
                STATUS = 'INA',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE BROKER_ID = :pBrokerId;

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
            FROM MRS1.BROKER
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
    if pBroker.fsmaNumber <> '' and not BROKRSRV_IsValidFsmaNumber(pBroker.fsmaNumber);
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

//==============================================================
// ListBrokersJson : List brokers as JSON array
//
//  Returns: Count of brokers
//
//==============================================================
dcl-proc BROKRSRV_ListBrokersJson export;
    dcl-pi *n int(10);
        pStatusFilter   char(3) const;
        pJsonData       varchar(32000);
        pSqlCode        int(10);
    end-pi;

    dcl-s jsonRow varchar(500);
    dcl-s brokerId packed(10:0);
    dcl-s brokerCode char(10);
    dcl-s companyName varchar(100);
    dcl-s vatNumber char(12);
    dcl-s fsmaNumber char(10);
    dcl-s street varchar(30);
    dcl-s houseNbr char(5);
    dcl-s postalCode char(7);
    dcl-s city varchar(24);
    dcl-s phone varchar(20);
    dcl-s email varchar(100);
    dcl-s contactName varchar(100);
    dcl-s brokerStatus char(3);
    dcl-s resultCount int(10) inz(0);
    dcl-s firstRow ind inz(*on);
    dcl-s statusFilter char(3);

    exec sql
        DECLARE C_LISTBROKERS CURSOR FOR
        SELECT BROKER_ID, BROKER_CODE, COMPANY_NAME,
               COALESCE(VAT_NUMBER, ''), COALESCE(FSMA_NUMBER, ''),
               COALESCE(STREET, ''), COALESCE(HOUSE_NBR, ''),
               COALESCE(POSTAL_CODE, ''), COALESCE(CITY, ''),
               COALESCE(PHONE, ''), COALESCE(EMAIL, ''),
               COALESCE(CONTACT_NAME, ''), STATUS
        FROM MRS1.BROKER
        WHERE TRIM(:statusFilter) = '' OR STATUS = TRIM(:statusFilter)
        ORDER BY COMPANY_NAME;

    // SQLCODE after DECLARE (should be 0)
    pSqlCode = sqlcode;

    monitor;
        statusFilter = %trim(pStatusFilter);
        pJsonData = '[';

        exec sql OPEN C_LISTBROKERS;

        // SQLCODE after OPEN
        pSqlCode = sqlcode;

        exec sql
            FETCH C_LISTBROKERS INTO :brokerId, :brokerCode, :companyName,
                :vatNumber, :fsmaNumber, :street, :houseNbr,
                :postalCode, :city, :phone, :email, :contactName, :brokerStatus;

        // SQLCODE after first FETCH
        pSqlCode = sqlcode;

        // Also handle SQLCODE 8013 (PUB400 licensing)
        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                pJsonData = %trim(pJsonData) + ',';
            endif;
            firstRow = *off;

            jsonRow = '{"BROKER_ID":' + %char(brokerId) +
                ',"BROKER_CODE":"' + %trim(brokerCode) +
                '","COMPANY_NAME":"' + %trim(companyName) +
                '","VAT_NUMBER":"' + %trim(vatNumber) +
                '","FSMA_NUMBER":"' + %trim(fsmaNumber) +
                '","STREET":"' + %trim(street) +
                '","HOUSE_NBR":"' + %trim(houseNbr) +
                '","POSTAL_CODE":"' + %trim(postalCode) +
                '","CITY":"' + %trim(city) +
                '","PHONE":"' + %trim(phone) +
                '","EMAIL":"' + %trim(email) +
                '","CONTACT_NAME":"' + %trim(contactName) +
                '","STATUS":"' + %trim(brokerStatus) + '"}';

            pJsonData = %trim(pJsonData) + jsonRow;
            resultCount += 1;

            exec sql
                FETCH C_LISTBROKERS INTO :brokerId, :brokerCode, :companyName,
                    :vatNumber, :fsmaNumber, :street, :houseNbr,
                    :postalCode, :city, :phone, :email, :contactName, :brokerStatus;
        enddo;

        exec sql CLOSE C_LISTBROKERS;

        pJsonData = %trim(pJsonData) + ']';

    on-error;
        pJsonData = '[]';
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// CountStats : Get broker counts for dashboard
//
//  Returns total and active broker counts
//
//==============================================================
dcl-proc BROKRSRV_CountStats export;
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
            FROM MRS1.BROKER;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;
end-proc;

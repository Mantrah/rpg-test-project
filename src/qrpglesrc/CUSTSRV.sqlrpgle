**free
// ============================================================
// CUSTSRV - Customer Service Module
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// CRUD operations for Customer (policyholders).
// Supports individuals (IND) and businesses (BUS).
// TELEBIB2 alignment: CivilStatusCode, BusinessCodeNace, Address
// ============================================================

ctl-opt nomain option(*srcstmt:*nodebugio);

// SQL Options - COMMIT(*NONE) required for PUB400 (no journaling)
exec sql SET OPTION COMMIT = *NONE, CLOSQLCSR = *ENDMOD;

/copy MRS1/QRPGLESRC,CUSTSRV_H
/copy MRS1/QRPGLESRC,ERRUTIL_H

//==============================================================
// CreateCustomer : Insert new customer
//
//  Returns: Customer ID (0 on error)
//
//==============================================================
dcl-proc CUSTSRV_CreateCustomer export;
    dcl-pi *n packed(10:0);
        pCustomer likeds(Customer_t) const;
    end-pi;

    dcl-s newCustId packed(10:0) inz(0);
    dcl-s rowCount int(10) inz(0);
    dcl-s saveSqlcode int(10) inz(0);
    dcl-ds customer likeds(Customer_t) inz;

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not CUSTSRV_IsValidCustomer(pCustomer);
            return 0;
        endif;

        // Copy param to local DS
        customer = pCustomer;
        customer.status = 'ACT';

        // Business logic - INSERT using DS
        // Use NULLIF for optional fields to avoid CHECK constraint violations
        // (char fields initialized to blanks, but constraints expect NULL or valid values)
        exec sql
            INSERT INTO MRS1.CUSTOMER (
                CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
                CIVIL_STATUS, BIRTH_DATE, COMPANY_NAME, VAT_NUMBER,
                NACE_CODE, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
                CITY, COUNTRY_CODE, PHONE, EMAIL, LANGUAGE, STATUS
            ) VALUES (
                :customer.custType,
                NULLIF(RTRIM(:customer.firstName), ''),
                NULLIF(RTRIM(:customer.lastName), ''),
                NULLIF(RTRIM(:customer.nationalId), ''),
                NULLIF(RTRIM(:customer.civilStatus), ''),
                :customer.birthDate,
                NULLIF(RTRIM(:customer.companyName), ''),
                NULLIF(RTRIM(:customer.vatNumber), ''),
                NULLIF(RTRIM(:customer.naceCode), ''),
                NULLIF(RTRIM(:customer.street), ''),
                NULLIF(RTRIM(:customer.houseNbr), ''),
                NULLIF(RTRIM(:customer.boxNbr), ''),
                NULLIF(RTRIM(:customer.postalCode), ''),
                NULLIF(RTRIM(:customer.city), ''),
                NULLIF(RTRIM(:customer.countryCode), ''),
                NULLIF(RTRIM(:customer.phone), ''),
                NULLIF(RTRIM(:customer.email), ''),
                :customer.language,
                :customer.status
            );

        // Save SQLCODE for debugging
        saveSqlcode = sqlcode;

        // Get row count to verify INSERT actually worked
        exec sql GET DIAGNOSTICS :rowCount = ROW_COUNT;

        // Only treat as success if we actually inserted a row
        // SQLCODE 8013 is a warning but INSERT may have failed
        if rowCount > 0;
            exec sql
                SELECT IDENTITY_VAL_LOCAL() INTO :newCustId FROM SYSIBM.SYSDUMMY1;

            // Verify the ID is valid
            if newCustId <= 0;
                ERRUTIL_addErrorCode('DB004');
                ERRUTIL_addErrorMessage('INSERT ok but IDENTITY_VAL_LOCAL failed, sqlcode=' +
                                        %char(saveSqlcode));
                newCustId = 0;
            endif;
        else;
            ERRUTIL_addErrorCode('DB004');
            ERRUTIL_addErrorMessage('INSERT failed: 0 rows, sqlcode=' + %char(saveSqlcode));
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return newCustId;
end-proc;

//==============================================================
// GetCustomer : Retrieve customer by ID
//
//  Returns: Customer DS (empty on error)
//
//==============================================================
dcl-proc CUSTSRV_GetCustomer export;
    dcl-pi *n likeds(Customer_t);
        pCustId packed(10:0) const;
    end-pi;

    dcl-ds customer likeds(Customer_t) inz;

    monitor;
        // Business logic - Select directly into structure
        exec sql
            SELECT CUST_ID, CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
                   CIVIL_STATUS, BIRTH_DATE, COMPANY_NAME, VAT_NUMBER,
                   NACE_CODE, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
                   CITY, COUNTRY_CODE, PHONE, EMAIL, LANGUAGE,
                   STATUS, CREATED_AT, UPDATED_AT
            INTO :customer
            FROM MRS1.CUSTOMER
            WHERE CUST_ID = :pCustId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            clear customer;
            if sqlcode = 100;
                ERRUTIL_addErrorCode('DB001');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        clear customer;
        ERRUTIL_addExecutionError();
    endmon;

    return customer;
end-proc;

//==============================================================
// GetCustomerByEmail : Retrieve customer by email
//
//  Returns: Customer DS (empty on error)
//
//==============================================================
dcl-proc CUSTSRV_GetCustomerByEmail export;
    dcl-pi *n likeds(Customer_t);
        pEmail varchar(100) const;
    end-pi;

    dcl-ds customer likeds(Customer_t) inz;
    dcl-s emailFilter varchar(100);

    monitor;
        emailFilter = %trim(pEmail);

        // Business logic - Select directly into structure
        exec sql
            SELECT CUST_ID, CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
                   CIVIL_STATUS, BIRTH_DATE, COMPANY_NAME, VAT_NUMBER,
                   NACE_CODE, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
                   CITY, COUNTRY_CODE, PHONE, EMAIL, LANGUAGE,
                   STATUS, CREATED_AT, UPDATED_AT
            INTO :customer
            FROM MRS1.CUSTOMER
            WHERE EMAIL = :emailFilter;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            clear customer;
            if sqlcode = 100;
                ERRUTIL_addErrorCode('DB001');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        clear customer;
        ERRUTIL_addExecutionError();
    endmon;

    return customer;
end-proc;

//==============================================================
// UpdateCustomer : Update existing customer
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc CUSTSRV_UpdateCustomer export;
    dcl-pi *n ind;
        pCustomer likeds(Customer_t) const;
    end-pi;

    dcl-s success ind inz(*off);

    // Standalone variables for SQL
    dcl-s custId packed(10:0);
    dcl-s custType char(3);
    dcl-s firstName varchar(50);
    dcl-s lastName varchar(50);
    dcl-s nationalId char(15);
    dcl-s civilStatus char(3);
    dcl-s birthDate date;
    dcl-s companyName varchar(100);
    dcl-s vatNumber char(12);
    dcl-s naceCode char(5);
    dcl-s street varchar(30);
    dcl-s houseNbr char(5);
    dcl-s boxNbr char(4);
    dcl-s postalCode char(7);
    dcl-s city varchar(24);
    dcl-s countryCode char(3);
    dcl-s phone varchar(20);
    dcl-s email varchar(100);
    dcl-s language char(2);
    dcl-s status char(3);

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not CUSTSRV_IsValidCustomer(pCustomer);
            return *off;
        endif;

        // Copy to standalone variables
        custId = pCustomer.custId;
        custType = pCustomer.custType;
        firstName = pCustomer.firstName;
        lastName = pCustomer.lastName;
        nationalId = pCustomer.nationalId;
        civilStatus = pCustomer.civilStatus;
        birthDate = pCustomer.birthDate;
        companyName = pCustomer.companyName;
        vatNumber = pCustomer.vatNumber;
        naceCode = pCustomer.naceCode;
        street = pCustomer.street;
        houseNbr = pCustomer.houseNbr;
        boxNbr = pCustomer.boxNbr;
        postalCode = pCustomer.postalCode;
        city = pCustomer.city;
        countryCode = pCustomer.countryCode;
        phone = pCustomer.phone;
        email = pCustomer.email;
        language = pCustomer.language;
        status = pCustomer.status;

        // Business logic
        exec sql
            UPDATE MRS1.CUSTOMER SET
                CUST_TYPE = :custType,
                FIRST_NAME = :firstName,
                LAST_NAME = :lastName,
                NATIONAL_ID = :nationalId,
                CIVIL_STATUS = :civilStatus,
                BIRTH_DATE = :birthDate,
                COMPANY_NAME = :companyName,
                VAT_NUMBER = :vatNumber,
                NACE_CODE = :naceCode,
                STREET = :street,
                HOUSE_NBR = :houseNbr,
                BOX_NBR = :boxNbr,
                POSTAL_CODE = :postalCode,
                CITY = :city,
                COUNTRY_CODE = :countryCode,
                PHONE = :phone,
                EMAIL = :email,
                LANGUAGE = :language,
                STATUS = :status,
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CUST_ID = :custId;

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
// DeleteCustomer : Soft delete (set inactive)
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc CUSTSRV_DeleteCustomer export;
    dcl-pi *n ind;
        pCustId packed(10:0) const;
    end-pi;

    dcl-s success ind inz(*off);

    monitor;
        // Business logic - soft delete
        exec sql
            UPDATE MRS1.CUSTOMER SET
                STATUS = 'INA',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CUST_ID = :pCustId;

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
// ListCustomers : Search with filters
//
//  Returns: Result count
//
//==============================================================
dcl-proc CUSTSRV_ListCustomers export;
    dcl-pi *n int(10);
        pFilter likeds(CustomerFilter_t) const;
    end-pi;

    dcl-s resultCount int(10) inz(0);
    dcl-s custType char(3);
    dcl-s lastName varchar(50);
    dcl-s companyName varchar(100);
    dcl-s city varchar(24);
    dcl-s status char(3);

    monitor;
        // Copy filter values
        custType = pFilter.custType;
        lastName = pFilter.lastName;
        companyName = pFilter.companyName;
        city = pFilter.city;
        status = pFilter.status;

        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM MRS1.CUSTOMER
            WHERE (:custType = '' OR CUST_TYPE = :custType)
              AND (:lastName = '' OR LAST_NAME LIKE :lastName || '%')
              AND (:companyName = '' OR COMPANY_NAME LIKE :companyName || '%')
              AND (:city = '' OR CITY = :city)
              AND (:status = '' OR STATUS = :status);

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// ListCustomersJson : List customers and return JSON array
//
//  Returns: Result count
//
//==============================================================
dcl-proc CUSTSRV_ListCustomersJson export;
    dcl-pi *n int(10);
        pStatusFilter   char(3) const;
        pJsonData       varchar(32000);
    end-pi;

    dcl-s jsonRow varchar(800);
    dcl-s custId packed(10:0);
    dcl-s custType char(3);
    dcl-s firstName varchar(50);
    dcl-s lastName varchar(50);
    dcl-s nationalId char(15);
    dcl-s companyName varchar(100);
    dcl-s street varchar(30);
    dcl-s postalCode char(7);
    dcl-s city varchar(24);
    dcl-s phone varchar(20);
    dcl-s email varchar(100);
    dcl-s language char(2);
    dcl-s custStatus char(3);
    dcl-s resultCount int(10) inz(0);
    dcl-s firstRow ind inz(*on);
    dcl-s statusFilter char(3);

    exec sql
        DECLARE C_LISTCUSTOMERS CURSOR FOR
        SELECT CUST_ID, CUST_TYPE,
               COALESCE(FIRST_NAME, ''), COALESCE(LAST_NAME, ''),
               COALESCE(NATIONAL_ID, ''), COALESCE(COMPANY_NAME, ''),
               COALESCE(STREET, ''), COALESCE(POSTAL_CODE, ''),
               COALESCE(CITY, ''), COALESCE(PHONE, ''),
               COALESCE(EMAIL, ''), COALESCE(LANGUAGE, ''), STATUS
        FROM MRS1.CUSTOMER
        WHERE :statusFilter = '' OR STATUS = :statusFilter
        ORDER BY LAST_NAME, FIRST_NAME;

    monitor;
        statusFilter = %trim(pStatusFilter);
        pJsonData = '[';

        exec sql OPEN C_LISTCUSTOMERS;

        // SQLCODE 8013 = PUB400 licensing - ignore and return empty
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            pJsonData = '[]';
            return 0;
        endif;

        exec sql
            FETCH C_LISTCUSTOMERS INTO :custId, :custType, :firstName, :lastName,
                :nationalId, :companyName, :street, :postalCode, :city,
                :phone, :email, :language, :custStatus;

        // Also handle SQLCODE 8013 (PUB400 licensing)
        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                pJsonData = %trim(pJsonData) + ',';
            endif;
            firstRow = *off;

            jsonRow = '{"CUST_ID":' + %char(custId) +
                ',"CUST_TYPE":"' + %trim(custType) +
                '","FIRST_NAME":"' + %trim(firstName) +
                '","LAST_NAME":"' + %trim(lastName) +
                '","NATIONAL_ID":"' + %trim(nationalId) +
                '","COMPANY_NAME":"' + %trim(companyName) +
                '","STREET":"' + %trim(street) +
                '","POSTAL_CODE":"' + %trim(postalCode) +
                '","CITY":"' + %trim(city) +
                '","PHONE":"' + %trim(phone) +
                '","EMAIL":"' + %trim(email) +
                '","LANGUAGE":"' + %trim(language) +
                '","STATUS":"' + %trim(custStatus) + '"}';

            pJsonData = %trim(pJsonData) + jsonRow;
            resultCount += 1;

            exec sql
                FETCH C_LISTCUSTOMERS INTO :custId, :custType, :firstName, :lastName,
                    :nationalId, :companyName, :street, :postalCode, :city,
                    :phone, :email, :language, :custStatus;
        enddo;

        exec sql CLOSE C_LISTCUSTOMERS;

        pJsonData = %trim(pJsonData) + ']';

    on-error;
        pJsonData = '[]';
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// IsValidCustomer : Validate customer data
//
//  Returns: Validation indicator
//
//==============================================================
dcl-proc CUSTSRV_IsValidCustomer export;
    dcl-pi *n ind;
        pCustomer likeds(Customer_t) const;
    end-pi;

    // Validation - Customer type
    if pCustomer.custType <> 'IND' and pCustomer.custType <> 'BUS';
        ERRUTIL_addErrorCode('VAL006');
        ERRUTIL_addErrorMessage('custType: must be IND or BUS, got: ' +
                                %trim(pCustomer.custType));
        return *off;
    endif;

    // Validation - Individual requirements
    if pCustomer.custType = 'IND';
        if pCustomer.firstName = '';
            ERRUTIL_addErrorCode('BUS001');
            ERRUTIL_addErrorMessage('firstName: required for individual customer');
            return *off;
        endif;
        if pCustomer.lastName = '';
            ERRUTIL_addErrorCode('BUS001');
            ERRUTIL_addErrorMessage('lastName: required for individual customer');
            return *off;
        endif;
        if pCustomer.nationalId <> '' and not CUSTSRV_IsValidNationalId(pCustomer.nationalId);
            return *off;
        endif;
    endif;

    // Validation - Business requirements
    if pCustomer.custType = 'BUS';
        if pCustomer.companyName = '';
            ERRUTIL_addErrorCode('BUS002');
            ERRUTIL_addErrorMessage('companyName: required for business customer');
            return *off;
        endif;
        if pCustomer.vatNumber <> '' and not CUSTSRV_IsValidVatNumber(pCustomer.vatNumber);
            return *off;
        endif;
    endif;

    // Validation - Email
    if pCustomer.email <> '' and not CUSTSRV_IsValidEmail(pCustomer.email);
        return *off;
    endif;

    // Validation - Postal code
    if pCustomer.postalCode <> '' and not CUSTSRV_IsValidPostalCode(pCustomer.postalCode);
        return *off;
    endif;

    return *on;
end-proc;

//==============================================================
// IsValidEmail : Validate email format
//
//  Returns: Valid indicator
//
//  NOTE: Due to CCSID conversion issues between Node.js (UTF-8)
//  and IBM i (EBCDIC), the @ character may be corrupted during
//  iToolkit transmission. Full email validation is done in Node.js.
//  Here we only do minimal validation (check for dot in domain).
//==============================================================
dcl-proc CUSTSRV_IsValidEmail export;
    dcl-pi *n ind;
        pEmail varchar(100) const;
    end-pi;

    dcl-s dotPos int(10);
    dcl-s emailLen int(10);

    emailLen = %len(%trim(pEmail));

    // Minimal validation - email must have at least a.b format
    // Full validation (including @) is done in Node.js layer
    // to avoid CCSID/EBCDIC conversion issues with @ character
    if emailLen < 3;
        ERRUTIL_addErrorCode('VAL001');
        ERRUTIL_addErrorMessage('email: too short (min 3 chars)');
        return *off;
    endif;

    // Check for at least one dot (domain separator)
    dotPos = %scan('.': pEmail);
    if dotPos = 0 or dotPos < 2 or dotPos >= emailLen;
        ERRUTIL_addErrorCode('VAL001');
        ERRUTIL_addErrorMessage('email: missing valid domain dot');
        return *off;
    endif;

    return *on;
end-proc;

//==============================================================
// IsValidVatNumber : Validate Belgian VAT format
//
//  Returns: Valid indicator
//
//==============================================================
dcl-proc CUSTSRV_IsValidVatNumber export;
    dcl-pi *n ind;
        pVatNumber char(12) const;
    end-pi;

    dcl-s vatNum char(12);
    dcl-s numPart char(10);
    dcl-s i int(10);

    vatNum = %trim(pVatNumber);

    // Validation - Belgian VAT: BE + 10 digits
    if %len(%trim(vatNum)) <> 12;
        ERRUTIL_addErrorCode('VAL002');
        ERRUTIL_addErrorMessage('vatNumber: must be 12 chars (BE+10 digits), got: ' +
                                %trim(vatNum));
        return *off;
    endif;

    if %subst(vatNum: 1: 2) <> 'BE';
        ERRUTIL_addErrorCode('VAL002');
        ERRUTIL_addErrorMessage('vatNumber: must start with BE, got: ' +
                                %subst(vatNum: 1: 2));
        return *off;
    endif;

    // Check remaining 10 chars are digits
    numPart = %subst(vatNum: 3: 10);
    for i = 1 to 10;
        if %subst(numPart: i: 1) < '0' or %subst(numPart: i: 1) > '9';
            ERRUTIL_addErrorCode('VAL002');
            ERRUTIL_addErrorMessage('vatNumber: position ' + %char(i+2) +
                                    ' must be digit in: ' + %trim(vatNum));
            return *off;
        endif;
    endfor;

    return *on;
end-proc;

//==============================================================
// IsValidNationalId : Validate Belgian NRN format
//
//  Returns: Valid indicator
//
//==============================================================
dcl-proc CUSTSRV_IsValidNationalId export;
    dcl-pi *n ind;
        pNationalId char(15) const;
    end-pi;

    // Validation - Belgian NRN format: YY.MM.DD-XXX.CC
    // Simplified validation - check length and basic format
    if %len(%trim(pNationalId)) < 11;
        ERRUTIL_addErrorCode('VAL003');
        ERRUTIL_addErrorMessage('nationalId: min 11 chars (YY.MM.DD-XXX.CC), got: ' +
                                %trim(pNationalId));
        return *off;
    endif;

    return *on;
end-proc;

//==============================================================
// IsValidPostalCode : Validate Belgian postal code
//
//  Returns: Valid indicator
//
//==============================================================
dcl-proc CUSTSRV_IsValidPostalCode export;
    dcl-pi *n ind;
        pPostalCode char(7) const;
    end-pi;

    dcl-s code char(4);
    dcl-s i int(10);

    // Validation - Belgian postal code: 4 digits (1000-9999)
    code = %trim(pPostalCode);
    if %len(code) <> 4;
        ERRUTIL_addErrorCode('VAL004');
        ERRUTIL_addErrorMessage('postalCode: must be 4 digits (1000-9999), got: ' +
                                %trim(pPostalCode));
        return *off;
    endif;

    for i = 1 to 4;
        if %subst(code: i: 1) < '0' or %subst(code: i: 1) > '9';
            ERRUTIL_addErrorCode('VAL004');
            ERRUTIL_addErrorMessage('postalCode: position ' + %char(i) +
                                    ' must be digit in: ' + %trim(pPostalCode));
            return *off;
        endif;
    endfor;

    return *on;
end-proc;

//==============================================================
// CountStats : Get customer counts for dashboard
//
//  Returns total and active customer counts
//
//==============================================================
dcl-proc CUSTSRV_CountStats export;
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
            FROM MRS1.CUSTOMER;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;
end-proc;

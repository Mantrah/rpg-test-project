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

/copy qrpglesrc/CUSTSRV_H

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

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not IsValidCustomer(pCustomer);
            return 0;
        endif;

        // Business logic
        exec sql
            INSERT INTO CUSTOMER (
                CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
                CIVIL_STATUS, BIRTH_DATE, COMPANY_NAME, VAT_NUMBER,
                NACE_CODE, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
                CITY, COUNTRY_CODE, PHONE, EMAIL, LANGUAGE, STATUS
            ) VALUES (
                :pCustomer.custType, :pCustomer.firstName, :pCustomer.lastName,
                :pCustomer.nationalId, :pCustomer.civilStatus, :pCustomer.birthDate,
                :pCustomer.companyName, :pCustomer.vatNumber, :pCustomer.naceCode,
                :pCustomer.street, :pCustomer.houseNbr, :pCustomer.boxNbr,
                :pCustomer.postalCode, :pCustomer.city, :pCustomer.countryCode,
                :pCustomer.phone, :pCustomer.email, :pCustomer.language, 'ACT'
            );

        if sqlcode = 0;
            exec sql
                SELECT IDENTITY_VAL_LOCAL() INTO :newCustId FROM SYSIBM.SYSDUMMY1;
        else;
            ERRUTIL_addErrorCode('DB004');
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
        // Business logic
        exec sql
            SELECT CUST_ID, CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
                   CIVIL_STATUS, BIRTH_DATE, COMPANY_NAME, VAT_NUMBER,
                   NACE_CODE, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
                   CITY, COUNTRY_CODE, PHONE, EMAIL, LANGUAGE, STATUS,
                   CREATED_AT, UPDATED_AT
            INTO :customer
            FROM CUSTOMER
            WHERE CUST_ID = :pCustId;

        if sqlcode <> 0;
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

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not IsValidCustomer(pCustomer);
            return *off;
        endif;

        // Business logic
        exec sql
            UPDATE CUSTOMER SET
                CUST_TYPE = :pCustomer.custType,
                FIRST_NAME = :pCustomer.firstName,
                LAST_NAME = :pCustomer.lastName,
                NATIONAL_ID = :pCustomer.nationalId,
                CIVIL_STATUS = :pCustomer.civilStatus,
                BIRTH_DATE = :pCustomer.birthDate,
                COMPANY_NAME = :pCustomer.companyName,
                VAT_NUMBER = :pCustomer.vatNumber,
                NACE_CODE = :pCustomer.naceCode,
                STREET = :pCustomer.street,
                HOUSE_NBR = :pCustomer.houseNbr,
                BOX_NBR = :pCustomer.boxNbr,
                POSTAL_CODE = :pCustomer.postalCode,
                CITY = :pCustomer.city,
                COUNTRY_CODE = :pCustomer.countryCode,
                PHONE = :pCustomer.phone,
                EMAIL = :pCustomer.email,
                LANGUAGE = :pCustomer.language,
                STATUS = :pCustomer.status,
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CUST_ID = :pCustomer.custId;

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
            UPDATE CUSTOMER SET
                STATUS = 'INA',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CUST_ID = :pCustId;

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

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM CUSTOMER
            WHERE (:pFilter.custType = '' OR CUST_TYPE = :pFilter.custType)
              AND (:pFilter.lastName = '' OR LAST_NAME LIKE :pFilter.lastName || '%')
              AND (:pFilter.companyName = '' OR COMPANY_NAME LIKE :pFilter.companyName || '%')
              AND (:pFilter.city = '' OR CITY = :pFilter.city)
              AND (:pFilter.status = '' OR STATUS = :pFilter.status);

    on-error;
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
        return *off;
    endif;

    // Validation - Individual requirements
    if pCustomer.custType = 'IND';
        if pCustomer.firstName = '' or pCustomer.lastName = '';
            ERRUTIL_addErrorCode('BUS001');
            return *off;
        endif;
        if pCustomer.nationalId <> '' and not IsValidNationalId(pCustomer.nationalId);
            return *off;
        endif;
    endif;

    // Validation - Business requirements
    if pCustomer.custType = 'BUS';
        if pCustomer.companyName = '';
            ERRUTIL_addErrorCode('BUS002');
            return *off;
        endif;
        if pCustomer.vatNumber <> '' and not IsValidVatNumber(pCustomer.vatNumber);
            return *off;
        endif;
    endif;

    // Validation - Email
    if pCustomer.email <> '' and not IsValidEmail(pCustomer.email);
        return *off;
    endif;

    // Validation - Postal code
    if pCustomer.postalCode <> '' and not IsValidPostalCode(pCustomer.postalCode);
        return *off;
    endif;

    return *on;
end-proc;

//==============================================================
// IsValidEmail : Validate email format
//
//  Returns: Valid indicator
//
//==============================================================
dcl-proc CUSTSRV_IsValidEmail export;
    dcl-pi *n ind;
        pEmail varchar(100) const;
    end-pi;

    dcl-s atPos int(10);
    dcl-s dotPos int(10);

    // Validation - Basic email format check
    atPos = %scan('@': pEmail);
    if atPos < 2;
        ERRUTIL_addErrorCode('VAL001');
        return *off;
    endif;

    dotPos = %scan('.': pEmail: atPos);
    if dotPos = 0 or dotPos <= atPos + 1;
        ERRUTIL_addErrorCode('VAL001');
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
        return *off;
    endif;

    if %subst(vatNum: 1: 2) <> 'BE';
        ERRUTIL_addErrorCode('VAL002');
        return *off;
    endif;

    // Check remaining 10 chars are digits
    numPart = %subst(vatNum: 3: 10);
    for i = 1 to 10;
        if %subst(numPart: i: 1) < '0' or %subst(numPart: i: 1) > '9';
            ERRUTIL_addErrorCode('VAL002');
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
        return *off;
    endif;

    for i = 1 to 4;
        if %subst(code: i: 1) < '0' or %subst(code: i: 1) > '9';
            ERRUTIL_addErrorCode('VAL004');
            return *off;
        endif;
    endfor;

    return *on;
end-proc;

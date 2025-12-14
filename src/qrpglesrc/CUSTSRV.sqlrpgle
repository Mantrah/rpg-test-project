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
        exec sql
            INSERT INTO MRS1.CUSTOMER (
                CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
                CIVIL_STATUS, BIRTH_DATE, COMPANY_NAME, VAT_NUMBER,
                NACE_CODE, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
                CITY, COUNTRY_CODE, PHONE, EMAIL, LANGUAGE, STATUS
            ) VALUES (
                :customer.custType, :customer.firstName, :customer.lastName,
                :customer.nationalId, :customer.civilStatus, :customer.birthDate,
                :customer.companyName, :customer.vatNumber, :customer.naceCode,
                :customer.street, :customer.houseNbr, :customer.boxNbr,
                :customer.postalCode, :customer.city, :customer.countryCode,
                :customer.phone, :customer.email, :customer.language,
                :customer.status
            );

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
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
        ERRUTIL_addErrorMessage('email: missing or invalid @ position in: ' +
                                %trim(pEmail));
        return *off;
    endif;

    dotPos = %scan('.': pEmail: atPos);
    if dotPos = 0 or dotPos <= atPos + 1;
        ERRUTIL_addErrorCode('VAL001');
        ERRUTIL_addErrorMessage('email: missing domain dot after @ in: ' +
                                %trim(pEmail));
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

**free
// ============================================================
// RPGWRAP - iToolkit Wrapper Module
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Wrapper procedures with scalar OUTPUT parameters for
// iToolkit/XMLSERVICE integration from Node.js.
// These call the main service procedures internally.
// ============================================================

ctl-opt nomain option(*srcstmt:*nodebugio);

// SQL Options - COMMIT(*NONE) required for PUB400 (no journaling)
exec sql SET OPTION COMMIT = *NONE, CLOSQLCSR = *ENDMOD;

/copy MRS1/QRPGLESRC,CUSTSRV_H
/copy MRS1/QRPGLESRC,BROKRSRV_H
/copy MRS1/QRPGLESRC,PRODSRV_H
/copy MRS1/QRPGLESRC,CONTSRV_H
/copy MRS1/QRPGLESRC,CLAIMSRV_H
/copy MRS1/QRPGLESRC,ERRUTIL_H

//==============================================================
// BROKER WRAPPERS
//==============================================================

//--------------------------------------------------------------
// GetBrokerById : Get broker by ID with scalar outputs
//--------------------------------------------------------------
dcl-proc WRAP_GetBrokerById export;
    dcl-pi *n;
        pBrokerId       packed(10:0) const;
        // OUTPUT parameters
        oBrokerCode     char(10);
        oCompanyName    char(100);
        oVatNumber      char(12);
        oFsmaNumber     char(10);
        oStreet         char(30);
        oHouseNbr       char(5);
        oPostalCode     char(7);
        oCity           char(24);
        oPhone          char(20);
        oEmail          char(100);
        oContactName    char(100);
        oStatus         char(3);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-ds broker likeds(Broker_t);

    ERRUTIL_init();
    broker = BROKRSRV_GetBroker(pBrokerId);

    if broker.brokerId > 0;
        oBrokerCode = broker.brokerCode;
        oCompanyName = broker.companyName;
        oVatNumber = broker.vatNumber;
        oFsmaNumber = broker.fsmaNumber;
        oStreet = broker.street;
        oHouseNbr = broker.houseNbr;
        oPostalCode = broker.postalCode;
        oCity = broker.city;
        oPhone = broker.phone;
        oEmail = broker.email;
        oContactName = broker.contactName;
        oStatus = broker.status;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        clear oBrokerCode;
        clear oCompanyName;
        clear oVatNumber;
        clear oFsmaNumber;
        clear oStreet;
        clear oHouseNbr;
        clear oPostalCode;
        clear oCity;
        clear oPhone;
        clear oEmail;
        clear oContactName;
        clear oStatus;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// ListBrokers : List brokers and return JSON array
// Delegates to BROKRSRV_ListBrokersJson for proper SQL context
//--------------------------------------------------------------
dcl-proc WRAP_ListBrokers export;
    dcl-pi *n;
        pStatus         char(3) const;
        // OUTPUT - JSON array of brokers
        oJsonData       varchar(32000);
        oCount          packed(10:0);
        oSuccess        char(1);
    end-pi;

    monitor;
        oCount = BROKRSRV_ListBrokersJson(pStatus: oJsonData);
        oSuccess = 'Y';
    on-error;
        oJsonData = '[]';
        oCount = 0;
        oSuccess = 'N';
    endmon;
end-proc;

//--------------------------------------------------------------
// DeleteBroker : Soft delete broker (set status to INA)
//--------------------------------------------------------------
dcl-proc WRAP_DeleteBroker export;
    dcl-pi *n;
        pBrokerId       packed(10:0) const;
        // OUTPUT
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-s result ind;

    ERRUTIL_init();
    result = BROKRSRV_DeleteBroker(pBrokerId);

    if result;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// CreateBroker : Create broker with scalar inputs
//--------------------------------------------------------------
dcl-proc WRAP_CreateBroker export;
    dcl-pi *n;
        pBrokerCode     char(10) const;
        pCompanyName    char(100) const;
        pVatNumber      char(12) const;
        pFsmaNumber     char(10) const;
        pStreet         char(30) const;
        pHouseNbr       char(5) const;
        pPostalCode     char(7) const;
        pCity           char(24) const;
        pPhone          char(20) const;
        pEmail          char(100) const;
        pContactName    char(100) const;
        // OUTPUT
        oBrokerId       packed(10:0);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-ds broker likeds(Broker_t) inz;

    ERRUTIL_init();

    broker.brokerCode = pBrokerCode;
    broker.companyName = pCompanyName;
    broker.vatNumber = pVatNumber;
    broker.fsmaNumber = pFsmaNumber;
    broker.street = pStreet;
    broker.houseNbr = pHouseNbr;
    broker.postalCode = pPostalCode;
    broker.city = pCity;
    broker.phone = pPhone;
    broker.email = pEmail;
    broker.contactName = pContactName;

    oBrokerId = BROKRSRV_CreateBroker(broker);

    if oBrokerId > 0;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//==============================================================
// CUSTOMER WRAPPERS
//==============================================================

//--------------------------------------------------------------
// GetCustomerById : Get customer by ID with scalar outputs
//--------------------------------------------------------------
dcl-proc WRAP_GetCustomerById export;
    dcl-pi *n;
        pCustId         packed(10:0) const;
        // OUTPUT parameters
        oCustType       char(3);
        oFirstName      char(50);
        oLastName       char(50);
        oNationalId     char(15);
        oBirthDate      char(10);
        oCompanyName    char(100);
        oVatNumber      char(12);
        oStreet         char(30);
        oHouseNbr       char(5);
        oPostalCode     char(7);
        oCity           char(24);
        oPhone          char(20);
        oEmail          char(100);
        oLanguage       char(2);
        oStatus         char(3);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-ds customer likeds(Customer_t);

    ERRUTIL_init();
    customer = CUSTSRV_GetCustomer(pCustId);

    if customer.custId > 0;
        oCustType = customer.custType;
        oFirstName = customer.firstName;
        oLastName = customer.lastName;
        oNationalId = customer.nationalId;
        // Convert date to ISO char(10) for iToolkit
        if customer.birthDate <> d'0001-01-01';
            oBirthDate = %char(customer.birthDate:*iso);
        else;
            oBirthDate = '';
        endif;
        oCompanyName = customer.companyName;
        oVatNumber = customer.vatNumber;
        oStreet = customer.street;
        oHouseNbr = customer.houseNbr;
        oPostalCode = customer.postalCode;
        oCity = customer.city;
        oPhone = customer.phone;
        oEmail = customer.email;
        oLanguage = customer.language;
        oStatus = customer.status;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        clear oCustType;
        clear oFirstName;
        clear oLastName;
        clear oNationalId;
        oBirthDate = '';
        clear oCompanyName;
        clear oVatNumber;
        clear oStreet;
        clear oHouseNbr;
        clear oPostalCode;
        clear oCity;
        clear oPhone;
        clear oEmail;
        clear oLanguage;
        clear oStatus;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// CreateCustomer : Create customer with scalar inputs
// Direct SQL INSERT with all parameters using RTRIM
//--------------------------------------------------------------
dcl-proc WRAP_CreateCustomer export;
    dcl-pi *n;
        pCustType       char(3) const;
        pFirstName      char(50) const;
        pLastName       char(50) const;
        pNationalId     char(15) const;
        pBirthDate      char(10) const;
        pCompanyName    char(100) const;
        pVatNumber      char(12) const;
        pStreet         char(30) const;
        pHouseNbr       char(5) const;
        pPostalCode     char(7) const;
        pCity           char(24) const;
        pCountryCode    char(3) const;
        pPhone          char(20) const;
        pEmail          char(100) const;
        pLanguage       char(2) const;
        // OUTPUT
        oCustId         packed(10:0);
        oSuccess        char(1);
        oErrorCode      char(10);
        oErrorMessage   varchar(256);
    end-pi;

    dcl-ds customer likeds(Customer_t) inz;

    ERRUTIL_init();

    customer.custType = pCustType;
    customer.firstName = pFirstName;
    customer.lastName = pLastName;
    customer.nationalId = pNationalId;
    // Convert char(10) ISO date to RPG date
    if %trim(pBirthDate) <> '' and %trim(pBirthDate) <> '1900-01-01';
        customer.birthDate = %date(%trim(pBirthDate):*iso);
    endif;
    customer.companyName = pCompanyName;
    customer.vatNumber = pVatNumber;
    customer.street = pStreet;
    customer.houseNbr = pHouseNbr;
    customer.postalCode = pPostalCode;
    customer.city = pCity;
    customer.countryCode = pCountryCode;
    customer.phone = pPhone;
    customer.email = pEmail;
    customer.language = pLanguage;

    oCustId = CUSTSRV_CreateCustomer(customer);

    if oCustId > 0;
        oSuccess = 'Y';
        oErrorCode = '';
        oErrorMessage = '';
    else;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
        oErrorMessage = ERRUTIL_getLastError();
    endif;
end-proc;

//--------------------------------------------------------------
// ListCustomers : List customers and return JSON array
//--------------------------------------------------------------
dcl-proc WRAP_ListCustomers export;
    dcl-pi *n;
        pStatus         char(3) const;
        // OUTPUT - JSON array of customers
        oJsonData       varchar(32000);
        oCount          packed(10:0);
        oSuccess        char(1);
    end-pi;

    dcl-s statusFilter char(3);
    dcl-s jsonRow varchar(800);
    dcl-s custId packed(10:0);
    dcl-s custType char(3);
    dcl-s firstName char(50);
    dcl-s lastName char(50);
    dcl-s nationalId char(15);
    dcl-s companyName char(100);
    dcl-s street char(30);
    dcl-s postalCode char(7);
    dcl-s city char(24);
    dcl-s phone char(20);
    dcl-s email char(100);
    dcl-s language char(2);
    dcl-s custStatus char(3);
    dcl-s firstRow ind inz(*on);

    exec sql
        DECLARE C_CUSTOMERS CURSOR FOR
        SELECT CUST_ID, CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
               COMPANY_NAME, STREET, POSTAL_CODE, CITY, PHONE, EMAIL,
               LANGUAGE, STATUS
        FROM MRS1.CUSTOMER
        WHERE :statusFilter = '' OR STATUS = :statusFilter
        ORDER BY LAST_NAME, FIRST_NAME;

    monitor;
        statusFilter = %trim(pStatus);
        oJsonData = '[';
        oCount = 0;

        exec sql OPEN C_CUSTOMERS;

        // SQLCODE 8013 = PUB400 licensing - ignore and return empty
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            oJsonData = '[]';
            oSuccess = 'Y';
            return;
        endif;

        exec sql
            FETCH C_CUSTOMERS INTO :custId, :custType, :firstName, :lastName,
                :nationalId, :companyName, :street, :postalCode, :city,
                :phone, :email, :language, :custStatus;

        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                oJsonData = %trim(oJsonData) + ',';
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

            oJsonData = %trim(oJsonData) + jsonRow;
            oCount += 1;

            exec sql
                FETCH C_CUSTOMERS INTO :custId, :custType, :firstName, :lastName,
                    :nationalId, :companyName, :street, :postalCode, :city,
                    :phone, :email, :language, :custStatus;
        enddo;

        exec sql CLOSE C_CUSTOMERS;

        oJsonData = %trim(oJsonData) + ']';
        oSuccess = 'Y';

    on-error;
        oJsonData = '[]';
        oCount = 0;
        oSuccess = 'N';
    endmon;
end-proc;

//--------------------------------------------------------------
// DeleteCustomer : Soft delete customer (set status to INA)
//--------------------------------------------------------------
dcl-proc WRAP_DeleteCustomer export;
    dcl-pi *n;
        pCustId         packed(10:0) const;
        // OUTPUT
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-s success ind;

    ERRUTIL_init();

    success = CUSTSRV_DeleteCustomer(pCustId);

    if success;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// GetCustomerByEmail : Get customer by email address
//--------------------------------------------------------------
dcl-proc WRAP_GetCustomerByEmail export;
    dcl-pi *n;
        pEmail          char(100) const;
        // OUTPUT parameters
        oCustId         packed(10:0);
        oCustType       char(3);
        oFirstName      char(50);
        oLastName       char(50);
        oNationalId     char(15);
        oCompanyName    char(100);
        oStreet         char(30);
        oPostalCode     char(7);
        oCity           char(24);
        oPhone          char(20);
        oEmail          char(100);
        oLanguage       char(2);
        oStatus         char(3);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-s emailFilter char(100);

    monitor;
        emailFilter = %trim(pEmail);

        exec sql
            SELECT CUST_ID, CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
                   COMPANY_NAME, STREET, POSTAL_CODE, CITY, PHONE, EMAIL,
                   LANGUAGE, STATUS
            INTO :oCustId, :oCustType, :oFirstName, :oLastName, :oNationalId,
                 :oCompanyName, :oStreet, :oPostalCode, :oCity, :oPhone,
                 :oEmail, :oLanguage, :oStatus
            FROM MRS1.CUSTOMER
            WHERE EMAIL = :emailFilter;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            oSuccess = 'Y';
            oErrorCode = '';
        elseif sqlcode = 100;
            clear oCustId;
            clear oCustType;
            clear oFirstName;
            clear oLastName;
            clear oNationalId;
            clear oCompanyName;
            clear oStreet;
            clear oPostalCode;
            clear oCity;
            clear oPhone;
            clear oEmail;
            clear oLanguage;
            clear oStatus;
            oSuccess = 'N';
            oErrorCode = 'DB001';
        else;
            oSuccess = 'N';
            oErrorCode = 'DB004';
        endif;

    on-error;
        oSuccess = 'N';
        oErrorCode = 'EXEC_ERR';
    endmon;
end-proc;

//--------------------------------------------------------------
// GetCustomerContracts : Get contracts for a customer (JSON)
//--------------------------------------------------------------
dcl-proc WRAP_GetCustomerContracts export;
    dcl-pi *n;
        pCustId         packed(10:0) const;
        // OUTPUT - JSON array of contracts
        oJsonData       varchar(32000);
        oCount          packed(10:0);
        oSuccess        char(1);
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
    dcl-s firstRow ind inz(*on);
    dcl-s startDateStr char(10);
    dcl-s endDateStr char(10);

    exec sql
        DECLARE C_CUST_CONTRACTS CURSOR FOR
        SELECT CONT_ID, CONT_REFERENCE, BROKER_ID, PRODUCT_ID,
               START_DATE, END_DATE, PREMIUM_AMT, STATUS
        FROM MRS1.CONTRACT
        WHERE CUST_ID = :pCustId
        ORDER BY START_DATE DESC;

    monitor;
        oJsonData = '[';
        oCount = 0;

        exec sql OPEN C_CUST_CONTRACTS;

        exec sql
            FETCH C_CUST_CONTRACTS INTO :contId, :contReference, :brokerId,
                :productId, :startDate, :endDate, :premiumAmt, :contStatus;

        // Also handle SQLCODE 8013 (PUB400 licensing)
        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                oJsonData = %trim(oJsonData) + ',';
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

            oJsonData = %trim(oJsonData) + jsonRow;
            oCount += 1;

            exec sql
                FETCH C_CUST_CONTRACTS INTO :contId, :contReference, :brokerId,
                    :productId, :startDate, :endDate, :premiumAmt, :contStatus;
        enddo;

        exec sql CLOSE C_CUST_CONTRACTS;

        oJsonData = %trim(oJsonData) + ']';
        oSuccess = 'Y';

    on-error;
        oJsonData = '[]';
        oCount = 0;
        oSuccess = 'N';
    endmon;
end-proc;

//==============================================================
// PRODUCT WRAPPERS
//==============================================================

//--------------------------------------------------------------
// ListProducts : List all products and return JSON array
//--------------------------------------------------------------
dcl-proc WRAP_ListProducts export;
    dcl-pi *n;
        pStatus         char(3) const;
        // OUTPUT - JSON array of products
        oJsonData       varchar(32000);
        oCount          packed(10:0);
        oSuccess        char(1);
    end-pi;

    dcl-s statusFilter char(3);
    dcl-s jsonRow varchar(500);
    dcl-s productId packed(10:0);
    dcl-s productCode char(10);
    dcl-s productName char(50);
    dcl-s productType char(3);
    dcl-s basePremium packed(9:2);
    dcl-s coverageLimit packed(11:2);
    dcl-s minThreshold packed(9:2);
    dcl-s waitingMonths packed(2:0);
    dcl-s prodStatus char(3);
    dcl-s firstRow ind inz(*on);

    exec sql
        DECLARE C_PRODUCTS CURSOR FOR
        SELECT PRODUCT_ID, PRODUCT_CODE, PRODUCT_NAME, PRODUCT_TYPE,
               BASE_PREMIUM, COVERAGE_LIMIT, MIN_THRESHOLD, WAITING_MONTHS, STATUS
        FROM MRS1.PRODUCT
        WHERE :statusFilter = '' OR STATUS = :statusFilter
        ORDER BY PRODUCT_NAME;

    monitor;
        statusFilter = %trim(pStatus);
        oJsonData = '[';
        oCount = 0;

        exec sql OPEN C_PRODUCTS;

        exec sql
            FETCH C_PRODUCTS INTO :productId, :productCode, :productName,
                :productType, :basePremium, :coverageLimit, :minThreshold,
                :waitingMonths, :prodStatus;

        // Also handle SQLCODE 8013 (PUB400 licensing)
        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                oJsonData = %trim(oJsonData) + ',';
            endif;
            firstRow = *off;

            jsonRow = '{"PRODUCT_ID":' + %char(productId) +
                ',"PRODUCT_CODE":"' + %trim(productCode) +
                '","PRODUCT_NAME":"' + %trim(productName) +
                '","PRODUCT_TYPE":"' + %trim(productType) +
                '","BASE_PREMIUM":' + %char(basePremium) +
                ',"COVERAGE_LIMIT":' + %char(coverageLimit) +
                ',"MIN_THRESHOLD":' + %char(minThreshold) +
                ',"WAITING_MONTHS":' + %char(waitingMonths) +
                ',"STATUS":"' + %trim(prodStatus) + '"}';

            oJsonData = %trim(oJsonData) + jsonRow;
            oCount += 1;

            exec sql
                FETCH C_PRODUCTS INTO :productId, :productCode, :productName,
                    :productType, :basePremium, :coverageLimit, :minThreshold,
                    :waitingMonths, :prodStatus;
        enddo;

        exec sql CLOSE C_PRODUCTS;

        oJsonData = %trim(oJsonData) + ']';
        oSuccess = 'Y';

    on-error;
        oJsonData = '[]';
        oCount = 0;
        oSuccess = 'N';
    endmon;
end-proc;

//--------------------------------------------------------------
// GetProductByCode : Get product by code
//--------------------------------------------------------------
dcl-proc WRAP_GetProductByCode export;
    dcl-pi *n;
        pProductCode    char(10) const;
        // OUTPUT
        oProductId      packed(10:0);
        oProductName    char(50);
        oProductType    char(3);
        oBasePremium    packed(9:2);
        oCoverageLimit  packed(11:2);
        oMinThreshold   packed(9:2);
        oWaitingMonths  packed(2:0);
        oStatus         char(3);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-s codeFilter char(10);

    monitor;
        codeFilter = %trim(pProductCode);

        exec sql
            SELECT PRODUCT_ID, PRODUCT_NAME, PRODUCT_TYPE, BASE_PREMIUM,
                   COVERAGE_LIMIT, MIN_THRESHOLD, WAITING_MONTHS, STATUS
            INTO :oProductId, :oProductName, :oProductType, :oBasePremium,
                 :oCoverageLimit, :oMinThreshold, :oWaitingMonths, :oStatus
            FROM MRS1.PRODUCT
            WHERE PRODUCT_CODE = :codeFilter;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            oSuccess = 'Y';
            oErrorCode = '';
        elseif sqlcode = 100;
            oProductId = 0;
            clear oProductName;
            clear oProductType;
            oBasePremium = 0;
            oCoverageLimit = 0;
            oMinThreshold = 0;
            oWaitingMonths = 0;
            clear oStatus;
            oSuccess = 'N';
            oErrorCode = 'DB001';
        else;
            oSuccess = 'N';
            oErrorCode = 'DB004';
        endif;

    on-error;
        oSuccess = 'N';
        oErrorCode = 'EXEC_ERR';
    endmon;
end-proc;

//--------------------------------------------------------------
// GetProductGuarantees : Get guarantees for a product (JSON)
//--------------------------------------------------------------
dcl-proc WRAP_GetProductGuarantees export;
    dcl-pi *n;
        pProductId      packed(10:0) const;
        // OUTPUT - JSON array of guarantees
        oJsonData       varchar(32000);
        oCount          packed(10:0);
        oSuccess        char(1);
    end-pi;

    dcl-s jsonRow varchar(500);
    dcl-s guaranteeCode char(10);
    dcl-s guaranteeName char(50);
    dcl-s description char(200);
    dcl-s coveragePct packed(5:2);
    dcl-s maxAmount packed(11:2);
    dcl-s waitingDays packed(5:0);
    dcl-s firstRow ind inz(*on);

    exec sql
        DECLARE C_PROD_GUARANTEES CURSOR FOR
        SELECT PG.GUARANTEE_CODE, G.GUARANTEE_NAME, G.DESCRIPTION,
               PG.COVERAGE_PCT, PG.MAX_AMOUNT, PG.WAITING_DAYS
        FROM MRS1.PRODUCT_GUARANTEE PG
        JOIN MRS1.GUARANTEE G ON PG.GUARANTEE_CODE = G.GUARANTEE_CODE
        WHERE PG.PRODUCT_ID = :pProductId
        ORDER BY G.GUARANTEE_NAME;

    monitor;
        oJsonData = '[';
        oCount = 0;

        exec sql OPEN C_PROD_GUARANTEES;

        exec sql
            FETCH C_PROD_GUARANTEES INTO :guaranteeCode, :guaranteeName,
                :description, :coveragePct, :maxAmount, :waitingDays;

        // Also handle SQLCODE 8013 (PUB400 licensing)
        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                oJsonData = %trim(oJsonData) + ',';
            endif;
            firstRow = *off;

            jsonRow = '{"GUARANTEE_CODE":"' + %trim(guaranteeCode) +
                '","GUARANTEE_NAME":"' + %trim(guaranteeName) +
                '","DESCRIPTION":"' + %trim(description) +
                '","COVERAGE_PCT":' + %char(coveragePct) +
                ',"MAX_AMOUNT":' + %char(maxAmount) +
                ',"WAITING_DAYS":' + %char(waitingDays) + '}';

            oJsonData = %trim(oJsonData) + jsonRow;
            oCount += 1;

            exec sql
                FETCH C_PROD_GUARANTEES INTO :guaranteeCode, :guaranteeName,
                    :description, :coveragePct, :maxAmount, :waitingDays;
        enddo;

        exec sql CLOSE C_PROD_GUARANTEES;

        oJsonData = %trim(oJsonData) + ']';
        oSuccess = 'Y';

    on-error;
        oJsonData = '[]';
        oCount = 0;
        oSuccess = 'N';
    endmon;
end-proc;

//--------------------------------------------------------------
// GetProductById : Get product by ID with scalar outputs
//--------------------------------------------------------------
dcl-proc WRAP_GetProductById export;
    dcl-pi *n;
        pProductId      packed(10:0) const;
        // OUTPUT
        oProductCode    char(10);
        oProductName    char(50);
        oProductType    char(3);
        oBasePremium    packed(9:2);
        oCoverageLimit  packed(11:2);
        oMinThreshold   packed(9:2);
        oWaitingMonths  packed(2:0);
        oStatus         char(3);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-ds product likeds(Product_t);

    ERRUTIL_init();
    product = PRODSRV_GetProduct(pProductId);

    if product.productId > 0;
        oProductCode = product.productCode;
        oProductName = product.productName;
        oProductType = product.productType;
        oBasePremium = product.basePremium;
        oCoverageLimit = product.coverageLimit;
        oMinThreshold = product.minThreshold;
        oWaitingMonths = product.waitingMonths;
        oStatus = product.status;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        clear oProductCode;
        clear oProductName;
        clear oProductType;
        oBasePremium = 0;
        oCoverageLimit = 0;
        oMinThreshold = 0;
        oWaitingMonths = 0;
        clear oStatus;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// CalculatePremium : Calculate premium (scalar params already)
//--------------------------------------------------------------
dcl-proc WRAP_CalculatePremium export;
    dcl-pi *n;
        pProductCode    char(10) const;
        pVehiclesCount  packed(2:0) const;
        pPayFrequency   char(1) const;
        // OUTPUT
        oBasePremium    packed(9:2);
        oVehicleAddon   packed(9:2);
        oFreqSurcharge  packed(9:2);
        oTotalPremium   packed(9:2);
        oSuccess        char(1);
    end-pi;

    dcl-c VEHICLE_ADDON 25.00;
    dcl-c FREQ_MONTHLY 0.05;
    dcl-c FREQ_QUARTERLY 0.02;

    // Initialize outputs
    oBasePremium = 0;
    oVehicleAddon = 0;
    oFreqSurcharge = 0;
    oTotalPremium = 0;
    oSuccess = 'N';

    monitor;
        oBasePremium = PRODSRV_CalculateBasePremium(pProductCode: 0);
        oVehicleAddon = pVehiclesCount * VEHICLE_ADDON;

        // Calculate frequency surcharge
        select;
            when pPayFrequency = 'M';
                oFreqSurcharge = (oBasePremium + oVehicleAddon) * FREQ_MONTHLY;
            when pPayFrequency = 'Q';
                oFreqSurcharge = (oBasePremium + oVehicleAddon) * FREQ_QUARTERLY;
            other;
                oFreqSurcharge = 0;
        endsl;

        oTotalPremium = oBasePremium + oVehicleAddon + oFreqSurcharge;
        oSuccess = 'Y';

    on-error;
        oSuccess = 'N';
    endmon;
end-proc;

//==============================================================
// CONTRACT WRAPPERS
//==============================================================

//--------------------------------------------------------------
// GetContractById : Get contract by ID
//--------------------------------------------------------------
dcl-proc WRAP_GetContractById export;
    dcl-pi *n;
        pContId         packed(10:0) const;
        // OUTPUT
        oContReference  char(25);
        oCustId         packed(10:0);
        oBrokerId       packed(10:0);
        oProductId      packed(10:0);
        oStartDate      char(10);
        oEndDate        char(10);
        oVehiclesCount  packed(2:0);
        oPayFrequency   char(1);
        oPremiumAmt     packed(9:2);
        oAutoRenew      char(1);
        oStatus         char(3);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-ds contract likeds(Contract_t);

    ERRUTIL_init();
    contract = CONTSRV_GetContract(pContId);

    if contract.contId > 0;
        oContReference = contract.contReference;
        oCustId = contract.custId;
        oBrokerId = contract.brokerId;
        oProductId = contract.productId;
        // Convert dates to ISO char(10) for iToolkit
        if contract.startDate <> d'0001-01-01';
            oStartDate = %char(contract.startDate:*iso);
        else;
            oStartDate = '';
        endif;
        if contract.endDate <> d'0001-01-01';
            oEndDate = %char(contract.endDate:*iso);
        else;
            oEndDate = '';
        endif;
        oVehiclesCount = contract.vehiclesCount;
        oPayFrequency = contract.payFrequency;
        oPremiumAmt = contract.premiumAmt;
        oAutoRenew = contract.autoRenew;
        oStatus = contract.status;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        clear oContReference;
        oCustId = 0;
        oBrokerId = 0;
        oProductId = 0;
        oStartDate = '';
        oEndDate = '';
        oVehiclesCount = 0;
        clear oPayFrequency;
        oPremiumAmt = 0;
        clear oAutoRenew;
        clear oStatus;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// CreateContract : Create contract with scalar inputs
//--------------------------------------------------------------
dcl-proc WRAP_CreateContract export;
    dcl-pi *n;
        pCustId         packed(10:0) const;
        pBrokerId       packed(10:0) const;
        pProductId      packed(10:0) const;
        pStartDate      char(10) const;
        pVehiclesCount  packed(2:0) const;
        pPayFrequency   char(1) const;
        pAutoRenewal    char(1) const;
        // OUTPUT
        oContId         packed(10:0);
        oContReference  char(25);
        oTotalPremium   packed(9:2);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-ds contract likeds(Contract_t) inz;
    dcl-s newContId packed(10:0);
    dcl-s productCode char(10);

    ERRUTIL_init();

    // Get product code from product ID for premium calculation
    exec sql SELECT PRODUCT_CODE INTO :productCode FROM PRODUCT WHERE PRODUCT_ID = :pProductId;

    contract.custId = pCustId;
    contract.brokerId = pBrokerId;
    contract.productId = pProductId;
    // Convert char(10) ISO date string to RPG date
    contract.startDate = %date(%trim(pStartDate):*iso);
    contract.vehiclesCount = pVehiclesCount;
    contract.payFrequency = pPayFrequency;
    contract.autoRenew = pAutoRenewal;
    // Calculate premium before insert
    contract.premiumAmt = CONTSRV_CalculatePremium(productCode: pVehiclesCount: pPayFrequency);

    newContId = CONTSRV_CreateContract(contract);

    if newContId > 0;
        // Get the created contract to return reference and premium
        contract = CONTSRV_GetContract(newContId);
        oContId = newContId;
        oContReference = contract.contReference;
        oTotalPremium = contract.premiumAmt;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        oContId = 0;
        clear oContReference;
        oTotalPremium = 0;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// ListContracts : List contracts and return JSON array
// Uses cursor-based approach for compatibility
//--------------------------------------------------------------
dcl-proc WRAP_ListContracts export;
    dcl-pi *n;
        pStatus         char(3) const;
        // OUTPUT - JSON array of contracts
        oJsonData       varchar(32000);
        oCount          packed(10:0);
        oSuccess        char(1);
    end-pi;

    dcl-s statusFilter char(3);
    dcl-s jsonRow varchar(500);
    dcl-s contId packed(10:0);
    dcl-s contReference char(25);
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
    dcl-s firstRow ind inz(*on);
    dcl-s startDateStr char(10);
    dcl-s endDateStr char(10);

    // DECLARE must be outside MONITOR block
    exec sql
        DECLARE C_CONTRACTS CURSOR FOR
        SELECT CONT_ID, CONT_REFERENCE, CUST_ID, BROKER_ID,
               PRODUCT_ID, START_DATE, END_DATE, VEHICLES_COUNT,
               PAY_FREQUENCY, PREMIUM_AMT, AUTO_RENEW, STATUS
        FROM MRS1.CONTRACT
        WHERE :statusFilter = '' OR STATUS = :statusFilter
        ORDER BY START_DATE DESC;

    monitor;
        statusFilter = %trim(pStatus);
        oJsonData = '[';
        oCount = 0;

        exec sql OPEN C_CONTRACTS;

        exec sql
            FETCH C_CONTRACTS INTO :contId, :contReference, :custId,
                :brokerId, :productId, :startDate, :endDate,
                :vehiclesCount, :payFrequency, :premiumAmt, :autoRenew, :contStatus;

        // Also handle SQLCODE 8013 (PUB400 licensing)
        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                oJsonData = %trim(oJsonData) + ',';
            endif;
            firstRow = *off;

            // Format dates
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

            oJsonData = %trim(oJsonData) + jsonRow;
            oCount += 1;

            exec sql
                FETCH C_CONTRACTS INTO :contId, :contReference, :custId,
                    :brokerId, :productId, :startDate, :endDate,
                    :vehiclesCount, :payFrequency, :premiumAmt, :autoRenew, :contStatus;
        enddo;

        exec sql CLOSE C_CONTRACTS;

        oJsonData = %trim(oJsonData) + ']';
        oSuccess = 'Y';

    on-error;
        oJsonData = '[]';
        oCount = 0;
        oSuccess = 'N';
    endmon;
end-proc;

//--------------------------------------------------------------
// DeleteContract : Soft delete contract (set status to CLS)
//--------------------------------------------------------------
dcl-proc WRAP_DeleteContract export;
    dcl-pi *n;
        pContId         packed(10:0) const;
        // OUTPUT
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    ERRUTIL_init();

    monitor;
        exec sql
            UPDATE MRS1.CONTRACT
            SET STATUS = 'CLS',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CONT_ID = :pContId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if SQLCODE = 0 or SQLCODE = 8013 or SQLCODE = -8013;
            oSuccess = 'Y';
            oErrorCode = '';
        else;
            oSuccess = 'N';
            oErrorCode = 'DB004';
            ERRUTIL_addErrorCode('DB004');
        endif;

    on-error;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endmon;
end-proc;

//==============================================================
// CLAIM WRAPPERS
//==============================================================

//--------------------------------------------------------------
// ListClaims : List claims and return JSON array
//--------------------------------------------------------------
dcl-proc WRAP_ListClaims export;
    dcl-pi *n;
        pStatus         char(3) const;
        // OUTPUT - JSON array of claims
        oJsonData       varchar(32000);
        oCount          packed(10:0);
        oSuccess        char(1);
    end-pi;

    dcl-s statusFilter char(3);
    dcl-s jsonRow varchar(600);
    dcl-s claimId packed(10:0);
    dcl-s claimReference char(15);
    dcl-s fileReference char(15);
    dcl-s contId packed(10:0);
    dcl-s guaranteeCode char(10);
    dcl-s declarationDate date;
    dcl-s incidentDate date;
    dcl-s claimedAmount packed(11:2);
    dcl-s approvedAmount packed(11:2);
    dcl-s claimStatus char(3);
    dcl-s resolutionType char(3);
    dcl-s firstRow ind inz(*on);
    dcl-s declDateStr char(10);
    dcl-s incDateStr char(10);

    exec sql
        DECLARE C_CLAIMS CURSOR FOR
        SELECT CLAIM_ID, CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
               GUARANTEE_CODE, DECLARATION_DATE, INCIDENT_DATE,
               CLAIMED_AMOUNT, APPROVED_AMOUNT, STATUS, RESOLUTION_TYPE
        FROM MRS1.CLAIM
        WHERE :statusFilter = '' OR STATUS = :statusFilter
        ORDER BY DECLARATION_DATE DESC;

    monitor;
        statusFilter = %trim(pStatus);
        oJsonData = '[';
        oCount = 0;

        exec sql OPEN C_CLAIMS;

        exec sql
            FETCH C_CLAIMS INTO :claimId, :claimReference, :fileReference,
                :contId, :guaranteeCode, :declarationDate, :incidentDate,
                :claimedAmount, :approvedAmount, :claimStatus, :resolutionType;

        // Also handle SQLCODE 8013 (PUB400 licensing)
        dow sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            if not firstRow;
                oJsonData = %trim(oJsonData) + ',';
            endif;
            firstRow = *off;

            declDateStr = %char(declarationDate:*iso);
            incDateStr = %char(incidentDate:*iso);

            jsonRow = '{"CLAIM_ID":' + %char(claimId) +
                ',"CLAIM_REFERENCE":"' + %trim(claimReference) +
                '","FILE_REFERENCE":"' + %trim(fileReference) +
                '","CONT_ID":' + %char(contId) +
                ',"GUARANTEE_CODE":"' + %trim(guaranteeCode) +
                '","DECLARATION_DATE":"' + declDateStr +
                '","INCIDENT_DATE":"' + incDateStr +
                '","CLAIMED_AMOUNT":' + %char(claimedAmount) +
                ',"APPROVED_AMOUNT":' + %char(approvedAmount) +
                ',"STATUS":"' + %trim(claimStatus) +
                '","RESOLUTION_TYPE":"' + %trim(resolutionType) + '"}';

            oJsonData = %trim(oJsonData) + jsonRow;
            oCount += 1;

            exec sql
                FETCH C_CLAIMS INTO :claimId, :claimReference, :fileReference,
                    :contId, :guaranteeCode, :declarationDate, :incidentDate,
                    :claimedAmount, :approvedAmount, :claimStatus, :resolutionType;
        enddo;

        exec sql CLOSE C_CLAIMS;

        oJsonData = %trim(oJsonData) + ']';
        oSuccess = 'Y';

    on-error;
        oJsonData = '[]';
        oCount = 0;
        oSuccess = 'N';
    endmon;
end-proc;

//--------------------------------------------------------------
// GetClaimById : Get claim by ID
//--------------------------------------------------------------
dcl-proc WRAP_GetClaimById export;
    dcl-pi *n;
        pClaimId        packed(10:0) const;
        // OUTPUT
        oClaimReference char(15);
        oFileReference  char(15);
        oContId         packed(10:0);
        oGuaranteeCode  char(10);
        oDeclarationDate char(10);
        oIncidentDate   char(10);
        oClaimedAmount  packed(11:2);
        oApprovedAmount packed(11:2);
        oStatus         char(3);
        oResolutionType char(3);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-ds claim likeds(Claim_t);

    ERRUTIL_init();
    claim = CLAIMSRV_GetClaim(pClaimId);

    if claim.claimId > 0;
        oClaimReference = claim.claimReference;
        oFileReference = claim.fileReference;
        oContId = claim.contId;
        oGuaranteeCode = claim.guaranteeCode;
        // Convert dates to ISO char(10) for iToolkit
        if claim.declarationDate <> d'0001-01-01';
            oDeclarationDate = %char(claim.declarationDate:*iso);
        else;
            oDeclarationDate = '';
        endif;
        if claim.incidentDate <> d'0001-01-01';
            oIncidentDate = %char(claim.incidentDate:*iso);
        else;
            oIncidentDate = '';
        endif;
        oClaimedAmount = claim.claimedAmount;
        oApprovedAmount = claim.approvedAmount;
        oStatus = claim.status;
        oResolutionType = claim.resolutionType;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        clear oClaimReference;
        clear oFileReference;
        oContId = 0;
        clear oGuaranteeCode;
        oDeclarationDate = '';
        oIncidentDate = '';
        oClaimedAmount = 0;
        oApprovedAmount = 0;
        clear oStatus;
        clear oResolutionType;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// CreateClaim : Create claim with scalar inputs
//--------------------------------------------------------------
dcl-proc WRAP_CreateClaim export;
    dcl-pi *n;
        pContId         packed(10:0) const;
        pGuaranteeCode  char(10) const;
        pIncidentDate   char(10) const;
        pClaimedAmount  packed(11:2) const;
        pDescription    char(500) const;
        // OUTPUT
        oClaimId        packed(10:0);
        oClaimReference char(15);
        oFileReference  char(15);
        oSuccess        char(1);
        oErrorCode      char(10);
    end-pi;

    dcl-ds claim likeds(Claim_t) inz;
    dcl-s newClaimId packed(10:0);

    ERRUTIL_init();

    claim.contId = pContId;
    claim.guaranteeCode = pGuaranteeCode;
    // Convert char(10) ISO date to RPG date
    if %trim(pIncidentDate) <> '';
        claim.incidentDate = %date(%trim(pIncidentDate):*iso);
    else;
        claim.incidentDate = %date();
    endif;
    claim.claimedAmount = pClaimedAmount;
    claim.description = pDescription;

    newClaimId = CLAIMSRV_CreateClaim(claim);

    if newClaimId > 0;
        claim = CLAIMSRV_GetClaim(newClaimId);
        oClaimId = newClaimId;
        oClaimReference = claim.claimReference;
        oFileReference = claim.fileReference;
        oSuccess = 'Y';
        oErrorCode = '';
    else;
        oClaimId = 0;
        clear oClaimReference;
        clear oFileReference;
        oSuccess = 'N';
        oErrorCode = ERRUTIL_getLastErrorCode();
    endif;
end-proc;

//--------------------------------------------------------------
// ValidateClaim : Check if claim is valid
// Uses existing CLAIMSRV procedures for validation
//--------------------------------------------------------------
dcl-proc WRAP_ValidateClaim export;
    dcl-pi *n;
        pContId         packed(10:0) const;
        pGuaranteeCode  char(10) const;
        pClaimedAmount  packed(11:2) const;
        pIncidentDate   char(10) const;
        // OUTPUT
        oIsValid        char(1);
        oIsCovered      char(1);
        oWaitingPassed  char(1);
        oAboveThreshold char(1);
        oWaitingDays    packed(5:0);
        oErrorCode      char(10);
    end-pi;

    dcl-s isCovered ind;
    dcl-s inWaiting ind;
    dcl-s incDate date;

    ERRUTIL_init();

    // Convert char(10) ISO date to RPG date
    if %trim(pIncidentDate) <> '';
        incDate = %date(%trim(pIncidentDate):*iso);
    else;
        incDate = %date();
    endif;

    // Check if guarantee is covered by the contract's product
    isCovered = CLAIMSRV_IsCovered(pContId: pGuaranteeCode);
    oIsCovered = 'N';
    if isCovered;
        oIsCovered = 'Y';
    endif;

    // Check if still in waiting period
    inWaiting = CLAIMSRV_IsInWaitingPeriod(pContId: pGuaranteeCode: incDate);
    oWaitingPassed = 'Y';
    oWaitingDays = 0;
    if inWaiting;
        oWaitingPassed = 'N';
        // Calculate remaining waiting days (simplified)
        oWaitingDays = 30; // Default - actual calc would need more info
    endif;

    // Check threshold (EUR 350 minimum)
    oAboveThreshold = 'N';
    if pClaimedAmount >= MIN_CLAIM_THRESHOLD;
        oAboveThreshold = 'Y';
    endif;

    // Overall validation
    oIsValid = 'N';
    if isCovered and not inWaiting and pClaimedAmount >= MIN_CLAIM_THRESHOLD;
        oIsValid = 'Y';
    endif;

    oErrorCode = ERRUTIL_getLastErrorCode();
end-proc;

//==============================================================
// DASHBOARD WRAPPERS
//==============================================================

//--------------------------------------------------------------
// GetDashboardStats : Get KPI statistics
//--------------------------------------------------------------
dcl-proc WRAP_GetDashboardStats export;
    dcl-pi *n;
        // OUTPUT
        oTotalBrokers       packed(10:0);
        oActiveBrokers      packed(10:0);
        oTotalCustomers     packed(10:0);
        oActiveCustomers    packed(10:0);
        oTotalContracts     packed(10:0);
        oActiveContracts    packed(10:0);
        oTotalClaims        packed(10:0);
        oAmicableClaims     packed(10:0);
        oTribunalClaims     packed(10:0);
        oAmicableRate       packed(5:2);
        oSuccess            char(1);
    end-pi;

    monitor;
        // Broker stats
        exec sql
            SELECT COUNT(*), SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END)
            INTO :oTotalBrokers, :oActiveBrokers
            FROM MRS1.BROKER;

        // Customer stats
        exec sql
            SELECT COUNT(*), SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END)
            INTO :oTotalCustomers, :oActiveCustomers
            FROM MRS1.CUSTOMER;

        // Contract stats
        exec sql
            SELECT COUNT(*), SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END)
            INTO :oTotalContracts, :oActiveContracts
            FROM MRS1.CONTRACT;

        // Claim stats
        exec sql
            SELECT COUNT(*),
                   SUM(CASE WHEN RESOLUTION_TYPE = 'AMI' THEN 1 ELSE 0 END),
                   SUM(CASE WHEN RESOLUTION_TYPE = 'TRI' THEN 1 ELSE 0 END)
            INTO :oTotalClaims, :oAmicableClaims, :oTribunalClaims
            FROM MRS1.CLAIM;

        // Calculate amicable rate (target: 79%)
        if (oAmicableClaims + oTribunalClaims) > 0;
            oAmicableRate = (oAmicableClaims * 100) /
                            (oAmicableClaims + oTribunalClaims);
        else;
            oAmicableRate = 0;
        endif;

        oSuccess = 'Y';

    on-error;
        oSuccess = 'N';
    endmon;
end-proc;

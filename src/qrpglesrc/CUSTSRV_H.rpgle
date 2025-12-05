**free
// ============================================================
// CUSTSRV_H - Customer Service Copybook
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Data structures and prototypes for CUSTSRV module.
// TELEBIB2 alignment: CivilStatusCode, BusinessCodeNace, Address
// ============================================================

//==============================================================
// Customer Data Structure
//==============================================================
dcl-ds Customer_t qualified template;
    custId          packed(10:0);
    custType        char(3);            // IND/BUS
    // Individual fields
    firstName       varchar(50);
    lastName        varchar(50);
    nationalId      char(15);           // Belgian NRN: 00.00.00-000.00
    civilStatus     char(3);            // CivilStatusCode (TELEBIB2)
    birthDate       date;
    // Business fields
    companyName     varchar(100);
    vatNumber       char(12);           // Belgian VAT: BE0123456789
    naceCode        char(5);            // BusinessCodeNace (TELEBIB2)
    // Address (TELEBIB2 ADR segment)
    street          varchar(30);        // X002
    houseNbr        char(5);            // X003
    boxNbr          char(4);            // X004
    postalCode      char(7);            // X006
    city            varchar(24);        // X007
    countryCode     char(3);            // X008
    // Contact
    phone           varchar(20);
    email           varchar(100);
    language        char(2);            // FR/NL/DE
    // Status
    status          char(3);            // ACT/INA/SUS
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;

//==============================================================
// Customer Filter Data Structure
//==============================================================
dcl-ds CustomerFilter_t qualified template;
    custType        char(3);
    lastName        varchar(50);
    companyName     varchar(100);
    city            varchar(24);
    status          char(3);
end-ds;

//==============================================================
// Civil Status Constants
//==============================================================
dcl-c CIVIL_SINGLE 'SGL';
dcl-c CIVIL_MARRIED 'MAR';
dcl-c CIVIL_COHABITING 'COH';
dcl-c CIVIL_DIVORCED 'DIV';
dcl-c CIVIL_WIDOWED 'WID';

//==============================================================
// Procedure Prototypes
//==============================================================

// CRUD Operations
dcl-pr CreateCustomer packed(10:0) extproc('CUSTSRV_CreateCustomer');
    pCustomer likeds(Customer_t) const;
end-pr;

dcl-pr GetCustomer likeds(Customer_t) extproc('CUSTSRV_GetCustomer');
    pCustId packed(10:0) const;
end-pr;

dcl-pr UpdateCustomer ind extproc('CUSTSRV_UpdateCustomer');
    pCustomer likeds(Customer_t) const;
end-pr;

dcl-pr DeleteCustomer ind extproc('CUSTSRV_DeleteCustomer');
    pCustId packed(10:0) const;
end-pr;

dcl-pr ListCustomers int(10) extproc('CUSTSRV_ListCustomers');
    pFilter likeds(CustomerFilter_t) const;
end-pr;

// Validation
dcl-pr IsValidCustomer ind extproc('CUSTSRV_IsValidCustomer');
    pCustomer likeds(Customer_t) const;
end-pr;

dcl-pr IsValidEmail ind extproc('CUSTSRV_IsValidEmail');
    pEmail varchar(100) const;
end-pr;

dcl-pr IsValidVatNumber ind extproc('CUSTSRV_IsValidVatNumber');
    pVatNumber char(12) const;
end-pr;

dcl-pr IsValidNationalId ind extproc('CUSTSRV_IsValidNationalId');
    pNationalId char(15) const;
end-pr;

dcl-pr IsValidPostalCode ind extproc('CUSTSRV_IsValidPostalCode');
    pPostalCode char(7) const;
end-pr;

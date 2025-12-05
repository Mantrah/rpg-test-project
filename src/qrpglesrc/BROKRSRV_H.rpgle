**free
// ============================================================
// BROKRSRV_H - Broker Service Copybook
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Data structures and prototypes for BROKRSRV module.
// TELEBIB2 alignment: AgencyCode, Address segments (X002-X008)
// ============================================================

//==============================================================
// Broker Data Structure
//==============================================================
dcl-ds Broker_t qualified template;
    brokerId        packed(10:0);
    brokerCode      char(10);           // AgencyCode (TELEBIB2)
    companyName     varchar(100);
    vatNumber       char(12);           // Belgian VAT: BE0123456789
    fsmaNumber      char(10);           // FSMA registration
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
    contactName     varchar(100);
    // Status
    status          char(3);            // ACT/INA/SUS
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;

//==============================================================
// Broker Filter Data Structure
//==============================================================
dcl-ds BrokerFilter_t qualified template;
    brokerCode      char(10);
    companyName     varchar(100);
    city            varchar(24);
    status          char(3);
end-ds;

//==============================================================
// Procedure Prototypes
//==============================================================

// CRUD Operations
dcl-pr CreateBroker packed(10:0) extproc('BROKRSRV_CreateBroker');
    pBroker likeds(Broker_t) const;
end-pr;

dcl-pr GetBroker likeds(Broker_t) extproc('BROKRSRV_GetBroker');
    pBrokerId packed(10:0) const;
end-pr;

dcl-pr GetBrokerByCode likeds(Broker_t) extproc('BROKRSRV_GetBrokerByCode');
    pBrokerCode char(10) const;
end-pr;

dcl-pr UpdateBroker ind extproc('BROKRSRV_UpdateBroker');
    pBroker likeds(Broker_t) const;
end-pr;

dcl-pr DeleteBroker ind extproc('BROKRSRV_DeleteBroker');
    pBrokerId packed(10:0) const;
end-pr;

dcl-pr ListBrokers int(10) extproc('BROKRSRV_ListBrokers');
    pFilter likeds(BrokerFilter_t) const;
end-pr;

// Validation
dcl-pr IsValidBroker ind extproc('BROKRSRV_IsValidBroker');
    pBroker likeds(Broker_t) const;
end-pr;

dcl-pr IsValidFsmaNumber ind extproc('BROKRSRV_IsValidFsmaNumber');
    pFsmaNumber char(10) const;
end-pr;

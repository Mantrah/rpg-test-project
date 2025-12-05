**free
// ============================================================
// CONTSRV_H - Contract Service Copybook
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Data structures and prototypes for CONTSRV module.
// Business rules:
// - 1 year duration, auto-renewal
// - Cancellation: 2 months before expiration
// TELEBIB2 alignment: BrokerPolicyReference
// ============================================================

//==============================================================
// Contract Data Structure
//==============================================================
dcl-ds Contract_t qualified template;
    contId          packed(10:0);
    contReference   char(20);           // BrokerPolicyReference (TELEBIB2)
    // Foreign Keys
    brokerId        packed(10:0);
    custId          packed(10:0);
    productId       packed(10:0);
    // Coverage Period
    startDate       date;
    endDate         date;
    // Pricing
    premiumAmt      packed(9:2);        // Annual premium
    payFrequency    char(1);            // M/Q/A
    // Options
    vehiclesCount   packed(2:0);
    autoRenew       char(1);            // Y/N
    // Status
    status          char(3);            // PEN/ACT/EXP/CAN/REN
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;

//==============================================================
// Contract Filter Data Structure
//==============================================================
dcl-ds ContractFilter_t qualified template;
    brokerId        packed(10:0);
    custId          packed(10:0);
    productId       packed(10:0);
    status          char(3);
    startDateFrom   date;
    startDateTo     date;
end-ds;

//==============================================================
// Contract Status Constants
//==============================================================
dcl-c CONT_PENDING 'PEN';
dcl-c CONT_ACTIVE 'ACT';
dcl-c CONT_EXPIRED 'EXP';
dcl-c CONT_CANCELLED 'CAN';
dcl-c CONT_RENEWAL 'REN';

//==============================================================
// Payment Frequency Constants
//==============================================================
dcl-c PAY_MONTHLY 'M';
dcl-c PAY_QUARTERLY 'Q';
dcl-c PAY_ANNUAL 'A';

//==============================================================
// Procedure Prototypes
//==============================================================

// CRUD Operations
dcl-pr CreateContract packed(10:0) extproc('CONTSRV_CreateContract');
    pContract likeds(Contract_t) const;
end-pr;

dcl-pr GetContract likeds(Contract_t) extproc('CONTSRV_GetContract');
    pContId packed(10:0) const;
end-pr;

dcl-pr GetContractByRef likeds(Contract_t) extproc('CONTSRV_GetContractByRef');
    pContReference char(20) const;
end-pr;

dcl-pr UpdateContract ind extproc('CONTSRV_UpdateContract');
    pContract likeds(Contract_t) const;
end-pr;

dcl-pr CancelContract ind extproc('CONTSRV_CancelContract');
    pContId packed(10:0) const;
end-pr;

dcl-pr ListContracts int(10) extproc('CONTSRV_ListContracts');
    pFilter likeds(ContractFilter_t) const;
end-pr;

dcl-pr GetCustomerContracts int(10) extproc('CONTSRV_GetCustomerContracts');
    pCustId packed(10:0) const;
end-pr;

dcl-pr GetBrokerContracts int(10) extproc('CONTSRV_GetBrokerContracts');
    pBrokerId packed(10:0) const;
end-pr;

// Validation
dcl-pr IsValidContract ind extproc('CONTSRV_IsValidContract');
    pContract likeds(Contract_t) const;
end-pr;

// Business Logic
dcl-pr CalculatePremium packed(9:2) extproc('CONTSRV_CalculatePremium');
    pProductCode char(10) const;
    pVehiclesCount packed(2:0) const;
    pPayFrequency char(1) const;
end-pr;

dcl-pr CanRenewContract ind extproc('CONTSRV_CanRenewContract');
    pContId packed(10:0) const;
end-pr;

dcl-pr RenewContract packed(10:0) extproc('CONTSRV_RenewContract');
    pContId packed(10:0) const;
end-pr;

dcl-pr IsContractActive ind extproc('CONTSRV_IsContractActive');
    pContId packed(10:0) const;
end-pr;

dcl-pr GenerateContractRef char(20) extproc('CONTSRV_GenerateContractRef');
    pBrokerId packed(10:0) const;
end-pr;

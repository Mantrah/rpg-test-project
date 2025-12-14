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
dcl-pr CONTSRV_CreateContract packed(10:0);
    pContract likeds(Contract_t) const;
end-pr;

dcl-pr CONTSRV_GetContract likeds(Contract_t);
    pContId packed(10:0) const;
end-pr;

dcl-pr CONTSRV_GetContractByRef likeds(Contract_t);
    pContReference char(20) const;
end-pr;

dcl-pr CONTSRV_UpdateContract ind;
    pContract likeds(Contract_t) const;
end-pr;

dcl-pr CONTSRV_CancelContract ind;
    pContId packed(10:0) const;
end-pr;

dcl-pr CONTSRV_ListContracts int(10);
    pFilter likeds(ContractFilter_t) const;
end-pr;

dcl-pr CONTSRV_GetCustomerContracts int(10);
    pCustId packed(10:0) const;
end-pr;

dcl-pr CONTSRV_GetBrokerContracts int(10);
    pBrokerId packed(10:0) const;
end-pr;

// Validation
dcl-pr CONTSRV_IsValidContract ind;
    pContract likeds(Contract_t) const;
end-pr;

// Business Logic
dcl-pr CONTSRV_CalculatePremium packed(9:2);
    pProductCode char(10) const;
    pVehiclesCount packed(2:0) const;
    pPayFrequency char(1) const;
end-pr;

dcl-pr CONTSRV_CanRenewContract ind;
    pContId packed(10:0) const;
end-pr;

dcl-pr CONTSRV_RenewContract packed(10:0);
    pContId packed(10:0) const;
end-pr;

dcl-pr CONTSRV_IsContractActive ind;
    pContId packed(10:0) const;
end-pr;

dcl-pr CONTSRV_GenerateContractRef char(20);
    pBrokerId packed(10:0) const;
end-pr;

**free
// ============================================================
// PRODSRV_H - Product Service Copybook
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Data structures and prototypes for PRODSRV module.
// Products match DAS.be offerings (Classic, Connect, Comfort, etc.)
// ============================================================

//==============================================================
// Product Data Structure
//==============================================================
dcl-ds Product_t qualified template;
    productId       packed(10:0);
    productCode     char(10);
    productName     varchar(50);
    productType     char(3);            // IND/FAM/BUS
    basePremium     packed(9:2);        // Annual base premium
    coverageLimit   packed(11:2);       // Max €200,000
    minThreshold    packed(7:2);        // Min €350
    taxBenefit      char(1);            // Y/N (Benefisc)
    waitingMonths   packed(2:0);
    status          char(3);            // ACT/INA
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;

//==============================================================
// Guarantee Data Structure
//==============================================================
dcl-ds Guarantee_t qualified template;
    guaranteeId     packed(10:0);
    productId       packed(10:0);
    guaranteeCode   char(10);           // CoverageCode (TELEBIB2)
    guaranteeName   varchar(50);
    coverageLimit   packed(11:2);
    waitingMonths   packed(2:0);
    status          char(3);            // ACT/INA
end-ds;

//==============================================================
// Product Code Constants (matching DAS.be)
//==============================================================
dcl-c PROD_CLASSIC 'CLASSIC';
dcl-c PROD_CONNECT 'CONNECT';
dcl-c PROD_COMFORT 'COMFORT';
dcl-c PROD_VIE_PRIV 'VIE_PRIV';
dcl-c PROD_CONSOM 'CONSOM';
dcl-c PROD_CONSOM_BF 'CONSOM_BF';
dcl-c PROD_CONFLIT_BF 'CONFLIT_BF';
dcl-c PROD_SUR_MES 'SUR_MES';
dcl-c PROD_FISCASST 'FISCASST';

//==============================================================
// Guarantee Code Constants (CoverageCode - TELEBIB2)
//==============================================================
dcl-c GUAR_CIV_RECOV 'CIV_RECOV';
dcl-c GUAR_CRIM_DEF 'CRIM_DEF';
dcl-c GUAR_INS_CONTR 'INS_CONTR';
dcl-c GUAR_MED_MALPR 'MED_MALPR';
dcl-c GUAR_NEIGHBOR 'NEIGHBOR';
dcl-c GUAR_FAMILY 'FAMILY';
dcl-c GUAR_TAX 'TAX';
dcl-c GUAR_EMPLOY 'EMPLOY';
dcl-c GUAR_SUCCES 'SUCCES';
dcl-c GUAR_ADMIN 'ADMIN';

//==============================================================
// Procedure Prototypes
//==============================================================

// Product Operations (mostly read-only)
dcl-pr GetProduct likeds(Product_t) extproc('PRODSRV_GetProduct');
    pProductId packed(10:0) const;
end-pr;

dcl-pr GetProductByCode likeds(Product_t) extproc('PRODSRV_GetProductByCode');
    pProductCode char(10) const;
end-pr;

dcl-pr ListProducts int(10) extproc('PRODSRV_ListProducts');
    pProductType char(3) const options(*nopass);
end-pr;

dcl-pr GetProductGuarantees int(10) extproc('PRODSRV_GetProductGuarantees');
    pProductId packed(10:0) const;
end-pr;

dcl-pr CalculateBasePremium packed(9:2) extproc('PRODSRV_CalculateBasePremium');
    pProductCode char(10) const;
    pVehiclesCount packed(2:0) const;
end-pr;

dcl-pr IsProductAvailable ind extproc('PRODSRV_IsProductAvailable');
    pProductCode char(10) const;
end-pr;

dcl-pr HasGuarantee ind extproc('PRODSRV_HasGuarantee');
    pProductId packed(10:0) const;
    pGuaranteeCode char(10) const;
end-pr;

dcl-pr GetGuaranteeWaitingPeriod packed(2:0) extproc('PRODSRV_GetGuaranteeWaitingPeriod');
    pProductId packed(10:0) const;
    pGuaranteeCode char(10) const;
end-pr;

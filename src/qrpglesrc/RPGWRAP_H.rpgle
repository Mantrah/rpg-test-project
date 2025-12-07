**free
// ============================================================
// RPGWRAP_H - iToolkit Wrapper Copybook
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Prototypes for wrapper procedures with scalar OUTPUT params.
// Used by Node.js via iToolkit/XMLSERVICE.
// ============================================================

//==============================================================
// BROKER WRAPPERS
//==============================================================

dcl-pr WRAP_GetBrokerById;
    pBrokerId       packed(10:0) const;
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
end-pr;

dcl-pr WRAP_ListBrokersCount;
    pStatus         char(3) const;
    oCount          packed(10:0);
    oSuccess        char(1);
end-pr;

dcl-pr WRAP_CreateBroker;
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
    oBrokerId       packed(10:0);
    oSuccess        char(1);
    oErrorCode      char(10);
end-pr;

//==============================================================
// CUSTOMER WRAPPERS
//==============================================================

dcl-pr WRAP_GetCustomerById;
    pCustId         packed(10:0) const;
    oCustType       char(3);
    oFirstName      char(50);
    oLastName       char(50);
    oNationalId     char(15);
    oBirthDate      date;
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
end-pr;

dcl-pr WRAP_CreateCustomer;
    pCustType       char(3) const;
    pFirstName      char(50) const;
    pLastName       char(50) const;
    pNationalId     char(15) const;
    pBirthDate      date const;
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
    oCustId         packed(10:0);
    oSuccess        char(1);
    oErrorCode      char(10);
end-pr;

//==============================================================
// PRODUCT WRAPPERS
//==============================================================

dcl-pr WRAP_GetProductById;
    pProductId      packed(10:0) const;
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
end-pr;

dcl-pr WRAP_CalculatePremium;
    pProductCode    char(10) const;
    pVehiclesCount  packed(2:0) const;
    pPayFrequency   char(1) const;
    oBasePremium    packed(9:2);
    oVehicleAddon   packed(9:2);
    oFreqSurcharge  packed(9:2);
    oTotalPremium   packed(9:2);
    oSuccess        char(1);
end-pr;

//==============================================================
// CONTRACT WRAPPERS
//==============================================================

dcl-pr WRAP_GetContractById;
    pContId         packed(10:0) const;
    oContReference  char(25);
    oCustId         packed(10:0);
    oBrokerId       packed(10:0);
    oProductId      packed(10:0);
    oStartDate      date;
    oEndDate        date;
    oVehiclesCount  packed(2:0);
    oPayFrequency   char(1);
    oPremiumAmt     packed(9:2);
    oAutoRenew      char(1);
    oStatus         char(3);
    oSuccess        char(1);
    oErrorCode      char(10);
end-pr;

dcl-pr WRAP_CreateContract;
    pCustId         packed(10:0) const;
    pBrokerId       packed(10:0) const;
    pProductId      packed(10:0) const;
    pStartDate      date const;
    pVehiclesCount  packed(2:0) const;
    pPayFrequency   char(1) const;
    pAutoRenewal    char(1) const;
    oContId         packed(10:0);
    oContReference  char(25);
    oTotalPremium   packed(9:2);
    oSuccess        char(1);
    oErrorCode      char(10);
end-pr;

//==============================================================
// CLAIM WRAPPERS
//==============================================================

dcl-pr WRAP_GetClaimById;
    pClaimId        packed(10:0) const;
    oClaimReference char(15);
    oFileReference  char(15);
    oContId         packed(10:0);
    oGuaranteeCode  char(10);
    oDeclarationDate date;
    oIncidentDate   date;
    oClaimedAmount  packed(11:2);
    oApprovedAmount packed(11:2);
    oStatus         char(3);
    oResolutionType char(3);
    oSuccess        char(1);
    oErrorCode      char(10);
end-pr;

dcl-pr WRAP_CreateClaim;
    pContId         packed(10:0) const;
    pGuaranteeCode  char(10) const;
    pIncidentDate   date const;
    pClaimedAmount  packed(11:2) const;
    pDescription    char(500) const;
    oClaimId        packed(10:0);
    oClaimReference char(15);
    oFileReference  char(15);
    oSuccess        char(1);
    oErrorCode      char(10);
end-pr;

dcl-pr WRAP_ValidateClaim;
    pContId         packed(10:0) const;
    pGuaranteeCode  char(10) const;
    pClaimedAmount  packed(11:2) const;
    pIncidentDate   date const;
    oIsValid        char(1);
    oIsCovered      char(1);
    oWaitingPassed  char(1);
    oAboveThreshold char(1);
    oWaitingDays    packed(5:0);
    oErrorCode      char(10);
end-pr;

//==============================================================
// DASHBOARD WRAPPERS
//==============================================================

dcl-pr WRAP_GetDashboardStats;
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
end-pr;

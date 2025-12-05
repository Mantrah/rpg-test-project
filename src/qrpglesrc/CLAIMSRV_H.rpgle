**free
// ============================================================
// CLAIMSRV_H - Claim Service Copybook
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Data structures and prototypes for CLAIMSRV module.
// Business rules:
// - 79% resolved via amicable settlement
// - Must check waiting period and coverage
// - Customer can freely choose lawyer
// TELEBIB2 alignment: ClaimReference, ClaimFileReference,
//                     ClaimAmount, ClaimCircumstancesCode, CoverageCode
// ============================================================

//==============================================================
// Claim Data Structure
//==============================================================
dcl-ds Claim_t qualified template;
    claimId         packed(10:0);
    claimReference  char(20);           // ClaimReference (TELEBIB2)
    fileReference   char(20);           // ClaimFileReference (TELEBIB2)
    // Foreign Key
    contId          packed(10:0);
    // Classification (TELEBIB2)
    guaranteeCode   char(10);           // CoverageCode
    circumstanceCode char(10);          // ClaimCircumstancesCode
    // Dates
    declarationDate date;
    incidentDate    date;
    // Details
    description     varchar(500);
    // Amounts (TELEBIB2: ClaimAmount)
    claimedAmount   packed(11:2);
    approvedAmount  packed(11:2);
    // Resolution
    resolutionType  char(3);            // AMI/LIT/REJ
    lawyerName      varchar(100);
    // Status
    status          char(3);            // NEW/PRO/RES/CLO/REJ
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;

//==============================================================
// Claim Filter Data Structure
//==============================================================
dcl-ds ClaimFilter_t qualified template;
    contId          packed(10:0);
    guaranteeCode   char(10);
    circumstanceCode char(10);
    status          char(3);
    declarationDateFrom date;
    declarationDateTo date;
end-ds;

//==============================================================
// Claim Status Constants
//==============================================================
dcl-c CLAIM_NEW 'NEW';
dcl-c CLAIM_IN_PROGRESS 'PRO';
dcl-c CLAIM_RESOLVED 'RES';
dcl-c CLAIM_CLOSED 'CLO';
dcl-c CLAIM_REJECTED 'REJ';

//==============================================================
// Resolution Type Constants (79% AMI at DAS)
//==============================================================
dcl-c RESOL_AMICABLE 'AMI';
dcl-c RESOL_LITIGATION 'LIT';
dcl-c RESOL_REJECTED 'REJ';

//==============================================================
// Circumstance Code Constants (ClaimCircumstancesCode - TELEBIB2)
//==============================================================
dcl-c CIRCUM_CONTRACT 'CONTR_DISP';
dcl-c CIRCUM_EMPLOYMENT 'EMPL_DISP';
dcl-c CIRCUM_NEIGHBOR 'NEIGH_DISP';
dcl-c CIRCUM_TAX 'TAX_DISP';
dcl-c CIRCUM_MEDICAL 'MED_MALPR';
dcl-c CIRCUM_CRIMINAL 'CRIM_DEF';
dcl-c CIRCUM_FAMILY 'FAM_DISP';
dcl-c CIRCUM_ADMIN 'ADMIN_DISP';

//==============================================================
// Business Rule Constants
//==============================================================
dcl-c MIN_CLAIM_THRESHOLD 350;          // €350 minimum intervention

//==============================================================
// Procedure Prototypes
//==============================================================

// CRUD Operations
dcl-pr CreateClaim packed(10:0) extproc('CLAIMSRV_CreateClaim');
    pClaim likeds(Claim_t) const;
end-pr;

dcl-pr GetClaim likeds(Claim_t) extproc('CLAIMSRV_GetClaim');
    pClaimId packed(10:0) const;
end-pr;

dcl-pr GetClaimByRef likeds(Claim_t) extproc('CLAIMSRV_GetClaimByRef');
    pClaimReference char(20) const;
end-pr;

dcl-pr UpdateClaim ind extproc('CLAIMSRV_UpdateClaim');
    pClaim likeds(Claim_t) const;
end-pr;

dcl-pr ListClaims int(10) extproc('CLAIMSRV_ListClaims');
    pFilter likeds(ClaimFilter_t) const;
end-pr;

dcl-pr GetContractClaims int(10) extproc('CLAIMSRV_GetContractClaims');
    pContId packed(10:0) const;
end-pr;

// Validation
dcl-pr IsValidClaim ind extproc('CLAIMSRV_IsValidClaim');
    pClaim likeds(Claim_t) const;
end-pr;

// Coverage Validation
dcl-pr IsCovered ind extproc('CLAIMSRV_IsCovered');
    pContId packed(10:0) const;
    pGuaranteeCode char(10) const;
end-pr;

dcl-pr IsInWaitingPeriod ind extproc('CLAIMSRV_IsInWaitingPeriod');
    pContId packed(10:0) const;
    pGuaranteeCode char(10) const;
    pIncidentDate date const;
end-pr;

// Business Operations
dcl-pr AssignLawyer ind extproc('CLAIMSRV_AssignLawyer');
    pClaimId packed(10:0) const;
    pLawyerName varchar(100) const;
end-pr;

dcl-pr ResolveClaim ind extproc('CLAIMSRV_ResolveClaim');
    pClaimId packed(10:0) const;
    pResolutionType char(3) const;
    pApprovedAmount packed(11:2) const;
end-pr;

// Reference Generation
dcl-pr GenerateClaimRef char(20) extproc('CLAIMSRV_GenerateClaimRef');
end-pr;

dcl-pr GenerateFileRef char(20) extproc('CLAIMSRV_GenerateFileRef');
    pClaimId packed(10:0) const;
end-pr;

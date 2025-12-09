**free
// ============================================================
// CLAIMSRV - Claim Service Module
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// CRUD operations for Claim (sinistres).
// Business rules:
// - 79% resolved via amicable settlement (no court)
// - Must check waiting period and coverage
// - Customer can freely choose lawyer
// - Minimum claim threshold: €350
// TELEBIB2 alignment: ClaimReference, ClaimFileReference,
//                     ClaimAmount, ClaimCircumstancesCode, CoverageCode
// ============================================================

ctl-opt nomain option(*srcstmt:*nodebugio);

// SQL Options - COMMIT(*NONE) required for PUB400 (no journaling)
exec sql SET OPTION COMMIT = *NONE, CLOSQLCSR = *ENDMOD;

/copy MRS1/QRPGLESRC,CLAIMSRV_H
/copy MRS1/QRPGLESRC,ERRUTIL_H
/copy MRS1/QRPGLESRC,CONTSRV_H
/copy MRS1/QRPGLESRC,PRODSRV_H

//==============================================================
// CreateClaim : Insert new claim
//
//  Returns: Claim ID (0 on error)
//
//==============================================================
dcl-proc CLAIMSRV_CreateClaim export;
    dcl-pi *n packed(10:0);
        pClaim likeds(Claim_t) const;
    end-pi;

    dcl-s newClaimId packed(10:0) inz(0);
    dcl-ds claim likeds(Claim_t);

    // Initialization
    ERRUTIL_init();
    claim = pClaim;

    monitor;
        // Validation
        if not CLAIMSRV_IsValidClaim(claim);
            return 0;
        endif;

        // Check coverage
        if not CLAIMSRV_IsCovered(claim.contId: claim.guaranteeCode);
            ERRUTIL_addErrorCode('BUS005');
            return 0;
        endif;

        // Check waiting period
        if claim.incidentDate <> *loval;
            if CLAIMSRV_IsInWaitingPeriod(claim.contId: claim.guaranteeCode: claim.incidentDate);
                ERRUTIL_addErrorCode('BUS004');
                return 0;
            endif;
        endif;

        // Check minimum threshold (€350)
        if claim.claimedAmount > 0 and claim.claimedAmount < MIN_CLAIM_THRESHOLD;
            ERRUTIL_addErrorCode('BUS006');
            return 0;
        endif;

        // Generate references if not provided
        if claim.claimReference = '';
            claim.claimReference = CLAIMSRV_GenerateClaimRef();
        endif;

        // Business logic
        exec sql
            INSERT INTO CLAIM (
                CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID, GUARANTEE_CODE,
                CIRCUMSTANCE_CODE, DECLARATION_DATE, INCIDENT_DATE,
                DESCRIPTION, CLAIMED_AMOUNT, STATUS
            ) VALUES (
                :claim.claimReference, :claim.fileReference, :claim.contId,
                :claim.guaranteeCode, :claim.circumstanceCode,
                :claim.declarationDate, :claim.incidentDate,
                :claim.description, :claim.claimedAmount, 'NEW'
            );

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            exec sql
                SELECT IDENTITY_VAL_LOCAL() INTO :newClaimId FROM SYSIBM.SYSDUMMY1;

            // Generate file reference
            if claim.fileReference = '';
                exec sql
                    UPDATE CLAIM
                    SET FILE_REFERENCE = 'DOS-' || TRIM(CHAR(:newClaimId))
                    WHERE CLAIM_ID = :newClaimId;
            endif;
        else;
            if sqlcode = -803;
                ERRUTIL_addErrorCode('DB002');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return newClaimId;
end-proc;

//==============================================================
// GetClaim : Retrieve claim by ID
//
//  Returns: Claim DS (empty on error)
//
//==============================================================
dcl-proc CLAIMSRV_GetClaim export;
    dcl-pi *n likeds(Claim_t);
        pClaimId packed(10:0) const;
    end-pi;

    dcl-ds claim likeds(Claim_t) inz;

    monitor;
        // Business logic
        exec sql
            SELECT CLAIM_ID, CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
                   GUARANTEE_CODE, CIRCUMSTANCE_CODE, DECLARATION_DATE,
                   INCIDENT_DATE, DESCRIPTION, CLAIMED_AMOUNT, APPROVED_AMOUNT,
                   RESOLUTION_TYPE, LAWYER_NAME, STATUS, CREATED_AT, UPDATED_AT
            INTO :claim
            FROM CLAIM
            WHERE CLAIM_ID = :pClaimId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            clear claim;
            if sqlcode = 100;
                ERRUTIL_addErrorCode('DB001');
            else;
                ERRUTIL_addErrorCode('DB004');
            endif;
        endif;

    on-error;
        clear claim;
        ERRUTIL_addExecutionError();
    endmon;

    return claim;
end-proc;

//==============================================================
// GetClaimByRef : Retrieve claim by reference
//
//  Returns: Claim DS (empty on error)
//
//==============================================================
dcl-proc CLAIMSRV_GetClaimByRef export;
    dcl-pi *n likeds(Claim_t);
        pClaimReference char(20) const;
    end-pi;

    dcl-ds claim likeds(Claim_t) inz;

    monitor;
        // Business logic
        exec sql
            SELECT CLAIM_ID, CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
                   GUARANTEE_CODE, CIRCUMSTANCE_CODE, DECLARATION_DATE,
                   INCIDENT_DATE, DESCRIPTION, CLAIMED_AMOUNT, APPROVED_AMOUNT,
                   RESOLUTION_TYPE, LAWYER_NAME, STATUS, CREATED_AT, UPDATED_AT
            INTO :claim
            FROM CLAIM
            WHERE CLAIM_REFERENCE = :pClaimReference;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode <> 0 and sqlcode <> 8013 and sqlcode <> -8013;
            clear claim;
        endif;

    on-error;
        clear claim;
        ERRUTIL_addExecutionError();
    endmon;

    return claim;
end-proc;

//==============================================================
// UpdateClaim : Update existing claim
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc CLAIMSRV_UpdateClaim export;
    dcl-pi *n ind;
        pClaim likeds(Claim_t) const;
    end-pi;

    dcl-s success ind inz(*off);

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation
        if not CLAIMSRV_IsValidClaim(pClaim);
            return *off;
        endif;

        // Business logic
        exec sql
            UPDATE CLAIM SET
                CLAIM_REFERENCE = :pClaim.claimReference,
                FILE_REFERENCE = :pClaim.fileReference,
                GUARANTEE_CODE = :pClaim.guaranteeCode,
                CIRCUMSTANCE_CODE = :pClaim.circumstanceCode,
                DECLARATION_DATE = :pClaim.declarationDate,
                INCIDENT_DATE = :pClaim.incidentDate,
                DESCRIPTION = :pClaim.description,
                CLAIMED_AMOUNT = :pClaim.claimedAmount,
                APPROVED_AMOUNT = :pClaim.approvedAmount,
                RESOLUTION_TYPE = :pClaim.resolutionType,
                LAWYER_NAME = :pClaim.lawyerName,
                STATUS = :pClaim.status,
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CLAIM_ID = :pClaim.claimId;

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
// ListClaims : Search with filters
//
//  Returns: Result count
//
//==============================================================
dcl-proc CLAIMSRV_ListClaims export;
    dcl-pi *n int(10);
        pFilter likeds(ClaimFilter_t) const;
    end-pi;

    dcl-s resultCount int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM CLAIM
            WHERE (:pFilter.contId = 0 OR CONT_ID = :pFilter.contId)
              AND (:pFilter.guaranteeCode = '' OR GUARANTEE_CODE = :pFilter.guaranteeCode)
              AND (:pFilter.circumstanceCode = '' OR CIRCUMSTANCE_CODE = :pFilter.circumstanceCode)
              AND (:pFilter.status = '' OR STATUS = :pFilter.status);

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// GetContractClaims : Get claims for contract
//
//  Returns: Result count
//
//==============================================================
dcl-proc CLAIMSRV_GetContractClaims export;
    dcl-pi *n int(10);
        pContId packed(10:0) const;
    end-pi;

    dcl-s resultCount int(10) inz(0);

    monitor;
        // Business logic
        exec sql
            SELECT COUNT(*) INTO :resultCount
            FROM CLAIM
            WHERE CONT_ID = :pContId;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return resultCount;
end-proc;

//==============================================================
// IsValidClaim : Validate claim data
//
//  Returns: Validation indicator
//
//==============================================================
dcl-proc CLAIMSRV_IsValidClaim export;
    dcl-pi *n ind;
        pClaim likeds(Claim_t) const;
    end-pi;

    // Validation - Required fields
    if pClaim.contId = 0;
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    if pClaim.guaranteeCode = '';
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    if pClaim.circumstanceCode = '';
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    if pClaim.declarationDate = *loval;
        ERRUTIL_addErrorCode('VAL006');
        return *off;
    endif;

    // Validation - Contract must be active
    if not CONTSRV_IsContractActive(pClaim.contId);
        ERRUTIL_addErrorCode('BUS003');
        return *off;
    endif;

    return *on;
end-proc;

//==============================================================
// IsCovered : Check if covered by contract
//
//  Returns: Covered indicator
//
//==============================================================
dcl-proc CLAIMSRV_IsCovered export;
    dcl-pi *n ind;
        pContId packed(10:0) const;
        pGuaranteeCode char(10) const;
    end-pi;

    dcl-s productId packed(10:0);

    monitor;
        // Get product from contract
        exec sql
            SELECT PRODUCT_ID INTO :productId
            FROM CONTRACT
            WHERE CONT_ID = :pContId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            return PRODSRV_HasGuarantee(productId: pGuaranteeCode);
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return *off;
end-proc;

//==============================================================
// IsInWaitingPeriod : Check waiting period
//
//  Returns: In waiting indicator
//
//==============================================================
dcl-proc CLAIMSRV_IsInWaitingPeriod export;
    dcl-pi *n ind;
        pContId packed(10:0) const;
        pGuaranteeCode char(10) const;
        pIncidentDate date const;
    end-pi;

    dcl-s productId packed(10:0);
    dcl-s startDate date;
    dcl-s waitingMonths packed(2:0);
    dcl-s waitingEndDate date;

    monitor;
        // Get contract details
        exec sql
            SELECT PRODUCT_ID, START_DATE
            INTO :productId, :startDate
            FROM CONTRACT
            WHERE CONT_ID = :pContId;

        // Treat SQLCODE 8013 (PUB400 licensing) as success
        if sqlcode = 0 or sqlcode = 8013 or sqlcode = -8013;
            // Get waiting period for this guarantee
            waitingMonths = PRODSRV_GetGuaranteeWaitingPeriod(productId: pGuaranteeCode);

            // Calculate waiting end date
            waitingEndDate = startDate + %months(waitingMonths);

            // Check if incident is within waiting period
            return (pIncidentDate < waitingEndDate);
        endif;

    on-error;
        ERRUTIL_addExecutionError();
    endmon;

    return *off;
end-proc;

//==============================================================
// AssignLawyer : Assign lawyer to claim
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc CLAIMSRV_AssignLawyer export;
    dcl-pi *n ind;
        pClaimId packed(10:0) const;
        pLawyerName varchar(100) const;
    end-pi;

    dcl-s success ind inz(*off);

    monitor;
        // Business logic
        exec sql
            UPDATE CLAIM SET
                LAWYER_NAME = :pLawyerName,
                STATUS = 'PRO',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CLAIM_ID = :pClaimId;

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
// ResolveClaim : Mark claim as resolved
//
//  Returns: Success indicator
//
//==============================================================
dcl-proc CLAIMSRV_ResolveClaim export;
    dcl-pi *n ind;
        pClaimId packed(10:0) const;
        pResolutionType char(3) const;
        pApprovedAmount packed(11:2) const;
    end-pi;

    dcl-s success ind inz(*off);
    dcl-s coverageLimit packed(11:2);

    // Initialization
    ERRUTIL_init();

    monitor;
        // Validation - Check resolution type
        if pResolutionType <> 'AMI' and
           pResolutionType <> 'LIT' and
           pResolutionType <> 'REJ';
            ERRUTIL_addErrorCode('VAL006');
            return *off;
        endif;

        // Validation - Check approved amount against coverage limit
        exec sql
            SELECT P.COVERAGE_LIMIT INTO :coverageLimit
            FROM CLAIM CL
            JOIN CONTRACT C ON CL.CONT_ID = C.CONT_ID
            JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID
            WHERE CL.CLAIM_ID = :pClaimId;

        if pApprovedAmount > coverageLimit;
            ERRUTIL_addErrorCode('BUS007');
            return *off;
        endif;

        // Business logic - 79% of DAS cases resolved amicably!
        exec sql
            UPDATE CLAIM SET
                RESOLUTION_TYPE = :pResolutionType,
                APPROVED_AMOUNT = :pApprovedAmount,
                STATUS = 'RES',
                UPDATED_AT = CURRENT_TIMESTAMP
            WHERE CLAIM_ID = :pClaimId;

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
// GenerateClaimRef : Generate claim number
//
//  Returns: Reference string
//
//==============================================================
dcl-proc CLAIMSRV_GenerateClaimRef export;
    dcl-pi *n char(20);
    end-pi;

    dcl-s reference char(20);
    dcl-s sequence packed(10:0);
    dcl-s year char(4);

    // Business logic - Generate unique claim reference
    // Format: SIN-YYYY-NNNNNN
    year = %char(%subdt(%date(): *years));

    monitor;
        exec sql
            SELECT COALESCE(MAX(CLAIM_ID), 0) + 1 INTO :sequence
            FROM CLAIM;

    on-error;
        sequence = 1;
    endmon;

    reference = 'SIN-' + year + '-' + %trim(%editc(sequence: 'Z'));

    return reference;
end-proc;

//==============================================================
// GenerateFileRef : Generate dossier number
//
//  Returns: Reference string
//
//==============================================================
dcl-proc CLAIMSRV_GenerateFileRef export;
    dcl-pi *n char(20);
        pClaimId packed(10:0) const;
    end-pi;

    dcl-s reference char(20);

    // Business logic - Format: DOS-NNNNNNNNNN
    reference = 'DOS-' + %editc(pClaimId: 'X');

    return reference;
end-proc;

-- ============================================================
-- SP_GetClaim - Get claim by ID with related data
-- Wrapper for CLAIMSRV_GetClaim RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_GetClaim(
    IN p_claim_id DECIMAL(10,0)
)
LANGUAGE SQL
SPECIFIC SP_GETCLAIM
DYNAMIC RESULT SETS 1
BEGIN
    DECLARE c1 CURSOR WITH RETURN FOR
        SELECT
            CL.CLAIM_ID,
            CL.CLAIM_REFERENCE,
            CL.FILE_REFERENCE,
            CL.CONT_ID,
            CL.GUARANTEE_CODE,
            CL.CIRCUMSTANCE_CODE,
            CL.DECLARATION_DATE,
            CL.INCIDENT_DATE,
            CL.DESCRIPTION,
            CL.CLAIMED_AMOUNT,
            CL.APPROVED_AMOUNT,
            CL.RESOLUTION_TYPE,
            CL.LAWYER_NAME,
            CL.STATUS,
            CL.CREATED_AT,
            CL.UPDATED_AT,
            -- Contract info
            C.CONT_REFERENCE,
            C.START_DATE AS CONTRACT_START_DATE,
            -- Customer info
            CUST.CUST_TYPE,
            CASE
                WHEN CUST.CUST_TYPE = 'IND' THEN
                    TRIM(CUST.FIRST_NAME) || ' ' || TRIM(CUST.LAST_NAME)
                ELSE CUST.COMPANY_NAME
            END AS CUSTOMER_NAME,
            -- Product info
            P.PRODUCT_CODE,
            P.PRODUCT_NAME,
            P.COVERAGE_LIMIT,
            -- Guarantee info
            G.GUARANTEE_NAME,
            COALESCE(G.WAITING_MONTHS, P.WAITING_MONTHS) AS WAITING_MONTHS
        FROM CLAIM CL
        LEFT JOIN CONTRACT C ON CL.CONT_ID = C.CONT_ID
        LEFT JOIN CUSTOMER CUST ON C.CUST_ID = CUST.CUST_ID
        LEFT JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID
        LEFT JOIN GUARANTEE G ON P.PRODUCT_ID = G.PRODUCT_ID
                              AND CL.GUARANTEE_CODE = G.GUARANTEE_CODE
        WHERE CL.CLAIM_ID = p_claim_id;

    OPEN c1;
END;

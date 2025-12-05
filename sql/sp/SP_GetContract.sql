-- ============================================================
-- SP_GetContract - Get contract by ID with related data
-- Wrapper for CONTSRV_GetContract RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_GetContract(
    IN p_cont_id DECIMAL(10,0)
)
LANGUAGE SQL
SPECIFIC SP_GETCONTRACT
DYNAMIC RESULT SETS 1
BEGIN
    DECLARE c1 CURSOR WITH RETURN FOR
        SELECT
            C.CONT_ID,
            C.CONT_REFERENCE,
            C.BROKER_ID,
            C.CUST_ID,
            C.PRODUCT_ID,
            C.START_DATE,
            C.END_DATE,
            C.PREMIUM_AMT,
            C.PAY_FREQUENCY,
            C.VEHICLES_COUNT,
            C.AUTO_RENEW,
            C.STATUS,
            C.CREATED_AT,
            C.UPDATED_AT,
            -- Broker info
            B.BROKER_CODE,
            B.COMPANY_NAME AS BROKER_COMPANY,
            -- Customer info
            CUST.CUST_TYPE,
            CUST.FIRST_NAME,
            CUST.LAST_NAME,
            CUST.COMPANY_NAME AS CUSTOMER_COMPANY,
            -- Product info
            P.PRODUCT_CODE,
            P.PRODUCT_NAME,
            P.COVERAGE_LIMIT
        FROM CONTRACT C
        LEFT JOIN BROKER B ON C.BROKER_ID = B.BROKER_ID
        LEFT JOIN CUSTOMER CUST ON C.CUST_ID = CUST.CUST_ID
        LEFT JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID
        WHERE C.CONT_ID = p_cont_id;

    OPEN c1;
END;

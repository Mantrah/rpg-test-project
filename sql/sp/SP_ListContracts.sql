-- ============================================================
-- SP_ListContracts - List contracts with filters
-- Wrapper for CONTSRV_ListContracts RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_ListContracts(
    IN p_status CHAR(3) DEFAULT '',
    IN p_broker_id DECIMAL(10,0) DEFAULT 0
)
LANGUAGE SQL
SPECIFIC SP_LISTCONTRACTS
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
            B.COMPANY_NAME AS BROKER_COMPANY,
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
            -- Claim count
            (SELECT COUNT(*)
             FROM CLAIM
             WHERE CONT_ID = C.CONT_ID) AS CLAIM_COUNT
        FROM CONTRACT C
        LEFT JOIN BROKER B ON C.BROKER_ID = B.BROKER_ID
        LEFT JOIN CUSTOMER CUST ON C.CUST_ID = CUST.CUST_ID
        LEFT JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID
        WHERE (p_status = '' OR C.STATUS = p_status)
          AND (p_broker_id = 0 OR C.BROKER_ID = p_broker_id)
        ORDER BY C.CREATED_AT DESC;

    OPEN c1;
END;

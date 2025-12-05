-- ============================================================
-- SP_ListBrokers - List all active brokers
-- Wrapper for BROKRSRV_ListBrokers RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_ListBrokers(
    IN p_status CHAR(3) DEFAULT 'ACT'
)
LANGUAGE SQL
SPECIFIC SP_LISTBROKERS
DYNAMIC RESULT SETS 1
BEGIN
    DECLARE c1 CURSOR WITH RETURN FOR
        SELECT
            BROKER_ID,
            BROKER_CODE,
            COMPANY_NAME,
            VAT_NUMBER,
            FSMA_NUMBER,
            STREET,
            HOUSE_NBR,
            BOX_NBR,
            POSTAL_CODE,
            CITY,
            COUNTRY_CODE,
            PHONE,
            EMAIL,
            CONTACT_NAME,
            STATUS,
            CREATED_AT,
            UPDATED_AT,
            -- Count contracts for this broker
            (SELECT COUNT(*)
             FROM CONTRACT
             WHERE BROKER_ID = BROKER.BROKER_ID) AS CONTRACT_COUNT
        FROM BROKER
        WHERE (p_status = '' OR STATUS = p_status)
        ORDER BY COMPANY_NAME;

    OPEN c1;
END;

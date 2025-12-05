-- ============================================================
-- SP_GetBroker - Get broker by ID
-- Wrapper for BROKRSRV_GetBroker RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_GetBroker(
    IN p_broker_id DECIMAL(10,0)
)
LANGUAGE SQL
SPECIFIC SP_GETBROKER
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
            UPDATED_AT
        FROM BROKER
        WHERE BROKER_ID = p_broker_id;

    OPEN c1;
END;

-- ============================================================
-- SP_CreateBroker - Create new broker
-- Wrapper for BROKRSRV_CreateBroker RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_CreateBroker(
    IN p_broker_code CHAR(10),
    IN p_company_name VARCHAR(100),
    IN p_vat_number CHAR(12),
    IN p_fsma_number CHAR(10),
    IN p_street VARCHAR(30),
    IN p_house_nbr CHAR(5),
    IN p_box_nbr CHAR(4),
    IN p_postal_code CHAR(7),
    IN p_city VARCHAR(24),
    IN p_country_code CHAR(3),
    IN p_phone VARCHAR(20),
    IN p_email VARCHAR(100),
    IN p_contact_name VARCHAR(100),
    OUT p_broker_id DECIMAL(10,0)
)
LANGUAGE SQL
SPECIFIC SP_CREATEBROKER
BEGIN
    DECLARE v_broker_id DECIMAL(10,0);

    -- Call RPG service program
    -- Note: This requires external program call setup
    -- For now, we'll use direct SQL insert as workaround

    INSERT INTO BROKER (
        BROKER_CODE, COMPANY_NAME, VAT_NUMBER, FSMA_NUMBER,
        STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY,
        COUNTRY_CODE, PHONE, EMAIL, CONTACT_NAME, STATUS
    ) VALUES (
        p_broker_code, p_company_name, p_vat_number, p_fsma_number,
        p_street, p_house_nbr, p_box_nbr, p_postal_code, p_city,
        p_country_code, p_phone, p_email, p_contact_name, 'ACT'
    );

    -- Get generated ID
    SET v_broker_id = IDENTITY_VAL_LOCAL();
    SET p_broker_id = v_broker_id;
END;

-- ============================================================
-- SP_CreateBroker - SQL Stored Procedure wrapping RPG
-- DAS.be Backend - Legal Protection Insurance
-- ============================================================
-- This procedure wraps the RPG BROKRSRV_CreateBroker function
-- with proper commitment control for unjournaled tables on PUB400
-- ============================================================

CREATE OR REPLACE PROCEDURE MRS1.SP_CreateBroker (
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
    IN p_contact_name VARCHAR(50),
    OUT p_broker_id DECIMAL(10,0),
    OUT p_sqlcode INTEGER,
    OUT p_sqlstate CHAR(5)
)
LANGUAGE SQL
MODIFIES SQL DATA
NOT DETERMINISTIC
COMMIT ON RETURN NO
SET OPTION COMMIT = *NONE
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            p_sqlstate = RETURNED_SQLSTATE;
        SET p_sqlcode = SQLCODE;
    END;

    SET p_sqlcode = 0;
    SET p_sqlstate = '00000';
    SET p_broker_id = 0;

    -- Insert directly (bypassing RPG for now to test commitment control)
    INSERT INTO MRS1.BROKER (
        BROKER_CODE, COMPANY_NAME, VAT_NUMBER, FSMA_NUMBER,
        STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY,
        COUNTRY_CODE, PHONE, EMAIL, CONTACT_NAME, STATUS
    ) VALUES (
        p_broker_code, p_company_name, p_vat_number, p_fsma_number,
        p_street, p_house_nbr, p_box_nbr, p_postal_code, p_city,
        p_country_code, p_phone, p_email, p_contact_name, 'ACT'
    );

    IF SQLCODE = 0 THEN
        SET p_broker_id = IDENTITY_VAL_LOCAL();
        SET p_sqlcode = 0;
    ELSE
        SET p_sqlcode = SQLCODE;
    END IF;
END;

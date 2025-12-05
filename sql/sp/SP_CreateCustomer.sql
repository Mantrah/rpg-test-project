-- ============================================================
-- SP_CreateCustomer - Create new customer (IND or BUS)
-- Wrapper for CUSTSRV_CreateCustomer RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_CreateCustomer(
    IN p_cust_type CHAR(3),
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_national_id CHAR(15),
    IN p_civil_status CHAR(3),
    IN p_birth_date DATE,
    IN p_company_name VARCHAR(100),
    IN p_vat_number CHAR(12),
    IN p_nace_code CHAR(5),
    IN p_street VARCHAR(30),
    IN p_house_nbr CHAR(5),
    IN p_box_nbr CHAR(4),
    IN p_postal_code CHAR(7),
    IN p_city VARCHAR(24),
    IN p_country_code CHAR(3),
    IN p_phone VARCHAR(20),
    IN p_email VARCHAR(100),
    IN p_language CHAR(2),
    OUT p_cust_id DECIMAL(10,0)
)
LANGUAGE SQL
SPECIFIC SP_CREATECUSTOMER
BEGIN
    DECLARE v_cust_id DECIMAL(10,0);

    INSERT INTO CUSTOMER (
        CUST_TYPE, FIRST_NAME, LAST_NAME, NATIONAL_ID,
        CIVIL_STATUS, BIRTH_DATE, COMPANY_NAME, VAT_NUMBER,
        NACE_CODE, STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE,
        CITY, COUNTRY_CODE, PHONE, EMAIL, LANGUAGE, STATUS
    ) VALUES (
        p_cust_type, p_first_name, p_last_name, p_national_id,
        p_civil_status, p_birth_date, p_company_name, p_vat_number,
        p_nace_code, p_street, p_house_nbr, p_box_nbr, p_postal_code,
        p_city, p_country_code, p_phone, p_email, p_language, 'ACT'
    );

    SET v_cust_id = IDENTITY_VAL_LOCAL();
    SET p_cust_id = v_cust_id;
END;

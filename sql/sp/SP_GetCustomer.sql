-- ============================================================
-- SP_GetCustomer - Get customer by ID
-- Wrapper for CUSTSRV_GetCustomer RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_GetCustomer(
    IN p_cust_id DECIMAL(10,0)
)
LANGUAGE SQL
SPECIFIC SP_GETCUSTOMER
DYNAMIC RESULT SETS 1
BEGIN
    DECLARE c1 CURSOR WITH RETURN FOR
        SELECT
            CUST_ID,
            CUST_TYPE,
            FIRST_NAME,
            LAST_NAME,
            NATIONAL_ID,
            CIVIL_STATUS,
            BIRTH_DATE,
            COMPANY_NAME,
            VAT_NUMBER,
            NACE_CODE,
            STREET,
            HOUSE_NBR,
            BOX_NBR,
            POSTAL_CODE,
            CITY,
            COUNTRY_CODE,
            PHONE,
            EMAIL,
            LANGUAGE,
            STATUS,
            CREATED_AT,
            UPDATED_AT
        FROM CUSTOMER
        WHERE CUST_ID = p_cust_id;

    OPEN c1;
END;

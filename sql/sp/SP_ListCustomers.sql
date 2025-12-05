-- ============================================================
-- SP_ListCustomers - List customers with filters
-- Wrapper for CUSTSRV_ListCustomers RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_ListCustomers(
    IN p_cust_type CHAR(3) DEFAULT '',
    IN p_status CHAR(3) DEFAULT 'ACT'
)
LANGUAGE SQL
SPECIFIC SP_LISTCUSTOMERS
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
            UPDATED_AT,
            -- Count contracts for this customer
            (SELECT COUNT(*)
             FROM CONTRACT
             WHERE CUST_ID = CUSTOMER.CUST_ID) AS CONTRACT_COUNT
        FROM CUSTOMER
        WHERE (p_cust_type = '' OR CUST_TYPE = p_cust_type)
          AND (p_status = '' OR STATUS = p_status)
        ORDER BY
            CASE
                WHEN CUST_TYPE = 'IND' THEN LAST_NAME
                ELSE COMPANY_NAME
            END;

    OPEN c1;
END;

-- ============================================================
-- SP_GetProductByCode - Get product by code (CLASSIC, CONNECT, etc.)
-- Wrapper for PRODSRV_GetProductByCode RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_GetProductByCode(
    IN p_product_code CHAR(10)
)
LANGUAGE SQL
SPECIFIC SP_GETPRODUCTBYCODE
DYNAMIC RESULT SETS 1
BEGIN
    DECLARE c1 CURSOR WITH RETURN FOR
        SELECT
            PRODUCT_ID,
            PRODUCT_CODE,
            PRODUCT_NAME,
            PRODUCT_TYPE,
            BASE_PREMIUM,
            COVERAGE_LIMIT,
            MIN_THRESHOLD,
            TAX_BENEFIT,
            WAITING_MONTHS,
            STATUS,
            CREATED_AT,
            UPDATED_AT
        FROM PRODUCT
        WHERE PRODUCT_CODE = p_product_code
          AND STATUS = 'ACT';

    OPEN c1;
END;

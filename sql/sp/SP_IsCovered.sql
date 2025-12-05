-- ============================================================
-- SP_IsCovered - Check if guarantee is covered by contract
-- Wrapper for CLAIMSRV_IsCovered RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_IsCovered(
    IN p_cont_id DECIMAL(10,0),
    IN p_guarantee_code CHAR(10),
    OUT p_is_covered CHAR(1),
    OUT p_waiting_months DECIMAL(2,0),
    OUT p_waiting_end_date DATE
)
LANGUAGE SQL
SPECIFIC SP_ISCOVERED
BEGIN
    DECLARE v_product_id DECIMAL(10,0);
    DECLARE v_start_date DATE;
    DECLARE v_guarantee_count INT;
    DECLARE v_waiting_months DECIMAL(2,0);

    -- Initialize output
    SET p_is_covered = 'N';
    SET p_waiting_months = 0;
    SET p_waiting_end_date = NULL;

    -- Get contract details
    SELECT PRODUCT_ID, START_DATE
    INTO v_product_id, v_start_date
    FROM CONTRACT
    WHERE CONT_ID = p_cont_id
      AND STATUS = 'ACT';

    -- Check if product has this guarantee
    -- FIX: COUNT(G.GUARANTEE_ID) instead of COUNT(*) to count only matching guarantees
    SELECT COUNT(G.GUARANTEE_ID),
           COALESCE(MAX(G.WAITING_MONTHS), MAX(P.WAITING_MONTHS))
    INTO v_guarantee_count, v_waiting_months
    FROM PRODUCT P
    LEFT JOIN GUARANTEE G ON P.PRODUCT_ID = G.PRODUCT_ID
                          AND G.GUARANTEE_CODE = p_guarantee_code
                          AND G.STATUS = 'ACT'
    WHERE P.PRODUCT_ID = v_product_id
      AND P.STATUS = 'ACT';

    IF v_guarantee_count > 0 THEN
        SET p_is_covered = 'Y';
        SET p_waiting_months = v_waiting_months;

        -- Calculate waiting period end date
        SET p_waiting_end_date = v_start_date + v_waiting_months MONTHS;
    END IF;
END;

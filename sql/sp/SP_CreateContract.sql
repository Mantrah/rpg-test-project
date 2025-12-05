-- ============================================================
-- SP_CreateContract - Create new insurance contract
-- Wrapper for CONTSRV_CreateContract RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_CreateContract(
    IN p_broker_id DECIMAL(10,0),
    IN p_cust_id DECIMAL(10,0),
    IN p_product_id DECIMAL(10,0),
    IN p_start_date DATE,
    IN p_premium_amt DECIMAL(9,2),
    IN p_pay_frequency CHAR(1),
    IN p_vehicles_count DECIMAL(2,0),
    IN p_auto_renew CHAR(1),
    OUT p_cont_id DECIMAL(10,0),
    OUT p_cont_reference CHAR(20)
)
LANGUAGE SQL
SPECIFIC SP_CREATECONTRACT
BEGIN
    DECLARE v_cont_id DECIMAL(10,0);
    DECLARE v_cont_reference CHAR(20);
    DECLARE v_end_date DATE;
    DECLARE v_year CHAR(4);
    DECLARE v_sequence INT;

    -- Generate contract reference: DAS-YYYY-BBBBB-NNNNNN
    SET v_year = CHAR(YEAR(CURRENT DATE));

    SELECT COALESCE(MAX(CONT_ID), 0) + 1
    INTO v_sequence
    FROM CONTRACT;

    SET v_cont_reference = 'DAS-' || v_year || '-' ||
                           RIGHT('00000' || TRIM(CHAR(p_broker_id)), 5) || '-' ||
                           RIGHT('000000' || TRIM(CHAR(v_sequence)), 6);

    -- Calculate end date (1 year)
    SET v_end_date = p_start_date + 1 YEAR;

    -- Insert contract
    INSERT INTO CONTRACT (
        CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
        START_DATE, END_DATE, PREMIUM_AMT, PAY_FREQUENCY,
        VEHICLES_COUNT, AUTO_RENEW, STATUS
    ) VALUES (
        v_cont_reference, p_broker_id, p_cust_id, p_product_id,
        p_start_date, v_end_date, p_premium_amt, p_pay_frequency,
        p_vehicles_count, p_auto_renew, 'ACT'
    );

    SET v_cont_id = IDENTITY_VAL_LOCAL();
    SET p_cont_id = v_cont_id;
    SET p_cont_reference = v_cont_reference;
END;

-- ============================================================
-- SP_CreateClaim - Create new claim with business validations
-- Wrapper for CLAIMSRV_CreateClaim RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_CreateClaim(
    IN p_cont_id DECIMAL(10,0),
    IN p_guarantee_code CHAR(10),
    IN p_circumstance_code CHAR(10),
    IN p_declaration_date DATE,
    IN p_incident_date DATE,
    IN p_description VARCHAR(500),
    IN p_claimed_amount DECIMAL(11,2),
    OUT p_claim_id DECIMAL(10,0),
    OUT p_claim_reference CHAR(20),
    OUT p_file_reference CHAR(20),
    OUT p_error_code CHAR(10)
)
LANGUAGE SQL
SPECIFIC SP_CREATECLAIM
BEGIN
    DECLARE v_claim_id DECIMAL(10,0);
    DECLARE v_claim_reference CHAR(20);
    DECLARE v_file_reference CHAR(20);
    DECLARE v_year CHAR(4);
    DECLARE v_sequence INT;
    DECLARE MIN_CLAIM_THRESHOLD DECIMAL(7,2) DEFAULT 350.00;  -- €350

    -- Initialize output
    SET p_error_code = '';

    -- Validation: Minimum threshold (€350)
    IF p_claimed_amount > 0 AND p_claimed_amount < MIN_CLAIM_THRESHOLD THEN
        SET p_error_code = 'BUS006';  -- Amount below minimum threshold
        RETURN;
    END IF;

    -- Generate claim reference: SIN-YYYY-NNNNNN
    SET v_year = CHAR(YEAR(CURRENT DATE));

    SELECT COALESCE(MAX(CLAIM_ID), 0) + 1
    INTO v_sequence
    FROM CLAIM;

    SET v_claim_reference = 'SIN-' || v_year || '-' ||
                            RIGHT('000000' || TRIM(CHAR(v_sequence)), 6);

    -- Insert claim
    INSERT INTO CLAIM (
        CLAIM_REFERENCE, CONT_ID, GUARANTEE_CODE,
        CIRCUMSTANCE_CODE, DECLARATION_DATE, INCIDENT_DATE,
        DESCRIPTION, CLAIMED_AMOUNT, STATUS
    ) VALUES (
        v_claim_reference, p_cont_id, p_guarantee_code,
        p_circumstance_code, p_declaration_date, p_incident_date,
        p_description, p_claimed_amount, 'NEW'
    );

    SET v_claim_id = IDENTITY_VAL_LOCAL();

    -- Generate file reference: DOS-NNNNNNNNNN
    SET v_file_reference = 'DOS-' || RIGHT('0000000000' || TRIM(CHAR(v_claim_id)), 10);

    -- Update with file reference
    UPDATE CLAIM
    SET FILE_REFERENCE = v_file_reference
    WHERE CLAIM_ID = v_claim_id;

    SET p_claim_id = v_claim_id;
    SET p_claim_reference = v_claim_reference;
    SET p_file_reference = v_file_reference;
END;

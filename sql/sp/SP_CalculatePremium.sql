-- ============================================================
-- SP_CalculatePremium - Calculate full premium with payment frequency
-- Wrapper for CONTSRV_CalculatePremium RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_CalculatePremium(
    IN p_product_code CHAR(10),
    IN p_vehicles_count DECIMAL(2,0),
    IN p_pay_frequency CHAR(1),
    OUT p_premium DECIMAL(9,2)
)
LANGUAGE SQL
SPECIFIC SP_CALCPREMIUM
BEGIN
    DECLARE v_base_premium DECIMAL(9,2);
    DECLARE v_multiplier DECIMAL(5,2);
    DECLARE VEHICLE_ADDON_RATE DECIMAL(5,2) DEFAULT 25.00;  -- €25 per vehicle

    -- Get base premium from product
    SELECT BASE_PREMIUM
    INTO v_base_premium
    FROM PRODUCT
    WHERE PRODUCT_CODE = p_product_code
      AND STATUS = 'ACT';

    -- Add vehicle addon
    SET v_base_premium = v_base_premium + (p_vehicles_count * VEHICLE_ADDON_RATE);

    -- Apply payment frequency multiplier
    CASE p_pay_frequency
        WHEN 'M' THEN SET v_multiplier = 1.05;  -- Monthly: +5%
        WHEN 'Q' THEN SET v_multiplier = 1.02;  -- Quarterly: +2%
        ELSE SET v_multiplier = 1.00;           -- Annual: no surcharge
    END CASE;

    -- Calculate final premium
    SET p_premium = v_base_premium * v_multiplier;
END;

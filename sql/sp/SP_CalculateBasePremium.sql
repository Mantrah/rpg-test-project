-- ============================================================
-- SP_CalculateBasePremium - Calculate premium with vehicle addon
-- Wrapper for PRODSRV_CalculateBasePremium RPG procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE SP_CalculateBasePremium(
    IN p_product_code CHAR(10),
    IN p_vehicles_count DECIMAL(2,0),
    OUT p_premium DECIMAL(9,2)
)
LANGUAGE SQL
SPECIFIC SP_CALCBASEPREMIUM
BEGIN
    DECLARE v_base_premium DECIMAL(9,2);
    DECLARE v_vehicle_addon DECIMAL(9,2);
    DECLARE VEHICLE_ADDON_RATE DECIMAL(5,2) DEFAULT 25.00;  -- €25 per vehicle

    -- Get base premium from product
    SELECT BASE_PREMIUM
    INTO v_base_premium
    FROM PRODUCT
    WHERE PRODUCT_CODE = p_product_code
      AND STATUS = 'ACT';

    -- Calculate vehicle addon
    SET v_vehicle_addon = p_vehicles_count * VEHICLE_ADDON_RATE;

    -- Total premium
    SET p_premium = v_base_premium + v_vehicle_addon;
END;

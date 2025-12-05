/**
 * Product Service
 * Business logic for product operations
 */

const { callProcedure, query } = require('../config/database');
const { STATUS } = require('../config/constants');

/**
 * Get all active products
 * @returns {Promise<Array>} List of products
 */
const getAllProducts = async () => {
  const sql = `
    SELECT
      PRODUCT_ID,
      PRODUCT_CODE,
      PRODUCT_NAME,
      CATEGORY,
      BASE_PREMIUM,
      COVERAGE_LIMIT,
      WAITING_MONTHS,
      STATUS,
      DESCRIPTION
    FROM PRODUCT
    WHERE STATUS = 'ACT'
    ORDER BY PRODUCT_CODE
  `;

  return await query(sql);
};

/**
 * Get product by ID
 * @param {number} productId - Product ID
 * @returns {Promise<Object>} Product details
 */
const getProductById = async (productId) => {
  const sql = `
    SELECT
      PRODUCT_ID,
      PRODUCT_CODE,
      PRODUCT_NAME,
      CATEGORY,
      BASE_PREMIUM,
      COVERAGE_LIMIT,
      WAITING_MONTHS,
      STATUS,
      DESCRIPTION,
      CREATED_AT,
      UPDATED_AT
    FROM PRODUCT
    WHERE PRODUCT_ID = ?
  `;

  const result = await query(sql, [productId]);

  if (result.length === 0) {
    throw { code: 'DB001', message: 'Product not found' };
  }

  return result[0];
};

/**
 * Get product by code
 * @param {string} productCode - Product code (e.g., 'DASCLAS')
 * @returns {Promise<Object>} Product details
 */
const getProductByCode = async (productCode) => {
  const result = await callProcedure('SP_GetProductByCode', [productCode]);

  if (result.length === 0) {
    throw { code: 'DB001', message: 'Product not found' };
  }

  return result[0];
};

/**
 * Get guarantees for a product
 * @param {number} productId - Product ID
 * @returns {Promise<Array>} List of guarantees
 */
const getProductGuarantees = async (productId) => {
  const sql = `
    SELECT
      GUARANTEE_ID,
      GUARANTEE_CODE,
      GUARANTEE_NAME,
      WAITING_MONTHS,
      STATUS,
      DESCRIPTION
    FROM GUARANTEE
    WHERE PRODUCT_ID = ?
      AND STATUS = 'ACT'
    ORDER BY GUARANTEE_CODE
  `;

  return await query(sql, [productId]);
};

/**
 * Calculate base premium for a product
 * @param {string} productCode - Product code
 * @param {number} vehiclesCount - Number of vehicles
 * @returns {Promise<Object>} Calculated premium
 */
const calculateBasePremium = async (productCode, vehiclesCount = 0) => {
  const result = await callProcedure('SP_CalculateBasePremium', [
    productCode,
    vehiclesCount
  ]);

  // SP returns result set, we need to extract the premium
  // Or we can modify to use OUT parameter approach
  // For now, let's query directly
  const sql = `
    SELECT
      BASE_PREMIUM,
      PRODUCT_CODE,
      PRODUCT_NAME
    FROM PRODUCT
    WHERE PRODUCT_CODE = ?
      AND STATUS = 'ACT'
  `;

  const productResult = await query(sql, [productCode]);

  if (productResult.length === 0) {
    throw { code: 'DB001', message: 'Product not found' };
  }

  const basePremium = parseFloat(productResult[0].BASE_PREMIUM);
  const vehicleAddon = vehiclesCount * 25; // €25 per vehicle
  const totalPremium = basePremium + vehicleAddon;

  return {
    productCode: productResult[0].PRODUCT_CODE,
    productName: productResult[0].PRODUCT_NAME,
    basePremium: basePremium,
    vehiclesCount: vehiclesCount,
    vehicleAddon: vehicleAddon,
    totalPremium: totalPremium
  };
};

/**
 * Calculate full premium with payment frequency
 * @param {string} productCode - Product code
 * @param {number} vehiclesCount - Number of vehicles
 * @param {string} payFrequency - Payment frequency (A, Q, M)
 * @returns {Promise<Object>} Calculated premium with frequency multiplier
 */
const calculateFullPremium = async (productCode, vehiclesCount = 0, payFrequency = 'A') => {
  const basePremiumData = await calculateBasePremium(productCode, vehiclesCount);

  // Apply payment frequency multiplier
  let multiplier = 1.00;
  let frequencyLabel = 'Annual';

  switch (payFrequency) {
    case 'M':
      multiplier = 1.05; // Monthly: +5%
      frequencyLabel = 'Monthly';
      break;
    case 'Q':
      multiplier = 1.02; // Quarterly: +2%
      frequencyLabel = 'Quarterly';
      break;
    case 'A':
    default:
      multiplier = 1.00; // Annual: no surcharge
      frequencyLabel = 'Annual';
      break;
  }

  const finalPremium = Math.round(basePremiumData.totalPremium * multiplier * 100) / 100;

  return {
    ...basePremiumData,
    payFrequency: payFrequency,
    frequencyLabel: frequencyLabel,
    frequencyMultiplier: multiplier,
    finalPremium: finalPremium
  };
};

module.exports = {
  getAllProducts,
  getProductById,
  getProductByCode,
  getProductGuarantees,
  calculateBasePremium,
  calculateFullPremium
};

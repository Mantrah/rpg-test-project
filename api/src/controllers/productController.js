/**
 * Product Controller
 * HTTP request handlers for product endpoints
 * Uses RPG backend via iToolkit for business operations
 */

const rpgConnector = require('../config/rpgConnector');
const { query } = require('../config/database');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { PAYMENT_FREQUENCY } = require('../config/constants');

/**
 * Get all products - SQL read-only
 * GET /api/products
 */
const getAllProducts = asyncHandler(async (req, res) => {
  const sql = 'SELECT * FROM PRODUCT WHERE STATUS = \'ACT\' ORDER BY PRODUCT_NAME';
  const products = await query(sql);
  res.json(success(products));
});

/**
 * Get product by ID via RPG
 * GET /api/products/:id
 */
const getProductById = asyncHandler(async (req, res) => {
  const productId = parseInt(req.params.id, 10);

  if (isNaN(productId)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid product ID format.'
      }
    });
  }

  const product = await rpgConnector.getProductById(productId);
  res.json(success(product));
});

/**
 * Get product by code - SQL read-only
 * GET /api/products/code/:code
 */
const getProductByCode = asyncHandler(async (req, res) => {
  const { code } = req.params;

  if (!code || code.length === 0) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Product code is required.'
      }
    });
  }

  const sql = 'SELECT * FROM PRODUCT WHERE PRODUCT_CODE = ?';
  const result = await query(sql, [code.toUpperCase()]);
  if (!result || result.length === 0) {
    const error = new Error('Product not found');
    error.statusCode = 404;
    throw error;
  }
  res.json(success(result[0]));
});

/**
 * Get product guarantees - SQL read-only
 * GET /api/products/:id/guarantees
 */
const getProductGuarantees = asyncHandler(async (req, res) => {
  const productId = parseInt(req.params.id, 10);

  if (isNaN(productId)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid product ID format.'
      }
    });
  }

  const sql = `
    SELECT PG.*, G.GUARANTEE_NAME, G.DESCRIPTION
    FROM PRODUCT_GUARANTEE PG
    JOIN GUARANTEE G ON PG.GUARANTEE_CODE = G.GUARANTEE_CODE
    WHERE PG.PRODUCT_ID = ?
    ORDER BY G.GUARANTEE_NAME
  `;
  const guarantees = await query(sql, [productId]);
  res.json(success(guarantees));
});

/**
 * Calculate premium via RPG
 * POST /api/products/calculate
 * Body: { productCode, vehiclesCount, payFrequency }
 */
const calculatePremium = asyncHandler(async (req, res) => {
  const { productCode, vehiclesCount = 0, payFrequency = 'A' } = req.body;

  // Validate product code
  if (!productCode) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Product code is required.'
      }
    });
  }

  // Validate vehicles count
  if (vehiclesCount < 0 || vehiclesCount > 99) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL003',
        message: 'Vehicles count must be between 0 and 99.'
      }
    });
  }

  // Validate payment frequency
  if (!PAYMENT_FREQUENCY[payFrequency]) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid payment frequency. Must be A, Q, or M.'
      }
    });
  }

  const premiumData = await rpgConnector.calculatePremium(
    productCode.toUpperCase(),
    vehiclesCount,
    payFrequency
  );

  res.json(success(premiumData, 'Premium calculated successfully'));
});

module.exports = {
  getAllProducts,
  getProductById,
  getProductByCode,
  getProductGuarantees,
  calculatePremium
};

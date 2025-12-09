/**
 * Product Controller
 * HTTP request handlers for product endpoints
 * ALL data access goes through RPG via rpgConnector
 */

const rpgConnector = require('../config/rpgConnector');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { PAYMENT_FREQUENCY } = require('../config/constants');

/**
 * Get all products via RPG
 * GET /api/products
 */
const getAllProducts = asyncHandler(async (req, res) => {
  const products = await rpgConnector.listProducts('ACT');
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
 * Get product by code via RPG
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

  const product = await rpgConnector.getProductByCode(code.toUpperCase());
  res.json(success(product));
});

/**
 * Get product guarantees via RPG
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

  const guarantees = await rpgConnector.getProductGuarantees(productId);
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

  // Validate payment frequency (check values: A, Q, M)
  if (!Object.values(PAYMENT_FREQUENCY).includes(payFrequency)) {
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

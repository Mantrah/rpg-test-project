/**
 * Product Routes
 * Handles product catalog and premium calculation endpoints
 */

const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

/**
 * @route   POST /api/products/calculate
 * @desc    Calculate premium with payment frequency
 * @access  Public
 * @body    productCode, vehiclesCount, payFrequency
 */
router.post('/calculate', productController.calculatePremium);

/**
 * @route   GET /api/products
 * @desc    Get all active products
 * @access  Public
 */
router.get('/', productController.getAllProducts);

/**
 * @route   GET /api/products/code/:code
 * @desc    Get product by code
 * @access  Public
 */
router.get('/code/:code', productController.getProductByCode);

/**
 * @route   GET /api/products/:id
 * @desc    Get product by ID
 * @access  Public
 */
router.get('/:id', productController.getProductById);

/**
 * @route   GET /api/products/:id/guarantees
 * @desc    Get all guarantees for a product
 * @access  Public
 */
router.get('/:id/guarantees', productController.getProductGuarantees);

module.exports = router;

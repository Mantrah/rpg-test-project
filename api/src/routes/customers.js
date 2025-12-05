/**
 * Customer Routes
 * Handles customer management endpoints
 */

const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');

/**
 * @route   POST /api/customers
 * @desc    Create new customer (IND or BUS)
 * @access  Public
 */
router.post('/', customerController.createCustomer);

/**
 * @route   GET /api/customers
 * @desc    Get all customers (optional status filter)
 * @access  Public
 * @query   status - Filter by status (ACT, SUS, CLS)
 */
router.get('/', customerController.getAllCustomers);

/**
 * @route   GET /api/customers/:id
 * @desc    Get customer by ID
 * @access  Public
 */
router.get('/:id', customerController.getCustomerById);

/**
 * @route   GET /api/customers/email/:email
 * @desc    Get customer by email
 * @access  Public
 */
router.get('/email/:email', customerController.getCustomerByEmail);

/**
 * @route   GET /api/customers/:id/contracts
 * @desc    Get all contracts for a customer
 * @access  Public
 */
router.get('/:id/contracts', customerController.getCustomerContracts);

module.exports = router;

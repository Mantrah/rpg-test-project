/**
 * Contract Routes
 * Handles contract management endpoints
 */

const express = require('express');
const router = express.Router();
const contractController = require('../controllers/contractController');

/**
 * @route   POST /api/contracts/calculate
 * @desc    Calculate premium for contract
 * @access  Public
 * @body    productCode, vehiclesCount, payFrequency
 */
router.post('/calculate', contractController.calculatePremium);

/**
 * @route   POST /api/contracts
 * @desc    Create new contract
 * @access  Public
 * @body    brokerId, custId, productCode, startDate, endDate, vehiclesCount, totalPremium, payFrequency, autoRenewal, notes
 */
router.post('/', contractController.createContract);

/**
 * @route   GET /api/contracts
 * @desc    Get all contracts (optional status filter)
 * @access  Public
 * @query   status - Filter by status (ACT, SUS, CLS, EXP)
 */
router.get('/', contractController.getAllContracts);

/**
 * @route   GET /api/contracts/reference/:reference
 * @desc    Get contract by reference
 * @access  Public
 */
router.get('/reference/:reference', contractController.getContractByReference);

/**
 * @route   GET /api/contracts/broker/:brokerId
 * @desc    Get all contracts for a broker
 * @access  Public
 */
router.get('/broker/:brokerId', contractController.getBrokerContracts);

/**
 * @route   GET /api/contracts/:id
 * @desc    Get contract by ID
 * @access  Public
 */
router.get('/:id', contractController.getContractById);

/**
 * @route   GET /api/contracts/:id/claims
 * @desc    Get all claims for a contract
 * @access  Public
 */
router.get('/:id/claims', contractController.getContractClaims);

module.exports = router;

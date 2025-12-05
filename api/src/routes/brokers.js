/**
 * Broker Routes
 * Defines HTTP endpoints for broker operations
 */

const express = require('express');
const router = express.Router();
const brokerController = require('../controllers/brokerController');

/**
 * @route   POST /api/brokers
 * @desc    Create a new broker
 * @access  Public (for MVP - add auth later)
 * @body    {brokerCode, companyName, vatNumber, fsmaNumber, address, contact}
 */
router.post('/', brokerController.createBroker);

/**
 * @route   GET /api/brokers
 * @desc    List all brokers
 * @access  Public
 * @query   ?status=ACT (optional)
 */
router.get('/', brokerController.listBrokers);

/**
 * @route   GET /api/brokers/:id
 * @desc    Get broker by ID
 * @access  Public
 * @param   id - Broker ID
 */
router.get('/:id(\\d+)', brokerController.getBroker);

/**
 * @route   GET /api/brokers/code/:code
 * @desc    Get broker by code
 * @access  Public
 * @param   code - Broker code (e.g., BRK001)
 */
router.get('/code/:code', brokerController.getBrokerByCode);

module.exports = router;

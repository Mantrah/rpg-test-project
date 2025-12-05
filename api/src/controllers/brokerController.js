/**
 * Broker Controller
 * Handles HTTP requests for broker endpoints
 */

const brokerService = require('../services/brokerService');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * POST /api/brokers
 * Create a new broker
 */
const createBroker = asyncHandler(async (req, res) => {
  const broker = await brokerService.createBroker(req.body);
  res.status(201).json(success(broker, 'Broker created successfully'));
});

/**
 * GET /api/brokers
 * List all brokers
 */
const listBrokers = asyncHandler(async (req, res) => {
  const { status } = req.query;
  const brokers = await brokerService.listBrokers(status);
  res.json(success(brokers));
});

/**
 * GET /api/brokers/:id
 * Get broker by ID
 */
const getBroker = asyncHandler(async (req, res) => {
  const brokerId = parseInt(req.params.id);
  const broker = await brokerService.getBroker(brokerId);
  res.json(success(broker));
});

/**
 * GET /api/brokers/code/:code
 * Get broker by code
 */
const getBrokerByCode = asyncHandler(async (req, res) => {
  const brokerCode = req.params.code;
  const broker = await brokerService.getBrokerByCode(brokerCode);
  res.json(success(broker));
});

module.exports = {
  createBroker,
  listBrokers,
  getBroker,
  getBrokerByCode
};

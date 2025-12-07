/**
 * Broker Controller - RPG Version
 * Handles HTTP requests for broker endpoints using RPG backend
 * Calls RPG service program DASSRV via iToolkit
 */

const rpgConnector = require('../config/rpgConnector');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * POST /api/brokers
 * Create a new broker via RPG
 */
const createBroker = asyncHandler(async (req, res) => {
  const broker = await rpgConnector.createBroker(req.body);
  res.status(201).json(success(broker, 'Broker created successfully'));
});

/**
 * GET /api/brokers
 * List all brokers - still uses SQL (list operations are read-only)
 */
const listBrokers = asyncHandler(async (req, res) => {
  const brokerService = require('../services/brokerService');
  const { status } = req.query;
  const brokers = await brokerService.listBrokers(status);
  res.json(success(brokers));
});

/**
 * GET /api/brokers/:id
 * Get broker by ID via RPG
 */
const getBroker = asyncHandler(async (req, res) => {
  const brokerId = parseInt(req.params.id);
  const broker = await rpgConnector.getBrokerById(brokerId);
  res.json(success(broker));
});

/**
 * GET /api/brokers/code/:code
 * Get broker by code - uses SQL (read-only)
 */
const getBrokerByCode = asyncHandler(async (req, res) => {
  const brokerService = require('../services/brokerService');
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

/**
 * Contract Controller
 * HTTP request handlers for contract endpoints
 */

const contractService = require('../services/contractService');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { STATUS, PAYMENT_FREQUENCY } = require('../config/constants');

/**
 * Create new contract
 * POST /api/contracts
 */
const createContract = asyncHandler(async (req, res) => {
  const contractData = req.body;

  // Validate required fields
  if (!contractData.brokerId || !contractData.custId || !contractData.productCode) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Broker ID, Customer ID, and Product Code are required.'
      }
    });
  }

  // Validate dates
  if (!contractData.startDate || !contractData.endDate) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Start date and end date are required.'
      }
    });
  }

  // Validate payment frequency
  if (contractData.payFrequency && !PAYMENT_FREQUENCY[contractData.payFrequency]) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid payment frequency. Must be A, Q, or M.'
      }
    });
  }

  // Validate vehicles count
  if (contractData.vehiclesCount < 0 || contractData.vehiclesCount > 99) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL003',
        message: 'Vehicles count must be between 0 and 99.'
      }
    });
  }

  const contract = await contractService.createContract(contractData);
  res.status(201).json(success(contract, 'Contract created successfully'));
});

/**
 * Get all contracts
 * GET /api/contracts?status=ACT
 */
const getAllContracts = asyncHandler(async (req, res) => {
  const { status } = req.query;

  // Validate status if provided
  if (status && !STATUS[status]) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid status. Must be ACT, SUS, CLS, or EXP.'
      }
    });
  }

  const contracts = await contractService.listContracts(status || null);
  res.json(success(contracts));
});

/**
 * Get contract by ID
 * GET /api/contracts/:id
 */
const getContractById = asyncHandler(async (req, res) => {
  const contId = parseInt(req.params.id, 10);

  if (isNaN(contId)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid contract ID format.'
      }
    });
  }

  const contract = await contractService.getContractById(contId);
  res.json(success(contract));
});

/**
 * Get contract by reference
 * GET /api/contracts/reference/:reference
 */
const getContractByReference = asyncHandler(async (req, res) => {
  const { reference } = req.params;

  if (!reference) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Contract reference is required.'
      }
    });
  }

  const contract = await contractService.getContractByReference(reference);
  res.json(success(contract));
});

/**
 * Get broker's contracts
 * GET /api/contracts/broker/:brokerId
 */
const getBrokerContracts = asyncHandler(async (req, res) => {
  const brokerId = parseInt(req.params.brokerId, 10);

  if (isNaN(brokerId)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid broker ID format.'
      }
    });
  }

  const contracts = await contractService.getBrokerContracts(brokerId);
  res.json(success(contracts));
});

/**
 * Get contract claims
 * GET /api/contracts/:id/claims
 */
const getContractClaims = asyncHandler(async (req, res) => {
  const contId = parseInt(req.params.id, 10);

  if (isNaN(contId)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid contract ID format.'
      }
    });
  }

  const claims = await contractService.getContractClaims(contId);
  res.json(success(claims));
});

/**
 * Calculate premium
 * POST /api/contracts/calculate
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

  const premiumData = await contractService.calculatePremium(
    productCode.toUpperCase(),
    vehiclesCount,
    payFrequency
  );

  res.json(success(premiumData, 'Premium calculated successfully'));
});

module.exports = {
  createContract,
  getAllContracts,
  getContractById,
  getContractByReference,
  getBrokerContracts,
  getContractClaims,
  calculatePremium
};

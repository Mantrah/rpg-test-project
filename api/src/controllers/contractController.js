/**
 * Contract Controller
 * HTTP request handlers for contract endpoints
 * ALL data access goes through RPG via rpgConnector
 */

const rpgConnector = require('../config/rpgConnector');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { PAYMENT_FREQUENCY } = require('../config/constants');

// Valid contract status values
const VALID_CONTRACT_STATUS = ['ACT', 'SUS', 'CLS', 'EXP'];

/**
 * Create new contract via RPG
 * POST /api/contracts
 */
const createContract = asyncHandler(async (req, res) => {
  const contractData = req.body;

  // Validate required fields (accept productId OR productCode)
  if (!contractData.brokerId || !contractData.custId || (!contractData.productId && !contractData.productCode)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Broker ID, Customer ID, and Product ID or Product Code are required.'
      }
    });
  }

  // Validate dates
  if (!contractData.startDate) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Start date is required.'
      }
    });
  }

  // Validate payment frequency (check if value exists in PAYMENT_FREQUENCY values)
  const validFrequencies = Object.values(PAYMENT_FREQUENCY);
  if (contractData.payFrequency && !validFrequencies.includes(contractData.payFrequency)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid payment frequency. Must be A, Q, or M.'
      }
    });
  }

  // Validate vehicles count
  if (contractData.vehiclesCount !== undefined && (contractData.vehiclesCount < 0 || contractData.vehiclesCount > 99)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL003',
        message: 'Vehicles count must be between 0 and 99.'
      }
    });
  }

  // If productCode is provided but not productId, lookup the productId
  if (!contractData.productId && contractData.productCode) {
    const product = await rpgConnector.getProductByCode(contractData.productCode);
    if (!product || !product.productId) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VAL004',
          message: `Product not found: ${contractData.productCode}`
        }
      });
    }
    contractData.productId = product.productId;
  }

  const contract = await rpgConnector.createContract(contractData);
  res.status(201).json(success(contract, 'Contract created successfully'));
});

/**
 * Get all contracts via RPG
 * GET /api/contracts?status=ACT
 */
const getAllContracts = asyncHandler(async (req, res) => {
  const { status } = req.query;

  // Validate status if provided
  if (status && !VALID_CONTRACT_STATUS.includes(status)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid status. Must be ACT, SUS, CLS, or EXP.'
      }
    });
  }

  const contracts = await rpgConnector.listContracts(status || '');
  res.json(success(contracts));
});

/**
 * Get contract by ID via RPG
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

  const contract = await rpgConnector.getContractById(contId);
  res.json(success(contract));
});

/**
 * Get contract by reference via RPG
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

  // Use list then find by reference
  const contracts = await rpgConnector.listContracts('');
  const contract = contracts.find(c => c.CONT_REFERENCE === reference);
  if (!contract) {
    const error = new Error('Contract not found');
    error.statusCode = 404;
    throw error;
  }
  res.json(success(contract));
});

/**
 * Get broker's contracts via RPG
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

  // Use list then filter by broker
  const contracts = await rpgConnector.listContracts('');
  const brokerContracts = contracts.filter(c => c.BROKER_ID === brokerId);
  res.json(success(brokerContracts));
});

/**
 * Get contract claims via RPG
 * GET /api/contracts/:id/claims
 * TODO: Add WRAP_ListClaims to return claims for a contract
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

  // TODO: Implement WRAP_ListClaimsByContract in RPG
  // For now, return empty array
  res.json(success([]));
});

/**
 * Calculate premium via RPG
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

  // Validate payment frequency (check if value exists)
  const validFreqs = Object.values(PAYMENT_FREQUENCY);
  if (!validFreqs.includes(payFrequency)) {
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

/**
 * DELETE /api/contracts/:id
 * Soft delete a contract via RPG (sets status to CLS)
 */
const deleteContract = asyncHandler(async (req, res) => {
  const contId = parseInt(req.params.id, 10);

  if (isNaN(contId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'VAL001', message: 'Invalid contract ID' }
    });
  }

  await rpgConnector.deleteContract(contId);
  res.json(success({ contId }, 'Contract deleted successfully'));
});

module.exports = {
  createContract,
  getAllContracts,
  getContractById,
  getContractByReference,
  getBrokerContracts,
  getContractClaims,
  calculatePremium,
  deleteContract
};

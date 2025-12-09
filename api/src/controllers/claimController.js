/**
 * Claim Controller
 * HTTP request handlers for claim endpoints
 * ALL data access goes through RPG via rpgConnector
 */

const rpgConnector = require('../config/rpgConnector');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { STATUS } = require('../config/constants');

/**
 * Create new claim via RPG
 * POST /api/claims
 */
const createClaim = asyncHandler(async (req, res) => {
  const claimData = req.body;

  // Validate required fields
  if (!claimData.contId || !claimData.guaranteeCode) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Contract ID and Guarantee Code are required.'
      }
    });
  }

  // Validate dates
  if (!claimData.incidentDate) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Incident date is required.'
      }
    });
  }

  // Validate claimed amount
  if (!claimData.claimedAmount || claimData.claimedAmount <= 0) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL003',
        message: 'Claimed amount must be greater than 0.'
      }
    });
  }

  const claim = await rpgConnector.createClaim(claimData);
  res.status(201).json(success(claim, 'Claim created successfully'));
});

/**
 * Get all claims via RPG
 * GET /api/claims?status=NEW
 */
const getAllClaims = asyncHandler(async (req, res) => {
  const { status } = req.query;

  // Validate status if provided
  if (status && !STATUS[status]) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid status.'
      }
    });
  }

  const claims = await rpgConnector.listClaims(status || '');
  res.json(success(claims));
});

/**
 * Get claim by ID via RPG
 * GET /api/claims/:id
 */
const getClaimById = asyncHandler(async (req, res) => {
  const claimId = parseInt(req.params.id, 10);

  if (isNaN(claimId)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid claim ID format.'
      }
    });
  }

  const claim = await rpgConnector.getClaimById(claimId);
  res.json(success(claim));
});

/**
 * Get claim by reference via RPG
 * GET /api/claims/reference/:reference
 */
const getClaimByReference = asyncHandler(async (req, res) => {
  const { reference } = req.params;

  if (!reference) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Claim reference is required.'
      }
    });
  }

  // Get all claims and filter by reference
  const claims = await rpgConnector.listClaims('');
  const claim = claims.find(c => c.CLAIM_REFERENCE === reference);

  if (!claim) {
    const error = new Error('Claim not found');
    error.statusCode = 404;
    throw error;
  }
  res.json(success(claim));
});

/**
 * Check coverage for contract and guarantee via RPG
 * POST /api/claims/check-coverage
 * Body: { contId, guaranteeCode }
 */
const checkCoverage = asyncHandler(async (req, res) => {
  const { contId, guaranteeCode } = req.body;

  // Validate required fields
  if (!contId || !guaranteeCode) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Contract ID and Guarantee Code are required.'
      }
    });
  }

  // Use validateClaim to check coverage
  const validation = await rpgConnector.validateClaim(
    contId,
    guaranteeCode,
    1000, // dummy amount for coverage check
    new Date().toISOString().split('T')[0]
  );

  res.json(success({
    isCovered: validation.isCovered,
    contId,
    guaranteeCode
  }));
});

/**
 * Validate claim before creation via RPG
 * POST /api/claims/validate
 * Body: { contId, guaranteeCode, claimedAmount, incidentDate }
 */
const validateClaim = asyncHandler(async (req, res) => {
  const claimData = req.body;

  // Validate required fields
  if (!claimData.contId || !claimData.guaranteeCode) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Contract ID and Guarantee Code are required.'
      }
    });
  }

  if (!claimData.claimedAmount || claimData.claimedAmount <= 0) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL003',
        message: 'Claimed amount must be greater than 0.'
      }
    });
  }

  const validation = await rpgConnector.validateClaim(
    claimData.contId,
    claimData.guaranteeCode,
    claimData.claimedAmount,
    claimData.incidentDate
  );
  res.json(success(validation));
});

/**
 * Get claims statistics via RPG (from dashboard stats)
 * GET /api/claims/stats
 */
const getClaimsStats = asyncHandler(async (req, res) => {
  // Get dashboard stats which includes claim stats
  const dashboardStats = await rpgConnector.getDashboardStats();

  const response = {
    totalClaims: dashboardStats.claims.total || 0,
    amicableResolutions: dashboardStats.claims.amicableResolutions || 0,
    tribunalResolutions: dashboardStats.claims.tribunalResolutions || 0,
    amicableRate: dashboardStats.claims.amicableRate || 0,
    amicableRateTarget: 79 // DAS Belgium target
  };

  res.json(success(response));
});

module.exports = {
  createClaim,
  getAllClaims,
  getClaimById,
  getClaimByReference,
  checkCoverage,
  validateClaim,
  getClaimsStats
};

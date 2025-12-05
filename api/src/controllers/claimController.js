/**
 * Claim Controller
 * HTTP request handlers for claim endpoints
 */

const claimService = require('../services/claimService');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { STATUS, BUSINESS_RULES } = require('../config/constants');

/**
 * Create new claim
 * POST /api/claims
 */
const createClaim = asyncHandler(async (req, res) => {
  const claimData = req.body;

  // Validate required fields
  if (!claimData.contId || !claimData.guaranteeCode || !claimData.circumstanceCode) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Contract ID, Guarantee Code, and Circumstance Code are required.'
      }
    });
  }

  // Validate dates
  if (!claimData.declarationDate || !claimData.incidentDate) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL002',
        message: 'Declaration date and incident date are required.'
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

  const claim = await claimService.createClaim(claimData);
  res.status(201).json(success(claim, 'Claim created successfully'));
});

/**
 * Get all claims
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

  const claims = await claimService.listClaims(status || null);
  res.json(success(claims));
});

/**
 * Get claim by ID
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

  const claim = await claimService.getClaimById(claimId);
  res.json(success(claim));
});

/**
 * Get claim by reference
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

  const claim = await claimService.getClaimByReference(reference);
  res.json(success(claim));
});

/**
 * Check coverage for contract and guarantee
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

  const coverage = await claimService.checkCoverage(contId, guaranteeCode);
  res.json(success(coverage));
});

/**
 * Validate claim before creation
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

  const validation = await claimService.validateClaim(claimData);
  res.json(success(validation));
});

/**
 * Get claims statistics
 * GET /api/claims/stats
 */
const getClaimsStats = asyncHandler(async (req, res) => {
  // This will be used for dashboard
  const sql = `
    SELECT
      COUNT(*) AS TOTAL_CLAIMS,
      SUM(CASE WHEN STATUS = 'NEW' THEN 1 ELSE 0 END) AS NEW_CLAIMS,
      SUM(CASE WHEN STATUS = 'REV' THEN 1 ELSE 0 END) AS UNDER_REVIEW,
      SUM(CASE WHEN STATUS = 'APP' THEN 1 ELSE 0 END) AS APPROVED_CLAIMS,
      SUM(CASE WHEN STATUS = 'REJ' THEN 1 ELSE 0 END) AS REJECTED_CLAIMS,
      SUM(CASE WHEN STATUS = 'CLS' THEN 1 ELSE 0 END) AS CLOSED_CLAIMS,
      SUM(CASE WHEN RESOLUTION_TYPE = 'AMI' THEN 1 ELSE 0 END) AS AMICABLE_RESOLUTIONS,
      SUM(CASE WHEN RESOLUTION_TYPE = 'TRI' THEN 1 ELSE 0 END) AS TRIBUNAL_RESOLUTIONS,
      SUM(CLAIMED_AMOUNT) AS TOTAL_CLAIMED,
      SUM(APPROVED_AMOUNT) AS TOTAL_APPROVED,
      AVG(CLAIMED_AMOUNT) AS AVG_CLAIMED,
      AVG(APPROVED_AMOUNT) AS AVG_APPROVED
    FROM CLAIM
  `;

  const { query } = require('../config/database');
  const result = await query(sql);

  const stats = result[0];

  // Calculate amicable resolution rate (target: 79%)
  const totalResolved = (stats.AMICABLE_RESOLUTIONS || 0) + (stats.TRIBUNAL_RESOLUTIONS || 0);
  const amicableRate = totalResolved > 0
    ? Math.round((stats.AMICABLE_RESOLUTIONS / totalResolved) * 100)
    : 0;

  const response = {
    totalClaims: stats.TOTAL_CLAIMS || 0,
    newClaims: stats.NEW_CLAIMS || 0,
    underReview: stats.UNDER_REVIEW || 0,
    approvedClaims: stats.APPROVED_CLAIMS || 0,
    rejectedClaims: stats.REJECTED_CLAIMS || 0,
    closedClaims: stats.CLOSED_CLAIMS || 0,
    amicableResolutions: stats.AMICABLE_RESOLUTIONS || 0,
    tribunalResolutions: stats.TRIBUNAL_RESOLUTIONS || 0,
    amicableRate: amicableRate,
    amicableRateTarget: 79, // DAS Belgium target
    totalClaimed: parseFloat(stats.TOTAL_CLAIMED || 0),
    totalApproved: parseFloat(stats.TOTAL_APPROVED || 0),
    avgClaimed: parseFloat(stats.AVG_CLAIMED || 0),
    avgApproved: parseFloat(stats.AVG_APPROVED || 0)
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

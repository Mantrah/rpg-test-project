/**
 * Claim Controller
 * HTTP request handlers for claim endpoints
 * Uses RPG backend via iToolkit for business operations
 */

const rpgConnector = require('../config/rpgConnector');
const { query } = require('../config/database');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { STATUS, BUSINESS_RULES } = require('../config/constants');

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
 * Get all claims - SQL read-only
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

  let sql = 'SELECT * FROM CLAIM';
  const params = [];
  if (status) {
    sql += ' WHERE STATUS = ?';
    params.push(status);
  }
  sql += ' ORDER BY DECLARATION_DATE DESC';
  const claims = await query(sql, params);
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
 * Get claim by reference - SQL read-only
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

  const sql = 'SELECT * FROM CLAIM WHERE CLAIM_REFERENCE = ?';
  const result = await query(sql, [reference]);
  if (!result || result.length === 0) {
    const error = new Error('Claim not found');
    error.statusCode = 404;
    throw error;
  }
  res.json(success(result[0]));
});

/**
 * Check coverage for contract and guarantee - SQL read-only
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

  const sql = `
    SELECT 1 AS IS_COVERED
    FROM CONTRACT C
    JOIN PRODUCT_GUARANTEE PG ON C.PRODUCT_ID = PG.PRODUCT_ID
    WHERE C.CONT_ID = ? AND PG.GUARANTEE_CODE = ? AND C.STATUS = 'ACT'
  `;
  const result = await query(sql, [contId, guaranteeCode]);
  const isCovered = result && result.length > 0;
  res.json(success({ isCovered, contId, guaranteeCode }));
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
 * Get claims statistics - SQL read-only
 * GET /api/claims/stats
 */
const getClaimsStats = asyncHandler(async (req, res) => {
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

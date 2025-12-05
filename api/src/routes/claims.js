/**
 * Claim Routes
 * Handles claim management and validation endpoints
 */

const express = require('express');
const router = express.Router();
const claimController = require('../controllers/claimController');

/**
 * @route   GET /api/claims/stats
 * @desc    Get claims statistics for dashboard
 * @access  Public
 */
router.get('/stats', claimController.getClaimsStats);

/**
 * @route   POST /api/claims/check-coverage
 * @desc    Check if guarantee is covered by contract
 * @access  Public
 * @body    contId, guaranteeCode
 */
router.post('/check-coverage', claimController.checkCoverage);

/**
 * @route   POST /api/claims/validate
 * @desc    Validate claim before creation (coverage, threshold, waiting period)
 * @access  Public
 * @body    contId, guaranteeCode, claimedAmount, incidentDate
 */
router.post('/validate', claimController.validateClaim);

/**
 * @route   POST /api/claims
 * @desc    Create new claim
 * @access  Public
 * @body    contId, guaranteeCode, circumstanceCode, declarationDate, incidentDate, description, claimedAmount
 */
router.post('/', claimController.createClaim);

/**
 * @route   GET /api/claims
 * @desc    Get all claims (optional status filter)
 * @access  Public
 * @query   status - Filter by status (NEW, REV, APP, REJ, CLS)
 */
router.get('/', claimController.getAllClaims);

/**
 * @route   GET /api/claims/reference/:reference
 * @desc    Get claim by reference
 * @access  Public
 */
router.get('/reference/:reference', claimController.getClaimByReference);

/**
 * @route   GET /api/claims/:id
 * @desc    Get claim by ID
 * @access  Public
 */
router.get('/:id', claimController.getClaimById);

module.exports = router;

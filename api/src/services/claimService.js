/**
 * Claim Service
 * Business logic for claim operations
 */

const { callProcedure, query } = require('../config/database');
const { STATUS, BUSINESS_RULES } = require('../config/constants');

/**
 * Create new claim
 * @param {Object} claimData - Claim data
 * @returns {Promise<Object>} Created claim with ID, reference, and file reference
 */
const createClaim = async (claimData) => {
  const {
    contId,
    guaranteeCode,
    circumstanceCode,
    declarationDate,
    incidentDate,
    description,
    claimedAmount
  } = claimData;

  // Validate minimum threshold (€350)
  if (claimedAmount > 0 && claimedAmount < BUSINESS_RULES.MIN_CLAIM_THRESHOLD) {
    throw {
      code: 'BUS006',
      message: `Claim amount must be at least €${BUSINESS_RULES.MIN_CLAIM_THRESHOLD}`
    };
  }

  // Call SP_CreateClaim - it returns OUT parameters via result set
  // We need to handle this differently
  const sql = `
    CALL SP_CreateClaim(?, ?, ?, ?, ?, ?, ?)
  `;

  await query(sql, [
    contId,
    guaranteeCode,
    circumstanceCode,
    declarationDate,
    incidentDate,
    description,
    claimedAmount
  ]);

  // Get the generated claim ID
  const lastIdResult = await query(
    'SELECT IDENTITY_VAL_LOCAL() AS CLAIM_ID FROM SYSIBM.SYSDUMMY1'
  );

  const claimId = lastIdResult[0].CLAIM_ID;

  // Get the full claim with references
  const claimResult = await query(
    'SELECT CLAIM_ID, CLAIM_REFERENCE, FILE_REFERENCE FROM CLAIM WHERE CLAIM_ID = ?',
    [claimId]
  );

  return {
    claimId: claimResult[0].CLAIM_ID,
    claimReference: claimResult[0].CLAIM_REFERENCE,
    fileReference: claimResult[0].FILE_REFERENCE,
    ...claimData
  };
};

/**
 * Get claim by ID
 * @param {number} claimId - Claim ID
 * @returns {Promise<Object>} Claim details with related data
 */
const getClaimById = async (claimId) => {
  const result = await callProcedure('SP_GetClaim', [claimId]);

  if (result.length === 0) {
    throw { code: 'DB001', message: 'Claim not found' };
  }

  return result[0];
};

/**
 * List all claims
 * @param {string} status - Optional status filter
 * @returns {Promise<Array>} List of claims
 */
const listClaims = async (status = null) => {
  let sql = `
    SELECT
      CL.CLAIM_ID,
      CL.CLAIM_REFERENCE,
      CL.FILE_REFERENCE,
      CL.CONT_ID,
      CL.GUARANTEE_CODE,
      CL.CIRCUMSTANCE_CODE,
      CL.DECLARATION_DATE,
      CL.INCIDENT_DATE,
      CL.CLAIMED_AMOUNT,
      CL.APPROVED_AMOUNT,
      CL.RESOLUTION_TYPE,
      CL.STATUS,
      CL.CREATED_AT,
      -- Contract info
      C.CONT_REFERENCE,
      -- Customer info
      CASE
        WHEN CUST.CUST_TYPE = 'IND' THEN TRIM(CUST.FIRST_NAME) || ' ' || TRIM(CUST.LAST_NAME)
        ELSE CUST.COMPANY_NAME
      END AS CUSTOMER_NAME,
      -- Product info
      P.PRODUCT_CODE,
      P.PRODUCT_NAME,
      -- Guarantee info
      G.GUARANTEE_NAME
    FROM CLAIM CL
    LEFT JOIN CONTRACT C ON CL.CONT_ID = C.CONT_ID
    LEFT JOIN CUSTOMER CUST ON C.CUST_ID = CUST.CUST_ID
    LEFT JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID
    LEFT JOIN GUARANTEE G ON P.PRODUCT_ID = G.PRODUCT_ID
                          AND CL.GUARANTEE_CODE = G.GUARANTEE_CODE
  `;

  const params = [];

  if (status) {
    sql += ' WHERE CL.STATUS = ?';
    params.push(status);
  }

  sql += ' ORDER BY CL.DECLARATION_DATE DESC';

  return await query(sql, params);
};

/**
 * Get claim by reference
 * @param {string} claimReference - Claim reference (e.g., 'SIN-2025-000045')
 * @returns {Promise<Object>} Claim details
 */
const getClaimByReference = async (claimReference) => {
  const sql = `
    SELECT * FROM CLAIM
    WHERE TRIM(CLAIM_REFERENCE) = TRIM(?)
  `;

  const result = await query(sql, [claimReference]);

  if (result.length === 0) {
    throw { code: 'DB001', message: 'Claim not found' };
  }

  return result[0];
};

/**
 * Check if guarantee is covered by contract
 * @param {number} contId - Contract ID
 * @param {string} guaranteeCode - Guarantee code
 * @returns {Promise<Object>} Coverage validation result
 */
const checkCoverage = async (contId, guaranteeCode) => {
  // For SP_IsCovered, we need to handle OUT parameters
  // Since ODBC doesn't easily handle OUT params, we'll use direct SQL logic
  const sql = `
    SELECT
      C.CONT_ID,
      C.CONT_REFERENCE,
      C.START_DATE,
      C.STATUS AS CONTRACT_STATUS,
      P.PRODUCT_ID,
      P.PRODUCT_CODE,
      P.PRODUCT_NAME,
      P.WAITING_MONTHS AS PRODUCT_WAITING_MONTHS,
      G.GUARANTEE_ID,
      G.GUARANTEE_CODE,
      G.GUARANTEE_NAME,
      G.WAITING_MONTHS AS GUARANTEE_WAITING_MONTHS,
      COALESCE(G.WAITING_MONTHS, P.WAITING_MONTHS) AS EFFECTIVE_WAITING_MONTHS
    FROM CONTRACT C
    LEFT JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID
    LEFT JOIN GUARANTEE G ON P.PRODUCT_ID = G.PRODUCT_ID
                          AND G.GUARANTEE_CODE = ?
                          AND G.STATUS = 'ACT'
    WHERE C.CONT_ID = ?
      AND C.STATUS = 'ACT'
      AND P.STATUS = 'ACT'
  `;

  const result = await query(sql, [guaranteeCode, contId]);

  if (result.length === 0) {
    return {
      isCovered: false,
      reason: 'Contract not found or not active',
      waitingMonths: null,
      waitingEndDate: null
    };
  }

  const data = result[0];

  // Check if guarantee exists for this product
  if (!data.GUARANTEE_ID) {
    return {
      isCovered: false,
      reason: 'Guarantee not covered by this product',
      contractReference: data.CONT_REFERENCE,
      productCode: data.PRODUCT_CODE,
      productName: data.PRODUCT_NAME,
      waitingMonths: null,
      waitingEndDate: null
    };
  }

  // Calculate waiting period end date
  const startDate = new Date(data.START_DATE);
  const waitingMonths = data.EFFECTIVE_WAITING_MONTHS || 0;
  const waitingEndDate = new Date(startDate);
  waitingEndDate.setMonth(waitingEndDate.getMonth() + waitingMonths);

  const today = new Date();
  const isWaitingPeriodOver = today >= waitingEndDate;

  return {
    isCovered: true,
    isWaitingPeriodOver: isWaitingPeriodOver,
    contractReference: data.CONT_REFERENCE,
    productCode: data.PRODUCT_CODE,
    productName: data.PRODUCT_NAME,
    guaranteeCode: data.GUARANTEE_CODE,
    guaranteeName: data.GUARANTEE_NAME,
    waitingMonths: waitingMonths,
    waitingEndDate: waitingEndDate.toISOString().split('T')[0],
    contractStartDate: data.START_DATE,
    daysUntilCoverage: isWaitingPeriodOver ? 0 : Math.ceil((waitingEndDate - today) / (1000 * 60 * 60 * 24))
  };
};

/**
 * Validate claim before creation
 * @param {Object} claimData - Claim data to validate
 * @returns {Promise<Object>} Validation result
 */
const validateClaim = async (claimData) => {
  const { contId, guaranteeCode, claimedAmount, incidentDate } = claimData;

  const validationResult = {
    isValid: true,
    errors: [],
    warnings: []
  };

  // Check coverage
  const coverage = await checkCoverage(contId, guaranteeCode);

  if (!coverage.isCovered) {
    validationResult.isValid = false;
    validationResult.errors.push({
      code: 'BUS001',
      field: 'guaranteeCode',
      message: coverage.reason
    });
  } else if (!coverage.isWaitingPeriodOver) {
    validationResult.isValid = false;
    validationResult.errors.push({
      code: 'BUS002',
      field: 'guaranteeCode',
      message: `Waiting period not over. Coverage starts on ${coverage.waitingEndDate} (${coverage.daysUntilCoverage} days remaining)`
    });
  }

  // Check minimum threshold
  if (claimedAmount > 0 && claimedAmount < BUSINESS_RULES.MIN_CLAIM_THRESHOLD) {
    validationResult.isValid = false;
    validationResult.errors.push({
      code: 'BUS006',
      field: 'claimedAmount',
      message: `Claim amount must be at least €${BUSINESS_RULES.MIN_CLAIM_THRESHOLD}`
    });
  }

  // Check coverage limit
  if (claimedAmount > BUSINESS_RULES.COVERAGE_LIMIT_MAX) {
    validationResult.warnings.push({
      code: 'BUS003',
      field: 'claimedAmount',
      message: `Claim amount exceeds standard coverage limit of €${BUSINESS_RULES.COVERAGE_LIMIT_MAX}`
    });
  }

  return {
    ...validationResult,
    coverage
  };
};

module.exports = {
  createClaim,
  getClaimById,
  listClaims,
  getClaimByReference,
  checkCoverage,
  validateClaim
};

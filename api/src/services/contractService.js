/**
 * Contract Service
 * Business logic for contract operations
 */

const { callProcedure, query } = require('../config/database');
const { STATUS, PAYMENT_FREQUENCY } = require('../config/constants');

/**
 * Create new contract
 * @param {Object} contractData - Contract data
 * @returns {Promise<Object>} Created contract with ID and reference
 */
const createContract = async (contractData) => {
  const {
    brokerId,
    custId,
    productCode,
    startDate,
    endDate,
    vehiclesCount,
    totalPremium,
    payFrequency,
    autoRenewal,
    notes
  } = contractData;

  // Call SP_CreateContract
  await callProcedure('SP_CreateContract', [
    brokerId,
    custId,
    productCode,
    startDate,
    endDate,
    vehiclesCount,
    totalPremium,
    payFrequency,
    autoRenewal || 'N',
    notes || null
  ]);

  // Get the generated contract ID and reference
  const lastIdResult = await query(
    'SELECT IDENTITY_VAL_LOCAL() AS CONT_ID FROM SYSIBM.SYSDUMMY1'
  );

  const contId = lastIdResult[0].CONT_ID;

  // Get the full contract with reference
  const contractResult = await query(
    'SELECT CONT_ID, CONT_REFERENCE FROM CONTRACT WHERE CONT_ID = ?',
    [contId]
  );

  return {
    contId: contractResult[0].CONT_ID,
    contReference: contractResult[0].CONT_REFERENCE,
    ...contractData
  };
};

/**
 * Get contract by ID
 * @param {number} contId - Contract ID
 * @returns {Promise<Object>} Contract details with related data
 */
const getContractById = async (contId) => {
  const result = await callProcedure('SP_GetContract', [contId]);

  if (result.length === 0) {
    throw { code: 'DB001', message: 'Contract not found' };
  }

  return result[0];
};

/**
 * List all contracts
 * @param {string} status - Optional status filter (ACT, SUS, CLS, EXP)
 * @returns {Promise<Array>} List of contracts
 */
const listContracts = async (status = null) => {
  const result = await callProcedure('SP_ListContracts', [status]);
  return result;
};

/**
 * Get contract by reference
 * @param {string} contReference - Contract reference (e.g., 'DAS-2025-00001-000123')
 * @returns {Promise<Object>} Contract details
 */
const getContractByReference = async (contReference) => {
  const sql = `
    SELECT
      CT.CONT_ID,
      CT.CONT_REFERENCE,
      CT.BROKER_ID,
      CT.CUST_ID,
      CT.PRODUCT_ID,
      CT.START_DATE,
      CT.END_DATE,
      CT.STATUS,
      CT.VEHICLES_COUNT,
      CT.TOTAL_PREMIUM,
      CT.PAY_FREQUENCY,
      CT.AUTO_RENEWAL,
      CT.NOTES,
      CT.CREATED_AT,
      CT.UPDATED_AT
    FROM CONTRACT CT
    WHERE TRIM(CT.CONT_REFERENCE) = TRIM(?)
  `;

  const result = await query(sql, [contReference]);

  if (result.length === 0) {
    throw { code: 'DB001', message: 'Contract not found' };
  }

  return result[0];
};

/**
 * Get contracts for a broker
 * @param {number} brokerId - Broker ID
 * @returns {Promise<Array>} List of broker's contracts
 */
const getBrokerContracts = async (brokerId) => {
  const sql = `
    SELECT
      CT.CONT_ID,
      CT.CONT_REFERENCE,
      CT.START_DATE,
      CT.END_DATE,
      CT.STATUS,
      CT.TOTAL_PREMIUM,
      CUST.CUST_TYPE,
      CASE
        WHEN CUST.CUST_TYPE = 'IND' THEN TRIM(CUST.FIRST_NAME) || ' ' || TRIM(CUST.LAST_NAME)
        ELSE CUST.COMPANY_NAME
      END AS CUSTOMER_NAME,
      P.PRODUCT_CODE,
      P.PRODUCT_NAME
    FROM CONTRACT CT
    LEFT JOIN CUSTOMER CUST ON CT.CUST_ID = CUST.CUST_ID
    LEFT JOIN PRODUCT P ON CT.PRODUCT_ID = P.PRODUCT_ID
    WHERE CT.BROKER_ID = ?
    ORDER BY CT.START_DATE DESC
  `;

  return await query(sql, [brokerId]);
};

/**
 * Get claims for a contract
 * @param {number} contId - Contract ID
 * @returns {Promise<Array>} List of contract claims
 */
const getContractClaims = async (contId) => {
  const sql = `
    SELECT
      CL.CLAIM_ID,
      CL.CLAIM_REFERENCE,
      CL.FILE_REFERENCE,
      CL.GUARANTEE_CODE,
      CL.CIRCUMSTANCE_CODE,
      CL.DECLARATION_DATE,
      CL.INCIDENT_DATE,
      CL.CLAIMED_AMOUNT,
      CL.APPROVED_AMOUNT,
      CL.STATUS,
      G.GUARANTEE_NAME
    FROM CLAIM CL
    LEFT JOIN GUARANTEE G ON CL.GUARANTEE_CODE = G.GUARANTEE_CODE
    WHERE CL.CONT_ID = ?
    ORDER BY CL.DECLARATION_DATE DESC
  `;

  return await query(sql, [contId]);
};

/**
 * Calculate premium for contract
 * @param {string} productCode - Product code
 * @param {number} vehiclesCount - Number of vehicles
 * @param {string} payFrequency - Payment frequency (A, Q, M)
 * @returns {Promise<Object>} Calculated premium
 */
const calculatePremium = async (productCode, vehiclesCount, payFrequency) => {
  const result = await callProcedure('SP_CalculatePremium', [
    productCode,
    vehiclesCount,
    payFrequency
  ]);

  // SP uses OUT parameter, need to handle differently
  // For now, use direct calculation like in productService
  const productService = require('./productService');
  return await productService.calculateFullPremium(
    productCode,
    vehiclesCount,
    payFrequency
  );
};

module.exports = {
  createContract,
  getContractById,
  listContracts,
  getContractByReference,
  getBrokerContracts,
  getContractClaims,
  calculatePremium
};

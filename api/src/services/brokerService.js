/**
 * Broker Service
 * Business logic for broker operations
 * Calls SQL stored procedures (SP_CreateBroker, SP_GetBroker, etc.)
 */

const { callProcedure, query } = require('../config/database');

/**
 * Create a new broker
 * @param {Object} brokerData - Broker information
 * @returns {Promise<Object>} - Created broker with ID
 */
const createBroker = async (brokerData) => {
  const {
    brokerCode,
    companyName,
    vatNumber = '',
    fsmaNumber = '',
    street = '',
    houseNbr = '',
    boxNbr = '',
    postalCode = '',
    city = '',
    countryCode = 'BEL',
    phone = '',
    email = '',
    contactName = ''
  } = brokerData;

  // Call SP_CreateBroker
  const result = await callProcedure('SP_CreateBroker', [
    brokerCode,
    companyName,
    vatNumber,
    fsmaNumber,
    street,
    houseNbr,
    boxNbr,
    postalCode,
    city,
    countryCode,
    phone,
    email,
    contactName
  ]);

  // Get the generated broker ID from output parameter
  // Note: ODBC returns output parameters differently depending on driver
  // For MVP, we'll query the last inserted ID
  const lastIdResult = await query('SELECT IDENTITY_VAL_LOCAL() AS BROKER_ID FROM SYSIBM.SYSDUMMY1');
  const brokerId = lastIdResult[0].BROKER_ID;

  return {
    brokerId,
    brokerCode,
    companyName,
    ...brokerData
  };
};

/**
 * Get broker by ID
 * @param {number} brokerId - Broker ID
 * @returns {Promise<Object>} - Broker data
 */
const getBroker = async (brokerId) => {
  const result = await callProcedure('SP_GetBroker', [brokerId]);

  if (!result || result.length === 0) {
    const error = new Error('Broker not found');
    error.code = 'DB001';
    throw error;
  }

  return result[0];
};

/**
 * List all brokers with optional status filter
 * @param {string} status - Optional status filter ('ACT', 'INA', etc.)
 * @returns {Promise<Array>} - Array of brokers
 */
const listBrokers = async (status = 'ACT') => {
  const result = await callProcedure('SP_ListBrokers', [status]);
  return result || [];
};

/**
 * Get broker by code
 * @param {string} brokerCode - Broker code
 * @returns {Promise<Object>} - Broker data
 */
const getBrokerByCode = async (brokerCode) => {
  const sql = `
    SELECT * FROM BROKER
    WHERE BROKER_CODE = ?
      AND STATUS = 'ACT'
  `;

  const result = await query(sql, [brokerCode]);

  if (!result || result.length === 0) {
    const error = new Error('Broker not found');
    error.code = 'DB001';
    throw error;
  }

  return result[0];
};

module.exports = {
  createBroker,
  getBroker,
  listBrokers,
  getBrokerByCode
};

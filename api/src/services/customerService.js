/**
 * Customer Service
 * Business logic for customer operations
 */

const { callProcedure, query } = require('../config/database');
const { CUSTOMER_TYPE, STATUS } = require('../config/constants');

/**
 * Create new customer (Individual or Business)
 * @param {Object} customerData - Customer data
 * @returns {Promise<Object>} Created customer with ID
 */
const createCustomer = async (customerData) => {
  const {
    custType,
    firstName,
    lastName,
    companyName,
    vatNumber,
    nrnNumber,
    birthDate,
    street,
    houseNbr,
    boxNbr,
    postalCode,
    city,
    countryCode,
    phone,
    mobile,
    email,
    language
  } = customerData;

  // Call SP_CreateCustomer
  await callProcedure('SP_CreateCustomer', [
    custType,
    firstName || null,
    lastName || null,
    companyName || null,
    vatNumber || null,
    nrnNumber || null,
    birthDate || null,
    street,
    houseNbr,
    boxNbr || null,
    postalCode,
    city,
    countryCode,
    phone || null,
    mobile || null,
    email,
    language
  ]);

  // Get the generated customer ID
  const lastIdResult = await query(
    'SELECT IDENTITY_VAL_LOCAL() AS CUST_ID FROM SYSIBM.SYSDUMMY1'
  );

  return {
    custId: lastIdResult[0].CUST_ID,
    ...customerData
  };
};

/**
 * Get customer by ID
 * @param {number} custId - Customer ID
 * @returns {Promise<Object>} Customer details
 */
const getCustomerById = async (custId) => {
  const result = await callProcedure('SP_GetCustomer', [custId]);

  if (result.length === 0) {
    throw { code: 'DB001', message: 'Customer not found' };
  }

  return result[0];
};

/**
 * List all customers
 * @param {string} status - Optional status filter (ACT, SUS, CLS)
 * @returns {Promise<Array>} List of customers
 */
const listCustomers = async (status = null) => {
  const result = await callProcedure('SP_ListCustomers', [status]);
  return result;
};

/**
 * Get customer by email
 * @param {string} email - Customer email
 * @returns {Promise<Object>} Customer details
 */
const getCustomerByEmail = async (email) => {
  const sql = `
    SELECT * FROM CUSTOMER
    WHERE TRIM(EMAIL) = TRIM(?)
      AND STATUS = 'ACT'
  `;

  const result = await query(sql, [email]);

  if (result.length === 0) {
    throw { code: 'DB001', message: 'Customer not found' };
  }

  return result[0];
};

/**
 * Get customer contracts
 * @param {number} custId - Customer ID
 * @returns {Promise<Array>} List of customer contracts
 */
const getCustomerContracts = async (custId) => {
  const sql = `
    SELECT
      CT.CONT_ID,
      CT.CONT_REFERENCE,
      CT.START_DATE,
      CT.END_DATE,
      CT.STATUS,
      P.PRODUCT_CODE,
      P.PRODUCT_NAME,
      CT.TOTAL_PREMIUM
    FROM CONTRACT CT
    LEFT JOIN PRODUCT P ON CT.PRODUCT_ID = P.PRODUCT_ID
    WHERE CT.CUST_ID = ?
    ORDER BY CT.START_DATE DESC
  `;

  return await query(sql, [custId]);
};

module.exports = {
  createCustomer,
  getCustomerById,
  listCustomers,
  getCustomerByEmail,
  getCustomerContracts
};

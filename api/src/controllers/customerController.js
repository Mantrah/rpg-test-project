/**
 * Customer Controller
 * HTTP request handlers for customer endpoints
 * Uses RPG backend via iToolkit for business operations
 */

const rpgConnector = require('../config/rpgConnector');
const { query } = require('../config/database');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { CUSTOMER_TYPE, STATUS } = require('../config/constants');

/**
 * Create new customer via RPG
 * POST /api/customers
 */
const createCustomer = asyncHandler(async (req, res) => {
  const customerData = req.body;

  // Validate customer type
  if (!CUSTOMER_TYPE[customerData.custType]) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid customer type. Must be IND or BUS.'
      }
    });
  }

  // Type-specific validation
  if (customerData.custType === 'IND') {
    if (!customerData.firstName || !customerData.lastName) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VAL002',
          message: 'First name and last name required for individual customers.'
        }
      });
    }
  } else if (customerData.custType === 'BUS') {
    if (!customerData.companyName) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VAL002',
          message: 'Company name required for business customers.'
        }
      });
    }
  }

  const customer = await rpgConnector.createCustomer(customerData);
  res.status(201).json(success(customer, 'Customer created successfully'));
});

/**
 * Get all customers - SQL read-only
 * GET /api/customers?status=ACT
 */
const getAllCustomers = asyncHandler(async (req, res) => {
  const { status } = req.query;

  // Validate status if provided
  if (status && !STATUS[status]) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid status. Must be ACT, SUS, or CLS.'
      }
    });
  }

  let sql = 'SELECT * FROM CUSTOMER';
  const params = [];
  if (status) {
    sql += ' WHERE STATUS = ?';
    params.push(status);
  }
  sql += ' ORDER BY LAST_NAME, FIRST_NAME';
  const customers = await query(sql, params);
  res.json(success(customers));
});

/**
 * Get customer by ID via RPG
 * GET /api/customers/:id
 */
const getCustomerById = asyncHandler(async (req, res) => {
  const custId = parseInt(req.params.id, 10);

  if (isNaN(custId)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid customer ID format.'
      }
    });
  }

  const customer = await rpgConnector.getCustomerById(custId);
  res.json(success(customer));
});

/**
 * Get customer by email - SQL read-only
 * GET /api/customers/email/:email
 */
const getCustomerByEmail = asyncHandler(async (req, res) => {
  const { email } = req.params;

  if (!email || !email.includes('@')) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid email format.'
      }
    });
  }

  const sql = 'SELECT * FROM CUSTOMER WHERE EMAIL = ?';
  const result = await query(sql, [email]);
  if (!result || result.length === 0) {
    const error = new Error('Customer not found');
    error.statusCode = 404;
    throw error;
  }
  res.json(success(result[0]));
});

/**
 * Get customer contracts - SQL read-only
 * GET /api/customers/:id/contracts
 */
const getCustomerContracts = asyncHandler(async (req, res) => {
  const custId = parseInt(req.params.id, 10);

  if (isNaN(custId)) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL001',
        message: 'Invalid customer ID format.'
      }
    });
  }

  const sql = 'SELECT * FROM CONTRACT WHERE CUST_ID = ? ORDER BY START_DATE DESC';
  const contracts = await query(sql, [custId]);
  res.json(success(contracts));
});

module.exports = {
  createCustomer,
  getAllCustomers,
  getCustomerById,
  getCustomerByEmail,
  getCustomerContracts
};

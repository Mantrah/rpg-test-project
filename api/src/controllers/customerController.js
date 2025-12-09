/**
 * Customer Controller
 * HTTP request handlers for customer endpoints
 * All operations go through RPG backend via iToolkit
 */

const rpgConnector = require('../config/rpgConnector');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { CUSTOMER_TYPE, STATUS } = require('../config/constants');

/**
 * Create new customer via RPG
 * POST /api/customers
 */
const createCustomer = asyncHandler(async (req, res) => {
  const customerData = req.body;

  // DEBUG: Log received data
  console.log('[DEBUG] Received body:', JSON.stringify(customerData));
  console.log('[DEBUG] custType value:', customerData.custType);
  console.log('[DEBUG] custType type:', typeof customerData.custType);
  console.log('[DEBUG] Valid types:', Object.values(CUSTOMER_TYPE));

  // Validate customer type (IND or BUS)
  const validTypes = Object.values(CUSTOMER_TYPE);
  if (!validTypes.includes(customerData.custType)) {
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
 * Get all customers via RPG
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

  const customers = await rpgConnector.listCustomers(status || '');
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
 * Get customer by email via RPG
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

  const customer = await rpgConnector.getCustomerByEmail(email);
  res.json(success(customer));
});

/**
 * Get customer contracts via RPG
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

  const contracts = await rpgConnector.getCustomerContracts(custId);
  res.json(success(contracts));
});

/**
 * Delete customer via RPG (soft delete)
 * DELETE /api/customers/:id
 */
const deleteCustomer = asyncHandler(async (req, res) => {
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

  await rpgConnector.deleteCustomer(custId);
  res.json(success(null, 'Customer deleted successfully'));
});

module.exports = {
  createCustomer,
  getAllCustomers,
  getCustomerById,
  getCustomerByEmail,
  getCustomerContracts,
  deleteCustomer
};

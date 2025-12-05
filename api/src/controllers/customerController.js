/**
 * Customer Controller
 * HTTP request handlers for customer endpoints
 */

const customerService = require('../services/customerService');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');
const { CUSTOMER_TYPE, STATUS } = require('../config/constants');

/**
 * Create new customer
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

  const customer = await customerService.createCustomer(customerData);
  res.status(201).json(success(customer, 'Customer created successfully'));
});

/**
 * Get all customers
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

  const customers = await customerService.listCustomers(status || null);
  res.json(success(customers));
});

/**
 * Get customer by ID
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

  const customer = await customerService.getCustomerById(custId);
  res.json(success(customer));
});

/**
 * Get customer by email
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

  const customer = await customerService.getCustomerByEmail(email);
  res.json(success(customer));
});

/**
 * Get customer contracts
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

  const contracts = await customerService.getCustomerContracts(custId);
  res.json(success(contracts));
});

module.exports = {
  createCustomer,
  getAllCustomers,
  getCustomerById,
  getCustomerByEmail,
  getCustomerContracts
};

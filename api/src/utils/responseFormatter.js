/**
 * Response Formatter
 * Standardizes API responses
 */

const { ERROR_CODES } = require('../config/constants');

/**
 * Success response
 * @param {*} data - Response data
 * @param {string} message - Optional message
 * @returns {Object} - Formatted response
 */
const success = (data, message = null) => {
  const response = {
    success: true,
    data
  };

  if (message) {
    response.message = message;
  }

  return response;
};

/**
 * Error response
 * @param {string} code - Error code (VAL*, BUS*, DB*)
 * @param {string} message - Error message
 * @param {Object} details - Additional error details
 * @returns {Object} - Formatted error response
 */
const error = (code, message = null, details = null) => {
  const response = {
    success: false,
    error: {
      code,
      message: message || ERROR_CODES[code] || 'Unknown error'
    }
  };

  if (details) {
    response.error.details = details;
  }

  return response;
};

/**
 * Map error code to HTTP status
 * @param {string} code - Error code
 * @returns {number} - HTTP status code
 */
const getHttpStatus = (code) => {
  if (code.startsWith('VAL')) return 400; // Bad Request
  if (code.startsWith('BUS')) return 422; // Unprocessable Entity
  if (code === 'DB001') return 404;       // Not Found
  if (code === 'DB002') return 409;       // Conflict
  if (code === 'DB004') return 500;       // Internal Server Error

  return 500; // Default to Internal Server Error
};

/**
 * Paginated response
 * @param {Array} data - Data array
 * @param {number} total - Total count
 * @param {number} page - Current page
 * @param {number} limit - Items per page
 * @returns {Object} - Paginated response
 */
const paginated = (data, total, page = 1, limit = 20) => {
  return {
    success: true,
    data,
    pagination: {
      total,
      page,
      limit,
      pages: Math.ceil(total / limit)
    }
  };
};

module.exports = {
  success,
  error,
  getHttpStatus,
  paginated
};

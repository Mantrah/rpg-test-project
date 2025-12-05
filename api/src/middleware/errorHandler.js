/**
 * Error Handler Middleware
 * Catches and formats errors consistently
 */

const { error, getHttpStatus } = require('../utils/responseFormatter');

/**
 * Global error handler
 */
const errorHandler = (err, req, res, next) => {
  console.error('❌ Error:', err);

  // Default error response
  let code = 'DB004';
  let message = err.message || 'Internal server error';
  let details = null;

  // Extract error code if present
  if (err.code) {
    code = err.code;
  }

  // Extract details if present
  if (err.details) {
    details = err.details;
  }

  // ODBC-specific errors
  if (err.odbcErrors) {
    message = err.odbcErrors[0]?.message || message;
    code = 'DB004';
  }

  const status = getHttpStatus(code);
  res.status(status).json(error(code, message, details));
};

/**
 * 404 Not Found handler
 */
const notFoundHandler = (req, res) => {
  res.status(404).json(error('DB001', `Route not found: ${req.method} ${req.path}`));
};

/**
 * Async error wrapper
 * Wraps async route handlers to catch errors
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  errorHandler,
  notFoundHandler,
  asyncHandler
};

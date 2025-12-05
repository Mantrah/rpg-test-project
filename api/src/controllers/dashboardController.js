/**
 * Dashboard Controller
 * HTTP request handlers for dashboard endpoints
 */

const dashboardService = require('../services/dashboardService');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Get dashboard statistics
 * GET /api/dashboard/stats
 */
const getDashboardStats = asyncHandler(async (req, res) => {
  const stats = await dashboardService.getDashboardStats();
  res.json(success(stats));
});

/**
 * Get broker statistics
 * GET /api/dashboard/brokers
 */
const getBrokerStats = asyncHandler(async (req, res) => {
  const stats = await dashboardService.getBrokerStats();
  res.json(success(stats));
});

/**
 * Get customer statistics
 * GET /api/dashboard/customers
 */
const getCustomerStats = asyncHandler(async (req, res) => {
  const stats = await dashboardService.getCustomerStats();
  res.json(success(stats));
});

/**
 * Get contract statistics
 * GET /api/dashboard/contracts
 */
const getContractStats = asyncHandler(async (req, res) => {
  const stats = await dashboardService.getContractStats();
  res.json(success(stats));
});

/**
 * Get claim statistics
 * GET /api/dashboard/claims
 */
const getClaimStats = asyncHandler(async (req, res) => {
  const stats = await dashboardService.getClaimStats();
  res.json(success(stats));
});

/**
 * Get revenue statistics
 * GET /api/dashboard/revenue
 */
const getRevenueStats = asyncHandler(async (req, res) => {
  const stats = await dashboardService.getRevenueStats();
  res.json(success(stats));
});

/**
 * Get claims by status (for pie chart)
 * GET /api/dashboard/claims-by-status
 */
const getClaimsByStatus = asyncHandler(async (req, res) => {
  const data = await dashboardService.getClaimsByStatus();
  res.json(success(data));
});

/**
 * Get recent claims
 * GET /api/dashboard/recent-claims?limit=5
 */
const getRecentClaims = asyncHandler(async (req, res) => {
  const limit = parseInt(req.query.limit, 10) || 10;

  if (limit < 1 || limit > 50) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VAL003',
        message: 'Limit must be between 1 and 50.'
      }
    });
  }

  const claims = await dashboardService.getRecentClaims(limit);
  res.json(success(claims));
});

/**
 * Get top products
 * GET /api/dashboard/top-products
 */
const getTopProducts = asyncHandler(async (req, res) => {
  const products = await dashboardService.getTopProducts();
  res.json(success(products));
});

module.exports = {
  getDashboardStats,
  getBrokerStats,
  getCustomerStats,
  getContractStats,
  getClaimStats,
  getRevenueStats,
  getClaimsByStatus,
  getRecentClaims,
  getTopProducts
};

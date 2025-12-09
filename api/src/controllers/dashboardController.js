/**
 * Dashboard Controller
 * HTTP request handlers for dashboard endpoints
 * ALL data access goes through RPG via rpgConnector
 */

const rpgConnector = require('../config/rpgConnector');
const { success } = require('../utils/responseFormatter');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Get dashboard statistics via RPG
 * GET /api/dashboard/stats
 */
const getDashboardStats = asyncHandler(async (req, res) => {
  const stats = await rpgConnector.getDashboardStats();
  res.json(success(stats));
});

/**
 * Get broker statistics via RPG
 * GET /api/dashboard/brokers
 */
const getBrokerStats = asyncHandler(async (req, res) => {
  const stats = await rpgConnector.getDashboardStats();
  res.json(success({
    total: stats.brokers.total,
    active: stats.brokers.active
  }));
});

/**
 * Get customer statistics via RPG
 * GET /api/dashboard/customers
 */
const getCustomerStats = asyncHandler(async (req, res) => {
  const stats = await rpgConnector.getDashboardStats();
  res.json(success({
    total: stats.customers.total,
    active: stats.customers.active
  }));
});

/**
 * Get contract statistics via RPG
 * GET /api/dashboard/contracts
 */
const getContractStats = asyncHandler(async (req, res) => {
  const stats = await rpgConnector.getDashboardStats();
  res.json(success({
    total: stats.contracts.total,
    active: stats.contracts.active
  }));
});

/**
 * Get claim statistics via RPG
 * GET /api/dashboard/claims
 */
const getClaimStats = asyncHandler(async (req, res) => {
  const stats = await rpgConnector.getDashboardStats();
  res.json(success({
    total: stats.claims.total,
    amicable: stats.claims.amicableResolutions,
    tribunal: stats.claims.tribunalResolutions,
    amicableRate: stats.claims.amicableRate,
    amicableRateTarget: stats.claims.amicableRateTarget
  }));
});

/**
 * Get revenue statistics via RPG
 * GET /api/dashboard/revenue
 */
const getRevenueStats = asyncHandler(async (req, res) => {
  // Get contracts and sum premiums
  const contracts = await rpgConnector.listContracts('ACT');
  const totalPremium = contracts.reduce((sum, c) => sum + (parseFloat(c.PREMIUM_AMT) || 0), 0);
  res.json(success({ totalPremium }));
});

/**
 * Get claims by status via RPG
 * GET /api/dashboard/claims-by-status
 */
const getClaimsByStatus = asyncHandler(async (req, res) => {
  const claims = await rpgConnector.listClaims('');

  // Group by status
  const statusCounts = {};
  claims.forEach(claim => {
    const status = claim.STATUS || 'UNK';
    statusCounts[status] = (statusCounts[status] || 0) + 1;
  });

  // Convert to array format
  const result = Object.entries(statusCounts)
    .map(([STATUS, COUNT]) => ({ STATUS, COUNT }))
    .sort((a, b) => b.COUNT - a.COUNT);

  res.json(success(result));
});

/**
 * Get recent claims via RPG
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

  const claims = await rpgConnector.listClaims('');
  // Claims are already sorted by DECLARATION_DATE DESC from RPG
  const recentClaims = claims.slice(0, limit);
  res.json(success(recentClaims));
});

/**
 * Get top products via RPG
 * GET /api/dashboard/top-products
 */
const getTopProducts = asyncHandler(async (req, res) => {
  const [products, contracts] = await Promise.all([
    rpgConnector.listProducts('ACT'),
    rpgConnector.listContracts('')
  ]);

  // Count contracts per product
  const productCounts = {};
  contracts.forEach(contract => {
    const productId = contract.PRODUCT_ID;
    productCounts[productId] = (productCounts[productId] || 0) + 1;
  });

  // Map products with contract counts
  const result = products
    .map(p => ({
      PRODUCT_CODE: p.PRODUCT_CODE,
      PRODUCT_NAME: p.PRODUCT_NAME,
      CONTRACT_COUNT: productCounts[p.PRODUCT_ID] || 0
    }))
    .sort((a, b) => b.CONTRACT_COUNT - a.CONTRACT_COUNT)
    .slice(0, 5);

  res.json(success(result));
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

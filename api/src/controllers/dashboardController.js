/**
 * Dashboard Controller
 * HTTP request handlers for dashboard endpoints
 * Uses RPG backend via iToolkit for main stats, SQL for read-only details
 */

const rpgConnector = require('../config/rpgConnector');
const { query } = require('../config/database');
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
 * Get broker statistics - SQL read-only
 * GET /api/dashboard/brokers
 */
const getBrokerStats = asyncHandler(async (req, res) => {
  const sql = `
    SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END) AS ACTIVE
    FROM BROKER
  `;
  const result = await query(sql);
  res.json(success({ total: result[0].TOTAL, active: result[0].ACTIVE }));
});

/**
 * Get customer statistics - SQL read-only
 * GET /api/dashboard/customers
 */
const getCustomerStats = asyncHandler(async (req, res) => {
  const sql = `
    SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END) AS ACTIVE
    FROM CUSTOMER
  `;
  const result = await query(sql);
  res.json(success({ total: result[0].TOTAL, active: result[0].ACTIVE }));
});

/**
 * Get contract statistics - SQL read-only
 * GET /api/dashboard/contracts
 */
const getContractStats = asyncHandler(async (req, res) => {
  const sql = `
    SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END) AS ACTIVE
    FROM CONTRACT
  `;
  const result = await query(sql);
  res.json(success({ total: result[0].TOTAL, active: result[0].ACTIVE }));
});

/**
 * Get claim statistics - SQL read-only
 * GET /api/dashboard/claims
 */
const getClaimStats = asyncHandler(async (req, res) => {
  const sql = `
    SELECT
      COUNT(*) AS TOTAL,
      SUM(CASE WHEN RESOLUTION_TYPE = 'AMI' THEN 1 ELSE 0 END) AS AMICABLE,
      SUM(CASE WHEN RESOLUTION_TYPE = 'TRI' THEN 1 ELSE 0 END) AS TRIBUNAL
    FROM CLAIM
  `;
  const result = await query(sql);
  const stats = result[0];
  const totalResolved = (stats.AMICABLE || 0) + (stats.TRIBUNAL || 0);
  const amicableRate = totalResolved > 0 ? Math.round((stats.AMICABLE / totalResolved) * 100) : 0;
  res.json(success({
    total: stats.TOTAL,
    amicable: stats.AMICABLE,
    tribunal: stats.TRIBUNAL,
    amicableRate,
    amicableRateTarget: 79
  }));
});

/**
 * Get revenue statistics - SQL read-only
 * GET /api/dashboard/revenue
 */
const getRevenueStats = asyncHandler(async (req, res) => {
  const sql = `
    SELECT SUM(PREMIUM_AMOUNT) AS TOTAL_PREMIUM
    FROM CONTRACT WHERE STATUS = 'ACT'
  `;
  const result = await query(sql);
  res.json(success({ totalPremium: parseFloat(result[0].TOTAL_PREMIUM || 0) }));
});

/**
 * Get claims by status (for pie chart) - SQL read-only
 * GET /api/dashboard/claims-by-status
 */
const getClaimsByStatus = asyncHandler(async (req, res) => {
  const sql = `
    SELECT STATUS, COUNT(*) AS COUNT
    FROM CLAIM
    GROUP BY STATUS
    ORDER BY COUNT DESC
  `;
  const result = await query(sql);
  res.json(success(result));
});

/**
 * Get recent claims - SQL read-only
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

  const sql = `SELECT * FROM CLAIM ORDER BY DECLARATION_DATE DESC FETCH FIRST ${limit} ROWS ONLY`;
  const claims = await query(sql);
  res.json(success(claims));
});

/**
 * Get top products - SQL read-only
 * GET /api/dashboard/top-products
 */
const getTopProducts = asyncHandler(async (req, res) => {
  const sql = `
    SELECT P.PRODUCT_CODE, P.PRODUCT_NAME, COUNT(C.CONT_ID) AS CONTRACT_COUNT
    FROM PRODUCT P
    LEFT JOIN CONTRACT C ON P.PRODUCT_ID = C.PRODUCT_ID
    GROUP BY P.PRODUCT_ID, P.PRODUCT_CODE, P.PRODUCT_NAME
    ORDER BY CONTRACT_COUNT DESC
    FETCH FIRST 5 ROWS ONLY
  `;
  const products = await query(sql);
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

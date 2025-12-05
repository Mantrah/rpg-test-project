/**
 * Dashboard Service
 * Business logic for dashboard KPIs and statistics
 */

const { query } = require('../config/database');
const { BUSINESS_RULES } = require('../config/constants');

/**
 * Get dashboard statistics
 * @returns {Promise<Object>} Dashboard KPIs
 */
const getDashboardStats = async () => {
  // Get all stats in parallel for performance
  const [
    brokerStats,
    customerStats,
    contractStats,
    claimStats,
    revenueStats,
    claimsByStatus,
    recentClaims,
    topProducts
  ] = await Promise.all([
    getBrokerStats(),
    getCustomerStats(),
    getContractStats(),
    getClaimStats(),
    getRevenueStats(),
    getClaimsByStatus(),
    getRecentClaims(5),
    getTopProducts()
  ]);

  return {
    brokers: brokerStats,
    customers: customerStats,
    contracts: contractStats,
    claims: claimStats,
    revenue: revenueStats,
    claimsByStatus: claimsByStatus,
    recentClaims: recentClaims,
    topProducts: topProducts
  };
};

/**
 * Get broker statistics
 * @returns {Promise<Object>} Broker KPIs
 */
const getBrokerStats = async () => {
  const sql = `
    SELECT
      COUNT(*) AS TOTAL_BROKERS,
      SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END) AS ACTIVE_BROKERS,
      SUM(CASE WHEN STATUS = 'SUS' THEN 1 ELSE 0 END) AS SUSPENDED_BROKERS
    FROM BROKER
  `;

  const result = await query(sql);
  const stats = result[0];

  return {
    total: stats.TOTAL_BROKERS || 0,
    active: stats.ACTIVE_BROKERS || 0,
    suspended: stats.SUSPENDED_BROKERS || 0
  };
};

/**
 * Get customer statistics
 * @returns {Promise<Object>} Customer KPIs
 */
const getCustomerStats = async () => {
  const sql = `
    SELECT
      COUNT(*) AS TOTAL_CUSTOMERS,
      SUM(CASE WHEN CUST_TYPE = 'IND' THEN 1 ELSE 0 END) AS INDIVIDUAL_CUSTOMERS,
      SUM(CASE WHEN CUST_TYPE = 'BUS' THEN 1 ELSE 0 END) AS BUSINESS_CUSTOMERS,
      SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END) AS ACTIVE_CUSTOMERS
    FROM CUSTOMER
  `;

  const result = await query(sql);
  const stats = result[0];

  return {
    total: stats.TOTAL_CUSTOMERS || 0,
    individual: stats.INDIVIDUAL_CUSTOMERS || 0,
    business: stats.BUSINESS_CUSTOMERS || 0,
    active: stats.ACTIVE_CUSTOMERS || 0
  };
};

/**
 * Get contract statistics
 * @returns {Promise<Object>} Contract KPIs
 */
const getContractStats = async () => {
  const sql = `
    SELECT
      COUNT(*) AS TOTAL_CONTRACTS,
      SUM(CASE WHEN STATUS = 'ACT' THEN 1 ELSE 0 END) AS ACTIVE_CONTRACTS,
      SUM(CASE WHEN STATUS = 'EXP' THEN 1 ELSE 0 END) AS EXPIRED_CONTRACTS,
      SUM(CASE WHEN AUTO_RENEWAL = 'Y' THEN 1 ELSE 0 END) AS AUTO_RENEWAL_CONTRACTS
    FROM CONTRACT
  `;

  const result = await query(sql);
  const stats = result[0];

  return {
    total: stats.TOTAL_CONTRACTS || 0,
    active: stats.ACTIVE_CONTRACTS || 0,
    expired: stats.EXPIRED_CONTRACTS || 0,
    autoRenewal: stats.AUTO_RENEWAL_CONTRACTS || 0
  };
};

/**
 * Get claim statistics
 * @returns {Promise<Object>} Claim KPIs
 */
const getClaimStats = async () => {
  const sql = `
    SELECT
      COUNT(*) AS TOTAL_CLAIMS,
      SUM(CASE WHEN STATUS = 'NEW' THEN 1 ELSE 0 END) AS NEW_CLAIMS,
      SUM(CASE WHEN STATUS = 'REV' THEN 1 ELSE 0 END) AS UNDER_REVIEW,
      SUM(CASE WHEN STATUS = 'APP' THEN 1 ELSE 0 END) AS APPROVED_CLAIMS,
      SUM(CASE WHEN STATUS = 'REJ' THEN 1 ELSE 0 END) AS REJECTED_CLAIMS,
      SUM(CASE WHEN STATUS = 'CLS' THEN 1 ELSE 0 END) AS CLOSED_CLAIMS,
      SUM(CASE WHEN RESOLUTION_TYPE = 'AMI' THEN 1 ELSE 0 END) AS AMICABLE_RESOLUTIONS,
      SUM(CASE WHEN RESOLUTION_TYPE = 'TRI' THEN 1 ELSE 0 END) AS TRIBUNAL_RESOLUTIONS,
      SUM(CLAIMED_AMOUNT) AS TOTAL_CLAIMED,
      SUM(APPROVED_AMOUNT) AS TOTAL_APPROVED
    FROM CLAIM
  `;

  const result = await query(sql);
  const stats = result[0];

  // Calculate amicable resolution rate (target: 79%)
  const totalResolved = (stats.AMICABLE_RESOLUTIONS || 0) + (stats.TRIBUNAL_RESOLUTIONS || 0);
  const amicableRate = totalResolved > 0
    ? Math.round((stats.AMICABLE_RESOLUTIONS / totalResolved) * 100)
    : 0;

  return {
    total: stats.TOTAL_CLAIMS || 0,
    new: stats.NEW_CLAIMS || 0,
    underReview: stats.UNDER_REVIEW || 0,
    approved: stats.APPROVED_CLAIMS || 0,
    rejected: stats.REJECTED_CLAIMS || 0,
    closed: stats.CLOSED_CLAIMS || 0,
    amicableResolutions: stats.AMICABLE_RESOLUTIONS || 0,
    tribunalResolutions: stats.TRIBUNAL_RESOLUTIONS || 0,
    amicableRate: amicableRate,
    amicableRateTarget: BUSINESS_RULES.AMICABLE_RESOLUTION_TARGET * 100,
    totalClaimed: parseFloat(stats.TOTAL_CLAIMED || 0),
    totalApproved: parseFloat(stats.TOTAL_APPROVED || 0)
  };
};

/**
 * Get revenue statistics
 * @returns {Promise<Object>} Revenue KPIs
 */
const getRevenueStats = async () => {
  const sql = `
    SELECT
      SUM(TOTAL_PREMIUM) AS TOTAL_REVENUE,
      AVG(TOTAL_PREMIUM) AS AVG_PREMIUM,
      SUM(CASE WHEN PAY_FREQUENCY = 'M' THEN TOTAL_PREMIUM ELSE 0 END) AS MONTHLY_REVENUE,
      SUM(CASE WHEN PAY_FREQUENCY = 'Q' THEN TOTAL_PREMIUM ELSE 0 END) AS QUARTERLY_REVENUE,
      SUM(CASE WHEN PAY_FREQUENCY = 'A' THEN TOTAL_PREMIUM ELSE 0 END) AS ANNUAL_REVENUE
    FROM CONTRACT
    WHERE STATUS = 'ACT'
  `;

  const result = await query(sql);
  const stats = result[0];

  return {
    totalRevenue: parseFloat(stats.TOTAL_REVENUE || 0),
    avgPremium: parseFloat(stats.AVG_PREMIUM || 0),
    monthlyRevenue: parseFloat(stats.MONTHLY_REVENUE || 0),
    quarterlyRevenue: parseFloat(stats.QUARTERLY_REVENUE || 0),
    annualRevenue: parseFloat(stats.ANNUAL_REVENUE || 0)
  };
};

/**
 * Get claims by status for pie chart
 * @returns {Promise<Array>} Claims grouped by status
 */
const getClaimsByStatus = async () => {
  const sql = `
    SELECT
      STATUS,
      COUNT(*) AS COUNT
    FROM CLAIM
    GROUP BY STATUS
    ORDER BY COUNT DESC
  `;

  const result = await query(sql);

  // Map status codes to labels
  const statusLabels = {
    NEW: 'New',
    REV: 'Under Review',
    APP: 'Approved',
    REJ: 'Rejected',
    CLS: 'Closed'
  };

  return result.map(row => ({
    status: row.STATUS,
    label: statusLabels[row.STATUS] || row.STATUS,
    count: row.COUNT
  }));
};

/**
 * Get recent claims
 * @param {number} limit - Number of claims to return
 * @returns {Promise<Array>} Recent claims
 */
const getRecentClaims = async (limit = 10) => {
  const sql = `
    SELECT
      CL.CLAIM_ID,
      CL.CLAIM_REFERENCE,
      CL.FILE_REFERENCE,
      CL.DECLARATION_DATE,
      CL.CLAIMED_AMOUNT,
      CL.STATUS,
      C.CONT_REFERENCE,
      CASE
        WHEN CUST.CUST_TYPE = 'IND' THEN TRIM(CUST.FIRST_NAME) || ' ' || TRIM(CUST.LAST_NAME)
        ELSE CUST.COMPANY_NAME
      END AS CUSTOMER_NAME,
      G.GUARANTEE_NAME
    FROM CLAIM CL
    LEFT JOIN CONTRACT C ON CL.CONT_ID = C.CONT_ID
    LEFT JOIN CUSTOMER CUST ON C.CUST_ID = CUST.CUST_ID
    LEFT JOIN GUARANTEE G ON CL.GUARANTEE_CODE = G.GUARANTEE_CODE
    ORDER BY CL.DECLARATION_DATE DESC
    FETCH FIRST ? ROWS ONLY
  `;

  return await query(sql, [limit]);
};

/**
 * Get top products by contract count
 * @returns {Promise<Array>} Top products
 */
const getTopProducts = async () => {
  const sql = `
    SELECT
      P.PRODUCT_CODE,
      P.PRODUCT_NAME,
      COUNT(C.CONT_ID) AS CONTRACT_COUNT,
      SUM(C.TOTAL_PREMIUM) AS TOTAL_REVENUE
    FROM PRODUCT P
    LEFT JOIN CONTRACT C ON P.PRODUCT_ID = C.PRODUCT_ID
                         AND C.STATUS = 'ACT'
    WHERE P.STATUS = 'ACT'
    GROUP BY P.PRODUCT_CODE, P.PRODUCT_NAME
    ORDER BY CONTRACT_COUNT DESC
  `;

  const result = await query(sql);

  return result.map(row => ({
    productCode: row.PRODUCT_CODE,
    productName: row.PRODUCT_NAME,
    contractCount: row.CONTRACT_COUNT || 0,
    totalRevenue: parseFloat(row.TOTAL_REVENUE || 0)
  }));
};

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

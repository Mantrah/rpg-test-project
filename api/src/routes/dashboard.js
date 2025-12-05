/**
 * Dashboard Routes
 * Handles dashboard KPIs and statistics endpoints
 */

const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');

/**
 * @route   GET /api/dashboard/stats
 * @desc    Get all dashboard statistics (brokers, customers, contracts, claims, revenue)
 * @access  Public
 */
router.get('/stats', dashboardController.getDashboardStats);

/**
 * @route   GET /api/dashboard/brokers
 * @desc    Get broker statistics
 * @access  Public
 */
router.get('/brokers', dashboardController.getBrokerStats);

/**
 * @route   GET /api/dashboard/customers
 * @desc    Get customer statistics
 * @access  Public
 */
router.get('/customers', dashboardController.getCustomerStats);

/**
 * @route   GET /api/dashboard/contracts
 * @desc    Get contract statistics
 * @access  Public
 */
router.get('/contracts', dashboardController.getContractStats);

/**
 * @route   GET /api/dashboard/claims
 * @desc    Get claim statistics
 * @access  Public
 */
router.get('/claims', dashboardController.getClaimStats);

/**
 * @route   GET /api/dashboard/revenue
 * @desc    Get revenue statistics
 * @access  Public
 */
router.get('/revenue', dashboardController.getRevenueStats);

/**
 * @route   GET /api/dashboard/claims-by-status
 * @desc    Get claims grouped by status (for pie chart)
 * @access  Public
 */
router.get('/claims-by-status', dashboardController.getClaimsByStatus);

/**
 * @route   GET /api/dashboard/recent-claims
 * @desc    Get recent claims
 * @access  Public
 * @query   limit - Number of claims (default: 10, max: 50)
 */
router.get('/recent-claims', dashboardController.getRecentClaims);

/**
 * @route   GET /api/dashboard/top-products
 * @desc    Get top products by contract count
 * @access  Public
 */
router.get('/top-products', dashboardController.getTopProducts);

module.exports = router;

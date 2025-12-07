/**
 * DAS Belgium Backend API
 * Legal Protection Insurance System
 * Target: IBM i V7R5 (PUB400)
 */

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');

const db = require('./config/database');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Routes
const brokerRoutes = require('./routes/brokers');
const customerRoutes = require('./routes/customers');
const productRoutes = require('./routes/products');
const contractRoutes = require('./routes/contracts');
const claimRoutes = require('./routes/claims');
const dashboardRoutes = require('./routes/dashboard');
const bceRoutes = require('./routes/bce');
const debugRoutes = require('./routes/debug');

const app = express();
const PORT = process.env.PORT || 3000;
const API_PREFIX = process.env.API_PREFIX || '/api';

// Middleware
app.use(helmet()); // Security headers
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*'
}));
app.use(morgan('dev')); // Logging
app.use(express.json()); // Parse JSON
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'DAS Backend API',
    version: '1.0.0'
  });
});

// API Routes
app.use(`${API_PREFIX}/brokers`, brokerRoutes);
app.use(`${API_PREFIX}/customers`, customerRoutes);
app.use(`${API_PREFIX}/products`, productRoutes);
app.use(`${API_PREFIX}/contracts`, contractRoutes);
app.use(`${API_PREFIX}/claims`, claimRoutes);
app.use(`${API_PREFIX}/dashboard`, dashboardRoutes);
app.use(`${API_PREFIX}/bce`, bceRoutes);
app.use(`${API_PREFIX}/debug`, debugRoutes);

// Error handlers (must be last)
app.use(notFoundHandler);
app.use(errorHandler);

// Start server
const startServer = async () => {
  try {
    // Initialize database pool
    await db.initPool();

    // Start listening
    app.listen(PORT, () => {
      console.log('');
      console.log('╔═══════════════════════════════════════════════════════╗');
      console.log('║                                                       ║');
      console.log('║           DAS Belgium Backend API                     ║');
      console.log('║       Legal Protection Insurance System               ║');
      console.log('║                                                       ║');
      console.log('╚═══════════════════════════════════════════════════════╝');
      console.log('');
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📍 API endpoints: http://localhost:${PORT}${API_PREFIX}`);
      console.log(`💚 Health check: http://localhost:${PORT}/health`);
      console.log('');
      console.log('Available endpoints:');
      console.log(`  - ${API_PREFIX}/brokers`);
      console.log(`  - ${API_PREFIX}/customers`);
      console.log(`  - ${API_PREFIX}/products`);
      console.log(`  - ${API_PREFIX}/contracts`);
      console.log(`  - ${API_PREFIX}/claims`);
      console.log(`  - ${API_PREFIX}/dashboard`);
      console.log(`  - ${API_PREFIX}/bce`);
      console.log('');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('⚠️  SIGTERM received, closing server gracefully...');
  await db.closePool();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('\n⚠️  SIGINT received, closing server gracefully...');
  await db.closePool();
  process.exit(0);
});

// Start the server
startServer();

module.exports = app;

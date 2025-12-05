/**
 * Database Configuration - IBM i ODBC Connection
 * Connects to PUB400 (or local IBM i) via ODBC
 */

const odbc = require('odbc');

// Connection string for IBM i
const getConnectionString = () => {
  // Option 1: Use full connection string from env
  if (process.env.DB_CONNECTION_STRING) {
    return process.env.DB_CONNECTION_STRING;
  }

  // Option 2: Build from individual parameters
  const driver = process.env.DB_DRIVER || 'IBM i Access ODBC Driver';
  const host = process.env.DB_HOST || 'pub400.com';
  const uid = process.env.DB_USER;
  const pwd = process.env.DB_PASSWORD;
  const dbq = process.env.DB_DATABASE || 'DASBE';

  return `DRIVER={${driver}};SYSTEM=${host};UID=${uid};PWD=${pwd};DBQ=${dbq}`;
};

// Connection pool
let pool = null;

/**
 * Initialize database connection pool
 */
const initPool = async () => {
  try {
    const connectionString = getConnectionString();

    pool = await odbc.pool(connectionString);

    console.log('✅ Database connection pool initialized');
    return pool;
  } catch (error) {
    console.error('❌ Failed to initialize database pool:', error.message);
    throw error;
  }
};

/**
 * Get connection from pool
 */
const getConnection = async () => {
  if (!pool) {
    await initPool();
  }
  return await pool.connect();
};

/**
 * Execute a stored procedure with parameters
 * @param {string} procedureName - Name of the stored procedure (e.g., 'SP_GetBroker')
 * @param {Array} params - Array of parameters
 * @returns {Promise<Array>} - Result set
 */
const callProcedure = async (procedureName, params = []) => {
  const connection = await getConnection();

  try {
    // Build CALL statement with placeholders
    const placeholders = params.map(() => '?').join(', ');
    const sql = `CALL ${procedureName}(${placeholders})`;

    console.log(`📞 Calling: ${sql}`, params);

    const result = await connection.query(sql, params);
    return result;
  } catch (error) {
    console.error(`❌ Error calling ${procedureName}:`, error.message);
    throw error;
  } finally {
    await connection.close();
  }
};

/**
 * Execute a SELECT query
 * @param {string} sql - SQL query
 * @param {Array} params - Query parameters
 * @returns {Promise<Array>} - Result set
 */
const query = async (sql, params = []) => {
  const connection = await getConnection();

  try {
    console.log(`🔍 Query: ${sql}`, params);
    const result = await connection.query(sql, params);
    return result;
  } catch (error) {
    console.error(`❌ Query error:`, error.message);
    throw error;
  } finally {
    await connection.close();
  }
};

/**
 * Close the connection pool (for graceful shutdown)
 */
const closePool = async () => {
  if (pool) {
    await pool.close();
    console.log('✅ Database pool closed');
  }
};

module.exports = {
  initPool,
  getConnection,
  callProcedure,
  query,
  closePool
};

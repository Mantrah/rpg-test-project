/**
 * Database Configuration - IBM i native connection via idb-pconnector
 * Runs directly on IBM i in PASE environment
 */

const { Connection, DBPool } = require('idb-pconnector');

// Connection pool
let pool = null;

/**
 * Initialize database connection pool
 */
const initPool = async () => {
  try {
    // Create a pool with 5 connections
    pool = new DBPool({ url: '*LOCAL' }, { incrementSize: 5 });
    console.log('Database connection pool initialized (idb-pconnector)');
    console.log('Using library: MRS1 (tables must be fully qualified)');
    return pool;
  } catch (error) {
    console.error('Failed to initialize database pool:', error.message);
    throw error;
  }
};

/**
 * Get a connection with COMMIT(*NONE) setting
 */
const getConnection = async () => {
  if (!pool) {
    await initPool();
  }
  const conn = pool.attach();
  // Execute SET TRANSACTION to disable commitment control
  try {
    const stmt = conn.getStatement();
    await stmt.exec('SET TRANSACTION ISOLATION LEVEL NO COMMIT');
    await stmt.close();
  } catch (e) {
    // Ignore errors - best effort
  }
  return conn;
};

/**
 * Execute a SQL query
 * @param {string} sql - SQL query
 * @param {Array} params - Query parameters
 * @returns {Promise<Array>} - Result set
 */
const query = async (sql, params = []) => {
  if (!pool) {
    await initPool();
  }

  const conn = pool.attach();

  try {
    const stmt = conn.getStatement();

    // Prepare statement
    await stmt.prepare(sql);

    // Bind parameters if any
    if (params.length > 0) {
      // Convert params to idb-pconnector format [value, io_type, sql_type]
      // io_type: 1 = SQL_PARAM_INPUT
      const bindParams = params.map(p => [p, 1, 0]);
      await stmt.bindParam(bindParams);
    }

    await stmt.execute();
    const result = await stmt.fetchAll();

    await stmt.close();
    pool.detach(conn);

    return result;
  } catch (error) {
    console.error('Query error:', error.message, 'SQL:', sql);
    pool.detach(conn);
    throw error;
  }
};

/**
 * Execute an INSERT and return the generated ID
 * @param {string} sql - INSERT SQL
 * @param {Array} params - Query parameters
 * @returns {Promise<number>} - Generated ID
 */
const insert = async (sql, params = []) => {
  if (!pool) {
    await initPool();
  }

  const conn = pool.attach();

  try {
    const stmt = conn.getStatement();

    // Add WITH NC (No Commit) to bypass journaling requirement on PUB400
    let sqlWithNC = sql.trim();
    if (!sqlWithNC.toUpperCase().includes('WITH NC') && !sqlWithNC.toUpperCase().includes('WITH NONE')) {
      sqlWithNC = sqlWithNC.replace(/;?\s*$/, '') + ' WITH NC';
    }

    // Prepare statement
    await stmt.prepare(sqlWithNC);

    // Bind parameters if any
    if (params.length > 0) {
      const bindParams = params.map(p => [p, 1, 0]);
      await stmt.bindParam(bindParams);
    }

    await stmt.execute();
    await stmt.close();

    // Get the generated ID
    const idStmt = conn.getStatement();
    await idStmt.prepare('SELECT IDENTITY_VAL_LOCAL() AS ID FROM SYSIBM.SYSDUMMY1');
    await idStmt.execute();
    const idResult = await idStmt.fetchAll();
    await idStmt.close();

    pool.detach(conn);

    return idResult[0]?.ID || null;
  } catch (error) {
    console.error('Insert error:', error.message, 'SQL:', sql);
    pool.detach(conn);
    throw error;
  }
};

/**
 * Execute an UPDATE or DELETE
 * @param {string} sql - SQL statement
 * @param {Array} params - Query parameters
 * @returns {Promise<boolean>} - Success
 */
const execute = async (sql, params = []) => {
  if (!pool) {
    await initPool();
  }

  const conn = pool.attach();

  try {
    const stmt = conn.getStatement();

    // Add WITH NC (No Commit) for UPDATE/DELETE on PUB400 unjournaled tables
    let sqlWithNC = sql.trim();
    const sqlUpper = sqlWithNC.toUpperCase();
    if ((sqlUpper.startsWith('UPDATE') || sqlUpper.startsWith('DELETE')) &&
        !sqlUpper.includes('WITH NC') && !sqlUpper.includes('WITH NONE')) {
      sqlWithNC = sqlWithNC.replace(/;?\s*$/, '') + ' WITH NC';
    }

    await stmt.prepare(sqlWithNC);

    if (params.length > 0) {
      const bindParams = params.map(p => [p, 1, 0]);
      await stmt.bindParam(bindParams);
    }

    await stmt.execute();
    await stmt.close();

    pool.detach(conn);
    return true;
  } catch (error) {
    console.error('Execute error:', error.message, 'SQL:', sql);
    pool.detach(conn);
    throw error;
  }
};

/**
 * Close the connection pool (for graceful shutdown)
 */
const closePool = async () => {
  if (pool) {
    await pool.detachAll();
    console.log('Database pool closed');
  }
};

module.exports = {
  initPool,
  query,
  insert,
  execute,
  closePool
};

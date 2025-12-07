const express = require('express');
const router = express.Router();

// Get job info via SQL query
router.get('/jobinfo', async (req, res) => {
  try {
    const { DBPool } = require('idb-pconnector');
    const pool = new DBPool({ url: '*LOCAL' });
    const conn = pool.attach();

    // Get current job info
    const jobInfoSql = `
      SELECT JOB_NAME, JOB_USER, JOB_NUMBER, JOB_TYPE,
             SUBSYSTEM, SUBSYSTEM_LIBRARY_NAME,
             CCSID, SQL_STATEMENT_TEXT
      FROM QSYS2.GET_JOB_INFO('*')
    `;

    let jobInfo = {};
    try {
      const stmt1 = conn.getStatement();
      await stmt1.exec(jobInfoSql);
      const result1 = await stmt1.fetchAll();
      jobInfo = result1[0] || {};
    } catch (e) {
      jobInfo = { error: e.message };
    }

    // Get recent joblog entries
    const joblogSql = `
      SELECT MESSAGE_ID, MESSAGE_TYPE, MESSAGE_SUBTYPE,
             MESSAGE_TEXT, MESSAGE_SECOND_LEVEL_TEXT,
             MESSAGE_TIMESTAMP
      FROM TABLE(QSYS2.JOBLOG_INFO('*'))
      ORDER BY ORDINAL_POSITION DESC
      FETCH FIRST 20 ROWS ONLY
    `;

    let joblog = [];
    try {
      const stmt2 = conn.getStatement();
      await stmt2.exec(joblogSql);
      joblog = await stmt2.fetchAll();
    } catch (e) {
      joblog = [{ error: e.message }];
    }

    pool.detach(conn);

    res.json({
      success: true,
      jobInfo: jobInfo,
      joblog: joblog
    });

  } catch (error) {
    res.json({
      success: false,
      error: error.message
    });
  }
});

// Test INSERT with explicit COMMIT(*NONE)
router.post('/testinsert', async (req, res) => {
  try {
    const { DBPool } = require('idb-pconnector');
    const pool = new DBPool({ url: '*LOCAL' });
    const conn = pool.attach();
    const stmt = conn.getStatement();

    // Try to set isolation level FIRST
    try {
      await stmt.exec("SET TRANSACTION ISOLATION LEVEL NO COMMIT");
    } catch (e) {
      // ignore
    }

    const sql = `
      INSERT INTO MRS1.BROKER (
        BROKER_CODE, COMPANY_NAME, VAT_NUMBER, FSMA_NUMBER,
        STREET, HOUSE_NBR, POSTAL_CODE, CITY, COUNTRY_CODE,
        PHONE, EMAIL, CONTACT_NAME, STATUS
      ) VALUES (
        'DEBUG01', 'Debug Test', 'BE9999999999', '99999',
        'Debug St', '99', '9999', 'Debug', 'BEL',
        '0000000000', 'debug@test.be', 'Debug', 'ACT'
      )
    `;

    await stmt.exec(sql);

    // Get ID
    const idStmt = conn.getStatement();
    await idStmt.exec("SELECT IDENTITY_VAL_LOCAL() AS ID FROM SYSIBM.SYSDUMMY1");
    const idResult = await idStmt.fetchAll();

    pool.detach(conn);

    res.json({
      success: true,
      brokerId: idResult[0]?.ID
    });

  } catch (error) {
    res.json({
      success: false,
      error: error.message,
      sqlcode: error.sqlcode,
      sqlstate: error.sqlstate
    });
  }
});

// Get connection attributes
router.get('/connattr', async (req, res) => {
  try {
    const { DBPool, dbconn } = require('idb-pconnector');
    const pool = new DBPool({ url: '*LOCAL' });
    const conn = pool.attach();

    // Get the dbconn object to check attributes
    const dbconnObj = conn.getConnection();

    let attrs = {};
    // Try different SQL_ATTR values
    const attrNames = [
      { name: 'SQL_ATTR_COMMIT', value: 0 },
      { name: 'SQL_ATTR_AUTOCOMMIT', value: 102 }
    ];

    for (const attr of attrNames) {
      try {
        const val = dbconnObj.getConnAttr(attr.value);
        attrs[attr.name] = val;
      } catch (e) {
        attrs[attr.name] = 'Error: ' + e.message;
      }
    }

    pool.detach(conn);

    res.json({
      success: true,
      attributes: attrs
    });

  } catch (error) {
    res.json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

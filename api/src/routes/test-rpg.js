/**
 * Test RPG Routes - Test connection to RPG service program
 * Calls ERRUTIL_getJobInfo to verify RPG integration works
 */

const express = require('express');
const router = express.Router();
const { execSync } = require('child_process');

/**
 * GET /api/test-rpg/job-info
 * Test RPG call - returns current job info from ERRUTIL_getJobInfo
 */
router.get('/job-info', async (req, res) => {
  try {
    // Use QSYS2.GET_JOB_INFO directly via SQL to test
    const { query } = require('../config/database');

    const result = await query(`
      SELECT JOB_NAME, JOB_USER, JOB_NUMBER
      FROM TABLE(QSYS2.GET_JOB_INFO('*'))
    `);

    if (result && result.length > 0) {
      const job = result[0];
      const jobInfo = `${job.JOB_NUMBER}/${job.JOB_USER}/${job.JOB_NAME}`;

      res.json({
        success: true,
        jobInfo: jobInfo,
        details: {
          jobNumber: job.JOB_NUMBER,
          jobUser: job.JOB_USER,
          jobName: job.JOB_NAME
        }
      });
    } else {
      res.json({
        success: false,
        error: 'Could not retrieve job info'
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * GET /api/test-rpg/xmlservice-test
 * Test XMLSERVICE call to the RPG service program
 */
router.get('/xmlservice-test', async (req, res) => {
  try {
    // Call XMLSERVICE via stored procedure
    const { query } = require('../config/database');

    // Simple test - call XMLSERVICE with a data area read
    const xml = `<?xml version="1.0"?>
<script>
  <pgm name='DASSRV' lib='MRS1' func='ERRUTIL_GETJOBINFO'>
    <return>
      <data type='50a' var='result'></data>
    </return>
  </pgm>
</script>`;

    const result = await query(
      `SELECT XMLSERVICE FROM QXMLSERV.XMLSERVICE WHERE input = ?`,
      [xml]
    );

    res.json({
      success: true,
      result: result
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      note: 'XMLSERVICE may not be configured on PUB400'
    });
  }
});

module.exports = router;

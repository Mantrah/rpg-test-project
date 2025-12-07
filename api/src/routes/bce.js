/**
 * BCE Routes - Banque-Carrefour des Entreprises
 * Company lookup by VAT number
 */

const express = require('express');
const router = express.Router();
const bceService = require('../services/bceService');
const { success, error: formatError } = require('../utils/responseFormatter');

/**
 * GET /api/bce/search/:vatNumber
 * Search company by VAT number
 *
 * @param vatNumber - Belgian VAT (formats: BE0123456789, 0123456789, BE 0123.456.789)
 * @returns Company data from BCE
 */
router.get('/search/:vatNumber', async (req, res) => {
  try {
    const { vatNumber } = req.params;

    // Validate format
    if (!bceService.isValidVatFormat(vatNumber)) {
      return res.status(400).json(
        formatError('VAL002', 'Invalid Belgian VAT number format. Expected: BE0123456789')
      );
    }

    // Search in BCE
    const companyData = await bceService.searchByVat(vatNumber);

    res.json(success(companyData));
  } catch (error) {
    console.error('BCE search error:', error.message);

    if (error.message.includes('not found')) {
      return res.status(404).json(
        formatError('BCE001', 'Enterprise not found in BCE registry')
      );
    }

    res.status(500).json(
      formatError('BCE999', `BCE lookup failed: ${error.message}`)
    );
  }
});

/**
 * GET /api/bce/validate/:vatNumber
 * Validate VAT number format only (no BCE lookup)
 *
 * @param vatNumber - VAT number to validate
 * @returns Validation result with formatted number
 */
router.get('/validate/:vatNumber', (req, res) => {
  const { vatNumber } = req.params;

  const isValid = bceService.isValidVatFormat(vatNumber);
  const formatted = bceService.formatVatNumber(vatNumber);

  res.json(success({
    isValid,
    original: vatNumber,
    formatted: formatted || null
  }));
});

/**
 * GET /api/bce/mock/:vatNumber
 * Get mock data for testing (always returns data)
 *
 * @param vatNumber - VAT number
 * @returns Mock company data
 */
router.get('/mock/:vatNumber', (req, res) => {
  const { vatNumber } = req.params;

  // Format and extract enterprise number
  const formatted = bceService.formatVatNumber(vatNumber);
  if (!formatted) {
    return res.status(400).json(
      formatError('VAL002', 'Invalid VAT number format')
    );
  }

  const enterpriseNumber = formatted.substring(2);
  const mockData = bceService.getMockData(enterpriseNumber);

  res.json(success(mockData));
});

module.exports = router;

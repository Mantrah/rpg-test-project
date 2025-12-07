/**
 * BCE Service - Banque-Carrefour des Entreprises (KBO)
 * Integration with CBEAPI.be (free API - 2500 requests/day)
 *
 * API Docs: https://cbeapi.be/en/docs
 */

const https = require('https');

// CBEAPI endpoint
const CBEAPI_BASE = 'https://cbeapi.be/api/v1';

/**
 * Format VAT number to standard Belgian format
 * Input: 0123456789, BE0123456789, BE 0123.456.789
 * Output: BE0123456789
 */
const formatVatNumber = (input) => {
  // Remove all non-alphanumeric characters
  let cleaned = input.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();

  // Add BE prefix if missing
  if (!cleaned.startsWith('BE')) {
    cleaned = 'BE' + cleaned;
  }

  // Ensure 12 characters total (BE + 10 digits)
  if (cleaned.length !== 12) {
    return null;
  }

  return cleaned;
};

/**
 * Extract enterprise number from VAT (remove BE prefix)
 * BE0123456789 -> 0123456789
 */
const vatToEnterpriseNumber = (vatNumber) => {
  const formatted = formatVatNumber(vatNumber);
  if (!formatted) return null;
  return formatted.substring(2); // Remove 'BE'
};

/**
 * Search company by VAT/Enterprise number
 * @param {string} vatNumber - Belgian VAT number (various formats accepted)
 * @returns {Promise<Object>} Company data
 */
const searchByVat = async (vatNumber) => {
  const enterpriseNumber = vatToEnterpriseNumber(vatNumber);

  if (!enterpriseNumber) {
    throw new Error('Invalid VAT number format');
  }

  // Check if API token is configured
  const apiToken = process.env.CBEAPI_TOKEN;

  if (!apiToken) {
    console.warn('CBEAPI_TOKEN not configured, using mock data');
    return getMockData(enterpriseNumber);
  }

  try {
    const result = await fetchFromCBEAPI(enterpriseNumber, apiToken);
    return result;
  } catch (error) {
    console.error('CBEAPI error:', error.message);

    // Fallback to mock data
    if (process.env.NODE_ENV === 'development') {
      console.log('Falling back to mock data');
      return getMockData(enterpriseNumber);
    }

    throw error;
  }
};

/**
 * Fetch data from CBEAPI
 */
const fetchFromCBEAPI = (enterpriseNumber, apiToken) => {
  return new Promise((resolve, reject) => {
    const url = new URL(`${CBEAPI_BASE}/company/${enterpriseNumber}`);

    const options = {
      hostname: url.hostname,
      path: url.pathname,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${apiToken}`,
        'Accept': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          if (res.statusCode === 404) {
            reject(new Error('Enterprise not found in BCE'));
            return;
          }

          if (res.statusCode === 401) {
            reject(new Error('Invalid CBEAPI token'));
            return;
          }

          if (res.statusCode !== 200) {
            reject(new Error(`CBEAPI error: ${res.statusCode}`));
            return;
          }

          const json = JSON.parse(data);
          const parsed = parseCBEAPIResponse(json, enterpriseNumber);
          resolve(parsed);
        } catch (e) {
          reject(new Error('Failed to parse CBEAPI response: ' + e.message));
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.end();
  });
};

/**
 * Parse CBEAPI JSON response to our format
 */
const parseCBEAPIResponse = (json, enterpriseNumber) => {
  // CBEAPI returns data directly or in a data wrapper
  const company = json.data || json;

  return {
    vatNumber: 'BE' + (company.cbe_number || enterpriseNumber),
    enterpriseNumber: company.cbe_number || enterpriseNumber,
    companyName: company.denomination || company.name || '',
    legalForm: company.juridical_form || null,
    status: company.status || 'active',
    startDate: company.start_date || null,
    address: {
      street: company.address?.street || '',
      houseNbr: company.address?.street_number || company.address?.house_number || '',
      boxNbr: company.address?.box || '',
      postalCode: company.address?.post_code || company.address?.postal_code || '',
      city: company.address?.city || company.address?.municipality || '',
      countryCode: company.address?.country_code || 'BE'
    },
    naceCode: extractNaceCode(company)
  };
};

/**
 * Extract main NACE code from company data
 */
const extractNaceCode = (company) => {
  if (company.activities && company.activities.length > 0) {
    return company.activities[0].nace_code || company.activities[0].code || null;
  }
  if (company.nace_codes && company.nace_codes.length > 0) {
    return company.nace_codes[0];
  }
  return null;
};

/**
 * Mock data for testing/demo when CBEAPI unavailable
 */
const getMockData = (enterpriseNumber) => {
  // Real Belgian companies for demo
  const mockCompanies = {
    '0403170701': {
      vatNumber: 'BE0403170701',
      enterpriseNumber: '0403170701',
      companyName: 'ENGIE ELECTRABEL SA',
      legalForm: 'SA',
      status: 'active',
      address: {
        street: 'Boulevard Simon Bolivar',
        houseNbr: '36',
        boxNbr: '',
        postalCode: '1000',
        city: 'Bruxelles',
        countryCode: 'BE'
      },
      naceCode: '35110'
    },
    '0202239951': {
      vatNumber: 'BE0202239951',
      enterpriseNumber: '0202239951',
      companyName: 'DELHAIZE LE LION SA',
      legalForm: 'SA',
      status: 'active',
      address: {
        street: 'Rue Osseghemstraat',
        houseNbr: '53',
        boxNbr: '',
        postalCode: '1080',
        city: 'Molenbeek-Saint-Jean',
        countryCode: 'BE'
      },
      naceCode: '47110'
    },
    '0404491285': {
      vatNumber: 'BE0404491285',
      enterpriseNumber: '0404491285',
      companyName: 'ING BELGIQUE SA',
      legalForm: 'SA',
      status: 'active',
      address: {
        street: 'Avenue Marnix',
        houseNbr: '24',
        boxNbr: '',
        postalCode: '1000',
        city: 'Bruxelles',
        countryCode: 'BE'
      },
      naceCode: '64190'
    },
    '0417497106': {
      vatNumber: 'BE0417497106',
      enterpriseNumber: '0417497106',
      companyName: 'MICROSOFT NV',
      legalForm: 'NV',
      status: 'active',
      address: {
        street: 'Leonardo Da Vincilaan',
        houseNbr: '3',
        boxNbr: '',
        postalCode: '1930',
        city: 'Zaventem',
        countryCode: 'BE'
      },
      naceCode: '62010'
    }
  };

  // Return mock if exists, otherwise generate generic
  if (mockCompanies[enterpriseNumber]) {
    return mockCompanies[enterpriseNumber];
  }

  // Generic mock for any number
  return {
    vatNumber: 'BE' + enterpriseNumber,
    enterpriseNumber: enterpriseNumber,
    companyName: `Entreprise Demo ${enterpriseNumber.substring(0, 4)}`,
    legalForm: 'SPRL',
    status: 'active',
    address: {
      street: 'Rue de la Démonstration',
      houseNbr: '1',
      boxNbr: '',
      postalCode: '1000',
      city: 'Bruxelles',
      countryCode: 'BE'
    },
    naceCode: '62010'
  };
};

/**
 * Validate Belgian VAT number format
 */
const isValidVatFormat = (vatNumber) => {
  const formatted = formatVatNumber(vatNumber);
  if (!formatted) return false;

  // Check it's BE + 10 digits
  const digits = formatted.substring(2);
  return /^\d{10}$/.test(digits);
};

module.exports = {
  searchByVat,
  formatVatNumber,
  isValidVatFormat,
  getMockData
};

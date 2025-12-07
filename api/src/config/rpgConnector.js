/**
 * RPG Connector - iToolkit Integration
 * DAS Belgium - Legal Protection Insurance
 *
 * Calls RPG service program procedures via XMLSERVICE/iToolkit.
 * All business logic runs in RPG - Node.js is just the API layer.
 */

const { Connection, ProgramCall } = require('itoolkit');
const { Connection: idbConnection } = require('idb-pconnector');

// Service program configuration
const SRVPGM = 'DASSRV';
const LIBRARY = 'MRS1';

/**
 * Create iToolkit connection
 * @returns {Connection} iToolkit connection
 */
const createConnection = async () => {
  const idbConn = new idbConnection({ url: '*LOCAL' });
  return new Connection({
    transport: 'idb',
    transportOptions: { conn: idbConn }
  });
};

/**
 * Execute an RPG procedure call
 * @param {string} procName - Procedure name
 * @param {Array} params - Parameters array
 * @returns {Promise<Object>} - Result object with output values
 */
const callRpg = async (procName, params) => {
  return new Promise(async (resolve, reject) => {
    const conn = await createConnection();

    const pgm = new ProgramCall(SRVPGM, {
      lib: LIBRARY,
      func: procName
    });

    // Add parameters
    params.forEach(param => {
      pgm.addParam(param);
    });

    conn.add(pgm);

    conn.run((error, xmlOutput) => {
      if (error) {
        console.error('[RPG] Connection error:', error);
        reject(error);
        return;
      }

      try {
        // Log raw XML for debugging
        console.log('[RPG] Raw XML output:', JSON.stringify(xmlOutput));

        // Parse XML output
        const result = parseXmlOutput(xmlOutput, params);
        console.log('[RPG] Parsed result:', JSON.stringify(result));
        resolve(result);
      } catch (parseError) {
        console.error('[RPG] Parse error:', parseError);
        reject(parseError);
      }
    });
  });
};

/**
 * Parse XML output from XMLSERVICE
 * @param {string} xml - XML output
 * @param {Array} params - Original params (to get names)
 * @returns {Object} - Parsed result
 */
const parseXmlOutput = (xml, params) => {
  const result = {};

  // Extract data values from XML
  // XMLSERVICE returns: <data type='...' name='paramName'>value</data>
  params.forEach(param => {
    if (param.name) {
      const regex = new RegExp(`<data[^>]*name=['"]${param.name}['"][^>]*>([^<]*)</data>`, 'i');
      const match = xml.match(regex);
      if (match) {
        result[param.name] = parseValue(match[1], param.type);
      }
    }
  });

  return result;
};

/**
 * Parse value based on type
 */
const parseValue = (value, type) => {
  if (!value || value.trim() === '') return null;

  value = value.trim();

  if (type.includes('p') || type.includes('s')) {
    // Packed or zoned decimal
    return parseFloat(value);
  }
  if (type === 'date') {
    return value;
  }
  // Character - trim
  return value.trim();
};

//==============================================================
// BROKER PROCEDURES
//==============================================================

/**
 * Get broker by ID
 * @param {number} brokerId - Broker ID
 * @returns {Promise<Object>} - Broker data
 */
const getBrokerById = async (brokerId) => {
  const params = [
    { name: 'pBrokerId', type: '10p0', value: brokerId, io: 'in' },
    { name: 'oBrokerCode', type: '10a', io: 'out' },
    { name: 'oCompanyName', type: '100a', io: 'out' },
    { name: 'oVatNumber', type: '12a', io: 'out' },
    { name: 'oFsmaNumber', type: '10a', io: 'out' },
    { name: 'oStreet', type: '30a', io: 'out' },
    { name: 'oHouseNbr', type: '5a', io: 'out' },
    { name: 'oPostalCode', type: '7a', io: 'out' },
    { name: 'oCity', type: '24a', io: 'out' },
    { name: 'oPhone', type: '20a', io: 'out' },
    { name: 'oEmail', type: '100a', io: 'out' },
    { name: 'oContactName', type: '100a', io: 'out' },
    { name: 'oStatus', type: '3a', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' },
    { name: 'oErrorCode', type: '10a', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_GETBROKERBYID', params);

    if (result.oSuccess !== 'Y') {
      const error = new Error('Broker not found');
      error.code = result.oErrorCode;
      throw error;
    }

    return {
      brokerId: brokerId,
      brokerCode: result.oBrokerCode,
      companyName: result.oCompanyName,
      vatNumber: result.oVatNumber,
      fsmaNumber: result.oFsmaNumber,
      street: result.oStreet,
      houseNbr: result.oHouseNbr,
      postalCode: result.oPostalCode,
      city: result.oCity,
      phone: result.oPhone,
      email: result.oEmail,
      contactName: result.oContactName,
      status: result.oStatus
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning null for getBrokerById');
      return null;
    }
    throw error;
  }
};

/**
 * List all brokers (with optional status filter)
 * @param {string} status - Optional status filter (ACT, INA, SUS)
 * @returns {Promise<Array>} - Array of brokers
 */
const listBrokers = async (status = '') => {
  const params = [
    { name: 'pStatus', type: '3a', value: status || '', io: 'in' },
    { name: 'oJsonData', type: '32000a', value: '', io: 'out', varying: 2 },
    { name: 'oCount', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_LISTBROKERS', params);

    if (result.oSuccess !== 'Y') {
      console.warn('[RPG] listBrokers returned unsuccessful, returning empty array');
      return [];
    }

    // Parse JSON string returned by RPG
    try {
      return JSON.parse(result.oJsonData || '[]');
    } catch (e) {
      console.error('[RPG] JSON parse error:', e, 'Data:', result.oJsonData);
      return [];
    }
  } catch (error) {
    // SQLCODE 8013 = licensing/connection issue on PUB400 - ignore and return empty
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning empty array');
      return [];
    }
    throw error;
  }
};

/**
 * Delete a broker (soft delete - sets status to INA)
 * @param {number} brokerId - Broker ID
 * @returns {Promise<boolean>} - Success
 */
const deleteBroker = async (brokerId) => {
  const params = [
    { name: 'pBrokerId', type: '10p0', value: brokerId, io: 'in' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' },
    { name: 'oErrorCode', type: '10a', value: '', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_DELETEBROKER', params);

    if (result.oSuccess !== 'Y') {
      const error = new Error('Failed to delete broker');
      error.code = result.oErrorCode;
      throw error;
    }

    return true;
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning false for deleteBroker');
      return false;
    }
    throw error;
  }
};

/**
 * Create a new broker
 * @param {Object} brokerData - Broker data
 * @returns {Promise<Object>} - Created broker with ID
 */
const createBroker = async (brokerData) => {
  const params = [
    { name: 'pBrokerCode', type: '10a', value: brokerData.brokerCode || '', io: 'in' },
    { name: 'pCompanyName', type: '100a', value: brokerData.companyName || '', io: 'in' },
    { name: 'pVatNumber', type: '12a', value: brokerData.vatNumber || '', io: 'in' },
    { name: 'pFsmaNumber', type: '10a', value: brokerData.fsmaNumber || '', io: 'in' },
    { name: 'pStreet', type: '30a', value: brokerData.street || '', io: 'in' },
    { name: 'pHouseNbr', type: '5a', value: brokerData.houseNbr || '', io: 'in' },
    { name: 'pPostalCode', type: '7a', value: brokerData.postalCode || '', io: 'in' },
    { name: 'pCity', type: '24a', value: brokerData.city || '', io: 'in' },
    { name: 'pPhone', type: '20a', value: brokerData.phone || '', io: 'in' },
    { name: 'pEmail', type: '100a', value: brokerData.email || '', io: 'in' },
    { name: 'pContactName', type: '100a', value: brokerData.contactName || '', io: 'in' },
    { name: 'oBrokerId', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' },
    { name: 'oErrorCode', type: '10a', value: '', io: 'out' }
  ];

  const result = await callRpg('WRAP_CREATEBROKER', params);

  if (result.oSuccess !== 'Y') {
    const error = new Error('Failed to create broker');
    error.code = result.oErrorCode;
    throw error;
  }

  return {
    brokerId: result.oBrokerId,
    ...brokerData
  };
};

//==============================================================
// CUSTOMER PROCEDURES
//==============================================================

/**
 * Get customer by ID
 * @param {number} custId - Customer ID
 * @returns {Promise<Object>} - Customer data
 */
const getCustomerById = async (custId) => {
  const params = [
    { name: 'pCustId', type: '10p0', value: custId, io: 'in' },
    { name: 'oCustType', type: '3a', io: 'out' },
    { name: 'oFirstName', type: '50a', io: 'out' },
    { name: 'oLastName', type: '50a', io: 'out' },
    { name: 'oNationalId', type: '15a', io: 'out' },
    { name: 'oBirthDate', type: 'date', io: 'out' },
    { name: 'oCompanyName', type: '100a', io: 'out' },
    { name: 'oVatNumber', type: '12a', io: 'out' },
    { name: 'oStreet', type: '30a', io: 'out' },
    { name: 'oHouseNbr', type: '5a', io: 'out' },
    { name: 'oPostalCode', type: '7a', io: 'out' },
    { name: 'oCity', type: '24a', io: 'out' },
    { name: 'oPhone', type: '20a', io: 'out' },
    { name: 'oEmail', type: '100a', io: 'out' },
    { name: 'oLanguage', type: '2a', io: 'out' },
    { name: 'oStatus', type: '3a', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' },
    { name: 'oErrorCode', type: '10a', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_GETCUSTOMERBYID', params);

    if (result.oSuccess !== 'Y') {
      const error = new Error('Customer not found');
      error.code = result.oErrorCode;
      throw error;
    }

    return {
      custId: custId,
      custType: result.oCustType,
      firstName: result.oFirstName,
      lastName: result.oLastName,
      nationalId: result.oNationalId,
      birthDate: result.oBirthDate,
      companyName: result.oCompanyName,
      vatNumber: result.oVatNumber,
      street: result.oStreet,
      houseNbr: result.oHouseNbr,
      postalCode: result.oPostalCode,
      city: result.oCity,
      phone: result.oPhone,
      email: result.oEmail,
      language: result.oLanguage,
      status: result.oStatus
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning null for getCustomerById');
      return null;
    }
    throw error;
  }
};

/**
 * Create a new customer
 * @param {Object} customerData - Customer data
 * @returns {Promise<Object>} - Created customer with ID
 */
const createCustomer = async (customerData) => {
  const params = [
    { name: 'pCustType', type: '3a', value: customerData.custType || 'IND', io: 'in' },
    { name: 'pFirstName', type: '50a', value: customerData.firstName || '', io: 'in' },
    { name: 'pLastName', type: '50a', value: customerData.lastName || '', io: 'in' },
    { name: 'pNationalId', type: '15a', value: customerData.nationalId || '', io: 'in' },
    { name: 'pBirthDate', type: '10a', value: customerData.birthDate || '1900-01-01', io: 'in' },
    { name: 'pCompanyName', type: '100a', value: customerData.companyName || '', io: 'in' },
    { name: 'pVatNumber', type: '12a', value: customerData.vatNumber || '', io: 'in' },
    { name: 'pStreet', type: '30a', value: customerData.street || '', io: 'in' },
    { name: 'pHouseNbr', type: '5a', value: customerData.houseNbr || '', io: 'in' },
    { name: 'pPostalCode', type: '7a', value: customerData.postalCode || '', io: 'in' },
    { name: 'pCity', type: '24a', value: customerData.city || '', io: 'in' },
    { name: 'pCountryCode', type: '3a', value: customerData.countryCode || 'BEL', io: 'in' },
    { name: 'pPhone', type: '20a', value: customerData.phone || '', io: 'in' },
    { name: 'pEmail', type: '100a', value: customerData.email || '', io: 'in' },
    { name: 'pLanguage', type: '2a', value: customerData.language || 'FR', io: 'in' },
    { name: 'oCustId', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' },
    { name: 'oErrorCode', type: '10a', value: '', io: 'out' }
  ];

  const result = await callRpg('WRAP_CREATECUSTOMER', params);

  if (result.oSuccess !== 'Y') {
    const error = new Error('Failed to create customer');
    error.code = result.oErrorCode;
    throw error;
  }

  return {
    custId: result.oCustId,
    ...customerData
  };
};

/**
 * List all customers
 * @param {string} status - Filter by status (optional)
 * @returns {Promise<Array>} - Array of customers
 */
const listCustomers = async (status = '') => {
  const params = [
    { name: 'pStatus', type: '3a', value: status || '', io: 'in' },
    { name: 'oJsonData', type: '32000a', value: '', io: 'out', varying: 2 },
    { name: 'oCount', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' }
  ];

  const result = await callRpg('WRAP_LISTCUSTOMERS', params);

  if (result.oSuccess !== 'Y') {
    return [];
  }

  try {
    // Strip leading control characters (VARCHAR length bytes from RPG)
    let jsonData = result.oJsonData || '[]';
    const firstBracket = jsonData.indexOf('[');
    if (firstBracket > 0) {
      jsonData = jsonData.substring(firstBracket);
    }
    return JSON.parse(jsonData);
  } catch (e) {
    console.error('[RPG] Failed to parse customer JSON:', e);
    return [];
  }
};

/**
 * Get customer by email
 * @param {string} email - Email address
 * @returns {Promise<Object>} - Customer data
 */
const getCustomerByEmail = async (email) => {
  const params = [
    { name: 'pEmail', type: '100a', value: email, io: 'in' },
    { name: 'oCustId', type: '10p0', value: 0, io: 'out' },
    { name: 'oCustType', type: '3a', value: '', io: 'out' },
    { name: 'oFirstName', type: '50a', value: '', io: 'out' },
    { name: 'oLastName', type: '50a', value: '', io: 'out' },
    { name: 'oNationalId', type: '15a', value: '', io: 'out' },
    { name: 'oCompanyName', type: '100a', value: '', io: 'out' },
    { name: 'oStreet', type: '30a', value: '', io: 'out' },
    { name: 'oPostalCode', type: '7a', value: '', io: 'out' },
    { name: 'oCity', type: '24a', value: '', io: 'out' },
    { name: 'oPhone', type: '20a', value: '', io: 'out' },
    { name: 'oEmail', type: '100a', value: '', io: 'out' },
    { name: 'oLanguage', type: '2a', value: '', io: 'out' },
    { name: 'oStatus', type: '3a', value: '', io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' },
    { name: 'oErrorCode', type: '10a', value: '', io: 'out' }
  ];

  const result = await callRpg('WRAP_GETCUSTOMERBYEMAIL', params);

  if (result.oSuccess !== 'Y') {
    const error = new Error('Customer not found');
    error.code = result.oErrorCode;
    error.statusCode = 404;
    throw error;
  }

  return {
    custId: result.oCustId,
    custType: result.oCustType,
    firstName: result.oFirstName,
    lastName: result.oLastName,
    nationalId: result.oNationalId,
    companyName: result.oCompanyName,
    street: result.oStreet,
    postalCode: result.oPostalCode,
    city: result.oCity,
    phone: result.oPhone,
    email: result.oEmail,
    language: result.oLanguage,
    status: result.oStatus
  };
};

/**
 * Get contracts for a customer
 * @param {number} custId - Customer ID
 * @returns {Promise<Array>} - Array of contracts
 */
const getCustomerContracts = async (custId) => {
  const params = [
    { name: 'pCustId', type: '10p0', value: custId, io: 'in' },
    { name: 'oJsonData', type: '32000a', value: '', io: 'out', varying: 2 },
    { name: 'oCount', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' }
  ];

  const result = await callRpg('WRAP_GETCUSTOMERCONTRACTS', params);

  if (result.oSuccess !== 'Y') {
    return [];
  }

  try {
    return JSON.parse(result.oJsonData || '[]');
  } catch (e) {
    console.error('[RPG] Failed to parse contracts JSON:', e);
    return [];
  }
};

//==============================================================
// PRODUCT PROCEDURES
//==============================================================

/**
 * List all products (with optional status filter)
 * @param {string} status - Optional status filter (ACT, INA)
 * @returns {Promise<Array>} - Array of products
 */
const listProducts = async (status = '') => {
  const params = [
    { name: 'pStatus', type: '3a', value: status || '', io: 'in' },
    { name: 'oJsonData', type: '32000a', value: '', io: 'out', varying: 2 },
    { name: 'oCount', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_LISTPRODUCTS', params);

    if (result.oSuccess !== 'Y') {
      return [];
    }

    try {
      // Strip leading control characters (VARCHAR length bytes from RPG)
      let jsonData = result.oJsonData || '[]';
      const firstBracket = jsonData.indexOf('[');
      if (firstBracket > 0) {
        jsonData = jsonData.substring(firstBracket);
      }
      return JSON.parse(jsonData);
    } catch (e) {
      console.error('[RPG] Failed to parse products JSON:', e);
      return [];
    }
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning empty array for listProducts');
      return [];
    }
    throw error;
  }
};

/**
 * Get product by code
 * @param {string} productCode - Product code
 * @returns {Promise<Object>} - Product data
 */
const getProductByCode = async (productCode) => {
  const params = [
    { name: 'pProductCode', type: '10a', value: productCode, io: 'in' },
    { name: 'oProductId', type: '10p0', value: 0, io: 'out' },
    { name: 'oProductName', type: '50a', value: '', io: 'out' },
    { name: 'oProductType', type: '3a', value: '', io: 'out' },
    { name: 'oBasePremium', type: '9p2', value: 0, io: 'out' },
    { name: 'oCoverageLimit', type: '11p2', value: 0, io: 'out' },
    { name: 'oMinThreshold', type: '9p2', value: 0, io: 'out' },
    { name: 'oWaitingMonths', type: '2p0', value: 0, io: 'out' },
    { name: 'oStatus', type: '3a', value: '', io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' },
    { name: 'oErrorCode', type: '10a', value: '', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_GETPRODUCTBYCODE', params);

    if (result.oSuccess !== 'Y') {
      const error = new Error('Product not found');
      error.code = result.oErrorCode;
      error.statusCode = 404;
      throw error;
    }

    return {
      productId: result.oProductId,
      productCode: productCode,
      productName: result.oProductName,
      productType: result.oProductType,
      basePremium: result.oBasePremium,
      coverageLimit: result.oCoverageLimit,
      minThreshold: result.oMinThreshold,
      waitingMonths: result.oWaitingMonths,
      status: result.oStatus
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning null for getProductByCode');
      return null;
    }
    throw error;
  }
};

/**
 * Get guarantees for a product
 * @param {number} productId - Product ID
 * @returns {Promise<Array>} - Array of guarantees
 */
const getProductGuarantees = async (productId) => {
  const params = [
    { name: 'pProductId', type: '10p0', value: productId, io: 'in' },
    { name: 'oJsonData', type: '32000a', value: '', io: 'out', varying: 2 },
    { name: 'oCount', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_GETPRODUCTGUARANTEES', params);

    if (result.oSuccess !== 'Y') {
      return [];
    }

    try {
      // Strip leading control characters (VARCHAR length bytes from RPG)
      let jsonData = result.oJsonData || '[]';
      const firstBracket = jsonData.indexOf('[');
      if (firstBracket > 0) {
        jsonData = jsonData.substring(firstBracket);
      }
      return JSON.parse(jsonData);
    } catch (e) {
      console.error('[RPG] Failed to parse guarantees JSON:', e);
      return [];
    }
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning empty array for getProductGuarantees');
      return [];
    }
    throw error;
  }
};

/**
 * Get product by ID
 * @param {number} productId - Product ID
 * @returns {Promise<Object>} - Product data
 */
const getProductById = async (productId) => {
  const params = [
    { name: 'pProductId', type: '10p0', value: productId, io: 'in' },
    { name: 'oProductCode', type: '10a', io: 'out' },
    { name: 'oProductName', type: '50a', io: 'out' },
    { name: 'oProductType', type: '3a', io: 'out' },
    { name: 'oBasePremium', type: '9p2', io: 'out' },
    { name: 'oCoverageLimit', type: '11p2', io: 'out' },
    { name: 'oMinThreshold', type: '9p2', io: 'out' },
    { name: 'oWaitingMonths', type: '2p0', io: 'out' },
    { name: 'oStatus', type: '3a', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' },
    { name: 'oErrorCode', type: '10a', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_GETPRODUCTBYID', params);

    if (result.oSuccess !== 'Y') {
      const error = new Error('Product not found');
      error.code = result.oErrorCode;
      throw error;
    }

    return {
      productId: productId,
      productCode: result.oProductCode,
      productName: result.oProductName,
      productType: result.oProductType,
      basePremium: result.oBasePremium,
      coverageLimit: result.oCoverageLimit,
      minThreshold: result.oMinThreshold,
      waitingMonths: result.oWaitingMonths,
      status: result.oStatus
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning null for getProductById');
      return null;
    }
    throw error;
  }
};

/**
 * Calculate premium
 * @param {string} productCode - Product code
 * @param {number} vehiclesCount - Number of vehicles
 * @param {string} payFrequency - Payment frequency (M/Q/A)
 * @returns {Promise<Object>} - Premium calculation
 */
const calculatePremium = async (productCode, vehiclesCount, payFrequency) => {
  const params = [
    { name: 'pProductCode', type: '10a', value: productCode, io: 'in' },
    { name: 'pVehiclesCount', type: '2p0', value: vehiclesCount, io: 'in' },
    { name: 'pPayFrequency', type: '1a', value: payFrequency, io: 'in' },
    { name: 'oBasePremium', type: '9p2', io: 'out' },
    { name: 'oVehicleAddon', type: '9p2', io: 'out' },
    { name: 'oFreqSurcharge', type: '9p2', io: 'out' },
    { name: 'oTotalPremium', type: '9p2', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_CALCULATEPREMIUM', params);

    return {
      basePremium: result.oBasePremium || 0,
      vehicleAddon: result.oVehicleAddon || 0,
      frequencySurcharge: result.oFreqSurcharge || 0,
      totalPremium: result.oTotalPremium || 0
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning zeros for calculatePremium');
      return { basePremium: 0, vehicleAddon: 0, frequencySurcharge: 0, totalPremium: 0 };
    }
    throw error;
  }
};

//==============================================================
// CONTRACT PROCEDURES
//==============================================================

/**
 * Get contract by ID
 * @param {number} contId - Contract ID
 * @returns {Promise<Object>} - Contract data
 */
const getContractById = async (contId) => {
  const params = [
    { name: 'pContId', type: '10p0', value: contId, io: 'in' },
    { name: 'oContReference', type: '25a', io: 'out' },
    { name: 'oCustId', type: '10p0', io: 'out' },
    { name: 'oBrokerId', type: '10p0', io: 'out' },
    { name: 'oProductId', type: '10p0', io: 'out' },
    { name: 'oStartDate', type: 'date', io: 'out' },
    { name: 'oEndDate', type: 'date', io: 'out' },
    { name: 'oVehiclesCount', type: '2p0', io: 'out' },
    { name: 'oPayFrequency', type: '1a', io: 'out' },
    { name: 'oPremiumAmt', type: '9p2', io: 'out' },
    { name: 'oAutoRenew', type: '1a', io: 'out' },
    { name: 'oStatus', type: '3a', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' },
    { name: 'oErrorCode', type: '10a', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_GETCONTRACTBYID', params);

    if (result.oSuccess !== 'Y') {
      const error = new Error('Contract not found');
      error.code = result.oErrorCode;
      throw error;
    }

    return {
      contId: contId,
      contReference: result.oContReference,
      custId: result.oCustId,
      brokerId: result.oBrokerId,
      productId: result.oProductId,
      startDate: result.oStartDate,
      endDate: result.oEndDate,
      vehiclesCount: result.oVehiclesCount,
      payFrequency: result.oPayFrequency,
      premiumAmt: result.oPremiumAmt,
      autoRenew: result.oAutoRenew,
      status: result.oStatus
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning null for getContractById');
      return null;
    }
    throw error;
  }
};

/**
 * List all contracts (with optional status filter)
 * @param {string} status - Optional status filter (ACT, SUS, CLS, EXP)
 * @returns {Promise<Array>} - Array of contracts
 */
const listContracts = async (status = '') => {
  const params = [
    { name: 'pStatus', type: '3a', value: status || '', io: 'in' },
    { name: 'oJsonData', type: '32000a', value: '', io: 'out', varying: 2 },
    { name: 'oCount', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_LISTCONTRACTS', params);

    if (result.oSuccess !== 'Y') {
      console.warn('[RPG] listContracts returned unsuccessful, returning empty array');
      return [];
    }

    try {
      return JSON.parse(result.oJsonData || '[]');
    } catch (e) {
      console.error('[RPG] JSON parse error:', e, 'Data:', result.oJsonData);
      return [];
    }
  } catch (error) {
    // SQLCODE 8013 = licensing/connection issue on PUB400 - ignore and return empty
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning empty array');
      return [];
    }
    throw error;
  }
};

/**
 * Delete a contract (soft delete - sets status to CLS)
 * @param {number} contId - Contract ID
 * @returns {Promise<boolean>} - Success
 */
const deleteContract = async (contId) => {
  const params = [
    { name: 'pContId', type: '10p0', value: contId, io: 'in' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' },
    { name: 'oErrorCode', type: '10a', value: '', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_DELETECONTRACT', params);

    if (result.oSuccess !== 'Y') {
      const error = new Error('Failed to delete contract');
      error.code = result.oErrorCode;
      throw error;
    }

    return true;
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning false for deleteContract');
      return false;
    }
    throw error;
  }
};

/**
 * Create a new contract
 * @param {Object} contractData - Contract data
 * @returns {Promise<Object>} - Created contract
 */
const createContract = async (contractData) => {
  const params = [
    { name: 'pCustId', type: '10p0', value: contractData.custId, io: 'in' },
    { name: 'pBrokerId', type: '10p0', value: contractData.brokerId, io: 'in' },
    { name: 'pProductId', type: '10p0', value: contractData.productId, io: 'in' },
    { name: 'pStartDate', type: 'date', value: contractData.startDate, io: 'in' },
    { name: 'pVehiclesCount', type: '2p0', value: contractData.vehiclesCount || 0, io: 'in' },
    { name: 'pPayFrequency', type: '1a', value: contractData.payFrequency || 'A', io: 'in' },
    { name: 'pAutoRenewal', type: '1a', value: contractData.autoRenewal || 'Y', io: 'in' },
    { name: 'oContId', type: '10p0', io: 'out' },
    { name: 'oContReference', type: '25a', io: 'out' },
    { name: 'oTotalPremium', type: '9p2', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' },
    { name: 'oErrorCode', type: '10a', io: 'out' }
  ];

  const result = await callRpg('WRAP_CREATECONTRACT', params);

  if (result.oSuccess !== 'Y') {
    const error = new Error('Failed to create contract');
    error.code = result.oErrorCode;
    throw error;
  }

  return {
    contId: result.oContId,
    contReference: result.oContReference,
    totalPremium: result.oTotalPremium,
    ...contractData
  };
};

//==============================================================
// CLAIM PROCEDURES
//==============================================================

/**
 * List all claims (with optional status filter)
 * @param {string} status - Optional status filter (NEW, PRO, CLO, REJ)
 * @returns {Promise<Array>} - Array of claims
 */
const listClaims = async (status = '') => {
  const params = [
    { name: 'pStatus', type: '3a', value: status || '', io: 'in' },
    { name: 'oJsonData', type: '32000a', value: '', io: 'out', varying: 2 },
    { name: 'oCount', type: '10p0', value: 0, io: 'out' },
    { name: 'oSuccess', type: '1a', value: '', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_LISTCLAIMS', params);

    if (result.oSuccess !== 'Y') {
      return [];
    }

    try {
      // Strip leading control characters (VARCHAR length bytes from RPG)
      let jsonData = result.oJsonData || '[]';
      const firstBracket = jsonData.indexOf('[');
      if (firstBracket > 0) {
        jsonData = jsonData.substring(firstBracket);
      }
      return JSON.parse(jsonData);
    } catch (e) {
      console.error('[RPG] Failed to parse claims JSON:', e);
      return [];
    }
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning empty array for listClaims');
      return [];
    }
    throw error;
  }
};

/**
 * Get claim by ID
 * @param {number} claimId - Claim ID
 * @returns {Promise<Object>} - Claim data
 */
const getClaimById = async (claimId) => {
  const params = [
    { name: 'pClaimId', type: '10p0', value: claimId, io: 'in' },
    { name: 'oClaimReference', type: '15a', io: 'out' },
    { name: 'oFileReference', type: '15a', io: 'out' },
    { name: 'oContId', type: '10p0', io: 'out' },
    { name: 'oGuaranteeCode', type: '10a', io: 'out' },
    { name: 'oDeclarationDate', type: 'date', io: 'out' },
    { name: 'oIncidentDate', type: 'date', io: 'out' },
    { name: 'oClaimedAmount', type: '11p2', io: 'out' },
    { name: 'oApprovedAmount', type: '11p2', io: 'out' },
    { name: 'oStatus', type: '3a', io: 'out' },
    { name: 'oResolutionType', type: '3a', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' },
    { name: 'oErrorCode', type: '10a', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_GETCLAIMBYID', params);

    if (result.oSuccess !== 'Y') {
      const error = new Error('Claim not found');
      error.code = result.oErrorCode;
      throw error;
    }

    return {
      claimId: claimId,
      claimReference: result.oClaimReference,
      fileReference: result.oFileReference,
      contId: result.oContId,
      guaranteeCode: result.oGuaranteeCode,
      declarationDate: result.oDeclarationDate,
      incidentDate: result.oIncidentDate,
      claimedAmount: result.oClaimedAmount,
      approvedAmount: result.oApprovedAmount,
      status: result.oStatus,
      resolutionType: result.oResolutionType
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning null for getClaimById');
      return null;
    }
    throw error;
  }
};

/**
 * Create a new claim
 * @param {Object} claimData - Claim data
 * @returns {Promise<Object>} - Created claim
 */
const createClaim = async (claimData) => {
  const params = [
    { name: 'pContId', type: '10p0', value: claimData.contId, io: 'in' },
    { name: 'pGuaranteeCode', type: '10a', value: claimData.guaranteeCode, io: 'in' },
    { name: 'pIncidentDate', type: 'date', value: claimData.incidentDate, io: 'in' },
    { name: 'pClaimedAmount', type: '11p2', value: claimData.claimedAmount, io: 'in' },
    { name: 'pDescription', type: '500a', value: claimData.description || '', io: 'in' },
    { name: 'oClaimId', type: '10p0', io: 'out' },
    { name: 'oClaimReference', type: '15a', io: 'out' },
    { name: 'oFileReference', type: '15a', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' },
    { name: 'oErrorCode', type: '10a', io: 'out' }
  ];

  const result = await callRpg('WRAP_CREATECLAIM', params);

  if (result.oSuccess !== 'Y') {
    const error = new Error('Failed to create claim');
    error.code = result.oErrorCode;
    throw error;
  }

  return {
    claimId: result.oClaimId,
    claimReference: result.oClaimReference,
    fileReference: result.oFileReference,
    ...claimData
  };
};

/**
 * Validate a claim
 * @param {number} contId - Contract ID
 * @param {string} guaranteeCode - Guarantee code
 * @param {number} claimedAmount - Claimed amount
 * @param {string} incidentDate - Incident date
 * @returns {Promise<Object>} - Validation result
 */
const validateClaim = async (contId, guaranteeCode, claimedAmount, incidentDate) => {
  const params = [
    { name: 'pContId', type: '10p0', value: contId, io: 'in' },
    { name: 'pGuaranteeCode', type: '10a', value: guaranteeCode, io: 'in' },
    { name: 'pClaimedAmount', type: '11p2', value: claimedAmount, io: 'in' },
    { name: 'pIncidentDate', type: 'date', value: incidentDate, io: 'in' },
    { name: 'oIsValid', type: '1a', io: 'out' },
    { name: 'oIsCovered', type: '1a', io: 'out' },
    { name: 'oWaitingPassed', type: '1a', io: 'out' },
    { name: 'oAboveThreshold', type: '1a', io: 'out' },
    { name: 'oWaitingDays', type: '5p0', io: 'out' },
    { name: 'oErrorCode', type: '10a', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_VALIDATECLAIM', params);

    return {
      isValid: result.oIsValid === 'Y',
      isCovered: result.oIsCovered === 'Y',
      waitingPassed: result.oWaitingPassed === 'Y',
      aboveThreshold: result.oAboveThreshold === 'Y',
      waitingDaysLeft: result.oWaitingDays || 0,
      errorCode: result.oErrorCode
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning default validation for validateClaim');
      return {
        isValid: false,
        isCovered: false,
        waitingPassed: false,
        aboveThreshold: false,
        waitingDaysLeft: 0,
        errorCode: 'DB8013'
      };
    }
    throw error;
  }
};

//==============================================================
// DASHBOARD PROCEDURES
//==============================================================

/**
 * Get dashboard statistics
 * @returns {Promise<Object>} - Dashboard KPIs
 */
const getDashboardStats = async () => {
  const params = [
    { name: 'oTotalBrokers', type: '10p0', io: 'out' },
    { name: 'oActiveBrokers', type: '10p0', io: 'out' },
    { name: 'oTotalCustomers', type: '10p0', io: 'out' },
    { name: 'oActiveCustomers', type: '10p0', io: 'out' },
    { name: 'oTotalContracts', type: '10p0', io: 'out' },
    { name: 'oActiveContracts', type: '10p0', io: 'out' },
    { name: 'oTotalClaims', type: '10p0', io: 'out' },
    { name: 'oAmicableClaims', type: '10p0', io: 'out' },
    { name: 'oTribunalClaims', type: '10p0', io: 'out' },
    { name: 'oAmicableRate', type: '5p2', io: 'out' },
    { name: 'oSuccess', type: '1a', io: 'out' }
  ];

  try {
    const result = await callRpg('WRAP_GETDASHBOARDSTATS', params);

    return {
      brokers: {
        total: result.oTotalBrokers || 0,
        active: result.oActiveBrokers || 0
      },
      customers: {
        total: result.oTotalCustomers || 0,
        active: result.oActiveCustomers || 0
      },
      contracts: {
        total: result.oTotalContracts || 0,
        active: result.oActiveContracts || 0
      },
      claims: {
        total: result.oTotalClaims || 0,
        amicableResolutions: result.oAmicableClaims || 0,
        tribunalResolutions: result.oTribunalClaims || 0,
        amicableRate: result.oAmicableRate || 0,
        amicableRateTarget: 79
      }
    };
  } catch (error) {
    if (error.message && error.message.includes('8013')) {
      console.warn('[RPG] SQLCODE 8013 (licensing issue) - returning zeros for getDashboardStats');
      return {
        brokers: { total: 0, active: 0 },
        customers: { total: 0, active: 0 },
        contracts: { total: 0, active: 0 },
        claims: { total: 0, amicableResolutions: 0, tribunalResolutions: 0, amicableRate: 0, amicableRateTarget: 79 }
      };
    }
    throw error;
  }
};

module.exports = {
  // Broker
  listBrokers,
  getBrokerById,
  createBroker,
  deleteBroker,
  // Customer
  listCustomers,
  getCustomerById,
  getCustomerByEmail,
  getCustomerContracts,
  createCustomer,
  // Product
  listProducts,
  getProductById,
  getProductByCode,
  getProductGuarantees,
  calculatePremium,
  // Contract
  listContracts,
  getContractById,
  createContract,
  deleteContract,
  // Claim
  listClaims,
  getClaimById,
  createClaim,
  validateClaim,
  // Dashboard
  getDashboardStats
};

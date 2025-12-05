/**
 * Business Constants - DAS Belgium
 * Matches RPG copybooks and SQL stored procedures
 */

// Status codes (shared across entities)
const STATUS = {
  ACTIVE: 'ACT',
  INACTIVE: 'INA',
  SUSPENDED: 'SUS',
  PENDING: 'PEN',
  EXPIRED: 'EXP',
  CANCELLED: 'CAN',
  RENEWAL: 'REN'
};

// Contract statuses
const CONTRACT_STATUS = {
  PENDING: 'PEN',
  ACTIVE: 'ACT',
  EXPIRED: 'EXP',
  CANCELLED: 'CAN',
  RENEWAL: 'REN'
};

// Claim statuses
const CLAIM_STATUS = {
  NEW: 'NEW',
  IN_PROGRESS: 'PRO',
  RESOLVED: 'RES',
  CLOSED: 'CLO',
  REJECTED: 'REJ'
};

// Resolution types (79% AMI at DAS!)
const RESOLUTION_TYPE = {
  AMICABLE: 'AMI',      // 79% of cases
  LITIGATION: 'LIT',    // 21% of cases
  REJECTED: 'REJ'
};

// Customer types
const CUSTOMER_TYPE = {
  INDIVIDUAL: 'IND',
  BUSINESS: 'BUS'
};

// Civil status codes (TELEBIB2)
const CIVIL_STATUS = {
  SINGLE: 'SGL',
  MARRIED: 'MAR',
  COHABITING: 'COH',
  DIVORCED: 'DIV',
  WIDOWED: 'WID'
};

// Payment frequency
const PAYMENT_FREQUENCY = {
  MONTHLY: 'M',       // +5% surcharge
  QUARTERLY: 'Q',     // +2% surcharge
  ANNUAL: 'A'         // No surcharge
};

// Product codes (DAS Belgium catalog)
const PRODUCT_CODES = {
  CLASSIC: 'CLASSIC',
  CONNECT: 'CONNECT',
  COMFORT: 'COMFORT',
  VIE_PRIV: 'VIE_PRIV',
  CONSOM: 'CONSOM',
  CONSOM_BF: 'CONSOM_BF',
  CONFLIT_BF: 'CONFLIT_BF',
  SUR_MES: 'SUR_MES',
  FISCASST: 'FISCASST'
};

// Guarantee codes (Coverage types - TELEBIB2)
const GUARANTEE_CODES = {
  CIV_RECOV: 'CIV_RECOV',      // Civil recovery
  CRIM_DEF: 'CRIM_DEF',        // Criminal defense
  INS_CONTR: 'INS_CONTR',      // Insurance contracts
  MED_MALPR: 'MED_MALPR',      // Medical malpractice
  NEIGHBOR: 'NEIGHBOR',        // Neighborhood disputes
  FAMILY: 'FAMILY',            // Family law (Benefisc only)
  TAX: 'TAX',                  // Tax law (Benefisc only)
  EMPLOY: 'EMPLOY',            // Employment law (Benefisc only)
  SUCCES: 'SUCCES',            // Succession rights (Benefisc only)
  ADMIN: 'ADMIN'               // Administrative law (Benefisc only)
};

// Circumstance codes (Claim types - TELEBIB2)
const CIRCUMSTANCE_CODES = {
  CONTR_DISP: 'CONTR_DISP',    // Contract dispute
  EMPL_DISP: 'EMPL_DISP',      // Employment dispute
  NEIGH_DISP: 'NEIGH_DISP',    // Neighborhood dispute
  TAX_DISP: 'TAX_DISP',        // Tax dispute
  MED_MALPR: 'MED_MALPR',      // Medical malpractice
  CRIM_DEF: 'CRIM_DEF',        // Criminal defense
  FAM_DISP: 'FAM_DISP',        // Family dispute
  ADMIN_DISP: 'ADMIN_DISP'     // Administrative dispute
};

// Business rules
const BUSINESS_RULES = {
  MIN_CLAIM_THRESHOLD: 350,        // €350 minimum intervention
  VEHICLE_ADDON_RATE: 25,          // €25 per vehicle
  COVERAGE_LIMIT_MAX: 200000,      // €200,000 maximum coverage
  PAYMENT_SURCHARGE_MONTHLY: 1.05, // 5% surcharge
  PAYMENT_SURCHARGE_QUARTERLY: 1.02, // 2% surcharge
  CONTRACT_DURATION_YEARS: 1,      // 1 year contracts
  CANCELLATION_NOTICE_DAYS: 60,    // 2 months notice
  AMICABLE_RESOLUTION_TARGET: 0.79 // 79% target
};

// Error codes (from ERRUTIL)
const ERROR_CODES = {
  // Validation errors
  VAL001: 'Invalid email format',
  VAL002: 'Invalid VAT number',
  VAL003: 'Invalid national ID',
  VAL004: 'Invalid postal code',
  VAL005: 'Invalid FSMA number',
  VAL006: 'Required field missing',
  VAL007: 'End date before start date',

  // Business errors
  BUS001: 'Individual customer missing name',
  BUS002: 'Business customer missing company name',
  BUS003: 'Contract not active',
  BUS004: 'Incident during waiting period',
  BUS005: 'Not covered by product',
  BUS006: 'Amount below minimum threshold',
  BUS007: 'Approved amount exceeds coverage limit',
  BUS008: 'Auto-renewal disabled',
  BUS010: 'Product not available',

  // Database errors
  DB001: 'Record not found',
  DB002: 'Duplicate record',
  DB004: 'Database operation failed'
};

module.exports = {
  STATUS,
  CONTRACT_STATUS,
  CLAIM_STATUS,
  RESOLUTION_TYPE,
  CUSTOMER_TYPE,
  CIVIL_STATUS,
  PAYMENT_FREQUENCY,
  PRODUCT_CODES,
  GUARANTEE_CODES,
  CIRCUMSTANCE_CODES,
  BUSINESS_RULES,
  ERROR_CODES
};

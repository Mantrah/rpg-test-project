# CUSTSRV - Customer Service Module

**Program:** `CUSTSRV.sqlrpgle`
**Copybook:** `CUSTSRV_H.rpgle`
**Target System:** IBM i V7R5
**Project:** DAS.be Backend - Legal Protection Insurance

---

## Overview

### Purpose

CUSTSRV provides comprehensive customer (policyholder) management for the DAS.be legal protection insurance system. The module supports both individual customers (particuliers) and business customers (entreprises) with Belgian-specific validation rules and TELEBIB2 EDI compliance.

### Key Features

- **Dual customer types:** Individuals (IND) and Businesses (BUS)
- **Belgian identity validation:** National Register Number (NRN), VAT numbers
- **TELEBIB2 compliance:** CivilStatusCode, BusinessCodeNace, Address segments
- **Multilingual support:** French (FR), Dutch (NL), German (DE)
- **Comprehensive validation:** Email format, postal codes, required fields per type
- **Data quality enforcement:** Type-specific validation rules
- **Soft delete:** Preserve data integrity and audit trail

### Business Context

**DAS Belgium Customer Base:**
- **Individuals:** DAS Classic, Connect, Comfort, Benefisc products
- **Businesses:** Sur Mesure, FiscAssist professional coverage
- **Distribution:** All customers acquired through insurance brokers
- **Trilingual:** Belgium's three official languages supported

**Customer Types:**
- **IND:** Individual policyholders (firstName + lastName + NRN)
- **BUS:** Business entities (companyName + VAT + NACE code)

---

## Architecture

### Design Pattern

**Service Module Pattern:**
- NOMAIN module (service program)
- Type-aware validation (IND vs BUS)
- Modular validators for reusability
- Centralized error handling via ERRUTIL

### Data Flow

```
Caller Program
    ↓
CUSTSRV Procedure
    ↓
IsValidCustomer
    ├→ IsValidEmail
    ├→ IsValidVatNumber (BUS only)
    ├→ IsValidNationalId (IND only)
    └→ IsValidPostalCode
    ↓
ERRUTIL (error codes)
    ↓
SQL Operations (CUSTOMER table)
    ↓
Return Result
```

### Integration Points

- **ERRUTIL:** Validation and error handling
- **CUSTOMER Table:** Database persistence
- **TELEBIB2:** CivilStatusCode, BusinessCodeNace, ADR segments
- **CONTRACT Module:** Foreign key relationship (customer → contracts)

---

## Technical Specifications

### Control Options

```rpg
ctl-opt nomain option(*srcstmt:*nodebugio);
```

- **nomain:** Service program module (no main procedure)
- **srcstmt:** Source statement debugging support
- **nodebugio:** Disable interactive debugging I/O

### Database Tables

**CUSTOMER:** Primary table for customer master data

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| CUST_ID | DECIMAL(10,0) | PK, identity column | - |
| CUST_TYPE | CHAR(3) | IND/BUS | - |
| FIRST_NAME | VARCHAR(50) | First name (IND) | - |
| LAST_NAME | VARCHAR(50) | Last name (IND) | - |
| NATIONAL_ID | CHAR(15) | Belgian NRN (IND) | - |
| CIVIL_STATUS | CHAR(3) | Marital status (IND) | CivilStatusCode |
| BIRTH_DATE | DATE | Date of birth (IND) | BirthDate |
| COMPANY_NAME | VARCHAR(100) | Company name (BUS) | - |
| VAT_NUMBER | CHAR(12) | Belgian VAT (BUS) | - |
| NACE_CODE | CHAR(5) | Business activity (BUS) | BusinessCodeNace |
| STREET | VARCHAR(30) | Street name | X002 |
| HOUSE_NBR | CHAR(5) | House number | X003 |
| BOX_NBR | CHAR(4) | Box/suite number | X004 |
| POSTAL_CODE | CHAR(7) | Postal code | X006 |
| CITY | VARCHAR(24) | City name | X007 |
| COUNTRY_CODE | CHAR(3) | Country (BEL) | X008 |
| PHONE | VARCHAR(20) | Phone number | - |
| EMAIL | VARCHAR(100) | Email address | - |
| LANGUAGE | CHAR(2) | FR/NL/DE | - |
| STATUS | CHAR(3) | ACT/INA/SUS | - |
| CREATED_AT | TIMESTAMP | Record creation | - |
| UPDATED_AT | TIMESTAMP | Last update | - |

**Status Codes:**
- `ACT` - Active
- `INA` - Inactive (soft deleted)
- `SUS` - Suspended

### Data Structures

**Customer_t** ([CUSTSRV_H.rpgle:13](../src/qrpglesrc/CUSTSRV_H.rpgle#L13))

Complete customer information structure supporting both individual and business customers.

```rpg
dcl-ds Customer_t qualified template;
    custId          packed(10:0);
    custType        char(3);            // IND/BUS
    // Individual fields
    firstName       varchar(50);
    lastName        varchar(50);
    nationalId      char(15);           // Belgian NRN: YY.MM.DD-XXX.CC
    civilStatus     char(3);            // CivilStatusCode (TELEBIB2)
    birthDate       date;
    // Business fields
    companyName     varchar(100);
    vatNumber       char(12);           // BE0123456789
    naceCode        char(5);            // BusinessCodeNace (TELEBIB2)
    // Address (TELEBIB2 ADR segment)
    street          varchar(30);        // X002
    houseNbr        char(5);            // X003
    boxNbr          char(4);            // X004
    postalCode      char(7);            // X006
    city            varchar(24);        // X007
    countryCode     char(3);            // X008
    // Contact
    phone           varchar(20);
    email           varchar(100);
    language        char(2);            // FR/NL/DE
    // Audit
    status          char(3);
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;
```

**CustomerFilter_t** ([CUSTSRV_H.rpgle:46](../src/qrpglesrc/CUSTSRV_H.rpgle#L46))

Search filter criteria for listing customers.

```rpg
dcl-ds CustomerFilter_t qualified template;
    custType        char(3);
    lastName        varchar(50);
    companyName     varchar(100);
    city            varchar(24);
    status          char(3);
end-ds;
```

### Constants

**Civil Status Codes** ([CUSTSRV_H.rpgle:57-61](../src/qrpglesrc/CUSTSRV_H.rpgle#L57-L61))

TELEBIB2-aligned marital status codes for individual customers.

| Constant | Value | Description |
|----------|-------|-------------|
| CIVIL_SINGLE | SGL | Single/unmarried |
| CIVIL_MARRIED | MAR | Married |
| CIVIL_COHABITING | COH | Legal cohabitation |
| CIVIL_DIVORCED | DIV | Divorced |
| CIVIL_WIDOWED | WID | Widowed |

---

## Procedures Reference

### CreateCustomer

**Procedure:** `CUSTSRV_CreateCustomer` ([CUSTSRV.sqlrpgle:21](../src/qrpglesrc/CUSTSRV.sqlrpgle#L21))

Inserts a new customer (individual or business) into the system.

**Parameters:**
- `pCustomer` (Customer_t, const) - Customer data to insert

**Returns:**
- `DECIMAL(10,0)` - New customer ID (0 on error)

**Validation:**
- **IND:** firstName, lastName required; optional nationalId validation
- **BUS:** companyName required; optional VAT validation
- **Common:** Email format, postal code format

**Error Codes:**
- `VAL006` - Invalid customer type (not IND or BUS)
- `BUS001` - Individual missing firstName or lastName
- `BUS002` - Business missing companyName
- `VAL001` - Invalid email format
- `VAL002` - Invalid VAT number format
- `VAL003` - Invalid national ID format
- `VAL004` - Invalid postal code format
- `DB004` - Database operation failed

**Business Logic:**
1. Initialize error handler
2. Validate customer via IsValidCustomer
3. Insert with status 'ACT'
4. Retrieve generated CUST_ID via IDENTITY_VAL_LOCAL()
5. Return new ID or 0 on error

---

### GetCustomer

**Procedure:** `CUSTSRV_GetCustomer` ([CUSTSRV.sqlrpgle:73](../src/qrpglesrc/CUSTSRV.sqlrpgle#L73))

Retrieves customer by primary key.

**Parameters:**
- `pCustId` (DECIMAL(10,0), const) - Customer ID

**Returns:**
- `Customer_t` - Customer data structure (empty on error)

**Error Codes:**
- `DB001` - Customer not found (SQLCODE 100)
- `DB004` - Database operation failed

**Logic:**
1. Execute SELECT by CUST_ID
2. Populate Customer_t structure (all fields)
3. Clear structure on error
4. Return result

---

### UpdateCustomer

**Procedure:** `CUSTSRV_UpdateCustomer` ([CUSTSRV.sqlrpgle:115](../src/qrpglesrc/CUSTSRV.sqlrpgle#L115))

Updates existing customer information.

**Parameters:**
- `pCustomer` (Customer_t, const) - Customer data with ID

**Returns:**
- `IND` - Success indicator (*ON = success, *OFF = failure)

**Validation:**
- Same as CreateCustomer
- Customer ID must exist

**Error Codes:**
- (Same as CreateCustomer)
- `DB004` - Update failed

**Logic:**
1. Validate customer data
2. UPDATE all modifiable fields
3. Set UPDATED_AT to current timestamp
4. Return success indicator

**Business Rule:**
Allows switching between IND and BUS types (business requirement flexibility).

---

### DeleteCustomer

**Procedure:** `CUSTSRV_DeleteCustomer` ([CUSTSRV.sqlrpgle:174](../src/qrpglesrc/CUSTSRV.sqlrpgle#L174))

Soft deletes a customer (sets status to inactive).

**Parameters:**
- `pCustId` (DECIMAL(10,0), const) - Customer ID

**Returns:**
- `IND` - Success indicator

**Error Codes:**
- `DB004` - Update failed

**Business Rule:**
Soft delete preserves audit trail and referential integrity with contracts. Customer is marked as 'INA' but data remains in database for historical policy lookup.

---

### ListCustomers

**Procedure:** `CUSTSRV_ListCustomers` ([CUSTSRV.sqlrpgle:207](../src/qrpglesrc/CUSTSRV.sqlrpgle#L207))

Searches customers with filter criteria.

**Parameters:**
- `pFilter` (CustomerFilter_t, const) - Search filters

**Returns:**
- `INT(10)` - Count of matching customers

**Filter Logic:**
- Empty filter fields are ignored (OR condition)
- lastName and companyName use LIKE with trailing wildcard
- custType, city, status use exact match

**Note:** Current implementation returns count only. Typical enhancement would return result set via SQL cursor or array.

---

### IsValidCustomer

**Procedure:** `CUSTSRV_IsValidCustomer` ([CUSTSRV.sqlrpgle:238](../src/qrpglesrc/CUSTSRV.sqlrpgle#L238))

Validates customer data before insert/update with type-aware logic.

**Parameters:**
- `pCustomer` (Customer_t, const) - Customer to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**

**1. Customer Type:**
- Must be 'IND' or 'BUS' (error: VAL006)

**2. Individual (IND) Requirements:**
- firstName required (non-blank)
- lastName required (non-blank)
- nationalId validated if provided

**3. Business (BUS) Requirements:**
- companyName required (non-blank)
- vatNumber validated if provided

**4. Common Validations:**
- Email format (if provided)
- Postal code format (if provided)

**Error Codes:**
- `VAL006` - Invalid customer type
- `BUS001` - Individual missing required name fields
- `BUS002` - Business missing company name
- Plus validation errors from sub-validators

**Design Note:**
Cascading validation - calls specialized validators and propagates their error codes.

---

### IsValidEmail

**Procedure:** `CUSTSRV_IsValidEmail` ([CUSTSRV.sqlrpgle:290](../src/qrpglesrc/CUSTSRV.sqlrpgle#L290))

Validates email address format.

**Parameters:**
- `pEmail` (VARCHAR(100), const) - Email to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**
1. Must contain `@` symbol (position >= 2)
2. Must have `.` after `@` (domain extension)
3. Dot must be at least 2 characters after `@`

**Error Codes:**
- `VAL001` - Invalid email format

**Algorithm:**
```
Valid:   user@example.com
Invalid: @example.com        (@ at position < 2)
Invalid: user@example        (no dot after @)
Invalid: user@.com           (dot immediately after @)
```

**Note:** Basic validation only. Production implementation might use regex or stricter RFC 5322 compliance.

---

### IsValidVatNumber

**Procedure:** `CUSTSRV_IsValidVatNumber` ([CUSTSRV.sqlrpgle:320](../src/qrpglesrc/CUSTSRV.sqlrpgle#L320))

Validates Belgian VAT number format.

**Parameters:**
- `pVatNumber` (CHAR(12), const) - VAT number to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**
1. Exactly 12 characters (after trim)
2. Must start with "BE"
3. Remaining 10 characters must be digits (0-9)

**Error Codes:**
- `VAL002` - Invalid VAT number format

**Format:**
```
Valid:   BE0123456789
Invalid: BE123        (too short)
Invalid: NL123456789  (wrong country code)
Invalid: BE01234567AB (non-numeric digits)
```

**Belgian VAT Structure:**
- Prefix: `BE`
- Digits: 10 numeric characters
- Example: `BE0477472701` (real DAS Belgium VAT)

**Note:** This validates format only. Production implementation would include MOD 97 checksum validation per Belgian standards.

---

### IsValidNationalId

**Procedure:** `CUSTSRV_IsValidNationalId` ([CUSTSRV.sqlrpgle:360](../src/qrpglesrc/CUSTSRV.sqlrpgle#L360))

Validates Belgian National Register Number (Numéro de Registre National / Rijksregisternummer).

**Parameters:**
- `pNationalId` (CHAR(15), const) - NRN to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**
1. Minimum length: 11 characters (after trim)

**Error Codes:**
- `VAL003` - Invalid national ID format

**Belgian NRN Format:**
```
YY.MM.DD-XXX.CC
│  │  │  │   └─ Check digits (MOD 97)
│  │  │  └───── Sequential number + gender
│  │  └──────── Birth day
│  └─────────── Birth month
└────────────── Birth year (2 digits)

Example: 85.07.30-223.61
```

**Current Implementation:**
Simplified validation (length only). Production implementation would validate:
- Date components (valid month/day)
- Sequential number range
- MOD 97 checksum algorithm
- Gender encoding (odd=male, even=female)

---

### IsValidPostalCode

**Procedure:** `CUSTSRV_IsValidPostalCode` ([CUSTSRV.sqlrpgle:381](../src/qrpglesrc/CUSTSRV.sqlrpgle#L381))

Validates Belgian postal code format.

**Parameters:**
- `pPostalCode` (CHAR(7), const) - Postal code to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**
1. Exactly 4 digits (after trim)
2. Range: 1000-9999 (implicit via digit validation)

**Error Codes:**
- `VAL004` - Invalid postal code format

**Belgian Postal Code Structure:**
```
Valid:   1000 (Brussels)
Valid:   2000 (Antwerp)
Valid:   9999 (Valid range)
Invalid: 999  (too short)
Invalid: A123 (non-numeric)
```

**Major Cities:**
- 1000-1299: Brussels region
- 2000-2999: Antwerp province
- 3000-3499: Flemish Brabant
- 4000-4999: Liège province
- 9000-9999: East Flanders

---

## Error Handling

### ERRUTIL Integration

All procedures use ERRUTIL for consistent error management:

```rpg
monitor;
    // Business logic
on-error;
    ERRUTIL_addExecutionError();
endmon;
```

### Error Codes Reference

| Code | Description | Procedure |
|------|-------------|-----------|
| VAL001 | Invalid email format | IsValidEmail |
| VAL002 | Invalid VAT number | IsValidVatNumber |
| VAL003 | Invalid national ID | IsValidNationalId |
| VAL004 | Invalid postal code | IsValidPostalCode |
| VAL006 | Invalid/missing required field | IsValidCustomer |
| BUS001 | Individual missing name | IsValidCustomer (IND) |
| BUS002 | Business missing company name | IsValidCustomer (BUS) |
| DB001 | Record not found | GetCustomer (SQLCODE 100) |
| DB004 | Database operation failed | Any SQL error |

### Error Recovery Strategy

**CreateCustomer:**
- Returns 0 on error
- Caller should check ERRUTIL for specific validation failure

**GetCustomer:**
- Returns empty structure on error
- Check `custId = 0` to detect failure

**UpdateCustomer/DeleteCustomer:**
- Returns *OFF on error
- Caller should check ERRUTIL for details

**Validators:**
- Return *OFF and set specific error code
- Error codes indicate exact validation failure point

---

## Database Operations

### Insert Pattern

```rpg
exec sql
    INSERT INTO CUSTOMER (...) VALUES (...);

if sqlcode = 0;
    exec sql
        SELECT IDENTITY_VAL_LOCAL() INTO :newCustId
        FROM SYSIBM.SYSDUMMY1;
endif;
```

Uses `IDENTITY_VAL_LOCAL()` to retrieve auto-generated primary key.

### Update Pattern

```rpg
exec sql
    UPDATE CUSTOMER SET
        ...,
        UPDATED_AT = CURRENT_TIMESTAMP
    WHERE CUST_ID = :pCustomer.custId;
```

Automatically updates timestamp on every modification.

### Dynamic WHERE Clause

```rpg
WHERE (:pFilter.custType = '' OR CUST_TYPE = :pFilter.custType)
  AND (:pFilter.lastName = '' OR LAST_NAME LIKE :pFilter.lastName || '%')
  AND (:pFilter.companyName = '' OR COMPANY_NAME LIKE :pFilter.companyName || '%')
```

Empty filter fields are ignored, allowing flexible search combinations for both customer types.

### Transaction Control

No explicit transaction control (COMMIT/ROLLBACK) in this module. Assumes caller manages transaction boundaries for multi-table operations (e.g., customer + contract creation).

---

## Usage Examples

### Creating an Individual Customer

```rpg
dcl-ds customer likeds(Customer_t) inz;
dcl-s custId packed(10:0);

customer.custType = 'IND';
customer.firstName = 'Marie';
customer.lastName = 'Dubois';
customer.nationalId = '85.07.30-223.61';
customer.civilStatus = CIVIL_MARRIED;
customer.birthDate = %date('1985-07-30');
customer.street = 'Avenue Louise';
customer.houseNbr = '123';
customer.postalCode = '1050';
customer.city = 'Bruxelles';
customer.countryCode = 'BEL';
customer.email = 'marie.dubois@example.be';
customer.phone = '+32 2 123 4567';
customer.language = 'FR';

custId = CreateCustomer(customer);

if custId > 0;
    // Success - customer created
else;
    // Check ERRUTIL for validation errors
endif;
```

### Creating a Business Customer

```rpg
dcl-ds customer likeds(Customer_t) inz;
dcl-s custId packed(10:0);

customer.custType = 'BUS';
customer.companyName = 'Boulangerie Martin SPRL';
customer.vatNumber = 'BE0987654321';
customer.naceCode = '10711';  // Bakery
customer.street = 'Rue de la Station';
customer.houseNbr = '45';
customer.postalCode = '4000';
customer.city = 'Liège';
customer.countryCode = 'BEL';
customer.email = 'info@boulangeriemartin.be';
customer.phone = '+32 4 987 6543';
customer.language = 'FR';

custId = CreateCustomer(customer);
```

### Retrieving a Customer

```rpg
dcl-ds customer likeds(Customer_t);

customer = GetCustomer(1);

if customer.custId > 0;
    if customer.custType = 'IND';
        // Individual: use firstName, lastName
        dsply (%trim(customer.firstName) + ' ' + %trim(customer.lastName));
    else;
        // Business: use companyName
        dsply customer.companyName;
    endif;
else;
    // Not found or error
endif;
```

### Updating Customer Contact Info

```rpg
dcl-ds customer likeds(Customer_t);
dcl-s success ind;

customer = GetCustomer(1);
customer.email = 'new.email@example.be';
customer.phone = '+32 2 999 8888';

success = UpdateCustomer(customer);
```

### Searching Customers

```rpg
// Find all active individuals in Brussels
dcl-ds filter likeds(CustomerFilter_t) inz;
dcl-s count int(10);

filter.custType = 'IND';
filter.city = 'Bruxelles';
filter.status = 'ACT';

count = ListCustomers(filter);

// Find all businesses starting with "Boulangerie"
clear filter;
filter.custType = 'BUS';
filter.companyName = 'Boulangerie';

count = ListCustomers(filter);
```

### Validating Email Before Processing

```rpg
dcl-s email varchar(100);
dcl-s isValid ind;

email = 'test@example.com';
isValid = IsValidEmail(email);

if isValid;
    // Proceed with email usage
else;
    // Check ERRUTIL for VAL001 error code
endif;
```

### Validating Belgian VAT Number

```rpg
dcl-s vat char(12);
dcl-s isValid ind;

vat = 'BE0477472701';
isValid = IsValidVatNumber(vat);

if isValid;
    // Valid Belgian VAT
endif;
```

---

## Business Logic Details

### Customer Type Differentiation

**Individual (IND):**
- **Products:** DAS Classic, Connect, Comfort, Benefisc
- **Required:** firstName, lastName
- **Optional:** nationalId, civilStatus, birthDate
- **Use Case:** Private individuals seeking personal legal protection

**Business (BUS):**
- **Products:** Sur Mesure, FiscAssist
- **Required:** companyName
- **Optional:** vatNumber, naceCode
- **Use Case:** SMEs, freelancers, professionals

### Language Support

Belgium has three official languages:
- **FR:** French (Wallonia, Brussels)
- **NL:** Dutch/Flemish (Flanders, Brussels)
- **DE:** German (Eastern Cantons)

Customer communications, policy documents, and legal advice are provided in the customer's preferred language.

### Civil Status Impact

Civil status affects coverage in certain products:
- **Family Law coverage:** Only available in Benefisc products
- **Succession rights:** Dependent on marital status
- **Tax law (FiscAssist):** Different rules for married/cohabiting

### NACE Code Integration

NACE (Nomenclature of Economic Activities) classification used for:
- **Risk assessment:** Different legal risk profiles per industry
- **Premium calculation:** Pricing varies by business type
- **Coverage customization:** Industry-specific legal protection

---

## Development Notes

### Dependencies

**Internal:**
- `ERRUTIL.rpgle` - Error handling utility
- `CUSTSRV_H.rpgle` - Copybook (data structures, prototypes, constants)

**External:**
- CUSTOMER table (must exist in database)
- SQL environment configured

### Build Instructions

```bash
# Compile service module
CRTSQLRPGI OBJ(YOURLIB/CUSTSRV) SRCFILE(QRPGLESRC) COMMIT(*NONE) OBJTYPE(*MODULE)

# Create service program
CRTSRVPGM SRVPGM(YOURLIB/CUSTSRV) MODULE(YOURLIB/CUSTSRV) EXPORT(*ALL)
```

### Testing Considerations

**Unit Test Cases:**

**Basic CRUD:**
1. CreateCustomer - Individual with all fields
2. CreateCustomer - Business with all fields
3. CreateCustomer - Missing required fields (BUS001, BUS002)
4. GetCustomer - Valid/invalid ID
5. UpdateCustomer - Modify fields
6. DeleteCustomer - Soft delete verification

**Validation:**
7. Invalid email formats (no @, no dot, etc.)
8. Invalid VAT (wrong length, bad prefix, non-numeric)
9. Invalid NRN (too short)
10. Invalid postal code (not 4 digits, non-numeric)
11. Invalid customer type (not IND/BUS)

**Edge Cases:**
12. Empty optional fields (should allow)
13. Switching customer type (IND → BUS)
14. International addresses (non-Belgian postal codes)

**Integration Tests:**
- Customer-to-Contract relationship
- Multi-customer searches with large datasets
- Concurrent updates (optimistic locking)
- TELEBIB2 message generation

### Future Enhancements

1. **ListCustomers result set:** Return actual customer records via cursor/array
2. **Advanced validation:**
   - Full NRN checksum (MOD 97 algorithm)
   - VAT checksum validation
   - NACE code lookup table
3. **Duplicate detection:** Fuzzy matching on name + address
4. **GDPR compliance:**
   - Personal data encryption
   - Right to be forgotten (hard delete capability)
   - Audit log of data access
5. **International support:**
   - Multi-country postal code validation
   - International VAT (VIES integration)
6. **Full-text search:** Customer name/company using QSYS2.SYSTEXTINDEX
7. **Pagination:** Add offset/limit to ListCustomers

### TELEBIB2 Integration Notes

**CivilStatusCode Mapping:**
Uses exact TELEBIB2 codes: SGL, MAR, COH, DIV, WID

**BusinessCodeNace:**
5-character NACE-BEL codes for business activity classification

**ADR Segment Alignment:**
Same as BROKRSRV - exact TELEBIB2 field lengths for seamless EDI integration

**PolicyholderInformation Element:**
Customer data maps directly to TELEBIB2 policyholder segment in contract messages

---

## Version History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2025-12-05 | Claude | Initial implementation |

---

**Related Documentation:**
- [Implementation Plan](../implementation-plan.md)
- [CUSTOMER Table DDL](../../sql/CUSTOMER.sql)
- [ERRUTIL Module](ERRUTIL.md)
- [CONTSRV Module](CONTSRV.md) - Contract service (uses customers)

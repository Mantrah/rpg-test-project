# BROKRSRV - Broker Service Module

**Program:** `BROKRSRV.sqlrpgle`
**Copybook:** `BROKRSRV_H.rpgle`
**Target System:** IBM i V7R5
**Project:** DAS.be Backend - Legal Protection Insurance

---

## Overview

### Purpose

BROKRSRV provides CRUD operations for managing insurance brokers in the DAS.be legal protection insurance system. Brokers (courtiers/makelaars) are the **exclusive sales channel** for DAS Belgium - all policies are sold through licensed insurance brokers, never directly to customers.

### Key Features

- Complete broker lifecycle management (Create, Read, Update, soft Delete)
- FSMA registration validation (Belgian Financial Services Authority)
- Belgian VAT number handling (BE0123456789 format)
- TELEBIB2 standard alignment for EDI integration
- Search/filter capabilities for broker listings
- Soft delete (status-based deactivation)

### Business Context

**DAS Belgium Distribution Model:**
- 100% broker-based distribution (no direct sales)
- ~236 employees, leader in Belgian legal protection insurance
- 5 regional offices across Belgium
- All brokers must have FSMA registration
- TELEBIB2 EDI standard for data exchange

---

## Architecture

### Design Pattern

**Service Module Pattern:**
- NOMAIN module (service program)
- Exported procedures for external callers
- Encapsulated validation logic
- Centralized error handling via ERRUTIL

### Data Flow

```
Caller Program
    ↓
BROKRSRV Procedure (validation)
    ↓
ERRUTIL (error handling)
    ↓
SQL Operations (BROKER table)
    ↓
Return Result
```

### Integration Points

- **ERRUTIL:** Error handling and validation messages
- **BROKER Table:** Database persistence
- **TELEBIB2:** AgencyCode and ADR segment alignment

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

**BROKER:** Primary table for broker master data

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| BROKER_ID | DECIMAL(10,0) | PK, identity column | - |
| BROKER_CODE | CHAR(10) | Unique broker code | AgencyCode |
| COMPANY_NAME | VARCHAR(100) | Legal company name | - |
| VAT_NUMBER | CHAR(12) | Belgian VAT (BE format) | - |
| FSMA_NUMBER | CHAR(10) | FSMA registration | - |
| STREET | VARCHAR(30) | Street name | X002 |
| HOUSE_NBR | CHAR(5) | House number | X003 |
| BOX_NBR | CHAR(4) | Box/suite number | X004 |
| POSTAL_CODE | CHAR(7) | Postal code | X006 |
| CITY | VARCHAR(24) | City name | X007 |
| COUNTRY_CODE | CHAR(3) | Country (BEL) | X008 |
| PHONE | VARCHAR(20) | Phone number | - |
| EMAIL | VARCHAR(100) | Email address | - |
| CONTACT_NAME | VARCHAR(100) | Primary contact | - |
| STATUS | CHAR(3) | ACT/INA/SUS | - |
| CREATED_AT | TIMESTAMP | Record creation | - |
| UPDATED_AT | TIMESTAMP | Last update | - |

**Status Codes:**
- `ACT` - Active
- `INA` - Inactive (soft deleted)
- `SUS` - Suspended

### Data Structures

**Broker_t** ([BROKRSRV_H.rpgle:13](../src/qrpglesrc/BROKRSRV_H.rpgle#L13))

Complete broker information structure with TELEBIB2-aligned fields.

```rpg
dcl-ds Broker_t qualified template;
    brokerId        packed(10:0);
    brokerCode      char(10);           // AgencyCode
    companyName     varchar(100);
    vatNumber       char(12);           // BE0123456789
    fsmaNumber      char(10);           // FSMA registration
    // Address fields (TELEBIB2 ADR segment)
    street          varchar(30);        // X002
    houseNbr        char(5);            // X003
    boxNbr          char(4);            // X004
    postalCode      char(7);            // X006
    city            varchar(24);        // X007
    countryCode     char(3);            // X008
    // Contact info
    phone           varchar(20);
    email           varchar(100);
    contactName     varchar(100);
    // Audit
    status          char(3);
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;
```

**BrokerFilter_t** ([BROKRSRV_H.rpgle:39](../src/qrpglesrc/BROKRSRV_H.rpgle#L39))

Search filter criteria for listing brokers.

```rpg
dcl-ds BrokerFilter_t qualified template;
    brokerCode      char(10);
    companyName     varchar(100);
    city            varchar(24);
    status          char(3);
end-ds;
```

---

## Procedures Reference

### CreateBroker

**Procedure:** `BROKRSRV_CreateBroker` ([BROKRSRV.sqlrpgle:21](../src/qrpglesrc/BROKRSRV.sqlrpgle#L21))

Inserts a new broker into the system.

**Parameters:**
- `pBroker` (Broker_t, const) - Broker data to insert

**Returns:**
- `DECIMAL(10,0)` - New broker ID (0 on error)

**Validation:**
- Required: brokerCode, companyName
- FSMA number format validation (if provided)

**Error Codes:**
- `VAL006` - Required field missing
- `VAL005` - Invalid FSMA number format
- `DB002` - Duplicate broker code (SQLCODE -803)
- `DB004` - Database operation failed

**Logic:**
1. Initialize error handler
2. Validate broker data via IsValidBroker
3. Insert into BROKER table with status 'ACT'
4. Retrieve generated BROKER_ID via IDENTITY_VAL_LOCAL()
5. Return new ID or 0 on error

---

### GetBroker

**Procedure:** `BROKRSRV_GetBroker` ([BROKRSRV.sqlrpgle:75](../src/qrpglesrc/BROKRSRV.sqlrpgle#L75))

Retrieves broker by primary key.

**Parameters:**
- `pBrokerId` (DECIMAL(10,0), const) - Broker ID

**Returns:**
- `Broker_t` - Broker data structure (empty on error)

**Error Codes:**
- `DB001` - Broker not found (SQLCODE 100)
- `DB004` - Database operation failed

**Logic:**
1. Execute SELECT by BROKER_ID
2. Populate Broker_t structure
3. Clear structure on error
4. Return result

---

### GetBrokerByCode

**Procedure:** `BROKRSRV_GetBrokerByCode` ([BROKRSRV.sqlrpgle:116](../src/qrpglesrc/BROKRSRV.sqlrpgle#L116))

Retrieves broker by unique broker code (alternative key).

**Parameters:**
- `pBrokerCode` (CHAR(10), const) - Broker code

**Returns:**
- `Broker_t` - Broker data structure (empty on error)

**Error Codes:**
- `DB001` - Broker not found (SQLCODE 100)
- `DB004` - Database operation failed

**Use Case:**
For TELEBIB2 integration where AgencyCode is the primary identifier in EDI messages.

---

### UpdateBroker

**Procedure:** `BROKRSRV_UpdateBroker` ([BROKRSRV.sqlrpgle:157](../src/qrpglesrc/BROKRSRV.sqlrpgle#L157))

Updates existing broker information.

**Parameters:**
- `pBroker` (Broker_t, const) - Broker data with ID

**Returns:**
- `IND` - Success indicator (*ON = success, *OFF = failure)

**Validation:**
- Same as CreateBroker
- Broker ID must exist

**Error Codes:**
- `VAL006` - Required field missing
- `VAL005` - Invalid FSMA number
- `DB004` - Update failed

**Logic:**
1. Validate broker data
2. UPDATE all modifiable fields
3. Set UPDATED_AT to current timestamp
4. Return success indicator

---

### DeleteBroker

**Procedure:** `BROKRSRV_DeleteBroker` ([BROKRSRV.sqlrpgle:211](../src/qrpglesrc/BROKRSRV.sqlrpgle#L211))

Soft deletes a broker (sets status to inactive).

**Parameters:**
- `pBrokerId` (DECIMAL(10,0), const) - Broker ID

**Returns:**
- `IND` - Success indicator

**Error Codes:**
- `DB004` - Update failed

**Business Rule:**
Soft delete preserves audit trail and referential integrity with contracts. Broker is marked as 'INA' but data remains in database.

---

### ListBrokers

**Procedure:** `BROKRSRV_ListBrokers` ([BROKRSRV.sqlrpgle:244](../src/qrpglesrc/BROKRSRV.sqlrpgle#L244))

Searches brokers with filter criteria.

**Parameters:**
- `pFilter` (BrokerFilter_t, const) - Search filters

**Returns:**
- `INT(10)` - Count of matching brokers

**Filter Logic:**
- Empty filter fields are ignored (OR condition)
- Company name uses LIKE with trailing wildcard
- All other fields use exact match

**Note:** Current implementation returns count only. Typical enhancement would return result set via SQL cursor or array.

---

### IsValidBroker

**Procedure:** `BROKRSRV_IsValidBroker` ([BROKRSRV.sqlrpgle:274](../src/qrpglesrc/BROKRSRV.sqlrpgle#L274))

Validates broker data before insert/update.

**Parameters:**
- `pBroker` (Broker_t, const) - Broker to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**
1. brokerCode required (non-blank)
2. companyName required (non-blank)
3. fsmaNumber format (if provided)

**Error Codes:**
- `VAL006` - Required field missing
- `VAL005` - Invalid FSMA number (from IsValidFsmaNumber)

---

### IsValidFsmaNumber

**Procedure:** `BROKRSRV_IsValidFsmaNumber` ([BROKRSRV.sqlrpgle:304](../src/qrpglesrc/BROKRSRV.sqlrpgle#L304))

Validates FSMA registration number format.

**Parameters:**
- `pFsmaNumber` (CHAR(10), const) - FSMA number to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**
- Empty/blank is valid (optional field)
- Minimum length: 5 characters (trimmed)

**Error Codes:**
- `VAL005` - Invalid FSMA number format

**Business Context:**
FSMA (Financial Services and Markets Authority) is the Belgian regulator. All insurance brokers must be registered. Real-world implementation would validate against FSMA database or checksum algorithm.

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

| Code | Description | Context |
|------|-------------|---------|
| VAL005 | Invalid FSMA number | FSMA format validation |
| VAL006 | Required field missing | brokerCode or companyName blank |
| DB001 | Record not found | GetBroker/GetBrokerByCode (SQLCODE 100) |
| DB002 | Duplicate key | CreateBroker (SQLCODE -803) |
| DB004 | Database operation failed | Any SQL error |

### Error Recovery Strategy

**CreateBroker:**
- Returns 0 on error
- Caller should check ERRUTIL for details

**GetBroker/GetBrokerByCode:**
- Returns empty structure on error
- Check `brokerId = 0` to detect failure

**UpdateBroker/DeleteBroker:**
- Returns *OFF on error
- Caller should check ERRUTIL for details

---

## Database Operations

### Insert Pattern

```rpg
exec sql
    INSERT INTO BROKER (...) VALUES (...);

if sqlcode = 0;
    exec sql
        SELECT IDENTITY_VAL_LOCAL() INTO :newBrokerId
        FROM SYSIBM.SYSDUMMY1;
endif;
```

Uses `IDENTITY_VAL_LOCAL()` to retrieve auto-generated primary key from the current connection.

### Update Pattern

```rpg
exec sql
    UPDATE BROKER SET
        ...,
        UPDATED_AT = CURRENT_TIMESTAMP
    WHERE BROKER_ID = :pBroker.brokerId;

success = (sqlcode = 0);
```

Automatically updates timestamp on every modification.

### Dynamic WHERE Clause

```rpg
WHERE (:pFilter.brokerCode = '' OR BROKER_CODE = :pFilter.brokerCode)
  AND (:pFilter.companyName = '' OR COMPANY_NAME LIKE :pFilter.companyName || '%')
```

Empty filter fields are ignored, allowing flexible search combinations.

### Transaction Control

No explicit transaction control (COMMIT/ROLLBACK) in this module. Assumes caller manages transaction boundaries for multi-table operations.

---

## Usage Examples

### Creating a New Broker

```rpg
dcl-ds broker likeds(Broker_t) inz;
dcl-s brokerId packed(10:0);

broker.brokerCode = 'BRK001';
broker.companyName = 'Assurances Dupont SPRL';
broker.vatNumber = 'BE0123456789';
broker.fsmaNumber = '12345';
broker.street = 'Rue de la Loi';
broker.houseNbr = '16';
broker.postalCode = '1000';
broker.city = 'Bruxelles';
broker.countryCode = 'BEL';
broker.email = 'contact@dupont.be';
broker.contactName = 'Jean Dupont';

brokerId = CreateBroker(broker);

if brokerId > 0;
    // Success
else;
    // Check ERRUTIL for error details
endif;
```

### Retrieving a Broker

```rpg
dcl-ds broker likeds(Broker_t);
dcl-s brokerId packed(10:0);

brokerId = 1;
broker = GetBroker(brokerId);

if broker.brokerId > 0;
    // Broker found, use broker.companyName, etc.
else;
    // Not found or error
endif;
```

### Finding Broker by Code (TELEBIB2)

```rpg
dcl-ds broker likeds(Broker_t);

broker = GetBrokerByCode('BRK001');

if broker.brokerId > 0;
    // Found
endif;
```

### Updating Broker Contact

```rpg
dcl-ds broker likeds(Broker_t);
dcl-s success ind;

broker = GetBroker(1);
broker.email = 'newemail@dupont.be';
broker.phone = '+32 2 123 4567';

success = UpdateBroker(broker);
```

### Soft Deleting a Broker

```rpg
dcl-s success ind;

success = DeleteBroker(1);

if success;
    // Broker status set to 'INA'
endif;
```

### Searching Brokers

```rpg
dcl-ds filter likeds(BrokerFilter_t) inz;
dcl-s count int(10);

filter.city = 'Bruxelles';
filter.status = 'ACT';

count = ListBrokers(filter);

// count = number of active brokers in Brussels
```

---

## Development Notes

### Dependencies

**Internal:**
- `ERRUTIL.rpgle` - Error handling utility
- `BROKRSRV_H.rpgle` - Copybook (data structures and prototypes)

**External:**
- BROKER table (must exist in database)
- SQL environment configured

### Build Instructions

```bash
# Compile service module
CRTSQLRPGI OBJ(YOURLIB/BROKRSRV) SRCFILE(QRPGLESRC) COMMIT(*NONE) OBJTYPE(*MODULE)

# Create service program
CRTSRVPGM SRVPGM(YOURLIB/BROKRSRV) MODULE(YOURLIB/BROKRSRV) EXPORT(*ALL)
```

### Testing Considerations

**Unit Test Cases:**
1. CreateBroker with valid data
2. CreateBroker with missing required fields (VAL006)
3. CreateBroker with duplicate broker code (DB002)
4. GetBroker with valid/invalid ID
5. GetBrokerByCode with valid/invalid code
6. UpdateBroker with modified fields
7. DeleteBroker (verify status = 'INA')
8. ListBrokers with various filter combinations
9. IsValidFsmaNumber with edge cases

**Integration Tests:**
- TELEBIB2 EDI message processing
- Broker-to-Contract relationship
- Multi-broker searches with large datasets

### Future Enhancements

1. **ListBrokers result set:** Return actual broker records via cursor or array
2. **FSMA validation:** Connect to FSMA API for real-time validation
3. **VAT validation:** Belgian VAT checksum algorithm
4. **Pagination:** Add offset/limit to ListBrokers
5. **Full-text search:** COMPANY_NAME using QSYS2.SYSTEXTINDEX
6. **Audit logging:** Track all modifications with user/timestamp

### TELEBIB2 Integration Notes

**AgencyCode Mapping:**
- BROKER_CODE maps directly to TELEBIB2 AgencyCode element
- Used in policy and claim messages to identify the broker

**ADR Segment Alignment:**
Address fields use exact TELEBIB2 maximum lengths:
- X002 (street): 30 chars
- X003 (house number): 5 chars
- X004 (box): 4 chars
- X006 (postal code): 7 chars
- X007 (city): 24 chars
- X008 (country): 3 chars

This ensures seamless EDI integration without truncation.

---

## Version History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2025-12-05 | Claude | Initial implementation |

---

**Related Documentation:**
- [Implementation Plan](../implementation-plan.md)
- [BROKER Table DDL](../../sql/BROKER.sql)
- [ERRUTIL Module](ERRUTIL.md)

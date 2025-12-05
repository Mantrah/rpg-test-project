# CONTSRV - Contract Service Module

**Program:** `CONTSRV.sqlrpgle`
**Copybook:** `CONTSRV_H.rpgle`
**Target System:** IBM i V7R5
**Project:** DAS.be Backend - Legal Protection Insurance

---

## Overview

### Purpose

CONTSRV provides comprehensive contract (insurance policy) management for the DAS.be legal protection insurance system. The module orchestrates the relationship between brokers, customers, and products, implementing Belgian insurance contract rules including auto-renewal, cancellation periods, and premium calculation.

### Key Features

- **Complete policy lifecycle:** Creation, renewal, cancellation, expiration
- **Auto-renewal management:** Automatic policy renewal with 2-month opt-out window
- **Flexible premium calculation:** Base premium + vehicle addon + payment frequency adjustment
- **Reference number generation:** Unique policy numbers (DAS-YYYY-BBBBB-NNNNNN format)
- **Multi-entity relationships:** Links brokers, customers, and products
- **TELEBIB2 compliance:** BrokerPolicyReference field alignment
- **Payment flexibility:** Monthly, quarterly, annual payment options

### Business Context

**DAS Belgium Contract Rules:**
- **Duration:** 1 year policies
- **Auto-renewal:** Automatic renewal unless cancelled
- **Cancellation notice:** 2 months before expiration
- **Payment frequency:**
  - Annual (default, no surcharge)
  - Quarterly (+2% surcharge)
  - Monthly (+5% surcharge)
- **Distribution model:** All contracts sold through brokers

---

## Architecture

### Design Pattern

**Service Orchestration Pattern:**
- Coordinates BROKRSRV, CUSTSRV, PRODSRV
- Business rule enforcement
- Premium calculation delegation
- Lifecycle state machine (PEN → ACT → EXP/CAN/REN)

### Data Flow

```
API/Front-end
    ↓
CONTSRV_CreateContract
    ├→ IsValidContract (validation)
    ├→ GenerateContractRef (reference generation)
    ├→ CalculatePremium (PRODSRV integration)
    └→ INSERT CONTRACT
    ↓
Contract Created (ID returned)
```

**Renewal Flow:**
```
CONTSRV_CanRenewContract
    ├→ Check STATUS = 'ACT'
    ├→ Check AUTO_RENEW = 'Y'
    └→ Check within 60 days of expiry
    ↓
CONTSRV_RenewContract
    ├→ Copy old contract
    ├→ Generate new reference
    ├→ Set new dates (endDate → startDate, +1 year)
    └→ CREATE new contract
```

### Integration Points

- **BROKRSRV:** Broker validation and reference generation
- **CUSTSRV:** Customer lookup
- **PRODSRV:** Product lookup, premium calculation
- **CLAIMSRV:** Contract validation for claims
- **ERRUTIL:** Error handling
- **TELEBIB2:** BrokerPolicyReference EDI integration

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

**CONTRACT:** Insurance policies

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| CONT_ID | DECIMAL(10,0) | PK, identity column | - |
| CONT_REFERENCE | CHAR(20) | Unique policy number | BrokerPolicyReference |
| BROKER_ID | DECIMAL(10,0) | FK to BROKER | AgencyCode |
| CUST_ID | DECIMAL(10,0) | FK to CUSTOMER | - |
| PRODUCT_ID | DECIMAL(10,0) | FK to PRODUCT | - |
| START_DATE | DATE | Coverage start | - |
| END_DATE | DATE | Coverage end | - |
| PREMIUM_AMT | DECIMAL(9,2) | Annual premium (€) | - |
| PAY_FREQUENCY | CHAR(1) | M/Q/A | - |
| VEHICLES_COUNT | DECIMAL(2,0) | Number of vehicles | - |
| AUTO_RENEW | CHAR(1) | Y/N | - |
| STATUS | CHAR(3) | PEN/ACT/EXP/CAN/REN | - |
| CREATED_AT | TIMESTAMP | Record creation | - |
| UPDATED_AT | TIMESTAMP | Last update | - |

**Status Lifecycle:**
```
PEN (Pending) → ACT (Active) → EXP (Expired)
                           ↓
                         CAN (Cancelled)
                           ↓
                         REN (Renewal pending)
```

### Data Structures

**Contract_t** ([CONTSRV_H.rpgle:16](../src/qrpglesrc/CONTSRV_H.rpgle#L16))

Complete contract record structure.

```rpg
dcl-ds Contract_t qualified template;
    contId          packed(10:0);
    contReference   char(20);           // BrokerPolicyReference (TELEBIB2)
    // Foreign Keys
    brokerId        packed(10:0);
    custId          packed(10:0);
    productId       packed(10:0);
    // Coverage Period
    startDate       date;
    endDate         date;
    // Pricing
    premiumAmt      packed(9:2);        // Annual premium
    payFrequency    char(1);            // M/Q/A
    // Options
    vehiclesCount   packed(2:0);
    autoRenew       char(1);            // Y/N
    // Status
    status          char(3);            // PEN/ACT/EXP/CAN/REN
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;
```

**ContractFilter_t** ([CONTSRV_H.rpgle:41](../src/qrpglesrc/CONTSRV_H.rpgle#L41))

Search filter criteria for listing contracts.

```rpg
dcl-ds ContractFilter_t qualified template;
    brokerId        packed(10:0);
    custId          packed(10:0);
    productId       packed(10:0);
    status          char(3);
    startDateFrom   date;
    startDateTo     date;
end-ds;
```

### Constants

**Contract Status** ([CONTSRV_H.rpgle:53-57](../src/qrpglesrc/CONTSRV_H.rpgle#L53-L57))

| Constant | Value | Description |
|----------|-------|-------------|
| CONT_PENDING | PEN | Pending activation |
| CONT_ACTIVE | ACT | Active coverage |
| CONT_EXPIRED | EXP | Expired (not renewed) |
| CONT_CANCELLED | CAN | Cancelled by customer |
| CONT_RENEWAL | REN | Renewal in progress |

**Payment Frequency** ([CONTSRV_H.rpgle:62-64](../src/qrpglesrc/CONTSRV_H.rpgle#L62-L64))

| Constant | Value | Description | Surcharge |
|----------|-------|-------------|-----------|
| PAY_MONTHLY | M | Monthly payments | +5% |
| PAY_QUARTERLY | Q | Quarterly payments | +2% |
| PAY_ANNUAL | A | Annual payment | None |

---

## Procedures Reference

### CreateContract

**Procedure:** `CONTSRV_CreateContract` ([CONTSRV.sqlrpgle:24](../src/qrpglesrc/CONTSRV.sqlrpgle#L24))

Creates a new insurance contract.

**Parameters:**
- `pContract` (Contract_t, const) - Contract data to insert

**Returns:**
- `DECIMAL(10,0)` - New contract ID (0 on error)

**Validation:**
- Required: brokerId, custId, productId, startDate
- End date must be after start date (if provided)
- Payment frequency must be M/Q/A (defaults to A)

**Automatic Processing:**
1. Generates contract reference if not provided
2. Sets end date to startDate + 1 year if not provided
3. Sets status to 'ACT'

**Error Codes:**
- `VAL006` - Required field missing
- `VAL007` - End date before start date
- `DB002` - Duplicate contract reference (SQLCODE -803)
- `DB004` - Database operation failed

**Logic:**
1. Initialize error handler
2. Validate contract via IsValidContract
3. Generate reference if blank (GenerateContractRef)
4. Calculate end date if blank (startDate + 1 year)
5. Insert into CONTRACT table
6. Retrieve generated CONT_ID
7. Return new ID or 0 on error

---

### GetContract

**Procedure:** `CONTSRV_GetContract` ([CONTSRV.sqlrpgle:89](../src/qrpglesrc/CONTSRV.sqlrpgle#L89))

Retrieves contract by primary key.

**Parameters:**
- `pContId` (DECIMAL(10,0), const) - Contract ID

**Returns:**
- `Contract_t` - Contract data structure (empty on error)

**Error Codes:**
- `DB001` - Contract not found (SQLCODE 100)
- `DB004` - Database operation failed

---

### GetContractByRef

**Procedure:** `CONTSRV_GetContractByRef` ([CONTSRV.sqlrpgle:129](../src/qrpglesrc/CONTSRV.sqlrpgle#L129))

Retrieves contract by policy number (alternative key).

**Parameters:**
- `pContReference` (CHAR(20), const) - Contract reference

**Returns:**
- `Contract_t` - Contract data structure (empty on error)

**Use Case:**
Primary lookup for TELEBIB2 integration and broker portals where policy number is the main identifier.

---

### UpdateContract

**Procedure:** `CONTSRV_UpdateContract` ([CONTSRV.sqlrpgle:164](../src/qrpglesrc/CONTSRV.sqlrpgle#L164))

Updates existing contract information.

**Parameters:**
- `pContract` (Contract_t, const) - Contract data with ID

**Returns:**
- `IND` - Success indicator (*ON = success, *OFF = failure)

**Validation:**
- Same as CreateContract
- Contract ID must exist

**Error Codes:**
- (Same as CreateContract)
- `DB004` - Update failed

**Business Rule:**
Allows modification of all fields including status. For standard cancellation, use CancelContract instead.

---

### CancelContract

**Procedure:** `CONTSRV_CancelContract` ([CONTSRV.sqlrpgle:215](../src/qrpglesrc/CONTSRV.sqlrpgle#L215))

Cancels an active contract (sets status to cancelled).

**Parameters:**
- `pContId` (DECIMAL(10,0), const) - Contract ID

**Returns:**
- `IND` - Success indicator

**Error Codes:**
- `DB004` - Update failed

**Business Rule:**
Sets status to 'CAN'. Belgian insurance law requires 2-month notice before expiration for cancellation to be valid. This procedure does not enforce that rule (caller responsibility).

---

### ListContracts

**Procedure:** `CONTSRV_ListContracts` ([CONTSRV.sqlrpgle:248](../src/qrpglesrc/CONTSRV.sqlrpgle#L248))

Searches contracts with filter criteria.

**Parameters:**
- `pFilter` (ContractFilter_t, const) - Search filters

**Returns:**
- `INT(10)` - Count of matching contracts

**Filter Logic:**
- Numeric filter fields: 0 = ignore (OR condition)
- String filter fields: blank = ignore
- All filters use exact match

**Note:** Current implementation returns count only. Enhancement would return result set.

---

### GetCustomerContracts

**Procedure:** `CONTSRV_GetCustomerContracts` ([CONTSRV.sqlrpgle:278](../src/qrpglesrc/CONTSRV.sqlrpgle#L278))

Gets count of contracts for a specific customer.

**Parameters:**
- `pCustId` (DECIMAL(10,0), const) - Customer ID

**Returns:**
- `INT(10)` - Count of contracts (all statuses)

**Use Case:**
Customer service portal - show customer's policy history.

---

### GetBrokerContracts

**Procedure:** `CONTSRV_GetBrokerContracts` ([CONTSRV.sqlrpgle:305](../src/qrpglesrc/CONTSRV.sqlrpgle#L305))

Gets count of contracts for a specific broker.

**Parameters:**
- `pBrokerId` (DECIMAL(10,0), const) - Broker ID

**Returns:**
- `INT(10)` - Count of contracts (all statuses)

**Use Case:**
Broker portal - show broker's portfolio size.

---

### IsValidContract

**Procedure:** `CONTSRV_IsValidContract` ([CONTSRV.sqlrpgle:332](../src/qrpglesrc/CONTSRV.sqlrpgle#L332))

Validates contract data before insert/update.

**Parameters:**
- `pContract` (Contract_t, const) - Contract to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**
1. brokerId required (> 0)
2. custId required (> 0)
3. productId required (> 0)
4. startDate required (not *loval)
5. endDate must be after startDate (if provided)
6. payFrequency must be M/Q/A (defaults to A if invalid)

**Error Codes:**
- `VAL006` - Required field missing
- `VAL007` - End date before start date

**Design Note:**
Modifies pContract.payFrequency to 'A' if invalid (defensive programming).

---

### CalculatePremium

**Procedure:** `CONTSRV_CalculatePremium` ([CONTSRV.sqlrpgle:380](../src/qrpglesrc/CONTSRV.sqlrpgle#L380))

Calculates total premium including all adjustments.

**Parameters:**
- `pProductCode` (CHAR(10), const) - Product code
- `pVehiclesCount` (DECIMAL(2,0), const) - Number of vehicles
- `pPayFrequency` (CHAR(1), const) - Payment frequency (M/Q/A)

**Returns:**
- `DECIMAL(9,2)` - Calculated premium amount (€)

**Calculation Formula:**

**Step 1 - Base Premium:**
```rpg
basePremium = PRODSRV_CalculateBasePremium(productCode, vehiclesCount)
// Example: €114 (DAS Classic) + 2 × €25 = €164
```

**Step 2 - Payment Frequency Adjustment:**
```rpg
multiplier = 1.00  // Annual (default)
multiplier = 1.02  // Quarterly (+2%)
multiplier = 1.05  // Monthly (+5%)

totalPremium = basePremium × multiplier
```

**Examples:**
```
DAS Classic (€114) + 0 vehicles, Annual:
  = €114 × 1.00 = €114

DAS Classic (€114) + 2 vehicles, Monthly:
  = (€114 + €50) × 1.05 = €172.20

DAS Comfort (€396) + 3 vehicles, Quarterly:
  = (€396 + €75) × 1.02 = €480.42
```

**Business Context:**
Payment frequency surcharge compensates for administrative overhead and cash flow timing.

---

### CanRenewContract

**Procedure:** `CONTSRV_CanRenewContract` ([CONTSRV.sqlrpgle:414](../src/qrpglesrc/CONTSRV.sqlrpgle#L414))

Checks if contract is eligible for renewal.

**Parameters:**
- `pContId` (DECIMAL(10,0), const) - Contract ID

**Returns:**
- `IND` - Can renew indicator (*ON = eligible, *OFF = not eligible)

**Eligibility Rules:**

**1. Contract must be active:**
```rpg
if contract.status <> 'ACT';
    ERRUTIL_addErrorCode('BUS003');
    return *off;
endif;
```

**2. Auto-renewal must be enabled:**
```rpg
if contract.autoRenew = 'N';
    ERRUTIL_addErrorCode('BUS008');
    return *off;
endif;
```

**3. Must be within 60 days of expiry:**
```rpg
daysToExpiry = %diff(contract.endDate: %date(): *days);
if daysToExpiry > 60;
    return *off;  // Too early
endif;
```

**Error Codes:**
- `BUS003` - Contract not active
- `BUS008` - Auto-renewal disabled

**Business Rule:**
Belgian insurance law allows 2-month cancellation window. System processes renewals within same window (60 days).

---

### RenewContract

**Procedure:** `CONTSRV_RenewContract` ([CONTSRV.sqlrpgle:450](../src/qrpglesrc/CONTSRV.sqlrpgle#L450))

Creates a renewal contract based on existing contract.

**Parameters:**
- `pContId` (DECIMAL(10,0), const) - Existing contract ID

**Returns:**
- `DECIMAL(10,0)` - New contract ID (0 on error)

**Logic:**

**1. Validate eligibility:**
```rpg
if not CanRenewContract(pContId);
    return 0;
endif;
```

**2. Copy old contract:**
```rpg
oldContract = GetContract(pContId);
newContract = oldContract;
```

**3. Modify for renewal:**
```rpg
newContract.contId = 0;  // New ID will be generated
newContract.contReference = GenerateContractRef(oldContract.brokerId);
newContract.startDate = oldContract.endDate;  // Seamless continuation
newContract.endDate = newContract.startDate + %years(1);
newContract.status = 'ACT';
```

**4. Create new contract:**
```rpg
return CreateContract(newContract);
```

**Business Rule:**
New contract starts exactly when old contract ends - no coverage gap.

---

### IsContractActive

**Procedure:** `CONTSRV_IsContractActive` ([CONTSRV.sqlrpgle:482](../src/qrpglesrc/CONTSRV.sqlrpgle#L482))

Checks if contract is currently active (status + date range).

**Parameters:**
- `pContId` (DECIMAL(10,0), const) - Contract ID

**Returns:**
- `IND` - Active indicator (*ON = active, *OFF = inactive)

**Active Criteria:**
```rpg
return (status = 'ACT' and
        today >= startDate and
        today <= endDate);
```

**Use Case:**
Claim validation - ensure customer has active coverage at time of incident.

---

### GenerateContractRef

**Procedure:** `CONTSRV_GenerateContractRef` ([CONTSRV.sqlrpgle:519](../src/qrpglesrc/CONTSRV.sqlrpgle#L519))

Generates unique policy number.

**Parameters:**
- `pBrokerId` (DECIMAL(10,0), const) - Broker ID

**Returns:**
- `CHAR(20)` - Generated reference string

**Format:**
```
DAS-YYYY-BBBBB-NNNNNN

DAS    = Company prefix
YYYY   = Current year
BBBBB  = Broker ID (5 digits, zero-padded)
NNNNNN = Sequence number (auto-increment)
```

**Algorithm:**
```rpg
year = %char(%subdt(%date(): *years));  // "2025"
broker = %editc(pBrokerId: 'X');        // "00001"
sequence = MAX(CONT_ID) + 1;            // Next sequence

reference = 'DAS-' + year + '-' + broker + '-' + sequence;
```

**Examples:**
```
DAS-2025-00001-000001  // First contract for broker 1
DAS-2025-00042-000123  // 123rd contract for broker 42
DAS-2025-00001-000002  // Second contract for broker 1 (renewal)
```

**Fallback:**
If sequence query fails, uses timestamp as sequence (guaranteed unique).

---

## Error Handling

### ERRUTIL Integration

All procedures use ERRUTIL for error management:

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
| VAL006 | Required field missing | IsValidContract |
| VAL007 | End date before start date | IsValidContract |
| DB001 | Contract not found | GetContract (SQLCODE 100) |
| DB002 | Duplicate reference | CreateContract (SQLCODE -803) |
| DB004 | Database operation failed | Any SQL error |
| BUS003 | Contract not active | CanRenewContract |
| BUS008 | Auto-renewal disabled | CanRenewContract |

### Error Recovery Strategy

**CreateContract:**
- Returns 0 on error
- Check ERRUTIL for validation/database errors

**GetContract/GetContractByRef:**
- Returns empty structure on error
- Check `contId = 0` to detect failure

**UpdateContract/CancelContract:**
- Returns *OFF on error
- Check ERRUTIL for details

**RenewContract:**
- Returns 0 on error
- Error codes from CanRenewContract propagate

---

## Database Operations

### Insert Pattern with Defaults

```rpg
// Auto-generate reference if blank
if contract.contReference = '';
    contract.contReference = GenerateContractRef(contract.brokerId);
endif;

// Auto-set end date if blank
if contract.endDate = *loval;
    contract.endDate = contract.startDate + %years(1);
endif;

exec sql INSERT INTO CONTRACT (...) VALUES (...);
```

### Date Arithmetic

```rpg
// Add 1 year
endDate = startDate + %years(1);

// Calculate days difference
daysToExpiry = %diff(endDate: %date(): *days);

// Check date range
active = (today >= startDate and today <= endDate);
```

### Dynamic WHERE Clause

```rpg
WHERE (:pFilter.brokerId = 0 OR BROKER_ID = :pFilter.brokerId)
  AND (:pFilter.custId = 0 OR CUST_ID = :pFilter.custId)
```

Zero values ignored in numeric filters.

---

## Usage Examples

### Creating a New Contract

```rpg
dcl-ds contract likeds(Contract_t) inz;
dcl-s contId packed(10:0);

// Customer selected DAS Classic, monthly payment, 2 vehicles
contract.brokerId = 1;
contract.custId = 42;
contract.productId = 1;  // DAS Classic
contract.startDate = %date();
contract.vehiclesCount = 2;
contract.payFrequency = PAY_MONTHLY;
contract.autoRenew = 'Y';

// Calculate premium before creating
contract.premiumAmt = CalculatePremium(PROD_CLASSIC: 2: PAY_MONTHLY);
// Returns €172.20 (€114 + €50 + 5%)

contId = CreateContract(contract);

if contId > 0;
    dsply ('Contract created: ' + contract.contReference);
    // Displays: "Contract created: DAS-2025-00001-000001"
endif;
```

### Retrieving Contract by Policy Number

```rpg
dcl-ds contract likeds(Contract_t);
dcl-s policyNumber char(20);

policyNumber = 'DAS-2025-00001-000001';
contract = GetContractByRef(policyNumber);

if contract.contId > 0;
    // Found - use contract data
    dsply ('Customer: ' + %char(contract.custId));
    dsply ('Premium: €' + %char(contract.premiumAmt));
endif;
```

### Renewing a Contract

```rpg
dcl-s oldContId packed(10:0);
dcl-s newContId packed(10:0);
dcl-s canRenew ind;

oldContId = 123;

// Check eligibility
canRenew = CanRenewContract(oldContId);

if canRenew;
    // Create renewal
    newContId = RenewContract(oldContId);

    if newContId > 0;
        dsply ('Renewal created: ' + %char(newContId));
    endif;
else;
    // Check error codes: BUS003 or BUS008
endif;
```

### Cancelling a Contract

```rpg
dcl-s contId packed(10:0);
dcl-s success ind;

contId = 123;
success = CancelContract(contId);

if success;
    dsply ('Contract cancelled');
endif;
```

### Finding All Customer Contracts

```rpg
dcl-s custId packed(10:0);
dcl-s count int(10);

custId = 42;
count = GetCustomerContracts(custId);

dsply ('Customer has ' + %char(count) + ' contracts');
```

### Searching Contracts by Status

```rpg
dcl-ds filter likeds(ContractFilter_t) inz;
dcl-s count int(10);

// Find all active contracts for broker 1
filter.brokerId = 1;
filter.status = CONT_ACTIVE;

count = ListContracts(filter);

dsply ('Active contracts: ' + %char(count));
```

### Checking if Contract is Active

```rpg
dcl-s contId packed(10:0);
dcl-s isActive ind;

contId = 123;
isActive = IsContractActive(contId);

if isActive;
    // Proceed with claim processing
else;
    // Reject: "No active coverage"
endif;
```

---

## Business Logic Details

### Contract Lifecycle

```
1. Creation (Status = ACT)
   ↓
2. Active Period (startDate to endDate)
   ↓
3a. Expiration (Status = EXP) - if autoRenew = 'N'
3b. Renewal (create new contract) - if autoRenew = 'Y'
3c. Cancellation (Status = CAN) - customer request
```

### Auto-Renewal Process

**60 Days Before Expiry:**
- System checks CanRenewContract
- If eligible, sends renewal notice to customer
- Customer has 60 days to opt-out (Belgian law: 2 months)

**30 Days Before Expiry:**
- Final reminder sent
- Customer can still cancel

**Expiry Date:**
- If not cancelled, RenewContract executes
- New contract starts seamlessly (no gap)
- Old contract marked as EXP (historical record)

### Payment Frequency Economics

**Annual Payment (default):**
- Full premium paid upfront
- Best cash flow for DAS
- No surcharge

**Quarterly Payment (+2%):**
- 4 payments per year
- Moderate administrative cost
- Small surcharge

**Monthly Payment (+5%):**
- 12 payments per year
- Highest administrative cost
- Payment processing fees
- Higher surcharge

### Premium Calculation Deep Dive

**Components:**
1. **Product base premium:** €114-€756 (from PRODUCT table)
2. **Vehicle addon:** €25 per vehicle
3. **Payment frequency multiplier:** 1.00 / 1.02 / 1.05

**Formula:**
```
totalPremium = (basePremium + (vehicles × €25)) × multiplier
```

**Example - DAS Benefisc Family:**
```
Product: CONFLIT_BF
Base premium: €539
Vehicles: 3
Payment: Monthly

Calculation:
  Base: €539
  Vehicles: 3 × €25 = €75
  Subtotal: €539 + €75 = €614
  Monthly surcharge: €614 × 1.05 = €644.70

Annual premium: €644.70
Monthly payment: €644.70 ÷ 12 = €53.73
```

### Contract Reference Number System

**Format Rationale:**

**DAS-** prefix
- Company branding
- Distinguishes from broker's own policy numbers

**YYYY** year
- Easy to sort/filter by year
- Helps with archival

**BBBBB** broker ID
- Broker can identify their contracts
- Supports broker portal filtering

**NNNNNN** sequence
- Globally unique across all brokers
- Simple auto-increment

**Alternative Design Considerations:**
- Per-broker sequence (DAS-2025-00001-00001) - better for high-volume brokers
- Check digit suffix (DAS-2025-00001-000001-7) - reduces typos
- Product type indicator (DAS-IND-2025-...) - easier reporting

---

## Development Notes

### Dependencies

**Internal:**
- `ERRUTIL.rpgle` - Error handling utility
- `CONTSRV_H.rpgle` - Copybook (data structures, prototypes, constants)
- `PRODSRV_H.rpgle` - Product service copybook (imported for CalculateBasePremium)

**External:**
- CONTRACT table (must exist in database)
- BROKER table (FK relationship)
- CUSTOMER table (FK relationship)
- PRODUCT table (FK relationship)
- SQL environment configured

### Build Instructions

```bash
# Compile service module
CRTSQLRPGI OBJ(YOURLIB/CONTSRV) SRCFILE(QRPGLESRC) COMMIT(*NONE) OBJTYPE(*MODULE)

# Create service program with PRODSRV binding
CRTSRVPGM SRVPGM(YOURLIB/CONTSRV) MODULE(YOURLIB/CONTSRV) EXPORT(*ALL) BNDSRVPGM(PRODSRV)
```

**Important:** CONTSRV calls PRODSRV_CalculateBasePremium, so PRODSRV service program must be available at bind time.

### Testing Considerations

**Unit Test Cases:**

**Basic CRUD:**
1. CreateContract with all fields
2. CreateContract with auto-generated reference
3. CreateContract with auto-calculated end date
4. CreateContract with missing required fields (VAL006)
5. CreateContract with invalid dates (VAL007)
6. GetContract with valid/invalid ID
7. GetContractByRef with valid/invalid reference
8. UpdateContract modify fields
9. CancelContract

**Premium Calculation:**
10. CalculatePremium - annual payment
11. CalculatePremium - quarterly payment (+2%)
12. CalculatePremium - monthly payment (+5%)
13. CalculatePremium with 0 vehicles
14. CalculatePremium with multiple vehicles

**Renewal:**
15. CanRenewContract - eligible contract
16. CanRenewContract - not active (BUS003)
17. CanRenewContract - auto-renewal disabled (BUS008)
18. CanRenewContract - too early (> 60 days)
19. RenewContract - successful renewal
20. Verify new contract dates (seamless continuation)

**Status Checks:**
21. IsContractActive - within date range
22. IsContractActive - before start date
23. IsContractActive - after end date
24. IsContractActive - cancelled status

**Reference Generation:**
25. GenerateContractRef - unique references
26. GenerateContractRef - year component
27. GenerateContractRef - broker ID component

**Integration Tests:**
- Full contract creation flow (broker → customer → product → contract)
- Renewal cycle (create → renew → verify continuity)
- Claim validation (contract must be active)
- Broker portal contract listing
- Customer portal contract history

### Future Enhancements

1. **Result set returns:** ListContracts/GetCustomerContracts return actual contract arrays
2. **Advanced renewal:**
   - Automated renewal processing (batch job)
   - Email notifications at 60/30/7 days
   - Opt-out mechanism (customer portal)
3. **Premium adjustments:**
   - Mid-term endorsements (add vehicle)
   - Pro-rata calculations
   - Multi-policy discounts
4. **Payment integration:**
   - Payment schedule generation
   - Payment tracking
   - Overdue handling
5. **Compliance:**
   - Cancellation notice enforcement (must be >= 60 days)
   - Regulatory reporting
   - Audit trail
6. **Performance:**
   - Contract search with pagination
   - Full-text search on policy numbers
   - Expiring contracts report (batch processing)

### Performance Considerations

**Indexes Required:**
- CONTRACT.CONT_REFERENCE (unique) - fast lookup
- CONTRACT.BROKER_ID - broker portal
- CONTRACT.CUST_ID - customer portal
- CONTRACT.STATUS - active contract queries
- CONTRACT.END_DATE - renewal processing

**Renewal Batch Job:**
For production, create scheduled job to:
1. Find contracts expiring in 60 days with autoRenew = 'Y'
2. Call RenewContract for each
3. Send confirmation emails
4. Log results

---

## Version History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2025-12-05 | Claude | Initial implementation |

---

**Related Documentation:**
- [Implementation Plan](../implementation-plan.md)
- [CONTRACT Table DDL](../../sql/CONTRACT.sql)
- [BROKRSRV Module](BROKRSRV.md) - Broker service
- [CUSTSRV Module](CUSTSRV.md) - Customer service
- [PRODSRV Module](PRODSRV.md) - Product service
- [CLAIMSRV Module](CLAIMSRV.md) - Claim service (uses contracts)

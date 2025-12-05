# CLAIMSRV - Claim Service Module

**Program:** `CLAIMSRV.sqlrpgle`
**Copybook:** `CLAIMSRV_H.rpgle`
**Target System:** IBM i V7R5
**Project:** DAS.be Backend - Legal Protection Insurance

---

## Overview

### Purpose

CLAIMSRV provides comprehensive claim (sinistre) management for the DAS.be legal protection insurance system. The module handles the complete claim lifecycle from declaration through resolution, enforcing Belgian legal protection insurance business rules including waiting periods, coverage validation, and amicable settlement processes.

### Key Features

- **Complete claim lifecycle:** Declaration → Assignment → Resolution → Closure
- **Coverage validation:** Automatic verification against product guarantees
- **Waiting period enforcement:** Date-based eligibility checking
- **Minimum threshold:** €350 intervention threshold
- **Amicable resolution tracking:** 79% of DAS claims resolved without court
- **Lawyer assignment:** Free choice of legal counsel
- **TELEBIB2 compliance:** ClaimReference, ClaimFileReference, ClaimAmount, ClaimCircumstancesCode, CoverageCode
- **Multi-level validation:** Contract, coverage, waiting period, amount limits

### Business Context

**DAS Belgium Claims Philosophy:**

**"79% Amicable Resolution":**
- DAS resolves 79% of cases through negotiation (no court)
- "Wij helpen u" - "We help you" approach
- Internal legal team provides advice before litigation

**Claims Handling:**
- Service Box: Preventive legal advice, document review
- Free choice of lawyer for customer
- Maximum coverage: €200,000
- Minimum intervention: €350
- Waiting periods: 0-12 months depending on coverage type

---

## Architecture

### Design Pattern

**Multi-Layer Validation Pattern:**
- Contract validation (CONTSRV integration)
- Coverage validation (PRODSRV integration)
- Business rule enforcement (waiting period, threshold)
- Resolution workflow state machine

### Data Flow

```
Customer submits claim
    ↓
CLAIMSRV_CreateClaim
    ├→ IsValidClaim (required fields + contract active)
    ├→ IsCovered (product has guarantee)
    ├→ IsInWaitingPeriod (incident date vs contract start + waiting)
    ├→ Check MIN_CLAIM_THRESHOLD (€350)
    ├→ GenerateClaimRef (SIN-YYYY-NNNNNN)
    └→ INSERT CLAIM (status = 'NEW')
    ↓
CLAIMSRV_AssignLawyer
    └→ UPDATE (status = 'PRO')
    ↓
CLAIMSRV_ResolveClaim
    ├→ Validate resolution type (AMI/LIT/REJ)
    ├→ Validate approved amount vs coverage limit
    └→ UPDATE (status = 'RES')
```

### Integration Points

- **CONTSRV:** Contract validation (IsContractActive)
- **PRODSRV:** Coverage validation (HasGuarantee, GetGuaranteeWaitingPeriod)
- **ERRUTIL:** Error handling
- **TELEBIB2:** Claim reference, file reference, circumstance codes, coverage codes

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

**CLAIM:** Legal protection claims (sinistres)

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| CLAIM_ID | DECIMAL(10,0) | PK, identity column | - |
| CLAIM_REFERENCE | CHAR(20) | Unique claim number | ClaimReference |
| FILE_REFERENCE | CHAR(20) | Dossier number | ClaimFileReference |
| CONT_ID | DECIMAL(10,0) | FK to CONTRACT | - |
| GUARANTEE_CODE | CHAR(10) | Coverage type | CoverageCode |
| CIRCUMSTANCE_CODE | CHAR(10) | Claim type | ClaimCircumstancesCode |
| DECLARATION_DATE | DATE | Declaration date | - |
| INCIDENT_DATE | DATE | Incident date | - |
| DESCRIPTION | VARCHAR(500) | Claim description | - |
| CLAIMED_AMOUNT | DECIMAL(11,2) | Amount claimed (€) | ClaimAmount |
| APPROVED_AMOUNT | DECIMAL(11,2) | Amount approved (€) | - |
| RESOLUTION_TYPE | CHAR(3) | AMI/LIT/REJ | - |
| LAWYER_NAME | VARCHAR(100) | Assigned lawyer | - |
| STATUS | CHAR(3) | NEW/PRO/RES/CLO/REJ | - |
| CREATED_AT | TIMESTAMP | Record creation | - |
| UPDATED_AT | TIMESTAMP | Last update | - |

**Status Lifecycle:**
```
NEW (New claim)
  ↓
PRO (In progress - lawyer assigned)
  ↓
RES (Resolved)
  ↓
CLO (Closed)

Alternative path:
NEW → REJ (Rejected - not covered or in waiting period)
```

### Data Structures

**Claim_t** ([CLAIMSRV_H.rpgle:18](../src/qrpglesrc/CLAIMSRV_H.rpgle#L18))

Complete claim record structure.

```rpg
dcl-ds Claim_t qualified template;
    claimId         packed(10:0);
    claimReference  char(20);           // ClaimReference (TELEBIB2)
    fileReference   char(20);           // ClaimFileReference (TELEBIB2)
    // Foreign Key
    contId          packed(10:0);
    // Classification (TELEBIB2)
    guaranteeCode   char(10);           // CoverageCode
    circumstanceCode char(10);          // ClaimCircumstancesCode
    // Dates
    declarationDate date;
    incidentDate    date;
    // Details
    description     varchar(500);
    // Amounts (TELEBIB2: ClaimAmount)
    claimedAmount   packed(11:2);
    approvedAmount  packed(11:2);
    // Resolution
    resolutionType  char(3);            // AMI/LIT/REJ
    lawyerName      varchar(100);
    // Status
    status          char(3);            // NEW/PRO/RES/CLO/REJ
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;
```

**ClaimFilter_t** ([CLAIMSRV_H.rpgle:47](../src/qrpglesrc/CLAIMSRV_H.rpgle#L47))

Search filter criteria for listing claims.

```rpg
dcl-ds ClaimFilter_t qualified template;
    contId          packed(10:0);
    guaranteeCode   char(10);
    circumstanceCode char(10);
    status          char(3);
    declarationDateFrom date;
    declarationDateTo date;
end-ds;
```

### Constants

**Claim Status** ([CLAIMSRV_H.rpgle:59-63](../src/qrpglesrc/CLAIMSRV_H.rpgle#L59-L63))

| Constant | Value | Description |
|----------|-------|-------------|
| CLAIM_NEW | NEW | New claim submitted |
| CLAIM_IN_PROGRESS | PRO | In progress (lawyer assigned) |
| CLAIM_RESOLVED | RES | Resolved (outcome determined) |
| CLAIM_CLOSED | CLO | Closed (file complete) |
| CLAIM_REJECTED | REJ | Rejected (not covered/waiting) |

**Resolution Type** ([CLAIMSRV_H.rpgle:68-70](../src/qrpglesrc/CLAIMSRV_H.rpgle#L68-L70))

| Constant | Value | Description | DAS Rate |
|----------|-------|-------------|----------|
| RESOL_AMICABLE | AMI | Amicable settlement | **79%** |
| RESOL_LITIGATION | LIT | Litigation/court | 21% |
| RESOL_REJECTED | REJ | Rejected claim | N/A |

**Circumstance Codes** ([CLAIMSRV_H.rpgle:75-82](../src/qrpglesrc/CLAIMSRV_H.rpgle#L75-L82))

TELEBIB2 ClaimCircumstancesCode values.

| Constant | Value | Description |
|----------|-------|-------------|
| CIRCUM_CONTRACT | CONTR_DISP | Contract dispute |
| CIRCUM_EMPLOYMENT | EMPL_DISP | Employment dispute |
| CIRCUM_NEIGHBOR | NEIGH_DISP | Neighborhood dispute |
| CIRCUM_TAX | TAX_DISP | Tax dispute |
| CIRCUM_MEDICAL | MED_MALPR | Medical malpractice |
| CIRCUM_CRIMINAL | CRIM_DEF | Criminal defense |
| CIRCUM_FAMILY | FAM_DISP | Family dispute |
| CIRCUM_ADMIN | ADMIN_DISP | Administrative dispute |

**Business Rules** ([CLAIMSRV_H.rpgle:87](../src/qrpglesrc/CLAIMSRV_H.rpgle#L87))

| Constant | Value | Description |
|----------|-------|-------------|
| MIN_CLAIM_THRESHOLD | 350 | Minimum intervention threshold (€350) |

---

## Procedures Reference

### CreateClaim

**Procedure:** `CLAIMSRV_CreateClaim` ([CLAIMSRV.sqlrpgle:28](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L28))

Creates a new claim with comprehensive validation.

**Parameters:**
- `pClaim` (Claim_t, const) - Claim data to insert

**Returns:**
- `DECIMAL(10,0)` - New claim ID (0 on error)

**Validation Steps:**

**1. Required Fields:**
```rpg
if not IsValidClaim(claim);
    return 0;
endif;
```
Validates: contId, guaranteeCode, circumstanceCode, declarationDate, contract active.

**2. Coverage Validation:**
```rpg
if not IsCovered(claim.contId: claim.guaranteeCode);
    ERRUTIL_addErrorCode('BUS005');
    return 0;
endif;
```
Verifies product includes the requested guarantee.

**3. Waiting Period Check:**
```rpg
if IsInWaitingPeriod(claim.contId: claim.guaranteeCode: claim.incidentDate);
    ERRUTIL_addErrorCode('BUS004');
    return 0;
endif;
```
Ensures incident occurred after waiting period ended.

**4. Minimum Threshold:**
```rpg
if claim.claimedAmount < MIN_CLAIM_THRESHOLD;  // €350
    ERRUTIL_addErrorCode('BUS006');
    return 0;
endif;
```

**Automatic Processing:**
1. Generates claim reference if not provided (SIN-YYYY-NNNNNN)
2. Generates file reference after insert (DOS-NNNNNNNNNN)
3. Sets status to 'NEW'

**Error Codes:**
- `VAL006` - Required field missing
- `BUS003` - Contract not active
- `BUS004` - Incident during waiting period
- `BUS005` - Not covered by product
- `BUS006` - Amount below minimum threshold (€350)
- `DB002` - Duplicate claim reference (SQLCODE -803)
- `DB004` - Database operation failed

---

### GetClaim

**Procedure:** `CLAIMSRV_GetClaim` ([CLAIMSRV.sqlrpgle:116](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L116))

Retrieves claim by primary key.

**Parameters:**
- `pClaimId` (DECIMAL(10,0), const) - Claim ID

**Returns:**
- `Claim_t` - Claim data structure (empty on error)

**Error Codes:**
- `DB001` - Claim not found (SQLCODE 100)
- `DB004` - Database operation failed

---

### GetClaimByRef

**Procedure:** `CLAIMSRV_GetClaimByRef` ([CLAIMSRV.sqlrpgle:157](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L157))

Retrieves claim by claim reference (alternative key).

**Parameters:**
- `pClaimReference` (CHAR(20), const) - Claim reference

**Returns:**
- `Claim_t` - Claim data structure (empty on error)

**Use Case:**
Customer calls with claim number (SIN-2025-000123) to check status.

---

### UpdateClaim

**Procedure:** `CLAIMSRV_UpdateClaim` ([CLAIMSRV.sqlrpgle:193](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L193))

Updates existing claim information.

**Parameters:**
- `pClaim` (Claim_t, const) - Claim data with ID

**Returns:**
- `IND` - Success indicator (*ON = success, *OFF = failure)

**Validation:**
- Same as CreateClaim
- Claim ID must exist

**Business Note:**
For standard operations (assign lawyer, resolve claim), use specific procedures instead of direct update.

---

### ListClaims

**Procedure:** `CLAIMSRV_ListClaims` ([CLAIMSRV.sqlrpgle:245](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L245))

Searches claims with filter criteria.

**Parameters:**
- `pFilter` (ClaimFilter_t, const) - Search filters

**Returns:**
- `INT(10)` - Count of matching claims

**Filter Logic:**
- contId: 0 = ignore
- String fields: blank = ignore
- All filters use exact match

---

### GetContractClaims

**Procedure:** `CLAIMSRV_GetContractClaims` ([CLAIMSRV.sqlrpgle:275](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L275))

Gets count of claims for a specific contract.

**Parameters:**
- `pContId` (DECIMAL(10,0), const) - Contract ID

**Returns:**
- `INT(10)` - Count of claims (all statuses)

**Use Case:**
Customer portal - show claim history for policy.

---

### IsValidClaim

**Procedure:** `CLAIMSRV_IsValidClaim` ([CLAIMSRV.sqlrpgle:302](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L302))

Validates claim data before insert/update.

**Parameters:**
- `pClaim` (Claim_t, const) - Claim to validate

**Returns:**
- `IND` - Valid indicator

**Validation Rules:**
1. contId required (> 0)
2. guaranteeCode required (non-blank)
3. circumstanceCode required (non-blank)
4. declarationDate required (not *loval)
5. Contract must be active (calls CONTSRV_IsContractActive)

**Error Codes:**
- `VAL006` - Required field missing
- `BUS003` - Contract not active

**Design Note:**
Integrates with CONTSRV for contract validation - enforces cross-module business rules.

---

### IsCovered

**Procedure:** `CLAIMSRV_IsCovered` ([CLAIMSRV.sqlrpgle:343](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L343))

Checks if contract's product includes the requested guarantee.

**Parameters:**
- `pContId` (DECIMAL(10,0), const) - Contract ID
- `pGuaranteeCode` (CHAR(10), const) - Guarantee code

**Returns:**
- `IND` - Covered indicator (*ON = covered, *OFF = not covered)

**Logic:**
```rpg
// Get product from contract
SELECT PRODUCT_ID FROM CONTRACT WHERE CONT_ID = :contId;

// Check if product has guarantee
return PRODSRV_HasGuarantee(productId: guaranteeCode);
```

**Example:**
```rpg
// Can DAS Classic customer claim for family law?
isCovered = IsCovered(contractId: GUAR_FAMILY);
// Returns *OFF (family law only in Benefisc)
```

---

### IsInWaitingPeriod

**Procedure:** `CLAIMSRV_IsInWaitingPeriod` ([CLAIMSRV.sqlrpgle:375](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L375))

Checks if incident occurred during waiting period.

**Parameters:**
- `pContId` (DECIMAL(10,0), const) - Contract ID
- `pGuaranteeCode` (CHAR(10), const) - Guarantee code
- `pIncidentDate` (DATE, const) - Incident date

**Returns:**
- `IND` - In waiting period indicator (*ON = incident too early, *OFF = eligible)

**Logic:**
```rpg
// Get contract start date and product
SELECT PRODUCT_ID, START_DATE FROM CONTRACT;

// Get waiting period for guarantee
waitingMonths = PRODSRV_GetGuaranteeWaitingPeriod(productId: guaranteeCode);

// Calculate waiting end date
waitingEndDate = startDate + %months(waitingMonths);

// Check if incident is before waiting period ended
return (incidentDate < waitingEndDate);
```

**Example:**
```
Contract start: 2025-01-01
Waiting period: 12 months (family law)
Waiting end: 2026-01-01
Incident: 2025-06-15

IsInWaitingPeriod returns *ON → REJECT CLAIM (BUS004)
```

**Business Rule:**
Waiting periods prevent "insurance after the fact" - customer cannot get coverage for pre-existing or imminent disputes.

---

### AssignLawyer

**Procedure:** `CLAIMSRV_AssignLawyer` ([CLAIMSRV.sqlrpgle:419](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L419))

Assigns lawyer to claim and advances status to in-progress.

**Parameters:**
- `pClaimId` (DECIMAL(10,0), const) - Claim ID
- `pLawyerName` (VARCHAR(100), const) - Lawyer name

**Returns:**
- `IND` - Success indicator

**Logic:**
```rpg
UPDATE CLAIM SET
    LAWYER_NAME = :lawyerName,
    STATUS = 'PRO',  // In progress
    UPDATED_AT = CURRENT_TIMESTAMP
WHERE CLAIM_ID = :claimId;
```

**Business Context:**
Belgian legal protection insurance allows **free choice of lawyer** (libre choix de l'avocat). Customer can select any lawyer - DAS does not impose their own legal team.

---

### ResolveClaim

**Procedure:** `CLAIMSRV_ResolveClaim` ([CLAIMSRV.sqlrpgle:454](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L454))

Marks claim as resolved with outcome and approved amount.

**Parameters:**
- `pClaimId` (DECIMAL(10,0), const) - Claim ID
- `pResolutionType` (CHAR(3), const) - Resolution type (AMI/LIT/REJ)
- `pApprovedAmount` (DECIMAL(11,2), const) - Approved amount (€)

**Returns:**
- `IND` - Success indicator

**Validation:**

**1. Resolution Type:**
```rpg
if pResolutionType <> 'AMI' and
   pResolutionType <> 'LIT' and
   pResolutionType <> 'REJ';
    ERRUTIL_addErrorCode('VAL006');
    return *off;
endif;
```

**2. Coverage Limit:**
```rpg
SELECT P.COVERAGE_LIMIT
FROM CLAIM CL
JOIN CONTRACT C ON CL.CONT_ID = C.CONT_ID
JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID;

if pApprovedAmount > coverageLimit;
    ERRUTIL_addErrorCode('BUS007');
    return *off;
endif;
```

**Logic:**
```rpg
UPDATE CLAIM SET
    RESOLUTION_TYPE = :resolutionType,
    APPROVED_AMOUNT = :approvedAmount,
    STATUS = 'RES',  // Resolved
    UPDATED_AT = CURRENT_TIMESTAMP
WHERE CLAIM_ID = :claimId;
```

**Error Codes:**
- `VAL006` - Invalid resolution type
- `BUS007` - Approved amount exceeds coverage limit
- `DB004` - Database operation failed

**Business Note:**
Comment in code: "79% of DAS cases resolved amicably!" This is a key differentiator for DAS Belgium.

---

### GenerateClaimRef

**Procedure:** `CLAIMSRV_GenerateClaimRef` ([CLAIMSRV.sqlrpgle:516](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L516))

Generates unique claim reference number.

**Parameters:**
None

**Returns:**
- `CHAR(20)` - Generated reference string

**Format:**
```
SIN-YYYY-NNNNNN

SIN    = Sinistre (French for claim)
YYYY   = Current year
NNNNNN = Sequence number (auto-increment)
```

**Algorithm:**
```rpg
year = %char(%subdt(%date(): *years));  // "2025"
sequence = MAX(CLAIM_ID) + 1;           // Next sequence

reference = 'SIN-' + year + '-' + %editc(sequence: 'X');
```

**Examples:**
```
SIN-2025-000001  // First claim of 2025
SIN-2025-000123  // 123rd claim
SIN-2026-000001  // First claim of 2026
```

**Fallback:**
If sequence query fails, uses timestamp as sequence (guaranteed unique).

---

### GenerateFileRef

**Procedure:** `CLAIMSRV_GenerateFileRef` ([CLAIMSRV.sqlrpgle:548](../src/qrpglesrc/CLAIMSRV.sqlrpgle#L548))

Generates dossier (file) reference number.

**Parameters:**
- `pClaimId` (DECIMAL(10,0), const) - Claim ID

**Returns:**
- `CHAR(20)` - Generated reference string

**Format:**
```
DOS-NNNNNNNNNN

DOS = Dossier (French for file)
NNNNNNNNNN = Claim ID (zero-padded)
```

**Examples:**
```
DOS-0000000001  // Claim ID 1
DOS-0000000123  // Claim ID 123
DOS-0000012345  // Claim ID 12,345
```

**Business Context:**
Dossier number used for:
- Internal file tracking
- Lawyer communication
- Archival system
- TELEBIB2 ClaimFileReference element

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
| VAL006 | Required field missing / Invalid value | IsValidClaim, ResolveClaim |
| DB001 | Claim not found | GetClaim (SQLCODE 100) |
| DB002 | Duplicate reference | CreateClaim (SQLCODE -803) |
| DB004 | Database operation failed | Any SQL error |
| BUS003 | Contract not active | IsValidClaim |
| BUS004 | Incident during waiting period | CreateClaim |
| BUS005 | Not covered by product | CreateClaim |
| BUS006 | Amount below minimum threshold | CreateClaim |
| BUS007 | Approved amount exceeds limit | ResolveClaim |

### Error Recovery Strategy

**CreateClaim:**
- Returns 0 on error
- Specific error code indicates reason:
  - BUS003: Activate contract first
  - BUS004: Incident too early (waiting period)
  - BUS005: Product doesn't include this coverage
  - BUS006: Claim amount < €350

**Validation Procedures:**
- IsCovered/IsInWaitingPeriod return *OFF on error (fail-safe)
- Error logged but processing continues

---

## Database Operations

### Multi-Table JOIN for Coverage Validation

ResolveClaim uses complex JOIN to get coverage limit:

```sql
SELECT P.COVERAGE_LIMIT
FROM CLAIM CL
JOIN CONTRACT C ON CL.CONT_ID = C.CONT_ID
JOIN PRODUCT P ON C.PRODUCT_ID = P.PRODUCT_ID
WHERE CL.CLAIM_ID = :claimId;
```

Chain: Claim → Contract → Product → Coverage Limit

### Conditional Update with SQL Functions

GenerateFileRef uses SQL string functions:

```sql
UPDATE CLAIM
SET FILE_REFERENCE = 'DOS-' || TRIM(CHAR(:claimId))
WHERE CLAIM_ID = :claimId;
```

Converts numeric ID to string and concatenates prefix.

### Date Arithmetic for Waiting Period

```rpg
waitingEndDate = startDate + %months(waitingMonths);
return (incidentDate < waitingEndDate);
```

Uses RPG date arithmetic for business logic.

---

## Usage Examples

### Creating a New Claim

```rpg
dcl-ds claim likeds(Claim_t) inz;
dcl-s claimId packed(10:0);

// Customer calls about neighborhood dispute
claim.contId = 123;
claim.guaranteeCode = GUAR_NEIGHBOR;
claim.circumstanceCode = CIRCUM_NEIGHBOR;
claim.declarationDate = %date();
claim.incidentDate = %date() - %days(7);  // Incident last week
claim.description = 'Noise complaint against neighbor - ongoing issue';
claim.claimedAmount = 1500.00;  // Above €350 minimum

claimId = CreateClaim(claim);

if claimId > 0;
    dsply ('Claim created: ' + claim.claimReference);
    // Displays: "Claim created: SIN-2025-000123"
else;
    // Check ERRUTIL for error code:
    // BUS004 = waiting period
    // BUS005 = not covered
    // BUS006 = amount < €350
endif;
```

### Validating Coverage Before Creating UI

```rpg
dcl-s contId packed(10:0);
dcl-s isCovered ind;

contId = 123;

// Check if customer can make family law claim
isCovered = IsCovered(contId: GUAR_FAMILY);

if isCovered;
    // Show "File Family Law Claim" button
else;
    // Show "Upgrade to Benefisc for family law coverage"
endif;
```

### Checking Waiting Period

```rpg
dcl-s contId packed(10:0);
dcl-s incidentDate date;
dcl-s inWaiting ind;

contId = 123;
incidentDate = %date('2025-03-15');

inWaiting = IsInWaitingPeriod(contId: GUAR_TAX: incidentDate);

if inWaiting;
    // Reject claim with message:
    // "Tax law coverage has 6-month waiting period.
    //  Your contract started 2025-01-01.
    //  Coverage begins 2025-07-01."
endif;
```

### Assigning Lawyer to Claim

```rpg
dcl-s claimId packed(10:0);
dcl-s success ind;

claimId = 456;

// Customer chose their lawyer
success = AssignLawyer(claimId: 'Me. Jean Dupont');

if success;
    // Status changed from NEW → PRO
    // Send email to lawyer with dossier details
endif;
```

### Resolving Claim (Amicable Settlement)

```rpg
dcl-s claimId packed(10:0);
dcl-s success ind;

claimId = 456;

// DAS negotiated settlement - 79% of cases!
success = ResolveClaim(claimId: RESOL_AMICABLE: 1200.00);

if success;
    // Status changed to RES
    // Approved amount: €1,200
    // Resolution type: AMI (amicable)

    // Send confirmation to customer
    // Process payment to lawyer
else;
    // Check error: BUS007 = exceeds coverage limit
endif;
```

### Resolving Claim (Litigation)

```rpg
dcl-s claimId packed(10:0);
dcl-s success ind;

claimId = 789;

// Case went to court (21% of cases)
success = ResolveClaim(claimId: RESOL_LITIGATION: 5000.00);

if success;
    // Status changed to RES
    // Approved amount: €5,000 (court costs + fees)
    // Resolution type: LIT (litigation)
endif;
```

### Finding All Claims for a Contract

```rpg
dcl-s contId packed(10:0);
dcl-s count int(10);

contId = 123;
count = GetContractClaims(contId);

dsply ('Customer has ' + %char(count) + ' claims');
```

### Searching Claims by Status

```rpg
dcl-ds filter likeds(ClaimFilter_t) inz;
dcl-s count int(10);

// Find all resolved claims
filter.status = CLAIM_RESOLVED;

count = ListClaims(filter);

dsply ('Resolved claims: ' + %char(count));
```

---

## Business Logic Details

### Claim Lifecycle State Machine

```
NEW → PRO → RES → CLO
 ↓
REJ

NEW (New):
  - Claim submitted
  - Awaiting assignment

PRO (In Progress):
  - Lawyer assigned
  - Case being worked

RES (Resolved):
  - Outcome determined
  - Amount approved
  - Type recorded (AMI/LIT/REJ)

CLO (Closed):
  - Payment complete
  - File archived

REJ (Rejected):
  - Not covered (BUS005)
  - Waiting period (BUS004)
  - Below threshold (BUS006)
```

### Resolution Types Deep Dive

**AMI (Amicable) - 79% at DAS:**
- Negotiation between parties
- No court involvement
- Lower costs for all
- Faster resolution
- DAS's internal legal team handles

**Example scenarios:**
- Neighbor noise dispute → agreement on quiet hours
- Consumer product defect → replacement/refund negotiated
- Insurance claim denial → company reverses decision
- Employment wrongful termination → severance negotiated

**LIT (Litigation) - 21%:**
- Court proceedings
- Higher costs (lawyer fees, court costs)
- Longer duration
- Customer's chosen lawyer
- Coverage up to €200,000

**Example scenarios:**
- Medical malpractice lawsuit
- Criminal defense trial
- Complex family law divorce
- Large insurance fraud case

**REJ (Rejected):**
- Not a valid resolution - used for denied claims
- Usually set during ResolveClaim with €0 approved amount
- Customer can appeal

### Waiting Period Business Rules

**Rationale:**
Prevents "adverse selection" - customers buying insurance after problem arises.

**DAS Belgium Typical Waiting Periods:**

| Coverage Type | Waiting Period | Rationale |
|---------------|----------------|-----------|
| Criminal defense | 0 months | Immediate need, unpredictable |
| Civil recovery | 3 months | Standard |
| Insurance disputes | 3 months | Standard |
| Neighborhood disputes | 3 months | Standard |
| Tax law | 6 months | Longer to prevent tax season rush |
| Family law | 12 months | Longest - prevents divorce pre-planning |
| Employment law | 6 months | Moderate - prevents layoff anticipation |

**Implementation:**
```rpg
waitingEndDate = contractStartDate + %months(waitingPeriod);

if incidentDate < waitingEndDate;
    // REJECT - incident during waiting period
endif;
```

**Example:**
```
Contract start: 2025-01-01
Coverage: Family law (12 months waiting)
Waiting ends: 2026-01-01

Incident dates:
  2025-06-15 → REJECT (too early)
  2026-01-15 → ACCEPT (after waiting period)
```

### Minimum Threshold (€350)

**Rationale:**
- Administrative cost of handling claim
- Prevents frivolous small claims
- Focus resources on significant disputes

**Implementation:**
```rpg
dcl-c MIN_CLAIM_THRESHOLD 350;

if claimedAmount < MIN_CLAIM_THRESHOLD;
    ERRUTIL_addErrorCode('BUS006');
    return 0;
endif;
```

**Business Impact:**
- Customer can still use Service Box for advice (free)
- Threshold prevents claim filing for €50 parking ticket dispute
- Customer might handle small issue themselves with DAS advice

### Coverage Limit Enforcement

**Maximum: €200,000**

**Implementation in ResolveClaim:**
```rpg
SELECT P.COVERAGE_LIMIT INTO :coverageLimit;

if approvedAmount > coverageLimit;
    ERRUTIL_addErrorCode('BUS007');
    return *off;
endif;
```

**Business Scenarios:**

**Scenario 1 - Within Limit:**
```
Claim: Medical malpractice
Claimed: €50,000
Approved: €50,000
Coverage limit: €200,000
Result: APPROVED
```

**Scenario 2 - Exceeds Limit:**
```
Claim: Complex litigation
Claimed: €250,000
Approved: €250,000 (by court)
Coverage limit: €200,000
Result: REJECTED (BUS007)
Action: DAS pays €200,000, customer pays €50,000
```

**Real-world handling:**
- DAS pays up to limit
- Customer notified of excess
- Customer can pay difference or appeal

### Claim Reference Numbering Strategy

**Format Comparison:**

| System | Format | Example |
|--------|--------|---------|
| Claim Reference (ClaimReference) | SIN-YYYY-NNNNNN | SIN-2025-000123 |
| File Reference (ClaimFileReference) | DOS-NNNNNNNNNN | DOS-0000000123 |
| Contract Reference | DAS-YYYY-BBBBB-NNNNNN | DAS-2025-00001-000456 |

**Usage:**
- **Claim Reference:** Customer-facing, telephone support, email communication
- **File Reference:** Internal tracking, lawyer communication, archival
- **Both sent in TELEBIB2 EDI messages**

---

## Development Notes

### Dependencies

**Internal:**
- `ERRUTIL.rpgle` - Error handling utility
- `CLAIMSRV_H.rpgle` - Copybook (data structures, prototypes, constants)
- `CONTSRV_H.rpgle` - Contract service copybook (IsContractActive)
- `PRODSRV_H.rpgle` - Product service copybook (HasGuarantee, GetGuaranteeWaitingPeriod)

**External:**
- CLAIM table (must exist in database)
- CONTRACT table (FK relationship)
- PRODUCT table (via CONTRACT → PRODUCT join)
- GUARANTEE table (via PRODSRV procedures)
- SQL environment configured

### Build Instructions

```bash
# Compile service module
CRTSQLRPGI OBJ(YOURLIB/CLAIMSRV) SRCFILE(QRPGLESRC) COMMIT(*NONE) OBJTYPE(*MODULE)

# Create service program with dependencies
CRTSRVPGM SRVPGM(YOURLIB/CLAIMSRV) MODULE(YOURLIB/CLAIMSRV) EXPORT(*ALL) \
  BNDSRVPGM(CONTSRV PRODSRV)
```

**Important:** CLAIMSRV calls procedures from CONTSRV and PRODSRV, so both service programs must be available.

### Testing Considerations

**Unit Test Cases:**

**Basic CRUD:**
1. CreateClaim with valid data
2. CreateClaim with missing required fields (VAL006)
3. CreateClaim with inactive contract (BUS003)
4. GetClaim with valid/invalid ID
5. GetClaimByRef with valid/invalid reference
6. UpdateClaim modify fields

**Coverage Validation:**
7. CreateClaim with covered guarantee (success)
8. CreateClaim with non-covered guarantee (BUS005)
9. IsCovered - positive case (DAS Classic + civil recovery)
10. IsCovered - negative case (DAS Classic + family law)

**Waiting Period:**
11. CreateClaim incident after waiting period (success)
12. CreateClaim incident during waiting period (BUS004)
13. IsInWaitingPeriod - incident too early
14. IsInWaitingPeriod - incident after waiting ends

**Amount Validation:**
15. CreateClaim with amount >= €350 (success)
16. CreateClaim with amount < €350 (BUS006)
17. ResolveClaim within coverage limit (success)
18. ResolveClaim exceeds coverage limit (BUS007)

**Workflow:**
19. AssignLawyer - status changes NEW → PRO
20. ResolveClaim - AMI (amicable)
21. ResolveClaim - LIT (litigation)
22. ResolveClaim - REJ (rejected)
23. ResolveClaim - invalid resolution type (VAL006)

**Reference Generation:**
24. GenerateClaimRef - unique references
25. GenerateClaimRef - year component
26. GenerateFileRef - format DOS-NNNNNNNNNN

**Integration Tests:**
- Full claim lifecycle (create → assign → resolve)
- Coverage validation across product types
- Waiting period with various guarantee types
- Multi-table JOINs (claim → contract → product)
- TELEBIB2 EDI message generation

### Future Enhancements

1. **Result set returns:** ListClaims/GetContractClaims return actual claim arrays
2. **Workflow automation:**
   - Auto-assignment based on claim type
   - Lawyer recommendation system
   - Automatic amicable resolution attempts
3. **Enhanced validation:**
   - Duplicate claim detection (same incident)
   - Fraud detection patterns
   - Historical claim analysis per customer
4. **Service Box integration:**
   - Preventive advice tracking
   - Document review requests
   - Question/answer logging
5. **Communication:**
   - Email notifications at each status change
   - SMS alerts for claim updates
   - Customer portal integration
6. **Reporting:**
   - Amicable resolution rate tracking (target: 79%)
   - Average resolution time
   - Coverage type breakdown
   - Lawyer performance metrics
7. **Payment integration:**
   - Lawyer fee payment processing
   - Court cost reimbursement
   - Settlement payment tracking

### Performance Considerations

**Indexes Required:**
- CLAIM.CLAIM_REFERENCE (unique) - fast lookup
- CLAIM.FILE_REFERENCE - lawyer/admin lookup
- CLAIM.CONT_ID - contract claims query
- CLAIM.STATUS - status-based filtering
- CLAIM.DECLARATION_DATE - date range queries
- CLAIM.GUARANTEE_CODE - coverage type reporting

**Batch Processing:**
- Automatic closure of resolved claims after payment
- Waiting period validation can be pre-computed for new contracts
- Amicable resolution rate reporting (monthly)

**Caching:**
- Product guarantee lists (rarely change)
- Waiting period configurations (static)
- Coverage limits (static per product)

---

## Version History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2025-12-05 | Claude | Initial implementation |

---

**Related Documentation:**
- [Implementation Plan](../implementation-plan.md)
- [CLAIM Table DDL](../../sql/CLAIM.sql)
- [CONTSRV Module](CONTSRV.md) - Contract service (validates contracts)
- [PRODSRV Module](PRODSRV.md) - Product service (validates coverage)
- [BROKRSRV Module](BROKRSRV.md) - Broker service
- [CUSTSRV Module](CUSTSRV.md) - Customer service

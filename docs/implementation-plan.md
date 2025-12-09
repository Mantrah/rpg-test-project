# DAS.be Backend Implementation Plan

## Company Research

### DAS Belgium Profile

| Attribute | Value |
|-----------|-------|
| Founded | 1927 |
| Employees | ~236 |
| Parent Company | ERGO Group (Munich Re) |
| Headquarters | Boulevard du Roi Albert II, 7 - 1210 Brussels |
| Regional Offices | Brussels, Nivelles, Liège, Antwerp, Ghent (5 total) |
| Market Position | **Leader** in Belgian legal protection insurance |
| Distribution | **Exclusively through insurance brokers** |
| Supervision | National Bank of Belgium (code 0687) |

### Business Model

**Key Insight:** DAS does NOT sell directly to customers. All sales go through insurance brokers (courtiers/makelaars). This is fundamental to their architecture.

**PROF Concept:** Professional service promise to brokers
- Service Box: Preventive legal advice, document review
- Internal legal team (no outsourcing for basic advice)
- "Wij helpen u" - "We help you" philosophy

**Claims Resolution:** 79% of cases resolved through amicable negotiation (no court)

### Products for Individuals

| Product | Price/year | Coverage Level |
|---------|------------|----------------|
| DAS Classic | €114 | Basic |
| DAS Connect | €276 | Extended |
| DAS Comfort | €396 | Comprehensive |

**Alternative naming:** Vie Privée, Consommateur, Conflits
**Benefisc variants:** €245-756/year (with 40% tax benefit)

### Coverage Types (Guarantees)

| Category | Included In |
|----------|-------------|
| Civil recovery & neighborhood disputes | All |
| Criminal defense | All |
| Insurance contract disputes | All |
| Medical malpractice | All |
| Family law | Benefisc only |
| Tax law (FiscAssist) | Benefisc only |
| Employment law | Benefisc only |
| Succession rights | Benefisc only |
| Administrative law | Benefisc only |

### Key Business Rules

- Coverage ceiling: Up to €200,000
- Minimum intervention threshold: €350
- Waiting periods: 3-12 months depending on coverage
- Contract duration: 1 year, auto-renewal
- Cancellation: 2 months before expiration

---

## Technical Research

### DAS.be Digital Infrastructure

| Endpoint | Purpose | Access |
|----------|---------|--------|
| `claims.das.be` | Claims submission portal | Authenticated |
| `extranet.das.be` | Broker portal (Extranet23) | Authenticated |
| `www-data.das.be/strapi/` | CMS/documents (AWS S3) | Partial |

**Frontend:** Angular-based SPA
**No public API found** - All broker interactions through authenticated portals

### TELEBIB2 - Belgian Insurance EDI Standard

TELEBIB2 is the official UN/EDIFACT-based standard for electronic data exchange in Belgian insurance. Used for policy administration, claims handling, and accounting.

**ADR Segment (Address) - Official field names:**

| Field Code | Description | Max Length |
|------------|-------------|------------|
| X001 | Address qualifier | 3 |
| X002 | Street | 30 |
| X003 | House number | 5 |
| X004 | Box number | 4 |
| X005 | Bus/Boîte indicator | 1 |
| X006 | Postal code | 7 |
| X007 | City name | 24 |
| X008 | Country code | 3 |
| X009 | Country name | 35 |

**Key TELEBIB2 Business Elements:**

| Element | Purpose |
|---------|---------|
| BrokerPolicyReference | Broker's policy reference number |
| PolicyholderInformation | Policyholder data |
| ClaimReference | Claim identifier |
| ClaimFileReference | Claim file/dossier number |
| ClaimAmount | Claimed amount |
| ClaimCircumstancesCode | Type of claim circumstance |
| CoverageCode | Coverage/guarantee identifier |
| BeneficiaryCode | Beneficiary identifier |
| CivilStatusCode | Marital status |
| AgencyCode | Broker/agency identifier |
| BusinessCodeNace | NACE business activity code |

---

## Database Design

### Data Model Overview

```
BROKER (1) ──────< CONTRACT >────── (1) CUSTOMER
                      │
                      │
                      ▼
                   PRODUCT (1) ────< GUARANTEE
                      │
                      │
                      ▼
                    CLAIM
```

### Table: BROKER

Insurance brokers - the exclusive sales channel for DAS.

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| BROKER_ID | DECIMAL(10,0) | PK, auto-generated | AgencyCode |
| BROKER_CODE | CHAR(10) | Unique broker code | AgencyCode |
| COMPANY_NAME | VARCHAR(100) | Broker company name | - |
| VAT_NUMBER | CHAR(12) | Belgian VAT (BE0123456789) | - |
| FSMA_NUMBER | CHAR(10) | FSMA registration number | - |
| STREET | VARCHAR(30) | Street name | X002 |
| HOUSE_NBR | CHAR(5) | House number | X003 |
| BOX_NBR | CHAR(4) | Box number | X004 |
| POSTAL_CODE | CHAR(7) | Postal code | X006 |
| CITY | VARCHAR(24) | City name | X007 |
| COUNTRY_CODE | CHAR(3) | Country code (BEL) | X008 |
| PHONE | VARCHAR(20) | Phone number | - |
| EMAIL | VARCHAR(100) | Email address | - |
| CONTACT_NAME | VARCHAR(100) | Primary contact | - |
| STATUS | CHAR(3) | ACT/INA/SUS | - |
| CREATED_AT | TIMESTAMP | Creation timestamp | - |
| UPDATED_AT | TIMESTAMP | Last update | - |

### Table: CUSTOMER

Policyholders - individuals or businesses.

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| CUST_ID | DECIMAL(10,0) | PK, auto-generated | - |
| CUST_TYPE | CHAR(3) | IND/BUS | - |
| FIRST_NAME | VARCHAR(50) | First name (IND) | - |
| LAST_NAME | VARCHAR(50) | Last name (IND) | - |
| COMPANY_NAME | VARCHAR(100) | Company name (BUS) | - |
| VAT_NUMBER | CHAR(12) | Belgian VAT (BUS) | - |
| NATIONAL_ID | CHAR(15) | Belgian NRN (IND) | - |
| NACE_CODE | CHAR(5) | Business activity (BUS) | BusinessCodeNace |
| CIVIL_STATUS | CHAR(3) | Marital status (IND) | CivilStatusCode |
| BIRTH_DATE | DATE | Date of birth (IND) | BirthDate |
| STREET | VARCHAR(30) | Street | X002 |
| HOUSE_NBR | CHAR(5) | House number | X003 |
| BOX_NBR | CHAR(4) | Box number | X004 |
| POSTAL_CODE | CHAR(7) | Postal code | X006 |
| CITY | VARCHAR(24) | City | X007 |
| COUNTRY_CODE | CHAR(3) | Country (BEL) | X008 |
| PHONE | VARCHAR(20) | Phone | - |
| EMAIL | VARCHAR(100) | Email | - |
| LANGUAGE | CHAR(2) | FR/NL/DE | - |
| STATUS | CHAR(3) | ACT/INA/SUS | - |
| CREATED_AT | TIMESTAMP | Created | - |
| UPDATED_AT | TIMESTAMP | Updated | - |

**Civil Status Codes:**
| Code | Description |
|------|-------------|
| SGL | Single |
| MAR | Married |
| COH | Cohabiting |
| DIV | Divorced |
| WID | Widowed |

### Table: PRODUCT

Insurance product catalog.

| Column | Type | Description |
|--------|------|-------------|
| PRODUCT_ID | DECIMAL(10,0) | PK, auto-generated |
| PRODUCT_CODE | CHAR(10) | Unique product code |
| PRODUCT_NAME | VARCHAR(50) | Display name |
| PRODUCT_TYPE | CHAR(3) | IND/FAM/BUS |
| BASE_PREMIUM | DECIMAL(9,2) | Annual base premium |
| COVERAGE_LIMIT | DECIMAL(11,2) | Maximum coverage (€200,000) |
| MIN_THRESHOLD | DECIMAL(7,2) | Minimum claim (€350) |
| TAX_BENEFIT | CHAR(1) | Y/N (Benefisc) |
| WAITING_MONTHS | DECIMAL(2,0) | Waiting period |
| STATUS | CHAR(3) | ACT/INA |
| CREATED_AT | TIMESTAMP | Created |
| UPDATED_AT | TIMESTAMP | Updated |

**Product Codes (matching DAS):**
| Code | Name | Type | Base Premium |
|------|------|------|--------------|
| CLASSIC | DAS Classic | IND | €114 |
| CONNECT | DAS Connect | IND | €276 |
| COMFORT | DAS Comfort | IND | €396 |
| VIE_PRIV | Vie Privée | IND | €139 |
| CONSOM | Consommateur | IND | €154 |
| CONSOM_BF | Consommateur Benefisc | IND | €245 |
| CONFLIT_BF | Conflits Benefisc | IND | €539 |
| SUR_MES | Sur Mesure | BUS | Variable |
| FISCASST | FiscAssist | BUS | Variable |

### Table: GUARANTEE

Coverage types per product.

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| GUARANTEE_ID | DECIMAL(10,0) | PK | - |
| PRODUCT_ID | DECIMAL(10,0) | FK to PRODUCT | - |
| GUARANTEE_CODE | CHAR(10) | Coverage code | CoverageCode |
| GUARANTEE_NAME | VARCHAR(50) | Display name | - |
| COVERAGE_LIMIT | DECIMAL(11,2) | Specific limit | - |
| WAITING_MONTHS | DECIMAL(2,0) | Specific waiting | - |
| STATUS | CHAR(3) | ACT/INA | - |

**Guarantee Codes:**
| Code | Description |
|------|-------------|
| CIV_RECOV | Civil recovery |
| CRIM_DEF | Criminal defense |
| INS_CONTR | Insurance contracts |
| MED_MALPR | Medical malpractice |
| NEIGHBOR | Neighborhood disputes |
| FAMILY | Family law |
| TAX | Tax law |
| EMPLOY | Employment law |
| SUCCES | Succession rights |
| ADMIN | Administrative law |

### Table: CONTRACT

Insurance policies linking broker, customer, and product.

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| CONT_ID | DECIMAL(10,0) | PK | - |
| CONT_REFERENCE | CHAR(20) | Policy number | BrokerPolicyReference |
| BROKER_ID | DECIMAL(10,0) | FK to BROKER | AgencyCode |
| CUST_ID | DECIMAL(10,0) | FK to CUSTOMER | - |
| PRODUCT_ID | DECIMAL(10,0) | FK to PRODUCT | - |
| START_DATE | DATE | Coverage start | - |
| END_DATE | DATE | Coverage end | - |
| PREMIUM_AMT | DECIMAL(9,2) | Annual premium | - |
| PAY_FREQUENCY | CHAR(1) | M/Q/A | - |
| VEHICLES_COUNT | DECIMAL(2,0) | Number of vehicles | - |
| AUTO_RENEW | CHAR(1) | Y/N | - |
| STATUS | CHAR(3) | PEN/ACT/EXP/CAN/REN | - |
| CREATED_AT | TIMESTAMP | Created | - |
| UPDATED_AT | TIMESTAMP | Updated | - |

**Status Codes:**
| Code | Description |
|------|-------------|
| PEN | Pending activation |
| ACT | Active |
| EXP | Expired |
| CAN | Cancelled |
| REN | Renewal pending |

### Table: CLAIM

Legal protection claims (sinistres).

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| CLAIM_ID | DECIMAL(10,0) | PK | - |
| CLAIM_REFERENCE | CHAR(20) | Claim number | ClaimReference |
| FILE_REFERENCE | CHAR(20) | Dossier number | ClaimFileReference |
| CONT_ID | DECIMAL(10,0) | FK to CONTRACT | - |
| GUARANTEE_CODE | CHAR(10) | Coverage type | CoverageCode |
| CIRCUMSTANCE_CODE | CHAR(10) | Claim type | ClaimCircumstancesCode |
| DECLARATION_DATE | DATE | Declaration date | - |
| INCIDENT_DATE | DATE | Incident date | - |
| DESCRIPTION | VARCHAR(500) | Claim description | - |
| CLAIMED_AMOUNT | DECIMAL(11,2) | Amount claimed | ClaimAmount |
| APPROVED_AMOUNT | DECIMAL(11,2) | Amount approved | - |
| RESOLUTION_TYPE | CHAR(3) | AMI/LIT/REJ | - |
| LAWYER_NAME | VARCHAR(100) | Assigned lawyer | - |
| STATUS | CHAR(3) | NEW/PRO/RES/CLO/REJ | - |
| CREATED_AT | TIMESTAMP | Created | - |
| UPDATED_AT | TIMESTAMP | Updated | - |

**Resolution Types:**
| Code | Description |
|------|-------------|
| AMI | Amicable settlement (79% of cases) |
| LIT | Litigation |
| REJ | Rejected |

**Claim Status:**
| Code | Description |
|------|-------------|
| NEW | New claim |
| PRO | In progress |
| RES | Resolved |
| CLO | Closed |
| REJ | Rejected |

**Circumstance Codes:**
| Code | Description |
|------|-------------|
| CONTR_DISP | Contract dispute |
| EMPL_DISP | Employment dispute |
| NEIGH_DISP | Neighborhood dispute |
| TAX_DISP | Tax dispute |
| MED_MALPR | Medical malpractice |
| CRIM_DEF | Criminal defense |
| FAM_DISP | Family dispute |
| ADMIN_DISP | Administrative dispute |

---

## RPG Service Modules

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Node.js API (rpgConnector.js)              │
│                  iToolkit/XMLSERVICE                    │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              RPGWRAP (Wrapper Layer)                    │
│  - Converts scalar params ↔ Data Structures             │
│  - List ops: JSON generation via SQL cursors            │
│  - CRUD ops: Delegates to *SRV business services        │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    Service Layer                        │
├──────────┬──────────┬──────────┬──────────┬────────────┤
│ BROKRSRV │ CUSTSRV  │ PRODSRV  │ CONTSRV  │ CLAIMSRV   │
│ Broker   │ Customer │ Product  │ Contract │ Claim      │
│ CRUD     │ CRUD     │ CRUD     │ CRUD     │ CRUD       │
└────┬─────┴────┬─────┴────┬─────┴────┬─────┴─────┬──────┘
     │          │          │          │           │
     ▼          ▼          ▼          ▼           ▼
┌─────────────────────────────────────────────────────────┐
│                    Database Layer                       │
├──────────┬──────────┬──────────┬──────────┬────────────┤
│  BROKER  │ CUSTOMER │ PRODUCT  │ CONTRACT │   CLAIM    │
│          │          │ GUARANTEE│          │            │
└──────────┴──────────┴──────────┴──────────┴────────────┘
```

### BROKRSRV - Broker Service Module

| Procedure | Description | Returns |
|-----------|-------------|---------|
| CreateBroker | Insert new broker | Broker ID |
| GetBroker | Retrieve by ID | Broker DS |
| GetBrokerByCode | Retrieve by code | Broker DS |
| UpdateBroker | Update existing | Success indicator |
| DeleteBroker | Deactivate broker | Success indicator |
| ListBrokers | Search with filters | Result count |
| IsValidBroker | Validate broker data | Valid indicator |
| IsValidFsmaNumber | Validate FSMA registration | Valid indicator |

### CUSTSRV - Customer Service Module

| Procedure | Description | Returns |
|-----------|-------------|---------|
| CreateCustomer | Insert new customer | Customer ID |
| GetCustomer | Retrieve by ID | Customer DS |
| UpdateCustomer | Update existing | Success indicator |
| DeleteCustomer | Deactivate customer | Success indicator |
| ListCustomers | Search with filters | Result count |
| IsValidCustomer | Validate customer data | Valid indicator |
| IsValidEmail | Validate email format | Valid indicator |
| IsValidVatNumber | Validate Belgian VAT | Valid indicator |
| IsValidNationalId | Validate Belgian NRN | Valid indicator |
| IsValidPostalCode | Validate postal code | Valid indicator |

### PRODSRV - Product Service Module

| Procedure | Description | Returns |
|-----------|-------------|---------|
| GetProduct | Retrieve by ID | Product DS |
| GetProductByCode | Retrieve by code | Product DS |
| ListProducts | List active products | Result count |
| GetProductGuarantees | Get coverage types | Result count |
| CalculateBasePremium | Calculate premium | Premium amount |
| IsProductAvailable | Check availability | Available indicator |

### CONTSRV - Contract Service Module

| Procedure | Description | Returns |
|-----------|-------------|---------|
| CreateContract | Insert new contract | Contract ID |
| GetContract | Retrieve by ID | Contract DS |
| GetContractByRef | Retrieve by reference | Contract DS |
| UpdateContract | Update existing | Success indicator |
| CancelContract | Cancel contract | Success indicator |
| ListContracts | Search with filters | Result count |
| GetCustomerContracts | Contracts for customer | Result count |
| GetBrokerContracts | Contracts for broker | Result count |
| IsValidContract | Validate contract data | Valid indicator |
| CalculatePremium | Calculate total premium | Premium amount |
| CanRenewContract | Check renewal eligibility | Can renew indicator |
| RenewContract | Create renewal | New contract ID |
| IsContractActive | Check if active | Active indicator |
| GenerateContractRef | Generate policy number | Reference string |

### CLAIMSRV - Claim Service Module

| Procedure | Description | Returns |
|-----------|-------------|---------|
| CreateClaim | Insert new claim | Claim ID |
| GetClaim | Retrieve by ID | Claim DS |
| GetClaimByRef | Retrieve by reference | Claim DS |
| UpdateClaim | Update existing | Success indicator |
| ListClaims | Search with filters | Result count |
| GetContractClaims | Claims for contract | Result count |
| IsValidClaim | Validate claim data | Valid indicator |
| IsCovered | Check if covered by contract | Covered indicator |
| IsInWaitingPeriod | Check waiting period | In waiting indicator |
| AssignLawyer | Assign lawyer to claim | Success indicator |
| ResolveClaim | Mark as resolved | Success indicator |
| GenerateClaimRef | Generate claim number | Reference string |
| GenerateFileRef | Generate dossier number | Reference string |

---

## File Structure

```
rpg-test-project/
├── sql/
│   ├── BROKER.sql          # Broker table DDL
│   ├── CUSTOMER.sql        # Customer table DDL
│   ├── PRODUCT.sql         # Product table DDL
│   ├── GUARANTEE.sql       # Guarantee table DDL
│   ├── CONTRACT.sql        # Contract table DDL
│   └── CLAIM.sql           # Claim table DDL
├── src/qrpglesrc/
│   ├── BROKRSRV.sqlrpgle   # Broker service module
│   ├── BROKRSRV_H.rpgle    # Broker copybook
│   ├── CUSTSRV.sqlrpgle    # Customer service module
│   ├── CUSTSRV_H.rpgle     # Customer copybook
│   ├── PRODSRV.sqlrpgle    # Product service module
│   ├── PRODSRV_H.rpgle     # Product copybook
│   ├── CONTSRV.sqlrpgle    # Contract service module
│   ├── CONTSRV_H.rpgle     # Contract copybook
│   ├── CLAIMSRV.sqlrpgle   # Claim service module
│   ├── CLAIMSRV_H.rpgle    # Claim copybook
│   └── ERRUTIL.rpgle       # Error handling utility
└── docs/
    ├── implementation-plan.md
    ├── research/
    │   └── das-research.md
    └── architecture/
        └── data-model.md
```

---

## Implementation Order

### Phase 1: Foundation
1. Create SQL DDL for all 6 tables
2. Create ERRUTIL stub (error handling)
3. Create all copybooks with DS and prototypes

### Phase 2: Reference Data Services
4. Implement PRODSRV (read-only for products/guarantees)
5. Implement BROKRSRV (broker CRUD)

### Phase 3: Core Business Services
6. Implement CUSTSRV (customer CRUD + validation)
7. Implement CONTSRV (contract CRUD + business logic)

### Phase 4: Claims Processing
8. Implement CLAIMSRV (claim CRUD + coverage validation)

### Phase 5: Documentation
9. Generate documentation using document-rpg-program skill

---

## Coding Standards (per rpg-generator skill)

- **Free-format RPG** (`**free`)
- **Naming:** camelCase variables, PascalCase procedures/DS
- **Error handling:** ERRUTIL with MONITOR/ON-ERROR
- **SQL:** Embedded SQL for all database operations
- **Comments:** Section headers in monitor blocks
- **Validation:** Input validation before processing
- **TELEBIB2 alignment:** Use field sizes from TELEBIB2 where applicable

---

## What Will Impress DAS.be

1. **Deep domain knowledge**
   - Understanding of broker-centric distribution model
   - Proper insurance terminology (sinistre, garantie, police)
   - Knowledge of PROF concept and Service Box

2. **Belgian specifics**
   - TELEBIB2 field naming alignment
   - VAT format (BE0123456789)
   - NRN format (national register number)
   - Trilingual support (FR/NL/DE)
   - FSMA registration for brokers

3. **Business logic understanding**
   - 79% amicable resolution rate
   - Waiting periods per coverage type
   - €350 minimum threshold
   - €200,000 coverage ceiling
   - Auto-renewal with 2-month cancellation

4. **Modern RPG architecture**
   - Full free-format
   - Service modules (SRVPGM)
   - Embedded SQL
   - Separation of concerns

5. **Product knowledge**
   - Exact product names (Classic, Connect, Comfort)
   - Benefisc tax advantage
   - Coverage types matching their offerings

---

## Sources

- [DAS.be](https://www.das.be/fr) - Official website
- [DAS LinkedIn](https://be.linkedin.com/company/d-a-s-) - Company profile
- [HelloSafe DAS Review](https://hellosafe.be/protection-juridique/das) - Product details
- [TELEBIB2](https://www.telebib2.org/) - Belgian insurance EDI standard
- [ERGO Group](https://www.ergo.com/en/company/about-ergo/international-companies) - Parent company

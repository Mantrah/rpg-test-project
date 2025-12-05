# PRODSRV - Product Service Module

**Program:** `PRODSRV.sqlrpgle`
**Copybook:** `PRODSRV_H.rpgle`
**Target System:** IBM i V7R5
**Project:** DAS.be Backend - Legal Protection Insurance

---

## Overview

### Purpose

PRODSRV provides read-only access to the product catalog for DAS.be legal protection insurance. The module manages product definitions (Classic, Connect, Comfort, Benefisc) and their associated guarantees (coverage types), matching the actual DAS Belgium product portfolio.

### Key Features

- **Product catalog access:** Read-only retrieval of insurance products
- **Guarantee management:** Coverage types per product
- **Premium calculation:** Base premium + vehicle addon logic
- **Waiting period queries:** Product and guarantee-specific waiting periods
- **Availability checks:** Product and coverage validation
- **DAS product alignment:** Matches real DAS.be offerings

### Business Context

**DAS Belgium Product Portfolio:**

**Individual Products:**
- **DAS Classic:** €114/year - Basic coverage
- **DAS Connect:** €276/year - Extended coverage
- **DAS Comfort:** €396/year - Comprehensive coverage
- **Alternative names:** Vie Privée, Consommateur, Conflits

**Benefisc Products (tax deductible):**
- €245-756/year with 40% tax benefit
- Extended coverage including family law, employment law, tax law

**Business Products:**
- **Sur Mesure:** Variable pricing, customized for SMEs
- **FiscAssist:** Tax law coverage for professionals

**Coverage Rules:**
- Maximum coverage: €200,000
- Minimum claim threshold: €350
- Waiting periods: 3-12 months depending on coverage type

---

## Architecture

### Design Pattern

**Read-Only Catalog Pattern:**
- No Create/Update/Delete operations (managed via DDL/admin tools)
- Query-focused procedures
- Business logic for premium calculation
- Reference data integrity

### Data Flow

```
Caller (CONTSRV, API)
    ↓
PRODSRV Query Procedures
    ↓
PRODUCT + GUARANTEE Tables
    ↓
Return Product/Guarantee Data
```

### Integration Points

- **ERRUTIL:** Error handling for missing products
- **PRODUCT Table:** Product master data
- **GUARANTEE Table:** Coverage types per product
- **CONTSRV:** Contract creation uses product data
- **CLAIMSRV:** Coverage validation uses guarantee data

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

**PRODUCT:** Insurance product catalog

| Column | Type | Description |
|--------|------|-------------|
| PRODUCT_ID | DECIMAL(10,0) | PK, identity column |
| PRODUCT_CODE | CHAR(10) | Unique code (CLASSIC, CONNECT, etc.) |
| PRODUCT_NAME | VARCHAR(50) | Display name |
| PRODUCT_TYPE | CHAR(3) | IND/FAM/BUS |
| BASE_PREMIUM | DECIMAL(9,2) | Annual base premium (€) |
| COVERAGE_LIMIT | DECIMAL(11,2) | Maximum coverage (€200,000) |
| MIN_THRESHOLD | DECIMAL(7,2) | Minimum claim (€350) |
| TAX_BENEFIT | CHAR(1) | Y/N (Benefisc products) |
| WAITING_MONTHS | DECIMAL(2,0) | Default waiting period |
| STATUS | CHAR(3) | ACT/INA |
| CREATED_AT | TIMESTAMP | Record creation |
| UPDATED_AT | TIMESTAMP | Last update |

**GUARANTEE:** Coverage types per product

| Column | Type | Description | TELEBIB2 |
|--------|------|-------------|----------|
| GUARANTEE_ID | DECIMAL(10,0) | PK |  |
| PRODUCT_ID | DECIMAL(10,0) | FK to PRODUCT | - |
| GUARANTEE_CODE | CHAR(10) | Coverage code | CoverageCode |
| GUARANTEE_NAME | VARCHAR(50) | Display name | - |
| COVERAGE_LIMIT | DECIMAL(11,2) | Specific limit (overrides product) | - |
| WAITING_MONTHS | DECIMAL(2,0) | Specific waiting (overrides product) | - |
| STATUS | CHAR(3) | ACT/INA | - |

### Data Structures

**Product_t** ([PRODSRV_H.rpgle:13](../src/qrpglesrc/PRODSRV_H.rpgle#L13))

Product catalog record structure.

```rpg
dcl-ds Product_t qualified template;
    productId       packed(10:0);
    productCode     char(10);
    productName     varchar(50);
    productType     char(3);            // IND/FAM/BUS
    basePremium     packed(9:2);        // Annual base premium
    coverageLimit   packed(11:2);       // Max €200,000
    minThreshold    packed(7:2);        // Min €350
    taxBenefit      char(1);            // Y/N (Benefisc)
    waitingMonths   packed(2:0);
    status          char(3);            // ACT/INA
    createdAt       timestamp;
    updatedAt       timestamp;
end-ds;
```

**Guarantee_t** ([PRODSRV_H.rpgle:31](../src/qrpglesrc/PRODSRV_H.rpgle#L31))

Coverage type record structure.

```rpg
dcl-ds Guarantee_t qualified template;
    guaranteeId     packed(10:0);
    productId       packed(10:0);
    guaranteeCode   char(10);           // CoverageCode (TELEBIB2)
    guaranteeName   varchar(50);
    coverageLimit   packed(11:2);
    waitingMonths   packed(2:0);
    status          char(3);            // ACT/INA
end-ds;
```

### Constants

**Product Codes** ([PRODSRV_H.rpgle:44-52](../src/qrpglesrc/PRODSRV_H.rpgle#L44-L52))

DAS Belgium product portfolio constants.

| Constant | Value | Description |
|----------|-------|-------------|
| PROD_CLASSIC | CLASSIC | DAS Classic (€114/year) |
| PROD_CONNECT | CONNECT | DAS Connect (€276/year) |
| PROD_COMFORT | COMFORT | DAS Comfort (€396/year) |
| PROD_VIE_PRIV | VIE_PRIV | Vie Privée (€139/year) |
| PROD_CONSOM | CONSOM | Consommateur (€154/year) |
| PROD_CONSOM_BF | CONSOM_BF | Consommateur Benefisc (€245/year) |
| PROD_CONFLIT_BF | CONFLIT_BF | Conflits Benefisc (€539/year) |
| PROD_SUR_MES | SUR_MES | Sur Mesure (business, variable) |
| PROD_FISCASST | FISCASST | FiscAssist (business, variable) |

**Guarantee Codes** ([PRODSRV_H.rpgle:57-66](../src/qrpglesrc/PRODSRV_H.rpgle#L57-L66))

Coverage type constants (TELEBIB2 CoverageCode).

| Constant | Value | Description |
|----------|-------|-------------|
| GUAR_CIV_RECOV | CIV_RECOV | Civil recovery |
| GUAR_CRIM_DEF | CRIM_DEF | Criminal defense |
| GUAR_INS_CONTR | INS_CONTR | Insurance contract disputes |
| GUAR_MED_MALPR | MED_MALPR | Medical malpractice |
| GUAR_NEIGHBOR | NEIGHBOR | Neighborhood disputes |
| GUAR_FAMILY | FAMILY | Family law (Benefisc only) |
| GUAR_TAX | TAX | Tax law (Benefisc only) |
| GUAR_EMPLOY | EMPLOY | Employment law (Benefisc only) |
| GUAR_SUCCES | SUCCES | Succession rights (Benefisc only) |
| GUAR_ADMIN | ADMIN | Administrative law (Benefisc only) |

---

## Procedures Reference

### GetProduct

**Procedure:** `PRODSRV_GetProduct` ([PRODSRV.sqlrpgle:20](../src/qrpglesrc/PRODSRV.sqlrpgle#L20))

Retrieves product by primary key.

**Parameters:**
- `pProductId` (DECIMAL(10,0), const) - Product ID

**Returns:**
- `Product_t` - Product data structure (empty on error)

**Error Codes:**
- `DB001` - Product not found (SQLCODE 100)
- `DB004` - Database operation failed

**Logic:**
1. Execute SELECT by PRODUCT_ID
2. Populate Product_t structure
3. Clear structure on error
4. Return result

---

### GetProductByCode

**Procedure:** `PRODSRV_GetProductByCode` ([PRODSRV.sqlrpgle:60](../src/qrpglesrc/PRODSRV.sqlrpgle#L60))

Retrieves product by unique product code (alternative key).

**Parameters:**
- `pProductCode` (CHAR(10), const) - Product code

**Returns:**
- `Product_t` - Product data structure (empty on error)

**Error Codes:**
- `DB001` - Product not found (SQLCODE 100)
- `DB004` - Database operation failed

**Use Case:**
Primary lookup method for contract creation when user selects "DAS Classic" or uses product code constants.

**Example:**
```rpg
product = GetProductByCode(PROD_CLASSIC);
```

---

### ListProducts

**Procedure:** `PRODSRV_ListProducts` ([PRODSRV.sqlrpgle:100](../src/qrpglesrc/PRODSRV.sqlrpgle#L100))

Lists active products with optional type filter.

**Parameters:**
- `pProductType` (CHAR(3), const, optional) - Product type filter (IND/FAM/BUS)

**Returns:**
- `INT(10)` - Count of active products matching filter

**Logic:**
1. Check if parameter passed (%parms >= 1)
2. If no parameter, return all active products
3. If parameter provided, filter by PRODUCT_TYPE
4. Only returns products with STATUS = 'ACT'

**Use Cases:**
```rpg
// Get all active products
count = ListProducts();

// Get only individual products
count = ListProducts('IND');

// Get only business products
count = ListProducts('BUS');
```

**Note:** Current implementation returns count only. Enhancement would return actual product array/cursor.

---

### GetProductGuarantees

**Procedure:** `PRODSRV_GetProductGuarantees` ([PRODSRV.sqlrpgle:136](../src/qrpglesrc/PRODSRV.sqlrpgle#L136))

Gets count of active guarantees (coverage types) for a product.

**Parameters:**
- `pProductId` (DECIMAL(10,0), const) - Product ID

**Returns:**
- `INT(10)` - Count of active guarantees

**Logic:**
1. Query GUARANTEE table by PRODUCT_ID
2. Filter by STATUS = 'ACT'
3. Return count

**Use Case:**
Verify product has coverage types before allowing contract creation.

---

### CalculateBasePremium

**Procedure:** `PRODSRV_CalculateBasePremium` ([PRODSRV.sqlrpgle:164](../src/qrpglesrc/PRODSRV.sqlrpgle#L164))

Calculates total premium including vehicle surcharge.

**Parameters:**
- `pProductCode` (CHAR(10), const) - Product code
- `pVehiclesCount` (DECIMAL(2,0), const) - Number of vehicles to insure

**Returns:**
- `DECIMAL(9,2)` - Calculated premium amount (€)

**Error Codes:**
- `BUS010` - Product not found or inactive

**Business Logic:**

**Base Premium:**
Retrieved from PRODUCT.BASE_PREMIUM for active products.

**Vehicle Add-on:**
```rpg
dcl-c VEHICLE_ADDON 25.00;  // €25 per vehicle

totalPremium = basePremium + (vehiclesCount × €25)
```

**Examples:**
```
DAS Classic (€114) + 0 vehicles = €114
DAS Classic (€114) + 2 vehicles = €114 + €50 = €164
DAS Comfort (€396) + 3 vehicles = €396 + €75 = €471
```

**Business Context:**
Legal protection often covers vehicle-related disputes (traffic violations, insurance claims). Additional vehicles increase premium proportionally.

---

### IsProductAvailable

**Procedure:** `PRODSRV_IsProductAvailable` ([PRODSRV.sqlrpgle:205](../src/qrpglesrc/PRODSRV.sqlrpgle#L205))

Checks if product code exists and is active.

**Parameters:**
- `pProductCode` (CHAR(10), const) - Product code

**Returns:**
- `IND` - Available indicator (*ON = available, *OFF = not available)

**Logic:**
1. Count products matching code with STATUS = 'ACT'
2. Return *ON if count > 0, else *OFF

**Use Case:**
Pre-validation before contract creation to ensure product is sellable.

---

### HasGuarantee

**Procedure:** `PRODSRV_HasGuarantee` ([PRODSRV.sqlrpgle:233](../src/qrpglesrc/PRODSRV.sqlrpgle#L233))

Checks if a product includes a specific coverage type.

**Parameters:**
- `pProductId` (DECIMAL(10,0), const) - Product ID
- `pGuaranteeCode` (CHAR(10), const) - Guarantee code

**Returns:**
- `IND` - Has guarantee indicator (*ON = covered, *OFF = not covered)

**Logic:**
1. Count guarantees matching product ID + guarantee code
2. Filter by STATUS = 'ACT'
3. Return *ON if count > 0

**Use Case:**
Claim validation - verify customer's product covers the claim type.

**Example:**
```rpg
// Check if DAS Classic includes family law coverage
product = GetProductByCode(PROD_CLASSIC);
hasFamilyLaw = HasGuarantee(product.productId: GUAR_FAMILY);
// Returns *OFF (family law only in Benefisc products)
```

---

### GetGuaranteeWaitingPeriod

**Procedure:** `PRODSRV_GetGuaranteeWaitingPeriod` ([PRODSRV.sqlrpgle:263](../src/qrpglesrc/PRODSRV.sqlrpgle#L263))

Retrieves waiting period for a specific coverage type.

**Parameters:**
- `pProductId` (DECIMAL(10,0), const) - Product ID
- `pGuaranteeCode` (CHAR(10), const) - Guarantee code

**Returns:**
- `DECIMAL(2,0)` - Waiting period in months (default: 3 if not found)

**Logic:**
Uses SQL COALESCE to prioritize guarantee-specific waiting period over product default:

```sql
SELECT COALESCE(G.WAITING_MONTHS, P.WAITING_MONTHS)
FROM GUARANTEE G
JOIN PRODUCT P ON G.PRODUCT_ID = P.PRODUCT_ID
WHERE ...
```

**Fallback Strategy:**
1. Use guarantee-specific WAITING_MONTHS (if set)
2. If null, use product WAITING_MONTHS
3. If query fails, default to 3 months

**Use Case:**
Claim validation - determine if incident occurred during waiting period.

**Example:**
```rpg
// Family law typically has longer waiting period
waitingMonths = GetGuaranteeWaitingPeriod(productId: GUAR_FAMILY);
// Might return 12 months for family law vs 3 months for criminal defense
```

**Business Rules (DAS Belgium):**
- Basic coverage: 3 months waiting
- Family law: 12 months waiting
- Tax law: 6 months waiting
- Criminal defense: Immediate (0 months)

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
| DB001 | Product/guarantee not found | GetProduct/GetProductByCode (SQLCODE 100) |
| DB004 | Database operation failed | Any SQL error |
| BUS010 | Product not available | CalculateBasePremium |

### Error Recovery Strategy

**GetProduct/GetProductByCode:**
- Returns empty structure on error
- Check `productId = 0` to detect failure

**CalculateBasePremium:**
- Returns 0 on error
- BUS010 error code indicates invalid product

**IsProductAvailable/HasGuarantee:**
- Returns *OFF on error (fail-safe)
- Error logged but operation continues

**GetGuaranteeWaitingPeriod:**
- Returns default 3 months on error (safe fallback)
- Ensures claim processing continues

---

## Database Operations

### Read-Only Pattern

All procedures are SELECT-only - no INSERT/UPDATE/DELETE:

```rpg
exec sql
    SELECT ... INTO :dataStructure
    FROM PRODUCT
    WHERE ...;
```

**Rationale:**
Product catalog is reference data managed by:
- Database administrators via SQL DDL
- Product management via admin tools
- No runtime modification needed

### JOIN Pattern

GetGuaranteeWaitingPeriod uses JOIN + COALESCE for inheritance:

```sql
SELECT COALESCE(G.WAITING_MONTHS, P.WAITING_MONTHS)
FROM GUARANTEE G
JOIN PRODUCT P ON G.PRODUCT_ID = P.PRODUCT_ID
```

Allows guarantee-specific overrides while defaulting to product-level settings.

### Parameterized Optional WHERE

ListProducts uses optional parameter pattern:

```rpg
if %parms >= 1;
    productType = pProductType;
else;
    productType = '';
endif;

WHERE ... AND (:productType = '' OR PRODUCT_TYPE = :productType)
```

Empty parameter is ignored in WHERE clause, returning all types.

---

## Usage Examples

### Retrieve Product for Contract

```rpg
dcl-ds product likeds(Product_t);

// User selects "DAS Classic"
product = GetProductByCode(PROD_CLASSIC);

if product.productId > 0;
    dsply ('Premium: €' + %char(product.basePremium));
    dsply ('Coverage up to: €' + %char(product.coverageLimit));
endif;
```

### Calculate Premium with Vehicles

```rpg
dcl-s premium packed(9:2);

// DAS Classic + 2 vehicles
premium = CalculateBasePremium(PROD_CLASSIC: 2);
// Returns €164 (€114 base + €50 vehicle addon)
```

### Validate Product Before Contract

```rpg
dcl-s isAvailable ind;

isAvailable = IsProductAvailable('NEWPROD');

if isAvailable;
    // Proceed with contract creation
else;
    // Show error: "Product not available"
endif;
```

### Check Coverage for Claim

```rpg
dcl-ds product likeds(Product_t);
dcl-s hasCoverage ind;

product = GetProductByCode(PROD_CLASSIC);

// Can customer make family law claim?
hasCoverage = HasGuarantee(product.productId: GUAR_FAMILY);

if not hasCoverage;
    // Reject claim: "Not covered by your product"
endif;
```

### Verify Waiting Period

```rpg
dcl-s waitingMonths packed(2:0);
dcl-s contractStartDate date;
dcl-s incidentDate date;
dcl-s monthsActive packed(2:0);

waitingMonths = GetGuaranteeWaitingPeriod(productId: GUAR_TAX);

contractStartDate = %date('2024-01-01');
incidentDate = %date('2024-04-15');
monthsActive = 4;  // Simplified - real calculation more complex

if monthsActive < waitingMonths;
    // Reject claim: "Incident during waiting period"
endif;
```

### List Products by Type

```rpg
dcl-s count int(10);

// Get all active individual products
count = ListProducts('IND');
dsply ('Individual products: ' + %char(count));

// Get all products (any type)
count = ListProducts();
dsply ('Total products: ' + %char(count));
```

---

## Business Logic Details

### Product Types

**IND (Individual):**
- DAS Classic, Connect, Comfort
- Vie Privée, Consommateur
- Single person or family coverage

**FAM (Family):**
- Benefisc products with family law coverage
- Spouse/partner included
- Children covered

**BUS (Business):**
- Sur Mesure, FiscAssist
- SME legal protection
- Professional activity coverage

### Premium Calculation Logic

**Base Premium:**
Fixed annual amount per product (€114-€756).

**Vehicle Add-on:**
€25 per vehicle insured. Covers:
- Traffic violations
- Vehicle-related disputes
- Insurance claim disputes
- Purchase/sale conflicts

**No other modifiers:**
- No age-based pricing
- No claims history adjustment
- No regional variation

Real-world implementation might add:
- Multi-policy discount
- Broker commission rates
- Payment frequency adjustment (monthly vs annual)

### Waiting Period Hierarchy

**1. Guarantee-specific waiting:**
Some coverages have longer waiting periods.

**2. Product default waiting:**
If guarantee doesn't specify, use product default.

**3. System default:**
If all else fails, 3 months.

**DAS Belgium Typical Waiting Periods:**
- Criminal defense: 0 months (immediate)
- Civil recovery: 3 months
- Insurance disputes: 3 months
- Tax law: 6 months
- Family law: 12 months

### Coverage Availability Matrix

| Coverage | Classic | Connect | Comfort | Benefisc |
|----------|---------|---------|---------|----------|
| Civil recovery | ✓ | ✓ | ✓ | ✓ |
| Criminal defense | ✓ | ✓ | ✓ | ✓ |
| Insurance disputes | ✓ | ✓ | ✓ | ✓ |
| Medical malpractice | ✓ | ✓ | ✓ | ✓ |
| Neighborhood | ✓ | ✓ | ✓ | ✓ |
| Family law | - | - | - | ✓ |
| Tax law | - | - | - | ✓ |
| Employment law | - | - | - | ✓ |
| Succession | - | - | - | ✓ |
| Administrative | - | - | - | ✓ |

---

## Development Notes

### Dependencies

**Internal:**
- `ERRUTIL.rpgle` - Error handling utility
- `PRODSRV_H.rpgle` - Copybook (data structures, prototypes, constants)

**External:**
- PRODUCT table (must exist with seed data)
- GUARANTEE table (must exist with seed data)
- SQL environment configured

### Build Instructions

```bash
# Compile service module
CRTSQLRPGI OBJ(YOURLIB/PRODSRV) SRCFILE(QRPGLESRC) COMMIT(*NONE) OBJTYPE(*MODULE)

# Create service program
CRTSRVPGM SRVPGM(YOURLIB/PRODSRV) MODULE(YOURLIB/PRODSRV) EXPORT(*ALL)
```

### Data Initialization

**Critical:** Product catalog must be seeded before use:

```sql
-- Insert DAS products (example)
INSERT INTO PRODUCT (PRODUCT_CODE, PRODUCT_NAME, PRODUCT_TYPE, BASE_PREMIUM, ...)
VALUES ('CLASSIC', 'DAS Classic', 'IND', 114.00, ...);

-- Insert guarantees (example)
INSERT INTO GUARANTEE (PRODUCT_ID, GUARANTEE_CODE, GUARANTEE_NAME, ...)
VALUES (1, 'CIV_RECOV', 'Civil Recovery', ...);
```

See [implementation-plan.md](../implementation-plan.md) for complete seed data.

### Testing Considerations

**Unit Test Cases:**

**Product Retrieval:**
1. GetProduct with valid ID
2. GetProduct with invalid ID (DB001)
3. GetProductByCode with valid code
4. GetProductByCode with invalid code
5. GetProductByCode with each constant (PROD_CLASSIC, etc.)

**Product Listing:**
6. ListProducts with no parameter (all types)
7. ListProducts('IND')
8. ListProducts('BUS')
9. ListProducts with invalid type (should return 0)

**Premium Calculation:**
10. CalculateBasePremium with 0 vehicles
11. CalculateBasePremium with 1 vehicle
12. CalculateBasePremium with 5 vehicles
13. CalculateBasePremium with invalid product (BUS010)

**Guarantee Operations:**
14. GetProductGuarantees for product with guarantees
15. GetProductGuarantees for product without guarantees
16. HasGuarantee - positive case
17. HasGuarantee - negative case
18. GetGuaranteeWaitingPeriod - guarantee-specific
19. GetGuaranteeWaitingPeriod - product default
20. GetGuaranteeWaitingPeriod - fallback to 3 months

**Availability:**
21. IsProductAvailable - active product
22. IsProductAvailable - inactive product
23. IsProductAvailable - non-existent product

**Integration Tests:**
- Contract creation using product lookup
- Claim validation using guarantee checks
- Premium calculation in full contract flow

### Future Enhancements

1. **Return result sets:** ListProducts/GetProductGuarantees return actual records via arrays/cursors
2. **Advanced pricing:**
   - Multi-policy discount
   - Age-based pricing for individuals
   - Industry-based pricing for businesses
   - Broker commission calculation
3. **Coverage comparison:** Side-by-side product feature matrix
4. **Personalized recommendations:** Suggest products based on customer profile
5. **Pricing history:** Track premium changes over time
6. **Seasonal promotions:** Temporary pricing adjustments
7. **Product bundles:** Combined home + vehicle legal protection
8. **Coverage simulation:** "What if" scenarios for coverage changes

### Performance Considerations

**Caching Opportunity:**
Product catalog changes infrequently. Consider:
- In-memory product cache (user space or data area)
- Cache invalidation on product updates
- Significant performance improvement for high-volume contract creation

**Index Strategy:**
Ensure indexes exist on:
- PRODUCT.PRODUCT_CODE (unique)
- PRODUCT.STATUS
- GUARANTEE.PRODUCT_ID + GUARANTEE_CODE
- GUARANTEE.STATUS

---

## Version History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2025-12-05 | Claude | Initial implementation |

---

**Related Documentation:**
- [Implementation Plan](../implementation-plan.md)
- [PRODUCT Table DDL](../../sql/PRODUCT.sql)
- [GUARANTEE Table DDL](../../sql/GUARANTEE.sql)
- [CONTSRV Module](CONTSRV.md) - Contract service (uses products)
- [CLAIMSRV Module](CLAIMSRV.md) - Claim service (uses guarantees)

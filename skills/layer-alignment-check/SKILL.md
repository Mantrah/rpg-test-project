---
name: layer-alignment-check
description: Verify alignment between all layers of a multi-tier architecture (UI, API, Backend) for a given entity.
---

# Layer Alignment Check Skill

Systematically verify that all layers of a multi-tier architecture are properly aligned for a given entity (Customer, Broker, Contract, etc.).

**Target Architecture:** React UI -> Node.js API -> iToolkit/XMLSERVICE -> RPG Wrapper -> RPG Business Service -> DB2

## IMPORTANT: Mandatory Post-Fix Verification

**This skill MUST be used after EVERY code fix or modification** to ensure changes don't break alignment between layers.

After making any fix:
1. Identify which entity was affected
2. Run a full layer alignment check for that entity
3. Verify the fix didn't introduce new misalignments
4. Document any cascading changes needed

## When to Use

- Before deploying changes to production
- After adding new functionality to any layer
- When debugging "function not found" or parameter mismatch errors
- As part of code review for new features

## Architecture Layers (This Project)

| Layer | Location | Technology |
|-------|----------|------------|
| 1. UI Components | `ui/src/pages/` | React JSX |
| 2. API Service | `ui/src/services/api.js` | Axios |
| 3. Routes | `api/src/routes/` | Express Router |
| 4. Controllers | `api/src/controllers/` | Express Handlers |
| 5. RPG Connector | `api/src/config/rpgConnector.js` | iToolkit calls |
| 6. RPG Wrapper | `src/qrpglesrc/RPGWRAP.sqlrpgle` | WRAP_* procedures |
| 7. Business Service | `src/qrpglesrc/*SRV.sqlrpgle` | *SRV_* procedures |

## Verification Process

### Step 1: Identify Entity Operations

For the entity being verified, list all expected CRUD+ operations:

```
Standard Operations:
- List (get all with optional filters)
- GetById (get single by ID)
- Create (insert new)
- Update (modify existing)
- Delete (remove or soft-delete)

Entity-Specific Operations:
- GetByEmail, GetByCode, etc.
- GetRelated (e.g., GetCustomerContracts)
- Validate, Calculate, etc.
```

### Step 2: Trace Each Operation Through All Layers

For each operation, verify it exists in ALL layers:

```
Operation: deleteCustomer

Layer 1 (UI):        CustomerList.jsx -> deleteMutation -> customerApi.delete
Layer 2 (API.js):    customerApi.delete = (id) => api.delete(`/customers/${id}`)
Layer 3 (Routes):    router.delete('/:id', customerController.deleteCustomer)
Layer 4 (Controller): deleteCustomer -> rpgConnector.deleteCustomer(custId)
Layer 5 (Connector): deleteCustomer -> callRpg('WRAP_DELETECUSTOMER', params)
Layer 6 (RPGWRAP):   WRAP_DeleteCustomer -> CUSTSRV_DeleteCustomer(pCustId)
Layer 7 (Service):   CUSTSRV_DeleteCustomer (actual SQL)
```

### Step 3: Verify Parameter Alignment

For each operation, compare parameters across layers:

```
Focus on:
- Parameter COUNT (same number in each layer)
- Parameter NAMES (consistent naming)
- Parameter TYPES (especially dates, numbers, VARCHAR)
- Parameter ORDER (must match between rpgConnector and RPGWRAP)
```

#### Critical Type Mappings (iToolkit <-> RPG)

| Node.js (iToolkit) | RPG | Notes |
|--------------------|-----|-------|
| `'10p0'` | `packed(10:0)` | Integers |
| `'9p2'` | `packed(9:2)` | Decimals |
| `'10a'` | `char(10)` | Fixed char |
| `'50a'` | `char(50)` | Fixed char |
| `'32000a', varying: 2` | `varchar(32000)` | VARCHAR with 2-byte length |
| `'10a'` | `char(10)` | **DATES - Never use 'date' type!** |

#### OUT Parameters Requirements

All OUT parameters in rpgConnector MUST have initial `value`:
```javascript
// CORRECT
{ name: 'oSuccess', type: '1a', value: '', io: 'out' }
{ name: 'oCount', type: '10p0', value: 0, io: 'out' }

// WRONG - will send "undefined" string to RPG
{ name: 'oSuccess', type: '1a', io: 'out' }
```

### Step 4: Generate Alignment Report

Create a matrix showing presence/absence in each layer:

```markdown
| Operation | UI | API.js | Route | Controller | Connector | WRAP | Service |
|-----------|:--:|:------:|:-----:|:----------:|:---------:|:----:|:-------:|
| List      | ?  | ?      | ?     | ?          | ?         | ?    | ?       |
| GetById   | ?  | ?      | ?     | ?          | ?         | ?    | ?       |
| Create    | ?  | ?      | ?     | ?          | ?         | ?    | ?       |
| Delete    | ?  | ?      | ?     | ?          | ?         | ?    | ?       |
```

Use:
- ✅ = Present and correct
- ⚠️ = Present but has issues (document in findings)
- ❌ = Missing (CRITICAL)

### Step 5: Document Findings

For each issue found, document:

```markdown
#### Issue: [Short description]
- **Severity**: CRITICAL / BUG / MINOR
- **Layer**: [Which layer has the problem]
- **File**: [Exact file path]
- **Line**: [Line number if applicable]
- **Impact**: [What will fail]
- **Fix**: [How to resolve]
```

## Common Issues to Check

### Missing Procedures
- rpgConnector calls `WRAP_X` but RPGWRAP doesn't have it
- RPGWRAP calls `SRV_X` but Service doesn't have it

### Parameter Mismatches
- Different number of parameters between layers
- Wrong order of parameters (RPG is positional!)
- Type mismatches (especially dates)

### Date Handling
- **NEVER** use `'date'` type in iToolkit
- **ALWAYS** use `'10a'` (char(10)) for dates
- RPG side: `char(10)` with `%date()` / `%char()` conversion

### VARCHAR Output
- Must have `varying: 2` in rpgConnector for VARCHAR params
- Must strip leading bytes before JSON.parse:
  ```javascript
  const firstBracket = jsonData.indexOf('[');
  if (firstBracket > 0) jsonData = jsonData.substring(firstBracket);
  ```

### Missing Initial Values
- All OUT params need `value` property
- Numeric: `value: 0`
- Character: `value: ''`

## Execution Checklist

```markdown
## Layer Alignment Check: [Entity Name]

### Operations Matrix
| Operation | UI | API | Route | Ctrl | Conn | WRAP | SRV |
|-----------|:--:|:---:|:-----:|:----:|:----:|:----:|:---:|
| List      |    |     |       |      |      |      |     |
| GetById   |    |     |       |      |      |      |     |
| Create    |    |     |       |      |      |      |     |
| Update    |    |     |       |      |      |      |     |
| Delete    |    |     |       |      |      |      |     |

### Parameter Checks
- [ ] All OUT params have initial value
- [ ] Dates use '10a' not 'date'
- [ ] VARCHAR has varying: 2
- [ ] Parameter order matches between Connector and WRAP

### Findings
[List issues here]

### Recommended Fixes
[Priority-ordered list of fixes]
```

## Tips

1. **Start from the UI** - trace what the user can actually do
2. **Use grep/search** to find all references to procedure names
3. **Compare line by line** for parameter definitions
4. **Check both directions** - UI->Backend AND Backend->UI
5. **Don't assume** - read the actual code, don't rely on memory

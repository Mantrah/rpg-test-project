# Technical Fixes & Known Issues

This document tracks important fixes applied to the DAS Belgium system to prevent future regressions.

## Table of Contents

1. [iToolkit Date Parameter Fix](#1-itoolkit-date-parameter-fix)
2. [VARCHAR JSON Corruption Fix](#2-varchar-json-corruption-fix)
3. [iToolkit VARCHAR Output Fix](#3-itoolkit-varchar-output-fix)
4. [UI API Port Mismatch](#4-ui-api-port-mismatch)
5. [iToolkit OUT Parameter Initial Values](#5-itoolkit-out-parameter-initial-values)

---

## 1. iToolkit Date Parameter Fix

**Problem**: iToolkit/XMLSERVICE cannot properly serialize JavaScript date strings to RPG native `date` type. The date value gets corrupted (e.g., `60F1F260F0F80000` EBCDIC instead of proper date).

**Symptom**: Contract creation fails with cryptic errors when passing date parameters.

**Files Affected**:
- `api/src/config/rpgConnector.js` - createContract function
- `src/qrpglesrc/RPGWRAP.sqlrpgle` - WRAP_CreateContract procedure

**Fix Applied**:

### In rpgConnector.js (Node.js side):
```javascript
// WRONG - iToolkit can't handle 'date' type
{ name: 'pStartDate', type: 'date', value: contractData.startDate, io: 'in' }

// CORRECT - Pass as char(10) ISO format string
{ name: 'pStartDate', type: '10a', value: contractData.startDate || '', io: 'in' }
```

### In RPGWRAP.sqlrpgle (RPG side):
```rpgle
// WRONG - RPG date type
dcl-pi *n;
    pStartDate      date const;
    ...
end-pi;
contract.startDate = pStartDate;

// CORRECT - char(10) with conversion
dcl-pi *n;
    pStartDate      char(10) const;
    ...
end-pi;
// Convert ISO date string to RPG date
contract.startDate = %date(%trim(pStartDate):*iso);
```

**Rule**: Always pass dates as `char(10)` (ISO format `YYYY-MM-DD`) through iToolkit and convert in RPG using `%date(%trim(value):*iso)`.

---

## 2. VARCHAR JSON Corruption Fix

**Problem**: When RPG returns VARCHAR data containing JSON arrays, the brackets `[{` and `}]` and separators `},{` get corrupted into non-printable characters (e.g., `��`). This happens inconsistently - BROKRSRV returns clean JSON but CUSTSRV/PRODSRV return corrupted JSON.

**Symptom**:
- API logs show: `[RPG] Failed to parse customer JSON: SyntaxError: Unexpected token � in JSON at position 0`
- Raw data looks like: `��"CUST_ID":7,...�,�"CUST_ID":5,...��` instead of `[{"CUST_ID":7,...},{"CUST_ID":5,...}]`

**Files Affected**:
- `api/src/config/rpgConnector.js` - listCustomers, listProducts functions

**Fix Applied**:

```javascript
// In listCustomers and listProducts functions:
try {
  let jsonData = result.oJsonData || '[]';

  // Find first bracket (array or object)
  const firstBracket = jsonData.indexOf('[');

  if (firstBracket >= 0) {
    // Normal case - clean JSON with brackets
    jsonData = jsonData.substring(firstBracket);
  } else {
    // Corrupted case - no brackets, need to reconstruct
    const firstQuote = jsonData.indexOf('"');
    if (firstQuote >= 0) {
      jsonData = jsonData.substring(firstQuote);
      // Replace corrupted separators between objects
      // Pattern: "ACT"[non-printable],[non-printable]"CUST_ID" -> "ACT"},{"CUST_ID"
      // IMPORTANT: Use + (at least ONE) not * (zero or more) to avoid matching normal commas
      jsonData = jsonData.replace(/"[\x00-\x1f\x7f-\xff]+,[\x00-\x1f\x7f-\xff]*"/g, '"},{"');
      jsonData = jsonData.replace(/"[\x00-\x1f\x7f-\xff]*,[\x00-\x1f\x7f-\xff]+"/g, '"},{"');
      // Remove trailing garbage
      const lastQuote = jsonData.lastIndexOf('"');
      if (lastQuote >= 0) {
        jsonData = jsonData.substring(0, lastQuote + 1);
      }
      // Wrap in proper array/object brackets
      jsonData = '[{' + jsonData + '}]';
    }
  }

  return JSON.parse(jsonData);
} catch (e) {
  console.error('[RPG] Failed to parse JSON:', e);
  return [];
}
```

**Root Cause**: Unknown - possibly related to VARCHAR length prefix bytes (2-byte prefix for varying:2) or CCSID conversion issues between RPG and iToolkit. The BROKRSRV module (which works) delegates to a dedicated JSON function, while CUSTSRV/PRODSRV build JSON inline.

**Long-term Fix**: Refactor CUSTSRV and PRODSRV to use dedicated `*_ListJson` procedures like BROKRSRV does with `BROKRSRV_ListBrokersJson`.

---

## 3. iToolkit VARCHAR Output Fix

**Problem**: When retrieving VARCHAR data from RPG via iToolkit, the first bytes may contain length prefix or control characters that corrupt JSON parsing.

**Files Affected**:
- `api/src/config/rpgConnector.js` - All functions returning JSON arrays

**Fix Applied** (documented in CLAUDE.md):

```javascript
// Strip leading control bytes before JSON.parse
const firstBracket = jsonData.indexOf('[');
if (firstBracket > 0) {
  jsonData = jsonData.substring(firstBracket);
}
```

**Note**: This is a simpler version of Fix #2, used when the JSON is mostly intact but has leading garbage bytes.

---

## 4. UI API Port Mismatch

**Problem**: The React UI calls the wrong API port because the `.env.local` file contains an outdated port number. The API port may change when restarting the Node.js server on IBM i (especially when previous job wasn't properly terminated).

**Symptom**:
- UI shows "0 clients enregistrés" or empty lists
- `curl http://localhost:8086/api/customers` returns data correctly
- Browser DevTools Network tab shows failed requests or requests to wrong port
- No errors in UI (data appears empty, not errored)

**Files Affected**:
- `ui/.env.local` - Contains `VITE_API_BASE_URL`
- `ui/src/services/api.js` - Uses the environment variable

**Fix Applied**:

```bash
# In ui/.env.local - ensure port matches the running API
VITE_API_BASE_URL=http://localhost:8086/api
```

**Important**: After changing `.env.local`, you MUST restart Vite dev server:
```bash
# Kill existing Vite process and restart
cd ui && npm run dev
```

**Prevention**:
1. Always check API startup message for actual port: `🚀 Server running on port XXXX`
2. Verify `.env.local` matches before testing UI
3. When API port changes, update both:
   - `ui/.env.local` (for development)
   - Any production environment variables

**Quick Diagnostic**:
```bash
# Check what port API is running on
curl http://localhost:8086/health

# Check what port UI is configured for
cat ui/.env.local
```

---

## 5. iToolkit OUT Parameter Initial Values

**Problem**: When iToolkit parameters have `io: 'out'` but no `value` property, JavaScript sends the literal string "undefined" to XMLSERVICE. This causes XML parsing errors on the IBM i side.

**Symptom**:
- API logs show XML errors like: `<data type='10p0' name='oContId'>undefined</data>`
- Error code `1100017` - "XML copy in data"
- Contract/premium calculations fail with cryptic errors

**Files Affected**:
- `api/src/config/rpgConnector.js` - createContract, calculatePremium functions

**Fix Applied**:

```javascript
// WRONG - No value property means JavaScript sends "undefined"
{ name: 'oContId', type: '10p0', io: 'out' }

// CORRECT - Always provide initial value for OUT parameters
{ name: 'oContId', type: '10p0', value: 0, io: 'out' }      // numeric
{ name: 'oSuccess', type: '1a', value: '', io: 'out' }      // character
{ name: 'oReference', type: '25a', value: '', io: 'out' }   // character
```

**Rule**: ALL OUT parameters MUST have a `value` property:
- Numeric types (`Xp0`, `Xp2`): use `value: 0`
- Character types (`Xa`): use `value: ''`

**Example - createContract fix**:
```javascript
const params = [
  // IN parameters
  { name: 'pCustId', type: '10p0', value: contractData.custId, io: 'in' },
  // ...

  // OUT parameters - MUST have value property
  { name: 'oContId', type: '10p0', value: 0, io: 'out' },
  { name: 'oContReference', type: '25a', value: '', io: 'out' },
  { name: 'oTotalPremium', type: '9p2', value: 0, io: 'out' },
  { name: 'oSuccess', type: '1a', value: '', io: 'out' },
  { name: 'oErrorCode', type: '10a', value: '', io: 'out' }
];
```

---

## Deployment Checklist

When modifying iToolkit calls or RPG procedures:

1. **Date parameters**: Use `type: '10a'` in JS, `char(10) const` in RPG
2. **VARCHAR output**: Always include JSON cleanup code before `JSON.parse()`
3. **OUT parameters**: Always provide `value: 0` (numeric) or `value: ''` (char) for OUT params
4. **Test both brokers AND customers**: They use different code paths
5. **Check API logs**: Look for `[RPG] Failed to parse` or `undefined` errors
6. **Restart API after changes**: Kill existing node process on IBM i before restart
7. **Verify API port**: Check `ui/.env.local` matches actual API port after restart

---

## Related Files

- `CLAUDE.md` - Project coding standards and architecture notes
- `api/src/config/rpgConnector.js` - iToolkit integration layer
- `src/qrpglesrc/RPGWRAP.sqlrpgle` - RPG wrapper procedures

# MATHCALC - Mathematical Calculation Service

## Overview

Service module providing mathematical calculation utilities for RPG applications on IBM i V7R5.

**Purpose:** Centralized calculation procedures with error handling and validation

**Key Features:**
- Safe arithmetic operations with overflow protection
- ERRUTIL integration for error management
- Input validation
- Reusable calculation procedures

## Architecture

### Design Pattern

This is a stateless service module that provides calculation utilities without maintaining state between calls.

```mermaid
flowchart LR
    A[Caller Program] --> B[MATHCALC Service]
    B --> C[Validation]
    C --> D[Calculation]
    D --> E[Return Result]
    C --> F[ERRUTIL Error]
```

## Technical Specifications

### Control Options

```rpg
ctl-opt dftactgrp(*no) actgrp(*new);
ctl-opt option(*srcstmt:*nodebugio);
ctl-opt nomain;
```

- **Activation Group:** `*new` - Each call gets fresh activation
- **Debug:** Source statement support enabled
- **Module Type:** Service module (nomain)

### Dependencies

```rpg
/copy qrpglesrc/ERRUTIL
```

- **ERRUTIL:** Error handling utility for all error management

### Constants

```rpg
dcl-c MAX_VALUE 999999999.99;
dcl-c MIN_VALUE -999999999.99;
```

## Procedures Reference

### MATHCALC_calculateTotal

Calculate order total with tax applied.

**Purpose:** Compute total amount including tax for financial calculations

**Parameters:**
- `subtotal` (packed 15:2, const) - Base amount before tax
- `taxRate` (packed 5:3, const) - Tax rate as decimal (e.g., 0.075 for 7.5%)

**Returns:**
- `packed(15:2)` - Total amount with tax applied
- Returns `0` on error (negative values, overflow)

**Error Handling:**
- **MATH001** - Invalid input (negative subtotal or tax rate)
- Uses `ERRUTIL_addExecutionError()` for unexpected errors
- Returns 0 on any error condition

**Example Usage:**
```rpg
dcl-s orderTotal packed(15:2);
dcl-s subtotal packed(15:2) inz(100.00);
dcl-s taxRate packed(5:3) inz(0.075);

orderTotal = MATHCALC_calculateTotal(subtotal: taxRate);
// Result: 107.50
```

**Implementation Notes:**
- Validates both parameters are non-negative
- Uses monitor/on-error for overflow protection
- Returns safe default (0) rather than invalid values

### MATHCALC_calculateDiscount

Calculate discount amount based on percentage.

**Purpose:** Compute discount amount for pricing calculations

**Parameters:**
- `amount` (packed 15:2, const) - Original amount
- `discountPct` (packed 5:2, const) - Discount percentage (e.g., 10 for 10%)

**Returns:**
- `packed(15:2)` - Discount amount to subtract
- Returns `0` on error

**Error Handling:**
- **MATH002** - Invalid percentage (negative or > 100)
- **MATH003** - Invalid amount (negative)

**Example Usage:**
```rpg
dcl-s discount packed(15:2);
dcl-s price packed(15:2) inz(200.00);
dcl-s discountPct packed(5:2) inz(15);

discount = MATHCALC_calculateDiscount(price: discountPct);
// Result: 30.00 (15% of 200)
```

## Error Handling

### Error Management Strategy

All errors are managed through **ERRUTIL** - no indicator parameters are used.

**Error Codes:**

| Code | Description | Recovery |
|------|-------------|----------|
| MATH001 | Invalid input to calculateTotal | Validate parameters before calling |
| MATH002 | Invalid discount percentage | Ensure 0 <= percentage <= 100 |
| MATH003 | Invalid amount | Ensure positive amounts |

**Error Flow:**
```rpg
monitor;
  // Initialization
  result = 0;

  // Validation
  if subtotal < 0;
    ERRUTIL_addErrorCode('MATH001');
    return 0;  // Safe default
  endif;

  // Business logic
  result = subtotal * (1 + taxRate);

on-error;
  ERRUTIL_addExecutionError();
  return 0;  // Safe default
endmon;
```

## Usage Examples

### Basic Calculation

```rpg
**free
dcl-pr MATHCALC_calculateTotal packed(15:2);
  subtotal packed(15:2) const;
  taxRate packed(5:3) const;
end-pr;

dcl-s finalAmount packed(15:2);
dcl-s orderSubtotal packed(15:2) inz(250.00);
dcl-s salesTax packed(5:3) inz(0.0875);

// Calculate total with 8.75% tax
finalAmount = MATHCALC_calculateTotal(orderSubtotal: salesTax);
// Result: 271.88
```

### With Error Checking

```rpg
**free
dcl-s total packed(15:2);
dcl-s subtotal packed(15:2);

// ... get subtotal from user input ...

total = MATHCALC_calculateTotal(subtotal: 0.075);

if total = 0;
  // Check ERRUTIL for error details
  // Handle error condition
  dsply 'Calculation failed - check error log';
else;
  dsply ('Total: ' + %char(total));
endif;
```

## Development Notes

### Build Instructions

```bash
# Compile the module
CRTRPGMOD MODULE(YOURLIB/MATHCALC) SRCFILE(QRPGLESRC) DBGVIEW(*LIST)

# Create service program
CRTSRVPGM SRVPGM(YOURLIB/MATHCALC) MODULE(YOURLIB/MATHCALC) EXPORT(*ALL)
```

### Testing

Create test program that calls each procedure with:
- Valid inputs
- Boundary values (zero, max, min)
- Invalid inputs (negative, overflow)
- Edge cases

### Dependencies

- **ERRUTIL** module must be available
- Service program must be in library list of calling programs

### Known Limitations

1. Maximum values limited by packed(15:2) - MAX_VALUE constant
2. Tax rates assume decimal format (0.075 = 7.5%)
3. No support for compound tax calculations
4. Returns 0 on errors - caller must check ERRUTIL if distinction needed

### Performance Considerations

- Stateless design - no performance penalty for multiple calls
- All calculations in-memory - no I/O operations
- Minimal overhead from ERRUTIL (only on errors)

## Integration

### Calling from Other Programs

```rpg
**free
ctl-opt bnddir('YOURLIB/MATHCALC');

dcl-pr MATHCALC_calculateTotal packed(15:2);
  subtotal packed(15:2) const;
  taxRate packed(5:3) const;
end-pr;

// Use the procedure
total = MATHCALC_calculateTotal(100.00: 0.075);
```

### Service Program Binding

Add to binding directory:
```bash
ADDBNDDIRE BNDDIR(YOURLIB/UTILITIES) OBJ((MATHCALC))
```

## Version History

- **v1.0** - Initial release with calculateTotal and calculateDiscount
- **v1.1** - Added ERRUTIL integration
- **v1.2** - Enhanced validation and error codes

## Maintainer

See project README for contact information.

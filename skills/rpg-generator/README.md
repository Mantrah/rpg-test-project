# RPG Code Generator Skill

Generates modern, production-ready RPG ILE code following enterprise standards.

**Target System: IBM i V7R5**

## Features

- **Modern RPG:** Free-format, qualified DS, SQL, built-in functions
- **Smart Error Handling:** Detects and uses project-specific error utilities (ERRUTIL standard or custom)
- **Naming Conventions:** camelCase variables, PascalCase procedures, UPPER_SNAKE constants
- **JSON Support:** YAJL parsing/generation for APIs
- **Transaction Control:** COMMIT/ROLLBACK patterns

## Error Handling Discovery

**Before generating code, the skill:**
1. Checks project documentation for existing error handling system
2. Searches existing RPG code for `/copy` references (ERRUTIL, ERRORUTIL, custom utilities)
3. Uses discovered system or asks user if none found (defaults to ERRUTIL standard)

**Adapts to your project's error handling patterns** - no manual configuration needed.

## Generated Structure

**All programs include:**
- Control options (`dftactgrp(*no)`, `actgrp(*new)`)
- Appropriate error handling `/copy` (project-specific or ERRUTIL)
- Procedure documentation headers
- Monitor blocks with standard sections (Initialization, Validation, Business logic)
- Safe return values on errors

**Program types:**
- **Batch:** File processing, logging, transaction control
- **API/REST:** JSON (YAJL), HTTP status codes, request/response DS

## Requirements

- IBM i V7R5
- `/copy qrpglesrc/ERRUTIL` (or update procedure names: `ERRUTIL_addErrorCode`, `ERRUTIL_addErrorMessage`, `ERRUTIL_addExecutionError`)
- YAJL binding directory (for JSON)

## Usage Examples

### Basic
```bash
/rpg-generator create a batch program that reads customer orders and calculates totals
```

### REST API
```bash
/rpg-generator make a REST API endpoint that returns product information as JSON
```

### With Context
```bash
Generate RPG service module for order validation based on /docs/business/order-rules.md
```

## Limitations

**Testing:** This skill does not generate unit tests or test programs. Testing is not currently in scope.

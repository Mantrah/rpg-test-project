# RPG Program Documentation Generator

Generates comprehensive markdown documentation for RPG ILE programs by analyzing code structure, business logic, and existing documentation.

**Target System: IBM i V7R5**

## Features

- **Context-Aware:** Reads README and `/docs/` to match project style
- **Comprehensive:** Extracts procedures, data structures, error handling, business logic
- **RPG-Specific:** Understands YAJL, ERRUTIL, IBM i patterns
- **Structured Output:** Standardized sections with optional Mermaid diagrams

## What It Documents

**Code Structure:**
- Control options, binding directories
- Files, global variables, constants
- Data structures with field descriptions

**Procedures:**
- Purpose, parameters (with types), return values
- Error handling (ERRUTIL), usage examples

**Business Logic:**
- Architecture, data flow, integration points
- Transaction control

**Error Handling:**
- ERRUTIL integration, error codes, recovery strategies

**JSON/API (if applicable):**
- Request/response formats, YAJL, endpoint documentation

## Default Output

**Location:** `/docs/program/{programName}.md`

**For refactoring** (output to `/refactor/`):
Adds: Current implementation analysis, refactoring plan, migration notes

## Standard Sections

1. Program Overview (purpose, features)
2. Architecture (design, components, data flow)
3. Technical Specifications (control options, files, DS)
4. Procedures Reference (detailed documentation)
5. Error Handling (ERRUTIL, error codes)
6. JSON/API Documentation (if applicable)
7. Database Operations (tables, SQL, transactions)
8. Usage Examples (call syntax)
9. Development Notes (dependencies, build, testing)

## Usage Examples

### Basic
```bash
/document-rpg-program ORDERSRV.rpgle
```

### Custom Output
```bash
Generate documentation for CUSTSRV.rpgle and save to /docs/api/customer-service.md
```

### Focused
```bash
Document the API endpoints and JSON handling in ORDERSRV.rpgle
```

## Requirements

- RPG source code
- Project README.md (recommended for context and style)
- `/docs/` folder (optional, helps match existing documentation style)

## Supported Frameworks

- YAJL (JSON), ERRUTIL (error handling), HTTPAPI (HTTP/REST), Embedded SQL

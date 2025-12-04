---
name: rpg-generator
description: Generate modern RPG ILE code following enterprise standards for batch programs and REST APIs on IBM i V7R5.
---

# RPG Code Generator Skill

Generate modern RPG ILE code following enterprise standards and best practices for batch programs and REST APIs.

**Target System: IBM i V7R5**

## Standards

### Naming Conventions

- **Variables:** camelCase with type prefix
- **Data Structures:** PascalCase, qualified
- **Procedures:** PascalCase with descriptive verb indicating action AND return type
  - Returns indicator: prefix with "is", "has", "can"
  - Returns value: use "calculate", "compute", "get"
  - Performs action: use action verb
- **Constants:** UPPER_SNAKE_CASE
- **Files:** PascalCase for logical, UPPERCASE for physical

### Code Structure

- **Always use full free-format RPG** (`**free`)
- **Control options:**
  - `ctl-opt dftactgrp(*no) actgrp(*new);`
  - `ctl-opt option(*srcstmt:*nodebugio);`
  - `ctl-opt bnddir('...');` as needed
- **Error handling:** Always use MONITOR/ON-ERROR
- **Monitor block comments:** Always organize with standard sections:
  - `// Initialization` - Variable setup
  - `// Validation` - Input validation and error checking
  - `// Business logic` - Main processing (or Step 1, Step 2, etc. for complex processes)

### Procedure Documentation

Always include header comments:
```
//==============================================================
// ProcedureName : Brief description
//
//  Returns: Description of return value
//
//==============================================================
```

## Error Handling - CRITICAL

### Step 1: Discover Error Handling System

**BEFORE generating code, check for existing error handling system:**

1. **Read project documentation** (`README.md`, `/docs/architecture/`, `/docs/`)
2. **Search for error handling utilities:**
   - Look for `/copy` references in existing RPG code
   - Check for error utility modules (ERRUTIL, ERRORUTIL, APPERROR, etc.)
   - Identify error handling procedures (SetError, AddError, GetErrorMsg, etc.)

3. **Determine error handling approach:**
   - **If project-specific utility found:** Use it (adapt procedure names, copy path)
   - **If ERRUTIL found:** Use ERRUTIL (standard)
   - **If no utility found:** Ask user which to use (ERRUTIL default or custom)

### Step 2: Apply Error Handling

**Requirements (adapt to discovered system):**
- Include appropriate `/copy` at top of every program
- Use error code procedure for known/expected errors (e.g., `ERRUTIL_addErrorCode('CODE')`)
- Use error message procedure for errors without predefined codes
- Use execution error procedure in EVERY `on-error` block (e.g., `ERRUTIL_addExecutionError()`)
- Return safe default values (0, empty string, empty DS) on errors
- **Never use indicator parameters for error handling**

**ERRUTIL Standard (if used):**
- `/copy qrpglesrc/ERRUTIL`
- `ERRUTIL_addErrorCode('CODE')` - known errors
- `ERRUTIL_addErrorMessage('msg')` - dynamic errors
- `ERRUTIL_addExecutionError()` - in ON-ERROR blocks

## Program Types

### Batch Programs

Include:
- Parameter handling
- File processing with error handling
- Logging capability
- Transaction control (COMMIT/ROLLBACK)
- Proper program termination

### API Programs

Include:
- Request/Response data structures
- JSON parsing with YAJL (data-into/data-gen)
- HTTP status code handling
- Input validation
- Error response formatting
- Content-Type headers

## Code Generation Workflow

1. **Program Header** - Name, description, control options
2. **Copy Members** - Appropriate error handling `/copy` (discovered or ERRUTIL)
3. **Data Structures** - Qualified, PascalCase
4. **Procedures** - Each with:
   - Naming: verb + return type indication
   - Header documentation (//=== format)
   - Monitor block with standard comments
   - Error handling (discovered system)
   - Safe return values
5. **Modern Features** - SQL, %TRIM, %CHAR, %DATE, etc.
6. **Transaction Control** - COMMIT/ROLLBACK where needed
7. **Constants** - No magic numbers

## Procedure Design

- **Single Responsibility** - One function per procedure
- **Return Values** - Return computed value, not indicators
- **Error Handling** - Use discovered error system, return safe defaults
- **Validate First** - Check inputs before processing
- **CONST Parameters** - For read-only params

## Post-Generation Validation

**After code generation, launch parallel agents to verify compilation readiness:**

For each procedure generated, validate:
- [ ] No missing variables (all referenced variables are declared)
- [ ] No unused variables (all declared variables are used)
- [ ] No missing parameters (all procedure calls have correct params)
- [ ] Correct RPG ILE free-format syntax
- [ ] Proper data type usage (no type mismatches)
- [ ] Valid embedded SQL syntax (if applicable)

**Implementation:**
```
Launch Task agents in parallel (one per procedure) with subagent_type="general-purpose":
- Prompt: "Review procedure [name] for compilation readiness. Check for missing/unused variables, missing params, syntax errors. Report issues found."
```

**On issues:**
1. Fix automatically if straightforward
2. Report fixes made
3. Re-validate after fixes

## Out of Scope

**Testing:** Do NOT generate unit tests or test programs. Testing is not currently supported by this skill.

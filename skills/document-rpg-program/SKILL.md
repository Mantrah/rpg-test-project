---
name: document-rpg-program
description: Generate comprehensive markdown documentation for RPG ILE programs by analyzing code structure and business logic.
---

# RPG Program Documentation Generator Skill

Generate comprehensive markdown documentation for RPG ILE programs by analyzing code structure, business logic, and existing documentation.

**Target System: IBM i V7R5**

## IMPORTANT: Use Extended Thinking Mode

ALWAYS use extended thinking mode for deep analysis of code structure, business logic, relationships, and patterns.

## Workflow

### 1. Read Context Files (in order)

1. `README.md` - Overall project context
2. `/docs/` - Strategic info, style patterns
3. Existing program documentation (if any) - Maintain consistency
4. RPG source file(s) - Implementation

### 2. Analyze Code

**Extract:**
- Control options, binding directories
- File declarations, data structures (with field descriptions)
- Procedures: purpose, parameters (types), return values, error handling
- ERRUTIL usage, error codes
- Business logic, processing flow
- External dependencies (CALL/CALLP, copy members)

### 3. Generate Documentation

**Default:** `/docs/program/{programName}.md`

**Standard sections:**
1. Overview (purpose, features)
2. Architecture (design, data flow)
3. Technical Specs (control options, files, DS)
4. Procedures Reference
5. Error Handling
6. JSON/API (if applicable)
7. Database Operations (if applicable)
8. Usage Examples
9. Development Notes

**For refactoring** (output to `/refactor/`):
Add: Current implementation analysis, refactoring plan, migration notes

### 4. Output Process

1. Analyze context + source
2. Organize into standard sections
3. Generate markdown
4. Present for review
5. Write to location
6. Iterate on feedback

## Documentation Quality Standards

- **Match existing style** - Consistent terminology, formatting
- **Clear language** - Avoid jargon, explain RPG-specific patterns
- **Code references** - Link to source when helpful (procedure names, line numbers)
- **Business context** - Explain WHY, not just WHAT
- **Completeness** - All procedures, all error codes, all external dependencies
- **Accuracy** - Verify parameter types, return values match source

# Usage Guide - RPG Program Documentation Generator

Complete guide for using the document-rpg-program skill effectively.

## Quick Start

### Basic Invocation

```bash
/document-rpg-program ORDERSRV.rpgle
```

This will:
1. Read your project's README.md for context
2. Read all files in /docs/ for style and standards
3. Analyze the ORDERSRV.rpgle program
4. Generate documentation to `/docs/program/ORDERSRV.md`

## Invocation Methods

### 1. Simple Program Name

```bash
/document-rpg-program CUSTSRV
```

The skill will:
- Look for CUSTSRV.rpgle in common locations
- Use default output path
- Include all standard sections

### 2. With Specific Path

```bash
Document the program at src/services/MATHCALC.rpgle
```

### 3. Custom Output Location

```bash
Generate documentation for ORDERSRV.rpgle and save to /docs/api/orders.md
```

### 4. Focused Documentation

```bash
Document the API endpoints and JSON handling in ORDERSRV.rpgle
```

The skill will emphasize those sections while still including complete documentation.

## Workflow

### Step 1: Preparation

Before invoking the skill, ensure:

✅ **README.md exists** - Provides project context and style
✅ **docs/ folder exists** - Contains strategic documentation
✅ **Source code is accessible** - RPG program file is readable
✅ **Code is well-structured** - Following RPG naming conventions

### Step 2: Invocation

Choose your invocation method based on needs:

- **Quick doc**: Just provide program name
- **Custom location**: Specify output path
- **Focused**: Request specific sections

### Step 3: Review

The skill will:
1. Analyze all relevant files
2. Generate comprehensive documentation
3. **Present it for your review**
4. Wait for your approval before writing

### Step 4: Refinement

You can request changes:

```bash
Add more details about the error handling section
```

```bash
Include a flowchart for the main processing logic
```

```bash
Add examples for each procedure
```

### Step 5: Finalization

Once approved, the skill writes the documentation to the specified location.

## Best Practices

### For Best Results

#### 1. Maintain Good Documentation

Keep your README.md and docs/ folder updated:

```
/docs/
  ├── architecture/
  │   └── system-design.md
  ├── standards/
  │   └── coding-standards.md
  └── program/
      └── (generated docs here)
```

The skill learns from existing documentation to match your style.

#### 2. Use Descriptive Code

Well-named procedures and variables make better documentation:

**Good:**
```rpg
dcl-proc CUSTSRV_getCustomerById export;
dcl-proc ORDERSRV_calculateOrderTotal export;
```

**Less Helpful:**
```rpg
dcl-proc Process export;
dcl-proc Calc export;
```

#### 3. Include Header Comments

While the skill can document code without comments, header comments improve results:

```rpg
//==============================================================
// CUSTSRV_getCustomerById : Retrieve customer by ID
//
//  Returns: Customer data structure or empty if not found
//
//==============================================================
dcl-proc CUSTSRV_getCustomerById export;
```

#### 4. Follow Error Handling Patterns

Consistent ERRUTIL usage is better documented:

```rpg
monitor;
  // Validation
  if customerId <= 0;
    ERRUTIL_addErrorCode('CUST001');
    return emptyData;
  endif;

  // Business logic
  // ...

on-error;
  ERRUTIL_addExecutionError();
  return emptyData;
endmon;
```

## Customization Options

### Output Path

Default: `/docs/program/(program-name).md`

Custom:
```bash
Save documentation to /docs/api/customer-service.md
```

### Detail Level

**Basic** - High-level overview only
```bash
Generate basic documentation for MATHCALC.rpgle
```

**Standard** - Complete documentation (default)
```bash
/document-rpg-program MATHCALC.rpgle
```

**Comprehensive** - Include all details, examples, and diagrams
```bash
Generate comprehensive documentation with examples for ORDERSRV.rpgle
```

### Focus Areas

Emphasize specific aspects:

**API/JSON:**
```bash
Document the REST API endpoints in ORDERSRV.rpgle
```

**Procedures:**
```bash
Focus on procedure reference documentation for MATHCALC.rpgle
```

**Database:**
```bash
Document the database operations and SQL in DATASRV.rpgle
```

**Error Handling:**
```bash
Emphasize error handling and ERRUTIL usage in ORDERSRV.rpgle
```

## Advanced Usage

### Multiple Programs

Document multiple programs in sequence:

```bash
/document-rpg-program CUSTSRV.rpgle
```

Then:
```bash
/document-rpg-program ORDERSRV.rpgle
```

### Service Program Documentation

For service programs with multiple modules:

```bash
Generate documentation for the UTILITIES service program including all exported procedures
```

### Update Existing Documentation

To refresh documentation after code changes:

```bash
Update the documentation for ORDERSRV.rpgle with recent changes
```

The skill will read the existing documentation and update it.

## Troubleshooting

### Program Not Found

**Problem:** Skill can't locate the RPG source file

**Solution:** Provide full path
```bash
Document the program at /home/user/rpgsrc/ORDERSRV.rpgle
```

### Missing Context

**Problem:** Generated documentation doesn't match your style

**Solution:** Ensure README.md and docs/ folder exist and are complete

### Incomplete Documentation

**Problem:** Some sections are missing or brief

**Solution:** Request comprehensive documentation
```bash
Generate comprehensive documentation with all sections for ORDERSRV.rpgle
```

### Wrong Output Location

**Problem:** Documentation saved to unexpected location

**Solution:** Specify exact output path
```bash
Save to /docs/services/order-service.md
```

## Examples by Program Type

### Batch Processing Program

```bash
/document-rpg-program BATCHORD.rpgle
```

**Generated sections will emphasize:**
- File processing logic
- Transaction control
- Error handling and logging
- Parameter handling

### REST API Program

```bash
/document-rpg-program ORDERAPI.rpgle
```

**Generated sections will emphasize:**
- JSON request/response formats
- YAJL usage patterns
- HTTP endpoints
- Error responses

### Service Module

```bash
/document-rpg-program MATHSRV.rpgle
```

**Generated sections will emphasize:**
- Exported procedures
- Reusable utilities
- Parameters and return values
- Usage examples

### Database Utility

```bash
/document-rpg-program DBUTILS.rpgle
```

**Generated sections will emphasize:**
- SQL operations
- File access patterns
- Transaction control
- Data structures

## Tips for Maintenance

### Keep Documentation Current

When you change code, update documentation:

```bash
Update documentation for ORDERSRV.rpgle after adding new error codes
```

### Version Documentation

Include version history in your docs:
```markdown
## Version History
- v1.2 (2024-01-15) - Added inventory validation
- v1.1 (2024-01-10) - Enhanced error handling
- v1.0 (2024-01-01) - Initial release
```

### Link Documentation

Create index pages linking to all program documentation:

```markdown
# API Documentation

- [Order Service](program/ORDERSRV.md)
- [Customer Service](program/CUSTSRV.md)
- [Inventory Service](program/INVSRV.md)
```

## Next Steps

- See [sample-output.md](../examples/sample-output.md) for complete example
- Check [README.md](../README.md) for installation and setup
- Review [SKILL.md](../SKILL.md) for technical details

## Getting Help

If you encounter issues:
1. Check this usage guide
2. Review the examples
3. Ensure your code follows RPG standards
4. Provide clear, specific requests to the skill

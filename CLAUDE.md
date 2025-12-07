# Claude Configuration

RPG ILE test project for IBM i V7R5.

## Architecture

**IMPORTANT: All database access MUST go through RPG service programs.**

```
React UI → Node.js API → iToolkit/XMLSERVICE → RPG Service Programs → DB2
```

- **Node.js controllers**: HTTP handling, validation, call rpgConnector only
- **rpgConnector.js**: Calls RPG via iToolkit XMLSERVICE
- **RPG Service Programs**: ALL SQL/database operations (BROKRSRV, CONTSRV, CUSTSRV, etc.)
- **DB2**: Tables in library MRS1

**NO direct SQL queries from Node.js to DB2.** All data access goes through RPG.

## Project Structure

- `src/qrpglesrc/` - RPG source files (service programs)
- `api/` - Node.js Express API (calls RPG only)
- `ui/` - React frontend
- `sql/` - SQL DDL scripts (tables, views)
- `docs/` - Program documentation

## Skills

This project uses the following Claude skills:

- **rpg-generator** - Generate modern RPG ILE code following project standards
- **document-rpg-program** - Generate documentation for RPG programs
- **knowledge-capture** - Capture decisions and patterns during development

## Coding Standards

See `/skills/rpg-generator/SKILL.md` for naming conventions and code structure requirements.

## Error Handling

Use ERRUTIL for all error handling:
- `/copy qrpglesrc/ERRUTIL`
- `ERRUTIL_addErrorCode('CODE')` for known errors
- `ERRUTIL_addExecutionError()` in ON-ERROR blocks

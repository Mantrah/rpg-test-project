# Claude Configuration

RPG ILE test project for IBM i V7R5.

## Project Structure

- `src/qrpglesrc/` - RPG source files
- `sql/` - SQL DDL scripts (tables, views)
- `docs/` - Program documentation
- `refactor/` - Refactoring documentation and output

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

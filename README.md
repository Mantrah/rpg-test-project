# RPG Test Project

Test project for validating Claude Code skills for RPG ILE development on IBM i V7R5.

## Purpose

This project is used to test and validate:

- **rpg-generator** - Code generation with custom standards
- **document-rpg-program** - Automated documentation
- **knowledge-capture** - Decision tracking

## Structure

```
rpg-test-project/
├── CLAUDE.md           # Claude configuration
├── skills/             # Claude skills
│   ├── rpg-generator/
│   ├── document-rpg-program/
│   └── knowledge-capture/
├── src/
│   └── qrpglesrc/      # RPG source files
├── sql/                # Table DDL
├── docs/               # Documentation
└── refactor/           # Refactoring output
```

## Usage

Open this project in VS Code with Claude Code extension and use the skills to generate RPG programs.

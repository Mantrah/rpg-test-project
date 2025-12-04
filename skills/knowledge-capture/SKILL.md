---
name: knowledge-capture
description: Capture project knowledge during conversations. Use proactively when user mentions architecture decisions, business rules, integrations, or conventions.
---

# Knowledge Capture Skill

Automatically detects new project information during conversations and suggests documenting it for long-term knowledge preservation.

**IMPORTANT: Use this skill proactively when new project-specific information emerges during conversations or agent responses.**

## When to Use This Skill

Invoke this skill when:
- User mentions project-specific architecture decisions
- User reveals business rules or domain logic
- User describes integrations or dependencies
- User explains conventions or patterns specific to this project
- Agent responses reveal new information about the project
- Design decisions are discussed that should be preserved

**Don't invoke for:**
- General programming concepts
- Temporary session-specific decisions
- Information already being documented by other skills
- Code-specific details (those belong in code comments)

## Workflow

### Step 1: Extract Project Information

Analyze the recent conversation (last 2-3 exchanges) and identify statements about:

**Architecture & Technology:**
- External services/APIs used
- Libraries and frameworks
- Deployment patterns
- Integration points

**Business Domain:**
- Business rules and logic
- Domain-specific terminology
- Calculation methods
- Validation rules

**Project Conventions:**
- File organization patterns
- Naming conventions
- Documentation structure
- Development workflows

### Step 2: Search Existing Documentation

Search for mentions of the extracted information in:
- `/docs/**/*.md` (all documentation files)
- `README.md` (project root)
- `/refactor/**/*.md` (refactoring documentation)

**Search for:**
- Exact terms (e.g., "Mistral", "ERRUTIL", "VIP discount")
- Related concepts (e.g., "LLM", "error handling", "customer discounts")
- Context (e.g., "external integrations", "business rules")

### Step 3: Determine if Documentation is Needed

**Document if:**
- Information is NOT found in existing docs
- Information is important/reusable knowledge
- Information represents a decision or pattern
- Information would help future understanding

**Skip if:**
- Already documented (even if phrased differently)
- Temporary or session-specific
- Too granular (implementation detail, not pattern)
- Obvious from code structure

### Step 4: Suggest Documentation

If documentation is needed, suggest to user:

```
📝 New project information detected:

Topic: [Brief description]
Information: [What was learned]

This doesn't appear to be documented yet.

Suggested location: /docs/[category]/[filename].md
Suggested content:
---
[Draft documentation snippet]
---

Should I:
1. Create/update documentation now
2. Skip (not important enough)
3. Document differently (you provide location/content)

Your choice?
```

### Step 5: Create/Update Documentation

Based on user choice:

**Option 1: Create/update now**
- Determine best file location based on category
- Read existing file if it exists
- Add new information in appropriate section
- Use clear, concise language
- Include context and examples

**Option 2: Skip**
- Acknowledge and continue

**Option 3: User-specified**
- Use user's preferred location and content
- Apply their edits

## Documentation Categories

Suggest appropriate location based on information type:

| Category | Location | Examples |
|----------|----------|----------|
| Architecture | `/docs/architecture/` | System design, integrations, external services |
| Business Rules | `/docs/business/` | Domain logic, calculations, validations |
| Technical Patterns | `/docs/technical/` | Code patterns, conventions, standards |
| Project Setup | `README.md` | Getting started, dependencies, configuration |
| Refactoring Notes | `/refactor/` | Specific refactoring decisions and rationale |

## Documentation Format

When creating documentation snippets, use this format:

```markdown
## [Topic Name]

**Overview**: [1-2 sentence description]

**Details**:
- [Key point 1]
- [Key point 2]

**Example**:
[Code or usage example if applicable]

**Rationale**: [Why this decision was made, if applicable]

**Date**: [YYYY-MM-DD]
```

## Key Principles

1. **Proactive**: Invoke automatically when project information emerges
2. **Non-intrusive**: Batch suggestions; don't interrupt frequently
3. **Intelligent**: Only suggest documenting truly new, important information
4. **Helpful**: Provide draft content, not just "you should document this"
5. **Flexible**: User can accept/skip/modify suggestions
6. **Long-term**: Build project knowledge over months/years

## Integration

Complements: rpg-refactor, rpg-generator, document-rpg-program, devils-advocate - invoke when discovering new project patterns.

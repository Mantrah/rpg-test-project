# Knowledge Capture Skill

Automatically detects and documents important project information as it emerges in conversations.

## The Problem It Solves

```
Week 1: "We use Mistral LLM for processing"
Week 20: "What integrations do we have?" → Lost in chat history
```

With this skill: Information gets documented in `/docs/` automatically.

## When It Activates

Proactively detects:
- **Architecture**: "We integrate with Mistral LLM", "We use ERRUTIL"
- **Business rules**: "VIP customers get 10% discount"
- **Conventions**: "Refactoring docs go in /refactor/"

## How It Works

1. **Detects** new project information in conversation
2. **Searches** existing docs to avoid duplication
3. **Suggests** location and drafts content
4. **Creates** documentation after your approval

## Example

```
You: "We use YAJL for JSON parsing"

Skill: 📝 New information detected: JSON parsing library
       Not documented yet.
       Suggested: /docs/architecture/json-handling.md

       Create documentation? [Yes/No/Custom]
```

## Documentation Structure

```
/docs/
├── architecture/    # System design, integrations
├── business/        # Business rules, domain logic
└── technical/       # Code patterns, conventions
```

## Related

- `/remember` command: Fast-path for explicit knowledge capture

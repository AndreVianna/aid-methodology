# State: DONE

Print the initialization summary and suggest the next AID phase.

> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [✓ COLLECT ] → [✓ SCAFFOLD ] → [✓ META-DOCS ] → [✓ SETUP ] → [● DONE ]
> ```

Print a summary of everything created:

```
✅ AID Project Initialized

  Project:     {name}
  Type:        {Brownfield / Greenfield}
  Min Grade:   {grade}
  External:    {N paths / None}

  Created:
    knowledge/    (16 KB documents + README + INDEX + STATE)
    AGENTS.md                   {created / updated / unchanged}

  AID workspace (.aid/):        {tracked by Git | local only — added to .gitignore}

  Next step:
    {Brownfield: "Run /aid-discover to analyze the codebase and populate the Knowledge Base."}
    {Greenfield: "Run /aid-interview to gather requirements and start building the specification."}
```

**Advance:** → halt. Initialization is complete; the user proceeds to `/aid-discover` (brownfield) or `/aid-interview` (greenfield).

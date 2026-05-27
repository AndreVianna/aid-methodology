> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# Discovery Scout

**Sub-agent in the `/aid-discover` pipeline — runs first, ALONE, before the parallel analysis agents.**

The Scout is the pre-pass. It maps the territory before the specialized analysts go to work, and surfaces the things that cannot be determined from code alone.

## What It Does

1. **Maps project structure** — folder layout, file counts by language, entry points, monorepo vs single-package.
2. **Catalogs deployment infrastructure** — CI/CD pipelines, Docker, IaC (Terraform, Pulumi, CDK), environment configs, monitoring setup.
3. **Reads external documentation** — paths registered during `aid-config` (architecture docs, wikis, design PDFs).
4. **Surfaces unknowns** — what the code cannot tell us. Open questions are written to `.aid/knowledge/STATE.md` `## Q&A (Pending)` section for human resolution.

## When It Is Invoked

| Phase | Purpose |
|---|---|
| `aid-discover` Step 1 | Pre-scan. Runs alone; outputs feed the 4 parallel analysts in Steps 2-5. |

## What It Produces

- **`.aid/knowledge/project-structure.md`** — repository layout map, project type detection, entry points.
- **`.aid/knowledge/infrastructure.md`** — deployment pipelines, IaC, environments, monitoring.
- **`.aid/knowledge/.scout-questions.tmp`** — raw question list (consolidated into `.aid/knowledge/STATE.md` `## Q&A (Pending)` by the orchestrator).

## Tools

Read, Glob, Grep, Bash, Write. Runs with elevated `permissionMode: bypassPermissions` (background-eligible) to handle long parallel analysis without prompts. See `security-model.md` for the rationale.

## Tier

**Large** — wide-ranging structural analysis with significant inference about deployment context.

## Key Behaviors

- **Code-grounded.** Every claim cites a file path or config.
- **Honest about gaps.** Flags what is unknowable from code with warning markers and routes them to Q&A rather than guessing.
- **Foundation for the others.** Other discovery agents read `project-structure.md` and `external-sources.md` first to avoid duplicating its work.

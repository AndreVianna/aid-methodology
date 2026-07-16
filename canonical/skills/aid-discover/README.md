> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.


# Brownfield Codebase Discovery

Analyze an existing codebase and produce a structured Knowledge Base (`.aid/knowledge/` directory) that becomes the gravitational center of the project.

## When to Use

- **Full discovery:** New brownfield project. No KB exists yet.
- **Targeted discovery:** A downstream phase (aid-describe, aid-define, aid-specify, aid-plan, aid-detail, aid-execute, aid-execute (built-in review), aid-execute) wrote a Q&A entry to `.aid/knowledge/STATE.md` signalling a KB gap. Only analyze the specific area identified in that entry.

## Inputs

- Access to the codebase (local path, git repo URL, or archive).
- For targeted discovery: the Q&A entry in `.aid/knowledge/STATE.md` or the IMPEDIMENT.md that triggered re-entry.

## Process

### Step 1: Structure Scan

Detect project type and map the codebase layout.

```bash
# Detect project type
find . -maxdepth 3 -name "*.csproj" -o -name "*.sln" -o -name "pom.xml" \
  -o -name "package.json" -o -name "Cargo.toml" -o -name "go.mod" \
  -o -name "*.py" -o -name "Gemfile" | head -20

# Map folder structure
tree -L 3 -d --gitignore

# Count by language
find . -type f | grep -E '\.(cs|java|py|ts|js|go|rs)$' | \
  sed 's/.*\.//' | sort | uniq -c | sort -rn
```

Record in `.aid/knowledge/architecture.md`: project type, approximate size, age (from git log), entry points, build system.

### Step 2: Architecture Analysis

Identify patterns, layers, and boundaries.

- Look for standard patterns: MVVM, CQRS, Clean Architecture, Layered, Microservices.
- Map module boundaries: what depends on what.
- Trace data flow: entry point → processing → storage → output.
- Identify the dependency injection/service registration pattern.

Record in `.aid/knowledge/architecture.md`.

### Step 3: Stack Inventory

Catalog all technologies.

```bash
# .NET
dotnet --list-sdks 2>/dev/null; cat global.json 2>/dev/null
# Node
cat package.json | jq '.dependencies, .devDependencies' 2>/dev/null
# Java
cat pom.xml | grep -A1 '<dependency>' 2>/dev/null
# Python
cat requirements.txt pyproject.toml 2>/dev/null
```

Record in `.aid/knowledge/technology-stack.md`: languages, frameworks, versions, package managers, runtime.

### Step 4: Convention Mining

Infer coding standards from the code itself (not from documentation that may be outdated).

- Naming patterns (PascalCase, camelCase, snake_case for what).
- Error handling (exceptions, Result types, error codes).
- Logging patterns (which framework, structured vs unstructured).
- Configuration management (env vars, config files, secrets).
- File organization conventions.

Record in `.aid/knowledge/coding-standards.md`. Mark as "inferred from code" — these need human confirmation.

### Step 5: Module Mapping

For every significant module/package:

| Module | Purpose | Dependencies | Approx Size | Test Coverage |
|--------|---------|-------------|-------------|---------------|
| ... | ... | ... | ... files | Tested/Untested |

Record in `.aid/knowledge/module-map.md`.

### Step 6: Data Model Extraction

- Schema: tables/collections, columns/fields, types.
- Relationships: foreign keys, navigation properties, indexes.
- Migrations: migration history, current version.

```bash
# EF Core
find . -path "*/Migrations/*.cs" | head -20
# SQL files
find . -name "*.sql" | head -20
# Schema files
find . -name "schema.*" -o -name "*.prisma" -o -name "*.graphql" | head -10
```

Record in `.aid/knowledge/schemas.md`.

### Step 7: Integration Surface

Map all external touchpoints:

- APIs consumed (HTTP clients, SDK usage).
- APIs exposed (controllers, endpoints, routes).
- Message queues (RabbitMQ, Kafka, SQS).
- Caches (Redis, Memcached, in-memory).
- Third-party services (auth providers, payment, email).

Record in `.aid/knowledge/pipeline-contracts.md` and `.aid/knowledge/integration-map.md`.

### Step 8: Test Landscape

- Test frameworks in use.
- Test types present (unit, integration, E2E, performance).
- Coverage target/enforcement (if CI reports exist).
- CI/CD pipeline description.

Record in `.aid/knowledge/test-landscape.md`.

### Step 9: Tech Debt Audit

Flag concrete issues with file references:

- Large files (>500 lines) that likely need decomposition.
- Circular dependencies between modules.
- Missing tests in critical paths.
- Outdated package versions with known vulnerabilities.
- TODO/HACK/FIXME comments.

```bash
# Large files
find . -name "*.cs" -o -name "*.java" -o -name "*.ts" | \
  xargs wc -l 2>/dev/null | sort -rn | head -20
# TODOs
rg "TODO|HACK|FIXME|XXX" --count-matches 2>/dev/null | sort -t: -k2 -rn | head -20
```

Record in `.aid/knowledge/tech-debt.md` with risk ratings (High/Medium/Low).

### Step 10: Open Questions

Record in `.aid/knowledge/STATE.md`'s Q&A section everything that code analysis alone could not determine. Each entry includes an ID (Q{N}), question, category, impact (High / Medium / Low), status (Pending / Answered / Skipped), code evidence, and optional suggested answer. This covers business rules not explicit in code, deployment procedures not captured in scripts, and data flows requiring human explanation. These feed directly into aid-describe.

### Step 11: KB Index

Create `.aid/knowledge/README.md` with completeness tracking:

```markdown
# Knowledge Base — {Project Name}

| Document | Status | Last Updated | Source |
|----------|--------|-------------|--------|
| architecture.md | ✅ Complete | {date} | aid-discover |
| coding-standards.md | ⚠️ Partial | {date} | aid-discover (inferred) |
| domain-glossary.md | ❌ Missing | — | Needs interview |
```

## Output

A `.aid/knowledge/` directory containing the project's declared doc-set (the standard default set for software projects, adjustable per project; plus a README.md index and `.aid/knowledge/STATE.md`):

| Document | Always? | Description |
|----------|---------|-------------|
| README.md | Yes | Index with completeness status |
| project-structure.md | Yes | Top-level folder layout, entry points, key config files |
| external-sources.md | If external docs ingested | External documentation ingested into the KB |
| architecture.md | Yes | Patterns, layers, boundaries |
| technology-stack.md | Yes | Full stack catalog |
| module-map.md | Yes (if >1 module) | Module inventory |
| coding-standards.md | Yes | Inferred conventions |
| schemas.md | If DB exists | Schema and relationships |
| pipeline-contracts.md | If APIs/pipelines exist | External pipeline/API surface |
| integration-map.md | If integrations exist | Third-party services |
| domain-glossary.md | Rarely from code | Business terms (usually from interview) |
| test-landscape.md | Yes | Test infrastructure |
| tech-debt.md | Yes | Known debt with risk ratings |
| infrastructure.md | If infra is visible | Hosting, deployment |
| feature-inventory.md | After Q&A | User-provided feature list enriched with module, endpoint, and data entity mapping |

## Targeted Discovery (Re-entry)

When triggered by a Q&A entry in `.aid/knowledge/STATE.md` or an IMPEDIMENT.md from a downstream phase:

1. Read the Q&A entry or impediment to understand exactly what's missing.
2. Focus analysis ONLY on the identified area.
3. Update the specific KB document(s).
4. Update `.aid/knowledge/README.md` with a revision note:
   ```
   | {date} | {source phase} | Updated {document} — {what changed and why} |
   ```
5. Update `.aid/knowledge/README.md` status for affected documents.
6. Report completion to the calling phase so it can resume.

## Quality Checklist

- [ ] Every KB document has a clear scope — no overlap between documents.
- [ ] Claims are grounded in code evidence (file paths + grep-recoverable symbol/heading anchors, not bare line numbers).
- [ ] Inferred information is marked as inferred (e.g., "⚠️ Inferred from code — needs confirmation").
- [ ] `.aid/knowledge/STATE.md` Q&A section captures everything that requires human input with structured entries.
- [ ] `README.md` accurately reflects completeness status.
- [ ] `README.md` includes a revision history section with the initial discovery entry.

## Feedback Loops

This phase is the **target** of feedback loops from all downstream phases. It does not itself trigger upstream revision (it's the first phase).

When any downstream phase identifies a KB gap:
- If the gap is in a specific document → update that document.
- If the gap reveals a new area not yet covered → create the missing document.
- Always update README.md status and revision history.

## Why This Phase Exists

You can't write a useful spec for a system you don't understand. Most enterprise work is brownfield — an existing codebase with patterns, conventions, and tech debt that will shape every decision downstream. Discovery transforms "a repo we don't fully understand" into "a Knowledge Base that grounds every subsequent phase."

Without Discovery, specs are generic and agents improvise. With Discovery, specs reference actual code patterns and agents follow real conventions.

## Related Phases

- **Next:** [Interview](../aid-describe/) — uses open questions from `.aid/knowledge/STATE.md` to focus requirements gathering
- **Triggered by:** Any downstream phase via a Q&A entry in `.aid/knowledge/STATE.md`

## See Also

- [KB Document Templates](../../templates/knowledge-base/) — Per-document templates for each KB document.
- [AID Methodology](../../docs/aid-methodology.md) — The complete methodology.


# Brownfield Codebase Discovery

Analyze an existing codebase and produce a structured Knowledge Base (`knowledge/` directory) that becomes the gravitational center of the project.

## When to Use

- **Full discovery:** New brownfield project. No KB exists yet.
- **Targeted discovery:** A downstream phase (aid-interview, aid-specify, aid-plan, aid-detail, aid-implement, aid-review, aid-test) generated a GAP.md with `discovery-needed`. Only analyze the specific area identified in the gap.

## Inputs

- Access to the codebase (local path, git repo URL, or archive).
- For targeted discovery: the GAP.md or IMPEDIMENT.md that triggered re-entry.

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

Record in `knowledge/codebase-overview.md`: project type, approximate size, age (from git log), entry points, build system.

### Step 2: Architecture Analysis

Identify patterns, layers, and boundaries.

- Look for standard patterns: MVVM, CQRS, Clean Architecture, Layered, Microservices.
- Map module boundaries: what depends on what.
- Trace data flow: entry point → processing → storage → output.
- Identify the dependency injection/service registration pattern.

Record in `knowledge/architecture.md`.

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

Record in `knowledge/technology-stack.md`: languages, frameworks, versions, package managers, runtime.

### Step 4: Convention Mining

Infer coding standards from the code itself (not from documentation that may be outdated).

- Naming patterns (PascalCase, camelCase, snake_case for what).
- Error handling (exceptions, Result types, error codes).
- Logging patterns (which framework, structured vs unstructured).
- Configuration management (env vars, config files, secrets).
- File organization conventions.

Record in `knowledge/coding-standards.md`. Mark as "inferred from code" — these need human confirmation.

### Step 5: Module Mapping

For every significant module/package:

| Module | Purpose | Dependencies | Approx Size | Test Coverage |
|--------|---------|-------------|-------------|---------------|
| ... | ... | ... | ... files | Tested/Untested |

Record in `knowledge/module-map.md`.

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

Record in `knowledge/data-model.md`.

### Step 7: Integration Surface

Map all external touchpoints:

- APIs consumed (HTTP clients, SDK usage).
- APIs exposed (controllers, endpoints, routes).
- Message queues (RabbitMQ, Kafka, SQS).
- Caches (Redis, Memcached, in-memory).
- Third-party services (auth providers, payment, email).

Record in `knowledge/api-contracts.md` and `knowledge/integration-map.md`.

### Step 8: Test Landscape

- Test frameworks in use.
- Test types present (unit, integration, E2E, performance).
- Coverage metrics (if CI reports exist).
- CI/CD pipeline description.

Record in `knowledge/test-landscape.md`.

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

Record in `knowledge/tech-debt.md` with risk ratings (High/Medium/Low).

### Step 10: Gap Identification

Document what you couldn't determine from code alone:

- Business rules that aren't explicit in code.
- Deployment procedures not captured in scripts.
- Data flows that require human explanation.
- Security model details (auth config, secrets management).

Record in `knowledge/open-questions.md`. These feed directly into aid-interview.

### Step 11: KB Index

Create `knowledge/README.md` with completeness tracking:

```markdown
# Knowledge Base — {Project Name}

| Document | Status | Last Updated | Source |
|----------|--------|-------------|--------|
| codebase-overview.md | ✅ Complete | {date} | aid-discover |
| architecture.md | ✅ Complete | {date} | aid-discover |
| coding-standards.md | ⚠️ Partial | {date} | aid-discover (inferred) |
| domain-glossary.md | ❌ Missing | — | Needs interview |
```

Initialize `knowledge/revision-log.md` with the discovery entry.

## Output

A `knowledge/` directory containing the relevant subset of these 16 documents:

| Document | Always? | Description |
|----------|---------|-------------|
| README.md | Yes | Index with completeness status |
| codebase-overview.md | Yes | Project type, size, entry points |
| architecture.md | Yes | Patterns, layers, boundaries |
| module-map.md | Yes (if >1 module) | Module inventory |
| technology-stack.md | Yes | Full stack catalog |
| coding-standards.md | Yes | Inferred conventions |
| data-model.md | If DB exists | Schema and relationships |
| api-contracts.md | If APIs exist | External API surface |
| integration-map.md | If integrations exist | Third-party services |
| domain-glossary.md | Rarely from code | Business terms (usually from interview) |
| flow-diagrams.md | For complex flows | Key data/user flows |
| test-landscape.md | Yes | Test infrastructure |
| security-model.md | If auth exists | Security architecture |
| tech-debt.md | Yes | Known debt with risk ratings |
| infrastructure.md | If infra is visible | Hosting, deployment |
| open-questions.md | Yes | Gaps for interview |
| revision-log.md | Yes | Change history |

## Targeted Discovery (Re-entry)

When triggered by a GAP.md or IMPEDIMENT.md from a downstream phase:

1. Read the gap/impediment document to understand exactly what's missing.
2. Focus analysis ONLY on the identified area.
3. Update the specific KB document(s).
4. Add an entry to `knowledge/revision-log.md`:
   ```
   | {date} | {source phase} | Updated {document} — {what changed and why} |
   ```
5. Update `knowledge/README.md` status for affected documents.
6. Report completion to the calling phase so it can resume.

## Quality Checklist

- [ ] Every KB document has a clear scope — no overlap between documents.
- [ ] Claims are grounded in code evidence (file paths, line numbers, grep results).
- [ ] Inferred information is marked as inferred (e.g., "⚠️ Inferred from code — needs confirmation").
- [ ] `open-questions.md` captures everything that requires human input.
- [ ] `README.md` accurately reflects completeness status.
- [ ] `revision-log.md` has the initial discovery entry.

## Feedback Loops

This phase is the **target** of feedback loops from all downstream phases. It does not itself trigger upstream revision (it's the first phase).

When any downstream phase identifies a KB gap:
- If the gap is in a specific document → update that document.
- If the gap reveals a new area not yet covered → create the missing document.
- Always update README.md and revision-log.md.

## See Also

- [KB Document Templates](references/kb-templates.md) — Full templates for each KB document.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.

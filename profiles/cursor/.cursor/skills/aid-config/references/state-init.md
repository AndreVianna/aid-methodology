# aid-config — State: INIT (first-time scaffold)

```
[State: INIT] — Scaffolding .aid/ structure + writing settings.yml defaults.
aid-config  ▸ you are here
  [● INIT ] → [ VIEW ] → [ UPDATE ] → [ PERSIST ] → [ DONE ]
```

This state runs **only when `.aid/` does not exist** (first run on a fresh project).
It subsumes the entire workflow the legacy `aid-init` skill performed PLUS writing
the new `.aid/settings.yml` source of truth.

**This is a conversational state — ask questions one at a time, wait for each answer.**

---

## Step 1: Ask 8 questions

### Q1 — Project Type

```
Is this a greenfield or brownfield project?
  [1] Brownfield — existing code; /aid-discover will analyze it
  [2] Greenfield — new project; /aid-interview will gather requirements
```

Capture as `project.type` (`brownfield` or `greenfield`).

### Q2 — Project Name

```
What's the project name? (short identifier, used in filenames; no spaces)
```

Capture as `project.name`. Validate: non-empty, no spaces. Re-ask if invalid.

### Q3 — Brief Description

```
One-sentence description (what does this project DO?)
```

Capture as `project.description`. **This is the SOLE source of truth — it will NOT be
duplicated in CLAUDE.md/AGENTS.md.** The project-context file links to settings.yml
instead.

### Q4 — External Documentation Paths (optional)

```
External documentation paths (optional). Comma-separated, or press enter to skip.
Examples: docs/internal-api.md, https://wiki.example.com/architecture
```

If provided, verify each path exists (filesystem) or has a valid URL form. Inaccessible
paths: warn and ask whether to continue without them.

Capture as a list for later use during `/aid-discover` (recorded in `external-sources.md`).
This list is NOT written to settings.yml — it's discovery input, not configuration.

### Q5 — Install Tools

```
Which AI host tools have AID installed in this project? Choose any:
  [1] Claude Code (CLAUDE.md project-context file)
  [2] Codex CLI    (AGENTS.md project-context file)
  [3] Cursor       (AGENTS.md project-context file)
```

Multi-select. Capture as `tools.installed` list (`claude-code`, `codex`, `cursor`).
At least one required.

### Q6 — Minimum Grade

```
Minimum acceptable grade for skill REVIEW states? (global default; can be overridden per-skill)
Valid: A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, F
[default: A]
```

Capture as `review.minimum_grade`. Default `A` if user presses enter.

### Q7 — Heartbeat Interval

```
Heartbeat interval for long-running sub-agent visibility (minutes)?
[default: 1]
```

Capture as `traceability.heartbeat_interval` (integer; default `1`).

### Q8 — Max Parallel Tasks

```
Max parallel tasks for /aid-execute pool dispatch?
[default: 5]
```

Capture as `execution.max_parallel_tasks` (integer; default `5`).

---

## Step 2: Scaffold `.aid/` directory + KB templates

Create the directory structure:

```
.aid/
  settings.yml             ← step 4
  knowledge/
    project-structure.md   ← KB doc templates (16 total)
    external-sources.md
    architecture.md
    technology-stack.md
    module-map.md
    coding-standards.md
    data-model.md
    api-contracts.md
    integration-map.md
    domain-glossary.md
    test-landscape.md
    security-model.md
    tech-debt.md
    infrastructure.md
    ui-architecture.md
    feature-inventory.md
    README.md              ← meta
    STATE.md               ← meta (skill state ledger only — no config)
  generated/               ← .aid/generated/* — empty initially; created by build scripts later
  .temp/                   ← .aid/.temp/* — empty initially; gitignored
  .heartbeat/              ← .aid/.heartbeat/* — empty initially; gitignored
```

Copy each of the 16 KB doc templates from `.cursor/templates/knowledge-base/<name>.md`
into `.aid/knowledge/<name>.md`. These templates already carry YAML frontmatter
(`kb-category` + `source` + `intent` + `contracts` + `changelog`) per the
canonical KB Authoring spec.

**Brownfield:** templates have `<!-- pending discovery -->` markers — `/aid-discover`
will populate them.
**Greenfield:** templates have `<!-- pending interview/specify -->` markers.

---

## Step 3: Write knowledge-area meta documents

### `.aid/knowledge/README.md`

Use template from `.cursor/templates/knowledge-base/README.md`. Substitute:
- Project name
- Project type (brownfield/greenfield)

### `.aid/knowledge/INDEX.md`

INDEX.md is **generated** by `.cursor/scripts/kb/build-index.sh` after KB docs
have frontmatter content. **DO NOT hand-author INDEX.md.** Run the generator at
the end of INIT (after all 16 KB docs are scaffolded):

```bash
bash .cursor/scripts/kb/build-index.sh \
  --root .aid/knowledge \
  --output .aid/generated/INDEX.md
```

(For greenfield projects with empty placeholder intents, INDEX.md will be sparse
— that's expected; it populates as `/aid-discover` and `/aid-interview` add real
content.)

### `.aid/knowledge/STATE.md`

STATE.md is the Discovery-area state ledger (cycle history, Q&A, calibration
log per work-003). It is **NOT** the config file — config now lives in
`.aid/settings.yml`.

Create STATE.md from `.cursor/templates/discovery-state-template.md`. Substitute:
- Status: `Not Started` (Discovery hasn't run yet)
- Last updated: today's ISO date

STATE.md does NOT contain `Minimum Grade`, `Heartbeat Interval`, or
`Max Parallel Tasks` — those moved to `settings.yml`.

---

## Step 4: Write `.aid/settings.yml`

Copy `.cursor/templates/settings.yml` to `.aid/settings.yml` and substitute the
collected values from Step 1:

```yaml
project:
  name: <Q2 answer>
  description: <Q3 answer>
  type: <Q1 answer>

tools:
  installed:
    - <each Q5 selection>

review:
  minimum_grade: <Q6 answer>

execution:
  max_parallel_tasks: <Q8 answer>

traceability:
  heartbeat_interval: <Q7 answer>

# Optional per-skill overrides (commented out by default):
# discover: { minimum_grade: A+ }
# (etc.)
```

Validate that the resulting file parses as YAML.

---

## Step 5: Create / update project-context file (CLAUDE.md / AGENTS.md)

For each tool in `tools.installed`:

- `claude-code` → uses `CLAUDE.md`
- `codex` or `cursor` → uses `AGENTS.md`

If the project-context file does NOT exist, create it from the canonical template:
- `.cursor/templates/claude-md-template.md` (for CLAUDE.md)
- `.cursor/templates/agents-md-template.md` (for AGENTS.md)

**Key change vs legacy aid-init:** the AID Workspace section in CLAUDE.md/AGENTS.md
links to `.aid/settings.yml` for project description rather than duplicating it.
The placeholder section reads roughly:

```markdown
## AID Workspace

This project uses the AID methodology. Configuration lives in `.aid/settings.yml`
(the single source of truth — see `/aid-config` to view or update).

Knowledge Base: `.aid/knowledge/` — read `INDEX.md` first.

<!-- AID-DISCOVER -->
(KB-derived content goes here after /aid-discover runs)
```

If the file already exists, append the `## AID Workspace` section if missing
(do NOT overwrite existing content).

---

## Step 6: Install skill templates into `.aid/templates/`

Some skills (`/aid-summarize`) require non-canonical templates at runtime that
must live in the adopter's project. Copy:

- `.cursor/templates/knowledge-summary/` → `.aid/templates/knowledge-summary/`

This is the same step the legacy aid-init step-4b performed; only the location of
the source moved (.cursor/templates/knowledge-summary/ unchanged).

---

## Step 7: Update `.gitignore` (per user's earlier policy on `.aid/`)

The adopter's `.gitignore` is NOT touched automatically. Instead, print
recommendations:

```
Recommended .gitignore entries (you may add manually):
  .aid/.temp/        # transient state — never commit
  .aid/.heartbeat/   # heartbeat files — never commit
  .aid/.cache/       # local caches — never commit

To keep the KB local-only (not shared via git):
  .aid/              # ignores everything in .aid/
```

(Adopters who DO want to commit their KB add only the `.temp`/`.heartbeat`/`.cache`
entries.)

---

## Step 8: Print next-step instructions

For brownfield:
```
✅ AID initialized.
   • Run /aid-discover to analyze your codebase and populate the KB.
```

For greenfield:
```
✅ AID initialized.
   • Run /aid-interview to start requirements gathering.
```

For both:
```
   • Run /aid-config any time to view or update settings.
```

---

## Advance

Print:
```
Next: [State: VIEW] — run /aid-config again to view settings, or skip to /aid-discover or /aid-interview.
```

Exit.

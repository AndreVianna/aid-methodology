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
One-sentence description (what does this project DO?) — single line, ~100 chars.
```

Capture as `project.description`. **This is the SOLE source of truth — it will NOT be
duplicated in CLAUDE.md/AGENTS.md.** The project-context file links to settings.yml
instead.

**Validation:** must be single-line (no newlines). The settings.yml schema
serializes this as an inline YAML scalar. If the user enters a multi-line
value, re-prompt: "project.description must be single-line. Got <N> lines.
Please consolidate or shorten."

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

Copy each of the 16 KB doc templates from `.agents/templates/knowledge-base/<name>.md`
into `.aid/knowledge/<name>.md`. These templates already carry YAML frontmatter
(`kb-category` + `source` + `intent` + `contracts` + `changelog`) per the
canonical KB Authoring spec.

**Brownfield:** templates have `<!-- pending discovery -->` markers — `/aid-discover`
will populate them.
**Greenfield:** templates have `<!-- pending interview/specify -->` markers.

---

## Step 3: Write knowledge-area meta documents

### `.aid/knowledge/README.md`

Use template from `.agents/templates/knowledge-base/README.md`. Substitute:
- Project name
- Project type (brownfield/greenfield)

### `.aid/knowledge/INDEX.md`

INDEX.md is **generated** by `.agents/scripts/kb/build-index.sh` after KB docs
have frontmatter content. **DO NOT hand-author INDEX.md.** Run the generator at
the end of INIT (after all 16 KB docs are scaffolded):

```bash
bash .agents/scripts/kb/build-index.sh \
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

Create STATE.md from `.agents/templates/discovery-state-template.md`. Substitute:
- Status: `Not Started` (Discovery hasn't run yet)
- Last updated: today's ISO date

STATE.md does NOT contain `Minimum Grade`, `Heartbeat Interval`, or
`Max Parallel Tasks` — those moved to `settings.yml`.

---

## Step 4: Write `.aid/settings.yml`

Copy `.agents/templates/settings.yml` to `.aid/settings.yml` and substitute the
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
- `.agents/templates/claude-md-template.md` (for CLAUDE.md)
- `.agents/templates/agents-md-template.md` (for AGENTS.md)

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

- `.agents/templates/knowledge-summary/` → `.aid/templates/knowledge-summary/`

This is the same step the legacy aid-init step-4b performed; only the location of
the source moved (.agents/templates/knowledge-summary/ unchanged).

---

## Step 7: Update `.gitignore` (with explicit user confirmation)

The heartbeat protocol declares `.aid/.heartbeat/` **MUST** be gitignored
(see `.agents/templates/subagent-heartbeat-protocol.md`). The transient
state (`.aid/.temp/`) and local caches (`.aid/.cache/`) should also be
ignored to avoid noisy diffs and accidental secret commits.

Rather than touch the user's `.gitignore` silently, prompt with an
AskUserQuestion offering three options:

```
.gitignore entries: aid-config recommends ignoring transient AID state.
Three options:

[1] Append the protocol-required minimum (.aid/.temp/, .aid/.heartbeat/, .aid/.cache/)
    — keeps your KB tracked; ignores only transient runtime state.
[2] Append .aid/ (ignore everything inside .aid/)
    — KB stays local-only (not shared via git).
[3] Skip — I'll manage .gitignore myself.
```

**Option 1 (recommended) and Option 2 actually append** (with a check to
avoid duplicate lines). Use a guarded block so re-running aid-config doesn't
double-append:

```bash
GITIGNORE=".gitignore"
BLOCK_BEGIN="# >>> aid-config managed >>>"
BLOCK_END="# <<< aid-config managed <<<"

# Skip if the managed block already exists
if [ -f "$GITIGNORE" ] && grep -qF "$BLOCK_BEGIN" "$GITIGNORE"; then
  echo "ℹ️  .gitignore already has an aid-config managed block — skipping."
else
  {
    [ -f "$GITIGNORE" ] && echo ""
    echo "$BLOCK_BEGIN"
    case "$choice" in
      1) echo ".aid/.temp/"; echo ".aid/.heartbeat/"; echo ".aid/.cache/" ;;
      2) echo ".aid/" ;;
    esac
    echo "$BLOCK_END"
  } >> "$GITIGNORE"
  echo "✓ .gitignore updated with aid-config managed block."
fi
```

**Option 3** prints the recommended entries for manual copying but does not
write to `.gitignore`. If chosen, also warn: "⚠️ .aid/.heartbeat/ MUST be
gitignored per the heartbeat protocol; please add it manually before running
any subagent-dispatching skill."

Re-running `/aid-config` later detects the managed block and does not
re-append; users who want to change the choice should edit the block manually
or delete it and re-run.

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

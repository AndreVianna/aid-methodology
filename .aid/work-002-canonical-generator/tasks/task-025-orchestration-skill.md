# task-025: Write the generator orchestration `SKILL.md`

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-022, task-023, task-024

**Scope:**
- Author `.claude/skills/aid-generate/SKILL.md` — the maintainer-facing skill that dispatches the full pipeline.
- **Placement decision (resolves SPEC §234 hedge):** the generator lives at `.claude/skills/aid-generate/` at the **repo root**. Rationale: the AID repo dogfoods Claude Code (verified — `.claude/settings.json` already exists at the repo root per the directory listing); the generator is maintainer-only tooling; placing it in `.claude/` matches the existing maintainer-side pattern; the skill is never shipped in any install tree (verified by adding `.claude/skills/aid-generate/` to install-tree exclusion paths and the manifest safety boundary).
- **Caveat — if OQ1 resolves to option (c)** (Python module + thin per-tool entry points): tasks 018–021 currently target `.claude/skills/aid-generate/scripts/*.py`; if option (c) is adopted, those tasks must update their target paths to a tool-agnostic Python package location (e.g. `aid_generate/{profile,harness,render_agents,render_skills,render_templates}.py` at the repo root) and the `.claude/skills/aid-generate/` location reduces to a thin slash-command wrapper that shells out to `python -m aid_generate`. The Python module itself is unchanged; only paths and import locations shift.
- **Naming decision (resolves PLAN refinement §3):** `aid-generate`. Rationale: it matches the `aid-{verb}` slug convention used by every other skill (`aid-discover`, `aid-interview`, etc. per `coding-standards.md §8`); the verb "generate" precisely describes what it does (produces install trees from canonical+profiles); `aid-render` is rejected because RENDER is one of the **internal** pipeline steps (LOAD → VALIDATE → RENDER → VERIFY → REPORT per SPEC §148-204) — naming the whole skill after one of its internal steps confuses the scope; `aid-build` is rejected because "build" already has connotations of compilation / packaging that don't fit (no compiled artifact; this is structured text rendering).
- SKILL.md frontmatter (Claude Code shape, since the generator only runs in Claude Code maintainer context):
  - `name: aid-generate`
  - `description:` folded YAML block — "Regenerates the three install trees (claude-code, codex, cursor) from `canonical/` + `profiles/`. Maintainer-only tooling; never shipped to end users. State machine: LOAD → VALIDATE → RENDER → VERIFY → REPORT."
  - `allowed-tools: Read, Glob, Grep, Bash, Write, Edit` (Python scripts invoked via `Bash`).
  - `argument-hint: "[--tool claude-code|codex|cursor] regenerate only one tree (default: all three)  [--dry-run] render to scratch + diff, don't write to install trees"`
- SKILL.md body (state-machine notation per `coding-standards.md §1.4`):
  - `## ⚠️ Pre-flight Checks` — Python 3.11+ available (`python3 --version` ≥ 3.11); `canonical/` exists; `profiles/*.toml` exist; the repo is a git working tree (so the diff in REPORT is meaningful).
  - `## State Detection` — branch on `--dry-run` (renders to a `tempfile.mkdtemp()` then diffs against current install trees, no in-tree writes) vs. live mode (writes to install trees).
  - `## Mode: LOAD` — `python3 .claude/skills/aid-generate/scripts/profile.py --load profiles/{tool}.toml` for each profile (or all three if `--tool` omitted).
  - `## Mode: VALIDATE` — `python3 -m aid_generate.validate` (calls `profile.validate()` plus a presence check for `canonical/` completeness — every skill named in the methodology has a `canonical/skills/aid-{name}/`).
  - `## Mode: RENDER` — for each selected profile, dispatch in order: `render_agents.py`, `render_skills.py`, `render_templates.py`. Each writes to the profile's install-tree location (live) or scratch directory (dry-run) and populates the `EmissionManifest`. After all three renderers run, the orchestrator computes `manifest.diff(prev, curr)` and deletes the `removed_dst` set (live mode) or reports it (dry-run).
  - `## Mode: VERIFY` — `verify_deterministic.py` (hard gate; non-zero exit aborts); then `verify_advisory.py` (always exits 0; report consumed by REPORT).
  - `## Mode: REPORT` — emit a concise summary: per-profile file count emitted, file count deleted, byte-identical re-render check status, frontmatter-parse status, VERIFY-4b `skipped_count` and `warnings_count`, and the `git diff --stat` of the install-tree paths.
  - `## Quality Checklist` — Python 3.11+ available; all three profiles parse; canonical/ complete; manifest written; VERIFY-4a passes; REPORT surfaces VERIFY-4b skipped count.
- Use the `Print:` progress idiom per `coding-standards.md §1.5` for each state transition (`Print: \`[State: RENDER]\``, `Print: \`[1/3] Rendering claude-code...\``, etc.).

**Acceptance Criteria:**
- [ ] `.claude/skills/aid-generate/SKILL.md` exists with valid Claude Code frontmatter shape.
- [ ] Body has the seven state sections (`Pre-flight`, `State Detection`, plus the five `Mode: *` sections) plus a Quality Checklist.
- [ ] `--tool {claude-code|codex|cursor}` correctly regenerates only the named tree; default regenerates all three.
- [ ] `--dry-run` renders to a temp dir and emits a diff-only report; no in-tree writes.
- [ ] End-to-end live run on the current `canonical/` + `profiles/` succeeds: all renderers run, manifest written, VERIFY-4a passes (byte-identical re-render confirmed), VERIFY-4b reports `skipped_count = 8`, REPORT summarizes correctly.
- [ ] The skill file follows `coding-standards.md §1.1–§1.5` conventions verbatim (frontmatter shape, state-machine notation, Print: idiom).

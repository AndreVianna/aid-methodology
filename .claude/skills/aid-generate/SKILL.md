---
name: aid-generate
description: >
  Regenerates the three install trees (claude-code, codex, cursor) from canonical/ + profiles/.
  Maintainer-only tooling; never shipped to end users.
  State machine: LOAD -> VALIDATE -> RENDER -> VERIFY -> REPORT.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[--tool claude-code|codex|cursor] regenerate only one tree (default: all three)  [--dry-run] render to scratch + diff, don't write to install trees"
---

# AID Install-Tree Generator

> **Maintainer-only skill — outside `canonical/`.** This is the lone exception to the canonical-source pattern. It lives at `.claude/skills/aid-generate/` only and is NOT in `canonical/skills/`. Edits to this skill are made directly to its files. Reason: it generates the install trees, so it cannot itself be generated from canonical without a chicken-and-egg deployment problem.

This skill regenerates the three install trees (`claude-code/`, `codex/`, `cursor/`) from
the single canonical source (`canonical/`) and the per-tool profiles (`profiles/`).

**When to run:** any time a canonical skill, agent, or template is edited, and before
committing changes to the install trees. Also run to verify the install trees are in sync
with canonical after any manual edits.

**Safety boundary:** the generator only writes to and deletes files it previously emitted
(recorded in `{tool}/emission-manifest.jsonl`). User-created files inside install trees
are never touched.

---

## Pre-flight Checks

Before executing any state, verify:

1. Python 3.11+ is available:
   ```bash
   python --version
   ```
   Required for `tomllib` (stdlib from 3.11). Abort with clear error if unavailable.

2. `canonical/` directory exists at the repo root:
   ```bash
   ls canonical/agents/ canonical/skills/ canonical/templates/ canonical/rules/
   ```

3. At least one profile TOML exists:
   ```bash
   ls profiles/
   ```

4. The repo is a git working tree (for the REPORT `git diff --stat`):
   ```bash
   git rev-parse --git-dir
   ```

If any pre-flight check fails, print an error and stop.

---

## State Detection

Parse arguments from the invocation context:

- `--tool {claude-code|codex|cursor}` → set `SELECTED_PROFILES` to the single named profile.
  If not provided, `SELECTED_PROFILES = [claude-code, codex, cursor]`.
- `--dry-run` → set `DRY_RUN=true`. In dry-run mode, renderers write to a temporary
  scratch directory; no changes are made to the install trees. A diff report is printed at
  the end instead of a live manifest write.

Print: `[State: LOAD]`

---

## Mode: LOAD

For each profile in `SELECTED_PROFILES`, load and validate the profile TOML:

```bash
python .claude/skills/aid-generate/scripts/profile.py --profile profiles/{tool}.toml
```

Expected output: `OK: profiles/{tool}.toml — profile '{tool}' is valid`

If any profile fails validation, abort.

Also load the **previous** emission manifest (if it exists) for each selected profile:

```
{tool}/emission-manifest.jsonl   (e.g. claude-code/emission-manifest.jsonl)
```

The previous manifest is used in RENDER to compute `diff(prev, curr)` and identify
files to delete.

Print: `[1/{N}] Loaded profile: {tool}` for each profile.
Print: `[State: VALIDATE]`

---

## Mode: VALIDATE

Confirm canonical completeness:

1. Each AID skill phase has a corresponding `canonical/skills/aid-{name}/` directory with
   a `SKILL.md`. The 10 expected skills are:
   `aid-init`, `aid-discover`, `aid-interview`, `aid-specify`, `aid-plan`, `aid-detail`,
   `aid-execute`, `aid-deploy`, `aid-monitor`, `aid-summarize`.

   ```bash
   ls canonical/skills/
   ```

2. All 22 canonical agents exist under `canonical/agents/`.

   ```bash
   ls canonical/agents/ | wc -l
   ```
   Expected: 22 files.

3. `canonical/templates/` subtree is non-empty.

If validation finds missing content, print a clear inventory of what is missing and abort.

Print: `[State: RENDER]`

---

## Mode: RENDER

For each profile in `SELECTED_PROFILES`:

Print: `[{i}/{N}] Rendering {tool}...`

1. **Determine output root:**
   - Live mode: `{tool}/` (e.g. `claude-code/`, `codex/`, `cursor/`)
   - Dry-run mode: a temporary scratch directory (created per profile)

2. **Run the three renderers in order:**

   ```bash
   python .claude/skills/aid-generate/scripts/render_agents.py \
     --canonical-root . \
     --profile profiles/{tool}.toml \
     --output-root {output_root}

   python .claude/skills/aid-generate/scripts/render_skills.py \
     --canonical-root . \
     --profile profiles/{tool}.toml \
     --output-root {output_root}

   python .claude/skills/aid-generate/scripts/render_templates.py \
     --canonical-root . \
     --profile profiles/{tool}.toml \
     --output-root {output_root}
   ```

   Each renderer internally calls `manifest.add()` for every emitted file.

3. **Write the manifest** (live mode only):
   ```
   {tool}/emission-manifest.jsonl
   ```
   In dry-run mode, write the manifest to the scratch directory instead.

4. **Deletion pass** (live mode only):
   Compare `diff(prev_manifest, curr_manifest)` to find `removed_dst`.
   For each path in `removed_dst`:
   ```bash
   rm {tool}/{dst}
   ```
   Prune empty parent directories within the generator-owned subtree.
   Print: `Deleted: {dst}` for each deletion.

   In dry-run mode, print `[DRY-RUN] Would delete: {dst}` but do not delete.

Print: `[{i}/{N}] Done: {tool} — {file_count} files emitted`
Print: `[State: VERIFY]`

---

## Mode: VERIFY

### VERIFY-4a (hard gate)

Run the deterministic gate:

```bash
python .claude/skills/aid-generate/scripts/verify_deterministic.py \
  --canonical-root . \
  --report-path .aid/work-002-canonical-generator/verify-4a-report.json
```

If the exit code is non-zero: **abort**. Print the verify-4a-report.json offenders.
Do not proceed to REPORT.

In dry-run mode: skip the in-tree write of the manifest and run verify against the
scratch directory instead of the live install trees.

### VERIFY-4b (advisory)

Run the advisory conformance check:

```bash
python .claude/skills/aid-generate/scripts/verify_advisory.py \
  --canonical-root . \
  --report-path .aid/work-002-canonical-generator/verify-4b-report.json
```

Always exits 0. Capture `skipped_count` and `warning_count` from the JSON report for REPORT.

Print: `[State: REPORT]`

---

## Mode: REPORT

Print a concise summary of the run:

```
=== aid-generate REPORT ===
Mode: [LIVE | DRY-RUN]
Profiles rendered: {tool1}, {tool2}, {tool3}

Per-profile summary:
  claude-code:
    Files emitted: {n}
    Files deleted: {n}
    Manifest:      claude-code/emission-manifest.jsonl
  codex:
    Files emitted: {n}
    Files deleted: {n}
    Manifest:      codex/emission-manifest.jsonl
  cursor:
    Files emitted: {n}
    Files deleted: {n}
    Manifest:      cursor/emission-manifest.jsonl

VERIFY-4a: PASS
VERIFY-4b: skipped_count={n} (URLs pending fetch) | warning_count={n}

Git diff:
[output of: git diff --stat -- claude-code/ codex/ cursor/]

=== END REPORT ===
```

In dry-run mode, the "Git diff" section shows the diff between the scratch directories
and the current install trees (using `diff -r`).

---

## Quality Checklist

Before calling the run complete, confirm:

- [ ] Python 3.11+ available (`python --version` shows 3.11 or higher)
- [ ] All selected profiles parsed without errors (`validate()` returned `[]`)
- [ ] `canonical/` completeness verified: 10 skills, 22 agents, non-empty templates
- [ ] All three renderers completed without errors
- [ ] `emission-manifest.jsonl` written for each rendered profile
- [ ] VERIFY-4a: byte-identical re-render PASS, presence audit PASS, frontmatter parse PASS
- [ ] VERIFY-4b: `skipped_count` surfaced in REPORT (currently 8 — all URLs pending fetch)
- [ ] REPORT printed to stdout
- [ ] In live mode: `git diff --stat` shows only install-tree paths (no canonical/ changes)

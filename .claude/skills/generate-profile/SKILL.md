---
name: generate-profile
description: >
  Regenerates the agents-only profile trees (profiles/<tool>/: agents + aid-tool.conf) from canonical/, then resyncs this repo's dogfood install.
  Maintainer-only tooling; never shipped to end users.
  State machine: LOAD -> VALIDATE -> RENDER -> VERIFY -> REPORT.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "no arguments: regenerates every profile listed in profiles/*.toml, then resyncs the dogfood install"
---

# AID Install-Tree Generator

> **Maintainer-only skill — outside `canonical/`.** This is the lone exception to the canonical-source pattern. It lives at `.claude/skills/generate-profile/` only and is NOT in `canonical/skills/`. Edits to this skill are made directly to its files. Reason: it generates the profile trees, so it cannot itself be generated from canonical without a chicken-and-egg deployment problem.

This skill regenerates the per-tool profile trees (`profiles/claude-code/`, `profiles/codex/`, `profiles/cursor/`,
`profiles/copilot-cli/`, `profiles/antigravity/`) from the canonical agents (`canonical/agents/`) and the per-tool
profile TOMLs (`profiles/*.toml`). Skills and the runtime are never rendered: `release.sh` copies them byte-for-byte
from `canonical/` into the shared payload.

**When to run:** any time canonical content is edited (agents and templates are rendered; skills and the runtime
reach this repo's install through the dogfood resync that the run ends with), and before committing those changes.
Also run after any manual edit to a profile tree to check it against canonical. The run overwrites manual edits.

**Safety boundary:** the generator deletes each `profiles/<tool>/` directory in full and renders it again. It
touches nothing else in the render step, and no manifest is written or read. Never hand-edit a profile tree: the next
run overwrites it, and the CI `render-drift` job fails when a profile tree differs from a fresh render.

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
   ls canonical/agents/ canonical/skills/ canonical/aid/templates/
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

The generator takes no arguments. It always regenerates every profile TOML in `profiles/*.toml`
(`SELECTED_PROFILES` = all of them). There is no per-tool flag and no dry-run mode. For a check that writes nothing,
run `python .claude/skills/generate-profile/scripts/render.py --self-test --canonical-root .`.

Print: `[State: LOAD]`

---

## Mode: LOAD

For each profile TOML in `profiles/*.toml`, load and validate it:

```bash
python .claude/skills/generate-profile/scripts/aid_profile.py --profile profiles/{tool}.toml
```

Expected output: `OK: profiles/{tool}.toml — profile '{tool}' is valid`

If any profile fails validation, abort.

Print: `[1/{N}] Loaded profile: {tool}` for each profile.
Print: `[State: VALIDATE]`

---

## Mode: VALIDATE

Confirm canonical completeness:

1. Every AID skill has a corresponding `canonical/skills/aid-{name}/` directory with
   a `SKILL.md`. The taxonomy **sums**, and that is the point — a decomposition whose
   parts do not add up to the total is how this file was wrong twice:

   ```
   75 skill directories
     = 17 curated (NOT catalog rows; includes the aid-triage router)
     + 58 catalog rows
         = 34 verb-first shortcut skills (one generated per non-`repurpose` row)
         + 24 hand-authored `repurpose` skills (each with its own directory;
           includes aid-ask, aid-deploy and aid-monitor, which are
           re-registered classics and therefore NOT among the 18)
   ```

   **Do not hand-list the curated skills here.** A list was maintained inline and drifted:
   it named 14 skills while claiming 17, included `aid-deploy`/`aid-monitor`/`aid-query-kb`   <!-- count-history -->
   (catalog rows at the time, not curated), omitted the connector and ticket skills, and then
   added `aid-triage` and `aid-ask` a second time on top — summing to 113 for what was then a
   111-skill corpus. Derive the set instead:

   ```bash
   # curatedOnly = the curated roster MINUS anything that is also a catalog row
   # (named, not numbered: the count above is the derivation's output, never a literal to keep)
   node -e "import('./site/scripts/skills/skill-counts.mjs').then(async m => {
     const p = await import('./site/scripts/skills/paths.mjs');
     const c = m.deriveSkillCounts(p.REPO_ROOT);
     console.log(c.directories, '=', c.curatedOnly, '+', c.catalogRows,
                 '|', c.catalogRows, '=', c.shortcuts, '+', c.repurposed);
     console.log(c.curatedOnlyNames.join(', '));
   })"

   ls canonical/skills/ | wc -l   # must equal the first number printed above
   ```

   Rather than hardcoding the shortcut names, check that every catalog row plus every
   curated skill has a rendered `canonical/skills/<name>/SKILL.md` directory.

2. All 9 canonical agents exist under `canonical/agents/`.

   ```bash
   ls canonical/agents/ | wc -l
   ```
   Expected: 9 directories.

3. `canonical/aid/templates/` subtree is non-empty.

If validation finds missing content, print a clear inventory of what is missing and abort.

Print: `[State: RENDER]`

---

## Mode: RENDER

1. **Output:** each profile is written to `profiles/<tool>/` and holds exactly two things: the rendered agents
   under `profiles/<tool>/<root>/agents/` (`profiles/claude-code/.claude/agents/`,
   `profiles/codex/.codex/agents/`, `profiles/cursor/.cursor/agents/`,
   `profiles/copilot-cli/.github/agents/`, `profiles/antigravity/.agent/agents/`) and
   `profiles/<tool>/aid-tool.conf`, the descriptor the release packages with the agents.

2. **Run the generator** (renders ALL profiles in one pass; no flags):

   ```bash
   python .claude/skills/generate-profile/scripts/run_generator.py
   ```

   For each `profiles/*.toml`, `run_generator.py` validates the profile, deletes its `profiles/<tool>/`
   directory, and calls `render_profile` (`render.py`) to write the agents and `aid-tool.conf` again. After
   all profiles are rendered it runs the deterministic and advisory verify checks (below), then runs
   `sync_dogfood.py` to resync this repo's own install (see Dogfood Resync). A failure at any step stops the
   run with a non-zero exit code.

Print: `[State: VERIFY]`

---

## Mode: VERIFY

### VERIFY (deterministic) (hard gate)

Run the deterministic gate:

```bash
python .claude/skills/generate-profile/scripts/verify_deterministic.py \
  --canonical-root . \
  --report-path .aid/.temp/generate-profile/verify-deterministic-report.json
```

If the exit code is non-zero: **abort**. Print the verify-deterministic-report.json offenders.
Do not proceed to REPORT.

### VERIFY (advisory) (advisory)

`run_generator.py` already runs the deterministic check, and the advisory check too. The standalone commands
below also write the JSON reports.

Run the advisory conformance check:

```bash
python .claude/skills/generate-profile/scripts/verify_advisory.py \
  --canonical-root . \
  --report-path .aid/.temp/generate-profile/verify-advisory-report.json
```

Always exits 0. Capture `skipped_count` and `warning_count` from the JSON report for REPORT.

Print: `[State: REPORT]`

---

## Mode: REPORT

Print a concise summary of the run:

```
=== generate-profile REPORT ===
Profiles rendered: {tool1}, {tool2}, ..., {toolN}

Per-profile summary:
  claude-code:
    Files emitted: {n}     (profiles/claude-code/: agents + aid-tool.conf)
  codex:
    Files emitted: {n}     (profiles/codex/)
  cursor:
    Files emitted: {n}     (profiles/cursor/)
  copilot-cli:
    Files emitted: {n}     (profiles/copilot-cli/)
  antigravity:
    Files emitted: {n}     (profiles/antigravity/)

VERIFY (deterministic): PASS
VERIFY (advisory): skipped_count={n} (URLs pending fetch) | warning_count={n}
Dogfood resync: [summary printed by sync_dogfood.py]

Git diff:
[output of: git diff --stat -- profiles/]
[dogfood paths changed by the resync: git status --short]

=== END REPORT ===
```

---

## Dogfood Resync (this repo's install trees)

This repo installs AID into itself. Its tracked install trees are `aid update` output, not hand-copied
files: `.agents/skills/aid-*`, the `.claude/skills/aid-*` mirror, `.aid/runtime/`, `.claude/agents/`,
`.cursor/agents/`, the managed regions of `AGENTS.md` and `CLAUDE.md`, the managed blocks of
`.gitignore` and `.gitattributes`, `.aid/.aid-manifest.json` and `.aid/settings.yml`. A resync writes
them, and they are committed with the change that produced them. Maintainer-owned paths are never
written by a resync: `.claude/skills/generate-profile/`, `.claude/skills/release-aid/`,
`.claude/settings.json`, `.claude/output-styles/` and `.cursor/rules/`.

**Shortcut: `sync_dogfood.py`.** `run_generator.py` runs it after every regeneration. Run it directly to
resync without regenerating:

```bash
python .claude/skills/generate-profile/scripts/sync_dogfood.py                 # resync this repo
python .claude/skills/generate-profile/scripts/sync_dogfood.py --check         # report drift, write nothing
python .claude/skills/generate-profile/scripts/sync_dogfood.py --target <dir>  # another project root
```

It runs `bash release.sh --stage-only --out <tmp>`, then `bin/aid update --from-bundle <tmp> --target <root>`
with `AID_HOME=<tmp-home>` and `AID_NO_UPDATE_CHECK=1`, so the maintainer's registry and the network are
never touched. `--check` runs `bin/aid status --target <root>` and reads its `Shared files` block; a
`Layout:` line (manifest not yet format 3) counts as drift. `--stage-only` never runs the generator, so the
chain `run_generator.py` -> `sync_dogfood.py` -> `release.sh --stage-only` ends without recursing.

**Release-faithful procedure.** Use this when the staged release artifacts must be exercised, as at release time:

```bash
bash release.sh --dry-run                                   # clean tree required; stages .aid/.temp/release-<V>
AID_HOME=<tmp-home> AID_NO_UPDATE_CHECK=1 \
  bin/aid update --from-bundle .aid/.temp/release-<V> --target .
```

`--dry-run` runs the render check, which runs `run_generator.py` and therefore the dogfood resync, so the
working tree can be dirty when the command returns. Review the changes under the install trees and commit
them with the change, or revert them. The `AID_HOME` and `AID_NO_UPDATE_CHECK` prefix keeps the
maintainer's registry and the network out of the run, as the shortcut does.

**Idempotency.** A second resync prints `up to date` for `shared` and for every tool, and
`git status --porcelain` is empty afterwards.

**Testing a resync.** Do not test a resync against this repo, because the first run deletes `.claude/aid/`,
which the running pipeline may still use. Test on a scratch copy instead: `git archive HEAD | tar -x -C <scratch>/copy`,
then `git init` and commit inside the copy, then `sync_dogfood.py --target <scratch>/copy`.

**Rollback.** Run from the repo root, with `<pre-resync>` the commit before the resync:

```bash
git checkout <pre-resync> -- .claude .cursor CLAUDE.md AGENTS.md .aid/.aid-manifest.json .aid/settings.yml .gitignore .gitattributes
rm -rf .agents/skills/aid-* .aid/runtime
```

Then commit the result. The originals that the resync moved aside remain under `.aid/.trash/` (gitignored).

## Quality Checklist

Before calling the run complete, confirm:

- [ ] Python 3.11+ available (`python --version` shows 3.11 or higher)
- [ ] All profile TOMLs parsed without errors (`validate()` returned `[]`)
- [ ] `canonical/` completeness verified against the derivation above, and the decomposition
      SUMS: directories = curatedOnly + catalogRows, and catalogRows = shortcuts + repurposed.
      Also: 9 agents, non-empty templates.
- [ ] All renderers completed without errors
- [ ] Each `profiles/<tool>/` holds only `aid-tool.conf` and the `<root>/agents/` folder
- [ ] VERIFY (deterministic): byte-identical re-render PASS, presence audit PASS, frontmatter parse PASS
- [ ] VERIFY (advisory): `skipped_count` surfaced in REPORT (currently 8 — all URLs pending fetch)
- [ ] REPORT printed to stdout
- [ ] `git diff --stat -- profiles/` shows only profile-tree paths (no canonical/ changes)
- [ ] Dogfood resync done: `sync_dogfood.py --check` reports clean, and the resynced install trees are committed (see Dogfood Resync)

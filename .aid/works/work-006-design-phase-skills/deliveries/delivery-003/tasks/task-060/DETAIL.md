# task-060: Build helper, full five-profile render, both dogfood trees resynced, byte-identity green

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-060/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** CONFIGURE

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-059

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §6 steps 1-4, REQUIREMENTS
  **C-5**, **NFR-1** and **AC-1**. It closes BLUEPRINT criterion **2** -- the build helper, then the
  **full** `run_generator.py`, both dogfood trees resynced, and byte-identity green over **both**
  tuples in all three directions.
- **This is the committed render, not a throwaway.** delivery-002's task-039 produced a local render
  that task-048 reverted; this one is the real one, and it is the only render in the work whose output
  is committed. It runs after every `canonical/` edit in the work has landed, which is exactly why it
  sits here and not earlier.
- Run, in this order (C-5): `python .claude/skills/generate-profile/scripts/build-shortcut-skills.py`,
  then `python .claude/skills/generate-profile/scripts/run_generator.py` as a **full** run -- never a
  per-script or partial render. `architecture.md § Gotchas` (`:490-502`) is the source of that rule
  and names the failure it prevents: stale emission manifests failing CI render-drift.
- **Resync both repo-root dogfood trees, not just the obvious one:** `.claude/` from
  `profiles/claude-code/.claude/` **and** `.cursor/` from `profiles/cursor/.cursor/`. The
  load-bearing property is that **nothing writes them as a side effect of the render**, which is
  why an explicit resync step exists at all. `.cursor/` is the half that gets forgotten twice; it
  holds its own byte-identity tuple with its own disjoint key prefix, so omitting it fails the gate
  this task's next step runs.
- **One correction to feature-006 §6 step 3, made by resolving its basename against disk.** That
  step attributes the dogfood trees to `setup.sh` -- *"the dogfood trees are reached only by
  `setup.sh`"*. **There is no `setup.sh` anywhere in this repository**; the repo-root installers are
  `install.sh` and `install.ps1`, and `install.sh` bootstraps the global `aid` CLI rather than
  writing a project tree (`install.sh:1-30`). What `project-structure.md:158-159` actually says of
  `.claude/` and `.cursor/` is *"a rendered claude-code profile"* / *"a rendered cursor profile"*,
  each with **"No (regenerate via install)"** in its tracked-state column. So the mechanism is the
  install path, not a named script, and the conclusion §6 draws from it is unchanged and correct:
  `run_generator.py` writes `profiles/` and nothing else, so the two dogfood trees must be resynced
  by this task explicitly.
- **The resync is a merge onto the dogfood tree, never a wholesale replace, and the reason is a closed
  allowlist rather than a judgement.** `tests/canonical/test-dogfood-byte-identity.sh:126-156` defines
  `dbi_allowlisted()`, the documented non-generator set under `.claude/` -- it explicitly admits
  `skills/generate-profile/*` (`:149`) and `skills/release-aid/*` (`:150`). Both are repo-local,
  maintainer-only and absent from every profile source, so a `rm -rf` style resync would delete them,
  destroying this task's own toolchain and delivery-001's committed
  `.claude/skills/release-aid/SKILL.md` (feature-001 AC-7/AC-8). `:174` defines the `.cursor/`
  counterpart, which is narrower.
- **The thirty-six new descriptions and the thirty-four regenerated ones must reach all five
  profiles**, since that is the only thing that makes AC-12's work adopter-visible. The five profile
  roots are `profiles/claude-code/.claude/`, `profiles/codex/.codex/`, `profiles/cursor/.cursor/`,
  `profiles/copilot-cli/.github/` and `profiles/antigravity/.agent/` -- the profile path prefix is
  load-bearing, because three of the five bare root names do not exist at the repository root and a
  fourth is the GitHub config directory there.
- **`canonical/skills/` is declared as a write** because `build-shortcut-skills.py` writes
  `SKILLS_ROOT / <name> / "SKILL.md"` for every non-`repurpose` row (`:363-377`) and removes orphaned
  marker-tagged directories (`:394-398`). All sixty `repurpose` rows must come out byte-identical --
  that is the **only** oracle for the `repurpose` field, which the parser reads permissively with
  `r.get("repurpose", False)` (`:354`).
- Out of scope: the freshness oracle, which is a **different** check and is task-061's -- a
  consistently stale render passes byte-identity and fails render-drift; every count-bearing surface
  and its retune (task-062, task-069); the `tests/coverage-baseline.tsv` re-bootstrap (task-063); and
  the site's generated skill surface (task-064), which is regenerated by the site's own scripts and
  not by `run_generator.py`.

**Acceptance Criteria:**
- [ ] **C-5's order, evidenced rather than asserted.** `build-shortcut-skills.py` runs **first**, and
      afterwards `python .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check`
      exits 0 and prints `OK:`; then the **full** `run_generator.py` runs. The record states both
      commands in the order they were run
- [ ] **Every one of the sixty `repurpose` bodies is byte-identical across the helper run.**
      `git diff --exit-code HEAD -- canonical/skills/` is clean **except** for the paths the helper
      legitimately rewrote, and the record enumerates those paths. A row that lost `repurpose: true`
      parses cleanly and is silently regenerated; only this diff catches it
- [ ] **All 112 skills are present and invocable in both dogfood trees.**
      `ls -1d .claude/skills/aid-*/ | wc -l` captured to a variable -> `112`, and the equivalent
      count under `.cursor/` matches its own profile source's count taken from
      `profiles/cursor/emission-manifest.jsonl`
- [ ] **The new descriptions reached all five profiles.** For a witness drawn from each of the three
      strata -- one generated doorway, one curated skill and one of the thirty-six new skills -- the
      rendered `SKILL.md` under each of the five profile roots carries the post-sweep description, and
      `grep -rc 'Direct-entry Lite-path shortcut' profiles/` captured to a variable -> `0`
- [ ] **BLUEPRINT criterion 2's gate: `bash tests/canonical/test-dogfood-byte-identity.sh` is
      green, with both key sets reported.** The run's output carries `DBI00*`, `DBI01`, `DBI-FWD`,
      `DBI-REV` and `DBI-ORPHAN` **and** `DBI-CUR00*`, `DBI-CUR01`, `DBI-CUR-FWD`, `DBI-CUR-REV` and
      `DBI-CUR-ORPHAN`. A report that names only the first set is a report over one tuple
- [ ] **The resync destroyed nothing repo-local.** `git diff --exit-code HEAD --
      .claude/skills/release-aid/SKILL.md` is clean, `.claude/skills/generate-profile/scripts/`
      still holds all eight of its scripts, and
      `grep -c Unreleased .claude/skills/release-aid/SKILL.md` captured to a variable is still `0` --
      delivery-001's AC-7/AC-8 deliverable lives inside a tree this task rewrites wholesale, so it is
      guarded by name
- [ ] **Configuration is idempotent**, evidenced by a command that can produce the evidence: capture
      `find profiles .claude .cursor -type f -print0 | sort -z | xargs -0 sha256sum` to a file, re-run
      `build-shortcut-skills.py` and the full `run_generator.py`, capture again, and `diff` the two
      captures -> **empty**. `git status --porcelain` is not the oracle here: it emits two status
      characters and a path per line and no content hash, so it cannot witness byte-identity
- [ ] **No plaintext secrets**: the render adds, modifies or deletes nothing under
      `.aid/connectors/.secrets/` and introduces no credential-bearing path
- [ ] **The render is committed, and only the render.** The commit's file list is confined to
      `profiles/`, `.claude/`, `.cursor/` and any `canonical/skills/` path the helper rewrote; paths
      are staged **explicitly**, never with `git add -A`, `git add .`, `git add -u` or `git commit -a`
- [ ] `git diff --exit-code -- tests/ site/ docs/ .aid/knowledge/ canonical/aid/templates/` is clean
      -- the render touches none of them, and `tests/coverage-baseline.tsv` is **not**
      re-bootstrapped here (a CI-only run, task-063's)
- [ ] All section-6 quality gates pass

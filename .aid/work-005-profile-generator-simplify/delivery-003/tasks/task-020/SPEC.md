# task-020: test-multitool-isolation.sh structural acceptance suite

**Type:** TEST

**Source:** work-005-profile-generator-simplify -> delivery-003

**Depends on:** task-014

**Scope:**
- Add the new structural acceptance suite `tests/canonical/test-multitool-isolation.sh` (the durable, automatable half of AC4 per feature-004 SPEC §AC4, OQ5):
  - `T`-prefixed assertion IDs; source `tests/lib/assert.sh`.
  - It is **glob-discovered by `tests/run-all.sh:33`** — do NOT edit `run-all.sh` or any workflow to register it (no run-all.sh / CI edit needed).
  - In a throwaway repo, run `aid add claude-code,cursor,codex` (one version, FR10/FR11 invariant).
  - Assert each tool's tree exists with the uniform `{agents,skills,aid}` shape under its own root (`.claude/`, `.cursor/`, `.codex/`).
  - Assert the same canonical skill/agent bodies are **byte-identical across trees** (AC1).
  - Assert **no tree references a foreign root basename** (grep each tree for the other tools' root basenames).
- **`$HOME` pin + escape canary (MANDATORY):** force `$HOME` to a throwaway dir for the whole run and assert via an escape canary that the real user home was never touched (the migration-scan-defaults-to-`$HOME` hazard).
- ASCII-only.
- **Out of scope:** the AC4 *behavioral* 3-tool check (a delivery-gate step run by aid-execute, not a test file); the AC3 all-green-CI gate; `release.sh` (task-014); any `run-all.sh` / `test.yml` / `release.yml` edit; the emitter-test CI de-wire (`test.yml:97-98`, `release.yml:166-167`, owned by feature-002); the 001/002/003-owned tests.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-multitool-isolation.sh` exists, is `T`-prefixed, sources `tests/lib/assert.sh`, and is auto-discovered + green under `tests/run-all.sh` with NO `run-all.sh` / workflow edit.
- [ ] After `aid add claude-code,cursor,codex`, each tool's tree exists with the uniform `{agents,skills,aid}` shape under its own root (`.claude/`, `.cursor/`, `.codex/`).
- [ ] Canonical skill/agent bodies are asserted byte-identical across the three trees (AC1).
- [ ] No tree references a foreign root basename (grep assertion) — the structural half of AC4 (each tool uses its own tree; no foreign-root refs).
- [ ] `$HOME` is pinned to a throwaway dir and an escape canary asserts the real user home was never touched.
- [ ] The script is ASCII-only.
- [ ] TEST defaults: tests are deterministic with clean setup/teardown; the structural acceptance criteria from feature-004 AC4 are covered.
- [ ] All §6 quality gates pass.

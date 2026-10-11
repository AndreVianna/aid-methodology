# task-021: Clean-slate upgrade suite for every v3 layout and the root-file regions

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

**Type:** TEST

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-13, AC-14

**Depends on:** task-015

**Scope:**
- `tests/canonical/test-aid-migrate.sh`: build bundles with `tests/lib/bundle.sh`; re-key the
  existing format-upgrade cases whose expectations change (settings stamp 5, manifest format 3).
- AC-13, exactly as worded in REQUIREMENTS.md § 9: one v3 fixture per tool (Antigravity
  `.agent/skills`, and a Codex fixture with the legacy `.agents/aid/`), each holding one
  user-modified AID file in the old `skills/aid-*` and one in the old `aid/` subtree, plus one
  non-AID user file in each old directory. After `aid update --from-bundle <staging>`: the AC-3 and
  AC-7 checks; no `aid-*` under `.codex/skills`, `.cursor/skills`, `.github/skills`,
  `.agent/skills`; no `<root>/aid/`; every old AID-owned file, modified or not, byte-for-byte at
  `.aid/.trash/<original-path>`; non-AID files unchanged; `.aid/settings.yml` `format_version` = 5.
  A second `aid update` prints `up to date` for every tool and leaves `.aid/.trash/` unchanged.
  Cover both manifest-backed and manifest-less variants, including two tools and legacy Codex.
  Inject failure during retirement, after `retired=true` but before the manifest write (including
  after one v4 copy), and after the manifest/stamp but before record cleanup. On retry, the exact
  recorded tool set is restored, AC-3 and AC-7 pass, non-AID shas are unchanged, and the record
  is removed after success. `retired=true` skips retirement of newly copied v4 files; post-stamp
  recovery leaves the trash snapshot unchanged. Also cover invalid record schemas, future
  formats, staging failure, dry-run, atomic-record-write failures, add/remove gates, and a named
  update tool outside the pending record set, per task-015's observable criteria.
- AC-14 case (c), as worded (the § 11 test plan places (a), (b), (e) and (f) in
  `test-shared-install.sh`, task-017, and (d) in `test-multitool-isolation.sh`, task-018): v3
  claude-code fixtures -- a user-edited `CLAUDE.md` with user content above and below the full old
  AID region (every byte outside the old region is preserved in its original order, with one
  import region appended at the end; one LF is inserted only when the remaining non-empty user
  content does not end in LF, and the pre-update file is at `.aid/.trash/CLAUDE.md`); a no-marker `CLAUDE.md`
  (the (b) prefix check passes); a v3 `AGENTS.md` holding the full region (it ends holding the
  pointer region appended by the same LF rule, with its pre-update file at `.aid/.trash/AGENTS.md`). In each, exactly one
  `@AGENTS.md` line in `CLAUDE.md` and one `<!-- AID:BEGIN -->` line in `AGENTS.md`.
- v3 fixtures are built by hand; the suite never reads a work folder. Removed or renamed keys get
  coverage rows.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-aid-migrate.sh --verbose` exits `0`, with `PASS:` lines for each AC-13 clause per tool fixture (five plus the legacy `.agents/aid/` case) and the second-run checks.
- [ ] The same run prints a `PASS:` line for the interrupted-run clause: for each interruption point and both manifest-backed and manifest-less fixtures, the next `aid update` restores exactly the recorded tools, AC-3 and AC-7 pass, `grep -c '"migration"' .aid/.aid-manifest.json` prints `0`, the recovery record is absent, and every non-AID user file keeps its sha256; post-stamp recovery keeps the trash snapshot unchanged.
- [ ] The same run prints `PASS:` lines for invalid-record/future-format refusals, staging failure, dry-run, atomic-write failure, pending-record add/remove gates and out-of-set named tools, each with the expected unchanged snapshot or prevention of the next destructive step.
- [ ] The same run prints `PASS:` lines for AC-14 (c) in its variants (user-edited `CLAUDE.md` with trash copy, no-marker `CLAUDE.md`, v3 `AGENTS.md` with the pointer region) and the one-`@AGENTS.md` / one-`AID:BEGIN` invariant in each.
- [ ] Frozen-clock repeated retirement collisions and preoccupied `.N` suffixes preserve all backup bytes with identical Bash/PowerShell names and ordering.
- [ ] Frozen-clock repeated retirement collisions and preoccupied `.N` suffixes preserve all backup bytes with identical Bash/PowerShell names and ordering.
- [ ] `grep -cE 'profiles/[a-z-]+/' tests/canonical/test-aid-migrate.sh` prints `0`.
- [ ] The coverage-parity gate (run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for this suite.
- [ ] All section-6 quality gates pass.

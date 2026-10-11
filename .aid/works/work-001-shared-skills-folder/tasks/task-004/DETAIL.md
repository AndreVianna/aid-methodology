# task-004: Install-core primitives and the format-3 manifest (bash and PowerShell)

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

**Type:** IMPLEMENT

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-10, AC-16

**Depends on:** -- (none)

**Scope:**
Every item is one behaviour implemented twice, in `lib/aid-install-core.sh` and
`lib/AidInstallCore.psm1`, in the same commit (FR-14; PowerShell ASCII-only and PS 5.1-safe: no
`??`, no ternary, no `-AsHashtable`).
- Descriptor reader `read_kv_conf` / `Read-AidKvConf` (new): the format in REQUIREMENTS.md § 11
  Feature 001 › Data Model › Descriptor format (ASCII and LF only; split at the first `=`; `#` and
  blank lines ignored; a repeated key is a list; unknown keys ignored; never sourced or evaluated).
  A non-ASCII byte or a CR exits non-zero naming the file.
- Trash move `trash_file` / `Move-AidToTrash` (new) with the § Data Model › `.aid/.trash/`
  collision policy: destination `.aid/.trash/<original-relative-path>`; identical bytes already there
  -> no new copy; different bytes -> rotate to `<path>.<UTC timestamp>`, then the first unused
  `<path>.<UTC timestamp>.N` for N=1,2,...; never overwrite occupied candidates. Fail before
  source loss if rotation fails. Bash and PowerShell use identical candidate ordering and names. `_retire_file` (inside `_migrate_retired_layout`) delegates to it instead of `mv -f`.
- Guarded copy `copy_file_guarded <src> <dst> [<recorded-sha256>]` / `Copy-AidFileGuarded` (new):
  absent -> copy; identical -> leave; differing -> overwrite, and trash the destination first
  (`trash_file`) only when it is DRIFTED: its bytes differ from the recorded sha256 the caller
  passes, or no sha256 is recorded and its bytes differ from the bytes being written. A differing
  destination whose bytes equal the recorded sha256 (an unedited file of the previous version) is
  overwritten with no trash entry. Reports the same counters `copy_file` reports.
- Manifest format 3: `manifest_write`, `_manifest_write_python`, `_manifest_write_bash`,
  `Write-AidManifest`, `Build-ManifestJson` emit the § Data Model › Install manifest shape exactly
  (key order as shown, 2-space indent, LF, trailing newline, `files` sorted by `path` in byte order,
  `users` in `AID_TOOLS` order, `tools.<t>.paths` a plain copy of that tool's `files[].path`).
  Readers `manifest_format`, `manifest_read_shared`, `manifest_read_tool_files`, `manifest_read_host`
  and `Read-AidManifestShared`, `Read-AidManifestToolFiles`, `Read-AidManifestHost` (new). The
  format-2 read path stays, because uninstall and the clean-slate upgrade still read old manifests.
- This task adds the primitives only. The install path keeps writing format 2 until task-009
  switches it; existing suites therefore stay green here.
- Unit suite `tests/canonical/test-install-core-primitives.sh` (new; pins `HOME`; builds its own
  fixtures): descriptor parsing, trash collision policy, guarded copy, and writer byte-identity
  (bash python3 writer, bash pure-bash writer, PowerShell writer when `pwsh` is present).
- Deferred review note (definition-gate ledger row 25): The manifest JSON sample in REQUIREMENTS.md § 11 prints arrays inline, but the python writer (`json.dump(..., indent=2)`) puts each array element on its own line; the three writers must match the python writer's bytes, not the sample's layout.

**Acceptance Criteria:**
- [ ] `read_kv_conf` on a fixture holding a comment, a blank line, `a=b=c` and two `skill_mirror=` lines yields `a` = `b=c` and a two-item `skill_mirror` list; the same file with CRLF endings makes it exit non-zero with the file path in the message. `Read-AidKvConf` gives the same results where `pwsh` exists.
- [ ] Frozen-clock repeated differing backups and preoccupied timestamp suffixes preserve every byte, place newest bytes at `.aid/.trash/<rel>`, and use the first unused `.N` suffix; identical retry is idempotent and Bash/PowerShell names and ordering match.
- [ ] `copy_file_guarded` on an absent, an identical, a differing-but-unedited (destination sha256 equals the recorded one) and a drifted destination (a recorded sha256 that the bytes no longer match; and, with no recorded sha256, differing bytes) produces copied, unchanged, overwritten-with-no-trash and trashed-then-copied outcomes respectively, and only the two drifted cases write under `.aid/.trash/`.
- [ ] For one fixed input, the python3 writer, the pure-bash writer and (where `pwsh` exists) the PowerShell writer produce JSON that is byte-identical after masking `installed_at`, and it equals a committed golden file whose key order matches § Data Model.
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-install-core-primitives.sh` exits `0`.
- [ ] `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`; `bash tests/canonical/test-aid-cli.sh` and `bash tests/canonical/test-multitool-isolation.sh` give the same per-assertion PASS/FAIL result as on this task's base commit (no caller is switched yet).
- [ ] All section-6 quality gates pass.

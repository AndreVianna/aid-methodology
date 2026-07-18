# task-003: Foundation writers write-setting.sh + write-requirement.sh + MANIFEST co-vendor

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
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

**Type:** IMPLEMENT

**Source:** feature-001-write-infrastructure -> delivery-001

**Depends on:** task-001

**Scope:**
- Ship the two brand-new non-interactive writers feature-001 owns, and co-vendor all three canonical writers with the dashboard unit so the server self-locates them at runtime, version-locked to the reader/server.
- `write-setting.sh` (new; scriptable sibling of `.claude/aid/scripts/config/read-setting.sh`): `write-setting.sh --path <section.key> --value <V> [--file <settings.yml>]`. Closed `--path` allowlist `{project.name, project.description, review.minimum_grade}` (any other -> exit 4). `review.minimum_grade` validated `^[A-F][+-]?$`. `--value` rejects `\n`, embedded `"` and `\` -> exit 4 (KI-001: keeps the written value inside the strip-only alphabet every settings reader round-trips identically). Surgical flat-section rewrite of the `<section>:` -> `  <key>: <value>` line (mirrors `read-setting.sh`'s `lookup` model); creates the key (and section) if absent; every other line byte-preserved; atomic temp-file + `mv`. Exit codes mirror `read-setting.sh` (0 ok; 2 arg/IO; plus 4 invalid value). bash-only.
- `write-requirement.sh` (new; Q3 resolution): `write-requirement.sh --field <Name|Description> --value <V> [env AID_REQUIREMENTS_FILE=<abs path>]`. Target `AID_REQUIREMENTS_FILE` if set, else `<cwd>/REQUIREMENTS.md`. Surgical rewrite of the single `^\s*-\s*\*\*<Field>:\*\*\s*.*` bullet (matching the reader regex); creates it under the leading `# Requirements` heading if absent; all other lines byte-preserved; atomic temp-file + `mv`. `--value` rejects `\n`/`|` -> exit 4. Non-destructive: touches only that bullet -- never the work folder, branch, or worktree (AC5). bash-only.
- Shared exit alphabet with `writeback-state.sh` (0 ok / 2 arg-IO / 4 invalid-value) so the server's DEFAULT_MAP maps both writers correctly.
- Co-vendor `writeback-state.sh`, `write-setting.sh`, and `write-requirement.sh` with the dashboard unit by editing `dashboard/MANIFEST` ONLY (one path per line): `vendor.js`, `vendor.py`, `install.sh`, `install.ps1`, and `release.sh`'s CLI bundle all derive their file set from that single source, guarded by `tests/canonical/test-dashboard-manifest.sh`. Writers self-locate from `$AID_CODE_HOME` (same rationale as `home.html` served from `$AID_CODE_HOME/dashboard`, `bin/aid` ~line 1196).

**Acceptance Criteria:**
- [ ] `write-setting.sh` writes each of the 3 allowed paths as a surgical flat-section rewrite (creating key/section when absent), byte-preserving every other line, atomically (temp-file + `mv`); a disallowed `--path` -> exit 4.
- [ ] `write-setting.sh` rejects a `review.minimum_grade` value not matching `^[A-F][+-]?$` (exit 4) and rejects a `--value` containing `\n`, `"`, or `\` (exit 4; KI-001 round-trip alphabet).
- [ ] `write-requirement.sh` surgically rewrites only the `- **Name:**` / `- **Description:**` bullet (creating it under `# Requirements` when absent), byte-preserving all other lines, atomically; rejects `\n`/`|` (exit 4); never touches the folder, branch, or worktree (AC5).
- [ ] Both new writers' exit alphabet aligns with `writeback-state.sh` (0 ok / 2 arg-IO / 4 invalid-value) so DEFAULT_MAP maps their exits correctly.
- [ ] All three writers are listed in `dashboard/MANIFEST` (single edit); the derived consumers (`vendor.js`/`vendor.py`/`install.sh`/`install.ps1`/release bundle) include them, `tests/canonical/test-dashboard-manifest.sh` passes, and the server can self-locate them from `$AID_CODE_HOME`.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass

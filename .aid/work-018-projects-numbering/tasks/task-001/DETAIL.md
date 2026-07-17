# task-001: Modify `aid projects` — numbered `list` and `remove <N>` (both twins)

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

**Source:** work-018-projects-numbering -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Bash canonical `bin/aid`:
  - `_cmd_projects_list` (:2494): add a 1-based counter incremented once per emitted entry and a leading `#` column to the header (:2508), the rule (:2509), and each row's `printf` (:2525-2526). Preserve the existing marker column (`*`/two-space, :2518-2522) and the PATH/STATE/TOOLS/TIER columns. Leave the empty case (:2538-2540), the unregistered-cwd footnote (:2542-2546), and the `* = current directory` legend (:2548-2552) unchanged.
  - `_cmd_projects_remove` (:2629): before the existing canonicalize step (:2634), classify `_raw_path` purely by shape. If it is **all digits** (`[[ "$_raw_path" =~ ^[0-9]+$ ]]`), treat it as index N — always, never a path, even if a folder of that literal name exists: build the ordered union via `_registry_read_raw_union` (same helper `list` uses), set `count` to its length, parse N base-10 via `10#"$_raw_path"` (so `01` -> 1; `008`/`009` are handled as decimal and never raise a bash octal-literal error such as `$((008))`). Because `^[0-9]+$` admits `0`, add an explicit `N >= 1` value check: on `N < 1` (`0`, `00`) print a clear "index must be a positive integer (>= 1)" message to stderr and `exit 2`; on `N > count` or empty registry (`count == 0`) print a clear "no project numbered N (M registered)" message to stderr and `exit 2`; on `1 <= N <= count` set the target path to the Nth entry and fall through to the existing `registry_unregister` flow (:2642-2660). If the argument **contains a non-digit** it is a path: canonicalize (:2634-2640) and, if it resolves to a currently-registered project, unregister it (:2655) as before; if it does NOT resolve to a registered project, print a clear message to stderr and `exit 2` (replacing the former idempotent no-op). A `-`-prefixed token (`-1`) never reaches this handler — the action-match branch (:2907-2912) sweeps `remove`'s args past the dispatcher's own flag case, so `-1` reaches `_cmd_projects` and is rejected by its unknown-flag case (:2466-2469; PowerShell `bin/aid.ps1:1761-1764`) upstream with exit 2 — so negatives need no handling here.
  - `projects` usage block (:187-202) and top-of-file synopsis comment (:19): document the numbered list and the `remove [<path>|<N>]` form, and rewrite the existing `remove` usage line (:198) to drop the now-false "Works on stale/missing/no-aid entries.  Idempotent." wording and instead state the index form, the numeric errors, and that an unregistered/nonexistent path now errors.
- PowerShell canonical `bin/aid.ps1` (behavior-equal mirror; WinPS-5.1 compatible per `coding-standards.md`):
  - `Invoke-AidProjectsList` (:1604): same `#` column at the header (:1614), rule (:1615), and each row (:1628); same preservation of the marker/columns and the empty/footnote/legend blocks (:1640-1654).
  - `Invoke-AidProjectsRemove` (:1703): same all-digits classification (`$RawPath -match '^[0-9]+$'`) resolved against `Get-RegistryRawUnion` (:1611 helper), same explicit `[int]` `>= 1` value check (`[int]` parses decimal, so PowerShell has no bash-style octal hazard; the regex admits `0`) with `< 1`, `> count`, and empty-registry each -> clear stderr + `script:Exit-Aid 2`; in-range -> fall-through to `Registry-Unregister` (:1731). Path form (any argument with a non-digit): unregister a registered path as before, but a path that does NOT resolve to a registered project now -> clear stderr + `script:Exit-Aid 2` (no idempotent no-op). Negatives are rejected upstream as an unknown flag: the action-match branch (:2833-2844) sweeps `remove`'s args past the dispatcher's flag case, so `-1` reaches `Invoke-AidProjects` and is rejected by its unknown-flag case (:1761-1764) — mirrors the Bash path — so no handling here.
  - `projects` usage block (:238-253): mirror the doc changes, including rewriting the `remove` usage line (:249) to drop the now-false "Works on stale/missing/no-aid entries.  Idempotent." wording and state the index form + that an unregistered/nonexistent path now errors.
- Reuse `_registry_read_raw_union` / `Get-RegistryRawUnion` (single ordering source, FR-6) and `registry_unregister` / `Registry-Unregister` (removal) unchanged — add no new registry primitive.
- Do NOT touch the vendored copies or `bin/aid.cmd` / npm `aid.js`. The npm/pypi packages regenerate their vendored copies of the CLI from `bin/` automatically at package-build/pack time (`packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`); those gitignored, auto-generated copies need no manual re-sync and are out of scope for this task (NFR-2; `module-map.md` Invariants — `packages/*/_vendor/` is regenerated, never hand-edited).

**Acceptance Criteria:**
- [ ] `aid projects list` prefixes each project row with a 1-based sequential number (first row `1`) in `_registry_read_raw_union` order, with the `*` cwd marker preserved and the empty-case/footnote/legend output unchanged. *(SPEC AC-1, AC-8)*
- [ ] `aid projects remove K` for an all-digits `K` in `1 <= K <= N` unregisters the Kth listed project (same ordering `list` numbers against) and changes no other entry. *(SPEC AC-2, AC-6)*
- [ ] `aid projects remove <path>` (argument containing a non-digit) unregisters a registered path exactly as before, `./1` or an absolute path removes a project whose folder is literally named `1` (a bare `1` never does), and `aid projects add` is untouched. *(SPEC AC-3, AC-7, AC-13)*
- [ ] `aid projects remove` errors to stderr with exit `2` and leaves the registry unchanged for: an all-digits `K > N` or an empty registry, an all-digits value `< 1` (`0`, `00`), and a non-digit path that does not resolve to a registered project (no idempotent no-op); a `-`-prefixed `-1` is rejected upstream as an unknown flag (exit `2`). *(SPEC AC-4, AC-5, AC-10, AC-11, AC-12)*
- [ ] The Bash and PowerShell twins are behavior-identical for the numbered `list`, `remove <N>`, and every error case, both twins' usage/help + synopsis document the new forms, the `remove` usage line no longer claims "Idempotent"/"works on stale/missing" but states that an unregistered/nonexistent path now errors, and the vendored copies under `packages/` are left untouched (regenerated from `bin/` at build time, not manually re-synced). *(SPEC AC-9; NFR-1, NFR-2)*
- [ ] All section-6 quality gates pass.

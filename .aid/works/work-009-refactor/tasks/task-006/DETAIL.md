# task-006: Retarget the three shell state readers to STATE.yml

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-006/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
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

**Type:** REFACTOR

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-002

**Scope:**
- `canonical/aid/scripts/works/enumerate-works.sh`: `state_file="$work_path/STATE.md"` (`:230`)
  becomes `STATE.yml`, and `_frontmatter_value` (`:128-142`) -- the 12-line awk that already strips
  quotes and inline comments -- loses its `NR==1 && $0=="---"` fence guard and scans the whole file
  for a column-0 key. The `"${phase:---}"` degrade-to-sentinel behavior is preserved exactly.
- `canonical/aid/scripts/housekeep/cleanup-classify.sh`: the three state-signal reads (`:326`,
  `:458`, `:538`) retarget the filename, and their `fail:no STATE.md found` diagnostics name the
  new filename.
- `dashboard/scripts/delete-pipeline.sh` -- the **third** shell state reader (`SPEC.md § L-10`,
  FR-7a), and the only one whose read gates a destructive operation. Both halves are ONE atomic
  change and neither may land without the other:
  - the `Running` guard's path read, `_frontmatter_value "$CANDIDATE/STATE.md" lifecycle` (`:348`),
    becomes `$CANDIDATE/STATE.yml`; the guard itself (`:349`, `[[ "$LIFECYCLE" == "Running" ]]` ->
    `exit 7`) is unchanged.
  - `_frontmatter_value` (`:164-178`; `SPEC.md § L-10`'s table says `:164-168`, which stops at the
    fence line -- the function body ends at `:178`) loses its `NR==1 && $0=="---"` fence guard
    (`:168`) and its closing-fence `exit` (`:169`) so the scan covers the whole document -- and it
    is **byte-identical to `enumerate-works.sh:128-142` today (verified by `diff`)**, which is why
    it takes **the identical change `enumerate-works.sh` gets above**. Its header comment
    documents it as a "verbatim mirror of
    enumerate-works.sh"; it must stay byte-identical to that helper after this task, because the
    mirror property is what keeps the two from diverging on the same file. The header comment's
    "Reads only the YAML block delimited by the leading `---` fences" sentence is updated with it.
  - the file's two other `STATE.md` path resolutions move in the same change, or the retarget is
    incomplete: the candidate-reconciliation read `_frontmatter_value "$candidate/STATE.md"
    updated` (`:285` -- the newest-`updated` winner selection across roots, which silently
    degrades to an empty `upd` for every candidate if left behind) and the two header comments
    that resolve the same path (`:41`, `:48`). `SPEC.md § L-10`'s table enumerates only `:348` and
    `:164-168`; these are the same-file siblings, in scope here under SP-15's "no surviving
    reference *resolves a path to one*".
  - **Why atomicity is the property, not tidiness:** `_frontmatter_value` returns empty for a
    missing file (`[[ -f "$file" ]] || return 0`, `:166`) and the guard fires only on the exact
    string `Running`. Retargeting neither half, or only one half, yields an empty `LIFECYCLE` for
    **every** work -- the guard silently becomes an unconditional no-op and the script deletes a
    running pipeline's work folder or worktree.
  - Only one copy exists -- no `canonical/` source, no `profiles/` render, no dogfood copy, no
    PowerShell twin -- so it is hand-edited here, like the `dashboard/scripts/writeback-state.sh`
    fork, and no render step covers it. Editing it here is therefore NOT a C-1 violation.
  - Its *pre-existing* fail-open on a genuinely **missing** state file is preserved, not repaired
    (`SPEC.md § L-12`): hardening it would be an observable behavior change a `restructure` forbids.
- **Carried, not fixed** (`SPEC.md § L-5`, `§ L-12`): `cleanup-classify.sh`'s signal (ii) and
  status note read `> **Status:** Deployed` and a `## Deploy Status` section, neither of which the
  current template emits -- they are ALREADY returning their `fail:` reason against a
  current-shape work. This task preserves that outcome (the signal still degrades to `fail:` with a
  reason, and `scan_s6` still offers every folder with the signals as informational context only)
  and does NOT repair it: repairing it would change observable behavior, which a `restructure`
  forbids.
- No new shared accessor script: `read-state.sh` and a PowerShell twin are explicitly NOT
  introduced (`SPEC.md § L-5`, which re-argues the decision so it survives the third reader).
  The three grounds, none of which is a consumer count: (a) a *scalar* accessor would serve only
  the `enumerate-works.sh` / `delete-pipeline.sh` pair, and that pair is already one
  implementation by documented verbatim mirror -- `cleanup-classify.sh` probes markdown
  structure (`## Deploy Status` table walk, `^> **Status:**` grep), not frontmatter scalars, so
  it could not call one; (b) `delete-pipeline.sh` is the reader that cannot take the dependency --
  it has no `canonical/` source and no render, so sourcing a canonical helper would add a
  `dashboard/` -> `canonical/` runtime coupling and give a destructive-operation guard a new way
  to fail open, the very failure mode `SPEC.md § L-10` closes; (c) the cost is a script plus a
  PowerShell twin plus a test suite plus a five-profile/two-dogfood render fan-out, to remove a
  twelve-line duplication whose non-divergence is already asserted. The extraction trigger is a
  *capability* (the first consumer needing a nested key, a sequence entry or the `§D-3`
  reject-list warnings), not the arrival of an Nth consumer.
- Canonical only for the two canonical readers (C-1): the `profiles/` renders and dogfood copies of
  `enumerate-works.sh` and `cleanup-classify.sh` are regenerated in task-017, never hand-edited
  here. `dashboard/scripts/delete-pipeline.sh` is the single-copy exception above -- it has no
  canonical source and no render, so it is edited in place here.
- OUT of this task: any YAML dependency (C-3); the writer (task-007) and the
  `dashboard/scripts/writeback-state.sh` fork (task-007); the dashboard *server* write-path call
  sites and `home.html` (`SPEC.md § L-11`, task-020); the suites that exercise these scripts
  (task-015).

**Acceptance Criteria:**
- [ ] Against a converted work, `enumerate-works.sh` reports the same `phase` and `lifecycle`
      values it reported for the same work pre-refactor (SP-11).
- [ ] `_frontmatter_value` resolves a column-0 key anywhere in the file, strips both quote styles
      and a trailing inline `#` comment, and no longer requires a leading `---` fence.
- [ ] A missing, empty or unreadable state file still degrades to the `--` sentinel
      (`"${phase:---}"`) and exits 0 rather than failing (SP-11, NFR-8).
- [ ] `cleanup-classify.sh` produces the same classification signals and the same `scan_s6`
      offering as pre-refactor for the same folder, and its diagnostics name `STATE.yml`.
- [ ] The two already-stale signals (`> **Status:**`, `## Deploy Status`) still degrade to `fail:`
      with a reason -- their behavior is byte-equivalent to pre-refactor, and the commit message
      records that this is carried deliberately, not overlooked (`SPEC.md § L-12`).
- [ ] Against a converted work whose `STATE.yml` carries `lifecycle: Running`,
      `dashboard/scripts/delete-pipeline.sh` still refuses and exits 7 -- proving the retarget left
      the guard firing rather than turning it into an unconditional no-op. Asserted behaviorally,
      because a text search cannot see this failure (SP-19a, FR-7a).
- [ ] `delete-pipeline.sh`'s `_frontmatter_value` is byte-identical to `enumerate-works.sh`'s after
      this task -- `diff` of the two function bodies is empty -- and both resolve a column-0 key
      anywhere in the file with no leading `---` fence required (`SPEC.md § L-10`).
- [ ] `delete-pipeline.sh` resolves no `STATE.md` path anywhere: the `Running` guard (`:348`), the
      reconciliation `updated` read (`:285`) and the two header comments (`:41`, `:48`) all name
      `STATE.yml`, and the candidate reconciliation still selects the same newest-`updated` winner
      it selected pre-refactor for the same roots (SP-15, SP-19a).
- [ ] `delete-pipeline.sh`'s pre-existing fail-open on a genuinely missing state file is unchanged
      -- a work folder with no state file behaves exactly as it did pre-refactor -- and the commit
      message records that as carried, not repaired (`SPEC.md § L-12`).
- [ ] None of the three scripts takes a YAML dependency; all remain pure POSIX shell + awk
      (C-3, SP-11).
- [ ] No new `read-state.sh` (or PowerShell twin) is added anywhere.
- [ ] `grep -rn 'STATE\.md' canonical/aid/scripts/works/enumerate-works.sh
      canonical/aid/scripts/housekeep/cleanup-classify.sh dashboard/scripts/delete-pipeline.sh`
      returns nothing except an explicitly labelled legacy reference, if any (SP-15).
- [ ] No file under `profiles/`, `.claude/` or `.cursor/` is edited by this task (C-1); the only
      non-`canonical/` file touched is `dashboard/scripts/delete-pipeline.sh`, which has no
      canonical source.
- [ ] All section-6 quality gates pass.

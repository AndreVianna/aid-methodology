# State: CLEANUP

CLEANUP is the terminal gated stage of `/aid-housekeep`. It runs a deterministic
scan of stale `.aid/` artifacts, presents a tiered per-item checklist for the
user to confirm, deletes only confirmed items (tracked via `git rm`, untracked
via `rm`), commits once on the `aid/housekeep-*` branch, and chains to DONE.

It is reachable BOTH after SUMMARY-DELTA CHAINs forward (full sequence) AND
directly via `--cleanup-only` (`**Mode:** cleanup-only`). In the cleanup-only
entry the C1 predecessor gate is satisfied by the Mode choice — this body does
NOT re-implement the gate.

**NFR1 (no silent deletes):** the checklist is ALWAYS shown before any
`rm`/`git rm`. No path is deleted without appearing checked at the user's
final confirmation.

---

## Step 0 — State-entry: write run-state fields and print banner

Write through `housekeep-state.sh` (never hand-edit `## Housekeep Status`
directly):

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "CLEANUP"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "running"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Last Run" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Print the `[State: CLEANUP]` banner from `SKILL.md § State Detection`:

```
[State: CLEANUP] — Sweeping stale work-area artifacts.
aid-housekeep  ▸ you are here
  [✓ PREFLIGHT ] → [✓ KB-DELTA ] → [✓ SUMMARY-DELTA ] → [● CLEANUP ] → [ DONE ]
```

> **`--cleanup-only` inputs guard (AC10):** When `**Mode:** cleanup-only` is
> set, this body reads ONLY the filesystem scan, git state, `gh` (for signal
> (i)), and each work folder's own `STATE.md`. It does NOT read or assume any
> `**Summary Stage:**` field, `**KB Stage:**` field, or any other KB/summary
> run-state. The skip of KB/Summary stages is already recorded in the
> `## Housekeep Status` block by the SKILL.md entry path; this body's only
> source of input is what it derives from the filesystem and git at runtime.

---

## Step 1 — Run `cleanup-classify.sh` to obtain the candidate list

Determine `REPO_ROOT` (the root of the git repository; the directory containing
`.aid/`) and invoke the classifier. There is **no active work folder to exclude**:
housekeep run-state lives in `.aid/.temp/HOUSEKEEP_STATE_*.md` (not in a work
folder), so `--active-work` is not passed. `cleanup-classify.sh` still hard-skips
the one work folder whose `work-NNN` branch is currently checked out (the legacy
`aid/work-NNN-*` form is also tolerated), and it
**offers every other work folder** for the user to confirm or decline (the user has
the last word — no folder is silently hidden):

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"

CANDIDATES=$(bash .cursor/aid/scripts/housekeep/cleanup-classify.sh \
    --root "$REPO_ROOT")
CLASSIFY_EXIT=$?
```

The script exits 0 on success (candidate list emitted — may be empty if nothing
stale), 1 if `REPO_ROOT` or `.aid/` are missing, 2 on argument error. On
non-zero exit print the error and abort:

```
⚠️  cleanup-classify.sh failed (exit $CLASSIFY_EXIT). See stderr above.
    Cannot continue CLEANUP — re-run /aid-housekeep after resolving the issue.
```

`$CANDIDATES` is newline-separated; each line is a pipe-delimited candidate
record:

```
PATH|TIER|TRACKED|DEFAULT_CHECKED|REASON[|GATE]
```

Where:
- `PATH` — relative path from `REPO_ROOT`
- `TIER` — `0`, `1`, or `2`
- `TRACKED` — `tracked` or `untracked`
- `DEFAULT_CHECKED` — `true` (Tier-0) or `false` (Tier-1/2)
- `REASON` — human-readable classification reason
- `GATE` — (Tier-1 only) `offer` or `explicit-confirm:<reason-why-(ii)-disagrees>`

This body does NOT re-implement scan/tier/matrix/split logic — all
classification is the script's domain (feature-004 SPEC § Testing). Parse the
output records as defined above.

---

## Step 2 — Zero-candidates no-op check

If `$CANDIDATES` is empty (the scan found nothing stale):

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Cleanup Stage" --value "passed"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
```

Print:

```
✓ CLEANUP: no stale .aid/ artifacts found — nothing to clean up.
  Cleanup Stage: passed (no commit — nothing staged).
```

**No commit is made.** Advance: **CHAIN** → [State: DONE].

---

## Step 3 — Present the tiered checklist

> **Tier definitions:**
> - **Tier-0 (clearly safe):** gitignored scratch, heartbeat, cache, stray tool
>   reports, unregistered build outputs. Default: **checked** `[x]`.
> - **Tier-1 (work folders):** `.aid/works/work-*/` folders that passed signal (i)
>   (merged to `master`). Default: **unchecked** `[ ]`.
> - **Tier-2 (review):** loose `.aid/` files that look hand-authored. Default:
>   **unchecked** `[ ]`.
>
> Items with `GATE=explicit-confirm:<reason>` (Tier-1, (i)✓/(ii)✗) are NOT in
> the main checklist — they are handled separately in Step 3b.

### Step 3a — Build the main checklist (all candidates except explicit-confirm items)

Separate candidates into two pools:

1. **Main checklist candidates:** all records where `GATE` is absent, empty,
   or equals `offer`.
2. **Explicit-confirm candidates:** all records where `GATE` starts with
   `explicit-confirm:`.

For the main checklist pool, group by tier and render each row as:

- Tier-0 (default checked):
  ```
  [x] <PATH>  (<TRACKED-label>)  — <REASON>
  ```
- Tier-1/2 (default unchecked):
  ```
  [ ] <PATH>  (<TRACKED-label>)  — review: <REASON>
  ```

Where `<TRACKED-label>` is either `(git rm)` or `(untracked)` based on the
`TRACKED` field (NFR3: the user sees the deletion mechanism per item).

Render the full checklist grouped by tier, for example:

```
Tier-0 — clearly safe (pre-checked):
  [x] .aid/.temp/h5-interview-brief.md  (untracked)  — S1: gitignored temp scratch (.aid/.temp/)
  [x] .aid/.temp/review-pending/scope.md  (untracked)  — S1: gitignored temp scratch (.aid/.temp/)
  [x] .aid/.temp/summarize/spot-check-facts.txt  (untracked)  — S1: gitignored temp scratch (.aid/.temp/)
  [x] .aid/works/work-002-canonical-generator/verify-deterministic-report.json  (untracked)  — S4: stray tool report (verify JSON)

Tier-1 — work folders offered for deletion (unchecked):
  [ ] .aid/works/work-002-canonical-generator  (git rm)  — review: S6: work folder merged+concluded

Tier-2 — review: hand-authored files (unchecked):
  [ ] .aid/some-loose-file.md  (tracked)  — review: Tier-2: loose .aid/ file (hand-authored, not in a known scan root)
```

Use `AskUserQuestion` to present the checklist and ask the user to toggle items:

```
Use AskUserQuestion:
"Here is the list of stale .aid/ artifacts identified for cleanup.

<RENDERED CHECKLIST>

Toggle any items you want to change (check or uncheck), then confirm your final
selection.

- Tier-0 items are pre-checked (clearly safe: temp, cache, stray reports).
- Tier-1/2 items are unchecked — review before selecting.
- Items marked (git rm) are tracked by git and will be staged for deletion
  (recoverable from git history). Items marked (untracked) will be deleted
  with rm -rf (not in git history).

Reply with your final confirmed list of items to delete, or reply 'cancel' to
skip all deletions."
```

Capture the user's confirmed selection as `CONFIRMED_MAIN[]` (the paths the
user checked at confirm time). If the user replies `cancel` or confirms an
empty selection, set `CONFIRMED_MAIN=()`.

### Step 3b — Explicit-confirm prompts for (i)✓/(ii)✗ work folders

For EACH candidate in the explicit-confirm pool, issue a SEPARATE
`AskUserQuestion` that states the specific discrepancy (why signal (ii)
disagrees). Use the `GATE` field's reason text (the part after
`explicit-confirm:`).

Example prompt (one per explicit-confirm folder):

```
Use AskUserQuestion:
"Work folder '.aid/works/work-003-example' shows a discrepancy:

  Signal (i) — merged to master: PASS (PR is MERGED)
  Signal (ii) — STATE.md concluded: FAIL — <why: e.g. STATUS is 'Executing', no merged Deploy row>

This folder's PR appears merged, but its STATE.md does not show a Deployed
+ merged-PR terminal state. This could mean in-flight work was merged, or the
STATE.md was not updated.

Delete this folder?
- Yes — add '.aid/works/work-003-example' to the deletion set (git rm)
- No — skip this folder (leave it on disk)"
```

Populate `CONFIRMED_EXPLICIT[]` with any folders the user says "yes" to.

---

## Step 4 — Cancel-all / empty-selection no-op check

Combine the confirmed sets: `CONFIRMED_ALL = CONFIRMED_MAIN[] + CONFIRMED_EXPLICIT[]`.

If `CONFIRMED_ALL` is empty (user unchecked everything, cancelled, or no items
were confirmed in either pool):

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Cleanup Stage" --value "passed"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
```

Print:

```
✓ CLEANUP: no items confirmed for deletion — cleanup stage passed with no commit.
  Cleanup Stage: passed (cancel / nothing confirmed; no commit made).
```

**No commit is made.** This is a deliberate "I reviewed, deleted nothing" outcome
(NFR1/NFR2). It is `passed`, NOT `stalled` — cleanup always can conclude.

Advance: **CHAIN** → [State: DONE].

---

## Step 4b — Worktree teardown offer (per confirmed Tier-1 folder)

Reached only when `CONFIRMED_ALL` is non-empty (Step 4's cancel/empty-selection
check above did not chain to DONE). Extends the confirm-before-delete gate with
an opt-in worktree-teardown offer (FR7/AC7), defaulting to **Keep** — nothing is
torn down without an explicit toggle (NFR1/NFR3).

Teardown targets **only Tier-1** work folders. Gate on the classifier's own
`TIER` field (field 2 of the candidate record), NOT the basename alone: a
coincidentally `work-NNN`-named Tier-2 loose file (e.g.
`.aid/work-099-notes.md`, emitted by `scan_tier2`) must never trigger a
teardown offer against work-099's real worktree. `CONFIRMED_ALL` paths equal
the candidate `PATH` field, so look `TIER` up in `$CANDIDATES`:

```bash
CONFIRMED_WT=()   # entries: "<work-id>|<worktree-path>|<force?>"
for path in "${CONFIRMED_ALL[@]}"; do
    tier=""
    while IFS='|' read -r c_path c_tier _rest; do
        [[ "$c_path" == "$path" ]] && { tier="$c_tier"; break; }
    done <<< "$CANDIDATES"
    [[ "$tier" == "1" ]] || continue                  # not a Tier-1 work folder → no teardown
    folder="$(basename "${path%/}")"
    [[ "$folder" =~ ^(work-[0-9]+)- ]] || continue    # defensive: Tier-1 is always .aid/works/work-NNN-*/
    work_id="${BASH_REMATCH[1]}"                       # e.g. work-099

    # Presence pre-check (read-only): anything to tear down?
    has_branch=0; has_wt=0
    git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/heads/${work_id}" >/dev/null 2>&1 && has_branch=1
    git -C "$REPO_ROOT" worktree list --porcelain 2>/dev/null \
        | grep -q "^branch refs/heads/${work_id}$" && has_wt=1
    if [[ $has_branch -eq 0 && $has_wt -eq 0 ]]; then
        echo "  • ${work_id}: no worktree or ${work_id} branch present — nothing to tear down."
        continue
    fi

    # Resolve the path via the feature-001 helper (no fabrication: pre-check proved existence).
    LOC=$(bash .cursor/aid/scripts/works/worktree-lifecycle.sh locate "$work_id") \
        || { echo "  • ${work_id}: locate failed — skipping teardown (folder deletion still applies)."; continue; }
    IFS=$'\t' read -r WT_PATH WT_STATUS <<< "$LOC"   # TAB-separated: <path>\t<status> (feature-001 contract)

    # NFR3 safety probe (surfaced in the offer; gates --force).
    dirty=0; ahead=0
    [[ -n "$(git -C "$WT_PATH" status --porcelain 2>/dev/null)" ]] && dirty=1

    # `ahead` must be computed against an UP-TO-DATE remote-tracking ref, not
    # local `master` — a stale local `master` under-reports ahead=0 and would
    # silently skip the extra-confirm gate below Step 5b's `git branch -D`.
    # Mirror compute_signal_i's own approach (cleanup-classify.sh): a
    # best-effort fetch, then compare against `origin/master`. Degrade to the
    # safe side when offline/no-origin (fetch fails or origin/master does not
    # resolve) — treat the branch as potentially-ahead so the extra-confirm
    # gate always fires rather than being silently skipped.
    git -C "$REPO_ROOT" fetch origin >/dev/null 2>&1 || true
    if git -C "$REPO_ROOT" rev-parse --verify --quiet origin/master >/dev/null 2>&1; then
        [[ "$(git -C "$REPO_ROOT" rev-list --count "origin/master..${work_id}" 2>/dev/null || echo 0)" -gt 0 ]] && ahead=1
    else
        ahead=1   # safe side: origin/master unresolvable → assume potentially-ahead
    fi
    # → issue the AskUserQuestion below. On confirm, push "$work_id|$WT_PATH|<force|noforce>".
done
```

Note the pre-check is deliberately read-only and runs **before** `locate` is
ever called: `locate` resolves via the feature-001 4-rung ladder and *may
create* a worktree when none exists (rung 3 → status `created`). Teardown
must never fabricate a worktree just to delete it, so `locate` is only called
once the pre-check has proven a branch or worktree already exists — meaning
the status returned here is always `registered` or `recreated`, never
`created` (and never `current`: teardown targets only *other* works' folders,
never the worktree the agent is standing in — CLEANUP cannot even be reached
from inside a work's own worktree; see `state-preflight.md` Check 4). If
neither a branch nor a worktree exists, teardown is skipped for that folder
(nothing to remove) and `locate` is not called.

Issue a **separate** `AskUserQuestion` for each folder that reaches this point
(i.e., every Tier-1 folder with a branch or worktree present):

```
Use AskUserQuestion:
"'.aid/works/work-099-done' is confirmed for deletion. It also has an isolated worktree:

  Worktree : <WT_PATH>            (status: <WT_STATUS>)
  Branch   : work-099

  [ if dirty ]  ⚠ the worktree has UNCOMMITTED changes.
  [ if ahead ]  ⚠ branch work-099 has commits NOT on master (unmerged).

Also remove this worktree and prune branch work-099?
- Keep — leave the worktree and branch intact (default).
- Remove — git worktree remove + prune the work-099 branch.
  [ if dirty/ahead ]  Removing DISCARDS the uncommitted/unmerged work above."
```

Semantics:
- **Decline (Keep):** the folder is still deleted+committed by Steps 5–6, but
  the worktree and branch are left fully intact (AC7).
- **Confirm (Remove), clean case (`dirty=0 && ahead=0`):** record
  `"$work_id|$WT_PATH|noforce"` into `CONFIRMED_WT[]`.
- **Confirm (Remove), dirty/ahead case:** removal requires an **additional
  explicit confirmation** (shown inline in the prompt above) before it may be
  recorded as `force`; only then record `"$work_id|$WT_PATH|force"`. Without
  that second explicit confirm, treat the response as Decline (NFR3 edge
  case) — never silently escalate to `--force`.

No worktree or branch is ever removed without appearing in a confirmed
`AskUserQuestion` response first (NFR1, mirroring the folder-deletion
invariant in Step 5).

---

## Step 5 — Apply deletions (tracked/untracked split)

For each path in `CONFIRMED_ALL`, partition into `to_git_rm[]` and `to_rm[]`
using the `TRACKED` field from the candidate record returned by
`cleanup-classify.sh` (the script resolved tracked/untracked at scan time —
do NOT re-evaluate):

- `TRACKED == "tracked"` → append to `to_git_rm[]`
- `TRACKED == "untracked"` → append to `to_rm[]`

**Ensure the `aid/housekeep-*` branch BEFORE any deletion.** In the full sequence the
branch already exists (KB-DELTA created it); in `--cleanup-only` mode KB-DELTA is bypassed,
so CLEANUP must create it now — otherwise a cleanup-only run started on `master` would `rm`
untracked files and then be unable to commit (`branch-commit.sh` refuses `master`), stranding
the deletions. `--ensure-branch` is idempotent (reuses if already on an `aid/housekeep-*`
branch, creates from `master` otherwise), so it is safe in both modes and MUST run before the
destructive step below:

```bash
# Reuse the existing housekeep branch (full sequence) or create it (cleanup-only).
SLUG=$(bash .cursor/aid/scripts/housekeep/housekeep-state.sh --state "$STATE_FILE" --read --field "Branch" | sed 's#^aid/housekeep-##')
[ -z "$SLUG" ] && SLUG="$(date +%Y%m%d)"
bash .cursor/aid/scripts/housekeep/branch-commit.sh --ensure-branch --slug "$SLUG"
```

Only after the branch is ensured, apply deletions:

```bash
# Untracked paths — plain removal (not in git history)
for path in "${to_rm[@]}"; do
    rm -rf "$REPO_ROOT/$path"
done

# Tracked paths — stage for removal (recoverable from git history)
for path in "${to_git_rm[@]}"; do
    git rm -r --quiet -- "$REPO_ROOT/$path"
done
```

**No trash directory** (FR4: "No separate trash directory — it would itself
become crud"). Tracked paths removed via `git rm` are always recoverable from
git history (NFR1, AC8).

> **NFR1 invariant:** every path in `to_git_rm` and `to_rm` appeared checked
> in `CONFIRMED_ALL`. There is NO code path that deletes a path without it
> having been in the user's confirmed selection.

---

## Step 5b — Apply worktree teardown

Runs after Step 5's folder deletions, for every entry `CONFIRMED_WT[]`
collected in Step 4b. `git worktree remove` and `git branch -D` mutate git's
worktree registry and refs (under `.git/`), **not** tracked working-tree
content, so they are executed directly here and are **not** part of the
`branch-commit.sh` commit in Step 6 (that commit covers only the `git rm`
folder deletions staged in Step 5). Each command's exit status is checked —
a git-side refusal (e.g. `worktree remove` refusing a dirty tree, or
`branch -D` refusing a branch still checked out somewhere) must be surfaced,
never silently swallowed as an unconditional success:

```bash
WT_RESULTS=()   # entries: "<work-id>|<worktree-path>|<outcome>[|<detail>]"
                # outcome: removed (full success) | wt-only (branch -D failed) | failed
for entry in "${CONFIRMED_WT[@]}"; do
    IFS='|' read -r wid wpath force <<< "$entry"

    if [[ "$force" == "force" ]]; then
        rm_err=$(git -C "$REPO_ROOT" worktree remove --force "$wpath" 2>&1)   # dirty/ahead + explicit extra confirm
    else
        rm_err=$(git -C "$REPO_ROOT" worktree remove "$wpath" 2>&1)           # git itself refuses if dirty (NFR3 backstop)
    fi
    rm_status=$?
    if [[ $rm_status -ne 0 ]]; then
        WT_RESULTS+=("${wid}|${wpath}|failed|worktree remove: ${rm_err}")
        continue   # branch is still checked out in the worktree — branch -D would fail too
    fi

    br_err=$(git -C "$REPO_ROOT" branch -D "$wid" 2>&1)    # worktree removed first → branch is free to delete
    br_status=$?
    if [[ $br_status -ne 0 ]]; then
        WT_RESULTS+=("${wid}|${wpath}|wt-only|branch -D: ${br_err}")
        continue
    fi

    WT_RESULTS+=("${wid}|${wpath}|removed")
done

# Sweep stale admin entries. Best-effort/global (not per-entry): a failure here
# does not change any entry's WT_RESULTS outcome above, but is not swallowed —
# surface it as a warning so it is visible in the run's output.
if ! prune_err=$(git -C "$REPO_ROOT" worktree prune 2>&1); then
    echo "WARN: git worktree prune failed (non-fatal sweep): ${prune_err}"
fi
```

Ordering is load-bearing: `git worktree remove` must precede `git branch -D`
(git refuses to delete a branch still checked out in a worktree). `git
worktree prune` runs last, as a sweep. A folder whose teardown offer was
declined in Step 4b never populates `CONFIRMED_WT[]`, so its worktree and
branch reach this step untouched — only explicitly confirmed removals loop
here (NFR1/NFR3). The completion summary in Step 6 reports each `WT_RESULTS[]`
entry's ACTUAL outcome (`removed` / `wt-only` / `failed` — see the array's
comment above) alongside the deleted folders — never an unconditional success
line.

---

## Step 6 — Single commit, write gate field, chain to DONE

Make exactly **one** commit via `branch-commit.sh` for the staged deletions.
Never push. Never commit to `master`.

```bash
bash .cursor/aid/scripts/housekeep/branch-commit.sh \
    --commit \
    --message "chore(housekeep): cleanup stale .aid artifacts [feature-004]" \
    --add-all
```

`--add-all` stages any remaining tracked changes (the `git rm` calls already
staged the tracked deletions; `--add-all` is a catch-all for completeness).
`branch-commit.sh` enforces that the commit lands on the `aid/housekeep-*`
branch and contains no `git push` (safety self-check in the script).

Then write the gate field:

```bash
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Cleanup Stage" --value "passed"
bash .cursor/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
```

Print the completion summary. When `WT_RESULTS[]` (Step 4b/5b) is non-empty,
list each entry's ACTUAL outcome alongside the deleted folders — a git-side
refusal must be reported as a failure, never folded into an unconditional
success line:

```
✓ CLEANUP: <N> item(s) deleted — committed.
  Deleted:
    <list each deleted path with mechanism: (git rm) or (rm)>
  Worktrees removed:
    <list each entry from WT_RESULTS[], one line per entry, per its outcome field:
       outcome=removed  → work-NNN — <worktree-path> (removed; branch pruned)
       outcome=wt-only  → work-NNN — <worktree-path> (worktree removed; branch -D FAILED: <detail>)
       outcome=failed   → work-NNN — <worktree-path> (FAILED: <detail>)>
  Cleanup Stage: passed.
```

Omit the `Worktrees removed:` block entirely when `WT_RESULTS[]` is empty (no
teardown was offered or confirmed for this run). `Cleanup Stage: passed` still
reflects the folder deletions/commit in Steps 5–6 (unaffected by a worktree
teardown failure) — a `failed`/`wt-only` entry is a reported worktree-teardown
outcome, not a Cleanup-stage failure; the user re-runs `/aid-housekeep` (or
handles the leftover worktree/branch manually) to retry teardown separately.

**D2 coordination note:** This stage sweeps any residual
`verify-deterministic-report.json` / `verify-advisory-report.json` under
`.aid/` as S4 Tier-0 candidates (complementary to the `report_path=None`
source fix already applied to `run_generator.py`). This body does NOT touch
`run_generator.py` and does not re-litigate that fix.

---

**Advance:** **CHAIN** → [State: DONE] (continue inline).

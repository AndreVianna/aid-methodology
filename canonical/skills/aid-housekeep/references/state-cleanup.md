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
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "CLEANUP"
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "running"
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
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
the one work folder whose `aid/work-NNN-*` branch is currently checked out, and it
**offers every other work folder** for the user to confirm or decline (the user has
the last word — no folder is silently hidden):

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"

CANDIDATES=$(bash canonical/aid/scripts/housekeep/cleanup-classify.sh \
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
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Cleanup Stage" --value "passed"
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
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
> - **Tier-1 (work folders):** `.aid/work-*/` folders that passed signal (i)
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
  [x] .aid/work-002-canonical-generator/verify-deterministic-report.json  (untracked)  — S4: stray tool report (verify JSON)

Tier-1 — work folders offered for deletion (unchecked):
  [ ] .aid/work-002-canonical-generator  (git rm)  — review: S6: work folder merged+concluded

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
"Work folder '.aid/work-003-example' shows a discrepancy:

  Signal (i) — merged to master: PASS (PR is MERGED)
  Signal (ii) — STATE.md concluded: FAIL — <why: e.g. STATUS is 'Executing', no merged Deploy row>

This folder's PR appears merged, but its STATE.md does not show a Deployed
+ merged-PR terminal state. This could mean in-flight work was merged, or the
STATE.md was not updated.

Delete this folder?
- Yes — add '.aid/work-003-example' to the deletion set (git rm)
- No — skip this folder (leave it on disk)"
```

Populate `CONFIRMED_EXPLICIT[]` with any folders the user says "yes" to.

---

## Step 4 — Cancel-all / empty-selection no-op check

Combine the confirmed sets: `CONFIRMED_ALL = CONFIRMED_MAIN[] + CONFIRMED_EXPLICIT[]`.

If `CONFIRMED_ALL` is empty (user unchecked everything, cancelled, or no items
were confirmed in either pool):

```bash
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Cleanup Stage" --value "passed"
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
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
SLUG=$(bash canonical/aid/scripts/housekeep/housekeep-state.sh --state "$STATE_FILE" --read --field "Branch" | sed 's#^aid/housekeep-##')
[ -z "$SLUG" ] && SLUG="$(date +%Y%m%d)"
bash canonical/aid/scripts/housekeep/branch-commit.sh --ensure-branch --slug "$SLUG"
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

## Step 6 — Single commit, write gate field, chain to DONE

Make exactly **one** commit via `branch-commit.sh` for the staged deletions.
Never push. Never commit to `master`.

```bash
bash canonical/aid/scripts/housekeep/branch-commit.sh \
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
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Cleanup Stage" --value "passed"
bash canonical/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
```

Print the completion summary:

```
✓ CLEANUP: <N> item(s) deleted — committed.
  Deleted:
    <list each deleted path with mechanism: (git rm) or (rm)>
  Cleanup Stage: passed.
```

**D2 coordination note:** This stage sweeps any residual
`verify-deterministic-report.json` / `verify-advisory-report.json` under
`.aid/` as S4 Tier-0 candidates (complementary to the `report_path=None`
source fix already applied to `run_generator.py`). This body does NOT touch
`run_generator.py` and does not re-litigate that fix.

---

**Advance:** **CHAIN** → [State: DONE] (continue inline).

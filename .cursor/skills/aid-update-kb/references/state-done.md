# State: DONE

DONE commits the approved KB changes and closes the run. It is selected when
the run-state file records `**State:** DONE` and `**User Approved:** yes`.

**Approval invariant.** DONE is only reachable after an explicit human `[1]`
at APPROVAL. If this state is entered without `**User Approved:** yes` in the
run-state file, print an error and HALT without committing.

Print the `[State: DONE]` banner from `SKILL.md § State Detection`.

---

## Step 1: Re-verify closure (FR-34, before commit)

Before restamping or committing, re-run the deterministic closure check over
the changed KB docs to confirm the update left no native term undefined -- a
standing invariant shared with `aid-discover` and `aid-housekeep`.

The who-runs-closure-when boundary between `aid-update-kb` and `aid-housekeep`
is f010; DONE runs its own re-verification unconditionally.

```bash
bash .cursor/aid/scripts/kb/closure-check.sh \
  --output-a .aid/.temp/closure-verify-a.md \
  --output-b .aid/.temp/closure-verify-b.md
```

Read `closure-verify-a.md` (the ungrounded/undefined-terms oracle). If it
contains any undefined native terms introduced by the APPLY edits, determine
whether the fix stays within `**Confirmed Scope:**` or needs an addition
outside it (HL-7 -- a closure shortfall may not silently expand scope any
more than a REVIEW fix may):

### 1a. Fixable within Confirmed Scope

The gap can be closed by editing/cross-referencing a doc already in
`**Confirmed Scope:**` (e.g. a cross-reference the confirmed edit itself
should have included). Route back to APPLY -- still bounded to Confirmed
Scope, nothing new to confirm:

1. Do NOT commit.
2. Print:

   ```
   [DONE] Closure re-verification failed -- {N} undefined term(s) found.
   Run /aid-update-kb again; APPLY must define or cross-reference: <terms>.
   ```

3. Update the run-state file:

   ```
   **State:** APPLY
   **Closure Failure:** <terms> undefined after APPLY (fixable within Confirmed Scope)
   ```

4. HALT (the user re-enters via `/aid-update-kb`; APPLY will address the gap,
   still bounded to `Confirmed Scope` per `state-apply.md § Step 1`).

### 1b. Needs an out-of-scope addition (HL-7)

The gap can only be closed by a doc, or a Scope Plan item, that was never
confirmed (e.g. a brand-new `domain-glossary.md` entry no Scope Plan row
named). Do **NOT** auto-push this to APPLY -- that would let APPLY improvise
an edit outside the confirmed contract. Escalate to the user instead:

1. Append a Q&A entry to `.aid/knowledge/STATE.md ## Q&A (Pending)`:

   ```
   ### Q{N}
   - **Category:** Update-KB / Closure Shortfall
   - **Impact:** Required
   - **Status:** Pending
   - **Context:** /aid-update-kb DONE's closure re-check found undefined
     term(s) <terms> that require an edit outside Confirmed Scope to fix
     (e.g. a new domain-glossary.md entry that was never a confirmed Scope
     Plan item).
   - **Suggested:** Confirm whether <terms>/<doc> should be added to scope.
     If yes, re-run /aid-update-kb to re-enter CONFIRM/SCOPE with the
     expanded need.
   ```

2. Update the run-state file:

   ```
   **State:** CONFIRM
   **Closure Failure:** <terms> require out-of-scope addition -- escalated Q{N}
   ```

3. Print:

   ```
   [DONE] Closure re-verification found undefined term(s) needing an
   out-of-scope addition -- escalated as Q{N} in .aid/knowledge/STATE.md.
   Closure-chasing may not expand scope (HL-7). Run /aid-update-kb again to
   resolve at CONFIRM.
   ```

4. Do NOT commit. **Advance:** PAUSE-FOR-USER-ACTION -- return to CONFIRM on
   the next invocation (do not HALT-and-auto-resume at APPLY as in 1a).

If closure passes (no new undefined terms), proceed.

Clean up the closure verify transients:

```bash
rm -f .aid/.temp/closure-verify-a.md \
      .aid/.temp/closure-verify-b.md
```

---

## Step 2: Confirm the working branch (no new branch created)

The Pre-flight ISOLATE step already created and entered this run's
`aid/update-kb-<ts>` branch, before any state ran -- recorded as
`**Branch:**` in the run-state file. **DONE creates no separate branch of
its own** (there is no "ensure branch" / `git checkout -b` step here); it
only ever commits on the one branch the whole run has been living on since
Pre-flight.

Belt-and-suspenders sanity check (should be unreachable -- the worktree
never leaves this branch):

```bash
BRANCH=$(grep -m1 "^\*\*Branch:\*\*" "$STATE_FILE" | sed 's/^\*\*Branch:\*\* *//')
CUR="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [ -n "$BRANCH" ] && [ "$CUR" != "$BRANCH" ]; then
  echo "[DONE] Current branch ($CUR) does not match this run's recorded"
  echo "branch ($BRANCH) -- refusing to commit on the wrong branch. STOP."
  exit 1
fi
```

---

## Step 3: Restamp approved_at_commit: in each approved doc

For each doc listed in `**Edited Docs:**` in the run-state file, restamp the
`approved_at_commit:` frontmatter field to the commit SHA that will record the
approved edit. Because the commit has not happened yet, use the PENDING marker
and update it immediately after the commit in Step 4b.

Before committing, update each doc's frontmatter:

```yaml
approved_at_commit: PENDING
```

The f001 schema specifies that `approved_at_commit:` is written by
`aid-discover`/`aid-update-kb` on approval, never hand-authored and never set
in APPLY or REVIEW. Restamping here (post-gate) is the correct and only
permitted moment.

---

## Step 4: Commit

### Step 4a: Stage and commit

Stage the approved docs and commit on the `aid/update-kb-<ts>` branch
recorded in `**Branch:**` (the branch Pre-flight already created and entered
-- this step never creates or switches branches):

```bash
git add .aid/knowledge/<doc1>.md .aid/knowledge/<doc2>.md ...
git commit -m "kb(update): <one-line summary from **Prompt:**>

Changes applied by /aid-update-kb:
<list of doc | change-type pairs from **Scope Plan:**>

Grade: <grade> | Teach-back: PASS | Act-back: PASS
Approved by user at <ISO-8601 from **Approved At:**>"
```

**The skill NEVER pushes -- to this branch or to `master`.** This includes
`master` specifically: the skill never merges or pushes to `master` under
any circumstance. The human pushes `<Branch>` / opens the PR, and merges
into `master` only after CI is green.

### Step 4b: Restamp approved_at_commit: to the real commit SHA

After the commit, resolve the commit SHA and replace the PENDING marker in
each approved doc:

```bash
COMMIT_SHA=$(git rev-parse HEAD)
```

For each approved doc, replace `approved_at_commit: PENDING` with
`approved_at_commit: <COMMIT_SHA>`. Then amend the commit to include the
restamped frontmatter:

```bash
git add .aid/knowledge/<doc1>.md .aid/knowledge/<doc2>.md ...
git commit --amend --no-edit
```

---

## Step 5: Clean up the ledger and run-state

Remove the review ledger and any remaining transients:

```bash
rm -f .aid/.temp/review-pending/update-kb.md
rmdir --ignore-fail-on-non-empty .aid/.temp/review-pending/ 2>/dev/null || true
```

Remove the run-state file (`<STATE_FILE>`):

```bash
rm -f "$STATE_FILE"
# Also remove any other stale UPDATEKB_STATE_*.md siblings
find .aid/.temp -maxdepth 1 -name 'UPDATEKB_STATE_*.md' -delete 2>/dev/null || true
```

---

## Step 6: Print closing summary

```
[State: DONE] complete.

KB update committed on branch: <Branch>
Commit: <COMMIT_SHA>
Docs updated ({N}):
  <list of doc | change-type>
Grade: <grade> | Teach-back: PASS | Act-back: PASS
Closure re-verification: PASS

To publish the update:
  git push origin <Branch>
  # then open a PR to merge into master (the skill never pushes master itself
  # -- the human merges only after CI is green)
```

**Advance:** HALT.

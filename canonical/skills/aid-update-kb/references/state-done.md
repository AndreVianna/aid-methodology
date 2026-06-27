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
bash canonical/scripts/kb/closure-check.sh \
  --output-a .aid/.temp/closure-verify-a.md \
  --output-b .aid/.temp/closure-verify-b.md
```

Read `closure-verify-a.md` (the ungrounded/undefined-terms oracle). If it contains any
undefined native terms that were introduced by the APPLY edits:

1. Do NOT commit.
2. Print:

   ```
   [DONE] Closure re-verification failed -- {N} undefined term(s) found.
   Run /aid-update-kb again; APPLY must define or cross-reference: <terms>.
   ```

3. Update the run-state file:

   ```
   **State:** APPLY
   **Closure Failure:** <terms> undefined after APPLY
   ```

4. HALT (the user re-enters via `/aid-update-kb`; APPLY will address the gap).

If closure passes (no new undefined terms), proceed.

Clean up the closure verify transients:

```bash
rm -f .aid/.temp/closure-verify-a.md \
      .aid/.temp/closure-verify-b.md
```

---

## Step 2: Ensure branch

Ensure the `aid/update-kb-*` branch exists (create if absent; use the existing
one if this is a resumed run):

```bash
BRANCH="aid/update-kb-$(date +%Y-%m-%d)"
git rev-parse --verify "$BRANCH" >/dev/null 2>&1 || \
  git checkout -b "$BRANCH"
git checkout "$BRANCH"
```

Record the branch in the run-state file:

```
**Branch:** aid/update-kb-<date>
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

Stage the approved docs and commit on the `aid/update-kb-*` branch:

```bash
git add .aid/knowledge/<doc1>.md .aid/knowledge/<doc2>.md ...
git commit -m "kb(update): <one-line summary from **Prompt:**>

Changes applied by /aid-update-kb:
<list of doc | change-type pairs from **Change Plan:**>

Grade: <grade> | Teach-back: PASS | Act-back: PASS
Approved by user at <ISO-8601 from **Approved At:**>"
```

The skill NEVER pushes. The human pushes / opens the PR.

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

KB update committed on branch: aid/update-kb-<date>
Commit: <COMMIT_SHA>
Docs updated ({N}):
  <list of doc | change-type>
Grade: <grade> | Teach-back: PASS | Act-back: PASS
Closure re-verification: PASS

To publish the update:
  git push origin aid/update-kb-<date>
  # then open a PR to merge into the main branch
```

**Advance:** HALT.

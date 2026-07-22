# State: APPLY

APPLY makes targeted summary+pointer edits to the KB docs identified in
`**Confirmed Scope:**` -- and only those docs. It is selected when the
run-state file records `**State:** APPLY`.

**Authoring discipline (calibration gate).** Every edit is a synthesized
summary+pointer at KB altitude -- the *why/how-it-relates* the doc needs to be
useful, plus a durable pointer to the source via the `sources:` field. APPLY
does NOT transcribe source content verbatim. The REVIEW state enforces this
discipline through f005's M2 Anatomy mandate altitude checks (CAL-1 transcription /
CAL-2 hollowness); APPLY authors to pass it.

**Native language / concept spine invariant (FR-34).** Every edit preserves the
doc's native concept spine. Reuse the project's coined terms from
`domain-glossary.md`; do NOT introduce generic synonyms for project-specific
concepts. If a new concept must be added to `domain-glossary.md`, add it there
first, then reference it in the other docs.

**approved_at_commit: invariant.** Do NOT restamp the `approved_at_commit:`
frontmatter field in APPLY. That field is the approval baseline: it is written
by DONE (after the human gate at APPROVAL), never by APPLY or REVIEW. A doc
that has been edited but not yet approved is correctly `suspect` to
`kb-freshness-check.sh` (f007) -- restamping here would falsely mark it
`current`.

**Scope boundary (HL-2/HL-5).** APPLY edits ONLY the docs listed in
`**Confirmed Scope:**` -- the frozen contract CONFIRM's `[1] Confirm` wrote.
It never opportunistically touches a domain-adjacent or `suspect` doc that
is not itself in `Confirmed Scope`, and it never grows the edit past what a
Scope Plan item's `Description` actually describes. REVIEW's scope-diff
guard (`state-review.md § Step 0`) hard-fails on any divergence between the
disk-derived edited set and `Confirmed Scope` -- APPLY exists to make that
guard pass, not to be graded around.

Print the `[State: APPLY]` banner from `SKILL.md § State Detection`.

---

## Step 0: Re-scope revert guard (re-entry only, HL-7/AC-5)

Before doing anything else, detect whether this is a **re-entry into APPLY
after a re-scope** -- APPROVAL `[2]` or a REVIEW HL-7 escalation looped back
through SCOPE/CONFIRM and has now arrived back at APPLY with a *revised*
`**Confirmed Scope:**`, while a *prior* `**Edited Docs:**` from an earlier
APPLY pass in this same run is still on disk.

- If `<STATE_FILE>` has no `**Edited Docs:**` yet, this is a fresh first
  pass -- nothing to revert. Continue to Step 1.
- If `**Edited Docs:**` is present, compare its doc list against the
  *current* `**Confirmed Scope:**`. For every doc in the prior
  `**Edited Docs:**` that is **NOT** in the current `**Confirmed Scope:**`
  (a doc the re-scope dropped):

  ```bash
  git restore -- "<doc>"
  ```

  against the `**Pre-APPLY baseline:**` recorded in run-state (during this
  run `HEAD` has not moved -- commits only happen at DONE -- so plain
  `git restore` against the working tree/index already restores to that
  baseline). Print:

  ```
  [APPLY] Re-scope revert: <doc> reverted to Pre-APPLY baseline (dropped
  from Confirmed Scope by the re-scope).
  ```

  The working tree must never carry an edit broader than the *currently*
  confirmed scope -- this is the exact failure mode the re-scope revert
  closes (HL-7/AC-5).
- Docs still present in the current `Confirmed Scope` keep their existing
  edit; Step 2 re-processes them normally (a `Description` change from the
  re-scope is applied as a further targeted edit, not a re-write).

This step is idempotent on a normal first pass (nothing to compare, nothing
reverted) and is the mechanism `state-approval.md § Step 3 [2]` and
`state-review.md`'s HL-7 escalation both point to.

---

## Step 1: Read the Scope Plan, bounded to Confirmed Scope

Read `**Scope Plan:**` from `<STATE_FILE>` -- the (doc, change-type,
description, Traces-to, Kind) tuples SCOPE produced. Read
`**Confirmed Scope:**` -- the frozen doc set CONFIRM approved (HL-1); this is
the boundary.

Process only the Scope Plan rows whose doc appears in `**Confirmed Scope:**`,
in order. A Scope Plan row whose doc is NOT in `Confirmed Scope` (e.g. a stale
row from a SCOPE pass before a CONFIRM `[2] Adjust` loop-back rewrote the
plan) is skipped -- it was never confirmed, so APPLY never touches it.

---

## Step 2: For each (doc, change) -- make the targeted edit

For each bounded entry from Step 1:

### 2a. Read the doc

Read the full contents of the KB doc. Identify the section and location where
the change belongs (by scanning headings and existing entries).

### 2b. Apply the targeted edit

Apply the change using the `Edit` tool -- **a targeted in-place edit, NOT a
full rewrite** (repeated here and in the sub-agent dispatch prompt at 2c,
because both paths must honor it). The edit type determines the action:

**New summary+pointer entry:**
Insert a new entry (summary sentence + reference pointer) in the appropriate
section. The entry should:
- Begin with the what/why in one sentence (the synthesis, not a quote from
  the source).
- Include a pointer to the source via a parenthetical, e.g.
  `(see \`sources:\` -- <slug>)` or a doc-relative cross-reference.
- Match the surrounding entry format (heading level, bullet vs prose) for
  visual consistency.

**Corrected fact:**
Use `Edit` to replace the incorrect statement with the corrected one.
Preserve the surrounding prose structure; do not reflow sections.

**New `sources:` entry:**
Append the new source to the `sources:` frontmatter list using a repo-relative
path, glob, or URL matching the f001 schema already in use by the doc:

```yaml
sources:
  - <existing entries>
  - <repo-relative-path-or-URL>
```

**New concept on the spine (`domain-glossary.md`):**
Insert a new concept entry in `domain-glossary.md` following the existing
schema (term, definition, concept-spine entry if load-bearing). A
cross-reference to this new concept in another doc is made ONLY if that
other doc's cross-reference is itself a separate confirmed Scope Plan item
(`kind: closure` or `in-scope`) -- APPLY never opens an unbounded "add
cross-references as needed" cascade to docs that were not themselves
confirmed (HL-2/HL-5). If a cross-reference looks necessary but was not
confirmed, it is out of scope for this pass; note it for a future
`/aid-update-kb` instruction or `aid-housekeep` pass instead of adding it now.

### 2c. Dispatch sub-agents for owning doc-sets (optional)

For docs whose content requires domain depth beyond the Scope Plan's
description (e.g. a deep architecture doc), dispatch an `aid-architect` or
`aid-researcher` sub-agent to author the edit **at Medium tier with low/medium
effort** -- authoring/editing a KB doc is Retrieval-heavy work
(`canonical/aid/templates/agent-dispatch-tiering.md`), and Medium keeps the author
at or below this skill's REVIEW panel reviewer (reviewer tier >= executor tier). Only
a genuinely hard/deep doc justifies escalating the author to Large -- and then the
REVIEW panel reviewer must escalate to Large to match. The sub-agent receives:
- The doc path.
- The change-type and description from the Scope Plan (the single row it is
  authoring).
- **The "targeted edit, NOT a rewrite" guard, repeated verbatim** -- the
  sub-agent makes a targeted in-place edit to the existing doc; it does not
  regenerate, restructure, or rewrite the doc wholesale, even if it judges
  the doc could be improved elsewhere. Anything outside the confirmed
  Description is out of scope for this dispatch, full stop (HL-2/HL-5) --
  the sub-agent does not add cross-references, restructure sections, or fix
  unrelated issues it happens to notice while reading the doc.
- The native language and concept-spine constraint (preserve coined terms from
  `domain-glossary.md`).
- The calibration discipline: synthesize, do NOT transcribe.
- The `approved_at_commit:` invariant: do NOT restamp this field.

Use the Dispatch Protocol from `SKILL.md § Dispatch Protocol` for each
dispatched sub-agent.

For straightforward edits (fact corrections, adding a `sources:` entry, a
single new pointer entry), apply them inline without a sub-agent.

---

## Step 3: Verify the edits

After all edits are applied, confirm:

- [ ] Each targeted doc has been edited with the change described in its
      Scope Plan row -- and no doc outside `**Confirmed Scope:**` was
      touched.
- [ ] No `approved_at_commit:` field has been modified.
- [ ] No coined term from `domain-glossary.md` has been replaced with a generic
      synonym.
- [ ] All new `sources:` entries use the f001 schema (repo-relative paths,
      globs, or URLs matching the existing `sources:` format in that doc).
- [ ] No source content was transcribed verbatim (the edit is a synthesis +
      pointer, not a copy-paste).
- [ ] No open-ended cross-reference was added beyond what a confirmed Scope
      Plan item itself describes.

---

## Step 4: Record edits in run-state

Update `<STATE_FILE>`:

```
**State:** REVIEW
**Edited Docs:**
- .aid/knowledge/<doc1>.md (change-type: <type>)
- .aid/knowledge/<doc2>.md (change-type: <type>)
**APPLY Completed:** <ISO-8601 timestamp>
```

Print: `[APPLY] {N} doc(s) edited. Advancing to REVIEW.`

**Advance:** CHAIN -> REVIEW (continue inline).

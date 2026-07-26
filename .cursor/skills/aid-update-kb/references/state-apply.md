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

## Step 0: Re-scope revert guard (disk-derived, re-entry only, HL-7/AC-5)

Before doing anything else, detect and revert any doc that is **currently
changed on disk** in `.aid/knowledge/` but is **NOT** in the *current*
`**Confirmed Scope:**` -- regardless of whether that doc was ever
self-reported in a prior `**Edited Docs:**` list. This guard is
**disk-derived**, the same method REVIEW's Step 0a scope-diff guard uses --
it never trusts `**Edited Docs:**` as its input, because it must cover BOTH
re-scope scenarios this redesign has, and only one of them is ever
self-reported:

- **APPROVAL `[2]` shrinking a scope that legitimately included the dropped
  doc** -- that doc WAS processed by a prior APPLY pass, so it IS listed in
  `**Edited Docs:**`.
- **A stray out-of-scope edit REVIEW's Step 0 scope-diff guard caught (Step
  4(b), "decline" answer)** -- that doc was, by construction, never
  processed by APPLY's Confirmed-Scope-bounded Step 1/2 loop, so it was
  **never** added to `**Edited Docs:**` in the first place. A revert keyed
  on `**Edited Docs:**` can never strip this case -- disk truth is the only
  source that sees it.

### 0a. Derive the currently-changed doc set from disk

Same method as `state-review.md § Step 0a`:

```bash
BASELINE=$(grep -m1 "^\*\*Pre-APPLY baseline:\*\*" "$STATE_FILE" | sed 's/^\*\*Pre-APPLY baseline:\*\* *//')
if [ -z "$BASELINE" ] || [ "$BASELINE" = "clean" ]; then
  DISK_CHANGED=$(git status --porcelain -- .aid/knowledge/ | awk '{print $2}')
else
  DISK_CHANGED=$(git diff --name-only "$BASELINE" -- .aid/knowledge/)
fi
```

If `DISK_CHANGED` is empty, there is nothing on disk to revert (a fresh
first pass, or a prior revert already cleaned it up) -- continue to Step 1.

### 0b. Revert every disk-changed doc that is not in the current Confirmed Scope

For each doc in `DISK_CHANGED` that is **NOT** listed in the current
`**Confirmed Scope:**`:

```bash
git restore -- "<doc>"
```

against the `**Pre-APPLY baseline:**` recorded in run-state (during this
run `HEAD` has not moved -- commits only happen at DONE -- so plain
`git restore` against the working tree/index already restores to that
baseline). Print:

```
[APPLY] Re-scope revert: <doc> reverted to Pre-APPLY baseline (disk-changed
but not in current Confirmed Scope; disk-derived -- reverted whether or not
it was ever in a prior Edited Docs self-report).
```

The working tree must never carry an edit broader than the *currently*
confirmed scope -- this is the exact failure mode the re-scope revert closes
(HL-7/AC-5), for BOTH the self-reported (APPROVAL `[2]`) and the
never-self-reported (REVIEW 4(b) decline) case.

Docs in `DISK_CHANGED` that ARE still in the current `Confirmed Scope` keep
their existing edit; Step 2 re-processes them normally (a `Description`
change from the re-scope is applied as a further targeted edit, not a
re-write -- and, per Step 2's idempotency guard below, a no-op if that edit
is already correctly present).

This step is idempotent on a normal first pass (`DISK_CHANGED` reflects
nothing to revert until a re-scope actually shrinks `Confirmed Scope`) and
is the mechanism `state-approval.md § Step 3 [2]` and `state-review.md § 4(b)`'s
"decline" resolution both point to.

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

**Re-entry (HL-7, idempotency).** On a normal first pass every bounded row
needs its edit applied. On a **re-entry** into APPLY -- e.g. REVIEW's 4(a)
incomplete-APPLY loop-back, which chains straight back here after only SOME
Confirmed-Scope docs were edited -- this same Step 1 reprocesses ALL bounded
rows again, including ones a prior pass already finished correctly. Step 2's
actions below are each **check-before-write**: a row already correctly
applied in a prior pass is a no-op this pass, never a duplicate/corrupted
re-edit.

---

## Step 2: For each (doc, change) -- make the targeted edit

For each bounded entry from Step 1:

### 2a. Read the doc (or create it, if `Kind: new-file`)

If the row's `Kind` is `new-file`, the doc does not exist on disk yet --
skip straight to **2b's "New file" branch** below (there is nothing to
read). Otherwise, read the full contents of the KB doc. Identify the section
and location where the change belongs (by scanning headings and existing
entries).

### 2b. Apply the targeted edit

Apply the change using the `Edit` tool -- **a targeted in-place edit, NOT a
full rewrite** (repeated here and in the sub-agent dispatch prompt at 2c,
because both paths must honor it). Every action below is **check-before-write
(HL-7 idempotency, re-entry safe)**: verify the intended content is not
already present before inserting/editing; if it already is (a prior APPLY
pass in this same run already applied it correctly), treat the row as a
no-op and move to the next one. The edit type determines the action:

**New file (`Kind: new-file`, HL-6/AC-6):**
The Scope Plan row names a doc that does not exist yet -- allowed only
because it was confirmed as a `new-file` Kind at CONFIRM (HL-6), never a
silent side effect. Before any of the four Change-type actions below can
apply, create the file itself with the `Write` tool (not `Edit` -- there is
nothing to edit yet), following the KB's f001 authoring schema (the same
dual-audience standard `aid-discover`'s M2 Authoring Standard Checks
enforce, `.cursor/skills/aid-discover/references/state-review.md § M2
Authoring Standard Checks`):
- Frontmatter as the first block, before any content, with the core fields
  (`objective:`, `summary:`, `sources:`) and classification fields
  (`audience:`, `owner:`, `tags:` -- including a concern ID `C0`-`C9`/`D`
  mapping the new doc to a spine dimension). Do **NOT** set
  `approved_at_commit:` here -- the invariant above applies to new files
  too; DONE writes it, only after the human gate, same as every other doc.
- A `## Contents` (or equivalent index/TOC) section near the top if the new
  doc will have more than 3 sections.
- Body section(s) synthesizing the row's `Description` -- summary+pointer
  content per the same calibration discipline as every other Change-type
  (synthesize, do not transcribe).
- `## Change Log` as the **last** section, with an opening entry recording
  this run's creation (date, one-line reason, and a pointer to this
  `/aid-update-kb` run as the source).

  **Idempotency (re-entry, HL-7):** if the file already exists on disk (a
  prior APPLY pass in this same run already created it before a REVIEW
  loop-back), do NOT re-create it -- check its `## Change Log` for this
  run's creation entry; if present, the file itself is already done, and
  only its Change-type content (below) still needs the usual
  check-before-write treatment.

  Once the file exists (freshly created, or already present from a prior
  pass), apply the row's own Change-type action below into it, exactly as
  for any other doc.

**New summary+pointer entry:**
Check first whether an entry matching this row's `Description` (same
summary substance + source pointer) is already present in the target
section -- if so, this row is a no-op. Otherwise insert a new entry (summary
sentence + reference pointer) in the appropriate section. The entry should:
- Begin with the what/why in one sentence (the synthesis, not a quote from
  the source).
- Include a pointer to the source via a parenthetical, e.g.
  `(see \`sources:\` -- <slug>)` or a doc-relative cross-reference.
- Match the surrounding entry format (heading level, bullet vs prose) for
  visual consistency.

**Corrected fact:**
Check first whether the doc already reads the corrected form described by
this row -- if so (the incorrect statement is no longer present), this row
is a no-op. Otherwise use `Edit` to replace the incorrect statement with the
corrected one. Preserve the surrounding prose structure; do not reflow
sections.

**New `sources:` entry:**
Check first whether the entry is already present in the `sources:` list --
if so, this row is a no-op. Otherwise append the new source using a
repo-relative path, glob, or URL matching the f001 schema already in use by
the doc:

```yaml
sources:
  - <existing entries>
  - <repo-relative-path-or-URL>
```

**New concept on the spine (`domain-glossary.md`):**
Check first whether `domain-glossary.md` already has an entry for this term
matching the confirmed definition -- if so, this row is a no-op. Otherwise
insert a new concept entry following the existing schema (term, definition,
concept-spine entry if load-bearing). A cross-reference to this new concept
in another doc is made ONLY if that other doc's cross-reference is itself a
separate confirmed Scope Plan item (`kind: closure` or `in-scope`) -- APPLY
never opens an unbounded "add cross-references as needed" cascade to docs
that were not themselves confirmed (HL-2/HL-5). If a cross-reference looks
necessary but was not confirmed, it is out of scope for this pass; note it
for a future `/aid-update-kb` instruction or `aid-housekeep` pass instead of
adding it now.

### 2c. Dispatch sub-agents for owning doc-sets (optional)

For docs whose content requires domain depth beyond the Scope Plan's
description (e.g. a deep architecture doc), dispatch an `aid-architect` or
`aid-researcher` sub-agent to author the edit **at Medium tier with low/medium
effort** -- authoring/editing a KB doc is Retrieval-heavy work
(`.cursor/aid/templates/agent-dispatch-tiering.md`), and Medium keeps the author
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
- [ ] Each `Kind: new-file` row's doc was created via `Write` (never `Edit`),
      following the f001 schema -- frontmatter first, `## Contents` if more
      than 3 sections, `## Change Log` last -- and carries no
      `approved_at_commit:` value yet.
- [ ] No row already correctly applied in a prior pass (re-entry) was
      re-edited or duplicated -- Step 2's check-before-write guard held.

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

# State: APPLY

APPLY makes targeted summary+pointer edits to the KB docs identified in ANALYZE.
It is selected when the run-state file records `**State:** APPLY`.

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

Print the `[State: APPLY]` banner from `SKILL.md § State Detection`.

---

## Step 1: Read the change plan

Read `**Change Plan:**` from `<STATE_FILE>`. The list is the (doc, change-type,
description) tuples emitted by ANALYZE. Process them in order.

---

## Step 2: For each (doc, change) -- make the targeted edit

For each entry in the change plan:

### 2a. Read the doc

Read the full contents of the KB doc. Identify the section and location where
the change belongs (by scanning headings and existing entries).

### 2b. Apply the targeted edit

Apply the change using the `Edit` tool (targeted in-place edit; NOT a full
rewrite). The edit type determines the action:

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
schema (term, definition, concept-spine entry if load-bearing). After adding
to the glossary, return to the other affected docs and add cross-references
as needed.

### 2c. Dispatch sub-agents for owning doc-sets (optional)

For docs whose content requires domain depth beyond the change plan's
description (e.g. a deep architecture doc), dispatch an `aid-architect` or
`aid-researcher` sub-agent to author the edit **at Medium tier with low/medium
effort** -- authoring/editing a KB doc is Retrieval-heavy work
(`.github/aid/templates/agent-dispatch-tiering.md`), and Medium keeps the author
at or below this skill's REVIEW panel reviewer (reviewer tier >= executor tier). Only
a genuinely hard/deep doc justifies escalating the author to Large -- and then the
REVIEW panel reviewer must escalate to Large to match. The sub-agent receives:
- The doc path.
- The change-type and description from the change plan.
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

- [ ] Each targeted doc has been edited with the change described in the plan.
- [ ] No `approved_at_commit:` field has been modified.
- [ ] No coined term from `domain-glossary.md` has been replaced with a generic
      synonym.
- [ ] All new `sources:` entries use the f001 schema (repo-relative paths,
      globs, or URLs matching the existing `sources:` format in that doc).
- [ ] No source content was transcribed verbatim (the edit is a synthesis +
      pointer, not a copy-paste).

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

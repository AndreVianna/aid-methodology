# State: ANALYZE

ANALYZE maps the user prompt onto a concrete set of (doc, change) pairs. It is
selected on a fresh run (no run-state file) or when the run-state file records
`**State:** ANALYZE`.

**Cross-delivery dependency (task-040/f007):** ANALYZE consumes
`kb-freshness-check.sh` (delivery-007, f007) to intersect the prompt-implied
docs with per-doc suspect verdicts. If the script is absent (branch ordering),
ANALYZE skips the freshness fold and proceeds on the INDEX.md routing alone.

**Cross-delivery dependency (task-014/f005):** ANALYZE loads
`.aid/knowledge/INDEX.md` (f002 routing table) -- the same navigation table
`aid-query-kb` and `aid-discover` use -- to map the prompt onto candidate docs.

---

## Step 0: Initialize run-state

Write the initial run-state file at `<STATE_FILE>` (path resolved by
`SKILL.md § State Detection`):

```
**State:** ANALYZE
**Prompt:** <the user's argument verbatim>
**Started:** <ISO-8601 timestamp>
**Branch:** (to be filled by DONE)
**Change Plan:** (to be filled below)
```

Print the `[State: ANALYZE]` banner from `SKILL.md § State Detection`.

---

## Step 1: Load the INDEX.md routing table

Read `.aid/knowledge/INDEX.md`. For each row in the Primary and Secondary tables,
note the Document path, Objective, Tags, and Audience. Map the user prompt onto
candidate KB docs by asking:

- Which Objective / Tags in the index match the domain the prompt describes?
- Which docs' Audience is consistent with the change being described?

Collect the initial candidate set. Every doc whose Objective or Tags overlaps
the prompt's domain is a candidate. If the prompt names a specific doc (e.g.
"update module-map.md"), include it unconditionally.

---

## Step 2: Run kb-freshness-check.sh and intersect (f007)

Run the freshness check to identify which docs' `sources:` frontmatter may have
drifted relative to their underlying source:

```bash
bash canonical/aid/scripts/kb/kb-freshness-check.sh \
  --root .aid/knowledge --format tsv
```

Parse the TSV output. For each doc, note whether the verdict is `suspect` or
`current`. Intersect with the candidate set:

- **Candidate AND suspect:** high-confidence target -- the prompt points here
  AND the doc may have drifted.
- **Candidate AND current:** still in scope -- the prompt asserts a content
  change the freshness check cannot see (e.g. a new concept the sources did not
  previously mention). Include if the prompt's stated delta applies to this doc.
- **Not a candidate AND suspect:** out of scope for this run -- do not add it
  (that is `aid-housekeep`'s job, FR-33 boundary).

If `kb-freshness-check.sh` is absent or exits non-zero, skip the freshness fold
silently and proceed with the candidate set from Step 1.

---

## Step 3: Read each candidate doc; decide the concrete change

For each doc in the targeted scope, read it and its `sources:` frontmatter field.
Decide what the prompt implies for that doc. The change is exactly one of:

| Change type | When to use |
|-------------|-------------|
| New summary+pointer entry | The doc covers this topic but lacks an entry for the specific new item |
| Corrected fact | An existing entry states something the prompt asserts is now wrong |
| New `sources:` entry | The update adds a new underlying source not listed in frontmatter |
| New concept on the spine | `domain-glossary.md` is missing a coined term introduced by the change |
| No change needed | The doc already covers the item accurately -- skip it |

Record the (doc, change-type, description) tuple for each targeted doc.

---

## Step 4: Emit the change plan

Write the (doc, change) list into the run-state file under `**Change Plan:**`.
Format:

```
**Change Plan:**
- .aid/knowledge/<doc1>.md | <change-type> | <one-line description>
- .aid/knowledge/<doc2>.md | <change-type> | <one-line description>
```

If the change plan is empty (the prompt does not imply any KB update), print:

```
[ANALYZE] No targeted KB docs identified for the supplied prompt.
Verify the prompt describes a concrete change to the project that should be
reflected in the Knowledge Base. If the change is purely internal (e.g.
a refactor with no observable contract change), no KB update is needed.
```

Then HALT (do not advance to APPLY with an empty plan).

---

## Step 5: Closure escalation (FR-32 / FR-34 hook)

Before advancing, check whether any item in the change plan introduces a
**project-specific coined term** that cannot be grounded from the artifacts in
`.aid/knowledge/` or the sources listed in the `sources:` frontmatter:

- If the term already appears in `domain-glossary.md`, it is grounded -- no
  escalation.
- If the term can be inferred from the source files listed in the candidate
  doc's `sources:` frontmatter, it is grounded -- no escalation.
- If the term is genuinely new and ungroundable from available artifacts, do
  NOT invent a definition. Instead:

  1. Append a new Q&A entry to `.aid/knowledge/STATE.md ## Q&A (Pending)`:

     ```
     ### Q{N}
     - **Category:** Update-KB / Ungroundable Concept
     - **Impact:** Required
     - **Status:** Pending
     - **Context:** /aid-update-kb ANALYZE cannot ground the term "<term>" from
       the available artifacts. The prompt states: "<relevant excerpt>".
       Sources checked: <list of sources:> entries examined.
     - **Suggested:** Provide a definition or point to the source artifact where
       "<term>" is defined so ANALYZE can author the correct glossary entry.
     ```

  2. Update the run-state file:

     ```
     **State:** ANALYZE
     **Escalation:** Ungroundable Concept "<term>" -- Q{N} appended to
       .aid/knowledge/STATE.md
     ```

  3. Print:

     ```
     [ANALYZE] Pausing -- concept "<term>" cannot be grounded from available
     artifacts. Q{N} appended to .aid/knowledge/STATE.md. Provide a definition
     or source pointer, then run /aid-update-kb again to resume.
     ```

  4. PAUSE-FOR-USER-ACTION -- do NOT advance to APPLY.

---

## Step 6: Advance

If the change plan is non-empty and no escalation was triggered:

Update the run-state file:

```
**State:** APPLY
```

Print: `[ANALYZE] Change plan ready. {N} doc(s) in scope. Advancing to APPLY.`

**Advance:** CHAIN -> APPLY (continue inline).

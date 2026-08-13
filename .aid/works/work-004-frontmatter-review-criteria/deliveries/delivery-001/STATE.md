---
delivery_state: Gated
gate_tier: Medium
gate_grade: "Pending"
gate_timestamp: "--"
ticket_ref: "--"
---

# Delivery State -- delivery-001

> **Delivery:** delivery-001
> **Work:** work-004-frontmatter-review-criteria
> **Branch:** aid/work-004-delivery-001

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. -->

- **Updated:** 2026-08-13T10:30:00Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- written by the delivery-gate closing step of aid-execute. -->

- **Issue List:** --

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch. -->

### Q1 — Is a file's resolved criteria list derivable for an arbitrary subset of the file?

- **Asked by:** an external proposal to scope the cycle N≥2 re-review (hunt for new findings only in
  what the previous FIX changed). Its one compatibility ask of this delivery: do not make resolution
  whole-file-only, or the follow-on has to reopen delivery-001.
- **Answer: yes, and in the strongest form — resolution is scope-free.** The resolution inputs are the
  file's **path and frontmatter** only: the registry selector picks one type, and the resolved list is
  `union(global rows, that type's rows, the file's own review-criteria:)`. No step reads file content,
  section structure, or line numbers. So the resolved list for a section is not merely *derivable* from
  the whole-file list — it is **the same list**. Narrowing the surface narrows what you check the list
  against, never the list itself. **No change to this delivery is needed.**
- **Caveat the follow-on must carry, because this delivery does not settle it.** Resolution scope and
  **evaluation** scope are different properties, and only the first is scope-free. Whether an individual
  criterion yields a correct verdict against a subset varies per criterion, and **nothing declares
  which**:
  - subset-evaluable — `G-01` (cosmetic counts), `G-02` (durable citations), `SK-01` (each dispatch-table
    agent resolves): each fires on a local occurrence.
  - whole-file only — `KB-02` (exactly one concern per doc, and the layout's last section): a section
    cannot witness it.
  - whole-corpus — `G-07` (every in-scope file resolves to exactly one type): not even whole-file.

  A scoped cycle that evaluates a whole-file criterion against one changed section returns a **false
  verdict**, not a narrower one. The follow-on therefore derives each criterion's evaluation scope, or
  declares it — an `evaluation-scope` key would be **new mechanism**, which **C-1** bars from this work,
  so it is correctly the follow-on's to add and not smuggled in here.
- **Scope decision:** the proposal is **recorded, not adopted.** It is a follow-on work needing an owner
  decision; delivery-001's scope is unchanged, and none of its 7 tasks moved.

### Q2 — Is a criterion ENTRY open to unknown keys, or validated as a closed key set?

- **Asked by:** the same external proposal, re-sent with a second compatibility ask. Its reason: a
  planned follow-on adds one optional key (`oracle:`) to a criterion entry. If entries are a closed
  key set, that is a schema migration across every criterion delivery-002's 290-file walk will have
  written; if entries inherit the document-level tolerance, it is a pure addition.
- **Answer: it was not stated either way, so it is now stated — tolerated.**
  `frontmatter-schema.md § Parsing rules` already said "Unknown fields are tolerated
  (forward-compatible with future schema additions)" at **document** level, and the ask is right that
  nothing said it at **list-entry** level. One sentence added there, plus a matching line in the
  graded-content list so the two cannot be read as contradicting each other.
- **The distinction the wording is careful about:** tolerating an unknown key and omitting a required
  one are different things, and the entry's required keys are unchanged — `id`, `kind`, `criterion`,
  `severity` on a `validate`, `why` always. An unknown key is tolerated *and not graded*, because
  there is nothing yet to grade it against.
- **Scope:** this is one sentence extending a rule the schema already carried to the level below,
  inside a file **task-002 already edits**. It adds no mechanism (**C-1**) and no acceptance criterion,
  so it needs no SPEC reopen. Applied during delivery-001's gate fix cycle so the gate reviewer sees it.

### Q3 — The two follow-on works themselves

- **Recorded, not adopted, and not scheduled here.** Both need an owner decision: (1) scope the cycle
  N≥2 re-review to what the previous FIX changed, keeping full ledger verification plus one final full
  pass; (2) add an optional `oracle:` key carrying an executable check for a criterion that can be
  decided mechanically.
- **Both asks above are now satisfied, so neither follow-on needs to reopen delivery-001.**
- **One convergence worth noting for whoever picks these up.** Q1 recorded a caveat: resolution is
  scope-free, but **evaluation** scope is not — `KB-02` is whole-file and `G-07` whole-corpus, so a
  scoped cycle that evaluates them against one changed section returns a false verdict rather than a
  narrower one. Follow-on 2's `oracle:` key largely dissolves that caveat for exactly the criteria it
  bites hardest on: a criterion with an executable oracle is re-decided by running it, at any scope
  and at negligible cost, so its evaluation scope stops mattering. The proposal's own worked example
  is `G-07` — the same criterion Q1 named as the worst case. **Follow-on 2 is therefore a
  prerequisite-shaped sibling of follow-on 1, not an independent nice-to-have**, and sequencing 2
  before or with 1 would remove follow-on 1's sharpest correctness objection instead of guarding
  around it.

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup assembled from tasks/task-NNN/STATE.md. -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

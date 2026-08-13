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

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup assembled from tasks/task-NNN/STATE.md. -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

# Feature Decomposition Process

Full process for State 5: decomposing approved Functional Requirements into
feature sections of `REQUIREMENTS.md § 11 Features`.

Features are **sections, not folders**. A feature is a decomposition of §5 into an
independently implementable unit — it is not a second place to state requirements.
Everything it needs already exists upstream in the same document: §5 states the
requirement, §9 states the criteria, §3 states the user types. The feature section
cites those and adds only what decomposition itself decides — the boundary, the
priority, and (later, from `/aid-specify`) the technical approach.

That is why there is one document. When each feature had its own `SPEC.md`, the
same criterion was written twice — once in §9 and again in every SPEC that claimed
it — and the two could disagree without anything noticing. Both CRITICAL findings
in this project's largest work to date were exactly that: sibling specs asserting
different values for one shared fact. Sections of a single document cannot diverge
that way, because there is only one statement to read.

---

## Step 1: Analyze

Read REQUIREMENTS.md (in the work folder), focusing on:
- §5 Functional Requirements — primary source for features
- §4 Scope — boundaries (in scope / out of scope)
- §9 Acceptance Criteria — assign to features by `AC-N` id
- §10 Priority — feature priority

If KB exists, also read `.aid/knowledge/INDEX.md` and relevant KB documents
to understand existing features/modules that may influence decomposition.

## Step 2: Propose Feature List

```
Based on the functional requirements, I've identified {N} features:

| # | Feature | Description | Requirements | Criteria | Priority |
|---|---------|-------------|--------------|----------|----------|
| 001 | {Title} | {one-line description} | §5 FR-1, FR-2 | AC-1, AC-4 | Must |
| 002 | {Title} | {one-line description} | §5 FR-3 | AC-2 | Must |
| 003 | {Title} | {one-line description} | §5 FR-4 | AC-3, AC-5 | Should |

Does this decomposition look right?

[1] Approve as-is
[2] Adjust — tell me what to change (add, remove, merge, split, rename)
```

**Feature decomposition rules:**
- Each feature should be independently implementable
- **Every §5 functional requirement maps to at least one feature** — an unmapped
  requirement is either out of scope (say so in §4) or a missing feature
- **Every §9 criterion is owned by exactly one feature** — two features claiming
  one criterion means the boundary is wrong; zero means the criterion is orphaned
- Features too large to implement in one sprint should be split
- Related requirements forming a single user journey should be one feature
- Priority comes from §10 or context in REQUIREMENTS.md

Both coverage rules are stated as rules because they are decidable from the
document alone: the requirement ids and criterion ids either all appear in the
table or they do not. State the gap rather than papering over it.

## Step 3: Process Response

- **[1] Approve:** Write the feature sections (Step 4)
- **[2] Adjust:** Modify the list per user feedback. Present again. Repeat until approved.

## Step 4: Write the Feature Sections

Append one `###` subsection per approved feature to `REQUIREMENTS.md § 11 Features`,
in the shape the template defines
(`../../../aid/templates/requirements/requirements-template.md § 11 Features`).

For each feature fill:

- **Title:** human-readable feature name
- **Priority:** from §10 or context (Must / Should / Could)
- **Requirements:** the `§5 FR-N` ids this feature implements
- **Criteria:** the `§9 AC-N` ids this feature owns — **ids only, never the
  criterion text.** §9 is the single statement; restating it here creates two
  copies that can disagree. If a §9 criterion does not name an observable, that is
  a defect in §9 — raise it rather than carrying it forward
  (`../../../aid/templates/requirements/requirements-template.md § Verifiable Acceptance Criteria`)
- **Description:** synthesized from §5 in stakeholder language
- **User Stories:** extracted or synthesized, using user types from §3
- **Technical Specification:** leave as the template placeholder — `/aid-specify`
  fills it

No `features/` directory is created, and no `SPEC.md` is written. A feature has no
files of its own.

## Step 5: Update Meta-Documents

1. Add Review History entry in STATE.md `## Interview State`:
   `| {N} | {today} | — | Feature Decomposition | {N} features defined |`
2. Record the features in STATE.md `## Features State` (one row per feature —
   this is the process view; §11 is the definition)
3. Update `.aid/knowledge/INDEX.md` if it exists — add work reference

Print:
```
✅ Feature decomposition complete. {N} features defined in REQUIREMENTS.md §11:

  001 — {Title}    §5 FR-1, FR-2    AC-1, AC-4    Must
  002 — {Title}    §5 FR-3          AC-2          Must

Every §5 requirement is mapped; every §9 criterion is owned exactly once.

Next steps:
- Review §11 in REQUIREMENTS.md if desired
- Run /aid-specify feature-001 to begin technical specification
```

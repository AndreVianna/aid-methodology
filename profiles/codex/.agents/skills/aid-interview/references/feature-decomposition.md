# Feature Decomposition Process

Full process for State 5: decomposing approved Functional Requirements into discrete
feature folders with SPEC.md files.

---

## Step 1: Analyze

Read REQUIREMENTS.md (in the work folder), focusing on:
- §5 Functional Requirements — primary source for features
- §4 Scope — boundaries (in scope / out of scope)
- §9 Acceptance Criteria — distribute to features
- §10 Priority — feature priority

If KB exists, also read `.aid/knowledge/INDEX.md` and relevant KB documents
to understand existing features/modules that may influence decomposition.

## Step 2: Propose Feature List

```
Based on the functional requirements, I've identified {N} features:

| # | Folder Name | Description | Source | Priority |
|---|-------------|-------------|--------|----------|
| 1 | feature-001-{name} | {one-line description} | §5.x, §7.x | Must |
| 2 | feature-002-{name} | {one-line description} | §5.x | Must |
| 3 | feature-003-{name} | {one-line description} | §5.x | Should |
| ... | ... | ... | ... | ... |

Does this decomposition look right?

[1] Approve as-is
[2] Adjust — tell me what to change (add, remove, merge, split, rename)
```

**Feature decomposition rules:**
- Each feature should be independently implementable
- Feature names use kebab-case (for folder names)
- Every functional requirement from §5 must map to at least one feature
- Features that are too large to implement in one sprint should be split
- Related requirements that form a single user journey should be one feature
- Priority comes from §10 or context in REQUIREMENTS.md

## Step 3: Process Response

- **[1] Approve:** Create feature folders (Step 4)
- **[2] Adjust:** Modify the list per user feedback. Present again. Repeat until approved.

## Step 4: Create Feature Folders

Create `features/` directory inside the work folder if it doesn't exist.

For each approved feature, create `features/feature-{NNN}-{name}/SPEC.md` using the
template from `../../../templates/feature.md`. Fill in:

- **Title:** feature name (human-readable)
- **Change Log:** `| {today} | Feature identified from REQUIREMENTS.md {source sections} | /aid-interview |`
- **Source:** relevant REQUIREMENTS.md section references
- **Description:** synthesized from §5 in stakeholder language
- **User Stories:** extracted or synthesized from REQUIREMENTS.md, using user types from §3
- **Priority:** from §10 or context (Must / Should / Could)
- **Acceptance Criteria:** from §9 mapped to this feature, or synthesized from §5
- **Technical Specification:** leave as template placeholder (added by /aid-specify)

## Step 5: Update Meta-Documents

1. Add Review History entry in INTERVIEW-STATE.md:
   `| {N} | {today} | — | Feature Decomposition | {N} features created |`
2. Update `.aid/knowledge/INDEX.md` if it exists — add work/features reference
3. Update `.aid/knowledge/README.md` if it exists — add work to revision history

Print:
```
✅ Feature decomposition complete. {N} features created in {work}/features/:

{list each: feature-001-name/, feature-002-name/, ...}

Next steps:
- Review the feature SPEC.md files if desired
- Run /aid-specify {work}/feature-001 to begin technical specification
```

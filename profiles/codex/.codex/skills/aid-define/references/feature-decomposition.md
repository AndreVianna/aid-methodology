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
- **Change Log:** `| {today} | Feature identified from REQUIREMENTS.md {source sections} | /aid-define |`
- **Source:** relevant REQUIREMENTS.md section references
- **Description:** synthesized from §5 in stakeholder language
- **User Stories:** extracted or synthesized from REQUIREMENTS.md, using user types from §3
- **Priority:** from §10 or context (Must / Should / Could)
- **Acceptance Criteria:** from §9 mapped to this feature, or synthesized from §5. **Carry each
  criterion's `Modality` across with it** — a mapped criterion keeps the modality it had in §9, and a
  criterion *synthesized* from §5 inherits the modality of the requirement it discharges. Do not default
  to `MUST`: it is the first thing the severity scale reads, so flattening it here silently inflates the
  severity of every future finding against that criterion.
- **Technical Specification:** leave as template placeholder (added by /aid-specify)

## Step 4b: Gate the carried modalities

Run the modality gate over the folders just created, before touching any meta-document:

```bash
bash .codex/aid/scripts/kb/lint-modality.sh --root .aid/works/{work}/features
```

Exit `0` means every acceptance criterion carried its `Modality` across. Exit `1` lists the rows that
did not — fix them here, not later: an untagged criterion is invisible until a reviewer is graded
against it, at which point it becomes a criteria gap that blocks the grade and costs a human round
trip. Exit `2` means the sweep inspected nothing, which for a just-written feature set means the
criteria are not in the `| AC-N | MODALITY | ... |` row shape the template declares.

Without this step the instruction above is unenforced: Step 4 orders the modality carried across, and
until this gate existed nothing checked that it had been — the only gate ran later, at `/aid-specify`,
over one feature at a time.

## Step 5: Update Meta-Documents

1. Add Review History entry in STATE.md `## Interview State`:
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

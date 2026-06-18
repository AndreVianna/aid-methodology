# Cross-Reference & Refine Process

Full validation process for State 6: requirements approved and features created.
Cross-references REQUIREMENTS.md against the Knowledge Base and codebase.

---

## Entry Point

**Ask first:** _"Requirements are approved and features are defined. Do you want to run
a cross-reference validation against the KB? Is there something specific to re-examine?"_

If user confirms → continue below.
If user has a specific concern → record it as context for the validation.
If user says no → print status summary and stop.

Validate against KB and codebase.

---

## 6a. Load Context

1. Read REQUIREMENTS.md (in the work folder)
2. Read STATE.md `## Interview Status` and `## Cross-phase Q&A`
3. Read `.aid/knowledge/INDEX.md` (if exists)
4. Read ALL KB documents listed in INDEX.md
5. Read all SPEC.md files in the work's `features/` subdirectories

## 6b. Cross-Reference

For each section of REQUIREMENTS.md, check against KB:

1. **Contradictions** — Requirement conflicts with KB evidence
2. **Gaps** — KB reveals things requirements should address but don't
3. **Missing evidence** — Requirements make claims that can't be verified
   (use `Grep` and `Glob` to search the actual codebase)
4. **Staleness** — KB updated since interview, affecting requirements
5. **Feature alignment** — Do feature SPEC.md files still match REQUIREMENTS.md?

## 6c. Grade

Use the universal rubric (`../../../templates/grading-rubric.md`). Classify each finding
by severity (Minor/Low/Medium/High/Critical). Grade is calculated — worst issue dominates.

Compare to minimum grade from `bash .claude/aid/scripts/config/read-setting.sh --skill interview --key minimum_grade --default A`.

**Update `**Interview Grade:**` in STATE.md `## Interview Status`.**

## 6d. Present Findings

```
[Cross-Reference — Grade: {grade}]

Checked REQUIREMENTS.md against {N} KB documents and {M} features.

**Contradictions:** {count}
**Gaps:** {count}
**Unverified claims:** {count}
**Feature alignment issues:** {count}

{details for each}

{If grade ≥ minimum:}
No blocking issues found. Requirements are consistent with the Knowledge Base.

{If grade < minimum:}
I have {N} questions to resolve these. Let's go through them one at a time.
```

## 6e. Create Q&A Entries and Ask

For each finding, add a Q&A entry in STATE.md `## Cross-phase Q&A`:

```markdown
### Q{N}

- **Category:** {category, e.g., Architecture, Requirements, Security}
- **Impact:** {High|Medium|Low|Required}
- **Status:** Pending
- **Context:** {why this matters; what evidence was found; surfaced by /aid-interview (cross-reference)}
- **Suggested:** {answer if inferrable from KB/code, or "—"}
```

Then present them one at a time using State 2 (Q&A mode) logic.

After each answer:
1. Update REQUIREMENTS.md
2. Update affected feature SPEC.md if the answer changes a feature
3. Add Change Log entries where content changed

## 6f. Wrap Up

After all questions answered:

1. Add Review History entry in STATE.md `## Interview Status`
2. Add Change Log entry in REQUIREMENTS.md
3. Print: `✅ Cross-reference complete. Run /aid-interview again to verify.`

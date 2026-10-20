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
2. Read STATE.yml's `interview` key and `qa` sequence
3. Read `.aid/knowledge/INDEX.md` (if exists)
4. Read ALL KB documents listed in INDEX.md
5. Read `REQUIREMENTS.md § 11 Features` — every `### Feature NNN` subsection

## 6b. Cross-Reference

For each section of REQUIREMENTS.md, check against KB:

1. **Contradictions** — Requirement conflicts with KB evidence
2. **Gaps** — KB reveals things requirements should address but don't
3. **Missing evidence** — Requirements make claims that can't be verified
   (use `Grep` and `Glob` to search the actual codebase)
4. **Staleness** — KB updated since interview, affecting requirements
5. **Feature alignment** — Do the §11 feature sections still match §5 and §9? Every §5 requirement mapped, every §9 criterion owned exactly once?

## 6c. Grade

Use the universal rubric (`../../../aid/templates/grading-rubric.md`). Classify each finding
by severity (Minor/Low/Medium/High/Critical). Grade is calculated — worst issue dominates.

Compare to minimum grade from `bash .aid/runtime/scripts/config/read-setting.sh --skill interview --key minimum_grade --default A`.

**Update `interview.grade` in STATE.yml.**

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

## 6e. Record Questions and Ask

Each finding that needs the user is already a `Pending` question in the work's `qa` sequence: the
reviewer recorded it with `writeback-state.sh --ask` (category, impact, context, suggested, `--asked-by aid-reviewer`)
and listed its id in its report. The main conversation does not record it a second time. If the main conversation
finds a gap of its own that the reviewer did not record, it records that one with `--ask` first, with
`--asked-by aid-define`.

Then present them one at a time through the question protocol, using the ids the reviewer listed. These questions are
asked by the main conversation only; a worker records them and lists them in its report. Record each answer with
`--answer --id <id>` (`--state Answered`, or `Skipped`) before the next question.

After each answer:
1. Update REQUIREMENTS.md
2. Update the affected §11 feature section if the answer changes a feature

## 6f. Wrap Up

After all questions answered:

1. Record the cross-reference event (aspirational Review History tracking -- no dedicated
   key in `work-state-template.yml`; see `SKILL.md`'s accuracy note)
2. Print: `✅ Cross-reference complete.`

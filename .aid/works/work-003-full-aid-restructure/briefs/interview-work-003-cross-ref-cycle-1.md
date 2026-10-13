# Reviewer brief -- aid-define cross-reference, cycle 1

ARTIFACTS UNDER REVIEW:
  - .aid/works/work-003-full-aid-restructure/REQUIREMENTS.md (§1-§10 approved requirements + §11 Features: 9 `### Feature NNN` sections)

  On cycle 1 and on the final full pass this is ONE unlabelled list, as before.
  From cycle 2 it carries TWO labelled lists and they mean different things:
    VERIFY (full)  -- re-check EVERY existing ledger row against these. Never
                      scoped: skipping one breaks Recurred detection.
    HUNT (scoped)  -- look for NEW findings ONLY here. This is what the
                      previous FIX changed, plus the files that reference it.
  Do not hunt outside HUNT, and do not skip anything in VERIFY. Definitions:
  `reviewer-ledger-schema.md` section "Two sets from cycle 2".

CONTEXT:
REQUIREMENTS.md was just approved and 9 features were decomposed from §5 Functional Requirements. This is the cross-reference pass that validates requirements + feature boundaries against the KB and codebase before any feature reaches /aid-specify. Note: AC-22, AC-24, AC-25 are deliberately cross-cutting (every feature must pass them) and owned by no single feature; AC-26/AC-27 were added during decomposition.

  Reviewer self-check: If CONTEXT contains downstream-phase concerns (specify,
  plan, detail, execute), flag it as an OOS observation and bound your review
  to the REQUIREMENTS.md sections listed in ARTIFACTS.

RUBRIC: .aid/runtime/templates/grading-rubric.md (universal severity → grade table)
  Grade REQUIREMENTS.md + feature decomposition for:
    - Internal consistency (objective ↔ functional requirements ↔ acceptance criteria)
    - Consistency with the KB (architecture, technology-stack, integration-map)
    - Codebase reality (proposed integration points exist; no contradictions with
      what the code already does)
    - Feature decomposition completeness (every Must requirement maps to ≥1 feature)
    - Feature boundary clarity (no feature mixes unrelated concerns; no overlap)
    - Gaps that warrant Q&A back to the user (record as Pending Q&A, not findings)

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Each artifact declares, or inherits, the criteria it must be true against. Resolve them
  and verify against the union -- global, then the artifact's document type, then any
  file-class row whose membership test it satisfies, then the artifact's own
  `review-criteria:` frontmatter; most specific wins on an id collision. An artifact outside
  the registry's corpus (a work artifact under `.aid/works/`) resolves to NO type, which is
  correct and not a finding -- the file-class rows are what reach it.
  Resolution is defined in .aid/runtime/templates/kb-authoring/review-rubric.md
  (section: Resolving review criteria); the type registry and the criteria table live in
  .aid/knowledge/authoring-conventions.md. This brief deliberately does NOT restate them.
  - Cite the criterion `id` as a prefix in the ledger's Description cell (7 columns, no
    new column). A finding citing no id, or an id resolving nowhere, is itself a defect.
  - A `kind: exclude` criterion binds you: reporting it is a defect in the review.
  - **If a criterion carries an `oracle:`, RUN it -- do not re-read the criterion to
    reach the same verdict.** Invoke it from the repository root under a 60-second
    timeout. It reports per FILE: exit 0 means no violation among the files it decided,
    exit 1 means at least one `VIOLATION <path>` line, exit 2 (or any other exit, a
    timeout, or exit 1 with no VIOLATION line) means it could not decide.
  - **`UNDECIDED <path>` lines are normal, not a failure.** Take the decided files as
    settled and judge only the undecided remainder by reading.
  - **A missing, non-executable, crashing, timed-out or malformed oracle DEGRADES that
    criterion to reading, and you record that the degradation happened.** Never let a
    degraded oracle read as a pass, and never file it as a violation -- "I could not
    tell" is neither.
  - One finding per `VIOLATION` line: the criterion `id` as the Description prefix, the
    invocation and that line in Evidence. Seven columns, unchanged.
  - If the severity came from a file-level override, record the resolved severity and the
    overriding file's `why` in the Evidence cell.

OUT OF SCOPE (do NOT grade against):
  - `#### Technical Specification` subsections — /aid-specify hasn't run yet for
    these features; only the auto-generated feature scaffold is in scope here
  - PLAN.md sequencing (doesn't exist yet)
  - Task breakdown (doesn't exist yet)
  - KB document accuracy — route KB-source findings to /aid-discover Q&A as
    observations for the upstream skill
  - Interview process quality (whether the right questions were asked) — that's
    a meta concern, not graded here

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/interview-work-003-cross-ref.md`. Do NOT count toward severity
  totals or grade. Note the routing destination (KB, SPEC) in Description/Evidence
  so the orchestrator can write the cross-phase Q&A entry.

DELIVERABLES:
  - BEFORE dispatching: render this brief to
    `.aid/works/work-003-full-aid-restructure/briefs/<scope>-cycle-<N>.md` and, from that same step, run
    `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief <that file>`.
    The file is what you are given and what the meter measures, so they cannot disagree;
    its absence is the signal that the step did not run. See
    `reviewer-dispatch.md` -- "Render the brief TO A FILE".

  - Findings format: severity-tagged + source-tagged (REQUIREMENTS | FEATURE | KB)
  - Output location: `.aid/.temp/review-pending/interview-work-003-cross-ref.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .aid/runtime/scripts/grade.sh; minimum resolved via
    `bash .aid/runtime/scripts/config/read-setting.sh --skill interview --key minimum_grade --default A`
  - Pending Q&A: write user-facing questions to the `qa` sequence in
    `.aid/works/work-003-full-aid-restructure/STATE.yml` (entries with `state: Pending`) -- the consolidated
    work STATE.yml per FR2 area-STATE consolidation; the legacy `INTERVIEW-STATE.md`
    is RETIRED -- so the next `/aid-define` run picks them up in Q&A mode
  - The aid-reviewer NEVER edits REQUIREMENTS.md or SPEC scaffolds — only grades and lists issues

LEDGER LIFECYCLE:
  Append new findings as rows with Status: Pending to `.aid/.temp/review-pending/interview-work-003-cross-ref.md`. Read the existing file first if it
  exists. Output per `.aid/runtime/templates/reviewer-ledger-schema.md` -- ONE table, no narrative.
  After writing the ledger, run: `bash .aid/runtime/scripts/grade.sh .aid/.temp/review-pending/interview-work-003-cross-ref.md` and include the grade in
  your return message.

CYCLE 1 -- ALSO RUN the cross-document contradiction pass (Guard 2) defined in
  `.aid/runtime/templates/reviewer-dispatch.md` section "The cross-document contradiction pass (Guard 2)":
  look for two parts of REQUIREMENTS.md (incl. §11 feature sections) asserting different values for one shared fact.

DO NOT write to STATE.yml or REQUIREMENTS.md. Instead, in your return message, list each user-facing
question you would add to the `qa` sequence (category, impact, context, suggested answer); the
orchestrator writes them.

CROSS-REFERENCE PROCESS (execution detail; steps 6d-6f are performed by the orchestrator, not you):
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

## 6e. Create Q&A Entries and Ask

For each finding, add a Q&A entry to the `qa` sequence in STATE.yml:

```markdown
### Q{N}

- **Category:** {category, e.g., Architecture, Requirements, Security}
- **Impact:** {High|Medium|Low|Required}
- **Status:** Pending
- **Context:** {why this matters; what evidence was found; surfaced by /aid-define (cross-reference)}
- **Suggested:** {answer if inferrable from KB/code, or "—"}
```

Then present them one at a time using State 2 (Q&A mode) logic.

After each answer:
1. Update REQUIREMENTS.md
2. Update the affected §11 feature section if the answer changes a feature

## 6f. Wrap Up

After all questions answered:

1. Record the cross-reference event (aspirational Review History tracking -- no dedicated
   key in `work-state-template.yml`; see `SKILL.md`'s accuracy note)
2. Print: `✅ Cross-reference complete. Run /aid-define again to verify.`

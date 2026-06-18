# /aid-interview — Reviewer Dispatch Brief Template

Loaded by `/aid-interview` CROSS-REFERENCE state (State 6). Renders the brief
passed to the `aid-reviewer` sub-agent. Follows `.claude/aid/templates/reviewer-dispatch.md`.

`{{ARTIFACTS}}` and `{{CONTEXT}}` are filled at dispatch time.

```
ARTIFACTS UNDER REVIEW:
{{ARTIFACTS}}

CONTEXT:
{{CONTEXT}}

  Reviewer self-check: If CONTEXT contains downstream-phase concerns (specify,
  plan, detail, execute), flag it as an OOS observation and bound your review
  to the REQUIREMENTS.md + feature SPEC.md files listed in ARTIFACTS.

RUBRIC: .claude/aid/templates/grading-rubric.md (universal severity → grade table)
  Grade REQUIREMENTS.md + feature decomposition for:
    - Internal consistency (objective ↔ functional requirements ↔ acceptance criteria)
    - Consistency with the KB (architecture, technology-stack, integration-map)
    - Codebase reality (proposed integration points exist; no contradictions with
      what the code already does)
    - Feature decomposition completeness (every Must requirement maps to ≥1 feature)
    - Feature boundary clarity (no feature mixes unrelated concerns; no overlap)
    - Gaps that warrant Q&A back to the user (record as Pending Q&A, not findings)

OUT OF SCOPE (do NOT grade against):
  - SPEC.md Technical Specification sections — /aid-specify hasn't run yet for
    these features; only the auto-generated feature scaffold is in scope here
  - PLAN.md sequencing (doesn't exist yet)
  - Task breakdown (doesn't exist yet)
  - KB document accuracy — route KB-source findings to /aid-discover Q&A as
    observations for the upstream skill
  - Interview process quality (whether the right questions were asked) — that's
    a meta concern, not graded here

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `.aid/.temp/review-pending/interview-{work}.md`. Do NOT count toward severity
  totals or grade. Note the routing destination (KB, SPEC) in Description/Evidence
  so the orchestrator can write the cross-phase Q&A entry.

DELIVERABLES:
  - Findings format: severity-tagged + source-tagged (REQUIREMENTS | FEATURE | KB)
  - Output location: `.aid/.temp/review-pending/interview-{work}.md`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .claude/aid/scripts/grade.sh; minimum resolved via
    `bash .claude/aid/scripts/config/read-setting.sh --skill interview --key minimum_grade --default A`
  - Pending Q&A: write user-facing questions to `.aid/{work}/STATE.md ## Pending Q&A`
    (the consolidated work STATE.md per FR2 area-STATE consolidation; the
    legacy `INTERVIEW-STATE.md` is RETIRED) so the next `/aid-interview` run
    picks them up in Q&A mode
  - The aid-reviewer NEVER edits REQUIREMENTS.md or SPEC scaffolds — only grades and lists issues
```

## Substitution at dispatch time

- `{{ARTIFACTS}}` — `.aid/{work}/REQUIREMENTS.md` plus the scaffold SPEC.md
  files in `.aid/{work}/features/feature-*/SPEC.md` (the auto-generated portion
  written during Feature Decomposition — State 5).
- `{{CONTEXT}}` — short, descriptive-only background:
  ```
    REQUIREMENTS.md was just approved and N features were decomposed from §5
    Functional Requirements. This is the cross-reference pass that validates
    requirements + feature boundaries against the KB and codebase before any
    feature reaches /aid-specify.
  ```
  Do NOT include interview transcripts, the aid-interviewer's working notes, or
  references to downstream skills.

**Derive from disk, not memory.** When populating `{{ARTIFACTS}}` at dispatch
time, derive the list from a deterministic source (e.g., `git diff --name-only`
for PR-level reviews, or the executor's produced-file list for per-task reviews),
filtered by the OUT OF SCOPE list above. Lists built from memory of what was
worked on tend to omit incidentally-touched files; the aid-reviewer then can't grade
what it doesn't know about.

# Reviewer Brief Template + Invocation Manifest

**One shared brief, two per-skill sections.** Six per-skill briefs each carried ~70 lines, of which
only two sections differed. Everything else — the placeholders, the out-of-scope policy, the
deliverables, the derive-from-disk rule — was copied six times and drifted six ways.

A caller now supplies an **invocation manifest** and the two sections that are genuinely its own.

---

## The invocation manifest

Passed as a file, not as free text. Free-text briefs cannot be validated, so a missing field became a
reviewer guessing rather than a caller failing.

```yaml
# .aid/.temp/review-invocation/<scope>.yml
scope:        specify-feature-003        # names the ledger; must match ^[a-z0-9][a-z0-9-]{0,63}$
artifacts:                               # derived from disk, never from memory
  - .aid/works/work-003/features/feature-003/SPEC.md
rule_set:     definition                 # resolved via review-rubrics/INDEX.md
ledger:       .aid/.temp/review-pending/specify-feature-003-cycle1.md   # SCRATCH, not durable
resume_mode:  new-cycle                  # new-cycle | resume  (declared; the file's presence decides)
depth:        deep                       # deep | light
tier:         medium                     # escalate to large to match a large executor
minimum_grade: A                         # resolved by read-setting.sh, not hardcoded here
gap_depth:    0                          # 0-2; >=1 means restricted mode
context:      |                          # descriptive ONLY -- no prior grades, no working notes
  SPEC.md for feature-003. All sections Complete.
```

**Every field is required except `gap_depth`** (defaults `0`). A caller that cannot fill one has not
finished deciding what it is asking for.

`ledger` is a **scratch** path. The durable `<scope>.md` is the orchestrator's; a reviewer that is
handed it can contaminate a later cycle with an earlier verdict.

---

## The brief

Rendered from the manifest plus the caller's two sections. `{{...}}` comes from the manifest.

```
ARTIFACTS UNDER REVIEW:
{{ARTIFACTS}}

CONTEXT:
{{CONTEXT}}

  Reviewer self-check: if CONTEXT names a downstream phase's concerns, that is an
  out-of-scope observation -- bound your review to ARTIFACTS.

RULE SET: {{RULE_SET}} -- resolve via .cursor/aid/templates/review-rubrics/INDEX.md
  Severity is a LOOKUP against the violated rule's anchor, per
  .cursor/aid/templates/grading-rubric.md#severity-scale. Do not invent a band.

{{RUBRIC_BODY}}          <- the caller's section 1: what this artifact is graded FOR

{{OUT_OF_SCOPE}}         <- the caller's section 2: what must NOT be graded here

OUT-OF-SCOPE FINDINGS POLICY:
  Record an out-of-scope observation as a Status: OOS row in the same ledger. It does
  not count toward the grade. Name the routing destination in Evidence so the calling
  skill can raise the cross-phase Q&A entry.
  An OOS row still needs a rule ID -- there is no ungrounded-finding exemption. If no
  rule covers the concern at all, that is a GAP, not a finding.

MISSING CRITERIA:
  If no rule in either authority ladder speaks to a concern, write a G- gap row --
  see .cursor/aid/templates/criteria-gap-protocol.md. Do NOT invent a criterion,
  and do not soften it into a low-severity finding. You cannot ask the user; put your
  proposal in your return message and the calling skill asks once for the batch.

DELIVERABLES:
  - Ledger: {{LEDGER}} -- the SCRATCH path above, written one row per
    `writeback-ledger.sh` call. Never re-emit the table.
  - Every finding row carries a rule ID and a looked-up severity.
  - Checkpoint coverage per unit: `In Progress` before, `Examined` after.
  - Grade: computed by grade.sh from the ledger, after check-gaps.sh passes.
    Minimum: {{MINIMUM_GRADE}}. You do NOT compute or state a grade.
  - You never edit the artifact. You report.
```

---

## What a caller supplies

Exactly two sections, and nothing else:

| Section | Content |
|---|---|
| `RUBRIC_BODY` | what this artifact type is graded **for** — the concerns unique to it |
| `OUT_OF_SCOPE` | what belongs to another phase and must not be penalised here |

Anything a caller wants to add beyond those two belongs in this template (if every caller needs it) or
in the rule set (if it is a review criterion). A third per-caller section is how six copies happened.

## Derive artifacts from disk, not memory

Build `artifacts` from a deterministic source — `git diff --name-only` for a change-level review, the
executor's produced-file list for a per-task one — then subtract the out-of-scope set. Lists built from
memory omit incidentally-touched files, and the reviewer cannot grade what it was never shown.

## See also

- [`review-rubrics/INDEX.md`](review-rubrics/INDEX.md) — rule-set routing
- [`reviewer-ledger-schema.md`](reviewer-ledger-schema.md) — the ledger the brief points at
- [`criteria-gap-protocol.md`](criteria-gap-protocol.md) — what to do when no rule exists
- [`grading-rubric.md#severity-scale`](grading-rubric.md#severity-scale) — the single severity source

## Change Log

| Date | Change |
|---|---|
| 2026-07-29 | Created. Absorbs the boilerplate six per-skill briefs each carried; adds the invocation manifest. |

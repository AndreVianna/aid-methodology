# /aid-specify — Reviewer Dispatch Brief Template

Loaded by `/aid-specify` REVIEW state. Renders the brief passed to the
`aid-reviewer` sub-agent. Follows `.agent/aid/templates/reviewer-dispatch.md`.

`{{ARTIFACTS}}` and `{{CONTEXT}}` are filled at dispatch time.

```
ARTIFACTS UNDER REVIEW:
{{ARTIFACTS}}

  On cycle 1 and on the final full pass this is ONE unlabelled list, as before.
  From cycle 2 it carries TWO labelled lists and they mean different things:
    VERIFY (full)  -- re-check EVERY existing ledger row against these. Never
                      scoped: skipping one breaks Recurred detection.
    HUNT (scoped)  -- look for NEW findings ONLY here. This is what the
                      previous FIX changed, plus the files that reference it.
  Do not hunt outside HUNT, and do not skip anything in VERIFY. Definitions:
  `reviewer-ledger-schema.md` section "Two sets from cycle 2".

CONTEXT:
{{CONTEXT}}

  Reviewer self-check: If CONTEXT contains downstream phase concerns (planning,
  task breakdown, execution), flag it as an OOS observation and bound your
  review to the SPEC.md sections listed in ARTIFACTS.

RUBRIC: .agent/aid/templates/grading-rubric.md (universal severity → grade table)
  Grade ONE feature's SPEC.md technical specification for:
    - Consistency with the KB (architecture, module-map, coding-standards, schemas)
    - Internal coherence (schemas ↔ feature flow ↔ layers ↔ acceptance criteria)
    - Codebase reality (does the proposed integration touch the modules it claims?)
    - Testability (acceptance criteria are concrete + verifiable)
    - Spec discipline (no implementation prose; design decisions captured)

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Each artifact declares, or inherits, the criteria it must be true against. Resolve them
  and verify against the union -- global, then the artifact's document type, then any
  file-class row whose membership test it satisfies, then the artifact's own
  `review-criteria:` frontmatter; most specific wins on an id collision. An artifact outside
  the registry's corpus (a work artifact under `.aid/works/`) resolves to NO type, which is
  correct and not a finding -- the file-class rows are what reach it.
  Resolution is defined in .agent/aid/templates/kb-authoring/review-rubric.md
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
  - Other features in the same work (only the named feature is under review)
  - PLAN.md sequencing (that's /aid-plan's grade)
  - Task breakdown (that's /aid-detail's grade)
  - KB document accuracy (route KB-source findings to /aid-discover Q&A — they
    are observations for the upstream skill, not penalties here)
  - REQUIREMENTS.md content (route findings to /aid-describe Q&A)
  - Any part of REQUIREMENTS.md OUTSIDE the slice this feature traces to. The brief
    carries only that slice, taken from the feature SPEC's `## Source`; the rest of the
    document is not under review here and re-reading it once per feature per cycle is
    the cost this bound exists to remove.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table at
  `{{LEDGER}}`. Do NOT count toward severity
  totals or grade. Note the routing destination (CODE | SPEC | KB | REQUIREMENTS)
  in Description/Evidence so the coordinating skill can write the cross-phase Q&A entry.

DELIVERABLES:
  - BEFORE dispatching: render this brief to
    `.aid/works/{work}/briefs/<scope>-cycle-<N>.md` and, from that same step, run
    `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief <that file>`.
    The file is what you are given and what the meter measures, so they cannot disagree;
    its absence is the signal that the step did not run. See
    `reviewer-dispatch.md` -- "Render the brief TO A FILE".

  - Findings format: severity-tagged + source-tagged (CODE | SPEC | KB | REQUIREMENTS)
  - Output location: `{{LEDGER}}`
  - Severity scale: CRITICAL | HIGH | MEDIUM | LOW | MINOR (per grading-rubric.md)
  - Grade: per .agent/aid/scripts/grade.sh; minimum resolved via
    `bash .agent/aid/scripts/config/read-setting.sh --skill specify --key minimum_grade --default A`
  - The aid-reviewer NEVER edits the SPEC — only grades and lists issues
```

## Substitution at dispatch time

- `{{ARTIFACTS}}` — the feature's `SPEC.md` path plus the section list under
  review (or "full SPEC" if all sections complete).
- `{{CONTEXT}}` — short, descriptive-only background:
  ```
    SPEC.md for feature-NNN-{name} in work-NNN-{name}. All sections marked Complete
    in the work STATE.yml's Features State view (row for this feature). This is the
    final review pass before the feature is marked Ready.
  ```
  Do NOT include the aid-architect's working notes, prior REVIEW cycle grades, or
  references to downstream skills.

**Derive from disk, not memory.** When populating `{{ARTIFACTS}}` at dispatch
time, derive the list from a deterministic source (e.g., `git diff --name-only`
for PR-level reviews, or the executor's produced-file list for per-task reviews),
filtered by the OUT OF SCOPE list above. Lists built from memory of what was
worked on tend to omit incidentally-touched files; the aid-reviewer then can't grade
what it doesn't know about.

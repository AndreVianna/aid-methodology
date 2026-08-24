# /aid-discover — Reviewer Dispatch Brief Template

Loaded by `/aid-discover` REVIEW state. Renders the brief that gets passed to
the `aid-reviewer` sub-agent. Follows `.github/aid/templates/reviewer-dispatch.md`.

`{{ARTIFACTS}}`, `{{CONTEXT}}`, and `{{GREENFIELD_BLOCK}}` are filled at dispatch
time. Other sections are static per skill.

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

{{GREENFIELD_BLOCK}}
  Reviewer self-check: If you find CONTEXT contains scope-expanding language
  (downstream phase references, specific project counts, hypothetical future
  uses, adjacent artifacts not listed in ARTIFACTS), flag it as an OOS
  observation about the brief itself and bound your review to ARTIFACTS only.

RUBRIC: kb-authoring/review-rubric.md (route by each doc's kb-category + source)
  - primary + hand-authored        → Full Primary
  - primary + generated            → Full Primary + Build-Verify (e.g., INDEX.md)
  - meta + hand-authored           → Spot-Check Snapshot only
  - meta + generated               → Build-Verify Only (e.g., metrics.md, project-index.md)
  - extension + hand-authored      → Extension-Scope (flagged outside the declared doc-set)
  - extension + generated          → Extension Build-Verify

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Each artifact declares, or inherits, the criteria it must be true against. Resolve them
  and verify against the union -- global, then the artifact's document type, then any
  file-class row whose membership test it satisfies, then the artifact's own
  `review-criteria:` frontmatter; most specific wins on an id collision. An artifact outside
  the registry's corpus (a work artifact under `.aid/works/`) resolves to NO type, which is
  correct and not a finding -- the file-class rows are what reach it.
  Resolution is defined in .github/aid/templates/kb-authoring/review-rubric.md
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
  - Code in the target repository (review the KB docs, not the code they describe)
  - Adopter-project specifics not in the ARTIFACTS list
  - Downstream skills (aid-describe, aid-define, aid-specify, etc. — they consume the KB but are not graded here)
  - Hypothetical future KB extensions

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table. Note the routing
  destination (the upstream skill the observation belongs to) in Description/Evidence.
  Do NOT count toward severity totals or the grade.

DELIVERABLES:
  - BEFORE dispatching: render this brief to
    `.aid/works/{work}/briefs/<scope>-cycle-<N>.md` and, from that same step, run
    `bash tests/review-cost-meter.sh record --task <scope> --cycle <N> --brief <that file>`.
    The file is what you are given and what the meter measures, so they cannot disagree;
    its absence is the signal that the step did not run. See
    `reviewer-dispatch.md` -- "Render the brief TO A FILE".

  - Findings format: per .github/aid/templates/kb-authoring/principles.md P3 temp-ledger
  - Ledger location: `.aid/.temp/review-pending/discovery.md`
  - Severity scale: per the routed rubric (CRITICAL / HIGH / MEDIUM / LOW / MINOR)
  - Grade: computed per .github/aid/scripts/grade.sh from the ledger; minimum is
    resolved via `bash .github/aid/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A`
  - OOS observations excluded from grade per protocol
```

## Substitution at dispatch time

Skill body renders this template with:

- `{{ARTIFACTS}}` — bullet list of KB doc paths under review for this cycle.
  Example:
  ```
    - .aid/knowledge/architecture.md
    - .aid/knowledge/module-map.md
    - .aid/knowledge/coding-standards.md
    - ...
  ```
- `{{CONTEXT}}` — short, descriptive-only background per
  reviewer-dispatch.md's CONTEXT discipline rule. Example:
  ```
    These are KB documents authored / updated in discovery cycle N. The cycle
    runs after [GENERATE | FIX] and grades all hand-authored primary docs +
    confirms generated docs were regenerated by their build scripts.
  ```
  Do NOT include downstream phase references, adopter-project counts, or
  hypothetical future uses.
- `{{GREENFIELD_BLOCK}}` — greenfield mode instruction block. Set by the `greenfield:`
  parameter of the invoking step (default `false`). Two cases:
  - `greenfield: false` (default, all ordinary aid-discover review cycles): render as
    empty (omit entirely). The reviewer sees no additional instruction; brownfield
    behavior is unchanged (NFR-2).
  - `greenfield: true` (seed review invoked from the aid-describe seed-authoring step,
    feature-003 flow step 5): render the following block verbatim --

    ```
    GREENFIELD MODE (seed review -- greenfield: true):
      This brief covers a seed review. Apply document-expectations.md
      "## Greenfield Mode" in full:
      - Evidence substitution: where a depth standard or red flag demands code/config
        evidence, substitute intent-evidence (the user's confirmed elicited statements
        and the gathered REQUIREMENTS). See "### Evidence substitution" for the specific
        C3, architecture.md, and C4 substitutions.
      - As-built red flags relaxed: suppress the named C0/technology-stack.md,
        C1/architecture.md, and C3/coding-standards.md as-built red flags listed in
        "### As-built red flags relaxed".
      - Dimension floors retained at full strength: all spine dimensions (C0-C9 and D)
        are reviewed at the same depth-standard bar. Only the evidence source shifts and
        the named as-built red flags are suppressed. No dimension is skipped.

    ```

**Derive from disk, not memory.** When populating `{{ARTIFACTS}}` at dispatch
time, derive the list from a deterministic source (e.g., `git diff --name-only`
for PR-level reviews, or the executor's produced-file list for per-task reviews),
filtered by the OUT OF SCOPE list above. Lists built from memory of what was
worked on tend to omit incidentally-touched files; the aid-reviewer agent then can't grade
what it doesn't know about.

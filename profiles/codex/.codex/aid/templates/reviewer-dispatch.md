# Reviewer Dispatch Protocol

> Normative spec for any skill that dispatches a reviewer agent. Loaded by every
> skill that runs a REVIEW state (`/aid-discover`, `/aid-execute`, `/aid-specify`,
> `/aid-plan`, `/aid-detail`).

## Why this exists

Reviewer dispatches in AID have historically used ad-hoc prose briefs. Prose briefs
leak scope: the author writes "this affects downstream phases X and Y" → the reviewer
grades for fitness against X and Y in addition to the artifact under review → findings
about adjacent concerns inflate the grade → review cycles bloat.

This protocol enforces **scope discipline**: every reviewer dispatch declares
exactly what's under review, what's not, and what the reviewer does with stray
observations.

## The brief structure

Every dispatched reviewer receives a brief with EXACTLY these 5 sections, in
this order:

```
ARTIFACTS UNDER REVIEW:
  - (explicit file list, no wildcards beyond the artifact set)

CONTEXT:
  - (descriptive-only background — see §CONTEXT discipline below)

RUBRIC: <named rubric from a rubric catalog>
  (which rubric applies to each artifact, by category if mixed)

OUT OF SCOPE (do not grade against):
  - (explicit exclusions: adjacent artifacts, downstream phases, hypothetical uses)

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as rows with Status: OOS in the same ledger table. Record the
  routing destination (which upstream phase/skill the observation belongs to) in
  the Description/Evidence text. OOS rows do NOT count toward severity totals and
  do NOT affect the grade.

DELIVERABLES:
  - Findings ledger at `.aid/.temp/review-pending/<scope>.md` per
    `.codex/aid/templates/reviewer-ledger-schema.md`
  - Output format: ONE markdown table only, no headers/narrative
  - Severity tags MUST be bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR]
  - Status enum: Pending / Fixed / Recurred / Accepted / OOS / Invalid
  - For new findings this cycle: append rows with Status: Pending
  - For existing rows from prior cycles: update Status only (Fixed if resolved, Recurred if regressed)
  - Do NOT include severity tag-strings in narrative or summary text
    (qualitative summary goes in the agent return message, not the ledger file)
  - OOS observations: append as Status: OOS rows in the same ledger table, with
    the routing destination noted in Description/Evidence (they do not count
    toward the grade)
```

Each section is mandatory. Empty content is allowed (e.g.,
`OUT OF SCOPE: (none — universal review)`) but the section header must appear.

## Section-by-section

### ARTIFACTS UNDER REVIEW

An **explicit file list**. The reviewer reads + grades exactly these files. No
wildcards beyond the artifact set (e.g., `.codex/aid/templates/kb-authoring/*.md` is
fine if the entire directory is in scope; `canonical/**` is too broad).

**From cycle 2 this section carries TWO labelled lists, not one.** Cycle 1 and the final
full pass carry a single unlabelled list, unchanged.

```
ARTIFACTS UNDER REVIEW:
  VERIFY (full -- every existing ledger row is re-checked against these):
    - (every file named in a ledger row's Doc column; plus the whole cycle-1
       set if any row's Doc is `—`)
  HUNT (scoped -- look for NEW findings only here):
    - (what the previous FIX changed, plus the files that reference it)
```

The two exist because a cycle does two jobs and only one is expensive. Verifying a
`Pending` row is a targeted disk check and stays FULL — scoping it would break `Recurred`
detection. Hunting for new findings is what forced a full re-scan every cycle, and that is
the half that becomes scoped. The split, the derivation of each set, and the guards are
defined once in `reviewer-ledger-schema.md § Two sets from cycle 2`; this section carries
them, it does not redefine them.

A reviewer given two labelled lists must not hunt outside the HUNT list, and must not skip
any file in the VERIFY list.

The reviewer MUST NOT open any file not listed here, except to:
- Resolve a citation reference (e.g., a docfile cites `path/to/foo.sh:42` — the
  reviewer may open `foo.sh` to verify the citation but does not grade `foo.sh`)
- Look up a named rubric definition
- **Resolve a listed artifact's review criteria** — read the artifact's own
  frontmatter (`review-criteria:`) and the project's criteria tables
  (`.aid/knowledge/authoring-conventions.md`). The brief does **not** restate the
  criteria: the artifact declares them, and the reviewer reads the declaration.
  Copying them into the brief would put a stale second copy in every dispatch.

#### State files are never artifacts (the rule)

A state file — `STATE.md` (legacy) or `STATE.yml`, at any of the three levels
(work-root, `deliveries/delivery-NNN/`, or
`deliveries/delivery-NNN/tasks/task-NNN/`), in either the flattened or the full
layout — is **NEVER listed in `{{ARTIFACTS}}`**. State churn appearing in a
reviewed diff is not a finding, and — this is the half reviewers get wrong —
**it is not an OOS row either**: an OOS row is an observation *about an
artifact*, and a state file is not one; it is pipeline-written data, not
authored content, so there is nothing for an OOS row to observe.

Excluding state from being *read as an artifact* is not the same as excluding
it from being *written to*. The reviewer still writes its outcome (grade,
findings, Status) into state (A-3) — that write is a downstream effect of the
review, not a subject of it, and nothing here changes it.

#### `filter_reviewable_artifacts` — the filter

Modeled on the KB's own exclusion function, `list_reviewable` in
[`aid-discover/references/doc-set-resolve.md`](../../skills/aid-discover/references/doc-set-resolve.md)
(which keeps M3/M4 keystone-gate ingestion off `kb-category: meta` KB docs) —
same intent, applied to the work-tree instead of the KB, and defined here
rather than there because this exclusion is about the reviewable-artifact
surface a dispatch builds, not the KB's own doc-set. Reads candidate artifact
paths, one per line, on stdin; drops every state-file path and passes every
other path through unchanged.

```bash
# filter_reviewable_artifacts — reads candidate artifact paths (one per line)
# on stdin, drops every state-file path and echoes the rest, one per line.
# A state file is always named STATE.md (legacy) or STATE.yml, whether it
# sits at the work root, at deliveries/delivery-NNN/, or at
# deliveries/delivery-NNN/tasks/task-NNN/ — the basename alone identifies it
# at every level, in both the flattened and the full layout, so no directory
# pattern is needed. Authored artifacts (REQUIREMENTS.md, SPEC.md, PLAN.md,
# BLUEPRINT.md, tasks/task-NNN/DETAIL.md) never share that basename and pass
# through untouched.
#
# The `|| true` is load-bearing, not defensive habit: `grep -v` exits 1 when it
# emits no lines, so a change set consisting ONLY of state files -- the most
# common commit shape in this pipeline, since every `writeback-state.sh` write
# produces one -- would otherwise abort a caller running under `set -e`. The
# correct answer for that input is an empty artifact list and exit 0, not a
# failed dispatch.
filter_reviewable_artifacts() {
  grep -Ev '(^|/)STATE\.(md|yml)$' || true
}
```

Applied at the derivation point that `## Brief generation` (below) already
mandates; defined once, here, and referenced from there rather than restated.

The match is on basename, so it is repo-wide rather than work-tree-scoped. That
is deliberate: no authored artifact anywhere is named `STATE.md`/`STATE.yml`, so
there is no path this can drop by mistake. It does also match the discovery-area
ledger `.aid/knowledge/STATE.md`, which is harmless — that path is never a
member of a work-tree artifact list in the first place, and its exclusion
remains **owned** by `list_reviewable` in `doc-set-resolve.md`. This filter does
not take that ownership over, and a test for this filter must not assert
anything about the KB ledger.

### CONTEXT

**Descriptive background only.** Tells the reviewer what the artifact IS and what
methodology framework it fits into. Does NOT tell the reviewer what downstream
consumers do with it or what other artifacts exist.

#### CONTEXT discipline (the rule)

> CONTEXT describes what the artifact IS. Does NOT describe what downstream
> consumers do with it. Does NOT name specific projects, files, or counts outside
> the ARTIFACTS list.

#### Examples — good vs bad CONTEXT

**Good CONTEXT:**
> "These are spec docs for a Knowledge Base authoring discipline. They define
> principles + a tier model + a frontmatter schema + a review rubric. The
> docs are intended to be internally consistent and unambiguous."

Why good: describes the artifact's purpose (authoring discipline spec), its
intended quality (internally consistent, unambiguous). No downstream
references. No external counts. No project-specific facts.

**Bad CONTEXT (avoid):**
> "Phase B (skill updates) and Phase C (21-doc migration) will depend on this
> spec being correct. The 21 docs include this repo's KB extensions plus..."

Why bad: drags Phase B and Phase C into the review scope; specifies the
dogfood project's 21-doc count; reviewer will now grade for fitness against
those downstream consumers rather than the artifact itself.

#### Reviewer self-check (the enforcement)

The brief MUST include this instruction near the end of CONTEXT:

> **Reviewer self-check:** If you find CONTEXT contains scope-expanding
> language (downstream phase references, specific project counts, hypothetical
> future uses), flag it and bound your review to the ARTIFACTS list only.

If the reviewer detects CONTEXT leak, it flags the leak as an OOS observation
about the brief itself, then proceeds with the narrow ARTIFACTS-only scope.

### RUBRIC

A **named rubric** drawn from a rubric catalog. Examples:

- `kb-authoring/review-rubric.md#full-primary` — for hand-authored KB primary docs
- `kb-authoring/review-rubric.md#spot-check-snapshot` — for KB meta docs
- `kb-authoring/review-rubric.md#build-verify-only` — for generated docs
- (future) `code-review-rubric.md#standard` — for code task review
- (future) `spec-review-rubric.md#standard` — for spec review

If multiple artifacts use different rubrics, the brief maps each to its rubric:

```
RUBRIC:
  .codex/aid/templates/kb-authoring/*.md   → kb-authoring/review-rubric.md#full-primary
  .codex/aid/scripts/*.sh        → (none — script bugs / shell correctness)
```

When no pre-defined rubric exists (one-off reviews like Phase A foundation),
the brief enumerates the checks inline.

**On a scoped cycle the criteria resolve against the scoped surface.** Criteria resolution
is scope-free by construction — a file's resolved list depends only on its path and
frontmatter, never on its content — so the list for a section IS the list for its file, and
scoping the hunt needs no change to resolution. What changes is only WHICH files the
reviewer resolves criteria for on that cycle: the VERIFY set in full, and the HUNT set for
new findings.

**A named rubric does not replace the artifact's declared criteria — the two compose.**
The rubric says how to review a *class* of artifact; the criteria say what *this* file
must be true against, resolved global → type → file per
`kb-authoring/review-rubric.md § Resolving review criteria`. Every finding cites the
criterion `id` it violates as a prefix in the ledger's `Description` cell, so the brief
never needs a `Rule` column and the ledger keeps its 7-column shape.

### The cross-document contradiction pass (Guard 2)

**Run on CYCLE 1 of any review whose `ARTIFACTS` span more than one artifact.** A review of
a single artifact does not run it and does not need to.

Pinning it to cycle 1 makes it once-per-phase **by construction**: cycle 1 is the full-read
cycle that happens anyway, and a multi-artifact review happens once per phase. No
"is this the last one?" detection is needed, and none should be invented.

Three reviews already receive every artifact of a phase at once, and they are its
invocation sites:

| Review | Already receives | Covers |
|---|---|---|
| `aid-define` CROSS-REFERENCE | `REQUIREMENTS.md` + every feature `SPEC.md` | Define's own output |
| `aid-plan` | full `PLAN.md` + **every** `feature-*/SPEC.md` | Specify's per-feature specs |
| `aid-detail` | every `task-NNN/DETAIL.md` + `PLAN.md` | Detail's task set |

**`aid-specify` deliberately gets no invocation.** It dispatches a reviewer PER artifact, so
no single specify review could see a contradiction spanning two features; its specs are
cross-checked at `aid-plan`'s review, the first review after Specify that sees them
together. Adding one there would run the pass once per feature, which is the opposite of
once per phase.

What the pass looks for is unchanged — two artifacts asserting different values for one
shared fact. Only its cadence moves. It gets *better* rather than merely cheaper: a
contradiction between siblings is invisible to a gate that only ever reads one of them.

**The residual window, stated:** a contradiction introduced by the pass's own fix is not
re-checked by that pass, because the pass is pinned to cycle 1 and the fix lands after it.
The final full pass before approval is the backstop. Re-running the pass every cycle until
fixpoint would rebuild the per-cycle loop this change exists to remove.

### OUT OF SCOPE

An **explicit exclusion list**. Things the reviewer must NOT consider when
grading. Common entries:

- "Downstream phases (Phase B, Phase C, etc.)"
- "Adjacent artifacts not in the ARTIFACTS list"
- "Dogfood-specific facts (this project's KB count, `.claude/` contents)"
- "Hypothetical future uses"
- "Profile mirrors auto-regenerated from canonical (`profiles/*/`)"

The brief author writes the exclusion list explicitly. Defaults for common
review types live in per-skill brief templates (see §Brief generation).

### OUT-OF-SCOPE FINDINGS POLICY

**Always identical across all dispatches** (do not customize per dispatch):

> Reviewer logs OOS findings as rows with Status: OOS in the same ledger table.
> Each OOS row names its routing destination (the upstream phase/skill the
> observation belongs to) in the Description/Evidence text. OOS rows do NOT count
> toward severity totals or the grade. The user (or skill orchestrator) reads
> the Status: OOS rows and decides downstream what to do with them.

OOS rows preserve the reviewer's insight without biasing the canonical grade.
Having no OOS rows is normal and signals "reviewer found nothing worth flagging
outside scope".

### DELIVERABLES

The expected output. Always:

- **Ledger format** per [kb-authoring/principles.md](kb-authoring/principles.md)
  P3 — temp-file ledger pattern at `.aid/.temp/review-pending/<dispatcher>.md`
- **Severity scale** per the named RUBRIC (or inline if no rubric)
- **Grade** computed per `.codex/aid/templates/grading-rubric.md`
- **OOS rows** (Status: OOS, with routing destination) as defined in OOS POLICY above

## Brief generation

Each skill that dispatches a reviewer ships a brief template at
`.codex/skills/<skill>/references/reviewer-brief.md`. Six per-skill briefs
are shipped: `aid-discover`, `aid-execute`, `aid-specify`, `aid-plan`,
`aid-detail`, `aid-define`. Each renders this protocol's 5-section structure
with skill-specific RUBRIC + OUT OF SCOPE; the consumer state file fills the
dynamic slots and dispatches.

The template is HYBRID — fixed structure with two dynamic slots:

| Section | Static or dynamic |
|---------|-------------------|
| ARTIFACTS UNDER REVIEW | **Dynamic** — filled at dispatch time from current state |
| CONTEXT | **Dynamic** — filled per dispatch with current cycle info, subject to CONTEXT discipline |
| RUBRIC | **Static per skill** — same rubric every dispatch |
| OUT OF SCOPE | **Static per skill** — same exclusions every dispatch |
| OOS POLICY | **Static** — identical across all skills, this protocol |
| DELIVERABLES | **Static per skill** — same expected outputs |

Substitution mechanism: the brief template uses `{{ARTIFACTS}}` and
`{{CONTEXT}}` placeholders (some briefs also use `{{MODE}}` or `{{SCOPE}}`).
Skill renders them at dispatch time (bash heredoc, small render helper, or
inline string substitution).

**Deriving `{{ARTIFACTS}}` — always from disk, never from memory.** For
PR-level reviews, derive from
`git diff --name-only <base>..HEAD | filter_reviewable_artifacts`, then
filtered by the OUT-OF-SCOPE list. For per-task/per-delivery reviews, derive
from the executor's produced-file list, piped through the same
`filter_reviewable_artifacts` (`§ARTIFACTS UNDER REVIEW` above — defined
once, applied here). Building the list from memory of what was worked on
tends to omit incidentally-touched files; the reviewer then can't grade what
it doesn't know about.

**Inspectability requirement:** the rendered brief is logged with the dispatch
record so it can be inspected after the fact (per work-003 traceability).

## One-off reviews

When a skill is being authored or revised and no per-skill brief template
exists yet (or when a one-time review is needed for non-recurring work),
the brief is **hand-crafted** following this protocol's 5-section structure.
The protocol applies; only the template-substitution mechanism is skipped.

## Worked example — Phase A foundation re-review brief

(Hand-crafted, one-off; no per-skill template applies)

```
ARTIFACTS UNDER REVIEW:
  - .codex/aid/templates/kb-authoring/README.md
  - .codex/aid/templates/kb-authoring/principles.md
  - .codex/aid/templates/kb-authoring/tier-model.md
  - .codex/aid/templates/kb-authoring/frontmatter-schema.md
  - .codex/aid/templates/kb-authoring/review-rubric.md
  - .codex/aid/templates/reviewer-dispatch.md  (this doc, newly authored)
  - .codex/aid/templates/generated-files.txt
  - .codex/aid/scripts/kb/build-metrics.sh
  - .codex/aid/scripts/kb/build-kb-index.sh
  - .codex/aid/templates/knowledge-base/*.md  (17 templates with prepended frontmatter)

CONTEXT:
  These are canonical artifacts that define a KB Authoring discipline. They
  comprise principles, a fact-stability tier model, a YAML frontmatter schema,
  per-category review rubrics, and a universal reviewer dispatch protocol.
  Tooling (build scripts + extended lint) implements the discipline.

  These artifacts are intended to be internally consistent, unambiguous, and
  technically correct as STANDALONE canonical artifacts.

  Reviewer self-check: If you find CONTEXT contains scope-expanding language
  (downstream phase references, specific project counts, hypothetical future
  uses, adjacent artifacts not listed in ARTIFACTS), flag it and bound your
  review to the ARTIFACTS list only.

RUBRIC: (one-off — no pre-defined rubric for canonical-spec review yet)
  Apply these checks:
  - Spec docs: internal consistency, ambiguity, missing edge cases, cross-doc
    contradictions, broken cross-references
  - Scripts: bash correctness, set -e safety, cross-platform portability (macOS/Linux),
    argument handling, idempotency, error paths
  - Templates: YAML frontmatter validity, schema compliance, intent: text quality

OUT OF SCOPE (do not grade against):
  - Downstream phases (any "Phase B" or "Phase C" work)
  - The dogfood project's .aid/ KB or .claude/ install in this repo
  - Profile mirrors at profiles/{claude-code,codex,cursor}/ (regenerated from canonical)
  - Adjacent canonical files not in ARTIFACTS
  - Hypothetical future skill uses or adopter-project specifics
  - Adopter-specific KB document counts, naming, or extensions

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger table, naming the
  routing destination in Description/Evidence. Exclude from severity totals
  and grade.

DELIVERABLES:
  - Write findings to: .aid/.temp/review-pending/phase-a-foundation-v2.md
  - Format: per .codex/aid/templates/reviewer-ledger-schema.md (ONE markdown table only)
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR]
  - Status enum: Pending / Fixed / Recurred / Accepted / OOS / Invalid
  - Grade computed by orchestrator via: grade.sh .aid/.temp/review-pending/phase-a-foundation-v2.md
  - OOS observations: Status: OOS rows in the same ledger table (with routing destination)
```

## When this protocol changes

This doc is normative for all reviewer dispatches. Changes affect every skill.
Revisions should:

1. Update the changelog entry below (see §Bootstrap exemption for how this doc tracks history)
2. Update per-skill `reviewer-brief.md` templates to reflect any new fixed sections
3. Be announced via a single deliberate revision PR, not folded into other work

## Bootstrap exemption

This doc lives in `.codex/aid/templates/` and is a **skill-bundle artifact**, not a KB
document. The frontmatter schema defined in `kb-authoring/frontmatter-schema.md` applies
to `.aid/knowledge/*.md` (KB docs in adopter projects), NOT to canonical skill-bundle
docs. Therefore this doc carries no `kb-category:`/`source:` frontmatter.

For changes to this doc, append a dated line at the bottom of this section:

- 2026-05-26: Initial authoring (Phase A KB Authoring overhaul)
- 2026-05-27: Phase B landed 6 per-skill `reviewer-brief.md` templates
  (aid-discover, aid-execute, aid-specify, aid-plan, aid-detail,
  aid-describe, aid-define); removed the "not yet implemented" parenthetical;
  documented the rendering convention; added "derive ARTIFACTS from
  disk, not memory" rule (closes F10, F22, F26 from PR #15 review)

## See also

- `.codex/aid/templates/self-review-protocol.md` — the flip side of this protocol
  (what every artifact-producing agent should have done BEFORE this dispatch
  was needed; the reviewer's role is verification, not discovery)
- `.codex/aid/templates/kb-authoring/principles.md` — P3 temp-ledger pattern
- `.codex/aid/templates/kb-authoring/review-rubric.md` — KB review rubric definitions
- `.codex/aid/templates/grading-rubric.md` — severity → grade computation
- `.codex/aid/templates/long-wait-protocol.md` — heartbeat / L2 timer dispatch protocol
- `.codex/agents/aid-reviewer/` — the reviewer agent definition

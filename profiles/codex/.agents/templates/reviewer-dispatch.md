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
  Log to `## Out-of-Scope Observations` in the ledger. Do NOT include in severity
  counts. Do NOT affect the grade.

DELIVERABLES:
  - Findings format: per `.agents/templates/kb-authoring/principles.md` P3 temp-ledger
  - Severity scale: per the named RUBRIC
  - Grade: computed per `.agents/templates/grading-rubric.md` (OOS observations excluded)
```

Each section is mandatory. Empty content is allowed (e.g.,
`OUT OF SCOPE: (none — universal review)`) but the section header must appear.

## Section-by-section

### ARTIFACTS UNDER REVIEW

An **explicit file list**. The reviewer reads + grades exactly these files. No
wildcards beyond the artifact set (e.g., `.agents/templates/kb-authoring/*.md` is
fine if the entire directory is in scope; `canonical/**` is too broad).

The reviewer MUST NOT open any file not listed here, except to:
- Resolve a citation reference (e.g., a docfile cites `path/to/foo.sh:42` — the
  reviewer may open `foo.sh` to verify the citation but does not grade `foo.sh`)
- Look up a named rubric definition

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
  .agents/templates/kb-authoring/*.md   → kb-authoring/review-rubric.md#full-primary
  .agents/scripts/*.sh        → (none — script bugs / shell correctness)
```

When no pre-defined rubric exists (one-off reviews like Phase A foundation),
the brief enumerates the checks inline.

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

> Reviewer logs OOS findings to `## Out-of-Scope Observations` in the ledger.
> They do NOT count toward severity totals or the grade. Human (or skill
> orchestrator) decides downstream what to do with them.

OOS observations preserve the reviewer's insight without biasing the canonical
grade. An empty OOS section is normal and signals "reviewer found nothing
worth flagging outside scope".

### DELIVERABLES

The expected output. Always:

- **Ledger format** per [kb-authoring/principles.md](kb-authoring/principles.md)
  P3 — temp-file ledger pattern at `.aid/.temp/review-pending/<dispatcher>.md`
- **Severity scale** per the named RUBRIC (or inline if no rubric)
- **Grade** computed per `.agents/templates/grading-rubric.md`
- **OOS section** as defined in OOS POLICY above

## Brief generation

Each skill that dispatches a reviewer ships a brief template at
`.agents/skills/<skill>/references/reviewer-brief.md`. Six per-skill briefs
are shipped: `aid-discover`, `aid-execute`, `aid-specify`, `aid-plan`,
`aid-detail`, `aid-interview`. Each renders this protocol's 5-section structure
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
PR-level reviews, derive from `git diff --name-only <base>..HEAD` filtered
by the OUT-OF-SCOPE list. For per-task/per-delivery reviews, derive from
the executor's produced-file list. Building the list from memory of what
was worked on tends to omit incidentally-touched files; the reviewer then
can't grade what it doesn't know about.

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
  - .agents/templates/kb-authoring/README.md
  - .agents/templates/kb-authoring/principles.md
  - .agents/templates/kb-authoring/tier-model.md
  - .agents/templates/kb-authoring/frontmatter-schema.md
  - .agents/templates/kb-authoring/review-rubric.md
  - .agents/templates/reviewer-dispatch.md  (this doc, newly authored)
  - .agents/templates/generated-files.txt
  - .agents/scripts/kb/build-metrics.sh
  - .agents/scripts/kb/build-index.sh
  - .agents/scripts/kb/verify-claims.sh  (NEW SECTIONS ONLY — see PART 0 onward)
  - .agents/templates/knowledge-base/*.md  (17 templates with prepended frontmatter)

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
  Log to `## Out-of-Scope Observations` section. Exclude from severity totals
  and grade.

DELIVERABLES:
  - Write findings to: .aid/.temp/review-pending/phase-a-foundation-v2.md
  - Format: per .agents/templates/kb-authoring/principles.md P3 temp-ledger
  - Severity: CRITICAL / HIGH / MEDIUM / LOW / MINOR (worst-issue dominates)
  - Grade: computed; INCLUDE explicit "OOS observations excluded" note in summary
```

## When this protocol changes

This doc is normative for all reviewer dispatches. Changes affect every skill.
Revisions should:

1. Update the changelog entry below (see §Bootstrap exemption for how this doc tracks history)
2. Update per-skill `reviewer-brief.md` templates to reflect any new fixed sections
3. Be announced via a single deliberate revision PR, not folded into other work

## Bootstrap exemption

This doc lives in `.agents/templates/` and is a **skill-bundle artifact**, not a KB
document. The frontmatter schema defined in `kb-authoring/frontmatter-schema.md` applies
to `.aid/knowledge/*.md` (KB docs in adopter projects), NOT to canonical skill-bundle
docs. Therefore this doc carries no `kb-category:`/`source:` frontmatter.

For changes to this doc, append a dated line at the bottom of this section:

- 2026-05-26: Initial authoring (Phase A KB Authoring overhaul)
- 2026-05-27: Phase B landed 6 per-skill `reviewer-brief.md` templates
  (aid-discover, aid-execute, aid-specify, aid-plan, aid-detail,
  aid-interview); removed the "not yet implemented" parenthetical;
  documented the rendering convention; added "derive ARTIFACTS from
  disk, not memory" rule (closes F10, F22, F26 from PR #15 review)

## See also

- `.agents/templates/self-review-protocol.md` — the flip side of this protocol
  (what every artifact-producing agent should have done BEFORE this dispatch
  was needed; the reviewer's role is verification, not discovery)
- `.agents/templates/kb-authoring/principles.md` — P3 temp-ledger pattern
- `.agents/templates/kb-authoring/review-rubric.md` — KB review rubric definitions
- `.agents/templates/grading-rubric.md` — severity → grade computation
- `.agents/templates/long-wait-protocol.md` — heartbeat / L2 timer dispatch protocol
- `.agents/agents/reviewer/` — the reviewer agent definition

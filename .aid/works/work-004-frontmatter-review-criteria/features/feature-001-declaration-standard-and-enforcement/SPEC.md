# Declaration Standard and Enforcement

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Feature identified from REQUIREMENTS.md §4 stream 1, §5 FR-2..FR-6 | /aid-define |
| 2026-08-13 | Second cross-reference pass: FR-9/FR-10 added to Source; the override-surfacing contradiction resolved to the ledger's `Evidence` cell (owner decision); `severity:` block and `contracts:` name corrected; level-1 scope restated as re-authoring | /aid-define |

## Source

- REQUIREMENTS.md §4 (In Scope, stream 1), §5 FR-2, FR-3, FR-4, FR-5, FR-6, **FR-9, FR-10**
- REQUIREMENTS.md §6 NFR-1, NFR-3; §7 C-1, C-3, C-6, C-7; §9 AC-2

*FR-5 is defined here and applied by feature-002 — this feature owns it. NFR-5 is an authoring
constraint on the declarations themselves and is carried by feature-002, not here.*

*FR-9 and FR-10 are **global instructions in `agent-boilerplate.md` and the five profile context
files**, and they are stream-1 surfaces, so they are owned here. An earlier draft omitted both from
this block while carrying acceptance criteria for them — the criteria traced to nothing.*

**Surfacing a severity override IS an acceptance criterion here** *(owner decision, 2026-08-13)*.
An earlier draft of this block declared it deliberately excluded, calling it "parked as an open cost"
while this SPEC's own acceptance list required it — the same requirement both gated and disowned in
one document. REQUIREMENTS.md FR-6 now settles where it lands: the reviewer writes the resolved
severity and the overriding file's `why` into the finding's **`Evidence` cell**. That is not a gate-
output change, `grade.sh` is untouched, and no mechanism is added — so the criterion and this feature's
no-new-mechanism rule hold together.

## Description

Today a file can state what it must be true against, and something will check it — but only if the
file is a Knowledge Base document. The check exists at
`canonical/aid/templates/kb-authoring/review-rubric.md` item 3, the field's schema exists at
`kb-authoring/frontmatter-schema.md`, and together they reach **19 of 315** in-scope files — item 3
sits inside the rubric's `## Rubric: Full Primary (hand-authored)` section, and the routing table
above it sends the three `kb-category: meta` docs to Spot-Check or Build-Verify instead, so they are
not reached either. *(An earlier draft said 22, counting the whole KB tree.)* Nothing tells a reviewer
to look at a skill's, an agent's or a template's frontmatter at all.

This feature builds the criteria system and makes the review process use it. Four moves:

1. **Build the criteria lists in `.aid/knowledge/authoring-conventions.md` — the largest piece, and
   the one that does the real work.** Two new sections, kept together: level 1 (global criteria and
   exclusions) and level 2 (per-document-type criteria and exclusions, each criterion carrying its own
   severity). Level 2 needs the document types enumerated so every in-scope file resolves to exactly
   one. A criterion written once at type level covers every file of that type, which is what keeps most
   of the 290 files' frontmatter empty.

   **Level 1 is a re-authoring, not a restructure.** An earlier draft called it "mostly restructuring,
   not authoring from nothing", pointing at `## Drift-Prone Content is Banned`,
   `## Citation Rule (Durable Anchors)` and `## Resolved Items Leave No Trace`. The first of those opens
   *"Four content classes are banned from **primary docs**"* — scoped to `kb-category: primary` KB
   documents, of which **13 are hand-authored**, against 290 in-scope files. Every such rule has to be
   re-argued at the wider scope and given a severity that holds for a skill reference and a template as
   well as a KB doc. Those sections are the raw material and the precedent; they are not the level-1
   list in a different shape, and estimating this as a restructure understates it.

   *Placement rationale:* the concern spine puts `authoring-conventions.md` at **C3 — conventions
   and standards**, which is what criteria are; `quality-gates.md` is **C6 — how quality is
   checked**, and keeps the grade scale, the ledger and the thresholds. Criteria and their cost in
   C3, scoring in C6, cross-referenced and never duplicated.
2. **Widen the field, and rename it.** One uniform **`review-criteria:`** for skills, agents,
   templates and KB docs alike, carrying **positive criteria and exclusions**, each entry holding its
   own `severity`. No per-artifact-kind schema, and **no separate `severity:` block** — FR-6 withdrew
   that as a second surface that could drift out of step with the first, so a draft naming it here was
   scheduling a deliverable the requirements had already retired.
3. **Name the criteria, and cite them in findings without touching the ledger.** Every criterion
   carries a greppable `id`; a finding names it as a prefix inside its existing `Description` cell.
   The ledger keeps its 7 columns and `grade.sh` keeps its positional parse — no `Rule` column is
   added, and none is needed.
4. **Put the criteria in front of every agent that writes — not just the reviewer.** Two edits, not
   one: `canonical/aid/templates/agent-boilerplate.md`, which every `AGENT.md` includes and which
   therefore reaches every **dispatched sub-agent**; and the **five hand-authored
   `profiles/<tool>/{CLAUDE,AGENTS}.md`**, which is what the session's own agent reads. Both say the
   same thing: resolve a file's criteria before writing or editing it, and update the KB's registry when
   a document type is introduced or retired. The reviewer then verifies compliance against the same
   list, resolving global → type → file, validating against the union with the most specific winning.

   *The repo-root `CLAUDE.md` is **not** an edit target — it is install output written by
   `lib/aid-install-core.sh` → `_copy_root_agent_file` from those five sources, so editing it would be
   overwritten on the next install (FR-9).*

Then the surfaces that run a review are told to read the declaration: the reviewer agent, the
dispatch template, the ledger schema, the six per-skill briefs — and the FIX contract, so a fixer
re-checks a file's own declaration after editing that file.

## User Stories

- As an AID user, I want a review to check what each file claims about itself, so that a document
  quietly going stale is caught by the ordinary review instead of by whoever trips over it later.
- As an AID user, I want one way to declare that criterion across every kind of file, so that
  learning it once is enough and there is no per-directory dialect to keep straight.
- As an AID user, I want a stale count and a false claim in a routing document to be scored
  differently, so that severity reflects what a mistake actually costs where it happens.
- As an AID user, I want a fixer to re-check the file it just edited against that file's own
  declaration, so that a repair does not leave the document contradicting itself.

## Priority

Must

## Acceptance Criteria

- [ ] Given `.aid/knowledge/authoring-conventions.md`, when this feature completes, then it carries a
      **global criteria list** and a **per-document-type criteria list** for every document type in
      the project, in two sections kept together, each criterion carrying its own severity — and every
      in-scope file resolves to **exactly one** type, with none untyped.
- [ ] Given a type whose members cannot all carry a file-level block, when the registry is written,
      then that type is **split**, symmetrically for every such type: `skill-generated` (**58**, one per
      `shortcut-catalog.yml` row) / `skill-authored` (**18**), and `template-payload` /
      `template-own`. Splitting `template` while leaving `skill` whole is a finding, not a completion —
      it would let a reviewer fault 58 files for a block they cannot keep.
- [ ] Given `quality-gates.md`, when this feature completes, then it still holds the grade scale, the
      ledger and the thresholds, and **no criterion or per-type severity is duplicated** between it
      and `authoring-conventions.md` — the two cross-reference instead.
- [ ] Given a criterion, when it is written, then it sits at the **highest level where it is true**,
      and no type-level list restates a global one.
- [ ] Given something that must never be validated, when it is recorded, then it is an **exclusion in
      `review-criteria:`** carrying its reason — not an omission, and not a severity of zero.
- [ ] Given the `rendered` exclusion, when it is authored, then it is keyed on **provenance** and has
      **both limbs**: (a) the file appears as a `dst` in an emission manifest, or (b) it sits under
      `profiles/<tool>/` **and has a corresponding `canonical/` source**. Limb (a) alone reaches
      **0 of the 1,376** markdown files under `profiles/` — no manifest carries a `profiles/` `dst`.
      Neither limb may be written as a bare path glob: authored repo-local content under a dogfood tree
      (`skills/generate-profile/**`, `skills/release-aid/**`, `output-styles/**`) and the five
      hand-authored `profiles/<tool>/{CLAUDE,AGENTS}.md` all stay reviewable.
- [ ] Given `render.py`, when an `AGENT.md` carries `review-criteria:`, then the key survives into
      the rendered agent file rather than being silently discarded — verified in `profiles/` after
      the single end-of-work render.
- [ ] Given a reviewer validating any file, when it resolves criteria, then it reads **all three
      levels** and validates against their union, most specific winning on conflict.
- [ ] Given **any agent that writes or edits an in-scope file**, when it begins, then
      `agent-boilerplate.md` instructs it to resolve that file's criteria first and comply — the
      instruction is global, not carried per skill and not scoped to `aid-reviewer` (FR-9).
- [ ] Given a work that introduces or retires a document type, when it completes, then the KB's type
      registry gained or lost its row, and `authoring-conventions.md` carries the backstop criterion
      that **every in-scope file resolves to exactly one registry row** (FR-10).
- [ ] Given a file that overrides a higher-level criterion, when a finding is written against that
      criterion, then the reviewer records the **resolved severity and the overriding file's `why` in
      the finding's `Evidence` cell**, and `why` being absent from the declaration is a schema error
      (FR-6). The override reuses the higher-level `id` and the same five fields — it introduces no
      new object shape. `grade.sh` is not modified, and no validator is added.
- [ ] Given any in-scope authored markdown file, when a reviewer resolves criteria for it, then the
      `review-criteria:` field is defined for that file's tree — not for `.aid/knowledge/` alone — and
      the field no longer appears in `frontmatter-schema.md`'s "stay fully exempt" legacy list, with
      `intent:` and `changelog:` keeping their treatment.
- [ ] Given a finding derived from a criterion, when it is written to a ledger, then its
      `Description` opens with the criterion `id`, that id **resolves** — in
      `authoring-conventions.md` for a scope-prefixed id, or in the file named in `Doc` for an `F-`
      id — and the ledger is still **exactly 7 columns**, with `grade.sh` unmodified.
- [ ] Given a finding citing no id, or an id that resolves nowhere, when the ledger is read, then
      that finding is itself treated as a defect — the reviewer invented a criterion.
- [ ] Given a criterion violation, when severity is assigned, then it resolves **global → document
      type → file**, with the most specific declaration winning and absence inheriting upward. *(One
      vocabulary throughout: FR-5's "type", not the "file-class" an earlier draft of this line used.)*
- [ ] Given the three independent severity definitions on disk — `grading-rubric.md § Issue
      Severities`, `reviewer-ledger-schema.md § Severity values`, and `aid-reviewer/AGENT.md §
      Severity Classification` — when this feature completes, then they are reconciled to one
      authority that the other two cite, rather than a fourth being added beside them.
- [ ] Given a review dispatch, when the reviewer receives its brief, then the brief directs it to
      read the artifact's own frontmatter — verified in `canonical/`, the source of truth. *(An
      earlier draft required this "evidenced in the rendered brief", which cannot be met here: C-2
      and NFR-4 defer every render to feature-003.)*
- [ ] Given a fixer that has just edited a file, when it completes the edit, then the FIX contract
      requires re-verifying that file's own declaration before the row is addressed.
- [ ] Given a review surface that needs criteria, when it states them, then it routes to the
      declaration rather than restating its content (FR-4).
- [ ] **Proof (AC-2, method per NFR-1):** given a planted contradiction between a file's body and
      its own `review-criteria:` entry, applied in a disposable worktree and never on this branch, when
      a real review runs, then the finding returns citing that criterion's `id`. Until this passes, the
      feature is not done — an instruction that exists and goes unread is the failure being fixed.
- [ ] Given C-1, when this feature is complete, then it has added no linter, validator, schema-as-code
      or CI check. The declaration is prose the reviewer reads.
- [ ] Given NFR-3, when this feature edits a file `work-003` also modifies, then the edit is additive
      and localized — a new section, paragraph or row — never a restructure.

---

## Technical Specification

*(Added by /aid-specify — do not fill during interview.)*

# Declaration Standard and Enforcement

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Feature identified from REQUIREMENTS.md §4 stream 1, §5 FR-2..FR-6 | /aid-define |

## Source

- REQUIREMENTS.md §4 (In Scope, stream 1), §5 FR-2, FR-3, FR-4, FR-5, FR-6
- REQUIREMENTS.md §6 NFR-1, NFR-3; §7 C-1, C-3, C-6, C-7; §9 AC-2

*FR-5 is defined here and applied by feature-002 — this feature owns it. NFR-5 is an authoring
constraint on the declarations themselves and is carried by feature-002, not here.*

*Deliberately **not** an acceptance criterion: surfacing a level-3 severity override in the gate
output. REQUIREMENTS.md FR-6 parks that as an "open cost, carried forward", and satisfying it would
mean changing gate output — new mechanism, which this feature's own criteria forbid. It stays parked
rather than being promoted to a gate by a SPEC that was never given the authority to promote it.*

## Description

Today a file can state what it must be true against, and something will check it — but only if the
file is a Knowledge Base document. The check exists at
`canonical/aid/templates/kb-authoring/review-rubric.md` item 3, the field's schema exists at
`kb-authoring/frontmatter-schema.md`, and together they reach **22 of 315** in-scope files. Nothing
tells a reviewer to look at a skill's, an agent's or a template's frontmatter at all.

This feature makes that one check the standard for every authored markdown file in AID, and makes
the review process actually use it. Three moves:

1. **Widen the field.** One uniform `contracts:` field — free-text assertions the reviewer derives
   from disk and compares — defined for skills, agents, templates and KB docs alike. No
   per-artifact-kind schema.
2. **Name the rule.** The contracts check gains a citable rule ID so a finding can name it in a
   ledger's `Rule` column. An unnamed check produces findings with nothing to cite, which is a large
   part of why it was invoked once in 47 findings.
3. **Say what a violation costs.** Severity resolves through a three-level cascade — global, then
   file-class, then the file's own frontmatter as an override. Levels 1 and 2 extend
   `grading-rubric.md`, which already ships; there is no second severity home.

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

- [ ] Given any in-scope authored markdown file, when a reviewer resolves criteria for it, then the
      `contracts:` field is defined for that file's tree — not for `.aid/knowledge/` alone.
- [ ] Given a finding derived from the contracts check, when it is written to a ledger, then it
      carries a rule ID that resolves to the check, and the `Rule` column is not blank or invented.
- [ ] Given a contract violation, when severity is assigned, then it resolves global → file-class →
      file-specific, with the most specific declaration winning and absence inheriting upward.
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
      its own `contracts:` line, applied in a disposable worktree and never on this branch, when a
      real review runs, then the finding returns citing that contract. Until this passes, the
      feature is not done — an instruction that exists and goes unread is the failure being fixed.
- [ ] Given C-1, when this feature is complete, then it has added no linter, validator, schema-as-code
      or CI check. The declaration is prose the reviewer reads.
- [ ] Given NFR-3, when this feature edits a file `work-003` also modifies, then the edit is additive
      and localized — a new section, paragraph or row — never a restructure.

---

## Technical Specification

*(Added by /aid-specify — do not fill during interview.)*

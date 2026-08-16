# Coverage Gate Completion

## Source

- REQUIREMENTS.md §4 Scope — T2 Gaps
- REQUIREMENTS.md §5 Functional Requirements — FR-B1 … FR-B7
- REQUIREMENTS.md §6 Non-Functional Requirements — NFR-1 … NFR-4
- REQUIREMENTS.md §7 Constraints
- REQUIREMENTS.md §9 Acceptance Criteria — AC-3, AC-5, AC-7, AC-11, AC-12
- REQUIREMENTS.md §10 Priority — item 2

## Description

Once the review stack is single, the question becomes what it still does not look at.
Six things are unwatched today, and each is a place where a defect can ship without
anything firing.

The project's own settings file has no check that runs on its own — it is read by every
skill and validated by none. A frontmatter linter exists but nothing proves it is
actually wired into a runtime gate, so it may be passing because it never runs. The
generated Knowledge Base tour, `kb.html`, is checked only for having been built; nothing
reads what it says. Delivery blueprints and specify reviews are not on the standard
ledger and grading path. Citation and quote accuracy is checked for Knowledge Base docs
but not for the artifacts a work produces. And a second grading backend still coexists
with the one that produces the letter grade.

The seventh item removes a finding class rather than watching it. A hand-maintained
history table inside a document drifts from git the moment one edit skips a row, and
reviewers then spend cycles on the drift instead of on the artifact. This feature keeps
the rule enforced and makes sure no template, skill, or fixture authors such a section.

Every gate here has to prove it fires. A gate that passes because it never runs is worse
than no gate, so each ships with a fixture that fails before the change and passes
after, or a before-and-after measurement.

## User Stories

- As a maintainer, I want `.aid/settings.yml` checked by a script that passes or fails on its own, so that a malformed settings file is caught before a skill reads it.
- As a maintainer, I want proof that the frontmatter linter actually runs in a gate, so that a clean result means "checked" rather than "not looked at".
- As the owner, I want someone to read what `kb.html` actually says, so that a Knowledge Base tour that builds successfully but reads wrongly does not ship.
- As a pipeline skill, I want blueprint and specify reviews on the same 7-column ledger and `grade.sh` path as every other review, so that one grading contract covers every phase.
- As the reviewer agent, I want citation and quote accuracy checked on work artifacts too, not only Knowledge Base docs, so that a misquoted requirement is a finding wherever it appears.
- As the owner, I want one backend producing the letter grade, so that two paths cannot report two different grades for the same work.
- As a maintainer, I want no artifact to carry its own history section, so that reviewers stop spending cycles on drift that git already records correctly.

## Priority

Must

## Acceptance Criteria

> Each criterion carries the modality of the requirement it discharges. FR-B6 is SHOULD
> in §5 and its criterion stays SHOULD here.

- [ ] **MUST** — Given each of the five gates this feature adds or wires (the mechanical settings gate, the wired frontmatter lint, the `kb.html` content review, BLUEPRINT and specify **per-section** review on the 7-column + `grade.sh` path, and citation/quote checks covering work artifacts), when the gate is exercised, then a fixture fails before the change and passes after, or a before/after measurement shows the gate firing. *(discharges FR-B1, FR-B2, FR-B3, FR-B4, FR-B5; §9 AC-3)*

  > **Q6 is open and this criterion does not pre-empt it.** FR-B4 says "specify
  > per-section review", and nothing named `per-section` exists in `canonical/` today,
  > while the specify per-FEATURE review is already on the `grade.sh` path
  > (`canonical/skills/aid-specify/references/state-review.md`). The wording above is
  > FR-B4's, unchanged. Whether "per-section" is narrowed away or defined is the owner's
  > answer to Q6, not this SPEC's to assume; the criterion is re-worded to match that
  > answer before the feature is specified.
- [ ] **SHOULD** — Given the summary grading path, when the single-backend change is made, then `grade.sh` is the sole letter producer and the change carries the same fixture or before/after proof as the gates above. *(discharges FR-B6; §9 AC-3 conditional tail)*
- [ ] **MUST** — Given the repository, when the history-section sweep is run over the authored trees, then no artifact-authoring instruction, template section, or fixture authors a `## Change Log`, a `## Revision History`, or a `changelog:` field — only the rule text that forbids one. *(discharges FR-B7; §9 AC-7)*
- [ ] **MUST** — Given a script proposed by this feature — the settings gate in particular — when it is merged, then it cites a measurement of the re-derivation it removes. *(discharges NFR-3; §9 AC-5)*
- [ ] **MUST** — Given this feature's changes, when `grade.sh` and `reviewer-ledger-schema.md` are diffed against the work's base commit, then neither counting logic nor column shape has changed; and `generate-profile` re-renders byte-identically with VERIFY deterministic PASS, with no hand-edit in `profiles/` or the dogfood trees. *(discharges NFR-1, NFR-2; §9 AC-11)*
- [ ] **MUST** — Given any count stated in this feature's artifacts, when the cited command is re-run, then it reproduces the number. *(discharges NFR-4; §9 AC-12)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

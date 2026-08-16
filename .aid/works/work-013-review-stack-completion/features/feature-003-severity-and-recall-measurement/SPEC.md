# Severity and Recall Measurement

## Source

- REQUIREMENTS.md §4 Scope — T3 Measure & judge
- REQUIREMENTS.md §5 Functional Requirements — FR-C1 … FR-C6
- REQUIREMENTS.md §6 Non-Functional Requirements — NFR-1 … NFR-4
- REQUIREMENTS.md §7 Constraints
- REQUIREMENTS.md §9 Acceptance Criteria — AC-4, AC-5, AC-9, AC-10, AC-11, AC-12
- REQUIREMENTS.md §10 Priority — item 3

## Description

With one stack and its blind spots closed, the last question is whether the grade means
anything. Four judgment-and-measurement gaps remain.

A severity today can be asserted without a reason. This feature requires every finding
to carry a one-line why that names the consequence — without undoing the cascade's
declared severities: when a finding cites a criterion that already prices itself, that
price is the default band and the why-line is still written. When the reviewer judges the
band itself, or diverges from the declared one, the row says so.

A new review cycle is told not to look at the previous cycle's ledger. Being told is not
the same as being unable. This feature makes the isolation structural, and proves it by
documenting an attempted path and its failure.

Nobody knows what fraction of real defects a review actually finds. This feature builds a
corpus of deliberately seeded defects and a command that reports recall against it, so
that recall becoming worse is a defect in the review subsystem rather than an invisible
decline.

And a fix that repairs one instance of a defect leaves its siblings in place. This
feature makes a class sweep part of closing a fix: the sweep command and its output are
recorded with the fix, and a seeded second instance of the same class is found by that
sweep rather than by the next review cycle.

This feature is last because its measurements only mean something once the first two have
settled what is being measured.

## User Stories

- As the owner, I want every finding to say what breaks, so that a grade reads as distance from the ideal rather than a feeling wrapped in arithmetic.
- As the reviewer agent, I want a severity practice I can defend line by line, so that a divergence from a declared severity is visible and justified instead of silent.
- As a pipeline skill, I want a new review cycle to be structurally unable to reach the previous cycle's ledger, so that a clean context is a property of the dispatch rather than an instruction I might not follow.
- As a maintainer, I want recall measured against seeded defects, so that a review getting worse at finding things shows up as a regression.
- As a maintainer, I want a fix to sweep its own defect class before it closes, so that the same bug is not rediscovered one instance at a time.
- As the reviewer agent, I want mechanical checks that only observe to stay out of the ledger, so that observations do not silently become grade-affecting findings.

## Priority

Should

## Acceptance Criteria

> `## Priority` above is this feature's scheduling weight from §10. Each criterion below
> carries its own modality, inherited from the requirement it discharges — a Should
> feature can and does contain MUST criteria.
>
> The last two criteria are synthesized: FR-C3 and FR-C6 reach no criterion in §9, so
> each inherits its source requirement's SHOULD.

- [ ] **MUST** — Given a real review cycle, when its ledger is measured by the cited command, then every row's `Description` carries a one-line why naming the consequence, and any row whose severity diverges from a cited criterion's declared `severity:` says so in `Evidence`; the row count is reported. *(discharges FR-C1; §9 AC-9)*
- [ ] **MUST** — Given a new review cycle, when a reviewer attempts to reach the prior cycle's ledger, then the attempt fails structurally, and the attempted path and its failure are documented rather than an instruction not to look. *(discharges FR-C2; §9 AC-4)*
- [ ] **MUST** — Given the seeded-defect corpus, when the recall-report command is run, then it produces a recall figure per rule set and overall, and its output is recorded. *(discharges FR-C4; §9 AC-4)*
- [ ] **MUST** — Given a FIX cycle, when it is closed, then its class sweep has run with the command and output recorded, and a seeded second instance of the same defect class was found by that sweep rather than by the next review cycle. *(discharges FR-C5; §9 AC-10)*
- [ ] **SHOULD** — Given a review where file-scoped HUNT is shown to be insufficient, when coverage is recorded, then a coverage unit may be a claim or worklist item rather than a file, demonstrated on at least one such review. *(discharges FR-C3; synthesized — no §9 criterion)*
- [ ] **SHOULD** — Given a mechanical check that only observes, when it runs, then it emits no ledger row; only an open criteria gap may block a grade for a missing rule; and an oracle emitting `VIOLATION` appears as an ordinary criteria finding in the same 7-column ledger, never as a second ledger. *(discharges FR-C6; synthesized — no §9 criterion)*
- [ ] **MUST** — Given a script proposed by this feature — the recall tooling in particular — when it is merged, then it cites a measurement of the re-derivation it removes. *(discharges NFR-3; §9 AC-5)*
- [ ] **MUST** — Given this feature's changes, when `grade.sh` and `reviewer-ledger-schema.md` are diffed against the work's base commit, then neither counting logic nor column shape has changed; and `generate-profile` re-renders byte-identically with VERIFY deterministic PASS, with no hand-edit in `profiles/` or the dogfood trees. *(discharges NFR-1, NFR-2; §9 AC-11)*
- [ ] **MUST** — Given any count stated in this feature's artifacts, when the cited command is re-run, then it reproduces the number. *(discharges NFR-4; §9 AC-12)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

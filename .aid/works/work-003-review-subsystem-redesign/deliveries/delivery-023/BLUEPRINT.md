# Delivery BLUEPRINT -- delivery-023: Host chaining confirmation

> **Delivery:** delivery-023
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-09

---

## Objective

Retire an assumption the whole extraction rests on: that `/aid-review` can actually be reached by a
chain-call on codex, copilot-cli and antigravity. Scoped as a distinct unit because it ships no
capability and cannot be discharged by any test in this repository.

## Scope

- A live chain-call of `/aid-review` from a pipeline skill on **codex**, **copilot-cli** and
  **antigravity**, with the result recorded as evidence.
- The fallback path exercised on at least one host where chaining does not work, if any.
- `skill_chaining` in those three profiles corrected to what was observed, if it disagrees.

**Out of scope:** claude-code and cursor, where chaining is exercised continuously by this work's own use; any
change to the fallback design, which is *"one fallback design, not five"* and is not revisited here.

## Gate Criteria

- [ ] A chain-call of `/aid-review` is **attempted** on each of codex, copilot-cli and antigravity,
      and the **observed outcome** -- executed, or failed and how -- is recorded with its transcript.
      The criterion is that the attempt was made and its result written down, **not** that chaining
      works: a delivery whose gate required success could not report the failure it exists to find
- [ ] Where a host does not chain, the fallback is exercised and its behaviour recorded -- an
      unexercised fallback is the failure this delivery exists to prevent
- [ ] Each profile's `skill_chaining` value states what was observed, not what was assumed
- [ ] The evidence names the host build/version, so the claim is falsifiable later
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-022
- **Blocks:** -- (none)

## Notes

**Why a delivery and not a test.** `RX13`-`RX16` prove both skills and the brief template *render*
identically to all five profiles. That is a different claim from a chain *executing* on three of
them. Confirming it needs a host runtime, which no canonical test has.

**Why the existing declarations are not evidence.** All five profiles carry `skill_chaining = true`,
but for these three hosts those lines were authored by commits **predating work-003** -- they are the
same declaration this question was raised about, not a verification of it.

**Why after the merge.** It confirms the shape that actually ships. Running it before delivery-022
would verify a skill about to be replaced.

**Kind: enabling.** It ships no user-visible capability; its output is evidence.

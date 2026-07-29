# Reviewer Dispatch Protocol

> **The mechanism now lives in two skills.** Dispatch review through
> [`/aid-deep-review`](../../skills/aid-deep-review/SKILL.md) for a graded pass, or
> [`/aid-light-review`](../../skills/aid-light-review/SKILL.md) for a cheap screen. The brief and its
> invocation manifest are defined in
> [`reviewer-brief-template.md`](reviewer-brief-template.md).
>
> This document keeps only what those two do not: **why** the discipline exists, and the two cases that
> sit outside the skills.

## Why the discipline exists

Reviewer dispatches once used ad-hoc prose briefs, and prose briefs **leak scope**. The author writes
*"this affects downstream phases X and Y"*; the reviewer grades the artifact against X and Y as well;
findings about adjacent concerns inflate the grade; review cycles bloat.

A brief therefore declares three things explicitly: what is under review, what is **not**, and what the
reviewer does with a stray observation. That is the whole point, and it is why the manifest has required
fields rather than optional ones — a caller that cannot say what is out of scope has not finished
deciding what it is asking for.

**Why the brief is a file and not free text.** Free text cannot be validated, so a missing section
became a reviewer guessing rather than a caller failing. The manifest makes the omission a hard error.

## One-off reviews

When no per-skill brief sections exist yet — a skill being authored, or genuinely non-recurring work —
hand-craft the two sections and invoke `/aid-deep-review` with a manifest as usual. **The protocol
applies; only the per-skill template is skipped.** Do not hand-roll a dispatch to bypass the ledger, the
gap gate, or the grade: those are what make the result a reviewable verdict rather than an opinion.

## Bootstrap exemption

This document lives in `.github/aid/templates/` and is a **skill-bundle artifact**, not a KB document.
The frontmatter schema in `kb-authoring/frontmatter-schema.md` governs `.aid/knowledge/*.md` in adopter
projects, not canonical bundle docs — so this file carries no `kb-category:` / `source:` frontmatter.

## When this protocol changes

Normative for every reviewer dispatch, so a change reaches every skill. A revision should be a single
deliberate change rather than folded into other work, and should update the brief template alongside it.

## History

- 2026-05-26: Initial authoring (Phase A KB Authoring overhaul).
- 2026-05-27: Six per-skill `reviewer-brief.md` templates landed; documented the rendering convention
  and the derive-ARTIFACTS-from-disk rule.
- 2026-07-29: **Reduced to a rationale document.** The five-section brief, the section-by-section
  guidance, the generation mechanism and the worked example were absorbed into
  `reviewer-brief-template.md` and the two review skills — nine callers had been carrying copies of that
  machinery. This file also carried an instruction retired earlier in the same work (*"for existing rows
  from prior cycles: update Status only"*), which is now the orchestrator's job, not the reviewer's;
  leaving 311 lines of duplicated protocol in place is precisely the drift the extraction removes.

## See also

- [`reviewer-brief-template.md`](reviewer-brief-template.md) — the brief and the invocation manifest
- [`review-rubrics/INDEX.md`](review-rubrics/INDEX.md) — rule-set routing
- [`reviewer-ledger-schema.md`](reviewer-ledger-schema.md) — the ledger, row kinds, reconciliation
- [`criteria-gap-protocol.md`](criteria-gap-protocol.md) — what to do when no rule exists
- [`grading-rubric.md#severity-scale`](grading-rubric.md#severity-scale) — the single severity source
- [`self-review-protocol.md`](self-review-protocol.md) — what the producing agent should have done first
- `.github/agents/aid-reviewer/` — the deep reviewer; `.github/agents/aid-screener/` — the screener

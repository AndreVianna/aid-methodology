---
name: aid-light-review
description: "Cheap screening pass over an artifact, callable by any skill. Dispatches aid-screener, reports what is obviously wrong, and STOPS. Computes no grade, writes no ledger, writes no coverage rows. Never a substitute for /aid-deep-review."
allowed-tools: Read, Glob, Grep, shell
---

# /aid-light-review

**A filter that runs before the expensive pass, not a cheap version of it.**

Dispatch `aid-screener` over an artifact, relay what it found, and stop. This skill exists so a caller
can spend a few cents finding a missing section before spending a lot finding nothing.

## What it deliberately does NOT do

These are not omissions, and each has a consequence if violated:

| Does not | Because |
|---|---|
| compute or report a grade | a grade is a graded verdict; a screen is not one, and a number invites treating it as one |
| write a ledger | ledger rows feed `grade.sh`; a cheap pass must never contribute to a grade |
| write `U-` coverage rows | coverage means *"examined against a rule set"*, and a later deep pass would read it as clearance |
| write `G-` gap rows | a gap gates a grade; only a pass that could resolve a rule set may raise one |
| run tests, builds or validators | `aid-screener` has no `Bash` — if a check needs a shell it is review work |
| enumerate the class | that is the expensive sweep, and duplicating it removes the saving |

**The coverage rule is the sharp one.** A clean light pass must leave **no artifact a deep pass could
mistake for clearance.** If this skill wrote `U-` rows, a deep review resuming afterwards would skip
units nobody adversarially examined — and it would be right to, because that is what a `U-` row means.

## States

### 1. RESOLVE

Read the invocation manifest (`.github/aid/templates/reviewer-brief-template.md` § invocation
manifest). Require `scope`, `artifacts`, `depth: light`.

Resolve the artifact's rule set via `review-rubrics/INDEX.md` — **for context only.** The screener does
not apply rule rows; knowing the class tells it what kind of thing it is reading.

If `depth` is not `light`, stop: the caller wants `/aid-deep-review`.

### 2. SCREEN

Dispatch **`aid-screener`** (`subagent_type: aid-screener`, small tier, effort `low`).

Give it: the artifact paths, the artifact class, and one sentence of context. **Do not** give it the
rule set's rows, a prior grade, a prior review's findings, or a ledger path — it has no `Bash` and
nothing to write to.

Never escalate the tier. Escalating a screener turns it into the review it precedes; if it needs more
capability, dispatch `/aid-deep-review` instead.

### 3. REPORT

Relay the screener's return message to the caller, unchanged in substance, plus exactly one verdict:

- `LIGHT: <n> issue(s) found. Not exhaustive -- a deep review is still required.`
- `LIGHT: nothing obvious found. NOT a pass -- no adversarial review was performed.`

**Never say "clean", "passed", or "looks good".** A caller that reads "clean" will skip the deep pass,
and that is the failure this skill is built to avoid.

Advance: DONE. This skill has no FIX loop — it produces no findings anyone is obliged to fix.

## What the caller does with the result

Its choice, and both are legitimate:

- **Fix the obvious first, then run `/aid-deep-review`.** Usually the point: the deep pass is not spent
  rediscovering a missing heading.
- **Run `/aid-deep-review` regardless.** Also correct. A light pass is never a precondition, and
  skipping it is never an error.

**What a caller may never do is treat a clean light pass as satisfying a gate.** No grade was computed,
so no minimum grade was met. Gates read grades.

## See also

- [`aid-deep-review`](../aid-deep-review/SKILL.md) — the graded pass this one precedes
- `.github/agents/aid-screener/AGENT.md` — the agent dispatched here
- `.github/aid/templates/reviewer-brief-template.md` — the invocation manifest

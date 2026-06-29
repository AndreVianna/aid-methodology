# Design Note — Finish the Phase-2 Rename Internally

**Status:** Pre-scoping — NOT yet a tracked work. Captured 2026-06-29 (post-v2.0.0). Smallest / most
contained of the four 2026-06-29 seeds — it *finishes* a rename that is ~90% done.

**Motivation.** v2.0.0 renamed Phase 2 from "Interview" to **"Describe → Define"** everywhere a *user*
looks — the methodology, the KB, the docs site, the `kb.html` pipeline diagram, CLAUDE.md, the
get-started/guides pages. But the **internal tokens were deliberately kept** as "Interview" because
changing them touches more wiring (the canonical state template, the dashboard reader, and their tests).
Result: a small but real **docs-say-Describe / internals-say-Interview** mismatch. This seed closes it.

The kept tokens are documented in `docs/diagram-content-reference.md` ("What this reference does NOT
cover") and were intentionally preserved:
- the Pipeline-State **`Phase:` enum value** `Interview` in `canonical/aid/templates/work-state-template.md`
  (asserted by `tests/canonical/test-pipeline-status-walkthrough.sh` + `test-work-state-template.sh`,
  and parsed by the dashboard reader);
- the literal **`## Interview State`** STATE.md section name.

(NOT in scope — these stay "interview" forever: the `aid-interviewer` agent name, and lowercase
"interview" the *conversational act*, which is still exactly what `aid-describe` does.)

---

## Problem

The user-facing label and the internal state token disagree. A work in Phase 2 shows `Phase: Interview`
in its STATE.md and "Interview" in the dashboard, while every doc/diagram says "Describe → Define". It's
cosmetic, but it's exactly the kind of internal inconsistency this product can't afford.

## Proposed approach

1. Decide the new token(s) (see decisions below).
2. Update `canonical/aid/templates/work-state-template.md` — the `Phase:` enum and the `## Interview
   State` section heading.
3. Update the **dashboard reader** — both twins (the Python `dashboard/reader/*.py` set and the Node
   `dashboard/server/reader.mjs`) that parse `Phase:` and the section name.
4. Update the **tests** that assert the enum/section (`test-pipeline-status-walkthrough.sh`,
   `test-work-state-template.sh`, and any others).
5. **Re-render** to the 5 profiles + `.claude` (canonical change → `run_generator.py`; DBI must stay byte-identical).
6. Update `diagram-content-reference.md` to move these tokens off the "not covered" list.

## Key decisions / options to settle in scoping

- **One Phase value or two?** Phase 2 is realized by *two* sub-skills (`aid-describe` 2a, `aid-define` 2b).
  Does the `Phase:` enum become a single `Describe-Define` (or `Describe`), or two values `Describe` (2a)
  and `Define` (2b)? Two values is more precise (the dashboard could show 2a vs 2b) but is a bigger change
  to the reader + every consumer. **Leaning:** a single value to mirror "one numbered phase", but this is
  the core design question.
- **`## Interview State` → what?** `## Phase-2 State` / `## Describe State` / `## Requirements State`?
  Pick a name that reads naturally for both 2a and 2b.
- **Backward-compatibility for in-flight works (migration).** Existing STATE.md files (and any user repo
  mid-Phase-2) carry `Phase: Interview` / `## Interview State`. The dashboard reader and skill State
  Detection should **accept the old token as an alias** for at least a transition period so existing works
  don't become unreadable. (This mirrors the registry's `repos:`→`projects:` transparent-read precedent.)
- **Does `AID_SUPPORTED_FORMAT` bump?** Likely **no** — this is a *value/label* rename, not a structural
  layout change, and the alias keeps old files readable. Confirm during scoping.

## Scope boundaries

Internal state tokens + their reader + tests only. The user-facing labels are already done (v2.0.0). Do
not touch the `aid-interviewer` agent or the lowercase conversational "interview".

## Relation to other work

Completes the work-001 / v2.0.0 Phase-2 relabel. Naturally consumes the fact-consistency gate's
"phase names" source of truth if that seed lands first (the enum value becomes one more asserted fact).

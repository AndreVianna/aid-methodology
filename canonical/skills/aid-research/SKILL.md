---
name: aid-research
description: >
  Investigate an open technical question and weigh its options. Use when options must be
  weighed before a choice is made.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<question> -- an open technical question to investigate"
---

# Research (investigate now, resolve nothing)

`/aid-research` investigates an open question **now** and returns a **curated, verified
answer** -- the complete picture, presented clearly. It is `aid-ask`'s bigger
sibling: where `aid-ask` *retrieves an answer that already exists* in the project's
context (one read-only pass, no work folder), research *builds a new judgment* for a
question the available context can't already answer -- with option evaluation, external
context, an optional authorized spike, verification, and a human-facing presentation.

- **Resolves nothing.** No "I recommend X." It lays out conclusions (+/-), conflicts, and
  gaps; the user decides.
- **Not a numbered pipeline phase**; it does not route to `/aid-execute`.

State machine: **INTAKE (-> INTAKE-ASK?) -> ALLOCATE -> INVESTIGATE (-> PROPOSE-SPIKE?) -> VERIFY
(loop) -> PRESENT [human resolves] -> HANDOFF? -> DONE**. Print the `[State: NAME] -- {purpose}` entry line
on each state.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists).

1. **Check the question.** Note whether the argument is empty. Do not ask here.
2. **Pick the path (question scope):**
   - **Fast path** -- a concrete, well-scoped question with clear evaluation criteria
     ("Is lib X compatible with our Node 24 build?", "Postgres vs SQLite for use-case Y
     against criteria A/B/C") -> investigate immediately.
   - **Guided path** -- vague / broad / underspecified ("research our DB options") -> narrow
     it first in INTAKE-ASK (2-3 scoping questions), then investigate.
3. **Classify complexity (sets model + effort):** simple (bounded question, a few docs,
   <=1 web source) -> `aid-researcher` at **sonnet / medium**; standard/complex (broad
   options analysis, deep traversal, many web sources, a spike) -> **opus / high**.
   Verifier tier is always >= producer tier.
4. **Check for works.** Run `bash .aid/runtime/scripts/works/enumerate-works.sh`
   (main tree + every git worktree). Note whether any exist. Do not prompt here.

**Advance:** CHAIN -> [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works exist; otherwise CHAIN -> [State: ALLOCATE].

---

## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:

1. **Empty argument** -> the bootstrapping question ("What do you want investigated?"). The
   answer is the question; the path and complexity are then set from it.
2. **Guided path** -> the 2-3 scoping questions that narrow the question.
3. **Works exist** -> the gate's new-vs-continuation question with the enumerated list.

**Advance:** ASK -> [State: ALLOCATE].

---

## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).

- **New work:** call the gate's `§ 3a` with the user's words, this skill's name (`aid-research`),
  its saved step (`INVESTIGATE`), the step the work continues at once it exists (INTAKE and INTAKE-ASK run before the record and save nothing), `--path lite`, and a kebab-case slug from the question. The gate's `§ 3a` step 2 creates and enters the worktree
  (`worktree-lifecycle.sh create <work-id> <name>`),
  **then** allocate (`.aid/works/<work-id>-<slug>/`) the work folder and write its record through
  the writer, before it hands back: "`STATE.yml` was created by the gate;
  skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand;
  set other keys through the writer." This skill drives no `phase`. Associate a git worktree only
  if a spike is later authorized (PROPOSE-SPIKE).
- **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.

Every `--step` call in this skill passes in its `--detail` the scoped question, the path and the complexity tier, so a
resume finds them in the record.

**Advance:** CHAIN -> [State: INVESTIGATE].

---

## State: INVESTIGATE

Dispatch **`aid-researcher`** (clean context, model+effort from INTAKE Step 3) to gather
and curate the evidence:

- **Two-tier grounding (enforced):** read the KB (`.aid/knowledge/`) + the project source
  as the **authoritative** base; enrich with external/web sources as needed, **cited with
  URL + access date**. Every project claim cites a KB doc or `file:line`; every external
  claim cites a URL+date.
- It writes a structured `RESEARCH.md` into the work folder (see [Response shape](#response-shape)).

**Spike escalation (conditional, human-authorized).** Default is **analytical-with-
handoff** -- no code is written. If the researcher determines a gap genuinely cannot be
closed on paper, it returns a **spike proposal** instead of a final answer; the step then
goes to **PROPOSE-SPIKE**. Otherwise it goes on to VERIFY.

**Advance:** CHAIN -> [State: VERIFY]; when the researcher returned a spike proposal,
CHAIN -> [State: PROPOSE-SPIKE] instead.

---

## State: PROPOSE-SPIKE  (only when a spike is proposed; the user decides)

Present *what* the spike would build, *where* (isolated in the work folder / opt-in worktree,
never touching production), and *what it would learn*. Ask the user to authorize or decline it.
Once the user answers: on **authorization** -> re-dispatch `aid-researcher` to write the
throwaway spike (isolated) and fold the finding into `RESEARCH.md`; on **decline** -> proceed
analytically and state the resulting limit in the Gaps section.

**Advance:** ASK -> [State: VERIFY].

---

## State: VERIFY  (who reviews the researcher)

1. **Mechanical grounding check** (no dispatch): every project claim carries a KB/source
   cite; every external claim a URL+date; the **Conflicts** and **Gaps** sections exist
   (empty-but-present is allowed; silently-omitted is not).
2. **Adversarial verification** -- dispatch a clean-context **`aid-reviewer`** to check
   `RESEARCH.md`: claims grounded and correctly attributed; conclusions evidence-backed
   and **not overstated into resolutions**; every KB<->web conflict surfaced with its
   reason; no material angle of the question left silently unaddressed. It writes a
   review-quality 7-column ledger (`reviewer-ledger-schema.md`) to
   `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade the response:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not
   clean -> loop back to INVESTIGATE for the researcher to revise. **Circuit-breaker: 3
   cycles** -> write `.aid/works/{work}/IMPEDIMENT-research.md`, and set the lifecycle to `Blocked` through the writer,
   surface it.

(Single grade -- the response *is* the deliverable; there is no separate target artifact.)

**Advance:** CHAIN -> [State: PRESENT].

---

## State: PRESENT  (always a hard stop -- the user resolves)

The hard stop follows the ASK step of `skill-steps.md`. Present `RESEARCH.md` **clearly and simply**:
the in-depth answer, conclusions (positive **and** negative), conflicts/contradictions
**with their reasons**, and gaps. Assert no resolution -- the user decides. Negatives and
gaps are first-class, never buried under positives.

**Advance:** ASK -> [State: HANDOFF].

---

## State: HANDOFF  (optional; printed suggestions only)

Offer the natural next steps as **printed suggestions**, each requiring the user to act:
record an ADR (`/aid-document-decision` -> once landed, `/aid-create-document`), update the
KB (`/aid-update-kb`), act on a conclusion (`/aid-create*` / `/aid-update*`), or comment on
a source ticket (`/aid-update-ticket comment [<connector>:]<ticket-id> <text>`). Never
auto-invoked; never a resolution. Ask which one, if any, the user takes; a picked one is named
in one plain line.

**Advance:** ASK -> [State: DONE].

---

## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Keep the work folder (`RESEARCH.md`, any spike scratch, the verify ledger) as the audit record.

**Advance:** HALT.

---

## Response shape

`RESEARCH.md` (the "clear + simple" deliverable), sections in order:

1. **Question** -- the query, as scoped/investigated.
2. **Answer** -- the in-depth, curated response.
3. **Conclusions** -- positive *and* negative, each evidence-backed and cited.
4. **Conflicts & contradictions** -- especially KB<->web, each with **its reason** and both
   citations; `none` if there were none.
5. **Gaps** -- what could not be answered / stays uncertain (incl. any limit from a
   declined spike); `none` if none.
6. **Sources** -- KB docs + `file:line` (authoritative) and external `URL (accessed
   YYYY-MM-DD)` (supplementary), clearly separated.

---

## Constraints

- **Resolves nothing** -- curated information + conclusions/conflicts/gaps; never a
  directive.
- **Two-tier grounding, enforced** (VERIFY step 1 + the researcher brief): KB+source
  authoritative, web supplementary + cited; KB<->web contradictions surfaced with reasons,
  never silently resolved.
- **Clean context** -- INVESTIGATE and VERIFY never share context.
- **Verification is always a sub-agent dispatch** (`aid-reviewer`), never inline.
- **Human final say before any commit** -- a spike (code), a KB update, a decision doc, or
  a ticket comment happens only on explicit authorization; presenting the answer is not a
  commit.
- **Tracking:** every record change goes through the writer (`skill-steps.md`, § The work record).

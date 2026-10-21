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
(loop) -> PRESENT [human resolves] -> HANDOFF? -> DONE**.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists). Their questions are recorded in a design document under `.aid/design/`, not in a work record.

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

**Advance:** CHAIN → [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works exist; otherwise CHAIN → [State: ALLOCATE].

---

## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:

1. **Empty argument** -> the bootstrapping question ("What do you want investigated?"). The
   answer is the question; the path and complexity are then set from it.
2. **Guided path** -> the 2-3 scoping questions that narrow the question.
3. **Works exist** -> the gate's new-vs-continuation question with the enumerated list.

Record each of these questions in a design document before it is shown, and its reply after it, as the gate's "Recording the questions asked before a work exists" says (`.aid/runtime/templates/work-initiation-gate.md`): `--ask --design .aid/design/untitled-<YYYYMMDD-HHMMSS>.md` first, then `--answer --design` on the same file with the id the writer printed; once the subject is known, `--rename-design .aid/design/untitled-<YYYYMMDD-HHMMSS>.md --to .aid/design/<slug>.md`, the slug being the one ALLOCATE gives the work.

**Advance:** ASK → [State: ALLOCATE].

---

## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).

- **New work:** call the gate's `§ 3a` with the user's words, this skill's name (`aid-research`), with `--seed .aid/design/<slug>.md` on the gate's `--create` when INTAKE-ASK recorded any question (the gate adds it to the work's `sources:` and copies its `## Questions` into the work's record),
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

**Advance:** CHAIN → [State: INVESTIGATE].

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

**Advance:** CHAIN → [State: PROPOSE-SPIKE] when the researcher returned a spike proposal; otherwise CHAIN → [State: VERIFY].

---

## State: PROPOSE-SPIKE  (only when a spike is proposed; the user decides)

Present *what* the spike would build, *where* (isolated in the work folder / opt-in worktree,
never touching production), and *what it would learn*. Then ask the user to authorize or decline it
as one approval question in the form of `.aid/runtime/templates/question-protocol.md`
(`Research -- question 1 of 1 -- importance: medium`, **Why I ask**: a spike writes code, so it needs your
go-ahead, **My recommendation**, and the closing line `Or answer in your own words, or ask me to explain.`).
Once the user answers: on **authorization** -> re-dispatch `aid-researcher` to write the
throwaway spike (isolated) and fold the finding into `RESEARCH.md`; on **decline** -> proceed
analytically and state the resulting limit in the Gaps section.

The question pauses this step where it stands, as `.aid/runtime/templates/skill-steps.md` part 3 sets: the step stays saved, `--step` brings its `--detail` up to date with what is done and which question is open, `--ask` records the question, and `--pipeline` sets the lifecycle `Paused-Awaiting-Input` and the pause reason before the question is asked. Once it is answered, `--answer` records the answer and `--pipeline` sets the lifecycle back to `Running`. The write that follows the answer, the spike
or the Gaps note, is part of this step. Once it is done, record in the `--detail` what was decided.

**Advance:** CHAIN → [State: VERIFY].

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
   cycles** -> write `.aid/works/{work}/IMPEDIMENT-research.md`, set the lifecycle to `Blocked` through the writer,
   and name the open finding in plain words. Then ask the one question that unblocks the work, in the
   form of `.aid/runtime/templates/question-protocol.md`, never as a bare "your call":

   ```text
   Research -- question 1 of 1 -- importance: high
   Shall I fix {the open finding} and run one more review, or do you take the report as it stands with it noted?
   Why I ask: the review loop stopped after 3 cycles, so only you can say whether to go on.
   My recommendation: {the option that fits the finding's severity, and why}
     1. Fix it and run one more review (recommended)
     2. Take the report as it stands, with the finding noted under Gaps
   Or answer in your own words, ask me to explain, or skip this question.
   ```

   Record it with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Research --impact High --context '<the question>' --suggested '<the recommendation>' --asked-by aid-research` before it is shown, and the reply with `--answer --id Q<n> --state <Answered|Skipped> --value '<the answer>' --applied-to 'research report'` right after. On the first option set the lifecycle back to `Running` and continue at INVESTIGATE for one more cycle; on the second set it back to `Running` and continue at PRESENT, naming the finding under Gaps. A skipped question leaves the work `Blocked`.

(Single grade -- the response *is* the deliverable; there is no separate target artifact.)

**Advance:** CHAIN → [State: PRESENT] when the grade is clean; CHAIN → [State: INVESTIGATE] when it is not clean and fewer than 3 cycles have run; ASK then HALT when the circuit-breaker has blocked the work (the question above stays open).

---

## State: PRESENT  (always a hard stop -- the user resolves)

The hard stop follows the ASK step of `skill-steps.md`. Present `RESEARCH.md` **clearly and simply**:
the in-depth answer, conclusions (positive **and** negative), conflicts/contradictions
**with their reasons**, and gaps. Assert no resolution -- the user decides. Negatives and
gaps are first-class, never buried under positives. The turn ends with the HANDOFF question below, in the form,
never with an open line such as "your call".

**Advance:** ASK → [State: HANDOFF].

---

## State: HANDOFF  (optional; printed suggestions only)

Offer the natural next steps as **printed suggestions**, each requiring the user to act:
record an ADR (`/aid-document-decision` -> once landed, `/aid-create-document`), update the
KB (`/aid-update-kb`), act on a conclusion (`/aid-create*` / `/aid-update*`), or comment on
a source ticket (`/aid-update-ticket comment [<connector>:]<ticket-id> <text>`). Never
auto-invoked; never a resolution. Ask which one, if any, the user takes, as one question in the form of
`.aid/runtime/templates/question-protocol.md` (`Research -- question 1 of 1 -- importance: low`, **Why I ask**,
**My recommendation**, numbered options with the recommended one first, and the closing line). Record it with
`writeback-state.sh --ask --category Research --impact Low --context '<the question>' --suggested '<the recommendation>' --asked-by aid-research` before it is shown, and the reply with
`--answer --id Q<n> --state <Answered|Skipped> --value '<the answer>'`; a picked one is named in one plain line.

**Advance:** ASK → [State: DONE].

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

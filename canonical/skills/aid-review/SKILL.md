---
name: aid-review
description: >
  Review code, a change or a design against criteria. Use when a review is asked for.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "[target] -- what to review (a file/dir, PR link, ticket id, work-NNN, 'my changes', or a described target)"
---

# Review (run now, produce findings)

`/aid-review` performs a review **now** and returns **grade + findings +
recommendations**. It is the adversarial sibling of `/aid-ask`: both are single-shot,
grounded, cited, and never plan-and-halt -- review evaluates an existing artifact against
criteria, where `/aid-ask` answers a free-form question.

- **Not a numbered pipeline phase.** It runs on demand; it does not enter the
  pipeline phases (Definition to CI) and never routes to `/aid-execute`.
- **Read-only except:** the findings ledger (a `.temp` artifact) and, only after
  your approval, a publish to the reviewed target (a PR/ticket comment, doc notes).
  It never edits the reviewed code/design itself and never fixes -- fixing is
  `/aid-fix`'s job.

State machine: **INTAKE (-> INTAKE-ASK?) -> ALLOCATE -> REVIEW -> VERIFY (loop) ->
PRESENT-FINDINGS [human] -> PUBLISH (on approval) -> DONE**.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists).

Purpose: resolve the target + criteria, pick the path, note the works.

### Step 1 -- check the target

Note whether the argument is empty. Do not ask here. If it is empty, INTAKE-ASK asks exactly one
bootstrapping question:

```
What do you want to review? Point me at a file/dir, a PR, a ticket id, a
work-NNN, "my changes", or describe the target.
```

### Step 2 -- pick the path (fast vs guided)

**Fast path** -- the prompt carries an explicit, resolvable target whose review method
is unambiguous. Record the target, method, and tentative delivery; go on to ALLOCATE, then REVIEW.

| Signal | Method | Tentative delivery |
|---|---|---|
| PR link / `#123` | diff review | PR comment(s) via `gh` |
| ticket id (`PROJ-45`) | assess ticket content | ticket comment via `/aid-update-ticket` |
| file / dir path | static review vs KB + coding-standards | findings report |
| "my changes" / working tree / staged | working-diff review | findings report |
| commit SHA / range / branch | diff review | findings report or PR comment |
| `work-NNN` or an AID artifact (REQUIREMENTS/SPEC/PLAN/DETAIL) | review vs its acceptance criteria + KB | findings in the work folder |
| a KB doc (`.aid/knowledge/*.md`) | review vs the KB-authoring rubric | findings report |

**Guided path** -- target open-ended (a UI, a BDD-scenario set, "is my auth sound?"),
or a fast trigger that does not resolve (file absent, ticket id but no catalogued
connector, PR # with no repo context). Interpret the request and form a plan -- *what*
you will review, *how* (method + any tool/MCP needed to gather evidence), and *where*
findings will be delivered. The plan is presented in INTAKE-ASK, where the user confirms or
corrects it before any review effort is spent.

### Step 3 -- criteria

Derive the review criteria from the KB (`coding-standards.md`, `architecture.md`, and
the artifact's own acceptance criteria if it is AID work) plus anything the user named.
Fast path: implicit. Guided path: part of the plan the user confirms.

### Step 4 -- classify complexity (sets model + effort)

- **Simple** (one small file, a short doc, a tiny diff) -> dispatch `aid-reviewer` at
  **model `sonnet`, effort `low`/`medium`**; single light VERIFY pass.
- **Standard/complex** (a full PR, a design, security/perf, multi-file) -> **model
  `opus`, effort `high`**; full VERIFY loop.
  Verifier tier is always >= reviewer tier.

### Step 5 -- check for works

Run `bash .aid/runtime/scripts/works/enumerate-works.sh` (main tree + every git worktree). Note
whether any exist. Do not prompt here.

**Advance:** CHAIN → [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is guided, works exist; otherwise CHAIN → [State: ALLOCATE].

---

## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:

1. **Empty argument** -> the bootstrapping question (Step 1). The answer is the target; the path
   is then picked from it.
2. **Guided path** -> present the plan (Step 2) and ask the user to confirm or correct it.
3. **Works exist** -> the gate's single new-vs-continuation question with the enumerated list.

**Advance:** ASK → [State: ALLOCATE].

---

## State: ALLOCATE

Allocate through the Work Initiation Gate (`.aid/runtime/templates/work-initiation-gate.md`).

- **New work:** call the gate's `§ 3a` with the user's words, this skill's name (`aid-review`), its saved step (`REVIEW`), the step the work continues at once it exists (INTAKE and INTAKE-ASK run before the record and save nothing), `--path lite`, and a short kebab-case slug derived from the target. The
  gate `§ 3a` step 2 creates and enters the work-level worktree
  (`worktree-lifecycle.sh create <work-id> <name>`),
  **then** allocate (`.aid/works/<work-id>-<slug>/`) the work folder and write its record through
  the writer, before it hands back: "`STATE.yml` was created by the gate;
  skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand;
  set other keys through the writer." A standalone review is not a pipeline run and drives no
  `phase` (specs/aid-review.md 10).
- **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.

Every `--step` call in this skill passes in its `--detail` the target, method, criteria, complexity tier and the
  plan the user confirmed, so a resume finds them in the record.

**Advance:** CHAIN → [State: REVIEW].

---

## State: REVIEW

Purpose: gather evidence and produce the grounded findings ledger.

1. **Gather evidence** the confirmed method needs, using whatever tools/MCP the plan
   calls for -- `git diff` for a PR/commit/working-tree, `Read`/`Grep` for a file/dir,
   the browser MCP to capture a UI, or -- for a ticket target -- fetch it by invoking
   `/aid-read-ticket [<connector>:]<ticket-id>` (the connector resolution and host-MCP fetch
   live there, feature-001; no direct-fetch recipe is re-implemented here; skip silently if no
   matching connector is catalogued).
2. **Dispatch `aid-reviewer` once, in a clean context** (model+effort from INTAKE Step
   4), with the standard one-off five-section brief per
   `.aid/runtime/templates/reviewer-dispatch.md` One-off reviews:
   `ARTIFACTS UNDER REVIEW` / `CONTEXT` / `RUBRIC` / `OUT OF SCOPE` / `OUT-OF-SCOPE
   FINDINGS POLICY`. The **RUBRIC MUST mandate** reading `.aid/knowledge/` + the relevant
   source and **citing a KB doc or a `file:line` in every finding's Evidence cell**.
   The reviewer writes the global 7-column ledger
   (`.aid/runtime/templates/reviewer-ledger-schema.md`:
   `# | Severity | Status | Doc | Line | Description | Evidence`) to
   `.aid/.temp/review-pending/<work>-review.md`.

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY  (who reviews the reviewer)

Purpose: ensure the review is grounded, correct, and complete before the human sees it.

1. **Mechanical grounding check** (no dispatch): reject any finding row whose `Evidence`
   cell is empty -- an ungrounded finding never reaches the human.
2. **Adversarial verification** -- dispatch a *second* `aid-reviewer` in a clean context
   (never sees the first reviewer's reasoning) to independently check each finding
   against KB + source: flag ungrounded / hallucinated / mis-severity findings, and any
   material **gap** (a real issue the first pass missed). It writes a review-quality
   ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade the review:** `bash .aid/runtime/scripts/grade.sh --explain <verify-ledger>`.
   If it is not clean, loop back to REVIEW so the first reviewer revises (drop ungrounded
   findings, add missed ones). **Circuit-breaker: 3 cycles** -> write
   `.aid/works/{work}/IMPEDIMENT-review.md`, set the lifecycle to `Blocked` through the writer
   (`--pipeline --field Lifecycle --value Blocked`), and surface it instead of looping.

Note: the *target's* grade (`grade.sh --explain` on the review ledger) is computed for
the presentation as information only -- it does NOT drive a fix loop here.

**Advance:** CHAIN → [State: PRESENT-FINDINGS] when the grade is clean; CHAIN → [State: REVIEW] when it is not clean and fewer than 3 cycles have run; HALT when the circuit-breaker has blocked the work.

---

## State: PRESENT-FINDINGS  (always a hard stop -- human final say)

The hard stop follows the ASK step of `skill-steps.md`. Present:

- the **target grade** (from `grade.sh` on the review ledger) -- informational;
- the **verified findings**, severity-ranked, each with its `file:line` / KB evidence;
- **recommendations**, and a **printed suggestion** to act: "N issues found -- run
  `/aid-fix` (or `/aid-update`) to address them" (review never starts the fix itself);
- the **proposed delivery action + the exact comment/notes text** that would be posted.

Then STOP and ask one decision question in the form of `.aid/runtime/templates/question-protocol.md`
(`Review -- question 1 of 1 -- importance: high`, **Why I ask**: nothing is posted without your approval,
**My recommendation**, numbered options: approve and publish / edit the text / choose a different
delivery / do not publish, and the closing line). Record it with
`writeback-state.sh --ask --category Review --impact High --context '<the question>' --suggested '<the recommendation>' --asked-by aid-review` before it is shown, and the reply with
`--answer --id Q<n> --state <Answered|Skipped> --value '<the answer>' --applied-to 'publish'`.
Nothing is posted to any external target until they approve.

**Advance:** ASK → [State: PUBLISH].

---

## State: PUBLISH  (only on approval)

If the user did not approve publishing, nothing is posted: the step goes on to DONE. Otherwise
deliver by the method appropriate to the target, chosen by judgment (not a hardcoded
enum): a PR comment via `gh`; a ticket comment via `/aid-update-ticket comment
[<connector>:]<ticket-id> <text>` (still user-authorized -- the approval just given at
PRESENT-FINDINGS is what authorizes this call, and the skill previews the exact payload again
at its own CONFIRM before posting); a findings report in the work folder (+ optional
inline-comment suggestions) for code; inline notes for a document. **Graceful fallback:** no PR /
no catalogued connector / unknown target -> present the exact text for the human to paste; when the
user must choose where it goes, ask that as one question in the same form, recorded with `--ask` before
it is shown and `--answer` after, recommending the paste.
Publishing is optional and never blocks DONE.

**Advance:** CHAIN → [State: DONE].

---

## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Leave the findings ledger on disk (`.aid/.temp/review-pending/<work>-review.md`) so a follow-up `/aid-fix` can consume it. Keep the work folder as the audit record.

**Advance:** HALT.

---

## Constraints

- **KB + source grounding is enforced** (VERIFY step 1 + the reviewer RUBRIC): no finding
  without a KB/source cite.
- **Clean context:** the REVIEW and VERIFY dispatches never share context; the verifier
  never sees the reviewer's reasoning.
- **Reviews are always a sub-agent dispatch** (`aid-reviewer`), never inline.
- **Human final say before any external commit** (PRESENT-FINDINGS).
- **Read-only** on the reviewed artifact; never fixes (hand off to `/aid-fix`).
- **Tracking:** every record change goes through the writer (`skill-steps.md`, § The work record).

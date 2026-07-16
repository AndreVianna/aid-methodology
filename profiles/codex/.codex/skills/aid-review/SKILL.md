---
name: aid-review
description: >
  Review/assess an existing artifact -- code, a change/diff, a design, a PR, a
  ticket, a document, a UI, whatever the request names -- against criteria, and
  return findings + recommendations NOW, in one pass. Single-shot and
  (except the findings ledger + optional approved publish) read-only: it never
  plans-and-halts. Grounded in the Knowledge Base (.aid/knowledge/) and the
  project source -- every finding cites a KB doc or a file:line. The review is
  produced by the aid-reviewer agent in a clean context and independently
  verified before you see it; you approve before anything is published to an
  external target (PR/ticket/doc). Allocates a work-NNN folder for isolation;
  does not fix anything (findings hand off to /aid-fix).
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[target] -- what to review (a file/dir, PR link, ticket id, work-NNN, 'my changes', or a described target)"
---

# Review (run now, produce findings)

`/aid-review` performs a review **now** and returns **grade + findings +
recommendations**. It is the adversarial sibling of `/aid-query-kb`: single-shot,
grounded, cited, no plan-and-halt. `/aid-audit` is its alias.

- **Not a numbered pipeline phase.** It runs on demand; it does not enter the
  Discover->Execute flow and never routes to `/aid-execute`.
- **Read-only except:** the findings ledger (a `.temp` artifact) and, only after
  your approval, a publish to the reviewed target (a PR/ticket comment, doc notes).
  It never edits the reviewed code/design itself and never fixes -- fixing is
  `/aid-fix`'s job.
- **Behavior contract:** `.aid/work-005-lite-skills-refactor/specs/aid-review.md`.

State machine: **INTAKE -> REVIEW -> VERIFY (loop) -> PRESENT-FINDINGS [human] ->
PUBLISH (on approval) -> DONE**. Print the state-entry line on entry to each state
(`[State: NAME] -- {one-line purpose}`), the convention every AID skill uses.

---

## State: INTAKE

Purpose: resolve the target + criteria, pick the path, allocate the work folder.

### Step 1 -- require a target

If the argument is empty, ask exactly one bootstrapping question and wait:

```
What do you want to review? Point me at a file/dir, a PR, a ticket id, a
work-NNN, "my changes", or describe the target.
```

### Step 2 -- pick the path (fast vs guided)

**Fast path** -- the prompt carries an explicit, resolvable target whose review method
is unambiguous. Record the target, method, and tentative delivery; go straight to REVIEW.

| Signal | Method | Tentative delivery |
|---|---|---|
| PR link / `#123` | diff review | PR comment(s) via `gh` |
| ticket id (`PROJ-45`) | assess ticket content | ticket comment via an MCP connector |
| file / dir path | static review vs KB + coding-standards | findings report |
| "my changes" / working tree / staged | working-diff review | findings report |
| commit SHA / range / branch | diff review | findings report or PR comment |
| `work-NNN` or an AID artifact (SPEC/PLAN/DETAIL/BLUEPRINT) | review vs its acceptance criteria + KB | findings in the work folder |
| a KB doc (`.aid/knowledge/*.md`) | review vs the KB-authoring rubric | findings report |

**Guided path** -- target open-ended (a UI, a BDD-scenario set, "is my auth sound?"),
or a fast trigger that does not resolve (file absent, ticket id but no catalogued
connector, PR # with no repo context). Interpret the request and form a plan -- *what*
you will review, *how* (method + any tool/MCP needed to gather evidence), and *where*
findings will be delivered -- **present the plan and wait for the user to confirm or
correct** before spending review effort.

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

### Step 5 -- allocate the work folder + STATE

Scan `.aid/` for `work-NNN-*`; the new work is `work-{NNN+1}` (`work-001` if none).
Derive a short kebab-case slug from the target. Create `.aid/work-NNN-<slug>/`.
Copy `.codex/aid/templates/work-state-template.md` to
`.aid/work-NNN-<slug>/STATE.md` and write the opening frontmatter (direct edit):
`pipeline.path: lite`, `initiator: aid-review`, `lifecycle: Running`, `active_skill:
aid-review`, `started`/`updated` timestamps. Leave the 7-phase `phase` scalar at its
template value -- a standalone review is not a pipeline run and does not drive it
(specs/aid-review.md 10). Optionally associate a git worktree when the review will
produce working artifacts (inline-comment drafts) or run tools that touch the tree.

**Advance:** REVIEW.

---

## State: REVIEW

Purpose: gather evidence and produce the grounded findings ledger.

1. **Gather evidence** the confirmed method needs, using whatever tools/MCP the plan
   calls for -- `git diff` for a PR/commit/working-tree, `Read`/`Grep` for a file/dir,
   the browser MCP to capture a UI, an issue-tracker MCP to fetch a ticket
   (`connectors/consumption-protocol.md`, MCP-first; skip silently if none catalogued).
2. **Dispatch `aid-reviewer` once, in a clean context** (model+effort from INTAKE Step
   4), with the standard one-off five-section brief per
   `.codex/aid/templates/reviewer-dispatch.md` One-off reviews:
   `ARTIFACTS UNDER REVIEW` / `CONTEXT` / `RUBRIC` / `OUT OF SCOPE` / `OUT-OF-SCOPE
   FINDINGS POLICY`. The **RUBRIC MUST mandate** reading `.aid/knowledge/` + the relevant
   source and **citing a KB doc or a `file:line` in every finding's Evidence cell**.
   The reviewer writes the global 7-column ledger
   (`.codex/aid/templates/reviewer-ledger-schema.md`:
   `# | Severity | Status | Doc | Line | Description | Evidence`) to
   `.aid/.temp/review-pending/<work>-review.md`.

**Advance:** VERIFY.

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
3. **Grade the review:** `bash .codex/aid/scripts/grade.sh --explain <verify-ledger>`.
   If it is not clean, loop back to REVIEW so the first reviewer revises (drop ungrounded
   findings, add missed ones). **Circuit-breaker: 3 cycles** -> write
   `.aid/{work}/IMPEDIMENT-review.md`, set STATE `lifecycle: Blocked` with a block reason,
   and surface it instead of looping.

Note: the *target's* grade (`grade.sh --explain` on the review ledger) is computed for
the presentation as information only -- it does NOT drive a fix loop here.

**Advance:** PRESENT-FINDINGS.

---

## State: PRESENT-FINDINGS  (always a hard stop -- human final say)

Set STATE `lifecycle: Paused-Awaiting-Input`. Present:

- the **target grade** (from `grade.sh` on the review ledger) -- informational;
- the **verified findings**, severity-ranked, each with its `file:line` / KB evidence;
- **recommendations**, and a **printed suggestion** to act: "N issues found -- run
  `/aid-fix` (or `/aid-change`) to address them" (review never starts the fix itself);
- the **proposed delivery action + the exact comment/notes text** that would be posted.

Then STOP and await the human's decision (approve / edit the text / choose a different
delivery / do not publish). Nothing is posted to any external target until they approve.

**Advance:** PUBLISH on approval; otherwise DONE.

---

## State: PUBLISH  (only on approval)

Deliver by the method appropriate to the target, chosen by judgment (not a hardcoded
enum): a PR comment via `gh`; a ticket comment via the MCP connector
(`connectors/consumption-protocol.md`, MCP-first); a findings report in the work folder
(+ optional inline-comment suggestions) for code; inline notes for a document. **Graceful
fallback:** no PR / no catalogued connector / unknown target -> present the exact text for
the human to paste. Publishing is optional and never blocks DONE.

**Advance:** DONE.

---

## State: DONE

Set STATE `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.
Leave the findings ledger on disk (`.aid/.temp/review-pending/<work>-review.md`) so a
follow-up `/aid-fix` can consume it. Keep the work folder as the audit record.

---

## Constraints

- **KB + source grounding is enforced** (VERIFY step 1 + the reviewer RUBRIC): no finding
  without a KB/source cite.
- **Clean context:** the REVIEW and VERIFY dispatches never share context; the verifier
  never sees the reviewer's reasoning.
- **Reviews are always a sub-agent dispatch** (`aid-reviewer`), never inline.
- **Human final say before any external commit** (PRESENT-FINDINGS).
- **Read-only** on the reviewed artifact; never fixes (hand off to `/aid-fix`).
- **Tracking:** write STATE `lifecycle` at every transition (`Running` at INTAKE, the
  gate pauses, terminal `Completed`/`Blocked` at the end).

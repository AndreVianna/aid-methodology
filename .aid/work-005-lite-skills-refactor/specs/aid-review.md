# Behavioral Spec — `aid-review` / `aid-audit` Redesign

> **Status:** LOCKED for implementation (design agreed 2026-07-15). All open items settled ([§13](#13-settled-decisions)).
> **Tracked under:** `.aid/work-005-lite-skills-refactor/` (branch `work-005-lite-skills-refactor`).
> **Scope:** `aid-review` (canonical) + `aid-audit` (alias). First of the "clear
> mismatch" lite-skill redesigns; several sections here generalize to the other
> mismatch skills (see [§12](#12-what-generalizes-to-the-other-mismatch-skills)).
> **Not implemented yet** — this document is the contract the implementation must satisfy.

---

## 1. Problem

The stated objective and the actual behavior contradict each other.

- **Objective (catalog `intent` / skill `description`):** *"Review/assess an existing
  artifact — code, a change/diff, or a design — against criteria; produce **findings +
  recommendations**."*
- **Actual behavior today:** `/aid-review <target>` is a thin doorway over the
  direct-entry shortcut engine (`canonical/aid/templates/shortcut-engine.md`). It runs
  `INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT` — **~5 Opus
  dispatches** (4 × `aid-architect` authoring + ≥1 × `aid-reviewer` at GATE) — to
  *plan a review as a piece of future work*, emitting a flattened `work-NNN` with
  `REQUIREMENTS/SPEC/PLAN/BLUEPRINT/DETAIL` and a single `RESEARCH` task, then **halts
  before the review is ever performed**. The review would only run later under a
  separate `/aid-execute`.

Net: the user asks for a review, waits through five Opus dispatches, and receives **no
findings** — only a planning package describing a review that hasn't happened. This is
both the red-tape problem (#1) and the over-provisioning problem (#2) in one skill.

## 2. Objective (locked)

`/aid-review <target>` **performs the review now** and returns **grade + findings +
recommendations**, grounded in the KB and the project source, with the human holding
final say before anything is written back to the reviewed target.

## 3. Topology change

Mirrors the proven `aid-query-kb` / `aid-ask` precedent (hand-authored, `repurpose:
true`, registered for parity + `/aid-triage`, skipped by `build-shortcut-skills.py`).

- Flip the catalog rows `aid-review` and `aid-audit` to **`repurpose: true`** in
  `canonical/aid/templates/shortcut-catalog.yml` so the build helper stops
  generating/overwriting their `SKILL.md`.
- Hand-author `canonical/skills/aid-review/SKILL.md` per this spec.
- `aid-audit` becomes a **thin hand-authored alias** → `aid-review` (exactly like
  `aid-ask` → `aid-query-kb`): same behavior, its own `SKILL.md`, one-line body
  delegating to `aid-review`.
- Keep `default_type: RESEARCH` and `group: G11` on both rows (used by `/aid-triage`).
- Remove `review` / `research` from the shortcut-engine's Family-file grouping table
  and Default-Type mapping **only if** no engine-driven verb still needs
  `analyze-report.md` (research/report still do — so leave that scaffolding intact;
  just detach the two review rows).

## 4. Invariants (non-negotiable)

1. **KB + source grounding is enforced, not requested.** Every finding MUST cite a KB
   doc and/or a `file:line` in its `Evidence` column. Enforcement is two-layer:
   (a) a mechanical check rejects any finding row with an empty `Evidence` cell;
   (b) the VERIFY pass re-checks each finding against the KB + source. An ungrounded
   finding cannot reach the human.
2. **Clean context.** The REVIEW and VERIFY dispatches each run in a fresh context;
   the verifier never sees the reviewer's reasoning
   (`architecture.md § Agent / Sub-Agent Dispatch Model`).
3. **Reviews are always a sub-agent dispatch** (`aid-reviewer`), never inline — global
   rule (`CLAUDE.md`, `reviewer-dispatch.md`).
4. **Human final say before any commit.** No durable side effect on the *target* or any
   external system (PR comment, ticket comment, edit to the reviewed doc/code, git
   commit) happens until the human approves at PRESENT-FINDINGS. Writing the findings
   ledger/report *into the work folder* is the work's own record and is **not** a
   "commit" in this sense.
5. **Review output uses the global 7-column ledger schema**
   (`reviewer-ledger-schema.md`): `# | Severity | Status | Doc | Line | Description |
   Evidence`, written to `.aid/.temp/review-pending/<scope>.md`.

## 5. State machine

```
INTAKE
  ├─ explicit resolvable target?  ──yes──▶ (FAST PATH) ───────────────┐
  └─ no ─▶ interpret → PROPOSE-PLAN → [validate w/ user] ─────────────┤
                                                                       ▼
REVIEW      (aid-reviewer, clean context, KB+source grounded → 7-col ledger)
  ▼
VERIFY      (2nd aid-reviewer, clean context; grades the REVIEW; bounded loop) ⤾
  ▼
PRESENT-FINDINGS   ── ALWAYS stop: grade + findings + proposed delivery ──  [human final say]
  ▼
PUBLISH     (only on approval; delivery method chosen by agent judgment per target)
  ▼
DONE
```

- **Guided path** = up to two human stops (plan, then findings).
- **Fast path** = one human stop (findings only). Skips *only* the up-front plan gate;
  never skips grounding, VERIFY, or the pre-publish approval.

## 6. States in detail

### INTAKE

1. **Require a target.** If the argument is empty, ask one bootstrapping question
   ("What do you want to review?") and wait. (A review with no target is meaningless —
   one question, not usage-and-exit.)
2. **Detect an explicit, resolvable target** (see the fast-path table in [§7](#7-fast-path-triggers-locked)).
   - **Resolves + method unambiguous → FAST PATH.** Record the target, the review
     method, and the tentative delivery; go straight to REVIEW.
   - **Does not resolve, or method is open-ended → GUIDED PATH.** The controlling agent
     interprets the request and forms a plan: *what* it will review, *how* (method +
     any tool/MCP it needs to gather evidence), and *where/how* findings will be
     delivered. It presents the plan and **waits for the user to confirm or correct**
     before spending review effort.
   - A fast trigger that fails to resolve (file absent, ticket ID but no catalogued
     connector, PR # with no repo context) **falls back to the guided path** rather
     than guessing.
3. **Classify complexity** → sets the REVIEW/VERIFY model+effort (see [§9](#9-modeleffort-tiering-problem-2)).
4. **Allocate the work folder.** `.aid/work-NNN-<slug>/` with a `STATE.md` from the
   normal work-state template (see [§10](#10-work-folder--tracking)). Optionally
   associate a **git worktree** when the review will produce working artifacts or run
   tools that could touch the tree (a pure read-only review needs no worktree).
5. **Criteria.** Derive review criteria from the KB (`coding-standards.md`,
   `architecture.md`, the artifact's own acceptance criteria if it is AID work) plus
   anything the user named. On the fast path this is implicit (no extra turn); on the
   guided path it is part of the plan the user confirms.

### REVIEW

Gather any evidence the confirmed method needs (the controlling agent uses whatever
tools/MCP the plan calls for — e.g. drives Playwright to capture a UI, runs `git diff`,
fetches a ticket via its MCP connector), then dispatch **`aid-reviewer` once, in clean
context**, with the standard one-off 5-section brief
(`ARTIFACTS UNDER REVIEW / CONTEXT / RUBRIC / OUT OF SCOPE / OUT-OF-SCOPE FINDINGS
POLICY`, per `reviewer-dispatch.md § One-off reviews`). The brief MUST mandate reading
`.aid/knowledge/` + the relevant source and citing KB/source in every finding. Output:
the 7-column ledger at `.aid/.temp/review-pending/<scope>.md`.

### VERIFY ("who reviews the reviewer")

1. **Mechanical grounding check** (no dispatch): reject/return any finding row whose
   `Evidence` cell is empty.
2. **Adversarial verification** — dispatch a *second* `aid-reviewer` in clean context
   (never sees the first reviewer's reasoning) to independently check the ledger against
   KB + source: flag ungrounded / hallucinated / mis-severity findings **and material
   gaps** (issues the first pass missed). Output: a *review-quality* ledger.
3. **Grade the review** — `grade.sh --explain <review-quality-ledger>`. If it is not
   clean, loop back to REVIEW so the first reviewer revises (drops ungrounded findings,
   adds missed ones). **Bounded: circuit-breaker at 3 cycles** → write an IMPEDIMENT and
   surface to the user rather than looping forever.

### PRESENT-FINDINGS (always a hard stop)

Show the user:
- the **target grade** (from `grade.sh` on the target ledger — *informational only*);
- the **verified findings**, severity-ranked, each with `file:line` / KB evidence;
- **recommendations**, and the bridge to the gated mutation skills — a **printed
  suggestion** to run `/aid-fix` or `/aid-change` (see [§13](#13-settled-decisions) —
  review never starts the fix itself);
- the **proposed delivery action + the exact comment/notes text** that would be posted.

Then **STOP** and await the human's decision (approve / edit / choose a different
delivery / do not publish).

### PUBLISH (only on approval)

Deliver the findings by the method appropriate to the target — chosen by **agent
judgment**, not a hardcoded enum. Illustrative, **non-exhaustive** patterns:

| Target (example) | Typical delivery |
|---|---|
| PR | inline / summary PR comment(s) via `gh` (direct CLI) |
| Issue/ticket | ticket comment via the **MCP-first** connector path (`consumption-protocol.md`) |
| Code (no PR) | findings report in the work folder (+ optional inline-comment suggestions) |
| Document | inline notes / suggestions in the doc |
| Anything else | agent picks a sensible delivery and proposes it at PRESENT-FINDINGS |

Graceful fallback: no PR / no catalogued connector / unknown target → present the exact
text for the human to paste. Publishing is always optional and never blocks DONE.

### DONE

Finalize `STATE.md`; keep the work folder as the audit record. Leave the ledger on disk
for a potential follow-up `/aid-fix` to consume (mandated format + a real downstream
consumer, so it is not stray "crud").

## 7. Fast-path triggers (locked)

General rule: **an explicitly resolvable target + an unambiguous method** → fast path.

| Signal in the prompt | Review method | Proposed delivery (approved at findings gate) |
|---|---|---|
| PR link / `#123` | diff review | PR comment(s) via `gh` |
| Jira/issue ID (`PROJ-45`) | assess ticket content | ticket comment via MCP connector |
| File / dir path | static review vs KB + coding-standards | findings report (+ optional inline) |
| "my changes" / working tree / staged | working-diff review | findings report |
| Commit SHA / range / branch | diff review | findings report or PR comment |
| `work-NNN` or an AID artifact (SPEC/PLAN/DETAIL/BLUEPRINT) | review vs its acceptance criteria + KB | findings in the work folder |
| A KB doc (`.aid/knowledge/*.md`) | review vs KB-authoring rubric | findings report |

Anything not matching → guided path. A non-resolving fast trigger → guided path.

## 8. Grading model (two grades; only one gates)

- **Target grade** — `grade.sh` on the *target* ledger (findings → grade). **Output
  only**; it does not drive a fix loop. Fixing the target is `/aid-fix`'s job, not
  review's.
- **Review grade** — `grade.sh` on the *review-quality* ledger from VERIFY. **This is
  the gate**: it drives the bounded REVIEW↔VERIFY loop so the review is grounded,
  complete, and correct before the human sees it.

Both reuse the existing `grade.sh` + `reviewer-ledger-schema.md` machinery unchanged;
only the artifact under the grade differs.

## 9. Model/effort tiering (problem #2)

`aid-reviewer` is always the reviewing agent (role consistency + clean context +
"reviews always sub-agent"). The skill classifies review complexity and **overrides the
dispatch model + effort per call** — the Agent-tool override takes precedence over the
agent's frontmatter `tier` **without** changing the shared agent (so the full pipeline,
which uses `aid-reviewer` at every GATE, is untouched).

| Complexity | Trigger examples | Model | Effort | VERIFY |
|---|---|---|---|---|
| Simple | one small file, a short doc, a tiny diff | sonnet | low/medium | single light pass |
| Standard/complex | full PR, a design, security/perf, multi-file | opus | high | full bounded loop |

Invariant preserved: **verifier tier ≥ reviewer tier**.

**Dispatch-count delta:** today ~5 Opus (fixed). After: **~2 dispatches (review +
verify), tiered** (as low as 2 × sonnet for a simple review). That is the concrete
answer to problem #2 for this skill.

## 10. Work folder & tracking

- **Reuse the normal work-state template** (`work-state-template.md`) — *settled, see
  [§13](#13-settled-decisions)*. No new template. INTAKE allocates
  `.aid/work-NNN-<slug>/STATE.md` and tracks the review through `lifecycle`
  (`Running` → `Paused-Awaiting-Input` at each human gate → `Completed`) plus this
  skill's own states in `## Lifecycle History`.
- The 7-phase pipeline `phase` scalar does not meaningfully apply to a standalone review
  (a review is not a pipeline run). It is left at its scaffold value / not driven; the
  pipeline machinery (`writeback-state.sh --pipeline`) is used only for `lifecycle` /
  `updated` / the pause fields. *(This "standalone-skill uses the normal template but
  doesn't drive `phase`" convention is shared by every mismatch skill — [§12](#12-what-generalizes-to-the-other-mismatch-skills).)*
- State is written at **every** transition (tracking IMPERATIVE — binds the controlling
  agent directly): `Running` at INTAKE, the gate pauses, terminal `Completed` at the end.
- Worktree association is opt-in (see INTAKE §4).

## 11. Files the implementation will touch

1. `canonical/aid/templates/shortcut-catalog.yml` — set `repurpose: true` on
   `aid-review` and `aid-audit`.
2. `canonical/skills/aid-review/SKILL.md` — replace generated body with the
   hand-authored single-shot skill per this spec.
3. `canonical/skills/aid-audit/SKILL.md` — hand-authored thin alias → `aid-review`.
4. `canonical/aid/templates/shortcut-engine.md` — detach the two review rows from the
   family-grouping / default-type tables (leave research/report scaffolding intact).
5. Regenerate: `build-shortcut-skills.py` (confirm it now skips the two rows) → full
   `run_generator.py` → resync dogfood `.claude/` from `profiles/claude-code/`
   (test-dogfood-byte-identity enforces it).

## 12. What generalizes to the other mismatch skills

Carry these forward when we do `research/investigate/spike`, `report`, `experiment`,
`document*` (and revisit `prototype*` / `test*`):

- **Hand-authored, `repurpose: true`, single-shot** replaces engine-generated planning.
- **Produce the deliverable now**, gate the human where a *durable/external side effect*
  happens — not before the work is done.
- **Fast path vs guided path** keyed on whether the request carries an explicit
  resolvable target.
- **Per-call model/effort tiering** by complexity, overriding the agent's frontmatter
  without touching shared-agent tiers.
- **Standalone-skill STATE convention** — reuse the normal work-state template; track
  `lifecycle` + the skill's own steps; do not drive the 7-phase `phase` scalar (§10).

## 13. Settled decisions

Resolved with the user 2026-07-15:

1. **Tracking file** → **reuse the normal work-state template** (phase not driven; the
   anti-over-engineering choice — no new template). Folded into §10.
2. **Fix handoff** → **printed suggestion only** ("run `/aid-fix` …"); the review stays
   strictly read-only and leaves the ledger on disk for `/aid-fix` to pick up. Folded
   into §6 (PRESENT-FINDINGS / DONE).
3. **Where the effort lives** → **tracked as `work-005-lite-skills-refactor`** (folder +
   branch) from the start. This document now lives under that work folder.

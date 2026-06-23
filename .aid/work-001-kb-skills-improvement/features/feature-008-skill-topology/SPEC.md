# Skill Topology

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-26, FR-27, FR-28) | /aid-interview |

## Source

- REQUIREMENTS.md §5.G (FR-26, FR-27, FR-28) — author/behavior side
- REQUIREMENTS.md §1.8 (skill topology, the freshness loop's signal-capture hole), §2.8 (P8)
- §4 S7, §10 (Should)

## Description

This feature fills the skill-topology gaps in the KB lifecycle. It **renames
`aid-ask` → `aid-query-kb`** (the read/query side; behavior preserved, clearer
name). It adds a new **`aid-update-kb`** skill for **targeted / punctual** KB
updates — the "second pass" for the precise deltas a finished work introduced —
applied through the same review/calibration gate as `aid-discover` (so quality is
not bypassed for small updates), because `aid-housekeep`'s KB-DELTA is too broad
for an end-of-work diff. Finally, `aid-query-kb` is made to **capture gaps** ("KB
can't answer" / "KB contradicts code") into a KB-gap queue consumed by
`aid-update-kb` / `aid-housekeep` — turning the single best free drift signal,
which `aid-ask` discards today, into a captured input.

This feature is the **author/behavior side** of the topology: the SKILL.md
definitions, state machines, and behavior. The cross-tree render, orphan-prune, and
install-manifest lockstep for the rename/add are handled by f009.

## User Stories

- As an **AID maintainer**, I want a targeted `aid-update-kb` skill so that a
  finished work's known deltas can be applied through the review gate without a
  heavy full housekeep sweep or hand-editing.
- As an **AID adopter**, I want `aid-ask` renamed to `aid-query-kb` with behavior
  preserved so that the read side has a clear name and keeps working.
- As a **doc owner**, I want a failed `aid-query-kb` query to enqueue a gap so that
  the cheapest, most accurate freshness signal is captured instead of discarded.

## Priority

Should

## Acceptance Criteria

- [ ] Given the read-side skill, when it is invoked, then `aid-ask` has been renamed
  to `aid-query-kb` with behavior preserved. *(FR-26, AC8)*
- [ ] Given a prompt-driven targeted update, when `aid-update-kb` runs, then it
  applies the update through the same review/calibration gate as `aid-discover`.
  *(FR-27, AC8)*
- [ ] Given a query the KB cannot answer (or that contradicts code), when
  `aid-query-kb` runs, then it enqueues a gap into the KB-gap queue consumed by
  `aid-update-kb` / `aid-housekeep`. *(FR-28, AC8)*

> Cross-cutting note: the rename/add must follow the content-isolation cornerstone
> (aid- prefix, manifests) and the thin-router SKILL.md + references/ state-machine
> convention (C6, C8). The ship-side propagation (render, orphan-prune, manifest
> lockstep) is f009.

---

## Technical Specification

> Skill-topology feature — the **author/behavior side** of the freshness loop's
> read/update halves. It (1) renames `aid-ask` → `aid-query-kb` (behavior preserved),
> (2) adds a new `aid-update-kb` thin-router state machine for prompt-driven targeted
> KB updates through f005's review gate, and (3) makes `aid-query-kb` capture query
> gaps into the existing `STATE.md ## Q&A (Pending)` backlog. **This feature touches
> `canonical/` source only.** The cross-tree render to the 5 host trees, the orphan-prune
> of the old rendered `aid-ask` dirs, the 5 install manifests, the "N user-facing skills"
> KB counts, and the docs site are **f009** (skill-change-propagation) — f008 does the
> canonical-source rename + the new canonical skill; **f009 propagates and ships them.**
> Every design decision below is grounded against the files cited inline; genuine unknowns
> are flagged **[SPIKE]**, not guessed.

### Overview

This feature fills three skill-topology gaps (FR-26/27/28, AC8) on the **author side**:

1. **`aid-ask` → `aid-query-kb` rename** (FR-26). A straight rename of the canonical skill
   directory + `name:`/title + any internal self-references; the read-only single-shot Q&A
   behavior (`allowed-tools: Read, Glob, Grep, Agent`, no state machine, no work folder) is
   **preserved verbatim**.
2. **New `aid-update-kb` skill** (FR-27). A **thin-router `SKILL.md` + `references/state-*.md`**
   state machine (C8) whose input is a **prompt** (what to update) and whose flow is
   **ANALYZE → APPLY → REVIEW → APPROVAL → DONE**: it analyzes which KB docs the prompt
   implies and the deltas, applies targeted summary+pointer edits (native-language
   consistency, restamping `sources:`/`approved_at_commit:`), grades the changed docs
   through **f005's review/calibration panel scoped to the changed docs**, and applies the
   change only on **human approval** (NFR-6/C4 — no auto-apply). This is the human-gated
   UPDATE half of the freshness loop.
3. **Gap capture** (FR-28). When `aid-query-kb` hits a gap ("the KB can't answer" / "the KB
   contradicts the code"), it appends a tagged entry to the **existing
   `STATE.md ## Q&A (Pending)` backlog** — the same queue scout-questions and `aid-housekeep`
   already use — consumed by `aid-update-kb` / `aid-housekeep`. **No new queue file is invented.**

**Confirmed design decisions this spec builds on (user-approved; not re-litigated):**
`aid-update-kb` is a prompt-driven thin-router (ANALYZE → APPLY → REVIEW → human-gated
approval) reusing f005's panel; `aid-ask` → `aid-query-kb` is a straight rename with behavior
preserved; gap capture reuses the existing `STATE.md ## Q&A (Pending)` backlog tagged as a
query-gap.

**Boundaries (what this feature does NOT do).**

- **Cross-tree propagation / ship = f009.** Rendering the renamed/new skill to the 5 host
  trees (`run_generator.py`), orphan-pruning the old rendered `aid-ask/` directories,
  updating the 5 install manifests, reconciling the "N user-facing skills" counts across the
  ~10 KB docs (the Q26/Q30 drift class — note-memory `adding-skill-kb-count-drift`), and the
  docs site — all **f009**. f008 edits `canonical/` only; **render-drift will be RED on the
  f008 branch by construction** until f009 runs the generator (f009 owns making it green).
- **f005's REVIEW gate is REUSED, not re-spec'd.** `aid-update-kb`'s REVIEW state **invokes
  the same five-mandate panel + teach-back + calibration machinery f005 builds**
  (`aid-discover/references/state-review.md`, the `reviewer-prompt-*.md` mandate bodies,
  `grade.sh`, the teach-back exit) scoped to the changed docs. f008 wires the call; it does
  not redefine the panel.
- **The `aid-housekeep` ↔ `aid-update-kb` boundary** (source-driven-global vs
  prompt-driven-targeted, FR-33) is enforced in **f010**. f008 builds `aid-update-kb`'s
  prompt-driven-targeted behavior and references the boundary; f010 draws the line and the
  closure-re-verification (FR-34) shared contract.
- **The freshness suspect verdicts** `aid-update-kb` consumes to scope which doc a delta
  touched are **f007**'s `kb-freshness-check.sh` output (consumed, not built here). The
  `sources:`/`approved_at_commit:` frontmatter schema is **f001**'s (consumed, not redefined).

---

### Part 1 — `aid-ask` → `aid-query-kb` rename (FR-26)

**Scope: canonical source only.** The single canonical source today is
`canonical/skills/aid-ask/SKILL.md` (confirmed: the canonical `aid-ask/` dir contains **only**
`SKILL.md` — no `references/`, no agent-default file). A repo-wide grep confirms **`aid-ask`
appears in `canonical/` in exactly one file** (`canonical/skills/aid-ask/SKILL.md`); there is
no canonical agent that hard-codes `aid-ask` as a default. So the f008 rename change-set is
small and self-contained.

**The change-set (canonical only):**

| # | Change | From | To |
|---|--------|------|----|
| R1 | Rename the skill directory | `canonical/skills/aid-ask/` | `canonical/skills/aid-query-kb/` |
| R2 | Frontmatter `name:` | `name: aid-ask` | `name: aid-query-kb` |
| R3 | `description:`/`argument-hint:` self-reference | `/aid-ask` mentions in the description + usage examples | `/aid-query-kb` |
| R4 | Body self-references | every `/aid-ask` / "aid-ask" / the `Usage: /aid-ask <question>` pre-flight line + the example file-path citation `.claude/skills/aid-ask/SKILL.md` (SKILL.md line 72) | `/aid-query-kb`, `.claude/skills/aid-query-kb/SKILL.md` |
| R5 | References dir | *(none today — no `references/` exists)* | *(none added; behavior stays single-shot — see below)* |
| R6 | Agent default | *(none — no canonical agent hard-codes `aid-ask`)* | *(no change; verify via the grep gate below)* |

**Behavior is preserved verbatim.** The renamed skill keeps:
`allowed-tools: Read, Glob, Grep, Agent` (read-only — no Write/Edit/Bash); the
**single-shot, no-state-machine** pass (classify → answer inline or dispatch `aid-researcher`
read-only → emit `## Answer` / `## Sources`); the "no work folder, no STATE.md for its own
use" rule; the source-citation discipline; the read-only-dispatch instruction. **The only
substantive behavior addition is gap capture** (Part 3) — and that addition keeps the skill
read-only-to-the-KB (it writes only an append to a work `STATE.md ## Q&A (Pending)` backlog,
not to any KB doc), which requires adding `Write`/`Edit` to `allowed-tools` (the one
frontmatter change beyond the rename — see Part 3 for the exact grant + scoping).

**Verification gate (in-feature).** A grep guard asserts the rename is total within
`canonical/`: after the edit, `grep -rn 'aid-ask' canonical/` MUST return **zero** matches
(the dir is gone, the SKILL.md self-references are rewritten). This is the f008 acceptance
check for R1–R6; the cross-tree equivalent (rendered trees + manifests + KB counts) is
**f009**'s gate, not f008's.

> **Propagation note (f009, NOT f008).** Rendering `aid-query-kb` to the 5 host trees,
> deleting the orphaned rendered `aid-ask/` directories, updating the 5 install manifests,
> bumping the "N user-facing skills" counts across the ~10 KB docs (architecture, module-map,
> feature-inventory, project-structure, integration-map, repo-presentation, pipeline-contracts,
> domain-glossary, coding-standards, KB README — the exact Q30 scope, now `aid-ask` → renamed
> + `aid-update-kb` added = a net **+1** skill plus one rename), and the docs site — all
> **f009**. f008's branch leaves render-drift RED by design; f009 makes it green.

---

### Part 2 — `aid-update-kb` skill (FR-27)

`aid-update-kb` is a new **thin-router skill** (C8) — a small `SKILL.md` (frontmatter +
state-detection + a Dispatch table) that routes into one `references/state-*.md` reference doc
per state, matching the `aid-housekeep` / `aid-discover` shape exactly. The state machine is
**ANALYZE → APPLY → REVIEW → APPROVAL → DONE** (with a FIX loop inside REVIEW, reusing
`aid-discover`'s FIX/REVIEW cycle).

#### The prompt contract (input)

```
/aid-update-kb "<what to update>"
```

The argument is a **free-form prompt** describing the delta to fold into the KB — typically a
finished work's known changes (e.g. "work-003 added the content-isolation cornerstone: the
AID:BEGIN/END boundary in root agent files and prefix-based orphan-prune"). The prompt is the
*scoping seed*; ANALYZE turns it into a concrete set of (doc, change) pairs. If no prompt is
supplied, the skill prints a usage line and exits (mirroring `aid-ask`'s pre-flight):

```
Usage: /aid-update-kb "<what changed / what to update in the KB>"
Example: /aid-update-kb "work-003 added the content-isolation cornerstone (AID:BEGIN/END boundary)"
```

`aid-update-kb` is an **optional, off-pipeline skill** (like `aid-housekeep` / `aid-ask`): not
in the numbered phase-to-skill pipeline, no phase gate references it. Its run-state lives in a
**transient project-level run-state file** under `.aid/.temp/` (the `aid-housekeep` precedent —
`UPDATEKB_STATE_<ts>.md`, gitignored, removed at DONE), NOT in any work `STATE.md`; the KB it
edits has its own `.aid/knowledge/STATE.md` for review/approval history.

`allowed-tools` for the skill: `Read, Glob, Grep, Bash, Write, Edit, Agent` (it edits KB docs
in APPLY, runs the deterministic helpers + `grade.sh` in ANALYZE/REVIEW, and dispatches the
review panel — same grant shape as `aid-housekeep`).

#### State machine

```
aid-update-kb  ▸ one step per run
  [ ANALYZE ] → [ APPLY ] → [ REVIEW ] → [ APPROVAL ] → [ DONE ]
                              ▲     │
                              └─FIX─┘   (REVIEW→FIX→REVIEW until grade>=min AND teach-back PASS)
```

| State | Reference doc | Worker | Advance |
|-------|---------------|--------|---------|
| ANALYZE | `references/state-analyze.md` | inline (Read/Glob/Grep + `kb-freshness-check.sh`) | CHAIN → APPLY (or PAUSE if the prompt is un-groundable → Q&A escalation) |
| APPLY | `references/state-apply.md` | inline (Edit) or `aid-architect`/`aid-researcher` for the owning doc-set | CHAIN → REVIEW |
| REVIEW | `references/state-review.md` (REUSES f005's panel — see below) | `aid-reviewer` panel (f005) | CHAIN → FIX if below gate; CHAIN → APPROVAL if grade>=min AND teach-back PASS |
| APPROVAL | `references/state-approval.md` | inline | PAUSE-FOR-USER-ACTION (human gate) → DONE on approval |
| DONE | `references/state-done.md` | inline | HALT (restamp `approved_at_commit:`, commit on a branch, clean run-state) |

**ANALYZE (`state-analyze.md`) — prompt → (doc, change) set.**

1. Load `.aid/knowledge/INDEX.md` (the routing table) to map the prompt onto candidate KB
   docs by Objective/Tags/Audience (f002's table; the same navigation `aid-ask` uses today).
2. Run `kb-freshness-check.sh --root .aid/knowledge --format tsv` (f007) to fold the prompt's named sources against
   per-doc **suspect** verdicts — the prompt names *what* changed; the freshness check confirms
   *which docs' `sources:` actually drifted*. The intersection (prompt-implied docs ∩ suspect
   docs) is the targeted scope; a prompt-named doc with no drift is still in scope if the
   prompt asserts a *content* change the freshness check can't see (e.g. a new concept).
3. For each candidate doc, read it + its `sources:` and decide the concrete change: a new
   summary+pointer entry, a corrected fact, a new `sources:` entry, or a new concept added to
   the spine (`domain-glossary.md`). Emit a **change plan** (the (doc, change) list) into the
   run-state file.
4. **Closure & escalation (FR-32/FR-34 hook).** If the prompt introduces a project-specific
   concept that **cannot be grounded from the artifacts**, ANALYZE does **not** invent it — it
   **escalates a Q&A to the human** by appending an entry to `.aid/knowledge/STATE.md
   ## Q&A (Pending)` (Category `Update-KB / Ungroundable Concept`, Impact `Required`, Status
   `Pending`) and PAUSEs. This reuses the exact escalation mechanism FR-32 / Part 3 use.

**APPLY (`state-apply.md`) — targeted summary+pointer edits + restamp.**

1. For each (doc, change) in the change plan, make a **targeted edit**: a *summary+pointer*
   edit at the KB altitude (the synthesized *why/how-it-relates* + a durable pointer to the
   `sources:` entry), **not** a transcription of the source (the calibration discipline f005
   grades — APPLY authors to pass CAL-1/CAL-2, REVIEW enforces it). Preserve the doc's
   **native language / concept spine** — reuse the project's coined terms from
   `domain-glossary.md`, do not introduce generic synonyms (the closure invariant FR-34).
2. **Update `sources:`** if the change adds a new underlying source (append the repo-relative
   path/glob/URL per f001's schema).
3. **Do NOT restamp `approved_at_commit:` in APPLY.** `approved_at_commit:` is the *approval*
   baseline (f001: "written by `aid-discover`/`aid-update-kb` on approval, never hand-authored").
   It is restamped in **DONE**, after the human gate (APPROVAL), to the commit that records the
   approved edit — so a doc edited-but-not-yet-approved is correctly *suspect/unknown* to f007,
   never falsely *current*. (This is the precise FR-27 ↔ NFR-6 interplay: APPLY changes content;
   only post-approval DONE moves the freshness baseline.)
4. Edits are made **in place** on the canonical KB docs under `.aid/knowledge/` (the adopter's
   KB — `aid-update-kb` is a KB-maintenance skill run in any AID repo, not a `canonical/`
   template edit). Work happens on an `aid/update-kb-*` branch (the `aid-housekeep`
   branch-per-run precedent); the skill **never pushes** (human pushes / opens the PR).

**REVIEW (`state-review.md`) — REUSE f005's panel, scoped to the changed docs.**

This state **does not redefine review** — it **invokes f005's review/calibration gate**
(FR-27's "the same review/calibration gate as `aid-discover`"). Concretely it reuses
`aid-discover/references/state-review.md`'s machinery with **`{{ARTIFACTS}}` scoped to the
changed-doc set** (the (doc, change) list from APPLY) instead of the full `discovery.doc_set`:

- Render f005's universal reviewer brief once; dispatch the **five mandate `aid-reviewer`
  sub-agents** (Correctness, Anatomy/Coverage, Concept-closure, Teach-back, Calibration) **in
  parallel** against the changed docs, each writing its per-mandate scratch ledger.
- **Merge** the five per-mandate scratch ledgers into the single canonical ledger
  `.aid/.temp/review-pending/update-kb.md`, **then delete the scratch ledgers** (f005's
  merge-then-delete model) (a distinct `<scope>` from discovery's
  `discovery.md`, per the reviewer-ledger schema's one-`<scope>.md`-per-invocation rule), run
  the **unchanged `grade.sh`**, and evaluate the **teach-back hard gate**.
- **Exit rule (identical to f005):** `READY iff grade(update-kb.md) >= minimum_grade AND
  teachback_verdict == PASS`. `minimum_grade` resolves via
  `read-setting.sh --skill update-kb --key minimum_grade --default A` (a new skill key,
  defaulting to A like discover).
- **Teach-back scope note [SPIKE-1].** f005's teach-back is a *whole-KB clean-context* exit
  (a fresh agent given ONLY the KB explains the engine). For a **targeted** update, re-running
  full whole-KB teach-back on every small delta may be heavier than the change warrants.
  **Open design choice:** does `aid-update-kb` REVIEW run (a) the **full** teach-back exit
  (strongest, guarantees the delta didn't break whole-KB closure — aligns with FR-34
  "re-verify closure after they change the KB"), or (b) a **scoped** teach-back limited to the
  concepts the changed docs define/reference? This spec's default is **(a) full teach-back**
  (FR-34 demands closure re-verification, and the teach-back question set is mechanically
  generated so the cost is one clean-context dispatch, not five), with (b) as the f010-tunable
  optimization if the full exit proves too costly. Flagged for PLAN/f010 confirmation.
- **FIX loop.** Below-gate findings route to `aid-discover`'s existing FIX state
  (`state-fix.md`) over `update-kb.md`, re-REVIEW until the gate passes — the identical
  REVIEW↔FIX cycle, no new loop invented.

**APPROVAL (`state-approval.md`) — the human gate (NFR-6/C4/AC13).**

Detection/grading is automatic; **the change to KB content is human-gated**. APPROVAL presents
the diff summary (which docs changed, the grade, teach-back verdict) and asks the user to
confirm — reusing `aid-discover/references/state-approval.md`'s pattern (`[1] Approved` /
`[2] Additional consideration`). On `[1]`, advance to DONE; on `[2]`, record the consideration
as a Q&A entry and loop back. **No auto-apply path exists** — the skill cannot reach DONE
(restamp + commit) without an explicit human `[1]`.

**DONE (`state-done.md`).** Restamp each approved doc's `approved_at_commit:` to the commit
that records the approved edit (f001: generator-written on approval), commit on the
`aid/update-kb-*` branch, print the closing summary, and remove the transient run-state file.
**Closure re-verification (FR-34, shared with f010):** before committing, re-run the
deterministic closure check (f004's `closure-check.sh`) over the changed KB to confirm the
update left no native term undefined — a standing invariant, not a discovery-only check. (The
*boundary contract* of who-runs-closure-when between `aid-update-kb` and `aid-housekeep` is
**f010**; f008 wires `aid-update-kb`'s own re-verification.)

---

### Part 3 — Gap capture (FR-28)

When `aid-query-kb` cannot answer from its context — the "## Gap" branch that today's
`aid-ask` **prints and discards** (SKILL.md lines 116–136) — it now **also enqueues the gap**
into the **existing `STATE.md ## Q&A (Pending)` backlog**, turning the cheapest, most-accurate
drift signal into a captured input instead of throwing it away.

**Where it enqueues.** The same `## Q&A (Pending)` backlog that scout-questions, REVIEW Q&A,
and `aid-housekeep` already use — **no new queue file**. The target file is:

- If the query was about an **in-flight work**, that work's `.aid/work-NNN-*/STATE.md
  ## Q&A (Pending)` (the work whose state the query touched).
- Otherwise (a KB/codebase query with no single owning work), the **knowledge backlog**
  `.aid/knowledge/STATE.md ## Q&A (Pending)` (the same file Q30/Q26 used for the skill-drift
  Q&A).
- **Default when ambiguous:** `.aid/knowledge/STATE.md ## Q&A (Pending)` (the KB is the
  natural home for a KB-gap), and name the alternative in the entry's Context.

**Entry format** (the existing `### Q{N}` schema — Category/Impact/Status/Context/Suggested,
the canonical Q&A shape used throughout `STATE.md`), tagged as a **query-gap** so
`aid-update-kb`/`aid-housekeep` can filter for it:

```
### Q{N}
- **Category:** Query-Gap / <KB-cannot-answer | KB-contradicts-code>
- **Impact:** <High if KB-contradicts-code | Medium if KB-cannot-answer>
- **Status:** Pending
- **Context:** /aid-query-kb was asked "<question verbatim>". The available context could
  not answer it: <the specific gap — which KB doc lacks the data, OR the exact KB claim that
  contradicts the code with both citations>. Sources checked: <docs/paths>.
- **Suggested:** Run /aid-update-kb "<the gap as an update prompt>" (or fold into the next
  /aid-housekeep KB-DELTA) to close the gap, then REVIEW → APPROVAL.
```

`N` is the next free `Q{N}` in that backlog (the existing "never renumber, next free number"
convention). The two gap flavors map to Impact: a **KB-contradicts-code** gap is `High`
(the KB is actively wrong — a drift defect); a **KB-cannot-answer** gap is `Medium` (a
coverage hole, not a contradiction). The Category prefix `Query-Gap /` is the **filter tag**.

**Behavioral guard.** Gap capture is the **only** write `aid-query-kb` performs, and it writes
**only** to a `STATE.md ## Q&A (Pending)` backlog — **never** to a KB doc, never auto-applying
a fix (NFR-6/C4: capture-and-flag, never auto-apply). This requires adding `Write, Edit` to
the renamed skill's `allowed-tools` (the one frontmatter delta beyond the rename), with an
explicit constraint in the SKILL.md body: *"writes are restricted to appending a Query-Gap
entry to a `STATE.md ## Q&A (Pending)` section; no KB doc, settings, or code file is ever
written."* The answer path stays read-only; only the gap-append branch writes.

**Who consumes the gap (reference only — built elsewhere).**

- **`aid-update-kb`** (Part 2) — a doc owner reads the Query-Gap backlog and runs
  `/aid-update-kb "<the gap>"` to fold the fix through the review gate. (ANALYZE can also be
  seeded by reading open `Query-Gap` entries.)
- **`aid-housekeep`** (f010) — KB-DELTA's whole-KB reconcile can scan open `Query-Gap` entries
  as additional drift signals alongside the f007 per-doc staleness verdicts. Built in f010.

---

### Affected components

| Component | Path | Change |
|-----------|------|--------|
| Skill rename | `canonical/skills/aid-ask/` → `canonical/skills/aid-query-kb/` | R1–R6: rename dir; rewrite `name:`/title/self-references (incl. the `.claude/skills/aid-ask/SKILL.md` example citation); behavior preserved; add `Write, Edit` to `allowed-tools` for the gap-append (Part 3). |
| Gap capture | `canonical/skills/aid-query-kb/SKILL.md` (Step 3 "## Gap" branch) | On insufficient context, append a `Query-Gap`-tagged `### Q{N}` entry to the resolved `STATE.md ## Q&A (Pending)` backlog (work-NNN or `.aid/knowledge/STATE.md`); add the write-scope constraint. |
| **NEW** skill | `canonical/skills/aid-update-kb/SKILL.md` | Thin-router: frontmatter (`name: aid-update-kb`, `allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent`, argument-hint), prompt pre-flight, state-detection (transient `.aid/.temp/UPDATEKB_STATE_*.md` run-state, `aid-housekeep` precedent), Dispatch table ANALYZE→APPLY→REVIEW→APPROVAL→DONE. |
| **NEW** state refs | `canonical/skills/aid-update-kb/references/state-{analyze,apply,review,approval,done}.md` | One reference doc per state (Part 2). `state-review.md` REUSES f005's panel scoped to the changed docs; `state-approval.md` reuses `aid-discover`'s approval pattern; `state-done.md` restamps `approved_at_commit:` + re-verifies closure (FR-34). |
| **NEW** settings key | `.aid/settings.yml` (read via `read-setting.sh --skill update-kb --key minimum_grade --default A`) | The review gate's minimum grade for `aid-update-kb`; defaults to A (no settings-file edit required — `read-setting.sh` returns the default when the key is absent). |
| f005 REVIEW machinery | `canonical/skills/aid-discover/references/state-review.md`, `reviewer-prompt-*.md`, `grade.sh`, the teach-back generator | **REUSED, not modified.** `aid-update-kb`'s REVIEW reuses the same gate via f005's `{{ARTIFACTS}}`/`{{CONTEXT}}` placeholders (`{{ARTIFACTS}}` = changed docs, `<scope>` = `update-kb`). **BUT** f005's REVIEW currently **hard-codes** the ledger `<scope>` (`discovery.md`) and the `discovery.doc_set` resolution, so exposing the ledger-scope + doc-set as injectable params is a **PLAN-confirmed one-line seam in f005** — not "no change anticipated." See [SPIKE-2]. |
| Verification | (in-feature grep gate) | `grep -rn 'aid-ask' canonical/` returns zero after the rename; the new `aid-update-kb/` skill parses as a valid thin-router (frontmatter + Dispatch table present). |
| **Render / propagate / ship** | — | **f009** (NOT f008): `run_generator.py` to 5 trees, orphan-prune rendered `aid-ask/`, 5 install manifests, ~10 KB-doc "N user-facing skills" counts, docs site. f008's branch leaves render-drift RED by design. |

### Constraints

- **C8 — thin-router skill convention.** `aid-update-kb` follows the thin-router `SKILL.md` +
  `references/state-*.md` state-machine pattern (the `aid-housekeep`/`aid-discover` shape:
  frontmatter, state-detection, Dispatch table, one reference doc per state, one-step-per-turn
  visible discipline). `aid-query-kb` stays single-shot (no state machine — its rename
  preserves the existing optional-skill shape, which is a valid thin variant: a skill with no
  multi-state machine, like the original `aid-ask`).
- **C6 — content-isolation.** Both skills keep the `aid-` prefix; `aid-update-kb`'s run-state
  lives under the gitignored `.aid/.temp/`; its review scratch ledgers under
  `.aid/.temp/review-pending/update-kb*.md` (the existing isolated tree). The skill set's
  manifest/orphan-prune lockstep is **f009**.
- **C2 — ASCII-only (shipped scripts).** f008 adds **no new shipped script** (the deterministic
  helpers it calls — `kb-freshness-check.sh` (f007), `closure-check.sh` (f004), `grade.sh`,
  the teach-back question generator (f005) — are built in their own features). The SKILL.md /
  reference docs are markdown (not ASCII-gated), but kept ASCII for sibling consistency. If
  any inline `bash` snippet in a reference doc is non-trivial enough to vendor, it stays
  ASCII; PS-5.1 is N/A (bash).
- **NFR-6 / C4 / AC13 — human-gated.** `aid-update-kb` cannot apply a KB change without an
  explicit human `[1] Approved` at APPROVAL; `aid-query-kb` only **captures** a gap (one
  append to a Q&A backlog), never auto-fixes. Detection/grading is automatic; every content
  change is human-gated.
- **C3 / NFR-4 — render-drift (handled by f009).** All f008 edits are in `canonical/`. f008
  intentionally does **not** run `run_generator.py` — the render to the 5 trees, the
  orphan-prune of `aid-ask/`, and the manifest/KB-count reconciliation are **f009**'s job, so
  **render-drift is expected RED on the f008 branch** and goes green only when f009 runs. The
  PLAN must sequence **f008 before f009** (author-before-propagate) and gate the f008→f009
  hand-off so the skill set is never shipped half-renamed.
- **FR-33 / FR-34 boundary (f010).** `aid-update-kb` is prompt-driven-targeted (this feature);
  `aid-housekeep` is source-driven-global (existing). The non-overlap contract and the shared
  closure-re-verification (FR-34) are drawn in **f010**; f008 builds `aid-update-kb`'s targeted
  behavior + its own closure re-verify in DONE and references f010 for the boundary.

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-1] Teach-back scope for a targeted update.** Does `aid-update-kb` REVIEW run the
  **full** whole-KB clean-context teach-back exit (this spec's default — guarantees FR-34
  whole-KB closure re-verification, one mechanically-generated dispatch) or a **scoped**
  teach-back over just the changed docs' concepts (cheaper, but may miss a delta that breaks a
  far-doc's closure)? Default = full; the scoped optimization is f010-tunable. Confirm with
  PLAN/f010.
- **[SPIKE-2] f005 REVIEW parameterization seam.** `aid-update-kb`'s REVIEW reuses f005's
  `state-review.md` with `{{ARTIFACTS}}` = the changed-doc set and `<scope>` = `update-kb`.
  f005's REVIEW already substitutes `{{ARTIFACTS}}` (the doc list) and writes a `<scope>`
  ledger, so the reuse is **parameter substitution, not a f005 rewrite** — but confirm f005's
  authored `state-review.md` keeps `{{ARTIFACTS}}`/`<scope>` as injectable parameters (not
  hard-coded to `discovery.doc_set`/`discovery.md`). If f005 hard-codes them, f005 (or a thin
  shared `state-review.md`) needs a one-line parameterization; flag the dependency in PLAN.
  **Hard sequencing: f005 + f007 (and f004/f001 for the helpers) must land before f008's
  REVIEW/ANALYZE can call them** — degrade-gracefully if sequenced earlier (REVIEW falls back
  to the existing single-blended reviewer until f005 lands; ANALYZE skips the freshness fold
  until f007 lands), but the targeted-essence-gate value isn't realized until they do.
- **[SPIKE-3] Gap-capture target resolution.** The rule "work-NNN STATE.md if the query was
  about an in-flight work, else `.aid/knowledge/STATE.md`" is a heuristic. For an ambiguous
  query (touches both a work and the KB), the spec defaults to the **knowledge backlog** and
  names the alternative in Context. Confirm this default is acceptable, or whether the user
  should be asked which backlog (the `ask-user-over-auto-proof` memory leans toward asking for
  destructive actions — but a Q&A append is non-destructive, so the default-and-name approach
  is proportionate). Validated by f012's fixtures if a gap-capture fixture is in scope.
- **[SPIKE-4] f009 hand-off gate.** Because f008 leaves render-drift RED by design, the PLAN
  must make the f008→f009 hand-off an explicit gate (f009 cannot be skipped, or the repo ships
  a half-renamed skill set + stale KB counts). Confirm the PLAN sequences f009 immediately
  after f008 and that no release tag can be cut between them.

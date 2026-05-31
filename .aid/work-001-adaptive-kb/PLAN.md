# Plan — work-001-adaptive-kb (Adaptive, Project-Shaped KB)

> Sequences the 4 Ready feature SPECs into deliverables. Scope is P0 (correctness) + lean P1
> (declared doc-set); P2 dropped (out of scope), P3 deferred, P4 dropped (REQUIREMENTS §4).

## Deliverables

### delivery-001: P0 Correctness Baseline
- **What it delivers:** A discovery/KB tooling layer that is internally consistent — exactly
  one owner per doc (the `infrastructure.md`/`external-sources.md` contradictions reconciled),
  one non-drifting per-doc expectations source that the reviewer actually loads at dispatch
  (both REVIEW and FIX), and a template tree that matches the real doc-set (the orphan
  `ui-architecture.md` stub + stale profile-README rows removed/corrected). This is the clean,
  correct baseline that the declared doc-set in delivery-002 then replaces/honors.
- **Features:** feature-001-scout-ownership-reconcile, feature-002-expectations-consolidation,
  feature-003-orphan-stub-cleanup
- **Depends on:** —
- **Priority:** Must
- **Standalone-functional:** Yes. Three self-contained correctness fixes on disjoint files,
  each with its own non-regression gate (existing 13 canonical suites green + new guard suites:
  ownership-consistency, expectations-single-source) and clean render-drift across the 3
  profiles. The KB behaves identically for a standard project — the value is internal
  correctness, which stands on its own whether or not delivery-002 ever lands.
- **Detail hint (/aid-detail):** the three features touch disjoint files (F1 → agent-defs,
  F2 → expectations source, F3 → top-level template stub + profile READMEs) and are mutually
  parallel-safe; they can run as parallel task waves within this delivery, and only their
  *joint* completion gates delivery-002.

### delivery-002: Declared, Project-Shaped Doc-Set
- **What it delivers:** The KB doc-set shapes itself to the project, expressed as configuration.
  A project declares `discovery.doc_set` (pipe-delimited `filename|owner|presence` in
  `.aid/settings.yml`, read via the existing `read-setting.sh`); discovery honors it end-to-end
  (omit a doc → no agent dispatched → no hang; add a doc → dispatched to its owner); the fixed
  14/16 doc-count assumption is removed across the tooling; discovery proposes a project-shaped
  set from `project-index.md` and the user confirms/edits it; custom docs get a competent
  existing-agent owner + expectations and are generated and reviewed; and this repo's cycle-1
  carve-out is reproducible as config. Resolves tech-debt H5.
- **Features:** feature-004-declared-doc-set (FR-P1-1…6 + FR-P0-4)
- **Depends on:** delivery-001
- **Priority:** Must
- **Standalone-functional:** Yes. Builds directly on the clean baseline; ships the full lean-P1
  capability with its own canonical suites (declared-set parse/resolve, propose→confirm flow,
  mapping-honors-declared-set incl. no-hang-on-omission + dispatch-on-addition, carve-out-as-config,
  non-software mechanical assertion) plus existing-suite + render-drift non-regression.
- **Detail hint (/aid-detail):** feature-004's SPEC carries a documented split between its
  **deterministic core** (declared-set artifact + default seed + de-hardcode of the 14/16
  literals + agent-to-file mapping-honors-declared-set — all mechanically testable, no LLM) and
  its **derivation layer** (the LLM propose→confirm flow + custom-doc ownership — the one
  heuristic surface, behind the user-confirm safety net). Sequence these as two task waves:
  core first (de-risks + fully gated), then derivation on top. Also ratify F4 KNOWN ISSUES
  #2 (carve-out validated as the *resulting* set, not a literal baseline→delta) and #3 (the §8
  seed is synthesized from on-disk templates, not a hardcoded list) at build time.

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Shared dispatch surface.** F1 reconciles the ownership *truth* in the agent-defs and F3 mirrors it into the profile READMEs (both pinned to `state-generate.md:69–72` as source-of-truth — neither edits the table itself); F4 then rewrites that dispatch table into data-driven form and strips its count literals. F4's rewrite must rest on the reconciled truth. | H | The delivery-001 → delivery-002 order enforces this: F4 only rewrites the table after F1 has reconciled the ownership truth and F3 has mirrored it. Do **not** start delivery-002's dispatch-table work before delivery-001 is complete. |
| 2 | **Expectations contract.** F4 resolves per-doc expectations from F2's single filename-keyed `document-expectations.md` (and adds custom-doc entries); if F2 hasn't landed, F4's resolution path has no canonical source. | M | F2 is in delivery-001, strictly before delivery-002. Already encoded in the sequence. |
| 3 | **Count-literal straddle.** F2 edits `discovery-reviewer/AGENT.md`, which also carries a stale "14/16" line that is F4's FR-P0-4 scope. | L | F2's SPEC §6 keeps its replacement pointer count-agnostic so it doesn't conflict with F4's later de-hardcode edit. Flag to the delivery-002 implementer to confirm the F2 pointer wasn't reintroduced as a count. |

## Execution Graphs

> Tasks from `/aid-detail` (14 total). Numbers are global. Within a wave, tasks are
> parallel-safe (disjoint files, no shared state). Edges are `dependency → task`.

### delivery-001 — P0 Correctness Baseline (tasks 001–006)

```
Wave A (∥):  task-001 [IMPL F1]   task-003 [IMPL F2]   task-005 [IMPL F3]
Wave B (∥):  task-002 [TEST F1]←001   task-004 [TEST F2]←003
Wave C:      task-006 [DOC KB]←{002,004,005}
```
Edges: 001→002 · 003→004 · {002,004,005}→006. The three feature lanes (F1/F2/F3) are
mutually parallel-safe (disjoint files); task-006 registers the baseline in the KB once all
three lanes are verified.

### delivery-002 — Declared, Project-Shaped Doc-Set (tasks 007–014)

```
Wave 1:  task-007 [IMPL read-path]←{001,003,005}      (CORE)
Wave 2:  task-008 [IMPL de-hardcode+mapping]←007       (CORE)
Wave 3:  task-009 [TEST core]←{007,008}   ‖   task-010 [IMPL propose→confirm]←008
Wave 4:  task-011 [IMPL custom-doc]←{010,003}
Wave 5:  task-012 [TEST derivation]←{010,011}
Wave 6:  task-013 [DOC KB + H5 resolved]←{009,012}
Wave 7:  task-014 [DOC summary regen]←013
```
Edges: 007→008 · {007,008}→009 · 008→010 · {010,003}→011 · {010,011}→012 ·
{009,012}→013 · 013→014. Only intra-delivery parallelism: task-009 (CORE test) ∥ task-010
(DERIVATION impl) — both unblocked by task-008, disjoint surfaces (test files vs
`state-generate.md` Step 0d). The chains 007→008 and 010→011→012 are strict.
**delivery-002 begins only after delivery-001 completes** (cross-cutting risk #1 — shared
`state-generate.md` dispatch surface).

> **Ratified deferral (detail review LOW #1):** F4 SPEC §2.2's optional retargeting of the 5
> `discovery-*/AGENT.md` Output-Documents prose to "defer to the declared set" is NOT a
> separate task — that prose is already made correct by task-001 (F1) and the dispatch is
> data-driven from the declared set after task-008; only the concrete SKILL-table edit (D5)
> was an atomic edit, and it is covered in task-008.

## Deferred

*None — all 4 Ready features are assigned. P2 (heterogeneous sources) is dropped (out of
scope), P3 (retrieval upgrades) deferred, P4 (vector/RAG/MCP) dropped — per REQUIREMENTS §4,
out of scope for this work, not deferred features within it.*

# task-029: Forward-authored carve in the aid-housekeep KB-DELTA review routing

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-005

**Depends on:** -- (none)

**Scope:**
- The load-bearing NFR-5 carve in `canonical/skills/aid-housekeep/references/state-kb-delta.md`. KB-DELTA
  today partitions its review set by VERDICT, and its Tier-2 reconciliation direction is doc<-code
  (update-the-doc from as-built) -- the exact direction NFR-5 FORBIDS for a forward-authored seed. Add
  `source`-frontmatter as a NEW review-routing dimension: in the Step 1/2 partition, route every
  `.aid/knowledge/*.md` whose frontmatter `source: forward-authored` OUT of the Tier-2 update-the-doc set
  and INTO a new conformance lane (the mechanism + reconciliation are authored in task-030/031).
- Scope the carve ENTIRELY by the marker: read `source` via the existing `fm_scalar` accessor pattern f007
  uses (`kb-freshness-check.sh` lines 143-156, 393-396); add no new schema/enum/field. `hand-authored` /
  `generated` docs are UNTOUCHED -- they stay in KB-DELTA's source->doc freshness + Tier-2 update-the-doc
  lane, byte-unchanged. If the forward-authored set is EMPTY (no greenfield seed in the repo), the carve is
  a no-op and KB-DELTA proceeds exactly as today (graceful degradation, no error).
- Mirror feature-003's panel-exclusion carve: a single shared doc-set review path disambiguated by the
  `source` value. State explicitly that confirming KB-DELTA's routine scope-refresh prompt must NEVER be
  reachable for a forward-authored doc (that would reconcile in the NFR-5-forbidden doc<-code direction).
- Edit the canonical source form; host-tree propagation is task-032. ASCII-only.
- **Out of scope:** the extract-and-diff mechanism + classifier that the lane RUNS (task-030); the
  reconciliation flow (task-031); the `output_root` extraction edit (task-028); the render (task-032);
  verification (task-033/034).

**Acceptance Criteria:**
- [ ] KB-DELTA's Step 1/2 partition routes `source: forward-authored` docs OUT of the Tier-2 update-the-doc set and INTO the conformance lane, adding `source` as a new review-routing dimension. *(NFR-5 carve; gate criteria 1, 2)*
- [ ] The carve is scoped solely by the `source: forward-authored` marker read via the existing `fm_scalar` pattern; no new schema/enum/field is added. *(C-1; feature-005 marker dependency)*
- [ ] `hand-authored` / `generated` docs are unchanged: they remain in KB-DELTA's source->doc freshness + Tier-2 update-the-doc lane (verify the brownfield routing prose is byte-unchanged via diff). *(NFR-2 brownfield-intact, DoD V3/V6; gate criterion 4)*
- [ ] An empty forward-authored set makes the carve a no-op (KB-DELTA proceeds unchanged); a forward-authored doc is never reachable by the routine scope-refresh / update-the-doc prompt. *(DoD V4/V5 degradation; gate criterion 2)*
- [ ] ASCII-only; skill reference is prose-executed (no inline unit test; IMPLEMENT unit-test default overridden -- the carve + brownfield-intact behavior are exercised by task-034). All REQUIREMENTS.md §6 quality gates pass (heavy gates at task-034).

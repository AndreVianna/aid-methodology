# Plan -- AID-Interview Improvements

> Plan history: **pass 1** sequenced the 3 spike-independent features (delivery-001 spike +
> delivery-002 infra debt, both now EXECUTED). **pass 2 (this re-plan)** adds delivery-003..006 for
> the content features 002/003/004/005 + the feature-006 split, now all specified at A+ from the
> spike's findings. Deliveries build on the executed delivery-001/002.

## Deliverables

### delivery-001: Elicitation Research Spike
- **What it delivers:** a `findings.md` research deliverable cataloguing the best
  Requirements-Elicitation / Domain-Discovery techniques used by seasoned analysts (RQ-A seed
  content + RQ-B analyst conversation; 7 technique families + the web-trending "grill-me"
  comparative), with an explicit consumption contract for features 002-005. Pure research; no
  production code.
- **Features:** feature-001-elicitation-research-spike
- **Depends on:** -- (foundation)
- **Priority:** Must

### delivery-002: Infra Debt Paydown
- **What it delivers:** hardened maintainer infrastructure, independent of the elicitation work:
  H1 (`tests/canonical/test-install-manifests-lockstep.sh` asserting the 5 install manifests agree
  on the dashboard 12-file set), M3 (refreshed `repository-structure.md` -- counts + all three
  prose paths + the ASCII tree), M4 (multi-viewport check in `validate-visuals.mjs`), M1
  (npm/PyPI publish enablement -- owner-gated/externally-blocked; not a code change, recommended
  for **deferral with rationale** per AC-9, the publish workflow already being OIDC-ready).
- **Features:** feature-007-infra-debt-paydown
- **Depends on:** -- (independent; parallel-capable with delivery-001)
- **Priority:** Could

### delivery-003: Seasoned-Analyst Engine + Guided Triage
- **What it delivers:** the seasoned-analyst elicitation engine (one fixed "what+why" opener +
  adaptive next-move selection, read+ask calibration, expert-advisor stance, and the NFR-7
  suggested-answer-+-rationale contract on every question) PLUS analyst-driven guided triage
  (draws out the path/recipe-deciding signals, KB-context-aware) -- improving the interview for
  EVERY user (brownfield and greenfield). In-place extension of the aid-interview skill; the
  existing brownfield path is preserved (AC-10).
- **Features:** feature-002-seasoned-analyst-engine, feature-004-guided-triage
- **Depends on:** -- (extends the current skill; builds on the executed delivery-001 findings)
- **Priority:** Must

### delivery-004: Greenfield Seed Authoring
- **What it delivers:** forward-author a minimal-but-sufficient KB seed from intent for code-less
  (greenfield) projects -- the 5-element seed model + the `source: forward-authored` marker
  (schema/lint/index/freshness edits), a greenfield-mode review gate, and the layered
  seed<->requirements coherence check. The inverse of brownfield extraction (the authored design
  IS the source of truth, design->code).
- **Features:** feature-003-greenfield-seed-authoring
- **Depends on:** delivery-003 (the engine elicits the seed)
- **Priority:** Must

### delivery-005: Build-Time Conformance
- **What it delivers:** a NEW code->design conformance check (extract-and-diff) that flags when
  as-built code diverges from a forward-authored design seed, for human-gated reconciliation --
  authority stays design->code until a human reconciles. Runs as an additive aid-housekeep
  KB-DELTA conformance lane (carving forward-authored docs out of the doc<-code update lane).
- **Features:** feature-005-build-time-conformance
- **Depends on:** delivery-004 (the seed model + marker it checks against)
- **Priority:** Must

### delivery-006: Split aid-interview -> aid-describe + aid-define
- **What it delivers:** split the (now-enhanced) `aid-interview` skill into two outcome-named
  skills at the approval gate -- `aid-describe` (TRIAGE + interview + COMPLETION + the entire lite
  path -> approved REQUIREMENTS) and `aid-define` (FEATURE-DECOMPOSITION + CROSS-REFERENCE ->
  feature folders). Byte-identical render across the 5 host trees + dogfood mirror, old dir
  orphan-pruned, install manifests / docs-site / skill-count (+1, 13->14) updated, the
  `aid-interviewer` agent untouched, CI green.
- **Features:** feature-006-rename-aid-define
- **Depends on:** delivery-003, delivery-004 (operates on the FINAL in-place content), AND
  **delivery-005** (a sequencing edge -- not a content dependency: d006's name-sweep and d005's
  `output_root` param both edit `canonical/skills/aid-discover/references/state-generate.md`, so
  they must NOT run in parallel; d006 lands LAST regardless).
- **Priority:** Should

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Shared-file coupling across deliveries.** Two collision surfaces: (a) delivery-003 (002+004), delivery-004 (003), and delivery-006 all edit `canonical/skills/aid-interview/` IN PLACE; (b) delivery-005 AND delivery-006 BOTH edit `canonical/skills/aid-discover/references/state-generate.md` (d005 adds the `output_root` param; d006's name-sweep rewrites the `/aid-interview` tokens there). Parallel delivery branches would collide on these files. | M | Both surfaces are resolved by strict sequencing the dependency graph already enforces: d003 -> d004 -> d005 -> d006 (d006 now also depends on d005 -- a sequencing edge for the shared `state-generate.md`). No two deliveries that share a file run concurrently. |
| 2 | **feature-006 split operates on a moving target.** Its blast-radius inventory + the 13->14 skill-count surfaces are computed against today's tree; delivery-003/004 add/restructure `references/` before it runs. | L | feature-006 is sequenced LAST (depends on delivery-003+004) and its spec already states it partitions the FINAL post-content file set; aid-detail/aid-execute re-derive the inventory against the then-current tree before the split task runs. |

## Deferred

_None -- all Ready features are now assigned to a delivery (feature-006 is delivery-006, no longer deferred)._

## Execution Graphs

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | — |
| task-003 | task-001, task-002 |

| Can Be Done In Parallel |
|------------------------|
| task-001, task-002 |

```wave-map
delivery: 001
wave 1: task-001, task-002
wave 2: task-003
```

task-001 = Classic elicitation/domain-discovery technique survey (RESEARCH) ·
task-002 = grill-me comparative (RESEARCH) · task-003 = Synthesis & Recommendations -> findings.md
(RESEARCH). The two surveys write separate research notes (no shared-file contention), so they run
in parallel; the synthesis assembles findings.md from both.

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-004 | — |
| task-005 | — |
| task-006 | — |
| task-007 | task-006 |
| task-008 | — |
| task-009 | — |

| Can Be Done In Parallel |
|------------------------|
| task-004, task-005, task-006, task-008, task-009 |

```wave-map
delivery: 002
wave 1: task-004, task-005, task-006, task-008, task-009
wave 2: task-007
```

task-004 = install-manifests-lockstep suite (TEST, H1) · task-005 = refresh repository-structure.md
(DOCUMENT, M3) · task-006 = multi-viewport check in validate-visuals.mjs (IMPLEMENT, M4) ·
task-007 = verify T4 catches a clip + wire suite (TEST, M4; depends on task-006) ·
task-008 = record M1 publish-enablement deferral (DOCUMENT, M1) ·
task-009 = grant aid-researcher web tools (CONFIGURE, R1; added 2026-06-27, owner direction).
Five items are mutually independent (wave 1); only the M4 TEST waits on the M4 IMPLEMENT.

### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-010 | — |
| task-011 | — |
| task-012 | — |
| task-013 | task-010, task-011, task-012 |
| task-014 | task-013 |
| task-015 | task-013, task-014 |
| task-016 | task-014, task-015 |
| task-017 | task-016 |
| task-018 | task-017 |

| Can Be Done In Parallel |
|------------------------|
| task-010, task-011, task-012 |

```wave-map
delivery: 003
wave 1: task-010, task-011, task-012
wave 2: task-013
wave 3: task-014
wave 4: task-015
wave 5: task-016
wave 6: task-017
wave 7: task-018
```

task-010 = advisor-stance + NFR-7 envelope doc (IMPLEMENT) / task-011 = move-playbook doc (IMPLEMENT) /
task-012 = calibration doc (IMPLEMENT) / task-013 = elicitation-engine driver doc (IMPLEMENT) /
task-014 = in-place spine engine-wiring (IMPLEMENT) / task-015 = engine-driven guided triage in
state-triage.md (IMPLEMENT) / task-016 = opener-seam de-dup in state-continue.md (IMPLEMENT) /
task-017 = full generator render + 5-profile/.claude propagation (CONFIGURE) / task-018 = delivery-003
verification: brownfield tests + dogfood-transcript review (TEST). The three engine component docs
(010/011/012) are separate single-concern files with no inter-dependence, so they author in parallel
(wave 1); the driver (013) integrates them; the rest is a genuine chain -- the spine wiring (014)
needs the engine docs, triage (015) consumes the wired engine and shares state-triage.md with 014, the
opener de-dup (016) reads the `**Opener:**` field 015 writes and the opener content 014 lands, the
render (017) propagates all canonical edits once, and verification (018) runs after the render. The
strict chain also honours PLAN risk #1 (no two tasks edit the same `canonical/skills/aid-interview/`
file in parallel).

### delivery-004 execution graph

| Task | Depends On |
|------|-----------|
| task-019 | — |
| task-020 | — |
| task-021 | task-019, task-020 |
| task-022 | — |
| task-023 | task-022 |
| task-024 | — |
| task-025 | task-020, task-023, task-024 |
| task-026 | task-019, task-020, task-022, task-023, task-024, task-025 |
| task-027 | task-026 |

| Can Be Done In Parallel |
|------------------------|
| task-019, task-020, task-022, task-024 |
| task-021, task-023 |

```wave-map
delivery: 004
wave 1: task-019, task-020, task-022, task-024
wave 2: task-021, task-023
wave 3: task-025
wave 4: task-026
wave 5: task-027
```

task-019 = forward-authored freshness short-circuit in `kb-freshness-check.sh` (IMPLEMENT) /
task-020 = marker schema enum row + lint/index pass-through notes (DOCUMENT) /
task-021 = marker fixture-through-three-scripts + brownfield-intact regression (TEST) /
task-022 = greenfield-mode block in `document-expectations.md` (IMPLEMENT) /
task-023 = thread `greenfield:` param through `reviewer-brief.md` + reconcile `state-review.md` panel
exclusion (IMPLEMENT) / task-024 = layered coherence-check reference doc (IMPLEMENT) /
task-025 = seed-authoring state (aid-describe step): 5-element model + domain-adaptive shape + gate
wiring (IMPLEMENT) / task-026 = full generator render + 5-profile/.claude propagation + DBI (CONFIGURE) /
task-027 = delivery-004 verification: greenfield gate A+ + zero-loopback sufficiency + coherence-block +
brownfield-intact + §6 (TEST).

Three independent lanes open in wave 1 on distinct files (no shared-file contention): the MARKER lane
(019 `kb-freshness-check.sh` / 020 the schema + `lint-frontmatter.sh` + `build-kb-index.sh` -- disjoint
from 019), the GATE lane (022 `document-expectations.md`), and the COHERENCE lane (024 a new
`aid-interview/references` file). Wave 2 runs the marker TEST (021, after both marker edits) in parallel
with the gate WIRING (023 `reviewer-brief.md` + `state-review.md`, after the gate block 022 it references).
The seed-authoring state (025) integrates the marker schema (020, for the stamp), the gate wiring (023,
which it invokes with `greenfield: true`), and the coherence doc (024, which it invokes), so it lands in
wave 3. The single consolidated render (026) follows ALL canonical edits; verification (027) runs last.
Shared-file discipline (PLAN risk #1) holds: `kb-freshness-check.sh`, the schema/lint/index trio,
`document-expectations.md`, `reviewer-brief.md`+`state-review.md`, and the two new `aid-interview`
reference files are each touched in exactly one wave, and no two tasks in any wave edit the same file.

### delivery-005 execution graph

| Task | Depends On |
|------|-----------|
| task-028 | — |
| task-029 | — |
| task-035 | — |
| task-030 | task-028, task-029 |
| task-031 | task-030 |
| task-032 | task-028, task-029, task-030, task-031, task-035 |
| task-033 | task-032 |
| task-034 | task-032 |

| Can Be Done In Parallel |
|------------------------|
| task-028, task-029, task-035 |
| task-033, task-034 |

```wave-map
delivery: 005
wave 1: task-028, task-029, task-035
wave 2: task-030
wave 3: task-031
wave 4: task-032
wave 5: task-033, task-034
```

task-028 = `output_root` dispatch parameter on the aid-discover extraction subagents (`agent-prompts.md` +
`state-generate.md`; default preserves callers + the `.aid/generated/` side-output) (IMPLEMENT) /
task-029 = forward-authored carve in `state-kb-delta.md` (route `source: forward-authored` OUT of the
Tier-2 update-the-doc lane -- the NFR-5 carve) (IMPLEMENT) / task-030 = extract-and-diff conformance
sub-step + classifier in `state-kb-delta.md` (scope-by-marker, shadow extraction via `output_root`,
keep-only-in-scope filter, concern-keyed diff, 4-class classifier + altitude filter) (IMPLEMENT) /
task-031 = human-gated flag-not-overwrite reconciliation flow in `state-kb-delta.md` (present-the-choice +
Required Q&A; never auto-edit the seed) (IMPLEMENT) / task-035 = optional conformance signpost in
`aid-execute/.../state-delivery-gate.md` (one-line "run /aid-housekeep to check conformance" pointer;
no mechanism; owner-added 2026-06-27) (IMPLEMENT) / task-032 = full generator render + 5-profile/.claude
propagation + DBI (CONFIGURE; after ALL canonical edits incl. 035) / task-033 = output_root verification: shadow-write isolation +
default-caller invariance + generated-side-output preserved (TEST) / task-034 = conformance-lane
verification: flag-not-overwrite + NFR-5 carve + altitude tuning + brownfield-intact + §6 (TEST).
task-035 edits `state-delivery-gate.md` -- a file no other delivery-005 task touches, so it opens a
third disjoint wave-1 lane; render (032) waits on it.

### delivery-006 execution graph

| Task | Depends On |
|------|-----------|
| task-036 | — |
| task-037 | task-036 |
| task-038 | task-037 |
| task-039 | task-038 |
| task-040 | task-039 |

| Can Be Done In Parallel |
|------------------------|
| — |

```wave-map
delivery: 006
wave 1: task-036
wave 2: task-037
wave 3: task-038
wave 4: task-039
wave 5: task-040
```

task-036 = re-derived blast-radius inventory + final `references/` partition against the THEN-current
(post 002/003/004/005) tree (DOCUMENT) / task-037 = canonical carve `git mv aid-interview ->
aid-describe` + create `aid-define`, partition the 6 define refs, author the two SKILL.md identities +
State Detection/Dispatch tables, the inter-skill seam (redirect COMPLETION's existing pause signpost +
writeback to `/aid-define`), the `state-done.md` hand-back, self-ref rewrite (IMPLEMENT) / task-038 =
boundary-aware external skill-name sweep (agents, recipes+tooling, templates, other canonical skills,
README, examples, dashboard 4 files, docs-site source incl. `gen-reference.mjs` SKILL_GROUPS split,
legacy docs, tests) + the 13->14 count-increment surfaces (numeric AND spelled-out
`Thirteen->Fourteen`) under the `aid-interviewer` substring guard (IMPLEMENT) / task-039 = FULL
`run_generator.py` render of both new dirs byte-identically across the 5 profiles + `.claude` mirror,
orphan-prune the old `aid-interview/` dir, rewrite the 5 `emission-manifest.jsonl` + the dogfood
`.aid/.aid-manifest.json`, regenerate `skills.md` + sync the methodology copy (CONFIGURE) / task-040 =
delivery-006 verification: DBI byte-identity both dirs, old dir pruned from every tree, zero stale
`/aid-interview` tokens (scoped sweep), count surfaces +1 (numeric + spelled-out), `aid-interviewer`
count unchanged vs the task-036 baseline, inter-skill seam, CI green incl. master-only heavy gates (TEST).

This delivery is a structural git-mv + propagation, NOT a behavior change, and is **highly serial**: the
inventory (036) feeds the canonical carve (037), which feeds the external sweep (038), which feeds the
single consolidated render (039), then verification (040). Every task touches a downstream-dependent
surface of the prior one (the carve sets the on-disk `canonical/skills/` listing the `gen-reference.mjs`
skills-drift guard and the render both key on; the sweep's source edits feed the docs regen; the render's
trees + manifests are what the DBI + orphan-prune checks read), so there is no safe parallelism -- the
single-lane wave-map is the mechanically-derived consequence. PLAN risk #1 (shared `state-generate.md`
with delivery-005) is honoured by the cross-delivery d005 -> d006 sequencing edge; within delivery-006
`state-generate.md` is touched only by the task-038 name-sweep.

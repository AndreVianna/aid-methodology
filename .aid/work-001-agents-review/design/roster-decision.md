# Roster Decision Package — Consolidated, Human-Approvable Decision Set

> **Produced by task-005 [DOCUMENT].** This is the verification/packaging artifact for the
> single human approval gate of `work-001-agents-review` (feature-001-roster-design SPEC →
> Process Flow step 6; Description). It introduces **no new decision** — it indexes the four
> frozen decision artifacts and records the result of each pre-approval self-consistency check
> the SPEC's *Acceptance Criteria mapping* requires. If a check failed, it would be FLAGGED back
> to the owning DESIGN task (task-003 roster / task-004 migration map), not fixed here.
>
> **Verification performed on disk on 2026-06-04** against `canonical/skills/` (11 dirs),
> `canonical/agents/` (22 dirs), and the four artifacts in this `design/` folder. Shell evidence
> is pasted inline per check.

---

## 1. Index / Overview — the four artifacts as one frozen decision set

The decision is captured as four logical artifacts (Markdown tables, the AID decision-doc
convention; feature-001 SPEC A1/A2). They are co-located in
`.aid/work-001-agents-review/design/` and are meant to be read together as a single approvable
unit. This file (`roster-decision.md`) is the index + verification wrapper; it does not replace
or re-derive any of them.

| # | Artifact | Path (relative to repo root) | Role | FR / AC |
|---|----------|------------------------------|------|---------|
| (a) | Needs → Role Matrix | [`design/needs-matrix.md`](./needs-matrix.md) | **Demand side** — 69 rows, one per (consumer × distinct agent-work need) across 12 consumers | FR1 / AC1 |
| (b) | Current-State Audit | [`design/current-audit.md`](./current-audit.md) | **Supply side** — one row per existing agent (all 22), dispatch breadth + overlap + boilerplate burden | FR2 |
| (c) | Target Roster Spec | [`design/target-roster.md`](./target-roster.md) | **Derived roster** — 9 proposed `aid-*` agents + Format decision + Generation decision sub-sections | FR3 / AC2 + Format AC |
| (d) | Migration Map | [`design/migration-map.md`](./migration-map.md) | **Old → new disposition contract** — 22 rows (rename/merge), the hand-off to feature-002 | FR4 / AC3 |

**Headline outcome.** Applying the three ranked design principles (single-responsibility → reuse
→ authoring-simplicity) through derivation rules R1–R5 reduces the roster from **22 → 9 agents**,
all carrying the mandatory `aid-` prefix (REQUIREMENTS.md §7, collision-avoidance). The 9 are:
`aid-interviewer`, `aid-architect`, `aid-developer`, `aid-researcher`, `aid-reviewer`,
`aid-operator`, `aid-orchestrator`, `aid-tech-writer`, `aid-clerk`. The count is an
**emergent outcome** of merging strict-subset / duplicate responsibilities and parameterizable
utilities — no rule targeted a specific number (R5; REQUIREMENTS.md §6); the `aid-` prefix is a
naming constraint layered on top, not a composition change. Dispositions under the uniform
namesake-`rename`/absorber-`merge` scheme: **0 keep, 8 rename, 14 merge, 0 drop** — because the
prefix changes every name, NO old bare name survives as a pure keep. `aid-clerk` is the
one destination with no namesake among the 22 (reached by the three `simple-*` merges).

**Format / generation decision.** Chosen format = **option (2) Shared-include for boilerplate**:
keep one per-agent canonical source file, but factor the two byte-duplicated blocks
(`## Heartbeat protocol`, `## Self-review discipline`) out into the existing
`canonical/templates/` and inject them at render time. Generation decision: `render_agents.py`
needs **one small additive include-resolution step** before the format-branch dispatch (the
existing `substitute_filenames` machinery cannot do it — only 3 fixed placeholder keys); profiles
need no required change. Both the include step and the stale `aid-generate` "three install
trees" / `--tool` enum / "22 agents" VALIDATE count are recorded as **feature-002 (FR5/FR7)**
inputs, not implemented here.

**Scope boundary (restated).** This entire feature is DECIDE, not EXECUTE. No agent, skill,
profile, KB doc, or install-tree file is mutated. The only files written by feature-001 are the
four artifacts above + the SPEC + this package. All rewiring/authoring/regeneration/KB updates
belong to feature-002-roster-rollout.

**`aid-` prefix widens the feature-002 rewire (REQUIREMENTS.md §7).** Because the prefix renames
EVERY agent — including the 8 that would otherwise have been pure keeps — the migration map now has
**0 `keep` rows**. Consequence for feature-002: **FR6 widens** from "rewire only the merged/renamed
agents' sites" to "rewrite EVERY agent-name dispatch site to its `aid-`prefixed target" (the 8
formerly-keep namesakes — architect, developer, interviewer, operator, orchestrator, researcher,
reviewer, tech-writer — are now also rewired). And **FR9's consistency sweep must confirm no BARE
(unprefixed) old name survives anywhere** in SOURCE, KB, or the five rendered trees — the sweep set
is all 22 bare names, not just the merge/drop subset.

---

## 2. Self-consistency check — per-AC result with on-disk evidence

Each check below was re-run on disk (not trusted from the artifacts' own embedded claims). The
filter for "true data row" excludes the artifacts' verification/closure sub-tables so the counts
reflect only the canonical decision tables.

### AC1 — needs→role matrix covers every consumer and phase/state (two-way set equality)

**AC1a — Consumer set (two-way, against `ls canonical/skills/` ∪ {aid-generate}).** The expected
set is the **12** = 11 `canonical/skills/` dirs + the maintainer-only `aid-generate`
(`.claude/skills/aid-generate/`, deliberately absent from `canonical/skills/`; SPEC A3). Verified
that `set(matrix.consumer) == expected` in **both** directions (not a one-sided diff).

```
expected (n=12): aid-config aid-deploy aid-detail aid-discover aid-execute aid-generate
                 aid-housekeep aid-interview aid-monitor aid-plan aid-specify aid-summarize
matrix   (n=12): aid-config aid-deploy aid-detail aid-discover aid-execute aid-generate
                 aid-housekeep aid-interview aid-monitor aid-plan aid-specify aid-summarize
diff: <empty>
```

**Result: PASS (empty-diff both directions).**

**AC1b — Phase/state pairs.** The matrix carries **69** `(consumer, phase/state)` rows; all 69
are **distinct** (no duplicate pair). Spot-checked the on-disk source-of-truth against the
matrix's enumeration: `aid-discover` state-*.md stems = {approval, done, fix, generate, q-and-a,
review} (6); `aid-execute` = {delivery-gate, execute-drilldown, execute, fix, re-run, review}
(6); `aid-summarize` = 10 stems; `aid-plan`/`aid-detail` use non-state-named reference files
(first-run-loop / review-deliverables; first-run / review) so their phases derive from the
SKILL.md dispatch table — all consistent with the matrix source-of-truth table (needs-matrix
lines 145–161) and its documented resolutions (A1–A7).

```
total (consumer, phase/state) pairs = 69 ; distinct = 69  → NO DUPLICATES
on-disk state-stem spot-check (aid-discover / aid-execute / aid-summarize): matches matrix
```

**Result: PASS.** The matrix records a full two-way empty-diff (needs-matrix lines 160–165);
the disk spot-check and the 69-distinct-pairs count reconcile with it. The phase/state
enumeration relies on documented OR-side resolutions for the four skills whose reference files
are not literally `state-*.md` (aid-config modes, aid-plan/aid-detail named files, aid-generate
modes) — these are recorded as A1–A4 in the matrix, not silent.

### AC2 — every proposed agent maps to ≥1 need + has a single non-overlapping responsibility

**AC2a — `covers_needs` non-empty and resolves to real needs-matrix rows (R4 + cross-ref).** All
**9** roster rows cite ≥1 need; every cited row number resolves into the matrix's `[1..69]`
range; none out of range; no empty cell.

```
needs-matrix rows: min=1 max=69 count=69
distinct cited need rows across roster: 3 4 6 9 10 11 12 13 14 16 17 18 19 21 22 25 27 28
                                        30 31 33 34 35 38 40 41 42 43 46 47 48 51
out-of-range citations: <none>
empty covers_needs cells: <none>
```

**Result: PASS.** Cross-reference resolution (covers_needs → real needs-matrix rows) holds.

**AC2b — pairwise `single_responsibility` non-overlap (R1).** This is a semantic check; verified
by reading the roster table's pairwise statement (target-roster.md lines 37–43). The
load-bearing boundaries each separate cleanly: architect (*propose new design*) vs researcher
(*catalogue existing state*); developer (*per-task implement + build-verify*) vs operator
(*release-gated ship*); researcher (*KB/analysis docs*) vs tech-writer (*user-facing docs*);
reviewer (*grades, never authors* — independence + tier invariant) vs every executor;
aid-clerk (*schema-bounded mechanical output, no reasoning*) vs all. No two of the 9 share a
responsibility.

**Result: PASS** (no overlap found among the 9).

### AC3 — migration map accounts for all 22 agents, each with a disposition + rationale

`old_agent` set of the 22 true data rows equals the 22 `canonical/agents/` dirs (empty-diff both
directions); row count == 22; disposition is from the closed enum on every row; no empty
rationale.

```
canonical/agents dirs = 22 ; migration-map true data rows = 22
old_agent set diff vs canonical/agents: <empty>  (EMPTY-DIFF PASS)
disposition tally: keep=0  rename=8  merge=14  drop=0   (aid- prefix ⇒ no pure keeps)
empty-rationale cells: <none>
```

**Closure (`{ non-blank new_agent } == { 9 `aid-*` roster agents }`, both directions):**

```
non-blank new_agent set (n=9): aid-architect aid-developer aid-interviewer aid-operator
                               aid-orchestrator aid-researcher aid-reviewer
                               aid-clerk aid-tech-writer
roster set (target-roster.md, n=9): aid-architect aid-developer aid-interviewer aid-operator
                               aid-orchestrator aid-researcher aid-reviewer
                               aid-clerk aid-tech-writer
closure diff: <empty>  (EMPTY-DIFF PASS, both directions)
```

0 drops ⇒ no roster agent depends on a dropped agent (the "no-dependent" guard is vacuously
satisfied). Every roster agent is reachable from ≥1 old agent (migration-map closure table lines
66–79).

**Result: PASS** (22-row, set-equality, enum, closure all hold).

### Format / generation AC — chosen format + generation approach stated and justified

Required sub-sections present in `target-roster.md`:

```
71:## Format decision        → "Chosen option: (2) Shared-include for boilerplate"
115:## Generation decision    → "render_agents.py and profiles/*.toml DO need a change … feature-002"
```

The Format decision names the chosen option from the four weighed, compares ≥2 alternatives with
trade-offs (table at lines 103–108), and justifies against principle 3 + the
buildable/4-format constraint (criteria i–iv). The Generation decision states the additive
render step, corrects the SPEC's inaccurate `substitute_filenames` assumption, and flags the
`aid-generate` stale references for feature-002 FR7.

**Result: PASS** (both sub-sections present and justified).

### Cross-reference resolution summary

| Cross-reference | Direction | Result |
|-----------------|-----------|--------|
| roster `covers_needs` → needs-matrix rows | every cited # ∈ [1..69]; none empty | **resolves** |
| migration-map `new_agent` → target-roster rows | non-blank set == 9 roster agents, empty-diff | **resolves** |
| migration-map `old_agent` → canonical/agents dirs | set-equality, empty-diff | **resolves** |
| matrix `consumer` → canonical/skills ∪ {aid-generate} | set-equality, empty-diff | **resolves** |

### Check scoreboard

| Check | Source (SPEC AC mapping) | Result |
|-------|--------------------------|--------|
| AC1a consumer two-way set-equality | AC1 | **PASS** (empty-diff) |
| AC1b phase/state pairs | AC1 | **PASS** (69 distinct; disk spot-check reconciles) |
| AC2a covers_needs non-empty + valid rows | AC2 / R4 | **PASS** |
| AC2b pairwise single-responsibility | AC2 / R1 | **PASS** (semantic; no overlap) |
| AC3 22-row + old_agent set-equality + enum + rationale | AC3 | **PASS** (empty-diff) |
| AC3 closure (new_agent set == 9 roster) | Migration considerations | **PASS** (empty-diff) |
| Format AC present + justified | Format/generation AC | **PASS** |
| Generation AC present + justified | Format/generation AC | **PASS** |
| Cross-references resolve | AC2/AC3 | **PASS** (all four directions) |

No check FAILED. No back-flag to task-003 or task-004 is required.

---

## 3. Approval-readiness note

**Verdict: APPROVABLE-WITH-NOTED-FLAGS.** The four artifacts are present, internally
cross-resolvable, and co-located in `design/`; every SPEC AC check returns PASS / empty-diff on
disk. The set is frozen and presentable as the single human-approvable decision that is the
input contract to feature-002-roster-rollout. There are **no blocking issues** — the flags below
are non-blocking design choices the artifacts already disclose, surfaced here so the human can
weigh them explicitly at the gate rather than discover them later.

### Flags the human should see at the gate

The two flags carried forward from task-004 (non-blocking; the migration map is internally closed
and consumable with both choices recorded):

1. **Split-destination folds collapsed to a single `new_agent` column.** Four agents fold into
   *two* destinations depending on task type — the **analysis** side vs the **fix/execute** side:
   - `security` and `performance` → `aid-researcher` (their analysis surface) **and** `aid-developer`
     (their fix/execute surface, per each agent's own "fix … — that's the Developer").
   - `devops` → `aid-developer` (CONFIGURE execution) **and** an `aid-operator` redirect (the aid-deploy
     CI/CD optional consult).

   The migration map's single `new_agent` cell records the **primary/analysis** destination
   (aid-researcher / aid-developer respectively) to keep closure deterministic, and the
   `dispatch_rewrite_hint` column spells out the secondary routing for feature-002 FR6. The human
   should confirm that collapsing each split to its primary column (rather than emitting two rows
   per agent) is acceptable for the approval record. *Owner if changed: task-004 (migration map).*

2. **`discovery-architect` → `aid-researcher` wording (the architect/researcher split).** The audit
   flags `discovery-architect` as overlapping the `architect` agent on architecture analysis. The
   roster splits that overlap by responsibility: *propose new design* stays with `aid-architect`;
   *read-only cataloguing of existing architecture* (what `discovery-architect` actually does for
   `architecture.md` / `technology-stack.md`) folds into `aid-researcher`. So `discovery-architect`
   merges into **aid-researcher**, not aid-architect, despite the name similarity. This is intentional and
   documented (target-roster lines 28/30; migration-map line 30), but the name collision is worth
   a human confirmation so the merge destination is not mistaken at the gate. *Owner if changed:
   task-003 (roster) + task-004 (migration map).*

### Other disclosed-but-non-blocking items (already recorded in the artifacts, for awareness)

- **KB staleness inputs (not fixed here; feature-002 FR8).** The audit measured on disk that
  `## Heartbeat protocol` is present in **all 22** agents and `## Self-review discipline` in
  **19** (absent only in `discovery-reviewer`, `orchestrator`, `reviewer`) — contradicting
  `coding-standards.md §8e` and `module-map.md` line 146. The audit uses disk truth; the KB fix is
  deferred to feature-002.
- **aid-detail REVIEW mis-route (needs-matrix A5).** `aid-detail` REVIEW currently dispatches
  `architect`, but the need is "review/grade task files against PLAN.md/SPECs" → `aid-reviewer`. The
  roster routes it to `aid-reviewer` and flags the rewire for feature-002 FR6.
- **`aid-clerk` is a net-new roster name.** It is the parameterized merge of the three
  `simple-*` utilities and is the only destination with no namesake among the 22; reachability is
  satisfied through the three merges (closure PASS).

The reduction is a **hypothesis** (per the SPEC): if feature-002 review finds a genuinely
distinct, recurring need a generalist cannot serve without violating single-responsibility, a
specialist can be re-introduced — the `merge` dispositions (not `drop`) keep that reversible and
auditable.

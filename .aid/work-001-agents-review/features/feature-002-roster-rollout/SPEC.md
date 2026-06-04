# Roster Rollout

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Feature identified from REQUIREMENTS.md §5 (FR5–FR9), §9 | /aid-interview |
| 2026-06-04 | Technical specification authored (FR5–FR9 rollout procedure, input contract, rewire/regen/verify method, AC mapping) | /aid-specify |
| 2026-06-04 | Spec fixes from review (KB heading citation; resolved dogfood .claude sweep/regen coherence gap; line-ref + wording tightening) | /aid-specify |
| 2026-06-04 | Applied REQUIREMENTS §7 `aid-` naming constraint: FR6 now renames ALL agent references to `aid-`prefixed names (no bare keeps); FR9 must assert zero surviving bare names | /aid-execute |

## Source

- REQUIREMENTS.md §5 (FR5 author definitions, FR6 rewire dispatch sites, FR7 regenerate install trees, FR8 update KB, FR9 consistency check)
- REQUIREMENTS.md §4 (scope), §9 (AC4–AC7), §10 (priority)

## Description

Make the repository match the roster approved in `feature-001-roster-design`. Author the new
`canonical/agents/<agent>/` definitions in the chosen format (applying authoring best practices
and reducing boilerplate), rewire every `SKILL.md` dispatch table and reference doc that names
an agent to the new roster, regenerate all five install trees via `/aid-generate` (correcting
the `aid-generate` skill's own stale "three trees" / `--tool` references in the process), update the KB
(`architecture.md` and any other agent-describing docs) to reflect the new model, and verify
that no dangling references to removed or renamed agents remain anywhere in the repo.

This is the mechanical execution of a frozen decision. It is broad (the rewiring spans
high-density surfaces like `aid-discover` and `aid-execute` down to the optional-skill tail),
but that breadth is task-sizing handled by `/aid-detail`, not a reason to split the feature.
Its terminal acceptance gates — a clean `/aid-generate`, a buildable repo, and a clean
repo-wide consistency sweep — make it reviewable as a unit.

## User Stories

- As an **AID maintainer**, I want every skill, reference, KB doc, and install tree migrated to
  the new roster in one consistent pass so that the repo builds and contains no dangling agent
  references.
- As an **AID adopter**, I want the regenerated install trees to keep the methodology working
  unchanged so that re-installing AID is seamless after the redesign.

## Priority

Must

## Acceptance Criteria

- [ ] **AC7** — Each new agent definition conforms to the chosen best-practice authoring format
      with reduced boilerplate (FR5 + design principle 3).
- [ ] **AC4** — No `SKILL.md`, reference doc, KB doc, template, recipe, or install-tree file
      references a non-existent agent; the consistency check passes clean (FR6 + FR9).
- [ ] **AC5** — `/aid-generate` runs without error and all five install trees (`claude-code`,
      `codex`, `cursor`, `copilot-cli`, `antigravity`) validate; the repo builds/validates after
      the change (FR7).
- [ ] **AC6** — `architecture.md`, `module-map.md`, and the `README.md` agent counts (plus any
      other agent-describing KB doc) reflect the new agent model (FR8).

---

## Technical Specification

> Authored by `/aid-specify`. This is a **methodology/tooling** work item — no DB, no UI.
> The standard SPEC sections are mapped to their methodology analogs: "Input Contract" plays
> the role of the data model (what this feature reads), "Rollout Process Flow" the role of the
> feature flow, and "Rewire Mechanism" the role of the layers/components. The feature is
> **parameterized over feature-001's decision artifacts** — it specifies the rollout *procedure*
> that works for whatever the migration map says, not a pre-assumed roster, count, or format.

### Overview & Approach

This feature is the **mechanical execution** of the roster decision frozen in
`feature-001-roster-design`. It owns FR5–FR9: author the new agent definitions (FR5), rewire
every dispatch site that names an agent (FR6), regenerate all five install trees via the
generator (FR7), update the KB + agent-count docs (FR8), and run a repo-wide consistency sweep
for dangling agent references (FR9).

**Consume, do not decide.** Nothing about the *target* roster, agent count, definition format,
or generation approach is decided here — those are the output of feature-001, recorded in
`design/target-roster.md` (roster rows + Format decision + Generation decision sub-sections) and
`design/migration-map.md` (one row per existing agent: `old_agent` → `disposition` keep/merge/rename/drop + `new_agent`
+ `rationale` + `dispatch_rewrite_hint`), per feature-001 SPEC → *Deliverable Artifacts & Formats*
(c) and (d). This feature reads those artifacts as **deterministic input** and applies them. If a
disposition says "merge `simple-glob`→`X`", this feature rewires `simple-glob` references to `X`;
it does not re-litigate whether that merge was correct.

**Source-vs-generated rule (the single most important correctness constraint).** AID is a
canonical→render→install pipeline (KB `architecture.md` §"Architectural Pattern", §"Folder
Structure"). Exactly two kinds of trees exist:

- **SOURCE (hand-edited):** `canonical/agents/`, `canonical/skills/`, `canonical/templates/`,
  `canonical/recipes/`, `canonical/rules/`, and `profiles/*.toml`. These are the *only* files
  FR5 (author) and FR6 (rewire) edit. **Plus** the lone documented exception: the maintainer-only
  `aid-generate` skill, which lives **only** at `.claude/skills/aid-generate/` and is deliberately
  NOT in `canonical/` (`architecture.md` line 186; `aid-generate/SKILL.md` line 13) — its own stale
  refs (FR7) are fixed by hand-editing it directly.
- **GENERATED (never hand-edited):** every rendered install tree — `profiles/{claude-code,codex,
  cursor,copilot-cli,antigravity}/{.claude,.codex/.agents,.cursor,.github,.agent}/`, excepting
  only the `aid-generate` skill noted above. These are produced exclusively by re-running the
  generator (FR7), which emits **only** into the `profiles/<tool>/` output roots (each
  profile's `output_root`; the claude-code profile's is `profiles/claude-code/.claude`, not the
  repo root). **The spec must never direct a hand-edit to a generated file** — doing so would
  be reverted on the next render and would fail the determinism gate (`verify_deterministic.py`
  sub-check 1: byte-identical re-render).
- **DOGFOOD CONVENIENCE TREE (out-of-band; not a generator output, not swept):** the repo-root
  `.claude/` (AID applied to itself; `architecture.md` line 92). It is a separately committed
  mirror of the claude-code render — but **the generator has no mechanism that writes to it**: the
  RENDER step targets `profiles/<tool>/` only, and no rsync/copy/sync step exists in the
  `aid-generate` skill, its `scripts/`, or CI (`test.yml`) that propagates
  `profiles/claude-code/.claude` → repo-root `.claude/`. It is therefore neither a FR5/FR6 SOURCE
  surface nor a FR7 generated output, and is **explicitly excluded from the FR9 sweep** (see
  *Consistency Check Method* and B2). Keeping the repo-root dogfood tree current is an out-of-band
  maintenance concern outside this feature's terminal gates.

So the rewire (FR6) edits canonical SOURCE; the regeneration (FR7) propagates those edits into
the five `profiles/<tool>/` rendered trees; the consistency sweep (FR9) then asserts no OLD name
survives in *either* canonical SOURCE or those five generated trees.

### Input Contract

**Precondition (hard gate):** feature-001 is approved at the work's single human approval gate
(feature-001 SPEC → Description). This feature MUST NOT begin until `design/target-roster.md` and
`design/migration-map.md` exist and are approved. If either is missing or unapproved, abort and
write a Q&A entry to `.aid/work-001-agents-review/STATE.md` `## Cross-phase Q&A` rather than
guessing a roster.

**What this feature reads from feature-001 (the deterministic inputs):**

| Artifact | Fields consumed | Used by |
|----------|-----------------|---------|
| `design/migration-map.md` | `old_agent`, `disposition` (`keep`/`merge`/`rename`/`drop`), `new_agent`, `rationale`, `dispatch_rewrite_hint` | FR6 rewire map; FR9 sweep target set (every `old_agent` whose disposition ≠ `keep`) |
| `design/target-roster.md` (roster rows) | `proposed_agent`, `single_responsibility`, `consumers`, `proposed_tier` | FR5 author set; FR6 dispatch destinations; FR8 new tier counts |
| `design/target-roster.md` → *Format decision* | chosen agent-definition format (one of the four feature-001 weighed: status-quo / shared-include / single-file-per-agent / consolidated-manifest) | FR5 authoring format; AC7 |
| `design/target-roster.md` → *Generation decision* | chosen generation approach (whether `render_agents.py` / profiles need changes to emit the new format) | FR7 regeneration; whether the generator is touched |

**Derived inputs (computed by this feature at execution time, not pre-assumed):**
- The **rewire map** = `{old_agent → new_agent}` for every `merge`/`rename` row; `keep` rows are
  no-ops; `drop` rows must have zero surviving references (their `new_agent` is empty).
- The **OLD-name sweep set** = `{old_agent | disposition ∈ {merge, rename, drop}}` — the names that
  must vanish from the repo (FR9). `keep` names are explicitly excluded from the sweep.
- The **author set** = the `proposed_agent` rows in `target-roster.md` (FR5).

Because all three are derived from the migration map, this spec imposes **no** specific final
roster, count, or format. A migration map that keeps all 22 and a map that collapses to 3 are both
valid inputs; the procedure below is identical.

### Rollout Process Flow

Ordered, dependency-aware. The safe ordering is **author + rewire SOURCE → regenerate → verify**;
generated trees are only ever produced by step 3, never edited in steps 1–2.

1. **Author new definitions in the decided format [FR5].** Create/update
   `canonical/agents/<proposed_agent>/` for each author-set row, in the format named by
   `target-roster.md` → *Format decision*, applying authoring best practices and reduced
   boilerplate (the duplicated `## Heartbeat protocol` + `## Self-review discipline` blocks per
   `coding-standards.md §8e`). Each definition conforms to whatever structure the Format decision
   mandates (e.g. status-quo per-agent `AGENT.md`+`README.md`, or a shared-include variant). For
   `drop` agents, remove their `canonical/agents/<old>/` directory. **(AC7.)** Parallelizable per
   agent.
2. **Rewire all dispatch sites in canonical SOURCE per migration map [FR6].** Apply the rewire map
   to every site that names an agent across SOURCE only (see *Rewire Mechanism*). Ordered after
   step 1 only in that destination agents must exist; authoring and rewiring may otherwise interleave.
3. **Regenerate all five trees + fix the generator's own stale refs [FR7].** First fix the
   `aid-generate` skill's stale references (it is hand-edited SOURCE-exception — see *Regeneration
   & Build Validation*), then run the generator for all five profiles, which renders SOURCE into
   the five `profiles/<tool>/` trees (the only surfaces the generator emits to — the repo-root
   dogfood `.claude/` is not a generator target; see B2). **Must run after
   steps 1–2** (it consumes the rewired source). **(AC5.)**
4. **Update KB + count docs [FR8].** Refresh the agent-count/tier statements in `architecture.md`,
   `module-map.md`, and `README.md` (and any other agent-describing KB doc) to the new roster — see
   *KB & Count Updates*. May run in parallel with step 3 (independent file set), but its *values*
   are derived from the new roster (step 1) not from the rendered trees. **(AC6.)**
5. **Repo-wide consistency sweep [FR9].** Grep the OLD-name sweep set across SOURCE, KB, templates,
   recipes, AND all rendered trees; assert zero dangling refs (see *Consistency Check Method*).
   **Must run last** — after regeneration (so the trees reflect the rewire) and after KB updates
   (so count docs no longer name dropped agents). **(AC4.)**

Parallelism summary: step 1 internally parallel; steps 1–2 may interleave; step 4 parallel with 3;
steps 3 and 5 are hard-ordered (3 before 5). `/aid-detail` decomposes these into tasks using the
measured density below as sizing input.

### Rewire Mechanism

How the `{old_agent → new_agent}` map is applied across the SOURCE dispatch surface. The
cross-reference pass (feature-001 audit + this feature's re-confirmation) has measured the surface;
treat these as **task-sizing input** for `/aid-detail`, not as a fixed edit list:

- **`SKILL.md` dispatch tables / State Detection blocks** — agent names in dispatch rows and
  state-machine assignments across `canonical/skills/*/SKILL.md`. High-density clusters:
  `aid-discover` (~218 agent-name occurrences across its tree, incl. all six `discovery-*`),
  `aid-execute` (~120), with a mid cluster and a low tail.
- **`references/*.md`** — `canonical/skills/*/references/state-*.md` and reviewer/brief docs that
  name agents in per-state assignments (e.g. `aid-execute/references/reviewer-{brief,guide}.md`,
  `task-type-rules.md`).
- **`canonical/templates/*`** — ~36 template files name agents (e.g. heartbeat/self-review protocol
  references, delivery-plan/spec templates that assign agents to tasks).
- **`canonical/recipes/*`** — recipe files that name an agent for a step.
- **The `aid-generate` SOURCE-exception** — if any of its dispatch text names an agent, it is
  rewired in place at `.claude/skills/aid-generate/` (hand-edit), since it is not generated.

> **`aid-` naming constraint (REQUIREMENTS §7).** Because the approved roster prefixes every agent
> with `aid-`, FR6 now renames ALL agent references to their `aid-`prefixed names — there are no bare
> "keep" rows, so every dispatch site (including the 8 formerly-keep namesakes) is rewritten. FR9's
> sweep set is therefore all 22 bare names, and the consistency check must assert **zero surviving
> bare (unprefixed) names** anywhere.

**Disposition handling:**
- `rename` (1→1, the 8 `aid-` namesakes) → textual replace `old`→`new` (i.e. bare `<name>` →
  `aid-<name>`) at every site. Use word-boundary matching to avoid substring collisions (e.g.
  `discovery-architect` vs `architect`); verify each replacement does not corrupt a longer name.
- `merge` (N→1) → every old name in the merge group maps to the single `new_agent`; multiple olds
  collapse to one new at each site (dedupe if two merged agents appeared in the same dispatch list).
- `drop` → remove the reference and the dispatch logic that depended on it; a `drop` with surviving
  references is a FR9 failure. Dropped agents have no `new_agent`, so there is nothing to point sites
  at — the dispatch must be restructured per the disposition's `dispatch_rewrite_hint`.

**Generated-tree guard:** the rewire NEVER edits files under `profiles/<tool>/` (except the
`aid-generate` skill). Those are reconciled by step 3. A rewire edit landing in a generated path is
a defect — the determinism gate would revert it. The repo-root `.claude/` dogfood tree is likewise
not a rewire target (it is neither SOURCE nor a generator output; see B2).

### Regeneration & Build Validation

**Fix the generator's own stale references first (FR7 explicit sub-requirement).** The
`aid-generate` skill currently lags the five-profile reality and must be corrected (hand-edited; it
is the SOURCE-exception):
- `SKILL.md` line 4 + line 15: "Regenerates the **three** install trees (claude-code, codex,
  cursor)" → five (claude-code, codex, cursor, copilot-cli, antigravity).
- `SKILL.md` line 8: `argument-hint` `--tool claude-code|codex|cursor` enum → five-value enum (or,
  better per FR7, derive the enum from `ls profiles/*.toml` rather than hardcoding).
- `SKILL.md` line 61: State-Detection `--tool {claude-code|codex|cursor}` default
  `[claude-code, codex, cursor]` → all five profiles.
- RENDER/REPORT body (output-root anchor lines 130–134; three-profile summary 222–239): output roots shown as `{tool}/` and the three-profile
  per-profile summary / `git diff --stat -- claude-code/ codex/ cursor/` → the actual
  `profiles/<tool>/...` output roots and five-profile summary.
- The VERIFY report path points at `.aid/work-002-canonical-generator/` (a different work) — update
  to a valid path for this run.
- `render_agents.py` header comment (lines 6–7) still says "markdown … and TOML (Codex)" / "both
  markdown … and TOML" — update to the four current format branches (`markdown`/`toml`/
  `copilot-agent`/`antigravity-rule`) if the Generation decision touches the renderer.

**Run the generator for all five profiles.** Per `aid-generate/SKILL.md` RENDER, for each profile
run `render_agents.py`, `render_skills.py`, `render_templates.py` (and `render_recipes.py` /
`render_canonical_scripts.py` per the renderer set in `architecture.md` line 123) with
`--canonical-root .` `--profile profiles/<tool>.toml` `--output-root profiles/<tool>/<install_root>`.
`render_agents.py` `render_agents()` globs `canonical/agents/*/AGENT.md` (line 640) and dispatches on
`profile.agent.format`: `markdown` (claude-code, cursor), `toml` (codex,
`_render_codex_toml`), `copilot-agent` (copilot-cli, `.agent.md`), `antigravity-rule` (antigravity,
`.agent/rules/*.md`). Each branch applies `substitute_filenames` + `rewrite_install_paths` (lines
456–469). If the Format/Generation decision changed the canonical agent shape, confirm each of the
four branches still renders a valid file for it (no new per-tool special-casing — feature-001's
decision criterion ii).

**The repo-root `.claude/` dogfood tree is NOT regenerated by this step.** Investigation of this
worktree confirms `/aid-generate` emits only to each profile's `output_root` (the claude-code
profile's is `profiles/claude-code/.claude`, per `profiles/claude-code.toml` line 6 / SKILL.md
RENDER lines 130–134) — there is **no** rsync/copy/sync step in the `aid-generate` skill, its
`scripts/` (`render_*.py`, `verify_*.py`, `aid_profile.py`), or CI (`test.yml`) that propagates
`profiles/claude-code/.claude` → the repo-root `.claude/`. (`aid_profile.py` line 64's
`"profiles/claude-code/.claude" → ".claude"` mapping is `install_root()` deriving a path-rewrite
*basename* for skill bodies, not an output target.) The repo-root `.claude/` is therefore a
committed dogfood convenience mirror kept current out-of-band, outside this feature's regeneration
step and terminal gates; it is excluded from the FR9 sweep (see B2 and *Consistency Check Method*).

**What "the repo builds/validates" means here (AC5):**
- **Hard gate:** `verify_deterministic.py --canonical-root .` exits 0 — its three sub-checks
  (byte-identical re-render, file-presence audit against the manifest, frontmatter parse of every
  emitted `.md`/`.toml`) all pass. A non-zero exit aborts (per SKILL.md VERIFY).
- **Self-test:** `render_agents.py --self-test --canonical-root .` passes (renders twice per profile,
  asserts byte-identical) for all five `profiles/*.toml`.
- **Grade/CI:** the repo grade harness `canonical/scripts/grade.sh` (rendered into each tree) runs
  clean, and the `test.yml` CI workflow / `tests/run-all.sh` aggregator passes. The KB-hygiene CI
  check (which validates the embedded canonical INDEX script path — see memory note) stays green;
  if INDEX.md is regenerated it must be via `canonical/scripts/kb/build-kb-index.sh`.
- `verify_advisory.py` is advisory (always exits 0); not a gate.

### KB & Count Updates

Refresh every agent-count / tier / roster statement, **parameterized over the new roster** (the
literal numbers come from the post-rollout `canonical/agents/` count and the new `proposed_tier`
distribution — not pre-assumed here). Exact known sites:

| Doc | Line(s) | Current (stale-after-rollout) text | Update to |
|-----|---------|-------------------------------------|-----------|
| `module-map.md` | 6 | "the 22 agents, the 13 renderer…" | new agent count |
| `module-map.md` | 15 (T1 fact) | "22 agents under canonical/agents/ (10 large / 9 medium / 3 small)" | new count + new tier split |
| `module-map.md` | 98–146 (§2 tiers) | "### 2a. Large tier (10) …", "### 2b. Medium tier (9) …", "### 2c. Small tier (3) …", and line 146 boilerplate-presence claim | per-tier rosters + per-tier counts; reconcile the boilerplate claim with the Format decision |
| `architecture.md` | 38, 64 | "22 agents", "22 agent dirs (AGENT.md + README.md each)" | new count; AGENT.md+README.md only if the Format decision keeps that shape |
| `architecture.md` | 190–197 (§3) | "Three-tier agent dispatch", "10 Large, 9 Medium, 3 small" diagram reference | new tier model/counts (or note if the tier model itself changed per REQUIREMENTS §7) |
| `README.md` | 231 | "AID defines 22 agents across three tiers." | new count |
| `README.md` | 323, 369 | "`.claude/agents/` — 22 agent markdown files", "22 agent definitions" | new count |

Discover any other agent-describing KB doc via `.aid/knowledge/INDEX.md` and grep for the literal
old count ("22 agent") and for OLD agent names. The FR8 update set and the FR9 sweep set are
reconciled in *Consistency Check Method* (FR8 fixes the count docs; FR9 then asserts no OLD name
survives in them).

### Consistency Check Method

The FR9 verification (AC4). Concrete, repo-wide, reviewer-runnable:

1. **Build the OLD-name sweep set** from `migration-map.md`: every `old_agent` whose `disposition`
   ∈ `{merge, rename, drop}`. Under the REQUIREMENTS §7 `aid-` constraint there are **no `keep`
   rows**, so the sweep set is **all 22 bare names** — the check must assert that no bare
   (unprefixed) old name survives anywhere (the 8 renamed namesakes included).
2. **Grep every OLD name** across the full surface, with word-boundary matching to avoid substring
   false-positives (e.g. `architect` inside `discovery-architect`):
   - SOURCE: `canonical/skills/**/SKILL.md`, `canonical/skills/**/references/*.md`,
     `canonical/templates/**`, `canonical/recipes/**`, `canonical/agents/**`, the `aid-generate`
     SOURCE-exception.
   - KB: `.aid/knowledge/**` (incl. `architecture.md`, `module-map.md`), `README.md`,
     `CONTRIBUTING.md`, `coding-standards.md`.
   - GENERATED: all five `profiles/<tool>/` trees (the generator's only output surface).
   - **Excluded:** the repo-root `.claude/` dogfood convenience tree. The generator does not emit
     to it and no in-repo sync step refreshes it (see *Regeneration & Build Validation* + B2), so
     this feature has no defined mechanism to fix an OLD name there; sweeping it would assert an
     unfixable surface. It is a separately committed mirror refreshed out-of-band and is outside
     AC4's gate.
3. **Assert zero matches** for every OLD name in the sweep set across all of the above. Any nonzero
   match = a dangling reference = AC4 failure.
4. **Reconcile with FR8/the rendered trees:** a match in a *generated* tree means the SOURCE was
   rewired but not re-rendered (re-run FR7); a match in a *count doc* means FR8 missed a site (fix
   it); a match in `canonical/` means FR6 missed a site (rewire it). The sweep distinguishes the
   three so the fix is targeted. The sweep is re-run after each fix until clean.
5. **Closure check:** confirm `canonical/agents/` directory set equals the `proposed_agent` set from
   `target-roster.md` (no dropped dir survives, no proposed agent is missing).

### Acceptance Criteria mapping

| AC (this SPEC / REQUIREMENTS §9) | Precise verification |
|----------------------------------|----------------------|
| **AC7** — each new agent definition conforms to the chosen format with reduced boilerplate (FR5 + principle 3) | For every `proposed_agent`, its `canonical/agents/<a>/` definition matches the structure mandated by `target-roster.md` → *Format decision*; the duplicated `## Heartbeat protocol`/`## Self-review discipline` burden is reduced as the Format decision specifies (verified by inspecting each new def + the boilerplate metric). |
| **AC4** — no `SKILL.md`, reference, KB doc, template, recipe, or install-tree file references a non-existent agent; consistency check clean (FR6 + FR9) | The *Consistency Check Method* sweep returns **zero** matches for every OLD-name in the sweep set across SOURCE + KB + templates + recipes + all five `profiles/<tool>/` rendered trees (the repo-root `.claude/` dogfood mirror is excluded — not a generator output, no in-repo sync; see B2); closure check (canonical/agents/ set == proposed roster set) passes. |
| **AC5** — `/aid-generate` runs without error, all five trees validate, repo builds (FR7) | `/aid-generate` completes for all five profiles; `verify_deterministic.py --canonical-root .` exits 0 (byte-identical re-render + presence audit + frontmatter parse); `render_agents.py --self-test` passes for all five `profiles/*.toml`; `canonical/scripts/grade.sh` + CI `test.yml`/`tests/run-all.sh` pass. |
| **AC6** — `architecture.md`, `module-map.md`, README counts (+ any other agent-describing KB doc) reflect the new model (FR8) | Every site in *KB & Count Updates* shows the new count/tier split; a grep for the old literal ("22 agent") and for OLD agent names across `.aid/knowledge/**` + `README.md` returns zero. |

### Out of Scope / Assumptions

**Out of scope:**
- Deciding the roster, count, format, or generation approach — all consumed from feature-001
  (re-litigating any disposition is out of scope).
- Any behavior change to a skill beyond the agent it dispatches (REQUIREMENTS §4 Out of Scope);
  no pipeline-phase or skill additions/removals.
- New host-tool render targets / install trees — the five stay as-is.
- Back-compat / deprecation shims for external adopters — they re-install regenerated trees.
- Hand-editing any generated tree (all generated content is produced by FR7 regeneration).
- Refreshing the repo-root `.claude/` dogfood convenience tree — the generator does not emit to it
  and no in-repo sync step exists; it is kept current out-of-band and is excluded from both FR7
  regeneration and the FR9 sweep (see B2).

**Assumptions / decisions to confirm:**
- **B1 — feature-001 approved precondition.** This feature is blocked until
  `design/target-roster.md` + `design/migration-map.md` exist and are approved at the work's single
  gate. Confirm the artifact home matches feature-001's A1 (`.aid/work-001-agents-review/design/`,
  possibly a combined `roster-decision.md`); this spec reads whichever physical layout feature-001
  produced.
- **B2 — repo-root `.claude/` dogfood tree is OUT of FR7 regeneration and the FR9 sweep (resolved
  decision).** Investigation of this worktree settled the open question: although `architecture.md`
  line 92 labels the repo-root `.claude/` a dogfood install tree, the generator does **not** emit to
  it. `/aid-generate` renders only into each profile's `output_root` (claude-code →
  `profiles/claude-code/.claude`, per `profiles/claude-code.toml` line 6 / SKILL.md RENDER lines
  130–134), and there is **no** rsync/copy/sync step in the `aid-generate` skill, its `scripts/`, or
  CI (`test.yml`) that propagates `profiles/claude-code/.claude` → repo-root `.claude/` (the
  `aid_profile.py` line 64 `→ ".claude"` mapping is an `install_root()` path-rewrite basename, not an
  output target). Decision: this feature scopes the repo-root `.claude/` dogfood tree **out** of both
  the FR7 regeneration step (step 3 emits to `profiles/<tool>/` only) and the FR9 sweep — so AC4
  asserts no surface this feature cannot fix. The repo-root `.claude/` is a separately committed
  convenience mirror kept current out-of-band; refreshing it is not part of this feature's terminal
  gates. (If a future feature adds a real dogfood-sync mechanism, the sweep can re-include it then.)
- **B3 — generator may or may not need changes.** Whether `render_agents.py` / `profiles/*.toml`
  are edited depends entirely on `target-roster.md` → *Generation decision*. If the Format decision
  keeps the per-agent `AGENT.md` shape, the renderer is untouched except for the FR7 stale-ref fixes;
  if it changes the source shape, the four format branches are revalidated/adjusted.
- **B4 — word-boundary matching for all rewire + sweep operations** to avoid substring collisions
  among agent names (notably `architect` ⊂ `discovery-architect`). Confirmed as a hard requirement,
  not an optimization.
- **B5 — count/tier literals are derived, not pre-set.** Every number in *KB & Count Updates* is
  computed from the post-rollout `canonical/agents/` count and the new `proposed_tier` distribution;
  this spec deliberately states no target count (REQUIREMENTS §6).
- **B6 — A5 boilerplate-stale-KB carry-over.** feature-001 A5 noted `module-map.md` line 146 and
  `coding-standards.md §8e` make stale boilerplate-presence claims; FR8 corrects these as part of
  the KB refresh so the post-rollout KB is internally consistent with the Format decision.

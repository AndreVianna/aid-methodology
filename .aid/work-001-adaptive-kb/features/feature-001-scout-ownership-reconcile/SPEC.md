# Reconcile discovery-scout Doc Ownership

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-30 | Feature drafted from approved REQUIREMENTS.md | /aid-interview FEATURE-DECOMPOSITION |
| 2026-05-30 | Cross-ref fixes: framed as three-way contradiction incl. discovery-quality; agent-prompts.md noted as already-consistent | /aid-interview (cross-reference) |
| 2026-05-31 | Technical Specification drafted | /aid-specify |
| 2026-05-31 | Review fix (E→target A): corrected discovery-quality evidence; added quality AGENT.md to edit list (multi-surface reconciliation) | /aid-specify |

## Source

- REQUIREMENTS.md §4 (P0 — Pre-work / correctness), FR-P0-1

## Description

The discovery doc-ownership for `infrastructure.md` is a **multi-surface contradiction** spanning
**both** discovery agent definitions. The source of truth (the GENERATE dispatch table in
`state-generate.md:72`, the `## Quality` prompt in `agent-prompts.md:114`, and the
Targeted-Discovery map in `SKILL.md:273`) assigns `infrastructure.md` to **quality** and gives
scout `project-structure.md` + `external-sources.md` (`SKILL.md:269`, `agent-prompts.md:13–21`,
`state-generate.md:41`). But two agent definitions diverge from that truth:

1. **`discovery-scout`'s AGENT.md over-claims infrastructure and under-claims external-sources.**
   Its frontmatter `description` (`discovery-scout/AGENT.md:3`) and `## What You Do`
   (`discovery-scout/AGENT.md:68`) both say it produces `infrastructure.md` and
   `project-structure.md`, and it never mentions `external-sources.md` at all (which the dispatch
   table and prompt actually assign to it).
2. **`discovery-quality`'s AGENT.md fails to claim infrastructure and wrongly disclaims it.** Its
   `## What You Do` `Produce` line (`discovery-quality/AGENT.md:68`) lists only
   `test-landscape.md` and `tech-debt.md` — `infrastructure.md` is absent — and its
   `## What You Don't Do` (`discovery-quality/AGENT.md:75`) reads "Map infrastructure or open
   questions (that's Discovery Scout)", i.e. quality **disclaims** infrastructure and hands it to
   scout — the inverse of the dispatch-table truth.

`agent-prompts.md` is the one surface that is already consistent (`## Scout` produces structure +
external-sources; `## Quality` produces infrastructure). The divergent sources are therefore the
`discovery-scout` agent definition (AGENT.md + README) **and** the `discovery-quality` agent
definition (AGENT.md). This feature reconciles ownership to a single, unambiguous source of truth
across all affected files — scout claims structure + external-sources and disclaims infra; quality
claims infra and stops disclaiming it — so every surface agrees. It is a correctness fix that
de-risks the later declared-set work, since the declared set will replace exactly this scattered
ownership prose.

## User Stories

- As a discovery sub-agent (scout), I want one authoritative statement of which docs I own so
  that I generate exactly the right set without conflicting instructions.
- As an AID meta-repo maintainer, I want scout ownership to be internally consistent so that
  the upcoming declared doc-set has a clean, correct baseline to encode.

## Priority

Must

## Acceptance Criteria

- [ ] Given `infrastructure.md` ownership diverges on two agent surfaces (scout's agent-def
      claims it; quality's agent-def both omits it from `## What You Do` and disclaims it in
      `## What You Don't Do`), while SKILL/state-generate/agent-prompts assign it to quality,
      when reconciled, then scout's agent-def claims `project-structure.md` + `external-sources.md`
      and disclaims infra, quality's agent-def claims `infrastructure.md` and no longer disclaims
      it, and all ownership prose agree on a single owner for every doc.
- [ ] Given the reconciliation, when discovery runs, then each agent generates exactly its
      reconciled doc set with no contradictory ownership instruction remaining anywhere.
- [ ] Given the change, when the generator self-tests and the existing canonical suites (13 today) run, then
      they stay green and render-drift across the 3 profiles is clean (non-regression).

---

## Technical Specification

> **Repo reality.** AID is a methodology/tooling repo: Markdown agent/skill definitions
> rendered into install trees by `run_generator.py`. There is no DB/API/UI. "Doc ownership" is
> *prose* in agent and skill source files, not a runtime data structure. `canonical/` is the
> single source of truth; the renderer emits 3 profiles under `profiles/` (claude-code, codex,
> cursor) which must stay byte-identical to canonical, and the root `.claude/` dogfood tree is
> AID-installed-on-AID (refreshed via `setup.sh`). Therefore **every ownership edit is made in
> `canonical/` and re-rendered** — never hand-edited in `profiles/` or `.claude/`.

### Authoritative ownership decision

The source of truth for "which agent generates which doc" is the **GENERATE dispatch table** in
`canonical/skills/aid-discover/references/state-generate.md` (the dispatch table at lines 67–72
and the Step 1 scout block at line 41), because that is the table the orchestrator actually reads
at generation time to decide what to dispatch. The `## Scout`/`## Quality` prompt sections in
`canonical/skills/aid-discover/references/agent-prompts.md` (the literal prompts handed to each
sub-agent) **already agree** with it, as does the SKILL.md Targeted-Discovery mapping
(`canonical/skills/aid-discover/SKILL.md:269,273`). The divergent strands are the **two discovery
agent definitions**: `discovery-scout`'s AGENT (over-claims `infrastructure.md`, under-claims
`external-sources.md`) plus its human-facing README, **and** `discovery-quality`'s AGENT (omits
`infrastructure.md` from its `## What You Do` `Produce` line and disclaims it in `## What You
Don't Do`). The fix converges **both** agent defs onto the already-dominant dispatch-table/prompt
truth — no behavioral table changes.

| Doc | Correct owner | Source-of-truth rationale |
|-----|---------------|---------------------------|
| `infrastructure.md` | **discovery-quality** | Source of truth assigns it to quality: state-generate dispatch table — `state-generate.md:72` row reads "discovery-quality \| test-landscape.md, tech-debt.md, infrastructure.md"; agent-prompts `## Quality` (`agent-prompts.md:114`) "produce … `.aid/knowledge/infrastructure.md`"; SKILL Targeted-Discovery map (`SKILL.md:273`) "`discovery-quality` \| test-landscape.md, tech-debt.md, infrastructure.md". **Both agent defs diverge:** quality's `## What You Do` `Produce` line (`discovery-quality/AGENT.md:68`) lists only "test-landscape.md, tech-debt.md" (infra absent) **and** its `## What You Don't Do` (`discovery-quality/AGENT.md:75`) says "Map infrastructure or open questions (that's Discovery Scout)" — wrongly handing infra to scout; while scout's AGENT (`discovery-scout/AGENT.md:3,68`) + README (`discovery-scout/README.md:25`) over-claim it. → **quality AGENT corrected to claim infra and drop the disclaimer; scout AGENT/README corrected to drop infra.** |
| `project-structure.md` | **discovery-scout** | Unanimous: state-generate Step 1 (`:41`) + scout pre-pass dispatch, agent-prompts `## Scout` (`agent-prompts.md:13`), SKILL map (`SKILL.md:269`), scout AGENT (`discovery-scout/AGENT.md:68`). No conflict → unchanged. |
| `external-sources.md` | **discovery-scout** | state-generate Step 1 (`:41`), agent-prompts `## Scout` (`agent-prompts.md:19–21`), SKILL map (`SKILL.md:269`) all assign it to scout. Scout AGENT **never states it** (under-claim) → **add the explicit claim** so ownership is stated, not implied. |

No other disputed doc found. The remaining standard docs each have exactly one consistent owner
across all surfaces. **Verified by grep:** extracting the `Produce \`.aid/knowledge/…\`` line
from each `canonical/agents/discovery-*/AGENT.md` `## What You Do` yields — architect →
`architecture.md, technology-stack.md` (`discovery-architect/AGENT.md:69`); analyst →
`module-map.md, coding-standards.md, schemas.md` (`discovery-analyst/AGENT.md:68`); integrator →
`pipeline-contracts.md, integration-map.md, domain-glossary.md` (`discovery-integrator/AGENT.md:69`)
— each of which matches its dispatch-table row (`state-generate.md:69–71`) exactly. Only the
scout and quality `Produce` lines disagree with the table; the analyst/architect/integrator
triple is already consistent. (`feature-inventory.md`, `README.md`, `INDEX.md` are
orchestrator-owned, no sub-agent — `SKILL.md:274`.) The new ownership-consistency suite (Test
plan §1) encodes this grep as a standing regression guard.

### Files & edits (all in `canonical/`; then re-render)

1. **`canonical/agents/discovery-scout/AGENT.md`** — the primary divergent source.
   - **Frontmatter `description` (line 3):** before → "Maps deployment infrastructure, CI/CD
     pipelines, and identifies gaps … Produces **infrastructure.md and project-structure.md**".
     after → re-scope the description to structure + external sources (scout's real role per the
     dispatch table is the pre-pass: project structure + external documentation), and drop the
     `infrastructure.md` claim. Intent: description must name `project-structure.md` and
     `external-sources.md`, not `infrastructure.md`.
   - **Body `## What You Do` (line 68):** before → "Produce `.aid/knowledge/infrastructure.md`
     and `.aid/knowledge/project-structure.md`". after → "Produce
     `.aid/knowledge/project-structure.md` and `.aid/knowledge/external-sources.md`". Also adjust
     the surrounding bullets (lines 65–67) that frame scout as the *infrastructure mapper* so the
     "What You Do" reads as structure + external-source mapping, not deployment-infra mapping.
   - **Body `## What You Don't Do` (lines 70–75):** add a line disclaiming infrastructure —
     "Map infrastructure or deployment (that's Discovery Quality)". Today scout's `## What You
     Don't Do` (`discovery-scout/AGENT.md:74`) only disclaims "tests or security"; it does not
     disclaim infra. After this edit scout's disclaimer and quality's reciprocal claim point the
     same way (infra → quality). **Note:** this is the *inverse* of the prior draft's plan, which
     wrongly proposed mirroring `discovery-quality/AGENT.md:75` — that line actually reads "Map
     infrastructure or open questions (that's Discovery Scout)", i.e. quality currently hands
     infra TO scout, so it must be retargeted in edit #3 below, not mirrored.
   - **`## Output Documents` block (lines 85–138):** the embedded `### .aid/knowledge/infrastructure.md`
     template currently lives in scout. **Move/remove it** — the authoritative `infrastructure.md`
     output template is the canonical KB template (`canonical/templates/knowledge-base/infrastructure.md`)
     and quality's prompt; scout's Output Documents must show `project-structure.md` +
     `external-sources.md` only. Replace the infrastructure template here with an
     `external-sources.md` shape (or reference the canonical template), and keep the
     `project-structure.md` description.
   - **`## When to Escalate` (lines 149–151) + line 143:** the escalation bullets reference
     "No CI/CD config", "IaC files", and "infrastructure.md" — retarget these to scout's actual
     outputs (structure / external sources) since infra escalation now belongs to quality.

2. **`canonical/agents/discovery-scout/README.md`** (human-facing; rendered alongside).
   - **Line 25:** before → "`.aid/knowledge/infrastructure.md` — deployment pipelines, IaC…".
     after → "`.aid/knowledge/external-sources.md` — external documentation ingested into the KB".
   - **Lines 9–13 / "What It Does":** the deployment-infrastructure framing (items 2) should be
     re-pointed to external-documentation + structure. Keep item 3 (reads external docs) and
     promote external-sources.md to a first-class produced doc in `## What It Produces`.

3. **`canonical/agents/discovery-quality/AGENT.md`** — **second divergent source** (the prior
   draft wrongly called this "already correct"). Verified on disk: line 68 reads "Produce
   `.aid/knowledge/test-landscape.md`, `.aid/knowledge/tech-debt.md`" (no infrastructure.md) and
   line 75 reads "Map infrastructure or open questions (that's Discovery Scout)" — quality both
   omits infra from what it produces AND disclaims it. Two edits:
   - **Body `## What You Do` `Produce` line (line 68):** before → "Produce
     `.aid/knowledge/test-landscape.md`, `.aid/knowledge/tech-debt.md`". after → "Produce
     `.aid/knowledge/test-landscape.md`, `.aid/knowledge/tech-debt.md`,
     `.aid/knowledge/infrastructure.md`" so quality's self-understanding matches the dispatch
     table (`state-generate.md:72`) and its own prompt (`agent-prompts.md:114`, which already
     asks it to produce infrastructure.md). Optionally add an infra-mapping bullet alongside the
     existing test/security/debt bullets (lines 65–67) so the new claim is grounded.
   - **Body `## What You Don't Do` (line 75):** before → "Map infrastructure or open questions
     (that's Discovery Scout)". after → **remove the "Map infrastructure" half** (quality now
     owns infra, so it must not disclaim it). Open-question routing belongs to scout, so retarget
     this line to "Map project structure or surface open questions (that's Discovery Scout)" —
     keeping scout's actual reconciled domain (`project-structure.md` + open-question consolidation
     per `discovery-scout/AGENT.md:67`) and dropping the infra reference entirely. The frontmatter
     `description` (line 3) lists only test-landscape + tech-debt and may optionally add
     infrastructure.md for symmetry, but the `## What You Do` `Produce` line is the surface the
     consistency suite checks.

4. **`canonical/skills/aid-discover/references/state-generate.md`** — **no ownership change.** The
   dispatch table (`:67–72`) and Step 1 (`:41`) are the authoritative truth and already correct.
   Left untouched by this feature. *(The "16"/count literals on lines 3, 9, 118–120 are
   FR-P0-4 / feature-004 scope, NOT this feature.)*

5. **`canonical/skills/aid-discover/SKILL.md`** — **no ownership change.** Targeted-Discovery map
   (`:269,273`) already correct. *(The "14" literal at `:144,150` is FR-P0-4 / feature-004 scope.)*

6. **`canonical/skills/aid-discover/references/agent-prompts.md`** — **no change.** `## Scout`
   already produces project-structure + external-sources; `## Quality` already produces
   infrastructure. Confirmed consistent.

**After editing canonical:** run `python run_generator.py`. This re-renders the 3 profiles
(`profiles/claude-code/.claude/agents/discovery-scout.md`, `profiles/codex/...`,
`profiles/cursor/...`, plus each README) and runs the built-in deterministic VERIFY (byte-identical
re-render, file-presence, frontmatter parse). The **dogfood `.claude/` tree refresh** (e.g.
`.claude/agents/discovery-scout.md`) is per REQUIREMENTS §4 a **separate maintenance task** and is
NOT gated by the render-drift CI job (which is scoped to `profiles/` only — the 4-tree
canonical+3-profile identity, not the 5th dogfood tree per `aid-discover/SKILL.md:46`). State
explicitly whether the dogfood refresh rides along in this feature's commit or is deferred.

### Flow impact

At GENERATE time (`state-generate.md`), the orchestrator reads the **dispatch table** to decide
which sub-agent to dispatch and which target files to verify (Step 1 scout, Steps 2–5 the four
parallel analysts). It hands each sub-agent the literal prompt from `agent-prompts.md`. The agent
definition's `## What You Do`/`## What You Don't Do` prose is the sub-agent's self-understanding of
scope. Today **both** scout's and quality's *self-understanding* (their AGENT.md files) contradict
the *dispatch + prompt*: the table dispatches quality (not scout) for infrastructure.md, yet
scout's def tells it to produce infrastructure.md and is silent on external-sources.md (which the
prompt *does* ask it for), while quality's def omits infrastructure.md from its `Produce` line and
disclaims it ("that's Discovery Scout"). This feature aligns both agents' self-understanding to the
dispatch/prompt truth — scout drops infra and claims external-sources; quality claims infra and
stops disclaiming it. **No behavioral change to which docs get generated** — the dispatch table and
prompts (the things that actually drive generation) are untouched; only the now-consistent agent-def
prose changes, so every reference agrees and a future reader/declared-set (feature-004) encodes one
unambiguous owner per doc.

### Test plan

1. **Grep-based ownership-consistency check (new, proposed canonical suite).** Add
   `tests/canonical/test-discovery-doc-ownership.sh` (auto-discovered by `tests/run-all.sh`'s
   `tests/canonical/test-*.sh` glob — no run-all.sh edit needed). It asserts the **invariant**:
   for each standard KB doc, exactly one discovery agent "produces" it, and no doc is produced by
   two agents. Concretely:
   - Parse the authoritative dispatch table in `state-generate.md` (Step 1 scout block + the
     `[2/5]`–`[5/5]` rows) into a `doc → owner` map.
   - For each agent under `canonical/agents/discovery-*/AGENT.md`, extract its "Produce
     `.aid/knowledge/<doc>.md`" claims from `## What You Do` and frontmatter `description`, **and**
     scan its `## What You Don't Do` for any "Map <doc>" disclaimer that contradicts the agent's
     own dispatch-table assignment (this is what catches quality:75's "Map infrastructure …
     (that's Discovery Scout)" disclaimer once quality is the assigned owner).
   - **Assert:** (a) the union of agent `Produce` claims equals the dispatch map exactly (no doc
     claimed by an agent the table doesn't assign it to; no doc the table assigns left unclaimed);
     (b) no doc appears in two agents' claims; and (c) no agent disclaims a doc the table assigns
     TO it. Because the contradiction spans BOTH scout (over-claims infra / under-claims
     external-sources) AND quality (omits infra from `Produce`, disclaims it in `What You Don't
     Do`), the suite must fail on the current tree for **both** agents and pass only after both are
     reconciled. This makes the feature-001 contradiction a *failing test* on a regressed tree and a
     passing test after the fix. Follow the existing suite shape
     (`tests/canonical/test-read-setting.sh`: `source ../lib/assert.sh`, `set -u`, `--verbose`,
     exit 0/1).
   - This suite is **deliberately ownership-only** (not doc-count) so it does not collide with
     feature-004's FR-P0-4 count work.
2. **Generator self-tests green:** `python .claude/skills/aid-generate/scripts/render_lib.py
   --self-test` + `test_manifest_safety.py` + `render_canonical_scripts.py --self-test` +
   `verify_deterministic.py --self-test` + `verify_advisory.py --self-test` (the exact set CI runs,
   `.github/workflows/test.yml:92–96`).
3. **Render-drift clean across 3 profiles:** `python run_generator.py` then `git diff --exit-code
   -- profiles/` returns clean (the CI `render-drift` job, `test.yml:36–40`). The built-in VERIFY
   (byte-identical re-render / file-presence / frontmatter parse) must print PASS.
4. **Existing 13 canonical suites stay green:** `bash tests/run-all.sh` reports "ALL N CANONICAL
   SUITES PASSED" (N = 13 existing + 1 new = 14; the gate is "existing green + new pass", not a
   pinned total, per REQUIREMENTS §7).
5. **Manual rendered-text read (self-review):** read **both** rendered agents.
   - `profiles/*/.claude/agents/discovery-scout.md` — confirm the description, What-You-Do,
     What-You-Don't-Do, Output-Documents, and Escalate sections all show structure +
     external-sources and never `infrastructure.md` as a scout output (scout now disclaims infra).
   - `profiles/*/.claude/agents/discovery-quality.md` — confirm `## What You Do` `Produce` line now
     includes `infrastructure.md`, and `## What You Don't Do` no longer disclaims infrastructure
     (the "that's Discovery Scout" line is retargeted away from infra). The two agent defs must be
     reciprocal: infra appears under quality and is disclaimed by scout.

### Backward compatibility & risks

- **No change to generated KB for a standard project.** The dispatch table and agent prompts —
  the only inputs that drive what gets generated — are unchanged. quality is still dispatched for
  and prompted to produce `infrastructure.md` (`state-generate.md:72`, `agent-prompts.md:114`);
  this feature only adds that claim to quality's AGENT *prose* so its self-understanding matches
  what it is already dispatched to do. scout still produces `project-structure.md` and (now
  explicitly in prose) `external-sources.md`, which it already produced in practice per the prompt.
  The set of docs and their content generators are identical pre/post.
- **Dogfood re-render requirement (call-out).** The root `.claude/` tree is AID-on-AID and is a
  *separate maintenance task* (REQUIREMENTS §4, line 136); the render-drift gate does not cover it.
  Risk: leaving `.claude/agents/discovery-scout.md` stale makes the dogfood install disagree with
  canonical. Mitigation: either refresh `.claude/` in the same commit (preferred, cheap) or
  explicitly log the deferral so it isn't silently divergent.
- **Risk: scout's embedded `infrastructure.md` template (AGENT.md:87–138) is content, not just a
  one-line claim.** Moving it is a larger edit than a label swap; the canonical KB template
  (`templates/knowledge-base/infrastructure.md`) is the authoritative shape, so scout's copy is
  removable without losing the template. Verify quality's prompt/template still fully covers the
  infrastructure shape after removal. **Note:** quality's AGENT today does NOT embed an
  `infrastructure.md` template in its `## Output Documents` (it shows only test-landscape.md and
  tech-debt.md, `discovery-quality/AGENT.md:87,125`); quality relies on the canonical KB template
  for infra shape. This feature's quality edit is a prose/claim alignment — adding the infra
  template body to quality's `## Output Documents` is optional and, if done, should reference the
  canonical template rather than duplicate it.
- **Cross-feature dependency (feature-004 declared-doc-set).** feature-004 (FR-P0-4 / FR-P1-1)
  will *replace* this scattered ownership prose with a declared `{filename, owner, presence}` set.
  This feature is the **clean baseline** for that: it guarantees a single unambiguous owner per
  doc before feature-004 encodes it, and the new ownership-consistency suite becomes the
  regression guard the declared set must continue to satisfy. **Sequencing:** feature-001 lands
  first (de-risks feature-004). The doc-**count** literals ("14"/"16") are explicitly *not* touched
  here — they are feature-004's FR-P0-4 scope.

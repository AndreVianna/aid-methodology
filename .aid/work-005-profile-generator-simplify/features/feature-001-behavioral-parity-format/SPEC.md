# Behavioral-Parity Format

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-20 | Feature identified from REQUIREMENTS.md §5 FR4/FR4a/FR4-distinction, §3, §8 A1/A2/A3, §9 AC4a/AC4b | /aid-interview |
| 2026-06-20 | Added early FR4a inputs from all-tools research: Codex TOML-native dispatch question (the real FR4 exception candidate), Cursor AGENTS.md reliability, always-on token cost | /aid-interview |
| 2026-06-20 | Technical Specification drafted (aid-specify); codebase Finding D1: AID uses NO host-native dispatch (prose `Agent(subagent_type: aid-<name>)`) → Codex needs no TOML exception (uniform markdown expected, TOML test-gated fallback). 5 decisions confirmed: 5 axes (token-cost=note), embedded-table companion, work-local-then-ship KB home, uniform-markdown-for-Codex. | /aid-specify |
| 2026-06-20 | A+ review (B+ → fix): removed `aid-housekeep` from D1's dispatch-site list (no literal site, delegated only); softened always-on Migration bullet "confirms"→"verifies whether" to match the verify-item framing | /aid-specify REVIEW |
| 2026-06-20 | Study apparatus slimmed + AC4a widened (intent-fidelity review correction): collapsed 3-artifact apparatus (study + separate cite-join ledger + decision record) into ONE `capability-study.md` (per-tool table + short decision section); DROPPED the separate Artifact-2 machine-checkable cite-join ledger as process-theater for a 5-row, D1-mostly-settled decision (column shape, E-CODEX-1, verify-first, AC4b-cite all kept). AC4a behavioral sample widened to the work's actual 3-tool scenario (Cursor + Claude Code + Codex); Copilot CLI + Antigravity parity named as asserted-via-Finding-D1, not exercised | intent-fidelity review |
| 2026-06-20 | Re-gate (C+ → fix): Layers row "two .aid/ artifacts" → "one (`capability-study.md`)"; Description "study confirms always-on" → "verifies" (match verify-item framing) | /aid-specify REVIEW |

## Source

- REQUIREMENTS.md §5 (FR4, FR4a, FR4-distinction)
- REQUIREMENTS.md §3 (Users & Stakeholders)
- REQUIREMENTS.md §8 (A1, A2, A3)
- REQUIREMENTS.md §9 (AC4a, AC4b)

## Description

Decide and define a single, uniform behavioral-parity format for AID's skills and
agents, so that a skill or agent behaves the same way no matter which host tool a
developer chooses. The decision is not made by assumption — its first deliverable is
a gating per-tool capability study covering all five supported tools (Claude Code,
Cursor, Codex, GitHub Copilot CLI, Antigravity). For each tool the study records how
the tool discovers and executes agents, skills, and rules; which formats it natively
supports; and — most importantly — the behaviorally-significant metadata it relies on:
activation (alwaysApply / glob / trigger / a skill's description), execution
(model, reasoning effort), capability (allowed tools / permissions), and
dispatchability (an invocable agent versus background reading). The study then maps,
per tool, how each piece of that metadata is preserved or translated when content is
re-encoded into the uniform format, so re-encoding can never silently change behavior.

Only once the study exists does the format decision follow from it: commit to uniform
markdown for both skills and agents (verify-first), keeping a native format only where
a tool is proven to require it, with any such exception documented. The container and
prose are uniform; behavioral metadata is never flattened away. This feature owns the
research and the format decision; it does not itself rewrite the generator.

**Early inputs (all-tools rules/format research, 2026-06-20 — verify against live docs):**
the always-on/rules question is already largely answered — every tool reads its root
context file (`CLAUDE.md`/`AGENTS.md`) as always-on context (this study **verifies** the
per-tool always-on *guarantee*, incl. the Cursor background-agent caveat), and a rules
folder is conditional/glob only (AID uses none), so always-on guidance folds into the
root file uniformly (this informs FR3). The open *format* question narrows to **agent dispatchability on Codex**:
Codex agents are TOML-native and markdown agents are not discovered as native subagents
(codex #15250) — so the study must determine whether AID relies on Codex-native **named
dispatch** (keep TOML as the documented FR4 exception) or **injects agents as prose**
(uniform markdown is fine). Codex is the only tool whose agent format truly diverges.
Secondary inputs: Cursor's `AGENTS.md` background-agent reliability, and always-on
token cost.

## User Stories

- As an AID adopter who freely chooses between Cursor and Claude Code, I want a representative skill and agent to behave the same in whichever tool I pick, so that my AID experience does not depend on my tool choice.
- As an AID maintainer, I want a documented per-tool capability study that captures each tool's discovery, execution, and behaviorally-significant metadata, so that the format decision rests on evidence rather than assumption and a future sixth tool can be assessed the same way.
- As an AID maintainer, I want the uniform-format decision to explicitly cite the study and call out any native-format exception, so that no format branch is deleted before its behavioral implications are understood.

## Priority

Must

## Acceptance Criteria

- [ ] Given the work is underway, when any format branch is about to be deleted, then the FR4a per-tool capability study has already been produced and documented — recording, for each of the 5 tools, its discovery/execution, natively-supported formats, and the behaviorally-significant metadata (activation, execution/model, capability/permissions, dispatchability) plus how each item is preserved/translated under the uniform format — and the FR4 format decision cites it. (AC4b)
- [ ] Given the study's parity criteria and a representative skill and a representative agent, when each is exercised across the **three tools this work's scenario uses (Cursor + Claude Code + Codex)**, then behavior is verified consistent against those criteria; Copilot CLI + Antigravity behavioral parity is **asserted by the Finding-D1 content-identity argument, not exercised** (CI cannot run five live runtimes) — named as a residual. (AC4a)

---

## Technical Specification

> **Feature character.** This is a **research + decision** feature, not a DB-backed
> application feature. Its deliverable is **one document** — a per-tool **capability study**
> (FR4a, `capability-study.md`) carrying a **short decision section** (the FR4 decision that
> cites it) — plus a one-time **behavioral-consistency verification** (AC4a). (The earlier
> separate cite-join ledger was dropped per the intent-review correction — see Data Model.)
> It produces **no generator code and no
> install-tree changes**; acting on the decision (collapsing the generator, deleting
> format branches, re-rendering profiles) is owned by **feature-002**. The honest section
> taxonomy below therefore marks most app-oriented conditional sections **N/A** rather
> than padding them.

### Section Applicability

**Core sections (adapted to a research/decision feature):**

| Section | Status | Adaptation |
|---------|--------|------------|
| Data Model | **Activated** | No relational schema (AID has none — `schemas.md`). The "data model" here is the **capability-matrix document schema**: the per-tool study's table shape + the embedded decision section (one doc). |
| Feature Flow | **Activated** | Not request→service→repo. The flow is the **study → decide → document → verify** workflow with its gates. |
| Layers & Components | **Activated** | Not code layers. The **files/docs this feature produces or touches** — the one new `.aid/` artifact (`capability-study.md`) + the read-only inputs it consumes. Explicitly excludes the generator (feature-002). |

**Conditional sections:**

| Section | Status | Rationale |
|---------|--------|-----------|
| AI Enhancements | **Activated** | The whole feature is about how AI **agents/skills** behave per host tool — agent dispatchability and activation/execution metadata are the subject matter. |
| Migration Plan | **Activated (study-only)** | No data migration. But the study must record the `.agents/`→`.codex/` and `.cursor/rules/`-drop **behavioral** implications (does retiring the split change dispatch?) so feature-002/003 can migrate safely. Scoped to *findings the study must surface*, not the migration mechanism itself. |
| Telemetry & Tracking | **Activated (light)** | The study's **confidence/verification-method** column is the only "telemetry" — how each finding was established (docs vs empirical) and its confidence. |
| API Contracts | **N/A** | AID ships no HTTP/RPC APIs (`pipeline-contracts.md`). The relevant "contract" — subagent dispatch — is covered under AI Enhancements + Data Model, not here. |
| UI Specs | **N/A** | No rendered UI. (The KB HTML viewer is untouched.) |
| Events & Messaging | **N/A** | Inter-skill choreography is filesystem hand-offs; no queues/events (`integration-map.md`). |
| DDD / CQRS / State Machines | **N/A** | No bounded contexts, no command/query split. (Skills are state machines, but this feature defines none.) |
| BDD Scenarios | **N/A** | AID has no Gherkin suite; AC4a is verified by a manual procedure, not BDD. |
| Security Specs | **N/A** | No auth/roles. (`allowed-tools`/permissions appear as a *capability metadata axis* in the study, not as a security requirement of this feature.) |
| Cache / Search / Batch / Mobile / Cloud / Hardware / Recovery | **N/A** | No performance, search, scheduled-work, mobile, cloud, hardware, or DR surface in a research/decision deliverable. |
| External Integrations | **N/A** | The study *reads* external vendor docs, but registers no runtime integration. (Vendor doc URLs are recorded as study citations, not integrations.) |

---

### Data Model — The Capability-Matrix Document Schema

There is **no relational database** in AID (`schemas.md`). The "data model" for this
feature is the **structured schema of the single FR4a study document** (`capability-study.md`):
the per-tool capability table plus an embedded short **decision section** that the FR4 decision
and AC4a verification consume.

> **Apparatus (intent-review correction, 2026-06-20):** Finding D1 settles **4 of the 5 tools
> before the study starts** — the only genuinely open surface is **one probe (E-CODEX-1)** plus
> re-confirming always-on. The earlier three-artifact apparatus (study + separate machine-checkable
> cite-join ledger + decision record) is therefore collapsed to **ONE study doc
> (`capability-study.md`) carrying the per-tool capability table, plus a short decision section**
> (the FR4 decision, citing D1 + the E-CODEX-1 result). The separate "machine-checkable cite-join
> ledger" and its "did-the-decision-follow-from-the-study" join-key ceremony are **dropped** as
> process-theater for a 5-row, ~80%-pre-answered decision. The per-tool table's **column shape is
> kept** (so a 6th tool slots in — NFR5), and the decision section's citation of the study
> satisfies AC4b.

#### Artifact 1 — `capability-study.md` (the single study doc: per-tool table + decision section)

A single markdown document with **one section per supported tool** (5 today, extensible
to a 6th — NFR5) **plus a short decision section** (the FR4 decision). Each tool section
carries a **Capability Matrix** table with a fixed column set so the document is diffable
and a future tool slots in identically.

**Per-tool Capability Matrix — column schema (one row per behavioral axis):**

| Column | Meaning | Allowed values / shape |
|--------|---------|------------------------|
| `Axis` | Which behavioral dimension | one of: `discovery` · `execution-model` · `activation` · `capability/permissions` · `dispatchability` (the FR4-distinction metadata set, plus discovery) |
| `Native mechanism` | How the tool natively expresses this axis | free text + the native key (e.g. Claude `model:` frontmatter; Cursor `alwaysApply:`; Antigravity `trigger: always_on`; Codex `model_reasoning_effort`) |
| `Native format` | The format the tool natively reads for this asset kind | `markdown` · `markdown+yaml` · `toml` · `.agent.md` · `rule-md` |
| `Uniform-markdown encoding` | How AID's uniform markdown carries the same behavior | the markdown frontmatter key/value or prose that translates to the native mechanism |
| `Preserve / Translate / Drop` | The mapping verdict for this axis under uniform markdown | `preserve` (carried verbatim) · `translate` (re-expressed in the tool's idiom by the generator) · `gap` (tool runtime cannot match — documented, never silently dropped) |
| `Verification` | How the finding was established | `docs:<url-or-citation-id>` · `empirical:<test-id>` · `both` |
| `Confidence` | Reviewer-checkable confidence | `high` · `medium` · `low` (low requires a follow-up note) |

> **Confirmed (2026-06-20):** the five axes (`discovery`, `execution-model`, `activation`,
> `capability/permissions`, `dispatchability`) are the complete axis set — FR4-distinction's
> four metadata classes plus `discovery` (how the tool finds the asset at all, which precedes
> the four). **`token-cost` (FR4a early-input #3) is a per-tool prose note, not a sixth axis**
> (it is a cost, not a behavior dimension).

Each tool section also carries a short **prose header**: tool + version pinned, the
asset kinds it supports (agents / skills / rules), and its **always-on guarantee** verdict
(the FR3/A1 question — does the root context file load on *every* request, including the
Cursor background-agent caveat and the Antigravity v1.20.3+ check).

#### The decision section (inside `capability-study.md`) — the FR4 verdict

Records the verdict per `(tool, asset-kind)`: **uniform markdown** or a **documented
native exception**, with the "provably required" justification (defined under Feature Flow)
and a citation back into the per-tool capability table above. For a 5-row, mostly-D1-settled
decision this is a **short prose-plus-table section, not a separate machine-checkable
cite-join ledger** — citing the study rows it follows from (which discharges AC4b's "the FR4
decision cites the study"). It explicitly cites **D1** (the 4 tools D1 settles) + the
**E-CODEX-1 result** (the one open probe).

> **Confirmed (2026-06-20, intent-review correction):** the decision lives **inside the one
> `capability-study.md` doc** as a short decision section with an embedded per-`(tool,asset-kind)`
> verdict table — the AID-idiomatic shape (cf. the reviewer-ledger schema). The earlier separate
> "Artifact 2 machine-checkable cite-join ledger" + its decision-follows-from-study join key are
> **dropped** (process-theater for a 5-row, ~80%-pre-answered decision); the decision section's
> prose citations to the study rows satisfy AC4b directly. A research decision does not warrant a
> new parsed format; `emission-manifest.jsonl` is a generator output, which this is not.

---

### Feature Flow — Study → Decide → Document → Verify

This replaces the request→service→repo flow with the FR4a-gates-FR4 workflow. It is a
**linear, human-gated** process (no auto-advance), consistent with AID's state-machine
discipline.

```
[INPUTS]  Early FR4a inputs (SPEC "Early inputs" + REQUIREMENTS FR4a bullets)
          + live vendor docs (5 tools)  + the AID codebase dispatch facts (below)
                    │
                    ▼
[S1 STUDY]  For each tool × each axis, fill the Capability Matrix:
            • read live vendor docs → record native mechanism + format + always-on verdict
            • where feasible, run an EMPIRICAL probe (see Telemetry) → record test-id
            • set Preserve / Translate / Gap + Verification + Confidence
            • the prior 5-tool "Early inputs" are entered as DRAFT rows, each
              re-verified against live docs; a verified row supersedes the draft,
              a contradicted row is corrected with a changelog note
                    │  (gate: every (tool,axis) row has a Verification + Confidence;
                    │   no row left as unverified draft)
                    ▼
[S2 DECIDE]  For each (tool, asset-kind): apply the decision procedure →
             uniform-markdown OR native-exception. Write the decision section
             (per-(tool,asset-kind) verdict table) inside capability-study.md.
                    │  (gate: every verdict cites a study row — AC4b)
                    ▼
[S3 DOCUMENT]  The decision section (in capability-study.md) cites the per-tool
               table per verdict, plus D1 + the E-CODEX-1 result.
               (FR4 decision is now "documented + cites the study")
                    │
                    ▼
[S4 VERIFY]   Behavioral-consistency check (AC4a): exercise 1 representative skill
              + 1 representative agent across the work's 3-tool scenario
              {Cursor, Claude Code, Codex} against the study's parity criteria.
              Record pass/gap. Copilot CLI + Antigravity parity is asserted by the
              Finding-D1 content-identity argument, NOT exercised (CI can't run 5
              live runtimes) — named as a residual, not buried in a confidence column.
                    │  (gate: consistent against criteria, OR any divergence is an
                    │   explicitly-documented gap, never hidden — NFR3)
                    ▼
[DONE]   Study + decision + verification recorded. Feature-002 may now act on FR4
         (delete branches / collapse generator). NOT before (AC4b ordering gate).
```

#### The FR4 decision procedure — "provably required" (S2)

A native format is **kept as a documented exception only when ALL of:**

1. **A behavioral axis is `gap` or un-`translate`-able under uniform markdown** for that
   tool — i.e. uniform markdown cannot carry the activation / execution / capability /
   dispatchability behavior, *and* the generator cannot translate it into the tool's idiom
   at render time; **and**
2. **AID actually relies on that behavior** — the gap touches a capability AID exercises
   (e.g. AID dispatches a named sub-agent through this tool), not a theoretical tool
   feature AID never uses; **and**
3. The finding is **`high` confidence**, established by `docs` *and* (where feasible)
   `empirical`.

If any of the three fails → **commit uniform markdown** (the FR4 default, verify-first).
"Provably required" = (1) ∧ (2) ∧ (3), each citing a study row. The decision record states
which of the three each retained exception satisfies, or — for every uniform-markdown
verdict — that condition (1) or (2) failed (the behavior is preserved/translatable, or AID
does not rely on it).

---

### Layers & Components — Files This Feature Produces / Touches

> **Boundary (load-bearing):** this feature **does NOT** touch
> `.claude/skills/generate-profile/scripts/*` (`render_agents.py`, `render_skills.py`,
> `render_lib.py`, the profile `*.toml` files) or any `profiles/*` tree. Collapsing the
> generator, deleting `render_agents.py`'s 4 format branches, and re-rendering are
> **feature-002**. This feature only **reads** those files as study evidence.

**Produces (new `.aid/` artifact — not shipped, not rendered):**

| Artifact | Proposed path | Rationale |
|----------|---------------|-----------|
| Capability study + decision section (the single doc) | `.aid/work-005-profile-generator-simplify/research/capability-study.md` | Lives with the work that gates on it; survives as the reusable per-tool reference; its decision section carries the FR4 verdict (citing D1 + E-CODEX-1) — consumed by feature-002 before any branch deletion. (The separate `format-decision.md` was folded in per the intent-review correction.) |

> **Confirmed (2026-06-20):** the study is authored **work-local** in
> `.aid/work-005-.../research/` for this feature. The verified study is **promoted to a
> durable KB doc at ship-time via feature-004's KB lockstep** — consistent with the work's
> "defer KB updates to ship" rule, avoiding premature INDEX/README/CI churn now. The KB
> target (a new `host-tool-capabilities.md` vs an addendum to `pipeline-contracts.md`'s
> Renderer Contract) is chosen by feature-004; **this feature makes no `.aid/knowledge/` edits**.
> (Precedent for a durable work-adjacent note: `.aid/design/cli-install-scope-and-migration.md`.)

**Reads (read-only study inputs — the codebase ground-truth):**

- `canonical/skills/aid-execute/references/state-execute.md` — the **dispatch mechanism**
  (PD-0 probe, PD-2 `Agent(subagent_type: aid-<name>, …)`); the load-bearing Codex evidence.
- `canonical/skills/*/references/*.md` + `SKILL.md` — every `subagent_type: aid-<name>`
  dispatch site (all in **byte-identical skill bodies**).
- `profiles/codex.toml` `[agent] format = "toml"` + `profiles/codex/.codex/agents/*.toml`
  — the Codex agent native format (the TOML `name = "aid-<name>"` field).
- `profiles/{claude-code,cursor,copilot-cli,antigravity}.toml` + their rendered agent
  files — the other 4 native formats + their behavioral-metadata frontmatter keys.
- `.claude/skills/generate-profile/scripts/render_agents.py` — the 4 format branches
  (`markdown | toml | copilot-agent | antigravity-rule`) and `_remap_tools_list` (how
  `allowed-tools` capability metadata is already translated per tool).
- `.aid/knowledge/{architecture,pipeline-contracts,content-isolation,domain-glossary}.md`
  — the KB grounding (dispatch model, renderer contract, `Format ⊥ behavior` term).

**Touches `.aid/knowledge/`:** none — KB promotion is deferred to feature-004 (confirmed above), so this feature makes no KB edits and triggers no INDEX/README regen.

---

### AI Enhancements — Subagent Dispatch & the Behavioral-Metadata Axes

This is the substantive section. The study's subject is how AID's **agents and skills**
behave per host tool. Two findings are pre-established from the codebase and seed the study
as **`high`-confidence, `empirical:codebase` rows** (the study still re-verifies the
*vendor-side* half against live docs):

#### Finding D1 — AID dispatches agents by **name through the host's generic Agent tool**, NOT via any tool's native named-dispatch primitive.

Every dispatch site in AID is a prose instruction inside a **byte-identical skill body**:

```
Agent(subagent_type: aid-<name>, prompt: <…>, run_in_background: true)
```

(`canonical/skills/aid-execute/references/state-execute.md` PD-2; mirrored at every
`subagent_type: aid-reviewer` / `aid-architect` site across `aid-specify`, `aid-detail`,
`aid-plan`, `aid-interview`, `aid-execute`). The dispatch key is the
**agent name string**; the host tool resolves that name to whatever agent definition it
discovered. AID never calls a Codex-specific `spawn_agent`, never relies on TOML
auto-discovery semantics, and contains **zero** native-named-dispatch keywords
(grep across `canonical/`, `profiles/*.toml`, `docs/`, `lib/`, `bin/` returns nothing).
The host capability AID *does* probe for is generic `run_in_background` (PD-0), with an
explicit **graceful-degradation to sequential** path when absent — i.e. AID already treats
even background dispatch as optional, never load-bearing.

#### Finding D2 — The `dispatchability` axis therefore reduces to: "can the tool resolve `aid-<name>` to the agent definition?" — which only requires the name to be **present and discoverable**, not in any particular format.

Codex's TOML agents carry `name = "aid-<name>"` (`profiles/codex/.codex/agents/aid-architect.toml`).
Whether that name is declared in TOML or in markdown frontmatter, the dispatch contract is
the same string-name resolution. The behavioral question is **"is the agent discoverable
under its name?"**, not **"is it TOML?"**.

#### The four behavioral-metadata axes, mapped to today's translation reality

The generator **already translates** capability metadata per tool (`render_agents.py`
`_remap_tools_list` rewrites `allowed-tools` — `Bash`→`Terminal` for Cursor, `Bash`→`shell`
for Copilot). This proves the **`translate`** verdict is mechanically achievable, not
hypothetical. The study records, per tool, for each of:

- **activation** — `alwaysApply` (Cursor) / glob / `trigger` (Antigravity) / a skill's
  `description` — how uniform markdown frontmatter carries it.
- **execution** — `model` + `reasoning_effort` (Codex `model_reasoning_effort`; Antigravity
  effort) — preserved as frontmatter, translated to the tool's tier idiom by the generator.
- **capability** — `allowed-tools` / permissions — already `translate` via `_remap_tools_list`.
- **dispatchability** — per D1/D2: `preserve` (the name) for every tool.

---

### The Codex Resolution (FR4 exception candidate — RESOLVED by the codebase)

> **Verdict: Codex does NOT need a TOML FR4 exception on dispatchability grounds.** AID does
> not rely on Codex-native named dispatch (Finding D1). Uniform markdown agents are
> sufficient for AID's dispatch model, because AID dispatches by **name string through the
> generic Agent tool**, and the host resolves that name regardless of the source format.
> codex issue #15250 ("markdown agents are not discovered as *native* Codex subagents") is
> **not load-bearing for AID**: AID never uses Codex's native subagent discovery — it injects
> the dispatch instruction in the (byte-identical) skill body the orchestrator reads, and the
> agent's behavioral metadata (model, reasoning effort, instructions) travels in the agent
> file's frontmatter/body either way.

**Therefore the format decision for Codex agents may commit to uniform markdown**, *provided*
the study confirms the two remaining sub-questions against live docs:

1. **Discovery (not dispatch):** does Codex *load/read* a markdown agent file at all (as
   context the orchestrator can act on), even if it does not register it as a native
   subagent? Finding D1 makes *dispatch* format-agnostic, but the agent's instructions must
   still reach the model. → **Empirical test E-CODEX-1** (below).
2. **Execution metadata:** Codex's `model_reasoning_effort` (execution axis) must survive
   re-encoding to markdown frontmatter — verify Codex reads effort from a markdown agent's
   frontmatter, or that the generator can place it where Codex reads it.

> **Confirmed (2026-06-20):** the spec treats **uniform-markdown-for-Codex as the expected
> outcome**; the TOML exception is the **fallback gated by E-CODEX-1** (the discovery
> sub-question, distinct from the dispatch gap D1 already closes) — and TOML is the *only*
> candidate exception across all 5 tools. If E-CODEX-1 cannot be run locally, the Codex
> discovery row stays `docs`-only at `medium` confidence and the TOML branch is **not deleted**
> until later — **this is acceptable for feature-001 DONE** (verify-first; feature-002 inherits
> the open row). The decision record must state which branch the study landed on.

**Empirical test E-CODEX-1 (definition, if the codebase doesn't fully settle discovery):**
In a throwaway Codex project, install one AID agent as a **markdown** file under the agent
path and one skill that dispatches it by name; confirm (a) the agent's instructions reach
the model and (b) a `subagent_type: aid-<name>`-style instruction in the skill body causes
the named behavior. Record as `empirical:E-CODEX-1` with pass/gap + confidence. If Codex
cannot be exercised locally, the row stays `docs`-only at `medium` confidence and the
decision notes the residual risk (verify-first means we do not delete the TOML branch until
this row is `high`).

---

### Migration Plan (study-only — behavioral implications, not the mechanism)

No data migration. The **mechanism** (`.agents/`→`.codex/` move, `.cursor/rules/` drop,
auto-prune) is feature-003 (FR7/FR7a). This feature's job is to surface, in the study, the
**behavioral** implications so the migration is provably safe:

- **Retiring the Codex split (`.agents/` + `.codex/` → `.codex/{agents,skills,aid}`,
  FR2):** the study confirms it does **not** change dispatch behavior — D1 shows dispatch is
  name-based and format/path-agnostic; the agent's *discoverability under its name* is the
  only requirement. Record the post-unify discovery path Codex actually reads.
- **Dropping all rules folders (FR3):** the study **verifies whether** the **always-on guarantee** holds
  via the root context file for each tool (the FR3/A1 verify-item, incl. the **Cursor
  background-agent caveat** and **Antigravity v1.20.3+** check), so removing
  `.cursor/rules/` + `.agent/rules/` does not silently lose always-on behavior.

These are **findings the study must contain**, gating feature-002/003 — not steps this
feature executes.

---

### Telemetry & Tracking (light — the study's verification discipline)

The only "telemetry" is the study's **Verification + Confidence** columns (Data Model).
Discipline:

- Every `(tool, axis)` row records **how** it was established: `docs:<citation>` (live
  vendor doc URL + access date), `empirical:<test-id>` (a reproducible probe like
  E-CODEX-1), or `both`.
- **Confidence** ∈ `high | medium | low`; a `low` row carries a follow-up note and may not
  back a "provably required" exception (decision procedure condition 3).
- The **prior 5-tool Early inputs** enter as **draft rows** and are individually re-verified
  against live docs; the change log notes any draft the live docs contradicted (the
  SPEC's "verify against live docs" instruction made executable).
- Verification status is tracked in the work `STATE.md` per the AID tracking discipline
  (the orchestrator owns the STATE writes).

---

### Acceptance-Criteria Coverage

| AC | Where satisfied in this spec |
|----|------------------------------|
| **AC4b** — study produced + documented before any branch deleted; FR4 decision cites it | Data Model (the single `capability-study.md` schema + its decision section) + Feature Flow S1→S3 gates + the AC4b "every verdict cites a study row" requirement + the DONE ordering gate (feature-002 may act only after) |
| **AC4a** — representative skill + agent verified consistent across the work's 3-tool scenario {Cursor, Claude Code, Codex}; Copilot CLI + Antigravity parity asserted via Finding-D1 content-identity, not exercised | Feature Flow S4 + its gate (consistent, or documented gap per NFR3) |
| **FR4 / FR4-distinction** | The decision procedure (S2) + the four-axis behavioral-metadata mapping (AI Enhancements) |
| **FR4a reusability (NFR5, 6th tool)** | Fixed per-tool Capability-Matrix column schema (Data Model); durable KB home resolved — work-local now, promoted at ship-time via feature-004 |
| **Codex resolution (the named FR4 exception candidate)** | The Codex Resolution section: resolved by Finding D1 (no native-dispatch reliance), with E-CODEX-1 gating the residual discovery sub-question |

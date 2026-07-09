---
kb-category: extension
source: hand-authored
objective: The load-bearing design, process, and tooling decisions that shaped AID — what was decided, why, what was rejected, and the evidence — so a newcomer can reconstruct the rationale the artifacts alone cannot show.
summary: Read this to understand WHY AID is shaped the way it is — the deliberate trade-offs behind Discovery-first, deterministic grading, RAG-by-convention, the single-canonical-source render, the install-scope model, and more.
sources:
  - docs/aid-methodology.md
  - canonical/EMISSION-MANIFEST.md
  - .aid/design/cli-install-scope-and-migration.md
  - .claude/aid/templates/grading-rubric.md
  - README.md
tags: [D, decisions, rationale, trade-offs, adr]
see_also: [architecture.md, technology-stack.md, infrastructure.md]
owner: architect
audience: [architect, developer]
intent: |
  The significant decisions that shaped AID and why they were made — the rationale a
  newcomer cannot reconstruct from the artifacts alone. Records decisions and reasoning
  (what / why / rejected alternatives / status / evidence), not a restatement of state.
contracts: []
changelog:
  - 2026-07-09: Housekeep KB-DELTA refresh — connectors subsystem + release-drift refresh (added D19: connectors registry is a catalog, not a connection manager)
  - 2026-06-25: Initial discovery (aid-discover — architect deep-dive)
---

# Decisions

> **Source:** aid-discover (Phase 1)
> **Status:** Complete
> **Last Updated:** 2026-07-09
>
> Each entry records: **what** was decided, **why**, the **rejected** alternatives (with
> the reason), **status**, and **evidence**. Decisions grounded in design notes / the
> methodology / commit history are CONFIRMED; inferred rationale is tagged.

## Contents

- [Summary Table](#summary-table)
- [D1 — Waterfall sequence with AI execution](#d1--waterfall-sequence-with-ai-execution)
- [D2 — Knowledge before specification (Discovery-first)](#d2--knowledge-before-specification-discovery-first)
- [D3 — Spec as hypothesis + eleven formal feedback loops](#d3--spec-as-hypothesis--eleven-formal-feedback-loops)
- [D4 — RAG by convention (no vector database)](#d4--rag-by-convention-no-vector-database)
- [D5 — Deterministic computed grade (not LLM-judged)](#d5--deterministic-computed-grade-not-llm-judged)
- [D6 — Adversarial review separation (reviewer tier >= executor)](#d6--adversarial-review-separation-reviewer-tier--executor)
- [D7 — Single canonical source rendered to five profiles + VERIFY gate](#d7--single-canonical-source-rendered-to-five-profiles--verify-gate)
- [D8 — Emission-manifest format = JSON Lines](#d8--emission-manifest-format--json-lines)
- [D9 — Pure-mirror deletion bounded by the manifest](#d9--pure-mirror-deletion-bounded-by-the-manifest)
- [D10 — Polyglot, dual-channel, zero-dependency distribution](#d10--polyglot-dual-channel-zero-dependency-distribution)
- [D11 — Content isolation + in-place root-file markers](#d11--content-isolation--in-place-root-file-markers)
- [D12 — CLI install scope: cwd-driven, no scan, CODE/STATE split](#d12--cli-install-scope-cwd-driven-no-scan-codestate-split)
- [D13 — Per-repo format_version stamp (git model)](#d13--per-repo-format_version-stamp-git-model)
- [D14 — Lite path + description-first TRIAGE](#d14--lite-path--description-first-triage)
- [D15 — Nine agents in three tiers (role consolidation)](#d15--nine-agents-in-three-tiers-role-consolidation)
- [D16 — PowerShell 5.1 compatibility floor](#d16--powershell-51-compatibility-floor)
- [D17 — Prose over scripts in skill definitions](#d17--prose-over-scripts-in-skill-definitions)
- [D18 — KB forbids diagrams; the HTML summary embraces them](#d18--kb-forbids-diagrams-the-html-summary-embraces-them)
- [D19 — Connectors registry: catalog, not connection manager (Q10)](#d19--connectors-registry-catalog-not-connection-manager-q10)
- [Still Load-Bearing](#still-load-bearing)
- [Change Log](#change-log)

---

## Summary Table

| # | Decision | Status | Primary evidence |
|---|----------|--------|------------------|
| D1 | Waterfall sequence + AI execution | Accepted | `docs/aid-methodology.md` §2 |
| D2 | Discovery-first (knowledge before spec) | Accepted | `docs/aid-methodology.md` §2/§3 |
| D3 | Spec-as-hypothesis + 11 feedback loops | Accepted | `docs/aid-methodology.md` §6 |
| D4 | RAG by convention, no vector DB | Accepted | `docs/aid-methodology.md` §3 |
| D5 | Deterministic computed grade | Accepted | `.claude/aid/templates/grading-rubric.md` |
| D6 | Reviewer tier >= executor, clean context | Accepted | `docs/aid-methodology.md` §5 |
| D7 | One canonical source -> 5 profiles + VERIFY | Accepted | `canonical/EMISSION-MANIFEST.md` |
| D8 | Emission manifest = JSONL | Accepted | `canonical/EMISSION-MANIFEST.md` |
| D9 | Pure-mirror manifest-bounded deletion | Accepted | `canonical/EMISSION-MANIFEST.md` |
| D10 | Polyglot, dual-channel, zero-dep distribution | Accepted | `packages/*` manifests |
| D11 | Content isolation + AID:BEGIN/END markers | Accepted (supersedes .aid-new) | `README.md` |
| D12 | cwd-driven CLI, no scan, CODE/STATE split | Settled, partial impl | `.aid/design/cli-install-scope-and-migration.md` |
| D13 | Per-repo `format_version` stamp | Settled | same design note §3.4 |
| D14 | Lite path + description-first TRIAGE | Accepted | `docs/aid-methodology.md` §4 |
| D15 | 9 agents / 3 tiers (consolidation) | Accepted (supersedes prior roster) | `docs/aid-methodology.md` §5 |
| D16 | PowerShell 5.1 floor | Accepted | `README.md`; project memory |
| D17 | Prose over scripts in skills | Accepted | project practice; `tests/run-all.sh` header |
| D18 | KB no-diagrams; HTML summary yes-diagrams | Accepted | authoring standard; `.aid/design/aid-summarize-redesign.md` |
| D19 | Connectors registry is a catalog, not a connection manager | Accepted (delivery-002 withdrawn) | `canonical/aid/templates/connectors/preset-catalog.md`; `canonical/skills/aid-discover/references/state-elicit.md` |

---

## D1 — Waterfall sequence with AI execution

- **What:** Adopt the Waterfall sequence (Understand -> Specify -> Plan -> Build -> Verify
  -> Ship) deliberately, executed by AI at AI speed.
- **Why:** Waterfall failed because humans could not execute it fast enough to afford
  iteration; AI changes the economics (discovery in hours, specs in minutes, iteration costs
  tokens not sprints).
- **Rejected:** Pure Agile / skip-to-implementation — rejected because it omits the
  structure (discovery, specification) that Agile iterations skip "because it felt too slow".
- **Status:** Accepted. CONFIRMED `docs/aid-methodology.md` (search: "Waterfall + AI — and
  That Is the Point").

## D2 — Knowledge before specification (Discovery-first)

- **What:** A dedicated Discovery phase produces a Knowledge Base before any spec is written;
  brownfield projects must run it.
- **Why:** Dropping an agent into a brownfield codebase without a KB produces hallucination —
  "technically plausible but architecturally wrong code".
- **Rejected:** Spec-first (SDD) — rejected as "incomplete": it assumes you already understand
  the system. CONFIRMED `docs/aid-methodology.md` (search: "SDD is not wrong. It is
  incomplete").
- **Status:** Accepted. CONFIRMED §2 "Knowledge Before Specification".

## D3 — Spec as hypothesis + eleven formal feedback loops

- **What:** Treat specs as living, revisable artifacts; define 11 named feedback loops so any
  phase can revise an upstream artifact with a traceable revision history.
- **Why:** Any spec written before implementation is partially wrong; the choice is whether to
  revise formally (audit trail) or informally (silent workarounds / hidden debt).
- **Rejected:** Re-spec-from-scratch on change (SDD's model) — rejected as lossy and
  untraceable. CONFIRMED `docs/aid-methodology.md` §9 comparison table (search: "Rebuild spec
  from scratch").
- **Status:** Accepted. CONFIRMED §6 "The Eleven Loops".

## D4 — RAG by convention (no vector database)

- **What:** Retrieve context via a 3-tier convention (always-loaded INDEX.md -> one KB doc on
  demand -> exact `path:line` citation) instead of embeddings.
- **Why:** The KB is small (14 short markdown docs); the bottleneck is *knowing what exists*,
  not retrieval speed. Convention beats infrastructure.
- **Rejected:** Vector DB / embeddings / chunking — rejected explicitly: "Because the KB is
  small enough that convention beats infrastructure ... at a fraction of the operational
  complexity." CONFIRMED `docs/aid-methodology.md` (search: "Why not a vector database?").
- **Status:** Accepted.

## D5 — Deterministic computed grade (not LLM-judged)

- **What:** The reviewer only classifies issues by bracketed severity (`[CRITICAL]`..`[MINOR]`);
  the letter grade is computed by `grade.sh` (worst severity dominates; count sets the
  modifier). The reviewer never hand-picks a grade.
- **Why:** Determinism makes progress visible (D->C means all highs fixed), enables loop
  detection (same grade 3 cycles = systemic), and applies one rubric everywhere.
- **Rejected:** Reviewer-assigned letter grade — rejected because it is non-reproducible and
  gameable; sentence-case (un-bracketed) tags are explicitly counted as zero to force the
  machine-readable form. CONFIRMED `.claude/aid/templates/grading-rubric.md` (search: "Why
  This Scale" and "producing a silent A+").
- **Status:** Accepted.

## D6 — Adversarial review separation (reviewer tier >= executor)

- **What:** The agent that writes never grades its own work; the reviewer's model tier is
  always >= the executor's and runs in a clean context after the executor finishes.
- **Why:** Prevents the reviewer anchoring on the executor's framing; catches spec,
  architecture, and convention issues tests cannot detect.
- **Rejected:** Single-agent self-review and "tests pass = done" — rejected as an
  anti-pattern. CONFIRMED `docs/aid-methodology.md` §5 + §10 Anti-Patterns (search:
  "Bypassing Execute's review loop").
- **Status:** Accepted.

## D7 — Single canonical source rendered to five profiles + VERIFY gate

- **What:** Author once in `canonical/`, render to five tool-specific `profiles/` trees with
  byte-identical bodies (only model names + agent format differ), guarded by a deterministic
  byte-compare VERIFY gate and a CI render-drift check.
- **Why:** Five host tools must stay in lockstep; one source eliminates five-way divergence.
- **Rejected:** Hand-maintaining per-tool copies — rejected implicitly by the "never edit
  profiles/ directly" rule. CONFIRMED `docs/aid-methodology.md` (search: "single source of
  truth — never edit profiles/ directly") + `run_generator.py`.
- **Status:** Accepted.

## D8 — Emission-manifest format = JSON Lines

- **What:** Record every emitted file (profile/src/dst/sha256) one-per-line in a `.jsonl`
  manifest, sorted by `dst`, LF-only, with a `{"_manifest_version": 1}` sentinel.
- **Why:** Streamable, greppable, diff-friendly, deterministic, and zero runtime dependency
  (Python stdlib `json`).
- **Rejected — with reasons stated in the doc:** **TOML** (verbose, no streaming, hard to
  diff multi-line records); **YAML** (ordering/quoting ambiguity hurts determinism, anchors
  add complexity); **SQLite** (binary, not diff-friendly, adds a runtime dependency, overkill).
  CONFIRMED `canonical/EMISSION-MANIFEST.md` (search: "Rejected alternatives").
- **Status:** Accepted.

## D9 — Pure-mirror deletion bounded by the manifest

- **What:** On re-render, the generator deletes only paths in the previous manifest but absent
  from the current (`removed_dst`); files outside any manifest are never touched.
- **Why:** Self-cleaning installs/updates must prune renamed/dropped AID files without ever
  risking user-authored files — the manifest is the authoritative safety boundary.
- **Rejected:** Unbounded directory prune / "delete whatever isn't re-emitted" — rejected
  because it could delete user content. CONFIRMED `canonical/EMISSION-MANIFEST.md` (search:
  "Files outside any manifest").
- **Status:** Accepted.

## D10 — Polyglot, dual-channel, zero-dependency distribution

- **What:** Implement install logic in both Bash and PowerShell; publish through both npm and
  PyPI (plus curl/irm bootstrap and offline tarballs); declare zero runtime dependencies.
- **Why:** AID must bootstrap on bare Bash and bare PowerShell hosts and reach both Node and
  Python users; zero deps keeps install fast and supply-chain-light.
- **Rejected:** Single-language / single-channel install — rejected because it would exclude
  whole host populations. CONFIRMED `packages/npm/package.json` (`"dependencies": {}`),
  `packages/pypi/pyproject.toml` (`dependencies = []`), `README.md` "Install".
- **Status:** Accepted. Parity enforced by `tests/canonical/test-aid-cli-parity.sh`.

## D11 — Content isolation + in-place root-file markers

- **What:** Namespace all AID content (skills/agents carry `aid-` prefix; scripts/templates/
  recipes live under an `aid/` subtree); update root context files (`CLAUDE.md`/`AGENTS.md`)
  in place only between `<!-- AID:BEGIN -->` / `<!-- AID:END -->` markers.
- **Why:** AID content and user content must never collide, and `aid update` must be able to
  prune AID's own stale files in place with no risk to user files.
- **Rejected:** The old `.aid-new` sidecar file for root-file conflicts — **superseded** and
  removed in v1.1.0 in favor of in-place marker rewriting. CONFIRMED `README.md` (search:
  "The old .aid-new sidecar file is gone").
- **Status:** Accepted (supersedes the `.aid-new` approach).

## D12 — CLI install scope: cwd-driven, no scan, CODE/STATE split

- **What:** `aid <cmd>` acts on the current directory's repo (like git); there is no
  machine-wide filesystem scan. Install scope (global vs per-user) is *derived at runtime*
  from payload-root writability, not recorded. Internal homes split into read-only
  `AID_CODE_HOME` (self-located payload) and mutable `AID_STATE_HOME`
  (`${AID_HOME:-<scope default>}`; global -> `/var/lib/aid`, non-global -> `~/.aid`).
- **Why:** A real-machine dogfood (v1.0.0 -> v1.1.0) exposed that writing machine state into
  a root-owned `$AID_HOME` failed for unprivileged `aid`, and a `$HOME`-only scan missed
  repos under `/srv/projects`. Prior art (git cwd-model, rustup channel-aware self-update,
  mlocate privileged-writer/all-readers) validated the redesign.
- **Rejected:** An install-time scope marker (rejected — self-correcting runtime probe is
  better); a `$HOME`-walking scan (rejected — misses out-of-home repos, scans wrong `$HOME`
  under sudo); a single combined `AID_HOME` for both code and state (rejected — caused the
  root-owned-state write bug).
- **Status:** Settled pre-implementation (2026-06-15); partially implemented (self-commands
  slice in PR #78). CONFIRMED `.aid/design/cli-install-scope-and-migration.md` (search:
  "Settled decisions" and "Core model").

## D13 — Per-repo `format_version` stamp (git model)

- **What:** Each repo records `format_version: <int>` in its `.aid/settings.yml`, decoupled
  from CLI semver, compared against `AID_SUPPORTED_FORMAT`; a newer stamp = refuse to operate
  (fail-safe), older/absent = offer migration.
- **Why:** A repo's migration state is a property of the repo, so it must live with the repo
  (git's `core.repositoryformatversion` model) — making the root-owned-marker re-prompt bug
  structurally impossible.
- **Rejected:** A machine-level `$AID_HOME/.migrated` marker + era-by-file-presence detection
  — **removed entirely**; rejected because machine markers can't be written by unprivileged
  `aid` and don't travel with the repo. CONFIRMED `.aid/design/cli-install-scope-and-migration.md`
  §3.4 (search: "per-repo stamp (git model)") + Decision F.
- **Status:** Settled. (Stop-gap `.migrated-marker` noted in project memory pending full impl.)

## D14 — Lite path + description-first TRIAGE

- **What:** Every interview opens with TRIAGE: the user describes the work in plain language,
  the agent infers the work-type (`bug-fix`/`new-feature`/`refactor`) and best-matching
  recipe, and a confident single-target match routes to a condensed lite path that skips
  Specify/Plan/Detail.
- **Why:** Proportionality should be automated, not weighed per change; most individual tasks
  are small and should not pay full-pipeline overhead.
- **Rejected:** One-size-fits-all full pipeline (rejected — over-heavy for small work, an
  explicit anti-pattern); a user-picked work-type menu (rejected in favor of inference — "You
  never pick this from a menu"). The old `single-doc` work-type was also removed (folded into
  new-feature/refactor). CONFIRMED `docs/aid-methodology.md` §4 (search: "description-first")
  and §10 (search: "Using the full path for every change").
- **Status:** Accepted.

## D15 — Nine agents in three tiers (role consolidation)

- **What:** 9 specialist agents across Large/Medium/Small tiers, mapped per profile to
  concrete models.
- **Why:** Match model cost to task stakes; one mechanical Small-tier `aid-clerk` avoids
  Large-tier overhead for glob/extract work.
- **Rejected / superseded:** The former larger roster — the five discovery-* agents
  (scout/architect/analyst/integrator/quality) were collapsed into a pool of `aid-researcher`
  instances; `aid-developer` absorbed the former data-engineer and devops roles;
  `aid-architect` absorbed the former ux-designer advisory work. CONFIRMED
  `docs/aid-methodology.md` §5 (search: "replaces the former five separate discovery-* agents"
  and "absorbs former data-engineer and devops roles").
- **Status:** Accepted (supersedes the prior agent roster).

## D16 — PowerShell 5.1 compatibility floor

- **What:** All shipped PowerShell must run on Windows PowerShell 5.1 (a fresh Windows box has
  5.1, not pwsh 7), enforced by an AST lint and a real 5.1 CI lane.
- **Why:** The bare-box bootstrap promise ("5.1+") — like the no-python3 assumption — means
  the installer must work before the user installs anything newer.
- **Rejected:** Requiring pwsh 7 / using 7-only constructs (TLS1.2 defaults, 3-arg Join-Path,
  `utf8NoBOM`, `$IsWindows`, non-ASCII in no-BOM `.ps1`) — rejected as 5.1-incompatible.
  CONFIRMED `README.md` (search: "PowerShell 5.1+") and project memory (winps-51-compat-lane).
- **Status:** Accepted. (Related: shipped `.ps1`/`.sh` must be ASCII-only / LF-only — see
  `architecture.md` Invariants.)

## D17 — Prose over scripts in skill definitions

- **What:** Trivial state/argument handling is done in `SKILL.md` prose, not bash; only
  non-trivial, reused, deterministic operations are extracted to `canonical/aid/scripts/`.
- **Why:** Skills are executed by an AI host that reads prose; inventing script infrastructure
  for trivial work adds maintenance cost without value. Mis-specified test ACs are relaxed
  rather than back-filled with infrastructure.
- **Rejected:** Scripting every step — rejected as over-engineering. CONFIRMED project memory
  (prose-over-scripts) and the script-extraction pattern visible under `canonical/aid/scripts/`.
- **Status:** Accepted. LIKELY (rationale grounded in practice + memory, not a single ADR).

## D18 — KB forbids diagrams; the HTML summary embraces them

- **What:** KB documents use `A -> B` arrows, relationship tables, and numbered flow lists —
  no diagrams. The `aid-summarize` HTML viewer (`kb.html`) is the opposite: a visually rich,
  newcomer-facing product where more concept infographics are better.
- **Why:** KB docs are dual-audience (human + machine) and must stay grep-able and
  diff-stable; the summary is a non-technical-newcomer presentation artifact with a different
  goal.
- **Rejected:** Diagrams in KB docs (rejected — hurt machine-readability/diffability); also
  the prior Mermaid-engine approach in the summary was **superseded** by pre-rendered inline
  SVG (dropping a ~3MB engine) plus a Playwright visual-fidelity gate. CONFIRMED authoring
  standard (this discovery's brief) and `.aid/design/aid-summarize-redesign.md`.
- **Status:** Accepted (summary redesign superseded the Mermaid approach).

## D19 — Connectors registry: catalog, not connection manager (Q10)

- **What:** The `.aid/connectors/` registry is a **CATALOG** — it lists the connections
  available to a repo's agents and how to use them. It is not a connection manager and does not
  wire any host tool's configuration. Two modes are derived from each descriptor's
  `connection_type`: **tool-managed** (`mcp`) — the host tool (Claude Code, Codex, Cursor, …)
  already provides its own MCP/plugin for the target, so AID forces `auth_method: none`, writes
  no `secret_reference`, and instructs the agent to request the connection from the host tool
  itself; **aid-managed** (`api | ssh | url | cli`) — a direct connection the host tool does not
  provide, where AID records a connect-sufficient descriptor plus a local, git-ignored credential
  the agent resolves at use-time via `secret_reference` (`env:` / `file:` / `keychain:`).
- **Why:** Host tools already own their own MCP servers and auth for what they provide; AID
  recording and wiring a second, competing credential/config for the same target would duplicate
  and conflict with the host's own connection. AID should record only what it itself manages and
  instruct the agent to request the rest from the host.
- **Rejected:** The original design where AID actively manages and wires *all* connections,
  including writing host MCP configs into each host tool — rejected because it duplicates
  host-tool-owned auth/config and requires AID to track host-specific MCP wiring formats it does
  not control. As a direct consequence, delivery-002 (MCP host wiring) was **withdrawn**.
- **Status:** Accepted (delivery-002 withdrawn as a consequence). CONFIRMED
  `canonical/aid/templates/connectors/preset-catalog.md` (search: "Management mode (STATE.md
  Q10"), `canonical/skills/aid-discover/references/state-elicit.md` (search: "Q10: AID writes,
  wires, and manages no host tool's MCP configuration"), and the connector scripts under
  `canonical/aid/scripts/connectors/` (`connector-registry.sh`, `connector-secret.sh`,
  `build-connectors-index.sh`).

---

## Still Load-Bearing

Decisions that are expensive to reverse and currently constrain most changes:

- **D7 (single canonical source) + D9 (manifest-bounded deletion)** — the entire build,
  distribution, and self-cleaning-update story depends on these; reversing either breaks the
  five-profile lockstep and the safe-prune guarantee.
- **D5 (deterministic grade)** — every phase's quality gate and loop-detection logic is built
  on it.
- **D6 (adversarial separation)** — the core quality mechanism; lowering the grade threshold
  to dodge it is an explicit anti-pattern.
- **D11 (content isolation) + D13 (per-repo stamp)** — the safe-update and migration model
  rests on these; they were adopted specifically to make prior bug classes impossible.
- **D10 (polyglot/dual-channel)** — reversing would orphan whole host populations.

**Superseded (not load-bearing):** the `.aid-new` sidecar (by D11), the machine `.migrated`
marker + `$HOME`-scan (by D12/D13), the five discovery-* agents (by D15), the Mermaid engine
in the summary (by D18).

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial decision record — 18 load-bearing decisions with rationale, rejected alternatives, status, and evidence. |
| 1.1 | 2026-07-09 | tech-writer | Housekeep KB-DELTA refresh: connectors subsystem + release-drift refresh — added D19 (connectors registry is a catalog, not a connection manager; delivery-002 MCP host wiring withdrawn as a consequence). |

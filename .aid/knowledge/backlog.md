---
kb-category: primary
source: hand-authored
objective: Defined and prioritized work items for AID that have not shipped — the slice committed to the next release and the prioritized remainder.
summary: Read this to see what is accepted into the plan but not yet shipped; raw unscheduled observations live in tech-debt.md and shipped work in release-tracking.md.
sources: []
tags: [C7, backlog, prioritization, items, planning]
see_also: [tech-debt.md, release-tracking.md, roadmap.md]
owner: architect
audience: [developer, architect, pm]
---

# Backlog

This document holds the work items that have been explicitly accepted into the plan but not
yet shipped. An item moves here when a human makes a deliberate planning decision to commit
to it — the per-item confirm gate at `/aid-create-backlog` or `/aid-update-backlog`. Raw,
unscheduled debt observations stay in `tech-debt.md` until that decision is made; shipped
items move to `release-tracking.md`.

## Contents

- [Next Release](#next-release)
- [Prioritized](#prioritized)
- [Gotchas](#gotchas)

## Next Release

The committed slice for the current tag. Every item here is drained by `release-aid` at tag
time — it becomes a tagged release-note bullet in `release-tracking.md` and is deleted from
this document in the same run.

| ID | Tag | Title | Definition & done-condition | Location | Risk if not done | Priority |
|----|-----|-------|-----------------------------|----------|-----------------|----------|
| **W7-4** | `[CHANGE]` | Breaking major release: v4 requires CLI v4 | v4 is a major (breaking) release. A v3 CLI cannot drive the v4 layout, and no old-CLI guard artifact ships. v4 upgrades only from v3.x projects, and each v3 repo upgrades with `aid update`. Update the CLI with `aid update self` first, then run `aid update` in the project. **Done when** the v4 release notes carry this statement and the upgrade section of `docs/install.md` states the same order | `docs/install.md` § *Upgrading from the v3 layout* | Users run the upgrade with a v3 CLI, or on a pre-v3 repo through a path nothing tests | P1 |
| **W7-5** | `[CHANGE]` | Shared cross-tool skills folder | Every tool installs the same `aid-*` skills to `.agents/skills/`. Claude Code also gets a byte-identical mirror at `.claude/skills/`. Skills are no longer rendered into per-tool trees. **Done when** the suites `tests/canonical/test-shared-*.sh` pass | `lib/aid-install-core.sh` § `install_shared` | The release ships per-tool skill copies that drift apart, and the v4 notes describe a layout the CLI does not install | P1 |
| **W7-6** | `[CHANGE]` | Shared runtime at `.aid/runtime/` | Scripts, templates, `rules.md` and the CLI-written `host.conf` install once at `.aid/runtime/`, replacing the per-tool `aid/` subtrees. A managed `.gitattributes` block keeps the installed skills and runtime LF. **Done when** the suites `tests/canonical/test-shared-*.sh` pass | `lib/aid-install-core.sh` § `install_shared`; § `_aid_gitattributes_block` | Each tool keeps its own `aid/` copy, so the runtime that the root rules point to is missing or stale | P1 |
| **W7-7** | `[CHANGE]` | Root context in AGENTS.md and CLAUDE.md | `AGENTS.md` carries the AID region for every tool, an instruction to read `.aid/runtime/rules.md` plus the rules summary. While Claude Code is installed, `CLAUDE.md` carries the same body plus an `@.aid/runtime/rules.md` import line. **Done when** the suites `tests/canonical/test-shared-*.sh` pass | `lib/aid-install-core.sh` § `_ensure_claude_md_region` | Claude Code sessions do not load the AID rules, or the root files point at paths that do not exist | P1 |
| **W7-8** | `[CHANGE]` | Install manifest format 3 | The manifest records each shared entry once, with its users and a sha256 per file. Uninstall removes a shared entry only after its last user leaves. **Done when** `tests/canonical/test-shared-remove.sh` passes | `lib/aid-install-core.sh` § `install_shared` | Removing one tool deletes files another installed tool still uses, and `aid status` cannot report drift per file | P1 |
| **W7-9** | `[CHANGE]` | Per-tool artifacts hold agents only | Per-tool artifacts hold agents and `aid-tool.conf` only. The release ships `aid-shared-v<V>.tar.gz`, five `aid-<tool>-v<V>.tar.gz` artifacts, `aid-cli-v<V>.tar.gz` and `SHA256SUMS`, with no wrapper directory. **Done when** `tests/canonical/test-release.sh` passes | `release.sh` § `aid-shared-v` asset collection | The published assets do not match the shape the installer and the release notes describe | P1 |
| **W7-10** | `[CHANGE]` | Per-host worktree root | The worktree root is per host: `.claude/worktrees/` while Claude Code is installed, otherwise `.aid/.worktrees/`. **Done when** `tests/canonical/test-worktree-lifecycle.sh` passes | `canonical/aid/scripts/works/worktree-lifecycle.sh` § `.aid/.worktrees` | The docs and the scripts disagree on where worktrees are created | P1 |
| **W7-11** | `[CHANGE]` | Upgrade of v3 repos through `aid update` | `aid update` upgrades a v3 repo by moving its old AID paths into `.aid/.trash/`. `aid add` refuses a v3 repo and points to `aid update`. **Done when** the suites `tests/canonical/test-aid-migrate*.sh` pass | `lib/aid-install-core.sh` § `retire_v3_layout`; `bin/aid` § `This project uses the v3 AID` | A v3 repo is left half-upgraded, or `aid add` writes the shared layout on top of the v3 one | P1 |
| **W7-16** | `[CHANGE]` | Retired slash name `/aid-triage` | Old: `/aid-triage`. New: say what you want in plain words; the skill guide in the rules routes it. **Done when** the release notes carry this row in the old -> new table | `canonical/aid/rules.md` § Handling a request | Users who type the retired name get no route, and the notes do not say where routing went | P1 |
| **W7-17** | `[CHANGE]` | Retired agent `aid-orchestrator` | Old: agent `aid-orchestrator`. New: the agent in your tool, guided by `rules.md` and `/aid-orchestrate`. **Done when** the release notes carry this row in the old -> new table | `canonical/aid/rules.md` § Handling a request; `canonical/skills/aid-orchestrate/SKILL.md` | Users look for an agent the release no longer ships, and the notes do not say where orchestration went | P1 |

## Prioritized

Accepted items not yet committed to the current tag, ordered by priority.

| ID | Tag | Title | Definition & done-condition | Location | Risk if not done | Priority |
|----|-----|-------|-----------------------------|----------|-----------------|----------|
| **W7-15** | `[CHANGE]` | Coverage headers on every canonical suite, so suite selection stays small | `tests/canonical/select-suites.sh --since <base>` picks a suite only from its `# COVERS:` header; a suite with no header is always picked, as a fail-safe. 156 of the 169 suites under `tests/canonical/` carry no header, so almost every change selects almost every suite and a one-file change pays for a near-full run. Add a `# COVERS:` header to each suite, naming the paths it reads, and add a check that a new suite cannot land without one. **Done when** every suite under `tests/canonical/` carries a `# COVERS:` header, a suite asserts that none is missing, and a one-file change under `canonical/skills/` selects only the suites that read that skill | `tests/canonical/select-suites.sh`; the header block of each `tests/canonical/test-*.sh` | Every change keeps running the whole suite, so each build step costs 15-20 minutes of tests whatever its size, and contributors learn to skip the test step | P2 |
| **W5-20** | `[CHANGE]` | A refused or routed design-lifecycle run still leaves an allocated work folder and git worktree behind | The design-lifecycle skills allocate through the Work Initiation Gate at their `INTAKE` state — before the `GUARD` that refuses a seed whose `## Open questions` is non-empty, and before the `REALIZE` that routes to a prerequisite skill when the destination is absent. An invocation that writes nothing therefore still creates a `work-NNN` folder **and**, because allocation runs `worktree-lifecycle.sh create`, a git worktree the user must remove by hand. Decide whether that is the intended shape. Two coherent resolutions: move allocation to after both exits, or have each exit tear down what it allocated. **Done when** the allocation contract states the chosen rule explicitly and every skill body matches it, with the refusal and routing-exit paths asserted either way. Note the counter-argument on record: allocation is currently unconditional *by design*, so that a graded, reviewable work folder exists for every invocation — changing it is a contract change, not a bug fix | `canonical/aid/templates/design-lifecycle.md` § *Skill shape — Allocation*, and its binding-table row `Allocation via the Work Initiation Gate`; the `INTAKE` state of each `canonical/skills/aid-{design,create,update}-*/SKILL.md` body; `canonical/aid/scripts/works/worktree-lifecycle.sh` | Refused and routed runs accumulate empty work folders and stray git worktrees in every adopter's project, with no skill that cleans them up; and verification keeps re-deriving the same surprise, having already produced one unsatisfiable acceptance criterion from the assumption that a non-realizing run allocates nothing | P3 |
| **W7-12** | `[CHANGE]` | Model names out of agent frontmatter into a settings tier map with fallback lists | Agent files name concrete models today, per tool, through each profile's `[model_tiers]`. Move the choice into a settings map from tier (Large, Medium, Small) to a model, with an ordered fallback list per tier, so a host that lacks a model falls back instead of failing. **Done when** an agent renders without a hard-coded model name and a missing primary model resolves to the next one in its tier's list, asserted by a suite | `profiles/*.toml` § `[model_tiers]`; `canonical/agents/*/AGENT.md` | A host that drops or renames a model breaks every agent pinned to it, and switching models means editing five profiles | P3 |
| **W7-13** | `[CHANGE]` | One shared agents folder instead of per-tool agent trees | Agents stay per tool because their formats and folders differ (Codex TOML, `.claude/agents`, `.cursor/agents`, `.github/agents`, `.agent/agents`). Decide whether a shared agents source folder is possible once the formats allow it, or confirm per-tool agents as the permanent shape. **Done when** the decision is recorded in `decisions.md` and, if shared, one agents payload is installed for every tool | `release.sh` § `build_tool_artifact`; `lib/aid-install-core.sh` § `install_shared` | The skills are shared but the agents are not, so one repo driven from several IDEs still carries a separate agent tree per tool | P3 |
| **W7-14** | `[NEW]` | Hooks | The CLI installs no host hooks today, although four of the five profiles (all but Codex) declare the `hooks` capability (see `external-sources.md` for the hook references). Define which AID behaviour a hook should enforce and install it through the CLI under the `aid-` namespace. **Done when** the first hook installs, is recorded in the manifest and is removed with its tool | `profiles/*.toml` § `[capabilities]` | Behaviour that should be enforced mechanically, such as the state-write discipline, relies on the model remembering it | P3 |

## Gotchas

- **ID is inherited on promotion, never re-minted.** The `comm -12` duplicate-item oracle
  (V18) keys on the id; re-minting a promoted id makes the check compare unlike things and
  breaks the move audit entirely.
- **Parking an item in `## Next Release` is a commitment.** That section is drained at
  tag time by `release-aid`; every row there becomes a tagged release-note bullet in
  `release-tracking.md` and is deleted from `backlog.md` in the same run. Do not park
  an item there unless the current tag will include it.
- **An item is moved, never copied.** The promoted row is deleted from `tech-debt.md` in
  the same run that adds it to `backlog.md`. An item present in both documents is a
  checkable defect.

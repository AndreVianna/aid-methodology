# Requirements

- **Name:** Shared Cross-Tool Skills Folder
- **Description:** Ship one tool-neutral skill set that the AID CLI installs byte-identically into a shared `.agents/skills/` folder, with a CLI-owned `.claude/skills/` copy for Claude Code and the shared runtime under `.aid/runtime/`, so one repository can be driven from several AI coding tools at once

## 1. Objective

Every installed AID skill is byte-identical across host tools and lives in one shared install
location, so developers can use several IDEs on the same repo.

The repository keeps only the canonical skills. Nothing pre-renders a per-tool skill copy. The
release ships one skill set, `canonical/skills/` as-is, and the CLI alone decides where it goes at
install time: always `.agents/skills/`, plus a `.claude/skills/` copy when Claude Code is
installed. The shared runtime follows the same rule: `canonical/aid/` is placed by the CLI at
`.aid/runtime/` and is not pre-rendered per profile. Profiles keep only what is genuinely per-tool:
agents, root-context-file selection, model tiers and capability flags.

## 2. Problem Statement

**Current shape.** All counts below were measured from disk at authoring time and are
load-bearing, because they size the change. Recount them with the command given beside each.

- **Five rendered trees.** The generator renders one install tree per profile:
  `profiles/claude-code/.claude`, `profiles/codex/.codex`, `profiles/cursor/.cursor`,
  `profiles/copilot-cli/.github` and `profiles/antigravity/.agent`. Each tree holds `skills/`,
  `agents/` and `aid/{scripts,templates}`. Generator anchors: `render_profile` and `copy_tree` in
  `.claude/skills/generate-profile/scripts/render.py`. Every profile's
  `emission-manifest.jsonl` lists 210 skill files, 136 runtime files and 9 agents. Recount with
  `grep -c '"dst": *"[^"]*/skills/' profiles/*/emission-manifest.jsonl`.
- **The installed skill bytes differ per tool, for four reasons.** `canonical/skills/` holds 112
  skill directories and 210 files.
  - (a) **Path rewrite.** `rewrite_install_paths` in
    `.claude/skills/generate-profile/scripts/render_lib.py` rewrites `canonical/...` references
    to `<root>/aid/...` and `<root>/skills/...`. 178 of the 210 files carry at least one such
    token. Recount with
    `grep -rlE '(^|[^A-Za-z0-9_])canonical/(aid/)?(scripts|templates|skills|agents|recipes)/' canonical/skills | wc -l`.
  - (b) **Tool-name remap.** `_rewrite_skill_frontmatter` in `render.py` rewrites the
    `allowed-tools` line through each profile's `[tool_names]` table. Cursor maps
    `Bash = "Terminal"` (`profiles/cursor.toml`) and Copilot CLI maps `Bash = "shell"`
    (`profiles/copilot-cli.toml`). 107 of the 112 `allowed-tools` lines name `Bash`, and all of
    them are comma-separated.
  - (c) **Filename placeholders.** `substitute_filenames` replaces `{project_context_file}`
    (4 skill files) with the profile's `root_file`, and `{reviewer_output_file}` (1 file) with
    `STATE.md`.
  - (d) **Hard-coded host paths.** There are two kinds.
    - `.claude/worktrees` appears in `canonical/skills/aid-update-kb/SKILL.md` (search:
      `WT_ROOT="${MAIN_ROOT}/.claude/worktrees"`) and in `canonical/skills/aid-execute/SKILL.md`
      (search: "work-level `.claude/worktrees/work-NNN-{name}`"). The runtime twin is
      `_worktrees_root_from` in `canonical/aid/scripts/works/worktree-lifecycle.sh`.
    - `.claude/aid/scripts/...` is hard-coded in `canonical/skills/aid-discover/references/state-generate.md`
      and `canonical/skills/aid-discover/references/agent-prompts.md`. That path is wrong on
      every non-Claude tool today.
  - The 34 generated shortcut doorways also carry a provenance comment that names the maintainer
    path `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`.
  - A fifth transform exists in the code but changes nothing today. `render.py` strips `context:`
    and `agent:` frontmatter keys for profiles other than Claude Code, and no canonical skill
    currently carries either key.
- **Two root-context sources.** Claude Code installs `CLAUDE.md` and the other four tools install
  `AGENTS.md` (`_root_agent_file` in `lib/aid-install-core.sh`). The two sources differ inside the
  `AID:BEGIN`/`AID:END` region. `profiles/claude-code/CLAUDE.md` uses `@.aid/knowledge.` imports
  and `.claude/aid/templates/...` paths, while `profiles/*/AGENTS.md` uses "Read" lines and
  root-relative `aid/templates/...` paths.
- **Per-tool CLI install.** `install_tool` in `lib/aid-install-core.sh` and `Install-AidTool` in
  `lib/AidInstallCore.psm1` copy one tool's tree. The manifest
  (`.aid/.aid-manifest.json`, `format_version: 2`) records paths per tool and a sha256 only for
  root agent files. On update, `copy_file` always overwrites AID-owned files that differ. Two
  things are sha-guarded today:
  - `uninstall_tool` keeps the root agent file in place when its sha no longer matches the
    recorded one.
  - `_copy_root_agent_file` applies the C1/C2 no-marker migration.

  Retired AID-owned files are moved to `.aid/.trash/<path>` by `_migrate_retired_layout`. They
  are not deleted.
- **No sharing model.** Each installed tool records `AGENTS.md` among its own paths. Nothing in
  `uninstall_tool` checks whether another installed tool still uses a path before removing it.
- **`.agents/` is a retired Codex root today.** The old Codex split layout lived there
  (`.aid/knowledge/release-tracking.md`, search: "the former `.agents/` split root is retired").
  Three pieces of code still act on it:
  - `detect_tool` treats a `.agents/` directory as a Codex marker.
  - `_migrate_retired_layout` sweeps `.agents/` on a Codex install.
  - The manifest-seam gate in `install_tool` aborts any bundle that contains a `.agents/` path
    (search: `_retired_roots=(".agents/"`).

  The PowerShell twins `Detect-Tool`, `Invoke-MigrateRetiredLayout` and `Install-AidTool` behave
  the same way.
- **Per-tool release.** `release.sh` (`build_tarball`) packages five per-tool tarballs, each
  holding a full rendered tree plus its root file.
- **Dogfood is a render copy.** This repo's `.claude/` and `.cursor/` trees are copied from the
  profile renders by `.claude/skills/generate-profile/scripts/sync_dogfood.py`.
  `tests/canonical/test-dogfood-byte-identity.sh` guards them.

**Pain.** One developer who uses several IDEs on one repo gets one AID install per tool. That means
duplicated skill sets whose bytes differ, and duplicated runtimes under each tool root. The host
tools then mix those copies. The maintainer probe (see §8) found the following:

- Cursor and Antigravity list a same-named skill from `.claude/skills` and `.agents/skills` only
  once.
- Cursor showed the description from the `.agents` copy but executed the body from the `.claude`
  copy.
- Antigravity used the `.agents` copy.

Any byte difference between copies therefore produces mixed, unpredictable behaviour.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| Multi-IDE developer | Uses two or more of Claude Code, Codex, Cursor, Copilot CLI, Antigravity on one repo | One skill set that behaves identically in every tool, and one runtime |
| Single-tool adopter | Existing user with one tool installed (format-4 layout) | `aid update` migrates them with no lost edits and no change in skill behaviour |
| AID maintainer | Edits `canonical/`, cuts releases, dogfoods AID in this repo | One source with no per-tool skill render, a simple release, and a dogfood tree produced the same way users get theirs |
| Distribution channels | `install.sh`/`install.ps1`, npm (`packages/npm`), PyPI (`packages/pypi`) | They vendor the updated `lib/` unchanged in shape; checksum verification covers the new artifacts |

## 4. Scope

### In Scope

- Make the canonical skills tool-neutral so they can ship verbatim. That covers paths, filename
  placeholders, host-specific paths, the `allowed-tools` format, and the generated-skill
  provenance comment (`build-shortcut-skills.py`).
- Make the canonical runtime (`canonical/aid/`) safe to place verbatim at `.aid/runtime/`.
- Remove the generator's skill and runtime rendering. Profiles keep agents and per-tool data, and
  `canonical/EMISSION-MANIFEST.md` and the generator self-tests are updated to match.
- Repackage the release as one shared payload (skills, runtime, `AGENTS.md` region source) plus
  per-tool extras (agents).
- Change CLI placement to:
  - `.agents/skills/aid-*` for every tool;
  - a CLI-owned `.claude/skills/aid-*` mirror for Claude Code;
  - `.aid/runtime/` for the runtime;
  - an `AGENTS.md` managed region for every tool.
- CLI multi-tool support:
  - reference-counted shared entries in the manifest;
  - drift detection and repair;
  - a one-version-per-repo policy;
  - a layout format bump with migration from every old layout;
  - the `CLAUDE.md` region migration.
- Bash and PowerShell parity, with tests.
- A tool-neutral work-level worktree root.
- Resync this repo's dogfood trees by CLI install.
- Update the KB, root context files, `docs/` and CI references that state the old layout.

### Out of Scope

- **Agents.** They stay per-tool, because their formats and folders differ (Codex TOML, per-tool
  `agents/` folders). Only their references to the runtime path change.
- **Model names.** Moving model names out of agent frontmatter into a settings tier map with
  fallback lists is a separate future work.
- **Hooks** are a separate future work.
- **Symlinks** are rejected (see §8). So is a Claude Code plugin or marketplace route, because it
  namespaces skills as `/aid:aid-ask` and needs an absolute marketplace path.
- **Skill behaviour.** No skill behaviour change beyond the neutralisations listed in FR-1 and
  FR-2.
- **Per-task worktrees.** The per-task worktree root `.aid/.worktrees/task-NNN/` used by
  `aid-execute` is unchanged.
- **Live connector consumption.** aid-managed connector consumption stays deferred.

## 5. Functional Requirements

- **FR-1: Tool-neutral canonical skills.** Every file under `canonical/skills/` is final installed
  bytes:
  - Runtime references are the fixed project-root-relative form `.aid/runtime/scripts/...` and
    `.aid/runtime/templates/...`.
  - Cross-skill references use `.agents/skills/aid-*/...`, which is present for every tool by
    FR-6.
  - References to agents name the agent (for example `aid-architect`), not a per-tool path.
  - `{project_context_file}` is written as `AGENTS.md`, and the other filename placeholders are
    written as their resolved values.
  - No host-specific path remains. `.claude/worktrees` is replaced by the neutral root from
    FR-13, and `.claude/aid/...` by `.aid/runtime/...`.
  - The generated-doorway provenance comment names no host install root.

  `build-shortcut-skills.py` emits this form, so a regeneration cannot reintroduce the old one.
- **FR-2: `allowed-tools` format.** The rules follow the Agent Skills spec:
  - Every `allowed-tools` value is space-separated.
  - Where the shell is allowed, it is listed as the aliases `Bash Shell Terminal`.
  - No skill frontmatter key is host-specific (no `context:`, no `agent:`).
  - No per-tool tool-name remap applies to skills.
- **FR-3: Tool-neutral canonical runtime.** `canonical/aid/{scripts,templates}` is placed verbatim
  at `.aid/runtime/{scripts,templates}`. Any reference in it that must resolve in an installed
  project uses the `.aid/runtime/`, `.agents/skills/` or agent-name forms from FR-1.
- **FR-4: Generator stops rendering skills and runtime.**
  - `render_profile` emits agents only: the per-tool frontmatter translate stays, and runtime
    references point at `.aid/runtime/`.
  - Profile emission manifests carry no `skills/` and no `aid/` rows.
  - The generator self-tests and the VERIFY gate are updated, and `run_generator.py` stays the
    single full-render command.
  - Profile TOMLs keep only per-tool data: `root_dir` for agents, root-file selection,
    `[tool_names]` for agents, `[model_tiers]`, `[capabilities]`, and the skill-mirror list from
    FR-6.
- **FR-5: Release packaging.**
  - `release.sh` builds one shared payload: `canonical/skills/` as-is, `canonical/aid/` as-is, and
    the single `AGENTS.md` region source.
  - It also builds one per-tool artifact for each of the five tools, holding agents and any
    per-tool extra. No per-tool artifact contains skills or runtime.
  - Every artifact is listed in `SHA256SUMS`, and the CLI verifies it fail-closed exactly as
    `fetch_tarball` and `verify_bundle_checksum` do today.
  - A format-4 CLI must not silently produce a partial install from a new-layout release. Either
    the artifact naming keeps it from fetching one, or its install aborts. The SPEC picks the
    mechanism.
- **FR-6: CLI placement.** For every tool, `aid add` and `aid update` place:
  - the shared skills at `.agents/skills/aid-*/`;
  - the runtime at `.aid/runtime/`;
  - the `AGENTS.md` managed region.

  A profile may declare skill-mirror directories. Claude Code declares `.claude/skills`. For each
  mirror the CLI writes a byte-identical copy of every `aid-*` skill file. The CLI never creates
  symlinks. It never reads, writes or prunes a non-`aid-*` entry in `.agents/skills/` or in a
  mirror; this repo's `.claude/skills/generate-profile/` and `.claude/skills/release-aid/` are
  examples that must survive. `.aid/runtime/` is wholly CLI-owned, so a file there that the
  manifest does not record is pruned, as `<root>/aid/` is today. Install and uninstall never
  modify user-owned `.aid/` state. That means `.aid/knowledge/`, `.aid/works/`, `.aid/design/`
  and `.aid/connectors/` are untouched, and `.aid/settings.yml` keeps its existing seed-on-install
  and remove-on-last-uninstall behaviour. `.aid/runtime/` is not added to the `.gitignore`
  managed block, matching how `<root>/aid/` is treated today.
- **FR-7: Manifest records shared entries.** The install manifest records three things for every
  shared entry (the files under `.agents/skills/aid-*`, each mirror, `.aid/runtime/`, and the
  `AGENTS.md` region):
  - the installed tools that use it;
  - the AID version it was written at;
  - for each file, its sha256.

  The manifest `format_version` is bumped, and bash, PowerShell and the `bin/aid` /
  `bin/aid.ps1` readers all read the new shape.
- **FR-8: Reference-counted uninstall.** `aid remove <tool>` removes the tool's own files and
  takes the tool off every shared entry's user list. A shared entry is removed only when its user
  list becomes empty. A mirror is removed when the tool that declared it is removed. The existing
  rule that a modified root file is left in place still holds.
- **FR-9: Drift detection and repair.**
  - `aid status` compares every file of every shared entry with its manifest-recorded sha256, and
    compares each mirror with `.agents/skills`. It reports each modified, missing or extra
    `aid-*` file by path and names `aid update` as the fix.
  - `aid add` and `aid update` repair drift by rewriting from the verified payload. A drifted file
    is first moved to `.aid/.trash/<original-path>`, so no edit is lost.
- **FR-10: One AID version per repo (decision: refuse on mismatch; upgrade only through
  `aid update`).** This keeps the existing same-version contract in `bin/aid` (search:
  `FR11: aid add version selection`):
  - `aid add` installs a new tool at the project's existing version.
  - `aid add --version <v>` with `v` different from the project version exits 2 and writes
    nothing.
  - `aid update` stages every installed tool plus the shared payload first, then commits them all
    at one version.

  Two refusals are added:
  - `aid add` refuses, naming `aid update`, when the manifest already records tools at differing
    versions.
  - `aid add` refuses, naming `aid update`, when the project's layout format is older than the
    CLI's.

  *Justification.* Shared files can hold only one version's bytes. If `add` upgraded them
  silently, it would change the skills another tool's user depends on without being asked.
  Refusing keeps `add` non-disruptive, which is the existing contract, and leaves a single,
  explicit, atomic upgrade path.
- **FR-11: Layout format bump and migration.** The repo layout stamp `AID_SUPPORTED_FORMAT` is
  bumped in all three carriers (`bin/aid`, `bin/aid.ps1`, `lib/AidInstallCore.psm1`), so the
  existing `_aid_format_gate` makes an older CLI refuse a migrated repo. `aid update` on an
  old-layout repo migrates it, for each installed tool, from these layouts:
  - `.claude/aid/` and `.claude/skills/aid-*`, where the latter becomes the mirror;
  - `.codex/aid/` and `.codex/skills/aid-*`, plus the legacy `.agents/aid/`;
  - `.cursor/aid/` and `.cursor/skills/aid-*`;
  - `.github/aid/` and `.github/skills/aid-*`;
  - `.agent/aid/` and `.agent/skills/aid-*` (Antigravity), which move to `.agents/skills`.

  Every retired AID-owned file is moved to `.aid/.trash/<original-path>` and never deleted. The
  ownership markers are the same as in `_migrate_retired_layout`: an `aid-` prefix, or a location
  inside an `aid/` subtree. Files without a marker are never touched. The migration is
  idempotent, so a second `aid update` changes nothing.

  `.agents/` stops being a retired root. `detect_tool` and `Detect-Tool` stop treating it as a
  Codex marker. The manifest-seam retired-roots list and `_migrate_retired_layout` are updated so
  they never sweep or reject `.agents/skills/`.
- **FR-12: One root context file.** Every tool, Claude Code included, uses the `AGENTS.md`
  managed region. That region is a single, reference-counted shared entry under FR-7 and FR-8.
  When the CLI migrates a Claude Code install, it handles `CLAUDE.md` as follows:
  - If `CLAUDE.md` still has the sha the manifest recorded, so it was never user-edited, it is
    deleted.
  - If it carries `AID:BEGIN`/`AID:END` markers and was edited, only the marked region is removed
    and every byte outside it is preserved.
  - If it has no markers and was edited, it is left byte-unchanged, and the CLI prints a WARN
    naming the file and the AID sections to remove by hand.

  The CLI no longer creates or records `CLAUDE.md`.
- **FR-13: Neutral work-level worktree root.** The work-level worktree container moves from
  `.claude/worktrees/` to a tool-neutral root under `.aid/`. The proposal is `.aid/.worktrees/`,
  beside the existing per-task worktrees; the SPEC confirms it. The new root is covered by the
  `.gitignore` managed block. `worktree-lifecycle.sh locate` still finds existing worktrees under
  `.claude/worktrees/`, since lookup is branch-keyed.
- **FR-14: Polyglot parity.** Every new or changed bash function in `lib/aid-install-core.sh` and
  `bin/aid` has a behaviour-identical PowerShell twin in `lib/AidInstallCore.psm1` and
  `bin/aid.ps1`. Both are covered by `tests/canonical/test-aid-cli-parity.sh` and
  `tests/canonical/test-install-parity.sh`. The PowerShell stays ASCII-only and runs on Windows
  PowerShell 5.1.
- **FR-15: Packages.** `packages/npm/scripts/vendor.js` and `packages/pypi/scripts/vendor.py`
  vendor the updated `lib/` and `bin/`. Their vendored file set does not change in shape.
- **FR-16: Dogfood by CLI install.** This repo's installed trees are produced by running the CLI
  against a local release staging directory: `bash release.sh --dry-run`, then
  `aid update --from-bundle <staging>`. They are not copied from profile renders.
  `sync_dogfood.py` is retired or re-pointed, `tests/canonical/test-dogfood-byte-identity.sh` is
  re-keyed to the new layout, and the maintainer procedure is documented in
  `.claude/skills/generate-profile/SKILL.md`.
- **FR-17: Docs and KB.** Every statement of the old layout is updated in the same change:
  - the root `CLAUDE.md` and `AGENTS.md` regions and their sources;
  - `README.md`, `docs/install.md` and `docs/aid-methodology.md`;
  - `.github/workflows/test.yml`;
  - the KB docs that state the layout, including the content-isolation invariant in
    `.aid/knowledge/architecture.md` § Invariants and `G-10`, `G-11` in
    `.aid/knowledge/authoring-conventions.md`.

  Shipped history in `.aid/knowledge/release-tracking.md` is left as history. A
  `release-tracking.md` / `backlog.md` entry for this change follows the project's normal
  release-tracking flow.

## 6. Non-Functional Requirements

- **Byte-identity.** Byte-identity is the correctness bar. Any byte difference between an
  installed skill copy and `canonical/skills/` is a defect. No transform, line-ending conversion
  or encoding change may be applied between the source, the release payload and the install.
- **Windows-safe.** No symlinks and no hard links. Every placement is a plain file copy, and the
  installed result is the same on Windows, macOS and Linux.
- **Safety of user content.** No install, update, migration, repair or uninstall path deletes a
  file without an AID ownership marker. Every AID-owned file that is replaced or retired while it
  differs from the bytes AID is writing is preserved under `.aid/.trash/`.
- **Atomicity and idempotency.** The existing stage-all-first behaviour is kept: every payload is
  fetched and checksum-verified before any destination write. A repeated `aid update` at the same
  version reports nothing changed.
- **Integrity.** Every new release artifact is covered by `SHA256SUMS` and the existing fail-closed
  verification. The endpoint-override gating (`AID_ALLOW_ENDPOINT_OVERRIDE`) is unchanged.

## 7. Constraints

- `canonical/` is the only editable source. After any `canonical/` edit, run the FULL
  `python .claude/skills/generate-profile/scripts/run_generator.py`, and keep the CI
  `render-drift` job (`.github/workflows/test.yml`) green for the agent-only profiles.
- Bash and PowerShell parity is mandatory. Shipped PowerShell is ASCII-only and runs on PS 5.1.
  Committed `.sh` files are LF-only.
- Version lockstep (`VERSION`, `packages/npm/package.json`, `packages/pypi/pyproject.toml`, the
  manifest `aid_version`) holds and is checked by `canonical/aid/scripts/release/check-version-sync.sh`.
- The layout format stamp is bumped together in all three of its carriers.
- Test keys removed or renamed in `tests/coverage-baseline.tsv` need matching rows in
  `tests/coverage-accepted-removals.tsv`, or the coverage-parity gate fails.
- Heavy CI gates run only on `master`. Before claiming green, run
  `HOME=$(mktemp -d) bash tests/run-all.sh` locally, HOME-pinned.
- Tests build their own fixtures and never depend on a work folder.
- KB edits never name this work.
- Trap: `.aid/knowledge/INDEX.md` embeds the generator script path checked by the `kb-hygiene`
  CI job (`.aid/knowledge/architecture.md` § Gotchas). Once the runtime installs verbatim, that
  embedded path must still satisfy the check.

## 8. Assumptions & Dependencies

**Evidence: a manual maintainer probe on Windows.** It covered Claude Code (auto and default
mode), Cursor and Antigravity v2.22.0. The Claude Code docs (skills, settings reference,
changelog) were checked on 2026-10-10.

- **Who reads `.agents/skills`.** Cursor and Antigravity read it. Claude Code does not, and its
  docs offer no setting to add a skills path. That is why the `.claude/skills` mirror exists.
- **Duplicate copies.** A same-named skill in both `.claude/skills` and `.agents/skills` is listed
  once by Cursor and Antigravity. Cursor used the `.agents` description with the `.claude` body,
  and Antigravity used the `.agents` copy. Copies must therefore be byte-identical.
- **Runtime path.** A fixed `.aid/runtime/probe.txt` path resolved from the project root in all
  three probed tools.
- **`allowed-tools` behaviour.**
  - `allowed-tools: Bash` was pre-approved in Claude Code default mode.
  - A generic `Shell` caused a permission prompt but did not break the skill.
  - Antigravity prompted for both, because it ignores `allowed-tools`.
  - Cursor was inconclusive.
- **Symlinks were rejected.** Windows needs Developer Mode or admin rights and git
  `core.symlinks`; otherwise symlinks check out silently as text files.

**Assumptions, each with a verification criterion and a fallback.**

- **A-1: Codex reads `.agents/skills`.** Only third-party sources report this.
  - *Verify:* manual probe, AC-20.
  - *Fallback:* Codex declares a skill mirror (FR-6), for example `.codex/skills`.
- **A-2: Copilot CLI reads `.agents/skills`.** Its docs say so; the probe did not test it.
  - *Verify:* AC-20.
  - *Fallback:* a Copilot mirror under FR-6.
- **A-3: Claude Code loads the project-root `AGENTS.md` as context.** The probe evidence above
  did not test this.
  - *Verify:* AC-20.
  - *Fallback:* keep a minimal CLI-owned `CLAUDE.md` managed region that contains only the
    `@AGENTS.md` import. User content outside it is preserved as in FR-12.
- **A-4: `allowed-tools: ... Bash Shell Terminal ...` is accepted by every host.** Unknown names
  must be ignored without error, and Claude Code must still pre-approve `Bash`. Copilot CLI's
  former remap target was lowercase `shell`.
  - *Verify:* AC-20.
  - *Fallback:* the SPEC revisits the alias list. Per-tool remapping does not return.
- **A-5: Claude Code's `EnterWorktree` accepts a worktree path outside `.claude/worktrees/`.**
  - *Verify:* AC-20.
  - *Fallback:* the SPEC keeps host-native entry working without reintroducing a host path into a
    skill. For example, the root choice lives only in the runtime script.

**Dependencies.**

- The existing install core (`install_tool`, `uninstall_tool`, `_migrate_retired_layout`,
  `_copy_root_agent_file`, `_prune_tool_dirs`) and its PowerShell twins.
- The format gate `_aid_format_gate` and `_aid_migrate_repo` in `bin/aid`.
- `release.sh` and the release workflow.
- The KB docs `architecture.md`, `project-structure.md`, `module-map.md`, `integration-map.md`,
  `infrastructure.md`, `test-landscape.md` and `authoring-conventions.md`.

## 9. Acceptance Criteria

- **AC-1:** Skills and runtime are no longer rendered.
  - After `python .claude/skills/generate-profile/scripts/run_generator.py`, which prints
    `VERIFY (deterministic): PASS`, the command
    `grep -cE '"dst": *"[^"]*/(skills|aid)/' profiles/*/emission-manifest.jsonl` prints `0` for
    all five manifests.
  - `find profiles -type d \( -name skills -o -name aid \)` prints nothing.
- **AC-2:** The release ships one skill set.
  - After `bash release.sh --dry-run`, the staging directory holds exactly one shared payload
    artifact, one per-tool artifact for each of the five tools, and the CLI bundle. All of them
    are listed in `SHA256SUMS`.
  - In the extracted shared payload, every file under `canonical/skills/` and `canonical/aid/` has
    a byte-identical counterpart at the same relative path, and there are no extra or missing
    files.
  - No per-tool artifact contains a skills or runtime path.
  - These checks are asserted by `tests/canonical/test-release.sh`.
- **AC-3:** Installed skills are byte-identical to canonical.
  - A `tests/canonical/` suite runs `aid add <tool> --from-bundle <staging>` into a fresh fixture
    repo for each of the five tools. It asserts that every `canonical/skills/<rel>` equals
    `.agents/skills/<rel>` byte-for-byte, and also equals `.claude/skills/<rel>` for Claude Code.
  - `find .agents/skills -path '*/aid-*' -type f | wc -l` equals
    `find canonical/skills -type f | wc -l`.
  - A negative control proves the suite catches drift: it mutates one byte of one staged skill and
    the suite must then fail.
- **AC-4:** Canonical skills contain no rendering tokens. Each of these commands prints `0`:
  - `grep -rlE '(^|[^A-Za-z0-9_])canonical/(aid/)?(scripts|templates|skills|agents|recipes)/' canonical/skills | wc -l`
  - `grep -rlE '\{(project_context_file|reviewer_output_file|open_questions_file)\}' canonical/skills | wc -l`
  - `grep -rlE '\.(claude|codex|cursor|agent)/' canonical/skills | wc -l`
  - `grep -rlE '\.github/(aid|skills|agents)/' canonical/skills | wc -l`
  - `grep -rn '\.claude/worktrees' canonical | wc -l`
- **AC-5:** Runtime references are neutral. The non-comment lines of `canonical/aid/` contain no
  `canonical/(aid/)?(scripts|templates|skills|agents|recipes)/` token and no
  `.claude|.codex|.cursor|.agent` install-root path. The only exceptions are lines listed in an
  allowlist file that a test reads, where each entry states why the path is meant to resolve in
  the AID source repo. That test passes in `tests/run-all.sh`.
- **AC-6:** `allowed-tools` follows FR-2.
  - `grep -l '^allowed-tools:.*,' canonical/skills/*/SKILL.md | wc -l` prints `0`.
  - The count of SKILL.md files whose `allowed-tools` names `Bash` equals the count whose
    `allowed-tools` contains `Bash Shell Terminal`.
  - `grep -lE '^(context|agent):' canonical/skills/*/SKILL.md | wc -l` prints `0`.
- **AC-7:** The runtime layout holds after `aid add` for each tool in a fixture repo.
  - Every file in `.aid/runtime/{scripts,templates}/` equals its `canonical/aid/{scripts,templates}/`
    source byte-for-byte.
  - No `aid/` directory exists under `.claude`, `.codex`, `.cursor`, `.github` or `.agent`.
  - The fixture's pre-seeded `.aid/knowledge/x.md`, `.aid/works/w/STATE.yml` and `.aid/design/d.md`
    keep identical sha256 before and after `aid add`, `aid update` and `aid remove`.
  - A stray file placed in `.aid/runtime/` is pruned by the next `aid update`.
- **AC-8:** The work-level worktree root is neutral.
  - In a fixture repo, `worktree-lifecycle.sh create work-001 x` prints a path under the FR-13
    root, and that root appears in the `.gitignore` AID managed block.
  - A fixture worktree pre-registered at `.claude/worktrees/work-002-y` (branch `work-002`) is
    returned by `worktree-lifecycle.sh locate work-002` with status `registered`.
- **AC-9:** Shared entries are reference-counted. In a fixture repo, run
  `aid add claude-code,cursor,codex`, then `aid remove cursor`.
  - `.agents/skills/aid-*`, `.claude/skills/aid-*`, `.aid/runtime/` and `AGENTS.md` keep identical
    sha256.
  - `.cursor/agents/aid-*` is gone, and the manifest's user lists no longer name `cursor`.
  - After `aid remove codex`, the shared entries are still present.
  - After `aid remove claude-code`, `.agents/skills/aid-*`, `.claude/skills/aid-*` and
    `.aid/runtime/` are absent.
  - Throughout, the fixture's non-AID `.agents/skills/my-skill/SKILL.md` and
    `.claude/skills/my-skill/SKILL.md` keep identical sha256.
- **AC-10:** Drift is detected and repaired. After `aid add claude-code`, append one byte to
  `.claude/skills/aid-ask/SKILL.md`, delete `.claude/skills/aid-fix/SKILL.md`, and append one byte
  to `.agents/skills/aid-plan/SKILL.md`.
  - `aid status` output names all three paths and the text `aid update`.
  - `aid update --from-bundle <same staging>` restores all three to canonical bytes.
  - The two modified files exist byte-for-byte under `.aid/.trash/` at their original relative
    paths.
  - A second `aid status` reports no drift.
- **AC-11:** Version skew is refused.
  - In a fixture at project version X, `aid add cursor --version Y` with Y different from X exits
    `2`, and a sha256 snapshot of the whole fixture tree is unchanged.
  - `aid add cursor` installs cursor at X.
  - With a manifest whose tools record differing versions, `aid add` exits non-zero and its
    message names `aid update`.
  - `aid update --from-bundle <staging>` leaves every tool `version` and every shared-entry version
    in the manifest equal to `aid_version`.
- **AC-12:** The format bump guards old and new CLIs.
  - `AID_SUPPORTED_FORMAT` in `bin/aid`, `AidSupportedFormat` in `bin/aid.ps1` and
    `$script:_AidSupportedFormat` in `lib/AidInstallCore.psm1` hold the same value, one above the
    pre-change value of `4`.
  - The new CLI's `aid add` into a format-4-layout fixture exits non-zero, writes nothing, and
    names `aid update`.
  - A test proves the FR-5 guarantee: a format-4 install core given the new release artifacts
    either finds no artifact under its expected name or aborts non-zero, and in both cases writes
    no partial install.
- **AC-13:** Migration works from every old layout. A fixture is built for each of the five tools
  in its format-4 layout, including Antigravity `.agent/skills` and the legacy Codex
  `.agents/aid/`. Each fixture contains:
  - one user-modified AID file in the old `skills/aid-*` and in the old `aid/` subtree;
  - one non-AID user file in each old directory.

  After `aid update --from-bundle <staging>`:
  - The AC-3 and AC-7 checks pass.
  - No `aid-*` entry remains under `.codex/skills`, `.cursor/skills`, `.github/skills` or
    `.agent/skills`, and no `<root>/aid/` remains.
  - Each modified file exists byte-for-byte under `.aid/.trash/<original-path>`.
  - Each non-AID file keeps identical sha256.
  - `.aid/settings.yml` `format_version` equals the new value.

  A second `aid update` prints `up to date` for every tool and leaves `.aid/.trash/` unchanged.
- **AC-14:** `CLAUDE.md` is migrated safely for three Claude Code fixtures.
  - (a) A `CLAUDE.md` whose sha equals the manifest-recorded sha is deleted.
  - (b) A user-edited `CLAUDE.md` with `AID:BEGIN`/`AID:END` markers equals, byte-for-byte, its
    pre-update content with the marked region (marker lines included) removed.
  - (c) A user-edited `CLAUDE.md` with no markers is byte-unchanged, and the run prints a WARN
    line naming it.
  - In all three, `AGENTS.md` contains exactly one `<!-- AID:BEGIN -->` line.
- **AC-15:** Tool detection is fixed. `detect_tool` on a fixture holding only `.agents/` exits `2`
  (undetectable) and does not print `codex`. On a fixture holding `.codex/` it prints `codex`.
  `Detect-Tool` behaves the same way.
- **AC-16:** Bash and PowerShell stay in parity. `tests/canonical/test-aid-cli-parity.sh`,
  `tests/canonical/test-install-parity.sh` and `tests/canonical/test-ps51-compat.sh` pass. The
  parity suite names every function added or changed for FR-6 to FR-12. On Windows,
  `tests/windows/Test-AidInstaller.ps1` passes with the AC-9, AC-10 and AC-13 scenarios added.
- **AC-17:** The packages are updated. `tests/canonical/test-npm-installer.sh` and
  `tests/canonical/test-pypi-installer.sh` pass, and the vendored `lib/aid-install-core.sh` and
  `lib/AidInstallCore.psm1` match `lib/` by sha256.
- **AC-18:** The dogfood trees are resynced. In this repo:
  - every `canonical/skills/<rel>` equals `.agents/skills/<rel>` and `.claude/skills/<rel>`;
  - `.aid/runtime/` equals `canonical/aid/`;
  - `.claude/aid/`, `.cursor/aid/` and `.cursor/skills/aid-*` are absent;
  - `.claude/skills/generate-profile/SKILL.md` and `.claude/skills/release-aid/SKILL.md` are
    present;
  - `.aid/.aid-manifest.json` records the shared entries.

  The re-keyed `tests/canonical/test-dogfood-byte-identity.sh` passes.
- **AC-19:** Docs and KB no longer state the old layout.
  - `git grep -nE '\.(claude|codex|cursor|agent)/aid/|\.github/aid/' -- CLAUDE.md AGENTS.md README.md docs .github/workflows .aid/knowledge ':!.aid/knowledge/release-tracking.md' ':!.aid/knowledge/kb.html'`
    prints no lines.
  - A reviewer confirms that `.aid/knowledge/architecture.md` § Invariants (content isolation) and
    criteria `G-10` and `G-11` in `.aid/knowledge/authoring-conventions.md` state the
    `.aid/runtime/` and `.agents/skills/aid-*` placement rules.
- **AC-20:** Host assumptions are verified. A maintainer repeats the §8 manual probe method and
  records a pass or fail for each of A-1 to A-5 as a `lifecycle_history` entry in this work's
  `STATE.yml`. Each failed assumption has
  its §8 fallback implemented and covered by an added criterion before the work is marked Done.
- **AC-21:** The existing suites stay green.
  - `HOME=$(mktemp -d) bash tests/run-all.sh` exits `0`, including the coverage-parity gate.
  - `python .claude/skills/generate-profile/scripts/render.py --self-test --canonical-root .`
    exits `0`.

## 10. Priority

**Must.** The internal order is the dependency order:

1. FR-1 to FR-4: neutral canonical sources and the generator change.
2. FR-5: release payload.
3. FR-6 to FR-12 and FR-14: CLI placement, manifest, uninstall, drift, version policy, migration,
   root context file and parity.
4. FR-13: worktree root.
5. FR-15 to FR-17: packages, dogfood and docs/KB.

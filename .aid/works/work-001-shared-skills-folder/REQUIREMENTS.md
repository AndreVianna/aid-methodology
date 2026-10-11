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

This ships as AID v4.0.0, a breaking major release: `VERSION` becomes 4.0.0 through the normal
release flow, and the release notes state `v4 requires CLI v4`.

## 2. Problem Statement

**Current shape.** All counts below were measured from disk at authoring time and are
load-bearing, because they size the change. Recount them with the command given beside each.

- **Five rendered trees.** The generator renders one install tree per profile:
  `profiles/claude-code/.claude`, `profiles/codex/.codex`, `profiles/cursor/.cursor`,
  `profiles/copilot-cli/.github` and `profiles/antigravity/.agent`. Each tree holds `skills/`,
  `agents/` and `aid/{scripts,templates}`. Generator anchors: `render_profile` and `copy_tree` in
  `.claude/skills/generate-profile/scripts/render.py`. Every profile's
  tree holds 210 skill files, 136 runtime files and 9 agents. Recount the skill files with
  `find profiles/codex/.codex/skills -type f | wc -l`.
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
| Single-tool adopter | Existing user with one tool installed (v3 layout) | `aid update` moves the old AID files to `.aid/.trash/` and installs the v4 layout, with no lost edits and no change in skill behaviour |
| AID maintainer | Edits `canonical/`, cuts releases, dogfoods AID in this repo | One source with no per-tool skill render, a simple release, and a dogfood tree produced the same way users get theirs |
| Distribution channels | `install.sh`/`install.ps1`, npm (`packages/npm`), PyPI (`packages/pypi`) | They vendor the updated `lib/` unchanged in shape; checksum verification covers the new artifacts |

## 4. Scope

### In Scope

- Release as AID v4.0.0, a breaking major release: `VERSION` becomes 4.0.0 through the normal
  release flow, and the release notes state `v4 requires CLI v4`.
- Make the canonical skills tool-neutral so they can ship verbatim. That covers paths, filename
  placeholders, host-specific paths, the `allowed-tools` format, and the generated-skill
  provenance comment (`build-shortcut-skills.py`).
- Make the canonical runtime (`canonical/aid/`) safe to place verbatim at `.aid/runtime/`.
- Remove the generator's skill and runtime rendering. The generator wipes and regenerates each
  `profiles/<tool>/` in full on every run, profiles keep agents and per-tool data only, the profile
  manifest machinery is retired (FR-4), and the generator self-tests are updated to match.
- Repackage the release as one shared payload (skills and runtime, `rules.md` included) plus
  per-tool extras (agents).
- Change CLI placement to:
  - `.agents/skills/aid-*` for every tool;
  - a CLI-owned `.claude/skills/aid-*` mirror for Claude Code;
  - `.aid/runtime/` for the runtime;
  - an `AGENTS.md` managed pointer region (to `.aid/runtime/rules.md`) for every tool;
  - while Claude Code is installed, a `CLAUDE.md` managed region whose only content is the
    `@AGENTS.md` import.
- CLI multi-tool support:
  - reference-counted shared entries in the manifest;
  - drift detection and repair;
  - a one-version-per-repo policy;
  - a layout format bump with a clean-slate upgrade from v3 (old AID paths and root-file regions to
    `.aid/.trash/`, then a fresh install);
  - content-based repair of malformed root-file regions.
- Bash and PowerShell parity, with tests.
- A work-level worktree root resolved per host at runtime (FR-13), never named in a skill.
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
- **v3 CLI protection.** No guard artifact, frozen v3 core or orphan recovery: v4 requires CLI v4.

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
  - No host-specific path remains. No skill names a worktree root; the runtime resolves it per
    host (FR-13). `.claude/aid/...` is replaced by `.aid/runtime/...`.
  - The generated-doorway provenance comment names no host install root.

  `build-shortcut-skills.py` emits this form, so a regeneration cannot reintroduce the old one.
- **FR-2: `allowed-tools` format.** The rules follow the Agent Skills spec:
  - Every `allowed-tools` value is space-separated.
  - Where the shell is allowed, it is listed as the aliases `Bash Shell Terminal`.
  - No skill frontmatter key is host-specific (no `context:`, no `agent:`).
  - No per-tool tool-name remap applies to skills.
- **FR-3: Tool-neutral canonical runtime.** `canonical/aid/{scripts,templates}` is placed verbatim
  at `.aid/runtime/{scripts,templates}`, and `canonical/aid/rules.md` (the AID rules, FR-12) at
  `.aid/runtime/rules.md`. Any reference in it that must resolve in an installed
  project uses the `.aid/runtime/`, `.agents/skills/` or agent-name forms from FR-1.
- **FR-4: Generator stops rendering skills and runtime.**
  - `render_profile` emits agents only: the per-tool frontmatter translate stays, and runtime
    references point at `.aid/runtime/`.
  - The generator wipes each `profiles/<tool>/` and regenerates it in full on every run. The
    profile emission manifests and the pure-mirror deletion are
    retired, and `canonical/EMISSION-MANIFEST.md` is deleted.
  - The generator self-tests and the VERIFY gate are updated, and `run_generator.py` stays the
    single full-render command.
  - Profile TOMLs keep only per-tool data: `root_dir` for agents, root-file selection,
    `[tool_names]` for agents, `[model_tiers]`, `[capabilities]`, and the skill-mirror list from
    FR-6.
- **FR-5: Release packaging.**
  - `release.sh` builds one shared payload: `canonical/skills/` as-is and `canonical/aid/` as-is
    (`rules.md` included).
  - It also builds one per-tool artifact for each of the five tools, holding agents and any
    per-tool extra. No per-tool artifact contains skills or runtime.
  - Every artifact is listed in `SHA256SUMS`, and the CLI verifies it fail-closed exactly as
    `fetch_tarball` and `verify_bundle_checksum` do today.
  - The v4.0.0 release notes state `v4 requires CLI v4`; no old-CLI guard artifact is shipped.
- **FR-6: CLI placement.** For every tool, `aid add` and `aid update` place:
  - the shared skills at `.agents/skills/aid-*/`;
  - the runtime at `.aid/runtime/`;
  - the `AGENTS.md` managed pointer region (FR-12).

  A profile may declare skill-mirror directories. Claude Code declares `.claude/skills`. For each
  mirror the CLI writes a byte-identical copy of every `aid-*` skill file. A profile may also
  declare a context import. Claude Code declares `CLAUDE.md`, for which the CLI keeps the import
  region of FR-12. The CLI never creates symlinks. It never reads, writes or prunes a
  non-`aid-*` entry in `.agents/skills/` or in a mirror; this repo's `.claude/skills/generate-profile/` and `.claude/skills/release-aid/` are
  examples that must survive. `.aid/runtime/` is CLI-owned, so a file there that the
  manifest does not record is pruned, as `<root>/aid/` is today, except under the
  **runtime-local paths**: user-provisioned paths that the CLI never prunes, never trashes, never
  reports as `extra:` and never compares byte-for-byte with `canonical/aid/`. The list is
  explicit and grows only by amending this sentence: any `node_modules/` directory under
  `.aid/runtime/` (`canonical/aid/scripts/summarize/playwright-provisioning.md` has adopters run `npm ci`
  in the installed summarize scripts directory). Install and uninstall never
  modify user-owned `.aid/` state. That means `.aid/knowledge/`, `.aid/works/`, `.aid/design/`
  and `.aid/connectors/` are untouched, and `.aid/settings.yml` keeps its existing seed-on-install
  and remove-on-last-uninstall behaviour. `.aid/runtime/` is not added to the `.gitignore`
  managed block, matching how `<root>/aid/` is treated today; only its runtime-local paths are.
  The CLI also keeps a managed block in the project-root `.gitattributes` (created when missing,
  same markers and ownership rules as the `.gitignore` block) that forces LF for the AID-owned
  paths, so a `core.autocrlf=true` checkout does not turn every file modified or break the `.sh`
  runtime; the block is reference-counted with the shared entries and removed with the last tool.
- **FR-7: Manifest records shared entries.** The install manifest records three things for every
  shared entry (the files under `.agents/skills/aid-*`, each mirror, `.aid/runtime/`, the
  `AGENTS.md` region, and the `CLAUDE.md` import region):
  - the installed tools that use it;
  - the AID version it was written at;
  - for each file, its sha256.

  The manifest `format_version` is bumped, and bash, PowerShell and the `bin/aid` /
  `bin/aid.ps1` readers all read the new shape.
- **FR-8: Reference-counted uninstall.** `aid remove <tool>` removes the tool's own files and
  takes the tool off every shared entry's user list. A shared entry is removed only when its user
  list becomes empty. A mirror is removed when the tool that declared it is removed, and so is the
  `CLAUDE.md` import region (FR-12). The existing rule that a modified `AGENTS.md` is left in
  place still holds.
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

  Three refusals are added:
  - `aid add` refuses, naming `aid update`, when the manifest already records tools at differing
    versions.
  - `aid add` refuses, naming `aid update`, when the project's layout format is older than the
    CLI's.
  - `aid add` resolves its version from the staged payload's `aid_version` (whatever the source:
    download, `--version` or `--from-bundle`) and, when it differs from the project version,
    exits 2 and writes nothing, with the same mixed-version refusal text and its hint to run
    `aid update`.

  *Justification.* Shared files can hold only one version's bytes. If `add` upgraded them
  silently, it would change the skills another tool's user depends on without being asked.
  Refusing keeps `add` non-disruptive, which is the existing contract, and leaves a single,
  explicit, atomic upgrade path.
- **FR-11: Layout format bump and clean-slate upgrade.** The repo layout stamp
  `AID_SUPPORTED_FORMAT` is bumped in all three carriers (`bin/aid`, `bin/aid.ps1`,
  `lib/AidInstallCore.psm1`), so the existing `_aid_format_gate` directs a v3-layout repo to
  `aid update`. `aid update` on a v3 layout (a format-2 manifest, or the old `<root>/aid/` and
  `<root>/skills/aid-*` paths) moves every old AID-owned path, and the old AID region of the root
  files, into `.aid/.trash/`, then runs a normal fresh v4 install of the same tools (§11 Upgrade
  from v3). The old layouts are:
  - `.claude/aid/` and `.claude/skills/aid-*`;
  - `.codex/aid/` and `.codex/skills/aid-*`, plus the legacy `.agents/aid/`;
  - `.cursor/aid/` and `.cursor/skills/aid-*`;
  - `.github/aid/` and `.github/skills/aid-*`;
  - `.agent/aid/` and `.agent/skills/aid-*` (Antigravity).

  Nothing is deleted: every moved file lands at `.aid/.trash/<original-path>`, and user files are
  never touched. The ownership rule is path-based. An old-layout file is AID-owned if it lies under
  `<root>/skills/aid-*/` at any depth (so every `references/*.md` counts), or under `<root>/aid/`,
  or its basename starts with `aid-`. `_is_aid_owned_file` in `_migrate_retired_layout` tests only
  the basename and ancestors named `aid`, so the upgrade uses a new path-based helper
  (`_is_aid_owned_path`, with a PowerShell twin) instead. There is no resume key, no journal and
  no step ordering: an interrupted run is fixed by re-running `aid update`, and a rollback is a
  restore from `.aid/.trash/`. A v3 CLI cannot drive a v4 layout (release notes: `v4 requires CLI
  v4`). A newer layout is refused by one check: a manifest `format_version` above 3 exits with
  `Run: aid update self`; no `layout_format` field is carried.

  `.agents/` stops being a retired root. `detect_tool` and `Detect-Tool` stop treating it as a
  Codex marker. The manifest-seam retired-roots list and `_migrate_retired_layout` are updated so
  they never sweep or reject `.agents/skills/`.
- **FR-12: One root context file, imported by Claude Code.** Every tool, Claude Code included,
  gets the AID instructions through the `AGENTS.md` managed region, a pointer to
  `.aid/runtime/rules.md` (A-6). That region is a single, reference-counted shared entry under FR-7
  and FR-8, and its lines are fixed and known (§11 *Root context file*).

  While Claude Code is installed, the CLI always keeps a small AID managed region in the
  project-root `CLAUDE.md` as well. The region sits between `AID:BEGIN`/`AID:END` markers, and its
  only content is the import line `@AGENTS.md`. §8 A-3 explains why it is always written. On
  every `aid add` and `aid update`, for each of the two files, the CLI repairs the region by
  content:
  - If the file does not exist, it is created holding only the region.
  - If the file holds exactly the well-formed region, it is unchanged.
  - If the file holds no AID region line, the region is appended at its end and every existing
    byte is kept.
  - Otherwise (a malformed, duplicated or partial region), the CLI copies the whole file to
    `.aid/.trash/<file>`, removes every exact AID region line anywhere in the file, and writes one
    well-formed region. Every other byte is kept.

  Skills (for example `/aid-discover`) never write inside a region.

  The region is hash-tracked like the other managed regions and is reference-counted with the
  Claude Code install. When Claude Code is uninstalled, the region is removed, and the file is
  deleted only if nothing but the region remained. User content outside the markers is never
  touched, and while Claude Code is not installed the CLI never reads or writes `CLAUDE.md`.
- **FR-13: Host-resolved work-level worktree root.** No skill names a worktree root. The runtime
  resolves it from a per-host value the CLI records at install: `.claude/worktrees/` while Claude
  Code is installed (its worktree tool only switches between worktrees under that folder, §8 A-5),
  otherwise the tool-neutral `.aid/.worktrees/`, beside the existing per-task worktrees. The
  neutral root is covered by the `.gitignore` managed block. `worktree-lifecycle.sh locate` finds
  existing worktrees under either root, since lookup is branch-keyed.
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
  - the five `profiles/*/README.md`, the `site/` docs, and the content-isolation checks in
    `canonical/agents/aid-reviewer/AGENT.md`, which must accept the new placement;
  - the KB docs that state the layout, including the content-isolation invariant in
    `.aid/knowledge/architecture.md` § Invariants, `G-10`, `G-11` and `G-13` in
    `.aid/knowledge/authoring-conventions.md`, and `quality-gates.md`, `artifact-schemas.md`,
    `coding-standards.md`, `decisions.md`, `tech-debt.md`, `technology-stack.md` and `STATE.md`
    under `.aid/knowledge/`.

  Shipped history in `.aid/knowledge/release-tracking.md` is left as history. A
  `release-tracking.md` / `backlog.md` entry for this change follows the project's normal
  release-tracking flow.

## 6. Non-Functional Requirements

- **Byte-identity.** Byte-identity is the correctness bar. Any byte difference between an
  installed skill copy and `canonical/skills/` is a defect. No transform, line-ending conversion
  or encoding change may be applied between the source, the release payload and the install.
- **Windows-safe.** No symlinks and no hard links. Every placement is a plain file copy, and the
  installed result is the same on Windows, macOS and Linux.
- **Safety of user content.** No install, update, upgrade, repair or uninstall path deletes a
  file without an AID ownership marker. Every AID-owned file that is replaced or retired while it
  is drifted (its bytes differ from its manifest-recorded sha256, or no sha256 is recorded for it
  and its bytes differ from the bytes AID is writing) is preserved under `.aid/.trash/`. A root
  context file without markers keeps every byte of user content (Layers & Components, *Root context file*).
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
mode), Cursor and Antigravity v2.22.0, and, in further runs on 2026-10-10, Codex and Copilot
CLI. The Claude Code docs (skills, settings reference, memory, changelog) were checked on
2026-10-10.

- **Who reads `.agents/skills`.** Cursor, Antigravity and Codex read it. Copilot CLI discovers
  skills from it. Claude Code does not, and its docs offer no setting to add a skills path. That
  is why the `.claude/skills` mirror exists.
- **Duplicate copies.** A same-named skill in both `.claude/skills` and `.agents/skills` is listed
  once by Cursor, Antigravity, Codex and Copilot CLI. Cursor used the `.agents` description with
  the `.claude` body, Antigravity used the `.agents` copy, and Copilot CLI listed the `.agents`
  description. Copies must therefore be byte-identical.
- **Runtime path.** A fixed `.aid/runtime/probe.txt` path resolved from the project root in all
  four probed tools, and skills that run the shell worked in Codex.
- **`allowed-tools` behaviour.**
  - `allowed-tools: Bash` was pre-approved in Claude Code default mode.
  - A generic `Shell` caused a permission prompt but did not break the skill.
  - Antigravity prompted for both, because it ignores `allowed-tools`.
  - Cursor was inconclusive.
- **Symlinks were rejected.** Windows needs Developer Mode or admin rights and git
  `core.symlinks`; otherwise symlinks check out silently as text files.

**Assumptions. Each is either settled or carries a verification criterion and a fallback.**

- **A-1: Codex reads `.agents/skills`.** Verified by the 2026-10-10 maintainer probe: Codex
  behaves like Cursor and Antigravity. No Codex skill mirror is declared, and the former fallback
  is moot.
- **A-2: Copilot CLI reads `.agents/skills`.** Discovery is verified by the 2026-10-10 probe:
  Copilot CLI listed the probe's duplicate skill once, with the `.agents` copy's description. No
  Copilot skill mirror is needed. Running a skill could not be probed, because every model call
  failed with an account-level authorization error unrelated to AID; the maintainer accepts
  execution as behaving like the other `.agents/skills` hosts (Cursor, Antigravity, Codex).
  - *Verify:* none required; accepted by the maintainer on 2026-10-10.
  - *Fallback:* if a later report shows a discovered skill cannot run from `.agents/skills`, a
    Copilot mirror under FR-6.
- **A-3: Claude Code loads the AID instructions in `AGENTS.md`.** Settled by documentation and by
  the always-import design of FR-12, so no probe is needed. The Claude Code memory docs
  (https://code.claude.com/docs/en/memory, § AGENTS.md, read 2026-10-10) state the following.
  - Claude Code v2.1.277 and later reads `AGENTS.md`. The **Project instructions** setting picks
    which instruction files load, and it has four values:
    - `claude-md-or-agents-md`, the default: the `CLAUDE.md` files, or the `AGENTS.md` files
      only when there is no `CLAUDE.md` or `CLAUDE.local.md` in the working directory or above it;
    - `claude-md-and-agents-md`: both, and "Claude Code skips an `AGENTS.md` it has already
      loaded, so one that your `CLAUDE.md` imports or symlinks to isn't read twice";
    - `claude-md`: the `CLAUDE.md` files only;
    - `managed-only`: the organization's managed `CLAUDE.md` and auto memory; every `AGENTS.md`
      is left out.
  - The setting is stored under
    `pluginConfigs["cc-plugin-agents-md@builtin"].options.instructionFiles`. Claude Code reads it
    only from `~/.claude/settings.json`, a `--settings` file or managed settings, and ignores it
    in project and local settings files. The CLI therefore can neither set it per project nor
    reliably know its value.
  - For a `CLAUDE.md` that imports `AGENTS.md`, Claude reads "Your `CLAUDE.md`, with `AGENTS.md`
    included through the import". The docs recommend that import for sessions where `AGENTS.md`
    support is unavailable: the built-in plugin disabled, some first sessions after an upgrade
    from v2.1.276 or earlier, and, before v2.1.281, some sessions such as those on Amazon Bedrock
    or with telemetry disabled.

  Therefore the always-import design loads the AID instructions under `claude-md-or-agents-md`,
  `claude-md-and-agents-md` and `claude-md`, and on older Claude Code releases. Only
  `managed-only` leaves them out, which is intended: it is an organization's choice to exclude
  project instructions. An `AGENTS.md`-only design would fail under the default whenever any
  `CLAUDE.md` sits in the working directory or above it.
  - *Verify:* none required; settled by the documentation above.
- **A-4: `allowed-tools: ... Bash Shell Terminal ...` is accepted by every host.** Unknown names
  must be ignored without error, and Claude Code must still pre-approve `Bash`. Copilot CLI's
  former remap target was lowercase `shell`.
  - *Verify:* AC-20.
  - *Fallback:* the SPEC revisits the alias list. Per-tool remapping does not return.
- **A-5: Claude Code's `EnterWorktree` accepts a worktree path outside `.claude/worktrees/`.**
  Does not hold. The tool's own contract accepts such a path only when entered from the launch
  directory; a switch from one worktree into another needs the target under `.claude/worktrees/`.
  - *Fallback (adopted):* the SPEC keeps host-native entry working without reintroducing a host
    path into a skill. The root choice lives only in the runtime script, from a per-host value
    the CLI records (§11 Feature 001). No probe is needed.
- **A-6: Every tool follows the pointer in `AGENTS.md`.** The region holds `@.aid/runtime/rules.md`
  and a read-first line, not the rules. Claude Code follows it through the documented `@` import
  inside `AGENTS.md` (loaded directly or through the `CLAUDE.md` import of A-3); the other four
  tools follow the read-first line.
  - *Verify:* AC-20, the maintainer's pointer probe.
  - *Fallback:* when an installed tool is listed as not following pointers (its profile TOML sets
    `rules_inline = true`, emitted as `rules_inline=true` in `aid-tool.conf`), the CLI writes the
    full `rules.md` bytes between the markers of the `AGENTS.md` region instead of the two pointer
    lines; repair then replaces the span between the BEGIN and END lines and removes no other
    line.

**Dependencies.**

- The existing install core (`install_tool`, `uninstall_tool`, `_migrate_retired_layout`,
  `_copy_root_agent_file`, `_prune_tool_dirs`) and its PowerShell twins.
- The format gate `_aid_format_gate` and `_aid_migrate_repo` in `bin/aid`.
- `release.sh` and the release workflow.
- The KB docs `architecture.md`, `project-structure.md`, `module-map.md`, `integration-map.md`,
  `infrastructure.md`, `test-landscape.md`, `authoring-conventions.md`, `quality-gates.md`,
  `artifact-schemas.md`, `coding-standards.md`, `decisions.md`, `tech-debt.md`,
  `technology-stack.md` and `STATE.md`.

## 9. Acceptance Criteria

- **AC-1:** Skills and runtime are no longer rendered.
  - After `python .claude/skills/generate-profile/scripts/run_generator.py`, which prints
    `VERIFY (deterministic): PASS`, a stray file planted beforehand in the generated part of a
    `profiles/<tool>/` tree (everything except its hand-kept `README.md`) is gone, and the tree
    holds only the agents and `aid-tool.conf`, checked directly on the regenerated tree.
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
    source byte-for-byte, ignoring the FR-6 runtime-local paths, and `.aid/runtime/rules.md`
    equals `canonical/aid/rules.md`.
  - No `aid/` directory exists under `.claude`, `.codex`, `.cursor`, `.github` or `.agent`.
  - The fixture's pre-seeded `.aid/knowledge/x.md`, `.aid/works/w/STATE.yml` and `.aid/design/d.md`
    keep identical sha256 before and after `aid add`, `aid update` and `aid remove`.
  - A stray file placed in `.aid/runtime/` is pruned by the next `aid update`.
  - A fixture file `.aid/runtime/scripts/summarize/node_modules/x.js` survives `aid update`,
    nothing from it lands in `.aid/.trash/`, and `aid status` prints no `extra:` line for it.
  - After `aid add cursor` in a fixture, `.gitattributes` contains the managed block with the
    three `text eol=lf` lines of the `.gitattributes` managed block, and a pre-existing user line
    in `.gitattributes` is unchanged.
- **AC-8:** The work-level worktree root is resolved per host.
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
  - After the last tool is removed, `.gitattributes` holds no AID block (the file is deleted when
    only the block remained), and a pre-existing user line in it is unchanged.
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
  - `aid add cursor --from-bundle <dir staged at a different version>` into a project at another
    version exits non-zero, and the whole-tree sha256 snapshot is unchanged.
  - With a manifest whose tools record differing versions, `aid add` exits non-zero and its
    message names `aid update`.
  - `aid update --from-bundle <staging>` leaves every tool `version` and every shared-entry version
    in the manifest equal to `aid_version`.
- **AC-12:** The format bump guards the layout.
  - `AID_SUPPORTED_FORMAT` in `bin/aid`, `AidSupportedFormat` in `bin/aid.ps1` and
    `$script:_AidSupportedFormat` in `lib/AidInstallCore.psm1` hold the same value, one above the
    pre-change value of `4`.
  - The new CLI's `aid add` into a v3-layout fixture exits non-zero, writes nothing, and names
    `aid update`.
  - A manifest whose `format_version` is above 3 makes the CLI exit non-zero with
    `Run: aid update self` and write nothing.
- **AC-13:** The clean-slate upgrade works from every v3 layout. A fixture is built for each of
  the five tools in its v3 layout, including Antigravity `.agent/skills` and the legacy Codex
  `.agents/aid/`. Each fixture contains:
  - one user-modified AID file in the old `skills/aid-*` and in the old `aid/` subtree;
  - one non-AID user file in each old directory.

  After `aid update --from-bundle <staging>`:
  - The AC-3 and AC-7 checks pass.
  - No `aid-*` entry remains under `.codex/skills`, `.cursor/skills`, `.github/skills` or
    `.agent/skills`, and no `<root>/aid/` remains.
  - Every old AID-owned file, modified or not, exists byte-for-byte under
    `.aid/.trash/<original-path>`.
  - Each non-AID file keeps identical sha256.
  - `.aid/settings.yml` `format_version` equals the new value.

  A second `aid update` prints `up to date` for every tool and leaves `.aid/.trash/` unchanged.
  An `aid update` killed after the trash step and before the manifest write, then re-run, ends in
  the same state (the AC-3 and AC-7 checks pass) and loses no non-AID file.
- **AC-14:** `CLAUDE.md` holds the `@AGENTS.md` import region exactly while Claude Code is
  installed, and `AGENTS.md` holds the pointer region. The *import region* is the three
  LF-terminated lines `<!-- AID:BEGIN -->`, `@AGENTS.md` and `<!-- AID:END -->`. The *pointer
  region* is the five LF-terminated lines given in §11 *Root context file*.
  - (a) **Created when missing.** `aid add claude-code` into a fixture with no `CLAUDE.md`
    creates one whose bytes equal the import region, and the fixture's `AGENTS.md` equals the
    pointer region. `aid add cursor` into a second such fixture creates no `CLAUDE.md`.
  - (b) **Added to a user file.** In a fixture whose user `CLAUDE.md` has no markers and ends in
    LF, after `aid add claude-code` the pre-add bytes are a byte-exact prefix of the file, and the
    only bytes after them are the import region. A following `aid update` leaves the file's
    sha256 unchanged.
  - (c) **Upgraded from the v3 full region.** In a v3 claude-code fixture whose user-edited
    `CLAUDE.md` holds user content above and below the full AID region, `aid update` leaves the
    file equal, byte-for-byte, to its pre-update content with the marked region (marker lines
    included) replaced by the import region. The pre-update file exists byte-for-byte at
    `.aid/.trash/CLAUDE.md`. A v3 fixture whose `CLAUDE.md` has no markers passes the (b) prefix
    check. A v3 `AGENTS.md` holding the full region gets the pointer region the same way.
  - (d) **Removed on Claude Code uninstall.** In a fresh fixture of the (a) kind and one of the
    (b) kind, run `aid add claude-code,cursor` and then `aid remove claude-code`. Afterwards
    `CLAUDE.md` is absent in the (a)-kind fixture and equals its pre-add bytes in the (b)-kind
    fixture. In both,
    `AGENTS.md` still contains exactly one `<!-- AID:BEGIN -->` line, the manifest's
    `shared.agents_md.users` is `["cursor"]`, and the manifest has no `shared.claude_md` entry.
  - (e) **User `AGENTS.md` without markers.** In a fixture whose user `AGENTS.md` has no markers
    and holds a `## Workflow` section, after `aid add claude-code` that section is present
    byte-for-byte, and the pre-add bytes of the file are a byte-exact prefix of it, followed by
    the pointer region.
  - (f) **Malformed, duplicated or partial region (repair by content).** Three fixtures: a user
    `CLAUDE.md` holding `<!-- AID:BEGIN -->` with no `<!-- AID:END -->`, followed by user text; a
    user `AGENTS.md` holding two copies of the pointer region around user text; a user `CLAUDE.md`
    holding a lone `@AGENTS.md` line. After `aid add claude-code`, each file holds exactly one
    well-formed region, every other line is present unchanged and in its original order, and a
    full copy of the pre-add file exists at `.aid/.trash/<file>`. A following `aid update` leaves
    each file's sha256 unchanged and adds no trash entry.
  - In every one of these fixtures, while Claude Code is installed, `CLAUDE.md` contains exactly
    one `@AGENTS.md` line and `AGENTS.md` contains exactly one `<!-- AID:BEGIN -->` line.
- **AC-15:** Tool detection is fixed. `detect_tool` on a fixture holding only `.agents/` exits `2`
  (undetectable) and does not print `codex`. On a fixture holding `.codex/` it prints `codex`.
  `Detect-Tool` behaves the same way.
- **AC-16:** Bash and PowerShell stay in parity. `tests/canonical/test-aid-cli-parity.sh`,
  `tests/canonical/test-install-parity.sh` and `tests/canonical/test-ps51-compat.sh` pass. The
  parity suite names every function added or changed for FR-6 to FR-12, and its scenarios cover
  flows 3 to 8. On Windows,
  `tests/windows/Test-AidInstaller.ps1` passes with the AC-9, AC-10 and AC-13 scenarios added.
- **AC-17:** The packages are updated. `tests/canonical/test-npm-installer.sh` and
  `tests/canonical/test-pypi-installer.sh` pass, and the vendored `lib/aid-install-core.sh` and
  `lib/AidInstallCore.psm1` match `lib/` by sha256.
- **AC-18:** The dogfood trees are resynced. In this repo:
  - every `canonical/skills/<rel>` equals `.agents/skills/<rel>` and `.claude/skills/<rel>`;
  - `.aid/runtime/{scripts,templates}` equals `canonical/aid/{scripts,templates}`, ignoring the
    FR-6 runtime-local paths; `.aid/runtime/rules.md` equals `canonical/aid/rules.md`, and `.aid/runtime/host.conf` exists and is the only other file;
  - `.claude/aid/`, `.cursor/aid/` and `.cursor/skills/aid-*` are absent;
  - the repo-root `CLAUDE.md` keeps its `## Project` section byte for byte, and its AID region
    holds only `@AGENTS.md`;
  - `.claude/skills/generate-profile/SKILL.md` and `.claude/skills/release-aid/SKILL.md` are
    present;
  - `.aid/.aid-manifest.json` records the shared entries.

  The re-keyed `tests/canonical/test-dogfood-byte-identity.sh` passes.
- **AC-19:** Docs and KB no longer state the old layout.
  - `git grep -nE '\.(claude|codex|cursor|agent)/aid/|\.github/aid/' -- CLAUDE.md AGENTS.md README.md docs .github/workflows .aid/knowledge 'profiles/*/README.md' site ':!.aid/knowledge/release-tracking.md' ':!.aid/knowledge/kb.html'`
    prints no lines.
  - A reviewer confirms that `.aid/knowledge/architecture.md` § Invariants (content isolation) and
    criteria `G-10` and `G-11` in `.aid/knowledge/authoring-conventions.md` state the
    `.aid/runtime/` and `.agents/skills/aid-*` placement rules, and that the content-isolation
    checks in `canonical/agents/aid-reviewer/AGENT.md` accept that placement.
- **AC-20:** The remaining host assumptions are verified. A maintainer repeats the §8 manual probe
  method for two checks and records a pass or fail for each as a `lifecycle_history` entry in this
  work's `STATE.yml`:
  - the `Bash Shell Terminal` alias list (A-4);
  - the pointer probe (A-6): in each of the five tools, a fixture whose `AGENTS.md` holds the
    pointer region (and, for Claude Code, a `CLAUDE.md` holding the import region), with a unique
    token in `.aid/runtime/rules.md`, makes the tool report the token when asked what its AID
    rules say.

  No other assumption needs a probe: A-1 is verified, A-2 is verified for discovery and accepted
  by the maintainer for execution, A-3 is settled by the Claude Code documentation and the
  always-import design of FR-12, and A-5 is settled by its adopted fallback (§8). If A-4 or the A-6
  probe for a tool fails, its §8 fallback is implemented (for A-6, `rules_inline` for that tool)
  and covered by an added criterion before the work is marked Done.
- **AC-21:** The existing suites stay green.
  - `HOME=$(mktemp -d) bash tests/run-all.sh` exits `0`, including the coverage-parity gate.
  - `python .claude/skills/generate-profile/scripts/render.py --self-test --canonical-root .`
    exits `0`.

## 10. Priority

**Must.** The internal order is the dependency order:

1. FR-1 to FR-4: neutral canonical sources and the generator change.
2. FR-5: release payload.
3. FR-6 to FR-12 and FR-14: CLI placement, manifest, uninstall, drift, version policy, upgrade,
   root context file and parity.
4. FR-13: worktree root.
5. FR-15 to FR-17: packages, dogfood and docs/KB.

## 11. Features

### Feature 001: Shared Cross-Tool Skills Folder

- **Criteria:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12,
  AC-13, AC-14, AC-15, AC-16, AC-17, AC-18, AC-19, AC-20, AC-21

#### Technical Specification

The specification is grounded in `.aid/knowledge/architecture.md` (§ Build & Distribute
Architecture, § Data Flow, § Invariants), `.aid/knowledge/test-landscape.md` and the code it
names. Three gaps that the requirements left open are decided here.

- **Gap 1, A-3 (how Claude Code gets the AID instructions).** *Decision:* `AGENTS.md` holds the
  AID managed pointer region for every tool (the rules live in `.aid/runtime/rules.md`). While Claude Code is installed, the CLI also always keeps a
  CLI-owned region in the project-root `CLAUDE.md` whose only content is `@AGENTS.md`, and it
  creates the file when it is missing. This import region is the primary design, not a fallback.
  *Rationale:* the Claude Code memory docs (https://code.claude.com/docs/en/memory, read
  2026-10-10; quoted in §8 A-3) settle the question without a probe.
  - Under the default **Project instructions** value, `claude-md-or-agents-md`, any `CLAUDE.md`
    or `CLAUDE.local.md` in the working directory or above it hides `AGENTS.md`. A user's own
    `CLAUDE.md` is enough, so shipping `AGENTS.md` alone is not safe.
  - The value is read only from `~/.claude/settings.json`, a `--settings` file or managed
    settings, and is ignored in project and local settings files. The CLI can neither set it per
    project nor reliably know it.
  - A `CLAUDE.md` that imports `AGENTS.md` loads it under `claude-md-or-agents-md`,
    `claude-md-and-agents-md` and `claude-md`, and in the sessions where `AGENTS.md` support is
    unavailable, such as Claude Code releases before v2.1.277. Under `claude-md-and-agents-md` the
    docs state that Claude Code "skips an `AGENTS.md` it has already loaded", so the import never
    loads the instructions twice.
  - Only `managed-only` leaves the instructions out. That is an organization's choice to exclude
    project instructions, so the outcome is intended.

  A symlink was rejected (§8). The rules are under [Layers & Components](#layers--components),
  *Root context file*.
- **Gap 2, A-5 (neutral worktree root vs `EnterWorktree`).** *Decision:* no skill names a host
  worktree root. `worktree-lifecycle.sh` resolves the work-level root at run time from a per-host
  value that the CLI records in `.aid/runtime/host.conf`. The default is `.aid/.worktrees/`. It is
  `.claude/worktrees/` while Claude Code is installed. Lookup stays branch-keyed, so a worktree
  under either root is found. *Rationale:* `EnterWorktree` needs targets under `.claude/worktrees/`
  for a worktree-to-worktree switch, so a fixed neutral root would break Claude Code. A per-host
  value written by the CLI keeps `canonical/` free of host paths (AC-4 greps all of `canonical/`
  for `.claude/worktrees`). This is the §8 A-5 fallback, and it is how FR-13 is realized.
- **Gap 3, an old CLI against a v4 release (FR-5).** *Decision:* none. AID v4.0.0 is a breaking
  major release, the artifacts keep the plain names `aid-shared-v<V>.tar.gz` and
  `aid-<tool>-v<V>.tar.gz` with no wrapper directory, and the release notes state `v4 requires CLI
  v4`. *Rationale:* the maintainer accepts that a v3 CLI cannot drive a v4 layout. Guarding it
  would cost a wrapper artifact format, a frozen v3 core fixture and an orphan-recovery path for a
  case the release notes already rule out. A v4 CLI refuses a manifest `format_version` it does
  not know (Data Model, *Format detection*).

##### Data Model

There is no database. The "schema" is the release artifact set, two small descriptor files, the
install manifest, one runtime host file, and the format stamps.

**Release artifacts** (in `.aid/.temp/release-<V>/`, all listed in `SHA256SUMS`):

| Artifact | Content (archive root) |
|---|---|
| `aid-shared-v<V>.tar.gz` | `aid-payload.conf`; `skills/**` (= `canonical/skills/**` as-is); `runtime/**` (= `canonical/aid/**` as-is, `rules.md` included) |
| `aid-<tool>-v<V>.tar.gz` (one per tool, five in all) | `aid-tool.conf`; `<root>/agents/**` (the rendered agents only, for example `.claude/agents/aid-*.md` or `.codex/agents/aid-*.toml`) |
| `aid-cli-v<V>.tar.gz`, `aid-install-core.sh`, `AidInstallCore.psm1` | unchanged (the bootstrap installers consume them) |

- **Archive layout.** Members are written without a leading `./`, relative to the archive root.
- **Byte-identity.** No transform is applied. AC-2 compares `skills/` with `canonical/skills/`
  and `runtime/` with `canonical/aid/`, at the same relative path inside each pair, with no
  extra or missing files. `aid-payload.conf` sits outside both trees.
- **Source file set.** The payload file set is `find canonical/skills canonical/aid -type f`,
  excluding `node_modules/`, `.git/` and dot-files. These are the exclusions that `copy_tree` in
  `render.py` applies today. Using `find` rather than `git ls-files` lets an uncommitted
  `--stage-only` build include new files.

**Descriptor format.** `aid-payload.conf`, `aid-tool.conf` and `host.conf` share one format, so
bash and PowerShell parse them the same way:

- ASCII and LF only;
- one `key=value` per line, split at the first `=`;
- `#` comment lines and blank lines are ignored;
- a repeated key is a list;
- unknown keys are ignored.

The files are never sourced or evaluated.

| File | Keys | Written by |
|---|---|---|
| `aid-payload.conf` | `aid_version=<V>` | `release.sh`, from `VERSION` |
| `aid-tool.conf` | `tool=<id>`; `skill_mirror=<dir>` (0..n); `worktree_root=<dir>` (0..1); `context_import=<file>` (0..1); `rules_inline=true` (0..1) | the generator, from the profile TOML, at `profiles/<tool>/aid-tool.conf` |
| `.aid/runtime/host.conf` | `worktree_root=<dir>` | the CLI, at every add, update and remove (see below) |

**Validation.** The CLI validates every descriptor value before any write. A violation exits 1
with a message that names the file and key.

- `skill_mirror` must match `^\.[a-z]+/skills$`, must not be `.agents/skills`, and must sit under
  the tool's own root.
- `worktree_root` must be `.aid/.worktrees` or `<tool-root>/worktrees`, a relative path with no
  `..` segment.
- `context_import` must be `CLAUDE.md`, the only context import AID supports.
- `rules_inline` must be `true` when present.
- `aid_version` must equal the version in the artifact name.

**Per-profile placement data.** This is declared in `profiles/<tool>.toml` and emitted into
`aid-tool.conf`:

| Profile | Agents root (`root_dir`) | `skill_mirrors` | `worktree_root` | `context_import` |
|---|---|---|---|---|
| claude-code | `.claude/agents` | `[".claude/skills"]` | `.claude/worktrees` | `CLAUDE.md` (Gap 1) |
| codex | `.codex/agents` | none (A-1 verified) | default (`.aid/.worktrees`) | none |
| cursor | `.cursor/agents` | none (probe-verified) | default | none |
| copilot-cli | `.github/agents` | none (A-2 discovery verified, execution accepted by the maintainer; the fallback `.github/skills` is used only if a later report shows execution failing) | default | none |
| antigravity | `.agent/agents` | none (probe-verified) | default | none |

Four TOML keys, `skill_mirrors` (a list), `worktree_root` (a string), `context_import` (a string)
and `rules_inline` (a boolean, default false; set only for a tool listed as not following
pointers, A-6), are new.
`aid_profile.py` validates them. `root_file` stays and is `"AGENTS.md"` in all five TOMLs. VERIFY
fails if any profile names another root file.

**The `host.conf` value.** The CLI computes `worktree_root` from the installed tool set. It is the
`worktree_root` of the first installed tool, in `AID_TOOLS` order, that declares one; otherwise it
is `.aid/.worktrees`. The file is rewritten whenever the tool set changes, so it returns to the
default when `claude-code` is removed. It is a runtime file recorded with its sha256 like any
other. It lies outside `runtime/{scripts,templates}`, so AC-7's byte check does not cover it.

**Install manifest, `.aid/.aid-manifest.json`, `format_version` 2 → 3.**

```json
{
  "format_version": 3,
  "aid_version": "<V>",
  "installed_at": "<ts>",
  "host": { "worktree_root": ".claude/worktrees" },
  "shared": {
    "skills":    { "root": ".agents/skills", "version": "<V>", "users": ["claude-code", "cursor"],
                   "files": [ { "path": "aid-ask/SKILL.md", "sha256": "<hex>" } ] },
    "runtime":   { "root": ".aid/runtime", "version": "<V>", "users": ["claude-code", "cursor"],
                   "files": [ { "path": "scripts/kb/build-kb-index.sh", "sha256": "<hex>" },
                              { "path": "host.conf", "sha256": "<hex>" } ] },
    "agents_md": { "path": "AGENTS.md", "version": "<V>", "users": ["claude-code", "cursor"],
                   "region_sha256": "<hex>", "file_sha256": "<hex>" },
    "claude_md": { "path": "CLAUDE.md", "version": "<V>", "users": ["claude-code"],
                   "region_sha256": "<hex>" },
    "mirrors":   { ".claude/skills": { "version": "<V>", "users": ["claude-code"] } }
  },
  "tools": {
    "claude-code": { "version": "<V>", "installed_at": "<ts>", "mirrors": [".claude/skills"],
                     "files": [ { "path": ".claude/agents/aid-architect.md", "sha256": "<hex>" } ],
                     "paths": [".claude/agents/aid-architect.md"] }
  }
}
```

- **Users.** `users` lists the installed tools that use the entry (FR-7). `shared.skills`,
  `shared.runtime` and `shared.agents_md` list every installed tool. A mirror lists the tools
  whose `aid-tool.conf` declares it, and `shared.claude_md` lists the tools whose `aid-tool.conf`
  declares `context_import`. An entry whose list would be empty is absent.
- **Mirrors.** A mirror carries no file list of its own. Its expected content is exactly
  `shared.skills.files`, read relative to the mirror directory. Checking a mirror against those
  recorded hashes is the same comparison as checking it against `.agents/skills`, without the
  blind spot of both copies drifting identically (FR-9).
- **`agents_md`.**
  - `region_sha256` is the sha256 of the marked region, marker lines included, as AID wrote it.
    It is the drift baseline.
  - `file_sha256` is the sha256 of the whole file after the write. It drives the existing
    "modified root file is left in place" rule on the last uninstall (FR-8).
- **`claude_md`.** `region_sha256` is the sha256 of the import region, marker lines included, as
  AID wrote it. It is the drift baseline. There is no `file_sha256`: on the last uninstall the
  region is removed whatever the rest of the file holds, and the file is deleted only when
  nothing else remains (FR-12).
- **`tools.<t>.paths`.** This is a plain copy of `files[].path` (the tool's own files only),
  written for format-2 readers. Format-3 code never reads it. It makes an old CLI's `aid remove`
  delete the right agents and nothing shared.
- **Serialization.** The python3 writer, the pure-bash fallback writer and the PowerShell writer
  emit byte-identical JSON:
  - 2-space indent, LF line endings, and a trailing newline;
  - keys in exactly the order shown above;
  - `files` sorted by `path` in byte order;
  - `users` in `AID_TOOLS` order.

  The parity tests rely on this (they mask `installed_at` and then diff the bytes).
- **Format detection.** A reader treats `format_version` 2 as the v3 layout, which triggers the
  clean-slate upgrade in `aid update` and refusal in `aid add`. It treats a value above 3 as
  "newer than this CLI", and refuses with `Run: aid update self`. No `layout_format` field is
  carried: that one check covers newer layouts.

**Format stamp.** `AID_SUPPORTED_FORMAT` goes from 4 to 5 in its three carriers: `bin/aid`,
`AidSupportedFormat` in `bin/aid.ps1`, and `$script:_AidSupportedFormat` in
`lib/AidInstallCore.psm1`. The comment block above `readonly AID_SUPPORTED_FORMAT` gains this
line: `format 5 (was 4): shared skills under .agents/skills (+ CLI-owned mirrors), runtime under
.aid/runtime/, one AGENTS.md pointer region for every tool, a CLAUDE.md @AGENTS.md import region
while claude-code is installed; manifest format_version 3`. A test keeps the three values in
lockstep. The settings stamp is capped as follows: `_aid_migrate_repo` (and its PowerShell twin)
writes `format_version: 5` only when the manifest is absent or records `format_version` 3.
Otherwise it writes `4`. The reason is that `aid update self` and `aid projects add` run
`_aid_migrate_repo` without installing anything. Without the cap they would stamp a v3-layout repo
as format 5, and the format gate would stop telling the user to run `aid update`.

**`.gitignore` managed block** (`_aid_gitignore_block`): `.aid/.worktrees/` is added to the
existing entries. When `host.worktree_root` is not under `.aid/`, the block also lists that root
(`.claude/worktrees/`). The block also lists each FR-6 runtime-local path
(`.aid/runtime/**/node_modules/`). The block stays a pure function of the manifest, so it is still
idempotent.

**`.gitattributes` managed block** (`_aid_gitattributes_block`): the same marker lines as the
`.gitignore` block, wrapping three lines:

```
.agents/skills/aid-*/** text eol=lf
.claude/skills/aid-*/** text eol=lf
.aid/runtime/** text eol=lf
```

`update_gitattributes` creates the file when missing; otherwise it replaces only the block and
keeps every byte outside it, as `update_gitignore` does. The block is a constant, so it is
idempotent. `remove_gitattributes_block` removes the block, marker lines included, keeps every
other byte, and deletes the file when only whitespace remains.

**`.aid/.trash/` collision policy** (used by every trash move in this feature):

- The destination is `.aid/.trash/<original-relative-path>`.
- If that path already holds identical bytes, no new copy is made.
- If it holds different bytes, the existing entry is first renamed to
  `<path>.<UTC yyyyMMddTHHmmssZ>`.

The newest copy therefore always sits at the original path, as AC-10 and AC-13 require, and no
earlier copy is overwritten. Today `_retire_file` uses `mv -f`, which silently replaces an earlier
trash copy. That is replaced by this policy.

##### Feature Flow

**1. Build and release (maintainer).**

1. Edit `canonical/`.
2. Run `run_generator.py`. It regenerates each profile tree in full (agents and `aid-tool.conf`
   only), runs VERIFY (deterministic), and then runs the dogfood resync (flow 7).
3. `release.sh` packages its artifacts:
   - the shared payload, from `canonical/skills` and `canonical/aid` (`rules.md` included), plus
     a generated `aid-payload.conf`;
   - five per-tool artifacts, from `profiles/<tool>/aid-tool.conf` and
     `profiles/<tool>/<root>/agents/`;
   - the unchanged CLI bundle and libs;
   - `SHA256SUMS`, which covers every `aid-*.tar.gz` and both libs.
4. New `release.sh` flag `--stage-only [--out DIR]`. It runs Steps 3 to 6 against the working
   tree as it is. It skips the clean-worktree check, the tag checks, the render and render-drift
   steps, and every network step. It is used by tests and by the dogfood resync. `--dry-run`
   keeps its current preconditions.

**2. Staging (shared by `aid add` and `aid update`; no destination writes).**

- **Online.**
  1. Resolve `<V>` (unchanged).
  2. Fetch `aid-shared-v<V>.tar.gz` and each target tool's `aid-<tool>-v<V>.tar.gz`, plus
     `SHA256SUMS`. The fetch is fail-closed, as in `fetch_tarball` today.
  3. If the shared artifact is missing, exit 3 with this message: `release v<V> has no shared
     payload -- it predates the shared layout and cannot be installed by this CLI; omit --version
     or use an older aid CLI`.
- **`--from-bundle <dir>`.**
  1. The directory must hold exactly one `aid-shared-v*.tar.gz`. If it holds none or several,
     exit 2 and list what was found.
  2. Each tool artifact's version must equal the shared payload's version.
  3. Each artifact is checked with `verify_bundle_checksum` (unchanged: a no-op when the
     directory has no `SHA256SUMS`).
  4. If `--from-bundle <file>` names a release artifact, the file's directory is used as the
     bundle directory. This keeps `install.sh add codex --from-bundle ./aid-codex-v<V>.tar.gz`
     working, as long as the sibling artifacts are present.
- **Extract.** `extract_payload` (new) requires no absolute path and no `..` segment in any member,
  and returns the extraction directory as the staging root.
- **Validate.** The descriptors are validated (see [Data Model](#data-model)). Each per-tool
  artifact must contain nothing outside `aid-tool.conf` and `<that tool's root>/agents/`. This
  check replaces the post-copy manifest-seam gate (`_retired_roots`). It is an allowlist, it runs
  before any write, and so it can never flag `.agents/skills/`.

**3. `aid add <t1>[,<t2>...]`** (1..N new tools; FR-10):

1. Run the writability pre-check (unchanged).
2. **Layout gate** (new `_aid_layout_gate`). A manifest exists and records `format_version` < 3, or
   the settings stamp is < 5. Exit 2, print `This project uses the v3 AID layout. Run: aid update
   (it upgrades every installed tool), then retry aid add.`, and write nothing (AC-12).
3. **Skew gate.** The manifest records a `tools.*.version` or a `shared.*.version` that differs
   from `aid_version`. Exit 2 and name `aid update` (AC-11).
4. **Version selection** (unchanged `FR11` block): use the project version, or the CLI version
   for the first tool. `--version <v>` different from the project version exits 2 and writes
   nothing.
5. **Stage** (flow 2): the shared payload once, plus each named tool. After staging validation
   and before any write, the **staged-version check** (new, in the `add` path) compares the staged
   payload's `aid_version` with the project version. The `FR11` block only pins `--version`;
   `_prepare_tool_staging_aid` takes the version from the bundle file name for `--from-bundle`,
   so the staged `aid_version` is the authoritative source. On a mismatch it exits 2, writes
   nothing, and prints the `FR11` mixed-version refusal text with the hint to run `aid update`
   (AC-11).
6. **Commit**, in a fixed order:
   1. Shared skills go to `.agents/skills/` with `copy_file_guarded`. An absent file is copied,
      an identical file is left alone, and a differing file is overwritten. It is trashed first
      only when drifted: its bytes differ from its manifest-recorded sha256, or no sha256 is
      recorded for it (FR-9).
   2. Each mirror declared by any user is written the same way. A newly added `claude-code`
      creates `.claude/skills/aid-*`.
   3. The runtime goes to `.aid/runtime/`, then `host.conf` is written.
   4. Each new tool's agents go to `<root>/agents/`.
   5. The `AGENTS.md` region is written through `_copy_root_agent_file`, which calls
      `_repair_root_region` with the pointer region (see [Layers & Components](#layers--components),
      *Root context file*). Then, when any user declares `context_import`,
      `_ensure_claude_md_region` writes the `CLAUDE.md` import region the same way.
   6. If any copy failed, abort before the manifest write (the existing work-007 C4 rule).
   7. Write the manifest atomically. Each new tool joins every shared `users` list, and each
      file is recorded with the sha256 of its staged bytes.
   8. Prune (flow 6).
   9. `seed_settings_yml` now reads its template from `.aid/runtime/templates/settings.yml`.
      Then run `update_gitignore`, `update_gitattributes` and `_migrate_term_exclusions`.
7. **Output.** The commit prints one summary block for `shared` and one per tool, in the existing
   counter format. A run that changes nothing prints `up to date (N files)` in every block.
   Because `add` rewrites differing shared files from the verified payload, it also repairs drift
   (FR-9).

**4. `aid update [<tool>...]`.**

1. Run the self-update preamble and the format gate (both unchanged). `repo > 5` is refused.
2. The commit set is every installed tool plus any named tool, all at one version. A named
   tool-subset can no longer advance the shared files ahead of the other tools. When the subset
   is widened, the CLI prints a notice listing the tools it added.
3. Stage everything (flow 2).
4. If the CLI finds a v3 layout (a format-2 manifest, or the old `<root>/aid/` and
   `<root>/skills/aid-*` paths), run steps 2 and 3 of [Upgrade from v3](#upgrade-from-v3-clean-slate)
   (`retire_v3_layout`, then the fresh install). Otherwise run the flow 3 commit steps for all tools.
5. Run `_aid_migrate_repo`, which now stamps 5.

`--dry-run` stops after staging. In addition to today's copy list, it prints the shared copies,
the trash moves and the prune list.

**5. `aid remove [<tool>...]`** (FR-8). This runs `uninstall_tool`, which dispatches on
`format_version`.

- **Format 2.** The existing legacy path, unchanged.
- **Format 3.**
  1. Remove the tool's `files`. A file whose sha256 differs from the recorded one is moved to the
     trash, not deleted.
  2. Remove the tool from every `users` list.
  3. A shared entry whose list becomes empty has its files removed under the same sha rule, and
     then its emptied directories are pruned. A mirror goes when no remaining user declares it.
  4. If `agents_md` loses its last user, apply the existing rule: delete the file when it still
     has `file_sha256`; otherwise print `Left in place (modified or not AID-owned): AGENTS.md`.
  5. If `claude_md` loses its last user, run `_remove_claude_md_region`. Removing `claude-code`
     while another tool remains therefore takes the region out of `CLAUDE.md` and leaves the
     `AGENTS.md` region in place for the other tools.
  6. Rewrite `host.conf` if the runtime remains.
  7. Delete the manifest and `.aid/settings.yml` when no tools remain (existing behaviour), and
     run `remove_gitattributes_block` (the `.gitignore` block stays, as today).

  Non-`aid-*` entries in `.agents/skills/` or in a mirror are never read or touched (AC-9).

**6. Prune (after every add and update commit).**

- **Candidates:**
  - `aid-*` children of `.agents/skills/` and of each mirror that are not in `shared.skills`;
  - any file under `.aid/runtime/` that is not in `shared.runtime` and not under an FR-6
    runtime-local path (those are never candidates);
  - `aid-*` children of each tool's `<root>/agents/` that are not in that tool's `files`.
- **What happens to a candidate:**
  - A candidate whose bytes match a sha256 recorded in the previous manifest is deleted.
  - Every other candidate (a stray file, or a modified one) is moved to the trash. A stray file in
    `.aid/runtime/` therefore leaves the runtime (AC-7), and nothing is lost.
- Emptied directories are removed, but never `<root>` itself.

**7. Dogfood resync (FR-16).** `sync_dogfood.py` is re-pointed from copying profile renders to the
two steps below.

1. Run `bash release.sh --stage-only --out <tmp>`.
2. Run the repo's own `bin/aid update --from-bundle <tmp> --target <repo>`. This runs with
   `AID_HOME=<tmp-home>` and `AID_NO_UPDATE_CHECK=1`, so the maintainer's registry and the
   network are never touched.

`run_generator.py` keeps chaining it. There is no recursion, because `--stage-only` never runs
the generator. The release-faithful procedure in `.claude/skills/generate-profile/SKILL.md` is
`bash release.sh --dry-run`, then `aid update --from-bundle .aid/.temp/release-<V>`. The
resulting `.aid/.aid-manifest.json`, `.agents/skills/`, `.claude/skills/aid-*`, `.aid/runtime/`,
the agents, `AGENTS.md` and `CLAUDE.md` are committed (AC-18).

**8. `aid status` (FR-9).**

- **Output.** The existing header and tools block are followed by a `Shared files` block:
  - each `modified:`, `missing:` or `extra:` path;
  - then `Run: aid update (drifted files are moved to .aid/.trash/ first)`;
  - or `Shared files: clean` when nothing has drifted.
- **What is checked.**
  - every file of `shared.skills`;
  - each mirror, against the `shared.skills` hashes;
  - `shared.runtime`;
  - the `AGENTS.md` region, against `region_sha256`;
  - the `CLAUDE.md` import region, against `shared.claude_md.region_sha256`, when that entry
    exists; a `CLAUDE.md` that is absent or has lost its markers is reported `missing:`;
  - each tool's `files`.

  An extra is an `aid-*` entry in `.agents/skills/` or a mirror that the manifest does not list,
  or an unrecorded file in `.aid/runtime/` outside the FR-6 runtime-local paths.
- **Hashing.** Hashes are computed in one batch: a single python3 `hashlib` pass, or a single
  `sha256sum`/`shasum` call over the file list. PowerShell calls `Get-FileHash` per file.
- **Exit code.** It stays 0 (drift is informational), or 7 when there is no manifest. For a
  format-2 manifest, status prints `Layout: format 4 (pre-shared). Run: aid update` and skips the
  drift check. The bare `aid` dashboard (`aid_status_body`) does not run the drift check, which
  keeps it fast.

**9. Work-level worktree root (runtime).**

- **New operation.** `worktree-lifecycle.sh root` (a new read-only operation) prints the
  absolute path of the container and creates the directory if needed. `_worktrees_root_from`
  reads `worktree_root` from `${main_root}/.aid/runtime/host.conf`, falling back to
  `./.aid/runtime/host.conf`.
- **Validation.** It validates the value with the same rule the CLI uses. If the value is
  absent or invalid, it uses `.aid/.worktrees` and prints one stderr diagnostic.
- **Lookup.** `create` and `locate` use that container. `locate` rung 1 stays branch-keyed, so a
  worktree under `.claude/worktrees/` is still found after the root changes (AC-8).
- **Skill callers.** `aid-update-kb` replaces its inline `WT_ROOT=...` line with
  `WT_ROOT="$(bash .aid/runtime/scripts/works/worktree-lifecycle.sh root)"`. `aid-execute`'s
  nesting paragraph names "the work-level worktree root that `worktree-lifecycle.sh root`
  prints". The enter step is unchanged: `EnterWorktree` on `claude-code`, which always gets a
  `.claude/worktrees/` target while Claude Code is installed.

##### Layers & Components

**Canonical sources (FR-1 to FR-3).**

- **`canonical/skills/**` (final bytes).**
  - Every `canonical/(aid/)?(scripts|templates)/` token becomes `.aid/runtime/(scripts|templates)/`.
  - `canonical/skills/` becomes `.agents/skills/`.
  - `canonical/agents/<a>/AGENT.md` references become the agent name.
  - `{project_context_file}` becomes `AGENTS.md`, `{reviewer_output_file}` becomes `STATE.md`,
    and `{open_questions_file}` becomes `additional-info.md`.
  - `.claude/aid/...` becomes `.aid/runtime/...` (in `aid-discover/references/state-generate.md`
    and `agent-prompts.md`).
  - The two `.claude/worktrees` sites change as described in Feature Flow 9.
- **`allowed-tools`.** Every line is space-separated, and `Bash` becomes `Bash Shell Terminal`
  (FR-2).
- **`build-shortcut-skills.py`.** It emits the same `allowed-tools` form, and its provenance
  comment names `generate-profile/scripts/build-shortcut-skills.py` with no host root (AC-4,
  AC-6).
- **`canonical/aid/**`.** The same token rewrite applies. `build-kb-index.sh` embeds
  `.aid/runtime/scripts/kb/build-kb-index.sh`, and `.aid/knowledge/INDEX.md` is regenerated in the
  same change. Installed and canonical bytes are now identical, which dissolves the
  INDEX-path gotcha in `architecture.md` § Gotchas. Lines that must resolve only in the AID source
  repo stay as they are and are listed in `tests/canonical/fixtures/runtime-source-path-allowlist.tsv`
  (new; columns `path`, `pattern`, `why`). An example is the `run_generator.py` row in
  `canonical/aid/templates/rough-time-hints.md` (AC-5). The install-tree skip lists in
  `build-project-index.sh` and `harvest-coined-terms.sh` (today `.claude .cursor .codex .agent`)
  gain `.agents`, so discovery never scans the installed skills as project source.
- **`canonical/agents/**`.** These are neutralized the same way, so the generator applies no text
  transform.
- **`canonical/aid/rules.md` (new).** This is the single source of the AID rules and replaces the
  region text of `profiles/*/AGENTS.md` and `profiles/claude-code/CLAUDE.md`. It is part of
  `canonical/aid/`, so it installs verbatim at `.aid/runtime/rules.md` and falls under the runtime
  equality checks. It names runtime paths as `.aid/runtime/templates/...` and uses "Read" lines.
  It lies outside the review-criteria registry's corpus (`canonical/aid/templates/` only), so no
  registry row is owed. Both root-file regions are constants in the install cores (see *Root
  context file* below).

**Generator (`.claude/skills/generate-profile/scripts/`; FR-4).**

- **`render.py`.**
  - `render_profile` renders only `canonical/agents/` and writes `aid-tool.conf`.
  - `copy_tree`'s `skills` and `none` branches and `_rewrite_skill_frontmatter` are deleted.
  - `_translate_agent` keeps the frontmatter translate (the `[tool_names]` remap on `tools:`,
    model resolution, and the Codex TOML branch) and `{{include:...}}` expansion.
  - VERIFY fails when an agent source still carries a `canonical/` token.
  - The self-test is updated so that `render.py --self-test` stays green (AC-21).
- **`render_lib.py`.** `rewrite_install_paths` and `substitute_filenames` are deleted along with
  their call sites.
- **`aid_profile.py`.** Validates the new TOML keys.
- **`verify_deterministic.py` and `verify_advisory.py`.** Their scope is cut to agents plus
  `aid-tool.conf`.
- **`run_generator.py`.** Still the single full-render command. It wipes each `profiles/<tool>/`
  and regenerates it in full on every run, so the tree holds exactly the generated agents and
  `aid-tool.conf` (AC-1).
- **`profiles/*/AGENTS.md` and `profiles/claude-code/CLAUDE.md`** are deleted.
- **Profile trees.** Each `profiles/<tool>/` holds agents and `aid-tool.conf` only (FR-4).

**Release (`release.sh`; FR-5).** Adds `build_shared_payload`, `build_tool_artifact` (replacing
`build_tarball`), `--stage-only` and `--out`. The `SHA256SUMS` glob is unchanged. The
release-notes stub text describes the new artifact set and states `v4 requires CLI v4`.

**Install core: bash and PowerShell twins (FR-6 to FR-12, FR-14).** Every row is one behaviour
implemented twice. The parity suite names every row (AC-16).

| Behaviour | `lib/aid-install-core.sh` / `bin/aid` | `lib/AidInstallCore.psm1` / `bin/aid.ps1` |
|---|---|---|
| descriptor reader | `read_kv_conf` (new) | `Read-AidKvConf` (new) |
| artifact fetch | `fetch_artifact` (new; `fetch_tarball` becomes a thin wrapper) | `Fetch-AidArtifact` (new) |
| wrapped extract plus member checks | `extract_payload` (new) | `Expand-AidPayload` (new) |
| staging of shared and tools | `_prepare_release_staging_aid` (replaces `_prepare_tool_staging_aid`) | its `bin/aid.ps1` twin |
| guarded copy | `copy_file_guarded` (new) | `Copy-AidFileGuarded` (new) |
| trash move with collision policy | `trash_file` (new; `_retire_file` delegates to it) | `Move-AidToTrash` (new) |
| shared commit | `install_shared` (new) | `Install-AidShared` (new) |
| per-tool commit (agents) | `install_tool` (rewritten) | `Install-AidTool` (rewritten) |
| host file | `write_host_conf` (new) | `Write-AidHostConf` (new) |
| manifest v3 write and read | `manifest_write` and `_manifest_write_python` / `_manifest_write_bash` (v3); `manifest_format`, `manifest_read_shared`, `manifest_read_tool_files`, `manifest_read_host` (new) | `Write-AidManifest`, `Build-ManifestJson` (v3); `Read-AidManifestShared`, `Read-AidManifestToolFiles`, `Read-AidManifestHost` (new) |
| clean-slate retire of the v3 layout | `retire_v3_layout` (new); `_migrate_retired_layout` (no longer sweeps `.agents/`) | `Invoke-RetireV3Layout` (new); `Invoke-MigrateRetiredLayout` |
| path-based ownership | `_is_aid_owned_path` (new) | `Test-AidOwnedPath` (new) |
| content-based root-region repair (`AGENTS.md`, `CLAUDE.md`) | `_repair_root_region` (new) | `Repair-AidRootRegion` (new) |
| `CLAUDE.md` import region | `_ensure_claude_md_region` and `_remove_claude_md_region` (new) | `Invoke-EnsureClaudeMdRegion` and `Invoke-RemoveClaudeMdRegion` (new) |
| prune | `prune_shared` (replaces `_prune_tool_dirs`) | `Invoke-PruneShared` (replaces `Invoke-PruneToolDirs`) |
| drift report | `drift_report` (new; called by `aid_status`) | `Get-AidDriftReport` (new; called by `Get-AidStatus`) |
| uninstall | `uninstall_tool` (v3 ref-counted branch) | `Uninstall-AidTool` |
| tool detection | `detect_tool` (`.agents` no longer marks Codex) | `Detect-Tool` |
| root file | `_root_agent_file` (`AGENTS.md` for every tool); `_copy_root_agent_file` (calls `_repair_root_region` with the pointer region) | `Get-RootAgentFile`; `Copy-RootAgentFile` |
| gitignore block | `_aid_gitignore_block` (adds the worktree roots) | `Get-AidGitignoreBlock` |
| gitattributes block | `_aid_gitattributes_block`, `update_gitattributes`, `remove_gitattributes_block` (new) | `Get-AidGitattributesBlock`, `Update-AidGitattributes`, `Remove-AidGitattributesBlock` (new) |
| settings seed | `seed_settings_yml` (template from `.aid/runtime/templates/`) | `Initialize-AidSettingsFile` |
| CLI gates and stamp | `_aid_layout_gate` (new), the skew gate in the `FR11` block, the stamp cap in `_aid_migrate_repo` | twins in `bin/aid.ps1` |
| staged-version check (`aid add`, flow 3 step 5) | `_check_staged_version` (new) | `Test-StagedVersion` (new) |


**Parity rules.**

- The PowerShell stays ASCII-only and runs on PS 5.1: no `??`, no ternary, no
  `-AsHashtable`.
- `.sh` files stay LF.
- Both shells produce the same exit codes, the same output lines, the same trash timestamps
  (UTC `yyyyMMddTHHmmssZ`) and the same manifest bytes.

**Root context file (FR-12; Gap 1).**

- **What `_root_agent_file` returns.** It returns `AGENTS.md` for every tool. `agents_md` is a
  shared entry.
- **The regions.** Both are fixed constants in both install cores, never payload files, and every
  line ends in LF. The AID rules live in `.aid/runtime/rules.md` (source `canonical/aid/rules.md`,
  part of the runtime payload). The `AGENTS.md` region only points at them and is exactly:

  ```
  <!-- AID:BEGIN -->
  <!-- Managed by the AID CLI. Do not edit between the AID markers. -->
  @.aid/runtime/rules.md
  Before acting, read and follow `.aid/runtime/rules.md` (AID rules).
  <!-- AID:END -->
  ```

  The `CLAUDE.md` import region is the three lines `<!-- AID:BEGIN -->`, `@AGENTS.md` and
  `<!-- AID:END -->`, written only while Claude Code is installed (Gap 1). Skills, including
  `/aid-discover`, never write inside either region.
- **`_repair_root_region <file> <region>`** (one function for both files). Every region line is
  fixed and known, so the CLI repairs by content, not by marker shape:
  - **The file is missing:** it is created holding only the region.
  - **The file holds exactly the well-formed region** (each region line once, in order, adjacent):
    nothing changes.
  - **The file holds no AID region line:** the region is appended at its end, preceded by one LF
    when the file is non-empty and does not end in LF. Every pre-existing byte is kept, so no trash
    copy is made.
  - **Anything else** (an orphan or duplicated marker, a partial or repeated region): the whole
    file is copied to `.aid/.trash/<file>` (collision policy), every line that exactly equals a
    region line of that file's region is removed wherever it sits, and one well-formed region is
    written at the position of the first removed line. Every other byte is kept. A second run
    finds the file well-formed and changes nothing.
- **`_ensure_claude_md_region`** runs in every add and update commit (flow 3, commit step 5)
  whenever an installed tool declares `context_import`, and calls `_repair_root_region` with the
  import region. `_copy_root_agent_file` does the same for `AGENTS.md` with the pointer region.
  After the write, the CLI records `agents_md.region_sha256` and `file_sha256`, or
  `claude_md.region_sha256`.
- **`_remove_claude_md_region`.** It runs when `shared.claude_md` loses its last user (flow 5).
  If the region no longer matches `region_sha256`, the whole file is copied to the trash first.
  Then the region is removed, marker lines included, and every other byte is kept, so a user
  file that ended in LF and received an appended region returns to its pre-add bytes. If the
  remainder is empty or whitespace-only, the file is deleted. A `CLAUDE.md` that has lost its
  markers, or holds malformed ones, is left byte-unchanged.
- **Scope.** While no installed tool declares `context_import`, the CLI never reads or writes
  `CLAUDE.md`. `AGENTS.md` keeps its region for the other tools whatever happens to
  `CLAUDE.md`.

**Runtime script.** `canonical/aid/scripts/works/worktree-lifecycle.sh` gains the `root`
operation, and `_worktrees_root_from` becomes `host.conf`-driven. Its usage header documents
both.

**Packages (FR-15).** `packages/npm/scripts/vendor.js` and `packages/pypi/scripts/vendor.py` are
unchanged in shape. They vendor the updated `lib/` and `bin/` (AC-17). `install.sh` and
`install.ps1` change only their usage examples (a staging directory instead of one tarball).

**Docs and KB (FR-17).** The following state the new layout in the same change:

- `README.md`, `docs/install.md`, `docs/aid-methodology.md` and `.github/workflows/test.yml`;
- the KB docs listed in §8 Dependencies, including the Install flow and render-output table in
  `architecture.md`;
- the content-isolation invariant, which now reads: skills use the `aid-` prefix under
  `.agents/skills/` and each mirror, the runtime lives under `.aid/runtime/`, and the root files
  are updated only between their markers: the `AGENTS.md` region for every tool, and, while
  Claude Code is installed, the `CLAUDE.md` region, which holds only `@AGENTS.md`;
- `G-10` and `G-11` in `authoring-conventions.md`, with the same placement rule.

The repo-root `CLAUDE.md` and `AGENTS.md` come out of the dogfood resync. No KB edit names this
work.

**Test plan (one row per criterion; new suites follow S1 to S5 and pin `HOME`).**

| AC | Where | What it asserts |
|---|---|---|
| AC-1 | `tests/canonical/test-shared-layout-sources.sh` (new); `render.py --self-test` | the AC-1 greps after a full `run_generator.py` |
| AC-2 | `tests/canonical/test-release.sh` (new RL cases) | the `--dry-run` artifact set; shared `skills/` and `runtime/` match canonical exactly; per-tool artifacts hold only `aid-tool.conf` and `<root>/agents/`; `SHA256SUMS` covers all |
| AC-3 | `tests/canonical/test-shared-install.sh` (new) | per tool, `aid add --from-bundle <stage-only dir>`; canonical equals `.agents/skills` (and `.claude/skills` for claude-code); file counts; negative control: mutate one staged byte, the check must fail |
| AC-4, AC-5, AC-6 | `test-shared-layout-sources.sh` | the AC greps; the AC-5 allowlist must have a `why` per row and no row may be stale |
| AC-7 | `test-shared-install.sh` | runtime bytes (and `rules.md`); no `<root>/aid/`; user `.aid/` shas unchanged across add, update and remove; a stray file in the runtime is pruned; the `.gitattributes` block and a user line kept |
| AC-8 | `tests/canonical/test-worktree-lifecycle.sh` | a cursor-only fixture creates under `.aid/.worktrees/`, which is in the block; `.claude/worktrees/work-002-y` is located as `registered`; extra: a claude-code fixture's root is `.claude/worktrees/` |
| AC-9, AC-10 | `tests/canonical/test-multitool-isolation.sh` (rewritten for the shared layout) | the ref-count sequence (including the `.gitattributes` block gone after the last remove) and the drift sequence exactly as worded |
| AC-11 | `tests/canonical/test-aid-cli.sh` (FR11 cases extended) | skew refusals; the whole-tree sha snapshot is unchanged; versions are equal after `update` |
| AC-12 | `tests/canonical/test-layout-format-guard.sh` (new) | carrier equality (three values); the new `aid add` on a v3-layout fixture exits 2, writes nothing and names `aid update`; a manifest with `format_version` above 3 is refused with `Run: aid update self` and writes nothing |
| AC-13 | `tests/canonical/test-aid-migrate.sh` (new fixtures for all five tools plus legacy `.agents/aid/`) | as worded, including the interrupted-run re-run, the second-run `up to date` and the unchanged trash |
| AC-14 | `test-shared-install.sh` (cases a, b, e and f), `test-aid-migrate.sh` (case c: the user-edited and no-marker v3 fixtures), `test-multitool-isolation.sh` (case d) | as worded; plus function-level cases for `_repair_root_region`, `_ensure_claude_md_region` and `_remove_claude_md_region`, including a non-LF-terminated file, a duplicated or partial region, and a drifted region that is trashed before removal |
| AC-15 | `test-aid-cli.sh`, `test-aid-cli-ps1.sh` | `detect_tool` and `Detect-Tool` |
| AC-16 | `test-aid-cli-parity.sh` (scenarios for flows 3 to 8, plus a static check naming every twin row above), `test-install-parity.sh`, `test-ps51-compat.sh`; `tests/windows/Test-AidInstaller.ps1` (AC-9, AC-10 and AC-13 scenarios) | parity |
| AC-17 | `test-npm-installer.sh`, `test-pypi-installer.sh` | vendored libs match by sha256 |
| AC-18 | `tests/canonical/test-dogfood-byte-identity.sh` (re-keyed: canonical ↔ `.agents/skills`, `.claude/skills`, `.aid/runtime/`; the manifest records the shared entries; agents ↔ the regenerated profile trees; the absences) | as worded |
| AC-19 | `test-shared-layout-sources.sh` (the grep) plus GATE reviewer | as worded |
| AC-20 | manual probes of the A-4 alias list and the A-6 pointer, recorded in `STATE.yml` | as worded |
| AC-21 | `tests/run-all.sh`, `render.py --self-test` | green |

**Shared fixture helper.** Every suite that builds bundles from `profiles/<tool>/` today switches
to `tests/lib/bundle.sh` (new). These are `test-aid-cli.sh`, `test-multitool-isolation.sh`,
`test-aid-migrate.sh`, `test-registry.sh`, the parity and package suites, and
`test-release-install-e2e.sh`. The helper runs `release.sh --stage-only --out <dir>`, so the tests
exercise the release code itself. Suites and CI steps that read rendered profile skills, runtime
or root files are re-pointed in the same change: `tests/canonical/test-chat-node-wake.sh`,
`test-cutover-no-dangling.sh`, `test-connector-skills-structural.sh`, `test-doc-counts.sh` and
`test-work-state-template.sh`, and the codex-tarball steps of `.github/workflows/installer-tests.yml`,
which build from `profiles/codex` today and switch to `release.sh --stage-only`.

**Removed or renamed assertion keys.** These come mainly from `test-agents-md-invariant.sh`
(retired, because its subject is gone), the per-root T-cases in `test-multitool-isolation.sh`,
and the `.cursor/` tuple of the dogfood suite. Each gets a row in
`tests/coverage-accepted-removals.tsv` (§7).

##### Upgrade from v3 (clean slate)

**Trigger.** `aid update` finds a v3 layout: a manifest with `format_version` 2, or the old paths
`<root>/aid/` and `<root>/skills/aid-*`. `aid add` never upgrades; it refuses (flow 3).

**Steps.**

1. Stage and validate everything (flow 2). A failure here means no write at all.
2. `retire_v3_layout` moves every old AID-owned path into `.aid/.trash/<original-path>` (collision
   policy as usual), using the path-based `_is_aid_owned_path` rule (FR-11). For `AGENTS.md` and
   `CLAUDE.md` it copies the whole file to the trash and removes the old AID region, marker lines
   included; a file left empty or whitespace-only is deleted, and a file with no well-formed
   region stays unchanged. Emptied directories are removed, never `<root>`. User files are never
   moved or deleted.
3. A normal fresh v4 install of the same tools (the manifest's tools, or the tools whose old roots
   held AID-owned paths): the flow 3 commit steps, the flow 6 prune, then `_aid_migrate_repo`,
   which stamps 5.

The run prints `N old AID file(s) moved to .aid/.trash/ (safe to delete once you have checked
them)`.

**Interruption and recovery.** There is no resume key, no journal and no step ordering. An
interrupted run is fixed by re-running `aid update`: step 2 only moves files, so a re-run finds
fewer old paths, and step 3 is the idempotent fresh install. To undo, restore from
`.aid/.trash/<original-path>` (the newest copy sits at the original path, older copies carry a
timestamp suffix) or from version control. A v3 CLI cannot drive a v4 layout (release notes: `v4
requires CLI v4`).

A second run on an upgraded repo prints `up to date` for `shared` and for every tool and leaves
`.aid/.trash/` unchanged (AC-13).

**This repo (dogfood).** Its format-2 manifest lists `claude-code` and `cursor`. The first
resync (flow 7) runs this upgrade. That trashes `.claude/aid/`, `.cursor/aid/` and
`.cursor/skills/aid-*`, replaces the full AID region of the root `CLAUDE.md` with the import
region while keeping its `## Project` section byte for byte, and keeps
`.claude/skills/generate-profile/`, `.claude/skills/release-aid/` and `.cursor/rules/` (AC-18).

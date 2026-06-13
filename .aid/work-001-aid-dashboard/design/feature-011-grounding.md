# Feature-011 (Upgrade-Migration) — Grounding Brief

> **Purpose:** Factual substrate for /aid-specify → /aid-plan → /aid-detail of a new
> upgrade-migration capability. Every claim is file:line-cited against the repo at
> `/home/andre.vianna/projects/AID` on branch `aid/work-001-aid-dashboard`. Confidence
> tags: CONFIRMED (directly observed) / LIKELY (strong inference) / UNCERTAIN.
> **Authored by:** Researcher (read-only). No production source touched.

---

## 0. Feature recap (scope this brief serves)

A migration that runs as part of the CLI upgrade:
- `aid update self` → updates the CLI, then **scans the machine** for `.aid` repos and
  migrates each (All/Yes/No/Cancel consent).
- `aid update [<tool>]` → updates the CLI if needed, then migrates **only the current repo**
  (no scan).
- npm/pypi postinstall → triggers the scan.
- **Per-repo migration:** validate/repair `.aid/settings.yml` (repos ≥0.7.X) OR synthesize it
  from `.aid/knowledge/DISCOVERY_STATE.md` (pre-0.7); add `.aid/dashboard/home.html`; relocate
  legacy KB summary → `.aid/dashboard/kb.html`; register repo in `$AID_HOME/registry.yml`.
- **Detection:** a `.aid/` folder with EITHER a settings file OR `knowledge/DISCOVERY_STATE.md`.

---

## 1. `.aid/settings.yml` schema — the migration target shape

### 1a. Canonical template (the verbatim copy `/aid-config` writes on first run)

Source of truth: **`canonical/templates/settings.yml`** (97 lines, full read).
`/aid-config` Step 1 copies `.claude/templates/settings.yml` → `.aid/settings.yml` **verbatim**
(`canonical/skills/aid-config/SKILL.md:38-43`). This repo's live `.aid/settings.yml` matches the
template with values filled in. **CONFIRMED filename is `.yml` everywhere** — a repo-wide search for
`settings.yaml` returns zero references; all readers/writers use `settings.yml`.

### 1b. Key inventory (every known section/key, type, owner)

| Dotted key | Type | Default (template) | Owner (writer) | Notes / evidence |
|---|---|---|---|---|
| `project.name` | string | `<project-name>` placeholder | `/aid-config` (INIT) | `settings.yml:14-15`; validated non-empty single-line (`aid-config/SKILL.md:145`-ish) |
| `project.description` | string (single-line, NO newlines) | `<project-description>` | `/aid-config` | `settings.yml:16`; "sole source of truth (not duplicated in CLAUDE.md/AGENTS.md)"; validation `aid-config/SKILL.md:145` |
| `project.type` | enum `brownfield`\|`greenfield` | `brownfield` | `/aid-config` | `settings.yml:17` |
| `tools.installed` | list<string> (block or inline) | `[claude-code]` (others commented) | `/aid-config` | `settings.yml:22-26`; valid tools = the manageable catalog (claude-code, codex, cursor, copilot-cli, antigravity) |
| `review.minimum_grade` | grade `^[A-F][+-]?$` | `A` | `/aid-config` | `settings.yml:37-38`; global REVIEW floor |
| `execution.max_parallel_tasks` | positive int | `5` | `/aid-config` | `settings.yml:43-44` |
| `traceability.heartbeat_interval` | positive int (minutes; `0` disables) | `1` | `/aid-config` | `settings.yml:49-50` |
| `kb_baseline.branch` | string (default-branch name) | absent (commented example) | **producer-written**: `aid-discover` (FR35), `aid-housekeep` (FR36) | `settings.yml:53-65`; **NOT user-authored**; `/aid-config` owns schema key (aid-config/SKILL.md:152) |
| `kb_baseline.tip_date` | ISO-8601 string | absent | same as above | `settings.yml:65`; absent ≡ "no baseline recorded" → reader skips freshness, stays approved |
| `<skill>.minimum_grade` | grade `^[A-F][+-]?$` | absent (commented examples) | `/aid-config` (per-skill override) | `settings.yml:78-96`; `<skill>` ∈ {discover, summary, interview, specify, plan, detail, execute, deploy, monitor} |

**Producers / writers:**
- **Sole creator/editor:** `/aid-config` skill (`canonical/skills/aid-config/SKILL.md:38-43` create;
  `:124` single-line in-place replace via temp-file + `mv -f`; `:126-132` append-block idiom for new
  blocks like the first `kb_baseline` write — see R13). **The installers do NOT write settings.yml**
  (`install.sh`/`install.ps1`/`lib/aid-install-core.sh`/`lib/AidInstallCore.psm1`/`bin/aid` have no
  settings.yml writer; the only `bin/aid` mentions are registry comments at `bin/aid:1110,1149`).
  *Migration implication:* there is **no existing scaffolder** for settings.yml outside `/aid-config`;
  the migration must either copy the template or synthesize. CONFIRMED.
- `kb_baseline` is the only producer-written block (`aid-discover`/`aid-housekeep`); a migration should
  treat its absence as valid and not synthesize it.

**Readers (what the migration must keep parseable):**
- **`canonical/scripts/config/read-setting.sh`** — the canonical resolver (full read, 263 lines). awk
  flat-section lookup (`:138-162`) + list lookup (`:169-207`); skill-mode override resolution
  (`:212-232`); path-mode (`:238-263`). **Tolerates a missing file** via `--default` (`:108-115`).
  No YAML binary required for the flat shapes AID stores.
- **Dashboard server `_read_settings`** (`dashboard/server/server.py:189-214`) — tolerant line-scan of
  `project:` → `name:`/`description:`; returns `(None, None)` on any failure. Node twin parses the same.
- **Dashboard reader `parse_project_name`** (`dashboard/reader/parsers.py:155-199`) and
  **`parse_kb_baseline`** (`parsers.py:231-279`) — display-only tolerant line-scans;
  `_strip_yaml_inline_comment` (`parsers.py:202-228`) strips inline comments.
- `dashboard/reader/locator.py:50` sets `settings_path = aid_dir / "settings.yml"`;
  `models.py:128,152,166` document the `kb_baseline` + `project_name` projection.

**Migration validate/repair-to contract (CONFIRMED substrate):** a "valid" settings.yml is one the
readers above parse without falling back — i.e. a top-level `project:` block with `name:`/`description:`,
and the four scalar sections (`tools`, `review`, `execution`, `traceability`). Repair = ensure those
sections exist with template defaults; preserve any present `kb_baseline`/per-skill overrides. The
single-line-replace vs append-block idioms (`aid-config/SKILL.md:124` vs `:126-132`) are the
crash-safe write patterns the migration should reuse (temp-file + `mv -f`).

---

## 2. `DISCOVERY_STATE.md` format — the era-b synthesis source

### 2a. Template

`canonical/templates/discovery-state-template.md` (88 lines, full read). **Note the renaming history:**
the template now produces **`STATE.md`** in `.aid/knowledge/` (line 10: "Absorbs what used to be
`DISCOVERY-STATE.md` + `SUMMARY-STATE.md`"). So a **pre-0.7 / "very old" repo** would carry the legacy
file under a name like `DISCOVERY_STATE.md` / `DISCOVERY-STATE.md`. **CONFIRMED:** no current code
references `DISCOVERY_STATE`/`DISCOVERY-STATE` (repo-wide search empty) — it is purely a historical
artifact name the migration detects, not a name any live producer writes. The current
`.aid/knowledge/STATE.md` is the modern equivalent. *Detection rule from the feature uses the legacy
`knowledge/DISCOVERY_STATE.md` name; the migration should LIKELY also accept the modern
`knowledge/STATE.md`.* (UNCERTAIN which exact filenames pre-0.7 used — flag for /aid-specify.)

### 2b. Fields available to populate settings.yml (era-b synthesis map)

From the template, the fields a synthesis could derive:

| Source field in DISCOVERY_STATE / STATE.md | Location | Maps to settings.yml | Confidence |
|---|---|---|---|
| Status (`Initial`/`In Progress`/`Approved`) | header blockquote `:4` | (none — run-state, not config) | — |
| Current Grade | header `:5` | (none) | — |
| `Profile` (web-app/library/cli/…) | Knowledge Summary table `:47` | (none direct; informs `project.type` heuristic) | LIKELY |
| KB Documents Status table | `:24-42` | (none — informs that KB exists) | — |
| `User Approved` | `:53` | (none) | — |
| Theme | `:50` | (none in settings.yml schema) | — |

**Key gap (CONFIRMED):** the DISCOVERY_STATE/STATE.md template carries **no `project.name` or
`project.description` fields** — those live only in settings.yml. So era-b synthesis cannot lift a
project name/description from STATE.md. **Derivable defaults for synthesis:**
- `project.name` → folder basename (the same fallback the dashboard uses: `models.py:166` "fallback:
  dir basename"). LIKELY.
- `project.description` → empty/placeholder, or prompt. UNCERTAIN.
- `project.type` → default `brownfield` (template default); a `greenfield` profile hint could flip it.
- `tools.installed` → derive from `.aid/.aid-manifest.json` `tools` keys (the authoritative installed-
  tools record, see §3) rather than from STATE.md. LIKELY — this is the better synthesis source than
  STATE.md.
- `review`/`execution`/`traceability` → template defaults (`A`, `5`, `1`).

*Implication for /aid-specify:* era-b synthesis = "copy template defaults + name=basename +
tools.installed from manifest"; STATE.md mostly confirms the repo IS an AID project rather than
supplying config values.

---

## 3. Install / upgrade / postinstall flow — where the scan hooks

### 3a. `aid update self` (the scan path)

`_cmd_update_self` at **`bin/aid:247-268`**. Behavior today:
- npm/pypi channel guard (`AID_INSTALL_CHANNEL`): prints the package-manager upgrade hint and
  **returns 0 without re-bootstrapping** (`bin/aid:250-259`).
- otherwise: `curl -fsSL "$AID_INSTALL_URL" | bash` (`:261-263`).
Dispatch: `bin/aid:1265-1279` (`SUBCMD == update` + first arg `self`); flags `--force`/`-y` are no-ops
(`:1271-1276`); `_cmd_update_self` then `exit $?`. **The machine-wide scan would attach after
`_cmd_update_self` returns** (a new post-update step in this dispatch block), before `exit`.
*Note:* on npm/pypi channels `_cmd_update_self` returns early (the actual CLI upgrade happens via the
package manager) — so for those channels the scan must be driven by the **package postinstall**
(§3e), not by `aid update self`. CONFIRMED.

### 3b. `aid update [<tool>]` (current-repo-only path)

Shared `add|update` engine. Dispatch + arg parse: `bin/aid:1302-1453`. Tool resolution
`_resolve_tools_for_aid` (`:1416-1453`): for `update` with no tool, resolves **all tools in the
repo manifest** (`:1420-1425`); errors exit 6 if no manifest (`:1476-1480`). Engine loop
`bin/aid:1541-1567` (`add|update` case): `_prepare_tool_staging_aid` (`:1495-1534`) →
`install_tool` (`:1547`) per tool → on success `registry_register "$_AID_TARGET"` (`:1565`) → `exit 0`.
**The current-repo migration would attach at the `add|update` success tail (`bin/aid:1563-1566`),
right beside the existing `registry_register` side-effect** — operating only on `$_AID_TARGET`
(resolved cwd/`--target`, canonicalized `cd && pwd` at `bin/aid:1366`). CONFIRMED.

> NOTE: feature-010 SPEC.md cites `bin/aid:1431/1452/1473/1255/804` for these seams; the live file
> (edited since) places them at `:1542`/`:1565`/`:1589`/`:1366`/`:804`. **/aid-detail must re-pin line
> numbers against the live `bin/aid` (63 KB) at detail time** — the SPEC's anchors have drifted.

### 3c. Shared engine functions (`lib/aid-install-core.sh` + `lib/AidInstallCore.psm1`)

The per-repo update reuses (Bash, `lib/aid-install-core.sh`):
- `install_tool` (`:1405`) — copies the tool tree, writes/updates `.aid/.aid-manifest.json`.
- `uninstall_tool` (`:1547`) — removes tool; `manifest_remove_tool` (`:973,1630`) deletes the manifest
  when the last tool is gone (`rm -f "$manifest"` at `:1019`); then removes `.aid-version` + empty
  `.aid/` (`:1632-1639`). **This manifest create/delete is the "first-tool/last-tool" boundary**
  feature-010 keys the registry side-effect off (SPEC FF-1).
- `manifest_write` (`:601`), `manifest_list_tools` (`:1117`), `manifest_exists` (`:1371`),
  `manifest_read_*` (`:455-601`), `detect_tool` (`:122`), `normalize_tool` (`:104`),
  `resolve_version` (`:160`), `fetch_tarball` (`:193`), `extract_tarball` (`:260`),
  `verify_bundle_checksum` (`:247`).
- **`lib/AidInstallCore.psm1`** is the PowerShell twin (57 KB) — same function set; any new shared
  migration helper added to the Bash core needs a PS twin (NFR5 parity, gated by
  `tests/canonical/test-aid-cli-parity.sh`).

### 3d. Bootstrap entry — `install.sh` / `install.ps1`

`install.sh` (55 KB): `_resolve_tools` (`:1201`), `prepare_tool_staging` (`:1254`), per-tool loop
`install_tool`/`uninstall_tool` (`:1313-1345`). `install.ps1` (60 KB) is the twin. **Neither contains
a settings.yml writer nor an FR31 KB-summary relocation block** (grep empty) — the FR31 relocation
lives only in the summarize/housekeep skills (§5). The bootstrap installs the CLI tree into `$AID_HOME`;
a postinstall scan would be triggered downstream, not from these scripts directly.

### 3e. npm + pypi package postinstall hooks — **THE GAP**

- **npm `packages/npm/package.json`:** scripts = **only `prepack` → `node scripts/vendor.js`**. There
  is **NO `postinstall` script.** `bin` = `bin/aid.js`. CONFIRMED.
- **npm shim `packages/npm/bin/aid.js`** (71 lines): a pure spawn-shim — sets
  `AID_INSTALL_CHANNEL=npm` and spawns vendored `bin/aid` (bash) / `bin/aid.ps1` (pwsh). No install/
  migration logic. CONFIRMED.
- **pypi `packages/pypi/pyproject.toml`:** `[project.scripts] aid = aid_installer.__main__:main`;
  build hook `[tool.hatch.build.hooks.custom] path = "scripts/vendor.py"` — a **build-time** vendor
  hook, **not** a runtime/install hook. CONFIRMED.
- **pypi shim `packages/pypi/aid_installer/__main__.py`** (82 lines): pure spawn-shim — sets
  `AID_INSTALL_CHANNEL=pypi`, spawns vendored `_vendor/bin/aid` / `aid.ps1`. No install/migration
  logic. CONFIRMED.

**Where a postinstall-triggered scan attaches (for /aid-specify):** there is **no existing postinstall
hook in either package** — the feature must **add** one:
- npm: add a `"postinstall"` script to `packages/npm/package.json` (runs on `npm i -g aid-installer`).
- pypi: pip/pipx have **no standard post-install hook** for wheels (PEP 517 removed `setup.py install`
  hooks); the scan would LIKELY have to be triggered **lazily on first `aid …` invocation** from the
  shims (`aid.js`/`__main__.py`) or from `bin/aid` itself (a "first-run after upgrade" sentinel),
  rather than a true pip postinstall. **Flag as a key /aid-specify decision** — the brief's feature
  statement says "npm/pypi postinstall triggers the scan," but pypi has no clean postinstall; a
  version-sentinel + lazy trigger is the realistic mechanism. UNCERTAIN/needs decision.

### 3f. PowerShell twin parity expectation

Every `bin/aid` change has a **`bin/aid.ps1` twin** (72 KB). They are **hand-maintained, NOT
`canonical/`→render artifacts** (feature-010 SPEC CLI-1, SPEC.md:549-564; R6/R10 in PLAN.md). Gates for
any `bin/aid` edit: **ASCII-only** (`tests/canonical/test-ascii-only.sh`), **Bash↔PowerShell parity**
(`tests/canonical/test-aid-cli-parity.sh`), **vendored-copy refresh** (`vendor.js`/`vendor.py`) — NOT
render-drift/`run_generator.py`. CONFIRMED.

---

## 4. Registry — `$AID_HOME/registry.yml`

### 4a. Format (CONFIRMED, written by `bin/aid`)

```yaml
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/
# description/version are read from each repo's own .aid/settings.yml at render time.
schema: 1
repos:
  - /abs/path/to/repoA
  - /abs/path/to/repoB
```
`schema: 1` (int) + `repos:` (list of absolute, canonicalized repo base-folder paths — the dir that
*contains* `.aid/`, not `.aid/` itself). Source: `bin/aid:1107-1115` (register writer) /
`bin/aid:1146-1153` (unregister writer); schema documented in feature-010 SPEC DM-1 (SPEC.md:214-262).

### 4b. Read/write functions (`bin/aid`)

- `_registry_read_repos <reg>` (`bin/aid:1082-1088`) — `grep -E '^\s*-\s+'` → strip prefix; empty when
  absent. **This is the line-scan the migration's scan can reuse to read the existing registry.**
- `registry_register <canon-path>` (`bin/aid:1094-1127`) — `reg="${AID_HOME}/registry.yml"`;
  `mkdir -p "$AID_HOME"`; idempotent set-insert; atomic temp-file + `mv -f` (`:1103,1121`); WARN-and-
  return-0 on failure (never blocks the host op, NFR10). Prints `Registered <repo> with the AID CLI.`
- `registry_unregister <canon-path>` (`bin/aid:1133-1165`) — set-remove; same atomic write.
- `$AID_HOME` resolution: `bin/aid:37-47` (`pwd -P` of `bin/aid` → `dirname/dirname`; env override
  `AID_HOME`; fallback `${HOME}/.aid`). Server reads it at `server.py:736,758` /
  `server.mjs:582,600` (`join(AID_HOME, "registry.yml")`).
- **PS twin:** `bin/aid.ps1` carries the equivalent register/unregister + read (parity-gated).

### 4c. How `aid add` registers today (the side-effect to mirror)

After a successful `add|update` loop, `bin/aid:1565` calls `registry_register "$_AID_TARGET"`
(canonicalized at `:1366`). After `remove`, `bin/aid:1588-1590` calls `registry_unregister` **only if
the manifest is now gone** (last tool). **The migration's per-repo "register the repo" step reuses
`registry_register` verbatim** — it is already idempotent, atomic, and CAN-1-canonicalized. CONFIRMED.

---

## 5. Legacy KB summary relocation (FR31 reuse)

**OLD path:** `.aid/knowledge/knowledge-summary.html`
**NEW path:** `.aid/dashboard/kb.html`
**Move semantics:** `mkdir -p .aid/dashboard` then `mv -n` (no-clobber), guarded by
`[ -f "$OLD" ] && [ ! -f "$NEW" ]`. Best-effort, idempotent.

Two existing implementations of this exact block — both reusable verbatim by the migration:
1. **`canonical/scripts/summarize/summarize-preflight.sh:102-113`** — `OLD_SUMMARY`/`NEW_SUMMARY` +
   `mkdir -p .aid/dashboard 2>/dev/null && mv -n "$OLD_SUMMARY" "$NEW_SUMMARY"`; prints
   "Migrated legacy summary -> … (FR31 relocation)." CONFIRMED.
2. **`canonical/skills/aid-housekeep/references/state-summary-delta.md:85-89`** — identical block;
   Step 1b; later commits the move (`:285-286`).

**Other historical summary locations:** the only OLD location is `.aid/knowledge/knowledge-summary.html`
(CONFIRMED — both producers reference only that path). The current canonical output is
`.aid/dashboard/kb.html` (this repo has a 3.4 MB `kb.html`). No other historical summary path found.
*Migration implication:* relocate using the exact `mkdir -p .aid/dashboard && mv -n OLD NEW` idiom; it
is already safe to run on a repo that has already migrated (the `[ ! -f NEW ]` guard).

---

## 6. `home.html` provisioning — confirmed gap (KI-010)

**CONFIRMED via KI-010 (`.aid/work-001-aid-dashboard/known-issues.md`):** there is **NO** writer/vendor/
template/scaffolder for `.aid/dashboard/home.html`. KI-010 states it is **vendored: NO, generated: NO,
scaffolded: NO** — it exists in this repo only because it was committed by hand.

- **Single existing copy:** `/.aid/dashboard/home.html` (122 KB, the dogfood repo's hand-committed
  file). (A second copy exists only as a test fixture:
  `dashboard/server/tests/fixtures/pt1h-repo-a/.aid/dashboard/home.html`.) CONFIRMED via
  `find . -name home.html`.
- **Vendor manifests that would need a `home.html` entry:**
  - `packages/npm/scripts/vendor.js` — `copies[]` array at `:40-59` (currently 17 files: CLI +
    `dashboard/index.html` + reader/server). **`home.html` is NOT in the list.**
  - `packages/pypi/scripts/vendor.py` — `COPIES` list at `:49-69` (same set). **Not in the list.**
- **For comparison, the vendored CLI home is `dashboard/index.html`** (`vendor.js:48`,
  `vendor.py:57`) — the machine-level page served at `/`. The per-repo `home.html` (served at
  `/r/<id>/home.html`, `server.py:775`-area) is the stranded one.

*Migration implication (matches KI-010 "intended remedy"):* the migration's "add
`.aid/dashboard/home.html`" step needs a **canonical source** for that file. Options for /aid-specify:
(a) vendor `home.html` into the install tree (`$AID_HOME/dashboard/home.html`) by adding it to BOTH
vendor manifests, then copy it into each migrated repo; and/or (b) have the server fall back to a
vendored `$AID_HOME/dashboard/home.html` when the repo copy is absent. **Decide the canonical source
location** — today only `.aid/dashboard/home.html` exists (KI-010 explicitly defers this decision to
the migration feature). `home.html` is a static, repo-agnostic SPA shell, so a single vendored copy
suffices. CONFIRMED gap; remedy is a /aid-specify decision.

---

## 7. AID planning conventions + current numbering

### 7a. REQUIREMENTS.md structure + highest numbers

`.aid/work-001-aid-dashboard/REQUIREMENTS.md` sections: `## Change Log` → `## 1. Objective` →
`## 2. Problem Statement` → `## 3. Users & Stakeholders` → `## 3a. Monitoring Levels` →
`## 4. Scope` (Architecture principle / In Scope / Out of Scope) → `## 5. Functional Requirements`
(FRs, plus a "Two-level dashboard re-architecture (FR27–FR36)" sub-section at `:297`) →
`## 6. Non-Functional Requirements` (`:433`) → `## 7. Constraints` (`:475`) →
`## 8. Assumptions & Dependencies` (`:550`) → `## 9. Acceptance Criteria` (`:603`) →
`## 10. Priority` (`:629`).

**Highest existing numbers (next for feature-011):**
- **FR: highest = FR36 → next = FR37.** CONFIRMED.
- **NFR: highest = NFR11 → next = NFR12.** CONFIRMED.
- **Constraints: highest = C7 → next = C8.** CONFIRMED (C1–C7 present).

### 7b. Feature SPEC structure (from feature-010)

Template, in order (`features/feature-010-cli-home-and-registry/SPEC.md`):
`# <title>` → `## Change Log` (table) → `## Source` (REQUIREMENTS refs) → `## Description` →
`## User Stories` → `## Priority` → `## Owned Requirements` → `## Acceptance Criteria` (checkbox list,
each criterion `Given…when…then…` with FR/NFR/C cites) → `## Decomposition Rationale (one feature, not
N)` → `---` → `## Technical Specification` (with an "Activated sections" blockquote naming which
`canonical/templates/specs/spec-template.md` sections apply, then **Data Model** (DM-N tables/jsonc),
**Feature Flow** (FF-N pseudo-flows), **Layers & Components** (LC-N table + MUST NOT), **CLI / Command
spec** (CLI-N), **API Contracts** (route table), **UI Specs**, **Security Specs** (SEC-N), and
**§6 quality gates** + design-decisions DD-N / RC-N as needed). Acceptance criteria are written as
testable `Given/when/then` bullets citing requirement IDs. CONFIRMED.

### 7c. PLAN.md structure + highest delivery

`.aid/work-001-aid-dashboard/PLAN.md`: `# Plan` (header blockquotes with re-plan history) →
`## Deliverables` (`### delivery-NNN: <title>` blocks, each with What / Features / **Depends on:** /
Sequencing) → `## Execution Graph` (`:379` — **per-delivery wave-maps**) → `## Cross-Cutting Risks`
(`:341`, table R1–R15) → `## Deferred` (`:361`).

- **Wave/parallel expression (CONFIRMED, `:379-516`):** each delivery has a wave list:
  `- Wave N (label): task-XXX (role) ∥ task-YYY (role) — needs task-ZZZ ∧ task-WWW`. Parallelism is the
  `∥` operator; dependencies use `∧` and "needs task-NNN"; "join" waves are explicitly labelled. There
  is **no separate "Can Be Done In Parallel" heading** — parallelism is encoded inline via `∥` within
  the per-delivery wave-map under `## Execution Graph`. The reader derives each task's
  `delivery`/`lane`/`short_name` from these blocks (feature-009 format; PLAN.md:85-88).
- **Highest delivery = delivery-010 → next = delivery-011.** CONFIRMED (deliveries 001–010 exist;
  005 is SUPERSEDED but numbered).

### 7d. Tasks — highest number + template + vocabulary

- **Task files live flat in `.aid/work-001-aid-dashboard/tasks/task-NNN.md`** (NOT under
  `features/*/tasks/`). **Highest = task-073 → next = task-074.** CONFIRMED.
- **Task file template** (from `tasks/task-073.md`): `# task-NNN: <title>` → `**Type:** <TYPE>` →
  `**Source:** <feature> → <delivery>` → `**Depends on:** task-XXX, task-YYY` → `**Scope:**` (bullet
  list of precise work) → `**Acceptance Criteria:**` (checkbox list). CONFIRMED.
- **Typed task vocabulary observed:** `DESIGN`, `TEST`, `MIGRATE` (used for the work-001 data
  migration, PLAN.md:463), plus implementation/producer task types (feature/build). The migration
  feature will LIKELY use **MIGRATE**-typed tasks for the per-repo migration logic and **TEST** for the
  Playwright/parity gates. The exact full enum is whatever the work's tasks use; confirm against
  `canonical/templates/` task template at /aid-detail if a strict enum is needed.

### 7e. The A+ gate mechanics

- **`bash .claude/scripts/grade.sh <ledger-file>`** computes the grade from a reviewer ledger
  (`grade.sh:1-40`): parses the **Severity** (col 3) + **Status** (col 4) of each data row, counts
  rows where Status ∈ {Pending, Recurred} by severity, worst-severity-dominates rubric. Flags:
  `--explain`, `--non-functional` (forces F), `--from-prose` (deprecated).
- **Reviewer ledger schema** = `.claude/templates/reviewer-ledger-schema.md` — a **single 7-column
  markdown table, no narrative**: `# | Severity | Status | Doc | Line | Description | Evidence`.
  Severity enum `[CRITICAL]|[HIGH]|[MEDIUM]|[LOW]|[MINOR]`; Status enum
  `Pending|Fixed|Recurred|Accepted|OOS|Invalid`. File path
  `.aid/.temp/review-pending/<scope>.md`. (Also pinned in project CLAUDE.md.) CONFIRMED.
- **R5 hard gate (project + user CLAUDE.md):** any review of rendered web output MUST use Playwright
  visual validation — source-only review is an automatic FAIL (grade F). Applies to any UI the
  migration touches (e.g. a freshly-provisioned `home.html`).

---

## 8. Cross-cutting notes for /aid-specify (open decisions & risks)

1. **pypi has no clean postinstall** (PEP 517 wheels) — the "postinstall triggers the scan" needs a
   realistic mechanism: a version-sentinel + lazy first-run trigger from the shim/`bin/aid`, or an
   npm-only postinstall. **Decision needed.** (§3e)
2. **`home.html` canonical source location** — must be vendored (add to both vendor manifests) and/or
   served as a `$AID_HOME` fallback; today only `.aid/dashboard/home.html` exists. (§6 / KI-010)
3. **Era-b synthesis cannot get name/description from STATE.md** — derive name=basename,
   tools.installed from the manifest, rest = template defaults. Pre-0.7 detection filename
   (`DISCOVERY_STATE.md` vs modern `STATE.md`) is UNCERTAIN — pin at /aid-specify. (§2)
4. **`bin/aid` line anchors in feature-010 SPEC have drifted** vs the live 63 KB file — re-pin all
   `bin/aid:NNN` seams at /aid-detail. (§3b)
5. **All `bin/aid` edits need the PS twin + 3 gates** (ASCII-only, parity, vendor refresh), NOT
   render-drift. (§3f)
6. **Migration is read-mostly + idempotent + WARN-not-fail** — reuse the existing atomic-write
   (`mv -f`), no-clobber (`mv -n`), idempotent-set, and NFR10 degrade-don't-block postures already in
   `registry_register` (§4) and the FR31 relocation (§5).

---

## 9. Next-number summary (for slotting feature-011 artifacts)

| Artifact | Highest existing | Next (feature-011) |
|---|---|---|
| Feature dir | feature-010 | **feature-011** |
| FR | FR36 | **FR37** |
| NFR | NFR11 | **NFR12** |
| Constraint | C7 | **C8** |
| Delivery | delivery-010 | **delivery-011** |
| Task | task-073 | **task-074** |

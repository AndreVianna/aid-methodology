# Numbered `aid projects` List with Remove-by-Number

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-16 | SPEC authored from REQUIREMENTS.md | /aid-change-cli |
| 2026-07-16 | Finalized remove number/path disambiguation per stakeholder (rules 1-4; quote rule dropped) | /aid-change-cli |
| 2026-07-16 | GATE fixes: vendoring auto-generated (NFR-2 reframed), corrected -1 rejection anchor, base-10 parsing, usage idempotency, KB cite | /aid-change-cli |

## Source

- REQUIREMENTS.md §5 Functional Requirements — FR-1..FR-7 (numbered list, remove-by-number,
  disambiguation, error handling, `add` unaffected, single ordering, docs + parity)
- REQUIREMENTS.md §6 Non-Functional Requirements — NFR-1 twin byte-parity, NFR-2 vendoring is build-time (not manual)
- REQUIREMENTS.md §8 Assumptions & Dependencies — A-1 integer-vs-path disambiguation (settled:
  all-digits -> index, non-digit -> path)
- REQUIREMENTS.md §9 Acceptance Criteria — AC-1..AC-13
- REQUIREMENTS.md §10 Priority — Must

## Description

`aid projects list` numbers every registered-project row from 1, and `aid projects remove`
accepts that number to unregister the matching project. A user can list, read a number off the
output, and remove a project with `aid projects remove <N>` instead of copying its full
canonical path. The existing `aid projects remove <path>` form keeps working; `aid projects
add` is untouched. The change edits the Bash and PowerShell CLI twins; their vendored copies
regenerate from `bin/` at package-build time (no manual re-sync).

## User Stories

- As an AID maintainer, I want each `aid projects list` row numbered from 1 so that I can refer
  to a project by its position instead of its full path.
- As an `aid` CLI user, I want `aid projects remove <N>` to unregister the Nth listed project so
  that I can remove a project without retyping its path.
- As an `aid` CLI user, I want `aid projects remove <path>` to keep working so that existing
  scripts and habits are not broken.

## Priority

Must

## Acceptance Criteria

- [ ] Given at least one registered project, when `aid projects list` runs, then each project
  row is prefixed with a 1-based sequential number (first row is `1`, incrementing by one) in
  `_registry_read_raw_union` order, and the `*` current-directory marker still shows for cwd.
- [ ] Given N registered projects, when `aid projects remove K` runs with an all-digits `K` in
  `1 <= K <= N`, then the Kth project in list order is unregistered and no other registry entry
  changes.
- [ ] Given a registered project referenced by a path argument containing a non-digit (e.g.
  `./name` or its absolute path), when `aid projects remove <path>` runs, then that path is
  unregistered exactly as the path form did before.
- [ ] Given N registered projects (N >= 1), when `aid projects remove K` runs with an all-digits
  `K > N`, then a clear stderr message is printed, the command exits `2`, and the registry is
  unchanged.
- [ ] Given no registered projects, when `aid projects remove 1` runs, then a clear stderr
  message is printed and the command exits `2` (the `N > count` case with `count == 0`).
- [ ] Given a fixed registry state, when `list` numbers a project `K` and `aid projects remove
  K` runs, then the project removed is the one `list` numbered `K` (single `_registry_read_raw_union` ordering).
- [ ] Given `aid projects add <path>`, when it runs, then its behavior and output are unchanged.
- [ ] Given no registered projects, when `aid projects list` runs, then `(no projects registered)`
  prints and no numbered rows appear.
- [ ] Given identical registry state, when the same commands (including the error cases) run
  under the Bash and PowerShell twins, then output and behavior are identical, and the
  usage/help text plus the synopsis comment document `remove <N>` and the numbered list on both
  twins, and the `remove` usage line no longer claims "Idempotent"/"works on stale/missing" but
  states that an unregistered/nonexistent path now errors.
- [ ] Given any registry state, when `aid projects remove 0` (or `00`) runs — an all-digits value
  `< 1` — then a clear stderr message ("index must be a positive integer, `>= 1`") is printed,
  the command exits `2`, and the registry is unchanged.
- [ ] Given any registry state, when `aid projects remove -1` runs, then it is rejected upstream
  as an unknown flag with exit `2` and the registry is unchanged (it is never classified as an
  index).
- [ ] Given a path argument containing a non-digit that does NOT canonicalize to a
  currently-registered project (e.g. `abc`), when `aid projects remove <path>` runs, then a clear
  stderr message is printed and the command exits `2` — not the former idempotent no-op.
- [ ] Given a registered project whose folder is literally named `1`, when `aid projects remove
  1` runs it resolves as an index (never that folder), and when `aid projects remove ./1` (or
  the absolute path) runs it unregisters that folder-named project.

---

## Technical Specification

> Added by `/aid-change-cli` (shortcut engine SPEC state). Mandatory three sections only —
> the `cli` artifact activates no conditional `## Technical Specification` section
> (`shortcut-scaffolding/create.md § SPEC`, inherited by `change-refactor.md`).

### Data Model

No persistent schema change. AID's project registry is a pair of `registry.yml` files under the
state homes (`${AID_STATE_HOME}/registry.yml`, `${HOME}/.aid/registry.yml`); their format, the
tier resolution, and the union ordering are all untouched. There is no relational store and no
persistent schema to change — the registry is simply that pair of `registry.yml` files.

The only "model" this change introduces is a **positional view** over the already-existing
in-memory ordered list of registered paths:

- Bash: the `_paths` array built from `_registry_read_raw_union` at `bin/aid:2502-2505`.
- PowerShell: the `$paths` array built from `Get-RegistryRawUnion` at `bin/aid.ps1:1611`.

The 1-based index is `array position + 1`; it is computed at render time and never stored. The
same array (rebuilt from the same helper) backs both the `list` numbering and the `remove <N>`
resolution, which is what guarantees the two agree (FR-6 / AC-6).

### Feature Flow

**List flow (numbered) — FR-1 / AC-1 / AC-8.**
`_cmd_projects_list` (`bin/aid:2494`) / `Invoke-AidProjectsList` (`bin/aid.ps1:1604`) builds the
ordered union, prints a header row + rule (`bin/aid:2508-2509` / `bin/aid.ps1:1614-1615`), then
loops the entries emitting one aligned row each (`bin/aid:2513-2536` / `bin/aid.ps1:1618-1638`).
The change adds a 1-based counter incremented once per emitted entry and a new leading `#`
column in the header, the rule, and each row's `printf`/format string; the existing marker
column (`*` / two-space) and the `PATH`/`STATE`/`TOOLS`/`TIER` columns follow it, unchanged in
content. The empty case (`bin/aid:2538-2540` / `bin/aid.ps1:1640-1642`) still prints
`(no projects registered)` with no numbered rows; the unregistered-cwd footnote
(`bin/aid:2542-2546` / `bin/aid.ps1:1644-1648`) and the `* = current directory` legend
(`bin/aid:2548-2552` / `bin/aid.ps1:1650-1654`) are unchanged.

**Remove flow (index-or-path) — FR-2 / FR-3 / FR-4 / AC-2..AC-5, AC-10..AC-13.**
The dispatcher parses the sub-action and its positional and calls the remove handler
(`bin/aid:2905-2926` -> `_cmd_projects` `bin/aid:2453` -> `_cmd_projects_remove` `bin/aid:2629`;
`bin/aid.ps1:2833-2866` -> `Invoke-AidProjects` `bin/aid.ps1:1742` -> `Invoke-AidProjectsRemove`
`bin/aid.ps1:1703`). A `-`-prefixed token such as `-1` never reaches this handler: the
action-match branch (`bin/aid:2907-2912`) sweeps `remove`'s args past the dispatcher's own flag
case, so `-1` reaches `_cmd_projects` and is rejected by its unknown-flag case (`bin/aid:2466-2469`,
PowerShell twin `bin/aid.ps1:1761-1764`) upstream with exit 2 (FR-4 / AC-11). A new first step in
the remove handler classifies the
argument purely by shape:

1. If the argument is **all digits** (`^[0-9]+$`, a non-negative decimal integer), treat it as
   index N — ALWAYS, never a path, even if a folder of that literal name exists (AC-13): rebuild
   the ordered union from `_registry_read_raw_union` (the same helper `list` uses), let `count`
   be its length, and parse N base-10 (Bash `10#"$arg"`, PowerShell `[int]` which is already
   decimal) so `01` -> 1 and leading-zero forms containing an 8 or 9 (`008`/`009`) are handled as
   decimal and never trip bash's octal-literal error (e.g. `$((008))`). Because `^[0-9]+$` admits `0`, an
   explicit `N >= 1` value check follows the regex:
   - `1 <= N <= count`: select the Nth entry as the target path and fall through to the existing
     canonicalize + `registry_unregister` logic (`bin/aid:2633-2660`) (AC-2 / AC-6).
   - `N < 1` (`0`, `00`): print a clear "index must be a positive integer (`>= 1`)" message to
     stderr and `exit 2`, registry unchanged (AC-10). `0` is all-digits, so it DOES reach the
     classifier — this is a live case caught by the `N >= 1` value check, not an unreachable
     guard.
   - `N > count`, including the empty registry (`count == 0`): print a clear "no project numbered
     N (M registered)" message to stderr and `exit 2`, registry unchanged (AC-4 / AC-5). Matches
     the command's existing exit-2 usage errors (e.g. `bin/aid:2467-2468`).
2. Otherwise (the argument **contains a non-digit**: `./1`, `C:/1`, `/abs/path`, `abc`, `1a`,
   `1.5`, `foo/bar`) treat it as a **path**: canonicalize (`bin/aid:2634-2640`); if it resolves
   to a currently-registered project, unregister it (`bin/aid:2655`) exactly as the path form did
   before (AC-3). If it does NOT resolve to a currently-registered project, print a clear stderr
   message and `exit 2` (AC-12) — this replaces the former idempotent "not registered (nothing
   to remove)" no-op. To target a folder literally named with digits, the user uses this path
   form (`./1` or an absolute path) (AC-13).

`aid projects remove` with no argument still defaults to cwd (existing behavior); the numeric
classification triggers only for an explicitly supplied all-digits argument.

**Add flow — FR-5 / AC-7.** `_cmd_projects_add` (`bin/aid:2585`) / `Invoke-AidProjectsAdd`
(`bin/aid.ps1:1660`) is untouched.

### Layers & Components

- **Canonical twins (edited in lockstep — NFR-1).**
  - `bin/aid` (Bash): `_cmd_projects_list` (`:2494`), `_cmd_projects_remove` (`:2629`), the
    `projects` usage block (`:187-202`), and the top-of-file synopsis comment (`:19`, and the
    `aid projects` usage line at `:19-20`).
  - `bin/aid.ps1` (PowerShell): `Invoke-AidProjectsList` (`:1604`), `Invoke-AidProjectsRemove`
    (`:1703`), and the `projects` usage block (`:238-253`). PowerShell twin MUST stay
    WinPS-5.1 compatible (`coding-standards.md`).
  - `bin/aid.cmd` is a thin cmd.exe shim over `aid.ps1` (`module-map.md`) — no change.
- **Reused helpers (unchanged — REQUIREMENTS D-1).** `_registry_read_raw_union` /
  `Get-RegistryRawUnion` (single ordering source), `registry_unregister` /
  `Registry-Unregister` (removal). No new registry primitive is added.
- **Coding standards.** Usage-error exit code `2` is reused per
  `coding-standards.md § Exit Codes` ("2 usage") for the numeric range / `< 1` errors and the
  unregistered-path error; diagnostics go to stderr, results to stdout. The integer test uses a
  portable all-digits pattern plus an explicit `>= 1` value check (Bash
  `[[ "$arg" =~ ^[0-9]+$ ]]` then a base-10 integer compare via `10#"$arg"`; PowerShell
  `-match '^[0-9]+$'` then an `[int]` compare, already decimal) — the regex admits `0`, so the
  value check is what rejects `N < 1`, and forcing base-10 avoids bash's octal-literal error for
  leading-zero values containing an 8 or 9 (e.g. `008`).
- **Help/synopsis text — FR-7.** The `projects` usage blocks and the synopsis comment gain the
  numbered-list note and the `remove [<path>|<N>]` form on both twins, kept identical. The
  existing `remove` usage line (`bin/aid:198`, `bin/aid.ps1:249`) is rewritten so it documents
  the index form, the numeric errors, and that an unregistered/nonexistent path now errors —
  dropping the now-false "Works on stale/missing/no-aid entries. Idempotent." wording (AC-12
  replaces that no-op with an exit-2 error).
- **Vendoring is build-time — NFR-2.** The only edit target is the canonical `bin/` twins. The
  npm and pypi packages regenerate their vendored copies from `bin/` at package-build/pack time
  (`packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`) — those copies are
  gitignored, auto-generated artifacts, so no manual re-sync is required and they are out of scope
  (per `module-map.md` Invariants, `packages/*/_vendor/` must be regenerated, never hand-edited).
  The npm package also vendors `aid.js`/`aid.cmd` (unchanged by this work).
- **Tests.** Twin behavior-parity is enforced by `tests/canonical/test-aid-cli-parity.sh`
  (`module-map.md`, `test-landscape.md`); the projects/registry behavior is covered by the CLI
  registry suite. The TEST task extends these to cover numbered `list` and `remove <N>`
  (in-range, `< 1`, out-of-range, empty-registry, negative-via-flag, unregistered-path,
  digit-named-folder path form, and path-form-preserved cases) on both twins.

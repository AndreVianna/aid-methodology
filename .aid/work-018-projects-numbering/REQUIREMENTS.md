# Requirements

- **Name:** Numbered `aid projects` List with Remove-by-Number
- **Description:** Number the `aid projects list` output from 1 and let `aid projects remove` accept that list number to unregister the corresponding project

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-16 | Initial capture (shortcut: aid-change-cli) | /aid-change-cli |
| 2026-07-16 | Finalized remove number/path disambiguation per stakeholder (rules 1-4; quote rule dropped) | /aid-change-cli |
| 2026-07-16 | GATE fixes: vendoring auto-generated (NFR-2 reframed), corrected -1 rejection anchor, base-10 parsing, usage idempotency, KB cite | /aid-change-cli |

## 1. Objective

Make the `aid projects` command friendlier to drive by hand. Today a user who wants to
unregister a project must copy or retype its full canonical path. This change numbers the
`aid projects list` output starting at 1 and lets `aid projects remove` take that number
(e.g. `aid projects remove 1` removes the first-listed project), so a user can list, read a
number, and remove it without handling the path at all.

## 2. Problem Statement

**Current shape/behavior.** `aid projects list` (`bin/aid:2494` / `bin/aid.ps1:1604`) prints
an aligned table whose columns are a leading 2-char marker (`*` = current directory), then
`PATH`, `STATE`, `TOOLS`, `TIER`, one row per entry in the union returned by
`_registry_read_raw_union` (consumed at `bin/aid:2503-2505`). `aid projects remove`
(`bin/aid:2629` / `bin/aid.ps1:1703`) accepts a single positional `<path>` argument (default
cwd), canonicalizes it, and unregisters that path. There is no way to refer to a listed
project by position.

**The pain.** Registry paths are long absolute paths. To remove one, the user must read the
path off the list, then retype or paste it exactly (canonicalized) into `remove`. That is
error-prone and slow for a routine housekeeping action.

**Target shape/behavior.** `list` gains a leading 1-based index column so every row is
numbered from 1 in the same order the list already prints. `remove` additionally accepts an
all-digits list number that resolves to the Nth project in that same order and unregisters it.
The existing `remove <path>` form still removes a genuinely-registered project path.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID maintainer (requester) | The AID maintainer driving `aid projects` from the terminal | List and unregister projects quickly without handling long paths |
| `aid` CLI user | Any adopter who manages registered AID projects with the `aid` CLI | Same list/remove ergonomics on both the Bash and PowerShell CLIs |

## 4. Scope

### In Scope

- `aid projects list`: prefix every project row with a 1-based sequential index (a new
  leading `#` column), in the exact order `_registry_read_raw_union` yields.
- `aid projects remove <N>`: accept an all-digits argument as a 1-based list index that
  resolves to the Nth project in that same list order and unregister it.
- Preserve `aid projects remove <path>` (path form) for a genuinely-registered path, and the
  all-digits-vs-path disambiguation rule between the two forms (see §5 FR-3, §8 A-1).
- Error handling for invalid/out-of-range numeric removal (`0`/`< 1`, `> count`, empty
  registry) and for an unregistered/nonexistent path, each exiting `2`.
- Twin parity across the Bash (`bin/aid`) and PowerShell (`bin/aid.ps1`) CLIs, and the
  usage/help text (`bin/aid:187-202`, `bin/aid.ps1:238`) and top-of-file synopsis comment
  (`bin/aid:19`). The npm/pypi packages regenerate their vendored copies from `bin/` at build
  time (`scripts/vendor.js` / `scripts/vendor.py`), so no manual re-sync is needed and those
  copies are out of scope.

### Out of Scope

- `aid projects add` behavior (a numeric index is meaningless for registering a new path).
- The registry storage format, tier resolution, `--local`/`--shared`/`--verbose` flags,
  and the `_registry_read_raw_union` ordering itself (consumed as-is, never re-ordered).
- The `(no projects registered)` empty-case text, the unregistered-cwd footnote, and the
  `* = current directory` legend (all unchanged).
- Any change to how removal is persisted (`registry_unregister` is reused unchanged).

## 5. Functional Requirements

- **FR-1 — Numbered list.** `aid projects list` MUST prefix every project row with a 1-based
  sequential index starting at 1 (the first-printed row is `1`), rendered as a new leading
  `#` column. The numbering order MUST be exactly the order `_registry_read_raw_union`
  yields (the order `list` already prints). The existing `*` current-directory marker MUST be
  preserved (readable layout: a `#` column plus the marker column), identical between the
  Bash and PowerShell twins.
- **FR-2 — Remove by number.** `aid projects remove <N>`, where `<N>` is an all-digits argument
  resolving to an in-range 1-based index (`1 <= N <= count`), MUST resolve to the Nth project in
  that same list order and unregister it (`aid projects remove 1` unregisters the first-listed
  project). Resolution reuses the same `_registry_read_raw_union` ordering that `list` numbers
  against.
- **FR-3 — Argument disambiguation (all-digits -> index; non-digit -> path).** `aid projects
  remove` MUST classify its single positional argument purely by shape. With **no argument** it
  defaults to cwd (unchanged). An **all-digits argument** (`^[0-9]+$`, a non-negative decimal
  integer) MUST be treated as a 1-based list index N — ALWAYS, never as a path, even when a
  folder of that literal name exists (a bare integer is never a folder). Leading-zero all-digit
  forms are parsed base-10 (`01` resolves to index 1; `008`/`009` are handled as decimal, never a
  bash octal literal). An argument that **contains any
  non-digit character** (`./1`, `C:/1`, `/abs/path`, `abc`, `1a`, `1.5`, `foo/bar`) MUST be
  treated as a path; to target a project whose folder is literally named with digits (e.g. `1`),
  the user gives the path form — `./1` or an absolute path. A `-`-prefixed token such as `-1`
  never reaches this classifier: `remove`'s arguments are swept past the dispatcher's own flag
  case by the action-match branch (`bin/aid:2907-2912`), so `-1` reaches `_cmd_projects` and is
  rejected by its unknown-flag case (`bin/aid:2466-2469`, PowerShell twin `bin/aid.ps1:1761-1764`)
  with exit 2 (see FR-4).
- **FR-4 — Removal error handling (numeric and path).** When the argument is classified as a
  1-based index (all-digits — FR-3), `aid projects remove <N>` MUST print a clear message to
  stderr, exit with code `2`, and leave the registry unchanged when:
  - `N < 1` (i.e. `0`, `00`) — the index must be a positive integer (`N >= 1`). Under the final
    rules `0` DOES reach the classifier, so this is a live, reachable case, not a
    defensive/unreachable guard.
  - `N > count`, including the empty-registry case (`count == 0`) — no project is numbered `N`
    (`M` registered).

  When the argument is classified as a path (contains a non-digit — FR-3) and does NOT
  canonicalize to a **currently-registered** project, `aid projects remove` MUST print a clear
  message to stderr and exit `2` — this REPLACES the former idempotent "not registered (nothing
  to remove)" no-op; an unregistered or nonexistent path is now an error. A negative-integer
  argument (`-1`, `-12`) errors via the existing unknown-flag rejection (exit 2): the action-match
  branch (`bin/aid:2907-2912`) sweeps `remove`'s args past the dispatcher's own flag case, so `-1`
  reaches `_cmd_projects` and is rejected by its unknown-flag case (`bin/aid:2466-2469`, PowerShell
  twin `bin/aid.ps1:1761-1764`) before the remove handler runs; the negative case is
  satisfied by that upstream path, not special-cased in the classifier. All of these are
  consistent with the command's existing exit-2 usage errors (`coding-standards.md § Exit
  Codes`, "2 usage").
- **FR-5 — `add` unaffected.** `aid projects add` MUST be unchanged; it registers a new path
  not yet in the list, for which a numeric index has no meaning.
- **FR-6 — Single source of truth for ordering.** The numbers shown by `list` and the numbers
  resolved by `remove <N>` MUST derive from the same ordering
  (`_registry_read_raw_union`); the two MUST never disagree for the same registry state.
- **FR-7 — Documentation + parity surface.** The change MUST update the `projects` usage/help
  text (`bin/aid:187-202`, `bin/aid.ps1:238`) and the top-of-file synopsis comment
  (`bin/aid:19`) to document `remove <N>` and the numbered list, and MUST rewrite the existing
  `remove` usage line (`bin/aid:198`, `bin/aid.ps1:249`) so it documents the `remove <N>` index
  form, the numeric errors, and that an unregistered/nonexistent path now errors — dropping the
  now-false "Idempotent"/"Works on stale/missing/no-aid entries" wording. It MUST keep the Bash
  and PowerShell twins behavior-identical. The npm/pypi packages regenerate their vendored copies
  from `bin/` at build time (`scripts/vendor.js` / `scripts/vendor.py`), so no manual re-sync of
  those copies is required and they are out of scope for this change.

## 6. Non-Functional Requirements

- **NFR-1 — Twin byte-parity.** Behavior MUST be identical across the Bash (`bin/aid`) and
  PowerShell (`bin/aid.ps1`) twins: same numbered-list layout, same `remove <N>` resolution,
  same error text/exit code. Enforced by `tests/canonical/test-aid-cli-parity.sh`
  (per `module-map.md` Invariants, the `bin/aid` <-> `bin/aid.ps1` language twins stay
  behavior-equal and must change in lockstep).
- **NFR-2 — Vendoring is build-time, not manual.** The only edit target is the canonical
  `bin/aid` + `bin/aid.ps1` twins. The npm and pypi packages regenerate their vendored copies of
  the CLI from `bin/` at package-build/pack time (`packages/npm/scripts/vendor.js`,
  `packages/pypi/scripts/vendor.py`), which produce gitignored, auto-generated artifacts — so no
  manual re-sync is required and the vendored copies are out of scope for this change (per
  `module-map.md` Invariants, `packages/*/_vendor/` must be regenerated, never hand-edited).

## 7. Constraints

- The change is confined to the `aid projects` command surface in the canonical `bin/` twins;
  it introduces no new dependency and does not alter the registry file format or tier
  resolution.

## 8. Assumptions & Dependencies

- **A-1 — Integer-vs-path disambiguation (settled).** `aid projects remove` decides between its
  two argument forms purely by shape, per the finalized rules:
  1. An **all-digits argument** (`^[0-9]+$`) is ALWAYS a 1-based list index — never a path, even
     if a folder of that literal name exists (a bare integer is never a folder). Leading-zero
     forms are parsed base-10 (`01` -> index 1; `008`/`009` are handled as decimal, never a bash
     octal literal).
  2. To target a project whose folder is literally named with digits (e.g. `1`), the user gives
     the **path form** — a relative `./1` or an absolute path. This is the documented way to
     reach such a folder, not an edge-case limitation.
  3. Out-of-range/invalid numeric arguments error (exit 2, registry unchanged): `N < 1` (`0`,
     `00`) and `N > count` (including the empty registry, `count == 0`) each print a clear
     stderr message. A negative integer (`-1`) errors via the dispatcher's existing unknown-flag
     rejection (exit 2) before the handler runs — negatives are NOT special-cased in the
     classifier.
  4. An argument containing any non-digit is a **path**; if it does not canonicalize to a
     currently-registered project it errors (exit 2) rather than performing the former
     idempotent no-op.

  The earlier quote-based disambiguation idea (a quoted `'1'` meaning folder `1`) is DROPPED and
  is not implementable: the shell strips quotes before `aid` runs, so `remove 1` and `remove '1'`
  deliver an identical argument. The `./1` path form is the escape hatch for a digit-named folder.
- **A-2 — Ordering is stable within a single invocation.** `_registry_read_raw_union` yields a
  deterministic order for a given registry state, so the number a user reads from `list`
  resolves to the same project when passed to `remove <N>` in the same registry state (§5
  FR-6). Concurrent registry mutation between a `list` and a later `remove` is out of scope
  (the same assumption the path form already makes).
- **D-1 — Reused helpers.** The change depends on the existing `_registry_read_raw_union`
  (ordering source) and `registry_unregister` (removal) and their PowerShell mirrors; it adds
  no new registry primitive.

## 9. Acceptance Criteria

- [ ] **AC-1 (numbered list).** Given at least one registered project, when `aid projects
  list` runs, then each project row is prefixed with a 1-based sequential number (the first
  row is `1`, incrementing by one) in `_registry_read_raw_union` order, and the `*`
  current-directory marker is still shown for the cwd row.
- [ ] **AC-2 (remove by number).** Given N registered projects, when `aid projects remove K`
  runs with an all-digits `K` in `1 <= K <= N`, then the Kth project in list order is
  unregistered and no other registry entry is changed.
- [ ] **AC-3 (path form preserved).** Given a registered project referenced by a path argument
  that contains a non-digit (e.g. `./name` or its absolute path), when `aid projects remove
  <path>` runs, then that path is unregistered exactly as the path form did before.
- [ ] **AC-4 (out-of-range index).** Given N registered projects (N >= 1), when `aid projects
  remove K` runs with an all-digits `K > N`, then a clear message is written to stderr, the
  command exits with code `2`, and the registry is unchanged.
- [ ] **AC-5 (empty registry).** Given no registered projects, when `aid projects remove 1`
  runs, then a clear message is written to stderr and the command exits with code `2` (the
  `N > count` case with `count == 0`).
- [ ] **AC-6 (single ordering).** Given a fixed registry state, when `aid projects list`
  numbers a project as `K` and `aid projects remove K` runs, then the project removed is the
  one `list` numbered `K` (both derive from `_registry_read_raw_union`).
- [ ] **AC-7 (`add` unaffected).** Given `aid projects add <path>`, when it runs, then its
  behavior and output are unchanged (no numeric-index handling introduced).
- [ ] **AC-8 (empty-case unchanged).** Given no registered projects, when `aid projects list`
  runs, then `(no projects registered)` is printed and no numbered rows appear.
- [ ] **AC-9 (twin parity + docs).** Given identical registry state, when the same `projects
  list` / `projects remove <N>` commands (including the error cases) run under the Bash and
  PowerShell twins, then the output and behavior are identical, and the usage/help text plus
  the synopsis comment document `remove <N>` and the numbered list on both twins, and the
  `remove` usage line no longer claims "Idempotent"/"works on stale/missing" but states that an
  unregistered/nonexistent path now errors.
- [ ] **AC-10 (index below 1).** Given any registry state, when `aid projects remove 0` (or
  `00`) runs — an all-digits value `< 1` — then a clear message ("index must be a positive
  integer, `>= 1`") is written to stderr, the command exits with code `2`, and the registry is
  unchanged.
- [ ] **AC-11 (negative via flag parser).** Given any registry state, when `aid projects remove
  -1` runs, then it is rejected upstream as an unknown flag with exit code `2` and the
  registry is unchanged (a `-`-prefixed token is never classified as an index).
- [ ] **AC-12 (unregistered path errors).** Given a path argument that contains a non-digit and
  does NOT canonicalize to a currently-registered project (e.g. `abc`), when `aid projects
  remove <path>` runs, then a clear message is written to stderr and the command exits with
  code `2` — this is now an error, not the former idempotent no-op.
- [ ] **AC-13 (digit-named folder via path form).** Given a registered project whose folder is
  literally named `1`, when `aid projects remove 1` runs it resolves as an index and never
  targets that folder, and when `aid projects remove ./1` (or the absolute path) runs it
  unregisters that folder-named project.

## 10. Priority

Must.

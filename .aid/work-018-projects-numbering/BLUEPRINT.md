# Delivery BLUEPRINT -- delivery-001: Numbered `aid projects` List with Remove-by-Number

> **Delivery:** delivery-001
> **Work:** work-018-projects-numbering
> **Created:** 2026-07-16

---

## Objective

Make `aid projects` drivable by list position instead of by full path. `aid projects list`
numbers every registered-project row from 1 in the exact order `_registry_read_raw_union`
yields, and `aid projects remove` gains a positive-integer form that resolves to the Nth listed
project and unregisters it. The existing `aid projects remove <path>` form is preserved, and
`aid projects add` is untouched. The delivery is scoped as one unit because the numbered `list`
(the source of the numbers) and the `remove <N>` resolution (the consumer of the numbers) share
a single ordering and must ship together, across both CLI twins (`bin/aid`, `bin/aid.ps1`).

## Scope

- `aid projects list`: add a leading 1-based `#` index column in `_registry_read_raw_union`
  order, preserving the `*` current-directory marker and the PATH/STATE/TOOLS/TIER columns
  (`bin/aid:2494`, `bin/aid.ps1:1604`).
- `aid projects remove`: classify an all-digits argument (`^[0-9]+$`) as a 1-based list index,
  parsed base-10 (Bash `10#`, PowerShell `[int]`) so leading-zero forms like `008`/`009` never
  trip bash's octal-literal error (in-range `1 <= N <= count` resolves against the same ordering;
  `0`/`< 1` and `> count`/empty registry error with exit 2); treat any argument containing a
  non-digit as a path (unregister a genuinely-registered path, error with exit 2 on an
  unregistered/nonexistent one); a negative argument is swept past the dispatcher's flag case by
  the action-match branch (`bin/aid:2907-2912`) and rejected as an unknown flag by `_cmd_projects`
  (`bin/aid:2466-2469`, PowerShell `bin/aid.ps1:1761-1764`).
- Invalid/out-of-range numeric removal (`0`/`< 1`, `> count`, empty registry) and an
  unregistered/nonexistent path: clear stderr message + exit code 2.
- Documentation: update the `projects` usage/help text (`bin/aid:187-202`, `bin/aid.ps1:238`)
  and the top-of-file synopsis comment (`bin/aid:19`) on both twins, and rewrite the existing
  `remove` usage line (`bin/aid:198`, `bin/aid.ps1:249`) so it documents the index form and the
  numeric/unregistered-path errors — dropping the now-false "Idempotent"/"works on stale/missing"
  wording.
- Twin parity: keep `bin/aid` and `bin/aid.ps1` behavior-identical. The npm/pypi packages
  regenerate their vendored copies from `bin/` at build time (`scripts/vendor.js` /
  `scripts/vendor.py`); those gitignored, auto-generated copies need no manual re-sync and are
  out of scope.
- Tests: extend the CLI parity + registry suites to cover numbered `list` and `remove <N>`.
- Covers REQUIREMENTS §5 FR-1..FR-7, §6 NFR-1..NFR-2, and SPEC AC-1..AC-13.

**Out of scope:** `aid projects add` behavior; the `registry.yml` storage format, tier
resolution, and the `_registry_read_raw_union` ordering itself (consumed as-is); the
`(no projects registered)` text, the unregistered-cwd footnote, and the `* = current directory`
legend (all unchanged); the `bin/aid.cmd` shim and all vendored copies under `packages/`
(gitignored, auto-regenerated from `bin/` at build time — no manual re-sync). A project whose
folder is literally named with digits is removed via
the path form (`./1` or an absolute path) — the documented behavior under §8 A-1, not an
out-of-scope limitation.

## Gate Criteria

- [x] `aid projects list` prefixes each project row with a 1-based sequential number (first row
  `1`) in `_registry_read_raw_union` order, with the `*` cwd marker preserved. *(SPEC AC-1)*
- [x] `aid projects remove K` for an all-digits `K` in `1 <= K <= N` unregisters the Kth listed
  project and changes no other registry entry. *(SPEC AC-2)*
- [x] `aid projects remove <path>` (argument containing a non-digit) that canonicalizes to a
  registered project unregisters that path exactly as before. *(SPEC AC-3)*
- [x] `aid projects remove K` with an all-digits `K > N` prints a clear stderr message, exits
  `2`, and leaves the registry unchanged. *(SPEC AC-4)*
- [x] `aid projects remove 1` against an empty registry prints a clear stderr message and exits
  `2`. *(SPEC AC-5)*
- [x] The number `list` shows for a project equals the number that `remove <N>` resolves to it
  (single `_registry_read_raw_union` ordering). *(SPEC AC-6)*
- [x] `aid projects add <path>` behavior and output are unchanged. *(SPEC AC-7)*
- [x] `aid projects list` on an empty registry prints `(no projects registered)` with no
  numbered rows. *(SPEC AC-8)*
- [x] The Bash and PowerShell twins produce identical output/behavior for `list` and
  `remove <N>` (including the error cases), both twins' usage/help + synopsis document
  `remove <N>` and the numbered list, and the `remove` usage line no longer claims
  "Idempotent"/"works on stale/missing" but states that an unregistered/nonexistent path now
  errors. *(SPEC AC-9)*
- [x] `aid projects remove 0` (or `00`) — an all-digits value `< 1` — prints a clear stderr
  message ("index must be `>= 1`"), exits `2`, and leaves the registry unchanged. *(SPEC AC-10)*
- [x] `aid projects remove -1` is rejected upstream as an unknown flag with exit `2`, the
  registry unchanged (never classified as an index). *(SPEC AC-11)*
- [x] `aid projects remove <path>` (argument containing a non-digit) that does NOT canonicalize
  to a registered project prints a clear stderr message and exits `2` — not the former
  idempotent no-op. *(SPEC AC-12)*
- [x] A project whose folder is literally named `1` is removed via the path form (`aid projects
  remove ./1` or its absolute path), while `aid projects remove 1` resolves as an index and
  never targets that folder. *(SPEC AC-13)*
- [x] All tasks in delivery-001 are Done or Canceled.
- [x] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Modify `aid projects` — numbered `list` and `remove <N>` (both twins) |
| task-002 | TEST | Test numbered `aid projects list` and `remove <N>` across both CLI twins |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-change-cli (change, artifact 'cli').

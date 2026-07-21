# Delivery BLUEPRINT -- delivery-001: Machine Scan to Discover and Register AID Projects

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md — the IMMUTABLE DEFINITION for this delivery of a
flattened single-delivery (Lite) work. It is not a state file; the delivery's mutable
lifecycle/gate state lives in the work-root `STATE.md` (`## Delivery Lifecycle` / `## Delivery
Gate`), not here.

> **Delivery:** delivery-001
> **Work:** work-019-discover-projects
> **Created:** 2026-07-21

---

## Objective

Deliver a new `aid` CLI subcommand (working name `aid projects scan`) that finds every folder
containing a `.aid/` directory on the machine and registers each in the project registry —
register-only, idempotent, and guardrailed — while reporting each project's version and never
modifying anything inside a discovered project. It ships in both CLI twins (`bin/aid` and
`bin/aid.ps1`), behavior-identical, and is proven by the cross-platform parity suite.

## Scope

In scope for this delivery (see SPEC.md `## Technical Specification`):

- The new subcommand in both twins: whole-machine default scope (fixed drives on Windows, `/`
  on Unix), `<root>` narrowing, `--depth`, `--dry-run`, `--include-network`/`--include-removable`,
  `--local`/`--shared`, `--verbose`, `-h`.
- Guardrails: unreadable-dir skip, heavy/cache pruning (basename-anywhere set) and OS/system-dir
  skip (root-only set) as two shared byte-identical name-sets, symlink-loop guard,
  network/removable exclusion by default, progress output, write-confinement to the registry only,
  and USER-tier forcing so a bulk scan never elevates.
- Reuse of the existing registration path and version reader (no schema or format change).
- Parity + guardrail test coverage in `tests/canonical/test-aid-cli-parity.sh`.
- Updated `aid projects -h` help text and user-facing docs.

**Out of scope:** updating/installing/migrating any discovered project (updates stay on-demand
via `aid update`); scaffolding a `.aid/` for a folder that has none; any registry/manifest
schema change; a remote/network crawl; changing the `aid-discover` SKILL or the "Discover"
pipeline phase.

## Gate Criteria

Each criterion is concrete and independently testable; it maps one SPEC.md Acceptance Criterion
onto a delivery gate check. The grade.sh pass uses these as the rubric.

- [ ] A folder with `.aid/` present is registered by the scan and appears in `aid projects list`,
  with no host tool installed and no file inside its `.aid/` changed (AC-1).
- [ ] With no `<root>`, the scan enumerates local FIXED drives only on Windows (network +
  removable excluded) and walks from `/` on Unix, and both twins classify drives identically (AC-2).
- [ ] `aid projects scan <root>` scans only that subtree; a non-directory `<root>` exits 2;
  `--depth <n>` bounds recursion and BOTH a non-integer and a negative `--depth` exit 2
  (`<n>` must be a non-negative integer), identically on both twins (AC-3).
- [ ] `--dry-run` prints the would-register list, leaves the target `registry.yml` byte-unchanged,
  and exits 0 (AC-4).
- [ ] An already-registered project is not duplicated and is reported as already-registered; a
  folder with no `.aid/` is neither scaffolded nor registered (AC-5).
- [ ] A discovered project's manifest version (with any `-beta.N` suffix) is reported verbatim, and
  a `.aid/` with no valid manifest is reported as `untracked` without error (AC-6).
- [ ] A completed scan reports newly-registered and already-registered counts plus one
  path+version+action line per project, and a long scan emits at least one progress line to
  stderr (AC-7).
- [ ] Over a fixture tree with an unreadable directory, a heavy/cache directory matched by basename
  at any depth (NFR-2), an OS/system-named directory at a scan root (skipped) plus the same name
  nested deeper as an ordinary subfolder (NOT pruned) (NFR-3), and a directory-symlink cycle, the
  scan skips the unreadable directory and continues, does not descend into the basename-matched
  heavy/cache directories, skips only the root-level OS/system directory while still discovering the
  project under the deeper same-named subfolder, and terminates (AC-8).
- [ ] Network and removable drives are excluded by default and included only with
  `--include-network` / `--include-removable` (AC-9).
- [ ] For the same fixture tree, `bin/aid` and `bin/aid.ps1` produce identical discovery/
  registration results and identical exit codes, no file under any project's `.aid/` is created or
  modified, and `tests/canonical/test-aid-cli-parity.sh` asserts it (AC-10).
- [ ] The subcommand exits 0 on completion and 2 on a usage error, prints result to stdout and
  diagnostics to stderr, and the PowerShell twin passes `ps51-compat-check.ps1` (AC-11).
- [ ] `aid projects -h` documents the new subcommand, its flags, and its default whole-machine
  scope with byte-identical user-visible text on both twins; every user-facing CLI doc that
  enumerates the `projects` actions lists the new action; `.aid/knowledge/release-tracking.md`
  `## Unreleased` carries a `[NEW]` entry; and the shipped name reflects the approval-gate
  confirmation across help, docs, and tests (AC-12).
- [ ] On a global install, a discovered project outside `$HOME` is auto-registered in the USER tier
  with no privilege elevation (no `sudo`/`_aid_priv_run` shared-dir probe) because scan forced the
  `--local` tier override; `--shared` takes the shared path exactly as `aid projects add --shared`,
  and both twins force/honor the tier identically (AC-13).
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement the scan subcommand in the Bash twin (`bin/aid`) |
| task-002 | IMPLEMENT | Mirror the scan subcommand in the PowerShell twin (`bin/aid.ps1`) |
| task-003 | TEST | Parity + guardrail coverage in `tests/canonical/test-aid-cli-parity.sh` |
| task-004 | DOCUMENT | Help text, user docs, and release-tracking entry |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-update-cli (change, artifact 'cli').

The two IMPLEMENT tasks are split as Bash-reference (task-001) then PowerShell-mirror (task-002),
matching the codebase's own "Mirror of bash …" twin relationship. Per the twin-parity convention
(`coding-standards.md § Conventions` — "change BOTH twins in the same commit"), both are expected
to land together in the delivery so parity is never split across a release; the split is a
decomposition of work, not a licence to ship one twin without the other. RESEARCH/DESIGN are folded
into the SPEC and into task-001's scope. The command name, flags, the two prune name-sets (heavy/cache
matched by basename anywhere vs. OS/system matched root-only), and the guardrails are settled in the
SPEC. Drive enumeration is now named for BOTH twins: the pwsh twin uses
`[System.IO.DriveInfo]::GetDrives()` natively, and the bash twin (which runs under Git-Bash/MSYS/Cygwin
on Windows) shells out to the always-present `powershell.exe` running that SAME classifier, so
classification is identical by construction. Concretising that bash shell-out is an explicit design
sub-step within task-001 (the reference twin), not a separate RESEARCH/DESIGN task — keeping this small,
well-scoped CLI change at four tasks.

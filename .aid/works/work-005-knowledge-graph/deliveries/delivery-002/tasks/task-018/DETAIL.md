# task-018: `scan-source.sh` traversal, exclusion filter and granularity cut

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-017

**Scope:**

- Create `canonical/aid/scripts/graph/scan-source.sh` and implement feature-004's Feature Flow
  **steps 1–4**. This is the **single** traversal of the project source in this work; feature-005
  consumes its streams and never re-walks, and
  `tests/canonical/test-graph-single-scanner.sh` (task-033) asserts no other file under
  `canonical/aid/scripts/graph/` contains a repository traversal.
  1. **Resolve the root** with `git rev-parse --show-toplevel`, as `kb-freshness-check.sh` does. Not
     a git repository -> exit 2 with an actionable message: Classes 1–3 depend on
     `git check-ignore` and `git check-attr`, so a non-git checkout cannot produce a reproducible
     exclusion set.
  2. **Collect candidate paths** with one `find` from the root carrying a directory-prune expression
     built the way `build-project-index.sh` builds `PRUNE_EXPR` (`.git`, `node_modules`, `profiles`,
     `.claude`, `.cursor`, `.codex`, `.agent`, `.aid`, `site/dist`, …), then `LC_ALL=C sort`. The
     prune set is the cheap, directory-shaped half of D4.
  3. **Apply the exclusion filter (D4) in class order**, through task-017's predicates, as **batched
     removals — one process per mechanism, never one per file**: a single
     `git check-ignore --stdin`, a single `git check-attr --stdin`, a single batched two-line `awk`
     for the `@generated` header predicate, one `case`-glob pass for `graph.ignore`; then the Class 4
     `.aid/` cut and the Class 5 allowlist. Removal-only, so the result is order-independent.
     Exclusions run **before** significance, so an excluded path can never qualify by any clause.
  4. **Apply the granularity cut (FR-23 / AC-16).** Collapse `canonical/skills/<name>/**` to the
     directory id `int:canonical/skills/<name>/` and `canonical/agents/<name>/**` to
     `int:canonical/agents/<name>/`, suppressing their member files. Every other node is file-level.
     No code path produces a `#` in an `int:` id.
- Batching is a correctness-of-runtime requirement, not a micro-optimisation:
  `build-project-index.sh` records per-file forks costing 0.5–1.8 s each under Windows Git Bash /
  MSYS and dominating its runtime, and this repository is authored on Windows.
- **Out of scope:** qualification, the `depended-upon` fixed point, the three output streams, and the
  single-writer `no-inferred-node` guard. Task-019 adds steps 5–8 to this same file and must not
  disturb this task's contents — the `scan-source.sh` serialisation is 018 -> 019.
- **Out of scope:** the predicates themselves (task-017); the miniature fixture repository and the
  suites (tasks 032, 033).
- Conventions: `set -euo pipefail`, because the script writes files and a failed step must abort;
  the `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop with `shift 2` per flag, unknown flag
  -> stderr + exit 2; `-h|--help` re-printing a slice of the header (the `sed -n '2,17p' "$0"` style
  `build-project-index.sh` uses); `LC_ALL=C` on every sort.

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/scan-source.sh` exists with `#!/usr/bin/env bash`,
      `set -euo pipefail`, a Purpose / Usage / Exit-codes header block, and `-h|--help` re-printing a
      slice of it.
- [ ] The root is resolved with `git rev-parse --show-toplevel`; a non-git checkout exits **2** with
      a message naming `git check-ignore` / `git check-attr` as the reason the scan cannot be
      reproducible there.
- [ ] Candidate collection is a **single** `find` from the root with a prune expression plus
      `LC_ALL=C sort`, and the prune set covers the directory-shaped half of D4.
- [ ] Every D4 mechanism runs as one batched process over a path list. Reading the script shows no
      `git check-ignore`, `git check-attr`, or content-predicate `awk` invocation inside a per-path
      loop.
- [ ] `git check-ignore` is invoked with `-c core.excludesFile=/dev/null`.
- [ ] Exclusions are removal-only and are applied **before** significance; running the filter classes
      in a different order yields the identical surviving set, and no excluded path can qualify by
      any clause.
- [ ] Class 1 removes `profiles/**`, `.claude/**`, `.cursor/**`, `.codex/**`, `.agent/**`,
      `.github/aid/**` (by subpath — `.github/` itself is **not** pruned wholesale, or the five
      `workflow` nodes would be lost), the gitignored `packages/` vendored copies, `site/dist/**`,
      `.aid/generated/**`, the `@generated`-header matches, and `linguist-generated` paths.
- [ ] The granularity cut collapses `canonical/skills/<name>/**` and `canonical/agents/<name>/**` to
      their directory ids and suppresses their member files; every other surviving path is
      file-level; **no emitted `int:` id contains a `#`**.
- [ ] `.claude/skills/generate-profile/**` survives Class 1 via the Class 5 allowlist, so the render
      plane's most load-bearing module is not hidden and no false "no gap" is manufactured for it.
- [ ] The script contains the only repository traversal under `canonical/aid/scripts/graph/`, so
      `tests/canonical/test-graph-single-scanner.sh` (task-033) passes.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into separate TEST tasks; the named suites land in **task-032** and **task-033**.
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.

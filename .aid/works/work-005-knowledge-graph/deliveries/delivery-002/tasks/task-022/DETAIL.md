# task-022: `derive-edges.sh` observation typing

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

**Depends on:** task-019, task-020

**Scope:**

- Create `canonical/aid/scripts/graph/derive-edges.sh` — feature-005's **pass 1b**, Feature Flow
  steps 5–6. This is the script that carries the whole of the feature-004 ÷ feature-005 seam:
  feature-004's scanner *emits* observations without typing them, and this script does **all** the
  typing.
- Read `.aid/.temp/graph/observations.tsv` (task-019's output). For each row: look
  `observation_kind` up in the edge-relation map by **sourcing**
  `canonical/aid/scripts/graph/edge-relation-map.sh` (task-020) rather than reimplementing its loader
  or its three fail-closed gates — task-021 sources the same library, and the shared carrier exists so
  the two consumers cannot drift — resolve `s2t` from the mapped relation,
  look `t2s` up as that relation's `inverse` via `rel_load_vocabulary`, and emit a feature-005 D1 row
  with `provenance = derived`, `class = 0`, and `observation` set to the observation's evidence
  anchor **verbatim**.
- An **unmapped kind appends to `candidates.tsv` and emits nothing.** There is no code path that
  emits a row with a blank or invented relation.
- The script performs **no traversal of its own**: it consumes the scanner's stream and re-reads no
  source file it was not handed. No `find` or `git ls-files` rooted at the repo root may appear in
  it — `tests/canonical/test-graph-single-scanner.sh` (task-033) asserts this, and a second walk
  would drift from feature-004's and the two would disagree about what exists.
- Record the one consequence worth stating: the `dependency` observation over
  `profiles/*/emission-manifest.jsonl` `src` -> `dst` pairs yields **no rows**, because every `dst`
  sits inside an excluded render tree (feature-004 D4 Class 1). The manifest's own `src` side is
  already covered by the `canonical/EMISSION-MANIFEST.md` declared carrier in pass 1a.
- **Out of scope:** the map file and its three load gates (task-020); the observations themselves and
  their resolution rules (task-019); the merge, ordering, render and self-validation
  (tasks 023, 024); the observation-typing and map-gate suite (task-037).
- Conventions: `set -euo pipefail`; the `while … case … shift 2` argument loop, unknown flag ->
  stderr + exit 2; a one-line `[derive] …` stderr summary; exit `0` / `1` / `2` per feature-005's
  scheme.

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/derive-edges.sh` exists with `#!/usr/bin/env bash`,
      `set -euo pipefail`, a Purpose / Usage / Exit-codes header, `-h|--help`, and a `[derive] …`
      one-line stderr summary.
- [ ] Every `observations.tsv` row whose `observation_kind` is mapped becomes exactly one D1 row
      stamped `derived` / `class = 0`, with `observation` carrying the observation's evidence anchor
      byte for byte.
- [ ] `t2s` is looked up as the mapped relation's `inverse` and is never chosen by this script, so
      feature-003's `V4 [REL-PAIR]` cannot fire on this writer's output; and because task-020's
      endpoint-legality gate already passed at load, the advisory `V12 [REL-ENDPOINT]` should not
      fire either.
- [ ] An unmapped `observation_kind` appends a `candidates.tsv` row and emits **no** row — there is
      no path to an untyped row, a blank relation, or an invented relation.
- [ ] One fixture per feature-004 D5 observation kind — `path-reference`, `invocation`, `dependency`,
      `include`, `convention` — produces the mapped relation pair, and the unmapped case produces a
      candidate. (The suite that runs these is task-037; this task's implementation must make each
      case reachable.)
- [ ] Both endpoints of every emitted row appear in `nodes.tsv` or `kb-nodes.tsv` — the closed-node-set
      rule holds for pass 1b as it does for pass 1a.
- [ ] The script contains no repository traversal and reads no source file other than the streams and
      template files it is handed, so `tests/canonical/test-graph-single-scanner.sh` (task-033)
      passes over it.
- [ ] No relation label appears in the script.
- [ ] The `profiles/*/emission-manifest.jsonl` `dependency` consequence is recorded in the script
      header, so a future reader does not treat the zero rows as a defect.
- [ ] Exit codes are `0` / `1` / `2` with feature-005's stated meanings; no new code is invented.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into a separate TEST task; the named suite lands in **task-037**
      (`test-derive-edges.sh`).
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.

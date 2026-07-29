# task-032: `test-source-enumeration.sh` and the miniature fixture repository

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

**Type:** TEST

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-019

**Scope:**

- Create `tests/canonical/test-source-enumeration.sh`, the suite feature-004's Layers table names
  for "per-clause qualification, per-class exclusion, the granularity cut, fixed-point settling,
  and byte-identical re-run on an unchanged fixture tree".
- Create the miniature fixture repository `tests/canonical/fixtures/graph/tree/` -- "a self-built
  miniature repository containing one instance of every exclusion class and one of every
  qualifier clause". Because `scan-source.sh` step 1 resolves its root with
  `git rev-parse --show-toplevel` and Classes 1-3 depend on `git check-ignore` and
  `git check-attr`, the suite must **materialise the fixture into a `mktemp -d` working
  directory and `git init` it** before scanning. The fixture is self-built and depends on no work
  folder's contents (A-6, and the project's transient-work-folder rule).
- Assertions, one group per mechanism feature-004 fixes:
  - **Per-clause qualification (D3).** One fixture artifact per `declared` carrier -- the
    `generated-files.txt` output path, the `shortcut-catalog.yml` row `name`, the
    `.aid/settings.yml` `knowledge.doc_set` entry, the `EMISSION-MANIFEST.md` "Asset Kinds" row, a
    KB doc's frontmatter `sources:` entry, a `.github/workflows/*.yml` command token, a
    `package.json` `bin`/`files` key, and `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob --
    and one per `derived` mechanism: convention membership, inbound reference count >= 1, and
    executable-header presence. Assert the resulting `qualifier` field is
    `entry-point` / `public-surface` / `depended-upon` / `named-unit` as the clause dictates, and
    that the `evidence` string is grep-recoverable against the fixture (paste it into `grep` and
    see what the scanner saw).
  - **First-match ordering.** A path qualified by more than one clause carries the
    **first-matching** clause in D3's evaluation order, with `declared` tried before `derived`, so
    the row is a pure function of disk state.
  - **Per-class exclusion (D4).** One instance of each of the five classes, each asserted absent
    from `nodes.tsv`: Class 1 (`profiles/**`, `.claude/**`, `.cursor/**`, `.codex/**`,
    `.agent/**`, `.github/aid/**`, `site/dist/**`, `.aid/generated/**`, a file whose first two
    lines carry `@generated` / `DO NOT EDIT` / `DO NOT MODIFY`, and a `linguist-generated`
    path); Class 2 (`linguist-vendored`, `**/node_modules/**`, `packages/*/_vendor/**`);
    Class 3 (`git check-ignore` with `-c core.excludesFile=/dev/null`, plus a `graph.ignore`
    glob from the fixture's own `.aid/settings.yml`); Class 4 (`.aid/**` excluded with the single
    `.aid/settings.yml` allowlist entry); Class 5 (`.claude/skills/generate-profile/**` allowed
    back in). Assert `.github/` itself is **not** pruned wholesale -- a fixture
    `.github/workflows/*.yml` node must survive while `.github/aid/**` is excluded.
  - **The `graph.ignore` comma limitation** is asserted as documented behaviour, not discovered:
    a pattern is a repo-relative glob matched with bash `case` semantics and may not contain a
    comma.
  - **Granularity cut (FR-23 / AC-16).** `canonical/skills/<name>/**` collapses to
    `int:canonical/skills/<name>/` and `canonical/agents/<name>/**` to
    `int:canonical/agents/<name>/`, with their member files suppressed; every other node is
    file-level; **no `node_id` contains a `#`**.
  - **Fixed-point settling (step 6).** A fixture chain where node A references B and B references
    C, with C qualifying only via `depended-upon` once B is qualified -- assert C is enumerated,
    proving the iteration reaches a fixed point rather than a single pass.
  - **Residue (step 7).** A fixture path matching no clause is absent from `nodes.tsv` and present
    in `candidates.tsv` with `drop_reason` `no-rule-match`; file existence alone never qualifies.
  - **Byte-identical re-run.** Two consecutive scans of the unchanged fixture tree produce
    byte-identical `nodes.tsv`, `observations.tsv` and `candidates.tsv`. Assert `LC_ALL=C`
    ordering and LF endings, and that no row carries a timestamp, an absolute path, a line
    number, or a file size.
  - **Exit contract and stderr summary.** `0` on a successful scan, `2` on a non-git checkout
    with an actionable message, and the one-line `[scan] N nodes, M observations, K candidates`
    stderr summary.
- Out of scope: the three seam and invariant suites `test-graph-single-scanner.sh`,
  `test-graph-node-partition.sh`, `test-graph-node-provenance.sh` (**task-033**); the scanner and
  the rules library themselves (tasks 017, 018, 019); the `graph.ignore` settings seed
  (task-013).
- Discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob with **no edit to
  `tests/run-all.sh`** (`test-landscape.md` "Glob discovery"). Sources `tests/lib/assert.sh` and
  uses the `ID + description` assertion-label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-source-enumeration.sh` exists, sources `tests/lib/assert.sh`, uses
      the `ID + description` label convention, and is discovered by `tests/run-all.sh` with no
      edit to that file.
- [ ] `tests/canonical/fixtures/graph/tree/` contains one instance of every D4 exclusion class
      (1-5) and one instance of every D3 qualifier clause, and the suite materialises it into a
      `mktemp -d` directory and `git init`s it before scanning.
- [ ] The fixture and the suite reference no path under `.aid/works/` (A-6).
- [ ] Each `declared` carrier and each `derived` mechanism has an assertion that the expected
      node is enumerated with the expected `qualifier` and a grep-recoverable `evidence` string.
- [ ] A multiply-qualified path is asserted to carry the first-matching clause in D3 order, with
      `declared` preferred over `derived`.
- [ ] Every D4 exclusion class has at least one assertion that its instance is absent from
      `nodes.tsv`; `.github/workflows/*.yml` survives while `.github/aid/**` does not; and
      `.claude/skills/generate-profile/**` is allowed back in.
- [ ] The granularity cut is asserted for both skill and agent directories, member files are
      asserted suppressed, and no `node_id` contains a `#`.
- [ ] The fixed-point assertion uses a two-hop reference chain and proves a node qualified only
      after another node's qualification is still enumerated.
- [ ] An unqualifiable fixture path is asserted present in `candidates.tsv` with `drop_reason`
      `no-rule-match` and absent from `nodes.tsv`.
- [ ] Two consecutive scans of the unchanged fixture produce byte-identical output for all three
      streams; the suite asserts LF endings and the absence of any timestamp, absolute path, line
      number, or file size.
- [ ] Exit `0` on a successful scan and exit `2` with an actionable message on a non-git
      checkout are both asserted, as is the `[scan] N nodes, M observations, K candidates`
      stderr line.
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; every sort in the suite pins `LC_ALL=C`; two runs of the suite itself agree.
- [ ] **Clean setup/teardown** -- every artifact is created under `mktemp -d` and removed on
      exit (including on failure, via `trap`); the suite leaves the working tree unmodified, and
      `git status --porcelain` is clean after it runs.
- [ ] **Every acceptance criterion from feature-004 that this suite carries is covered**:
      AC-16's exclusion and granularity halves, and FR-21's "file existence alone never
      qualifies" clause.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.

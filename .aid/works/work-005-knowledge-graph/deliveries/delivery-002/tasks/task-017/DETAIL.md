# task-017: `significance-rules.sh` qualification and exclusion predicates

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

**Depends on:** -- (none)

**Scope:**

- Create `canonical/aid/scripts/graph/significance-rules.sh`: a sourceable, side-effect-free-on-import
  library holding **one function per feature-004 D3 mechanism and one per D4 exclusion class**. The
  reason for the split from the scanner is stated in feature-004's Layers table: the scanner and its
  test suite must exercise the *same* code, not two readings of the rule. FR-24 is the
  highest-risk requirement in this work and this file is where it becomes mechanical.
- **D3 `declared` carriers — one predicate each**, returning the FR-21 qualifier and a
  grep-recoverable evidence string of the form D3's "Evidence string form" column specifies:
  `canonical/aid/templates/generated-files.txt`; `canonical/aid/templates/shortcut-catalog.yml`;
  `.aid/settings.yml` `knowledge.doc_set`; `canonical/EMISSION-MANIFEST.md` "Asset Kinds";
  a KB doc's frontmatter `sources:` list; `.github/workflows/*.yml`;
  `packages/npm/package.json` (`bin`, `files`) and `packages/pypi/pyproject.toml`;
  `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob.
- **D3 `derived` mechanisms — one predicate each**, exactly three and no more:
  convention membership (`canonical/skills/*/SKILL.md` -> the containing directory is a `skill`;
  `canonical/agents/*/AGENT.md` -> an `agent`; `canonical/aid/scripts/<area>/*` -> a `script`;
  `tests/canonical/test-*.sh` -> a `test-suite`); inbound reference count >= 1 (the
  `depended-upon` clause, whose settling pass lives in task-019); executable-header presence
  (`#!/usr/bin/env {bash,node,python3}`, or a `.ps1` carrying `#Requires -Version 5.1`), which
  yields `entry-point`.
- **D4 exclusion classes — one predicate each:** Class 1 generated/derived trees (including the
  two-line `@generated` / `DO NOT EDIT` / `DO NOT MODIFY` header predicate and
  `git check-attr linguist-generated`); Class 2 vendored (`linguist-vendored`,
  `**/node_modules/**`, `packages/*/_vendor/**`); Class 3 ignore-listed
  (`git -c core.excludesFile=/dev/null check-ignore --stdin`, **plus** `graph.ignore` resolved
  through `read-setting.sh`); Class 4 the `.aid/` partition with its single allowlist entry
  `.aid/settings.yml`; Class 5 the maintainer-tooling allowlist that pulls
  `.claude/skills/generate-profile/**` back in from Class 1.
- **Does NOT depend on task-013** *(corrected by owner 2026-07-28; an earlier draft of the task table
  had this edge).* Class 3's predicate reads `graph.ignore` via
  `read-setting.sh --path graph.ignore --default ''`, and that `--default ''` means an **absent
  section is not an error** — the predicate degrades to "no ignore list" rather than failing. So this
  task can be written and tested before task-013 seeds the section, and task-013 may land in parallel.
  Removing the edge takes the Q6 research decision (task-006) off the critical path of the entire
  enumeration and extraction spine (017 → 018 → 019 → 022 → 023/024), which is the largest chain in
  the work. The key's **path** (`graph.ignore`) is already fixed, so nothing here waits on Q6's
  outcome; only the seeded default value does.
- Once task-013 lands, this predicate must honour a populated `graph.ignore` with no change to its
  own code — that is the property the `--default ''` contract buys, and task-032 asserts it both ways.
- Class 3's `-c core.excludesFile=/dev/null` is load-bearing, not incidental: it neutralises the
  developer's global gitignore, which is what makes the exclusion set identical on every machine and
  therefore compatible with FR-32.
- **Out of scope: any repository traversal.** No `find` or `git ls-files` rooted at the repo root may
  appear in this file — `scan-source.sh` (tasks 018, 019) is the only file under
  `canonical/aid/scripts/graph/` allowed to contain one, and
  `tests/canonical/test-graph-single-scanner.sh` (task-033) enforces it. Predicates take paths (or a
  path list on stdin, for the batched mechanisms) and answer about them.
- **Out of scope:** the walk, the granularity cut, the fixed point, the three output streams and the
  single-writer guard (tasks 018, 019); the `kind` enum's use for grouping and gap phrasing
  (feature-006/007); the suites (tasks 032, 033).
- Conventions: `set -eu` for the sourceable library with no import-time side effects; settings read
  only through `read-setting.sh`, never a hand-parse of `settings.yml`; `LC_ALL=C` on every sort and
  comparison; batched processes, never per-file forks.

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/significance-rules.sh` exists, is sourceable with no import-time
      output, write, or `exit`, and carries a Purpose / Usage / Exit-codes header plus a `Provides:`
      index.
- [ ] There is exactly one function per D3 mechanism — the eight `declared` carriers and the three
      `derived` mechanisms — and exactly one per D4 class 1–5, each named so a reviewer can map it to
      its SPEC row without reading the body.
- [ ] Every qualification predicate returns both the FR-21 qualifier
      (`entry-point` / `public-surface` / `depended-upon` / `named-unit`) and a **grep-recoverable**
      evidence string in D3's stated form — a path plus a symbol, heading, glob, or matched literal.
      No evidence string contains a line number, a timestamp, an absolute path, or a file size.
- [ ] No predicate can yield `inferred`: every qualification returns `declared` or `derived` as its
      `evidence_provenance`, and the field has no third value. (The single-writer abort that makes
      this an enforced invariant rather than a convention lands in task-019.)
- [ ] Class 3 reads the ignore list **only** through
      `bash canonical/aid/scripts/config/read-setting.sh --path graph.ignore --default ''`; the file
      contains no hand-parse of `settings.yml`. Patterns match as repo-relative globs with bash
      `case` semantics, and a pattern containing a comma is rejected or documented as unsupported,
      per the resolver's comma-joined output.
- [ ] Class 3's `git check-ignore` invocation carries `-c core.excludesFile=/dev/null`, so a
      developer's global gitignore cannot change the exclusion set between machines.
- [ ] Class 4 excludes `.aid/**` with exactly one allowlist entry — `.aid/settings.yml` — so the
      `kb:` and `int:` node sets stay disjoint; Class 5 allow-lists
      `.claude/skills/generate-profile/**` back in from Class 1, because it is hand-authored
      maintainer tooling rather than a render of `canonical/`.
- [ ] `.aid/connectors/*.md` is **not** allow-listed (feature-004 Open Item 2 — recorded as the
      owner's to reopen, not this task's to decide).
- [ ] The file contains no repository traversal — no `find` or `git ls-files` rooted at the repo
      root — so `tests/canonical/test-graph-single-scanner.sh` (task-033) passes over it.
- [ ] Every batched mechanism (`check-ignore`, `check-attr`, the `@generated` header awk) is exposed
      as a predicate that takes a **path list**, never one that forks per file — the fork cost
      `build-project-index.sh` records at 0.5–1.8 s each under Windows Git Bash / MSYS is the reason.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into separate TEST tasks; the named suites land in **task-032**
      (`test-source-enumeration.sh`, per-clause qualification and per-class exclusion) and
      **task-033** (the three seam and invariant suites).
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`: shebang, header block,
      `set -eu`, stdout results / stderr diagnostics, `LC_ALL=C`, settings via `read-setting.sh`
      only) and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) —
      zero findings with Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline;
      it holds only the six accessibility NFRs.

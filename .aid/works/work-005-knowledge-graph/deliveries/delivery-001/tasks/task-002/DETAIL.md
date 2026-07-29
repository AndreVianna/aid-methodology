# task-002: `relation-vocabulary.yml` closed vocabulary and header contract block

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

**Type:** RESEARCH

**Source:** work-005-knowledge-graph -> delivery-001

**Depends on:** task-001

**Scope:**
- Execute feature-001's Feature Flow **Steps 5-7**. Two outputs, two homes: the vocabulary file
  under `canonical/`, and the report at
  `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/relation-vocabulary-report.md`.
- **Step 5 -- write the single source.** Author
  `canonical/aid/templates/graph/relation-vocabulary.yml` (a new `graph/` directory beside the
  existing `knowledge-summary/` and `kb-authoring/` template sets) from task-001's screened pair
  set and category set.
- **The file has exactly TWO top-level keys, in this order: `pairs:` then `categories:`.** No third
  top-level key may be added. The `coverage_bearing` reviewable subset lives in a **sibling file**
  beside this one and is authored later by task-045 (owner decision). This is not a style
  preference: the two-top-level-key parse contract is what `rel_load_vocabulary` (task-015) is
  written against, and task-015 is explicitly not asked to tolerate a third key. Adding
  `coverage_bearing:` here would also make a delivery-003 feature edit a delivery-001 artifact.
- **Entry shape**, exact and non-negotiable, because two loaders must agree byte-for-byte: each
  entry begins `  - relation: <value>` (two spaces, `- `, `relation` always first), with the
  remaining six keys one per physical line at four-space indent in the fixed order `inverse`,
  `symmetry`, `category`, `endpoint_kinds`, `passes`, `definition`. All seven keys present in every
  entry; a missing, unknown, duplicate or empty key is malformed. `definition` and each
  `endpoint_kinds` token are always double-quoted; `relation`/`inverse`/`symmetry`/`category` are
  plain lowercase tokens matching `[a-z][a-z0-9-]*`. `endpoint_kinds` and `passes` are non-empty
  **flow** sequences on one line. Enums are closed. No nesting below an entry's scalar/flow values,
  no anchors, aliases, merge keys, block scalars (`|`, `>`) or multiple documents (`---`). Entries
  sorted by `category` then `relation`; `categories:` sorted by name, each element a double-quoted
  `"<name>|<one-line meaning>"` scalar.
- **Header comment block** carrying the file's human face (P3 -- one file, both faces): the
  seven-key field contract, the enum values, the three worked examples, the addition process
  (feature-001 § How a proposed addition is reviewed), and the pointer naming the consumers.
- **Step 6 -- self-test the five properties by loading the file, not reading it:** closure,
  totality, involution, symmetric consistency (`symmetry: symmetric` iff `inverse == relation`, no
  third case), and category totality. The harness is throwaway and is **not committed**; the
  shipped loader is task-015's and the shipped validators are task-016's.
- **Step 7 -- demonstrate sufficiency** in the report: three worked `relationships.md` rows in the
  eight-column §5.2 shape -- one KB-to-KB, one KB-to-source, one KB-to-external -- each using only
  vocabulary terms in both relation columns, with free-text nuance confined to `Observation`. The
  KB-to-external row uses the Q4 synthetic fixture's keys (A-6). **Those keys are fixed by owner
  decision (2026-07-28) so this forward reference is resolvable**: the fixture registers
  `wcag-22-aa` and `idv-accessible-charts` as **resolvable**, and reserves `absent-source` as a
  deliberately **unresolvable** key for the negative case. This task's worked row therefore cites
  `ext:wcag-22-aa`. Task-035 (delivery-002) **must build its fixture with exactly these keys** rather
  than inventing its own — the two sides are checked against each other.
- **The vocabulary file is the single exception to delivery-001's no-product-code rule, and the
  delivery's only permanent artifact.** It is a declarative data catalog under
  `canonical/aid/templates/`, in the precedent class of `shortcut-catalog.yml` and `settings.yml` --
  explicitly **not** product code. Nothing else in this task may touch `canonical/`, `profiles/`,
  `tests/` or `.aid/knowledge/`.
- **Known and accepted consequence: delivery-001 does not render.** The manifest and install wiring
  for the new canonical file is feature-012's (task-044, delivery-002), so the render-drift gate is
  knowingly red from this task until task-044. Record it; do not fix it here, and do not add a
  render task to delivery-001.
- Out of scope: the loader `rel_load_vocabulary` (task-015); the `V3`/`V4`/`V12` validators
  (task-016); the `coverage_bearing` sibling file (task-045); the emission-manifest records and the
  full render (task-044); landing `artifact-schemas.md` / `domain-glossary.md` updates (task-095).

**Acceptance Criteria:**
- [ ] `canonical/aid/templates/graph/relation-vocabulary.yml` exists and has **exactly two**
      top-level keys, `pairs:` then `categories:`, in that order -- verified by listing every
      column-0 `key:` line in the file. No `coverage_bearing:` key and no other third key is present.
- [ ] **Loading** the file (not reading it) satisfies all five inverse-pair properties: closure
      (every `inverse` is some entry's `relation`), totality (exactly one `inverse` per entry),
      involution (`inverse(inverse(relation)) == relation`), symmetric consistency, and category
      totality (every entry carries exactly one `category`, and every `category` used appears in
      `categories:` with a one-line meaning).
- [ ] Every entry carries all seven keys, in the fixed order, at the specified indentation, and
      every clause of the restricted-YAML parse contract holds; entries are sorted by `category`
      then `relation` and `categories:` is sorted by name.
- [ ] Every entry declares `passes` as a non-empty subset of `declared`/`derived`/`inferred` and
      `endpoint_kinds` as a non-empty list of `<p>-><p>` tokens over `kb:`/`int:`/`ext:`, so
      feature-005 can apply both as fail-closed map-load-time gates (task-020) and feature-003 can
      emit the advisory `V12` `[REL-ENDPOINT]` `[LOW]` finding (task-016).
- [ ] The file contains **no install-relative path and no filename placeholder** anywhere -- in data
      or in comments. `.yml` is outside `render.py`'s `_TEXT_EXTENSIONS`, so neither
      `rewrite_install_paths` nor `substitute_filenames` runs on it and there is no `canonical/`
      directory in an installed profile for a path to resolve against. Worked-example ids in
      comments are written as illustrations, preferably drawn from paths that exist in an installed
      tree.
- [ ] The header comment block carries all five items: the seven-key field contract, the enum
      values, the three worked examples, the addition process, and the consumer pointer.
- [ ] Three worked `relationships.md` rows in the eight-column §5.2 shape appear in the report --
      one KB-to-KB, one KB-to-source, one KB-to-external -- each using only vocabulary terms in both
      relation columns; the KB-to-external row cites **`ext:wcag-22-aa`**, one of the two resolvable
      keys the Q4 fixture registers, because `.aid/knowledge/external-sources.md` has zero registered
      entries. The fixture's fixed key set is `wcag-22-aa` and `idv-accessible-charts` (resolvable)
      plus `absent-source` (deliberately unresolvable) — task-035 must match it exactly.
- [ ] The self-test harness is throwaway and uncommitted. `git status --porcelain` shows exactly one
      change under `canonical/` -- the new `relation-vocabulary.yml` -- plus the report under
      `.aid/works/work-005-knowledge-graph/`, and nothing under `profiles/`, `tests/` or
      `.aid/knowledge/`.
- [ ] The report records the known consequence that `profiles/` now lacks the five renders of this
      file and that the render-drift gate stays red until task-044 lands feature-012's wiring.
- [ ] Sources cited (RESEARCH default): every entry in the file traces to task-001's evidence base,
      and the report records the mapping.
- [ ] **"At least 2 alternatives compared" (RESEARCH default) is overridden here, and the reason is
      recorded in the report:** the category-axis comparison was discharged by task-001, and the
      carrier decision (`.yml` rather than Markdown, at this exact path) is an owner decision already
      recorded in feature-001's Change Log. This task authors the decided shape; it does not re-open
      either comparison.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.

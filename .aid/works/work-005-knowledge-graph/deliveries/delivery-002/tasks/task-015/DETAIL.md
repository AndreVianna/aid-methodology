# task-015: `rel_load_vocabulary` seven-key loader and cross-entry invariants

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

**Depends on:** task-002, task-014

**Scope:**

- Add `rel_load_vocabulary <file>` — feature-003 D9's eighth function — to the existing
  `canonical/aid/scripts/graph/relationship-schema.sh`, **without disturbing task-014's contents**.
  The `relationship-schema.sh` serialisation is 014 -> 015; this task appends one function and one
  `Provides:` entry and changes nothing else.
- Implement D4's restricted-YAML **awk state machine**: a single forward pass with one flush point;
  a four-space-indented `key: value` line belongs to the most recent `  - relation:` line; an entry
  ends at the next `  - relation:`, at `categories:`, or at end of file; comments (`#`) and blank
  lines are skipped anywhere; values are read as **opaque data**. This is the parser class
  `tests/canonical/test-catalog-dirs-parity.sh` already proves sufficient for a block sequence of
  flat mappings. It is deliberately **not** a `read-setting.sh` `lookup_list` reuse — that helper
  defers to `yq` for anything nested — and it acquires no YAML binary, which is what keeps the
  toolkit's zero-runtime-dependency posture.
- **The file has exactly two top-level keys — `pairs:` and `categories:` — and the loader must not
  be written to tolerate a third.** The `coverage_bearing` reviewable subset lives in a **sibling
  file** beside `relation-vocabulary.yml` (owner decision; task-045, delivery-003), precisely so this
  two-key parse contract stays intact and so a delivery-003 task never edits a delivery-001 artifact.
  A third top-level key is a malformed file.
- Validate all **seven** entry keys in fixed order, one key per physical line, against D4's value
  spaces — whether or not this feature consumes the key, because this loader is the single mechanical
  check on feature-001's output shape:
  `relation` (first key of every entry, `[a-z][a-z0-9-]*`, unique across `pairs:`), `inverse`
  (`[a-z][a-z0-9-]*`, must itself appear as some entry's `relation`), `symmetry`
  (`asymmetric` | `symmetric`), `category` (single-valued, declared in `categories:`),
  `endpoint_kinds` (one-line flow sequence of double-quoted `<p>-><p>` tokens over the D2 prefix
  set), `passes` (one-line flow sequence, non-empty subset of `declared`/`derived`/`inferred`),
  `definition` (double-quoted, one physical line, non-empty).
- Enforce the restricted subset rather than assuming it: no anchors, aliases, or merge keys; no
  multi-line block scalars (`|`, `>`); no second document (`---`); no nesting below an entry's
  scalar and flow values; `endpoint_kinds` and `passes` on one physical line each.
- Enforce every cross-entry invariant D4 names — these are file-level defects, never row findings:
  **closure** (every `inverse` is some entry's `relation`), **involution**
  (`inverse(inverse(r)) == r`), **symmetric consistency** (`symmetry == symmetric` iff
  `inverse == relation`, `asymmetric` iff not — no third case), **`relation` uniqueness**, and
  **category totality** (every `category` declared in `categories:`, and no `categories:` name
  declared twice).
- Expose the lookups the callers need: **membership** (a label is valid iff it is some entry's
  `relation` or `inverse` — V3), **pairing** (`(S2T, T2S)` valid iff some entry has
  `relation == S2T && inverse == T2S` **or** the mirror — V4, with a symmetric entry's
  `S2T == T2S` row accepted as valid rather than as a disagreement), `category` passed through
  untouched for feature-007/008's grouping, `endpoint_kinds` for V12, and `passes` for feature-005's
  map-load gates.
- Fail closed with **exit 2**, and only exit 2, on: absent file, absent `pairs:` key, a
  present-but-empty `pairs:`, any malformed entry, any restricted-subset violation, and any
  cross-entry invariant violation. Messages name the resolved absolute path, the entry's `relation`
  (or its ordinal, when `relation` is what is missing), and the offending key. The
  absent/empty case names feature-001 / task-002's
  `canonical/aid/templates/graph/relation-vocabulary.yml` as the blocking dependency — an absent
  vocabulary must halt validation, never silently pass every row.
- **Entry order is not enforced.** feature-001 sorts `pairs:` by `category` then `relation` as an
  authoring convention with no acceptance criterion behind it, and membership and pairing are
  order-free.
- **Out of scope:** task-014's seven functions — do not modify them; `validate-relationships.sh`
  (task-016); the vocabulary file's contents (task-002); the loader's one-fixture-per-rejection-class
  suite (task-034).

**Acceptance Criteria:**

- [ ] `rel_load_vocabulary` exists in `canonical/aid/scripts/graph/relationship-schema.sh`, and
      `git diff` shows task-014's seven functions unchanged — one function and one `Provides:` line
      are added and nothing else moves.
- [ ] The parser is an awk state machine over D4's restricted subset; the script acquires no YAML
      binary and invokes no `yq`.
- [ ] The loader reads **exactly two** top-level keys, `pairs:` and `categories:`, and exits 2 on a
      third — it is not written to tolerate a `coverage_bearing` key, which lives in a sibling file
      (task-045).
- [ ] All seven entry keys are validated against D4's value spaces, in the fixed order, one key per
      physical line. A missing key, a duplicate key, a key outside the seven, an empty value, or keys
      out of order each exits 2 with a message naming the resolved absolute path, the entry's
      `relation` (or its ordinal), and the offending key.
- [ ] Each restricted-subset violation exits 2: an anchor, an alias, a merge key, a `|` or `>` block
      scalar, a second `---` document, nesting below a scalar or flow value, and a multi-line
      `endpoint_kinds` or `passes`.
- [ ] Every cross-entry invariant is enforced and exits 2 on violation — closure, involution,
      symmetric consistency, `relation` uniqueness, category totality including a duplicated
      `categories:` name — and each is reported as a file-level defect, never as a row finding.
- [ ] Absent file, absent `pairs:`, and present-but-empty `pairs:` each exit 2 with a message naming
      task-002's `canonical/aid/templates/graph/relation-vocabulary.yml` as the blocking dependency.
      There is no code path on which a missing vocabulary yields a clean pass.
- [ ] Membership, pairing in either orientation, `category` passthrough, `endpoint_kinds` and
      `passes` lookups are all reachable by callers; a symmetric entry's `S2T == T2S` row resolves as
      **valid** on the strength of its `symmetry: symmetric` declaration, and an entry whose labels
      are self-inverse while `symmetry` says `asymmetric` (or the reverse) exits 2 so V4 never has to
      guess.
- [ ] Entry order is neither required nor checked.
- [ ] The only exit code the loader introduces is `2`; `0` / `1` / `2` retain the documented linter
      semantics and no new code is invented.
- [ ] No relation label appears anywhere under `canonical/aid/scripts/graph/` — provable by grep,
      per feature-003 D4's ownership proof.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — there is no unit-test vehicle for a shell library outside
      `tests/canonical/test-*.sh`; the named suite lands in **task-034**, which carries one fixture
      per rejection class (missing key, unknown key, duplicate key, empty value, keys out of order,
      enum violation, undeclared `category`, broken closure, broken involution, `symmetry`/`inverse`
      disagreement, absent file, empty `pairs:`).
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.

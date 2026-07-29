# task-012: Eleven `${SKILLS}` count surfaces reconciled to 112

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

**Type:** DOCUMENT

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-007

**Scope:**

- Move the eleven hand-written skill-count surfaces from 111 to **112**. These are exactly the
  assertions `tests/canonical/test-doc-counts.sh` parameterises on `${SKILLS}`, verified on the
  branch (`SKILLS=111` today; the suite passes 31/31):

  | File | Needle that must state the new count |
  |---|---|
  | `README.md` | `112 skills` |
  | `docs/repository-structure.md` | `112 skill definitions` |
  | `docs/aid-methodology.md` | `112 skill directories` |
  | `docs/glossary.md` | `112 skills total` |
  | `docs/diagram-content-reference.md` | `112 skills` |
  | `docs/install.md` | `` 112 `aid-`-prefixed skill `` |
  | `profiles/claude-code/README.md` | `112 skills` |
  | `profiles/codex/README.md` | `112 skills` |
  | `profiles/cursor/README.md` | `112 skills` |
  | `profiles/copilot-cli/README.md` | `112 skills` |
  | `profiles/antigravity/README.md` | `112 skills` |

- **The five `profiles/<tool>/README.md` files are hand-edited, and that is the declared exception,
  not a violation.** They live *inside* generated trees but are not emitted by the generator:
  `README` matches zero records in all five `emission-manifest.jsonl` files, and `render.py`'s
  `skills` branch emits only `SKILL.md` plus `references/*.md`. The pure-mirror boundary deletes only
  paths a previous manifest recorded, so they survive every render untouched. This is the real
  residue of the lockstep hazard and the concrete evidence behind tech-debt **L4**.
- **The proof is `bash tests/canonical/test-doc-counts.sh`, unmodified.** `SKILLS` is derived from
  disk, so the suite is the gate and needs no edit of its own — it is the closest thing this
  repository has to a documentation manifest.
- Depends on task-007 because `SKILLS` is derived from `canonical/skills/`: the count is only 112
  once `canonical/skills/aid-graph/` exists on disk.
- **Out of scope:** the site roster pair (task-010); the two re-anchored literal surfaces
  (task-011); and every **roster or prose** edit feature-013 makes at ship time to `README.md`,
  `docs/aid-methodology.md` and `docs/diagram-content-reference.md` (task-090). The 012/013 seam is
  count first, roster second, so `test-doc-counts.sh` gives a clean signal before prose lands on top.
- **Out of scope and flagged:** `docs/diagram-content-reference.md` also carries composition
  arithmetic and a roster-test sentence that no `${SKILLS}` assertion guards — "17 curated + 64
  shortcuts + 30 repurpose", "asserts 111 on-disk dirs = the 17 curated skill names ∪ all 94 catalog
  rows", and a `(111)` derived-command result. Those are feature-012 finding **U7** and belong to
  task-090's trigger edits; this task moves only the guarded needle and reports the rest.

**Acceptance Criteria:**

- [ ] All eleven files state 112 in the exact needle listed above — one needle per file, matching
      `tests/canonical/test-doc-counts.sh`'s assertion text character for character.
- [ ] `bash tests/canonical/test-doc-counts.sh` passes with the suite file **unmodified**:
      `git diff --exit-code -- tests/canonical/test-doc-counts.sh` is clean, and the run reports
      `SKILLS=112` with no surface left behind.
- [ ] `AGENTS`, `ROWS`, `CANON`, `ALIAS`, `REPURPOSE` and `SHORTCUTS` are unchanged and no assertion
      keyed on them is edited — `/aid-graph` is a curated hand-authored skill, not a
      `shortcut-catalog.yml` row.
- [ ] The five `profiles/<tool>/README.md` edits are recorded in review as the declared
      hand-maintained exception, with the verification behind it (zero `README` records across all
      five `emission-manifest.jsonl` files; `render.py`'s `skills` branch).
- [ ] The task hands task-044 the expectation that the FULL `run_generator.py` render leaves those
      five files untouched, so `git diff --exit-code -- profiles/` stays clean.
- [ ] No new hardcoded total is introduced: every edited needle is a surface `test-doc-counts.sh`
      already derives from disk, and no unguarded count literal is added anywhere (feature-012's
      derived-count criterion; tech-debt L4 measure 2).
- [ ] Accuracy verified against the current branch (DOCUMENT default): the derived count really is
      112 after task-007 —
      `find canonical/skills -mindepth 1 -maxdepth 1 -type d | wc -l` returns 112 (111 before) — and
      each of the eleven needles was located in its file before being edited.
- [ ] The unguarded `docs/diagram-content-reference.md` composition claims (U7) are left untouched
      and reported for task-090.
- [ ] The authoring baseline holds (`.aid/knowledge/authoring-conventions.md`), and the delivery
      gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.

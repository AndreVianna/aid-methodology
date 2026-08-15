# task-070: `INDEX.md` regenerated from the settled Knowledge Base

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-070/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-069

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §7's Knowledge Base table, row
  `INDEX.md` -- *"**Regenerated**, last of all: `bash canonical/aid/scripts/kb/build-kb-index.sh`"*. It
  closes the `INDEX.md` clause of BLUEPRINT criterion **9** (*"with `INDEX.md` regenerated after them
  and `kb.html` last of all"*).
- **It is a regeneration, never a hand-patch.** `INDEX.md` is a final-state summary of the Knowledge
  Base, not a source: refreshing it before the documents settle guarantees rework, and hand-editing it
  leaves a copy that is neither current nor reproducible. Every document it summarises -- including the
  two conditional documents delivery-001 created and the eight documents task-065 through task-067
  edited -- is final at this point.
- **The command, resolved against disk:** `bash canonical/aid/scripts/kb/build-kb-index.sh`, which is
  present in `canonical/aid/scripts/kb/` alongside the other thirteen KB helpers. Its own oracle is
  `tests/canonical/test-build-kb-index.sh`.
- **The resolved doc-set is 21 entries at this point, and the figure is derived rather than asserted.**
  `.aid/settings.yml` `knowledge.doc_set` held 19 entries before this work; delivery-001's `create`
  runs appended `roadmap.md` and `backlog.md` under CC-1 and CC-2, each with presence **`required`**.
  The regenerated index must cover exactly the resolved set, and the count is taken from
  `.aid/settings.yml` at run time, not from this file.
- **This task's write set is `INDEX.md` alone.** It reads the whole Knowledge Base and writes one
  summary of it; it neither creates nor registers a document, so `.aid/settings.yml` and
  `.aid/knowledge/README.md` must both come out unchanged -- CC-2 makes registration an effect of
  running a `create` skill, and no `create` skill runs here.
- **`relationships.md` and `graph.html` are not regenerated here.** They are `/aid-graph`'s outputs and
  delivery-001's task-019 owned them; this task is `build-kb-index.sh` only.
- Out of scope: `kb.html`, which is task-071's `/aid-summarize` re-run and is *last of all*; any
  Knowledge Base document's content (task-065 through task-067); the count guard (task-069); and
  `relationships.md` / `graph.html`.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 9's `INDEX.md` clause -- it was regenerated, not hand-patched.**
      `bash canonical/aid/scripts/kb/build-kb-index.sh` is run and the record names the command and its
      exit code; `git diff HEAD -- .aid/knowledge/INDEX.md` shows only changes the script produced,
      verified by re-running the script and getting a byte-identical file
- [ ] **The regeneration is idempotent**: run the script, capture `sha256sum .aid/knowledge/INDEX.md`,
      run it again, capture again, and the two captures match
- [ ] **The index covers exactly the resolved doc-set**, whose size is taken from `.aid/settings.yml`
      `knowledge.doc_set` at run time and recorded: the set of documents `INDEX.md` names and the set of
      `doc_set` entries agree, with `comm -3` over the two sorted lists **empty**. `roadmap.md` and
      `backlog.md` are both present, each registered `required` under CC-1
- [ ] **Its own oracle is green.** `bash tests/canonical/test-build-kb-index.sh` passes, and
      `git diff master -- tests/canonical/test-build-kb-index.sh` is **empty**
- [ ] **A regenerated summary line that states a count is reconciled in its source document.**
      `INDEX.md` is generated, so the generator is its oracle (`KB-03`) and it is never hand-fixed.
      The retired repo-wide count guard is not the oracle here and is not run: the surviving
      `tests/canonical/test-doc-counts.sh` **does not scan `.aid/knowledge/`** by design
      (`../../RESCOPE-COUNT-GUARD.md`), so any count a regenerated row surfaces is a `G-01` matter in
      the **summarised document**, and the record names the document and the verdict
- [ ] **No registration surface moved.** `git status --porcelain .aid/settings.yml
      .aid/knowledge/README.md` is clean -- no `create` skill runs here, so CC-2's registration path
      cannot have fired
- [ ] **Only `INDEX.md` moved.** `git diff --name-only HEAD -- .aid/knowledge/` lists exactly
      `INDEX.md`; `relationships.md`, `graph.html` and `kb.html` are all unchanged
- [ ] Accuracy verified against the current codebase: the script path and its oracle's assertion ids are
      re-resolved against the tree as it stands
- [ ] Nothing outside the declared write moves:
      `git diff --exit-code -- canonical/ tests/ site/ docs/ profiles/ .claude/ .cursor/` is clean
- [ ] All section-6 quality gates pass

# task-034: Normalise the table page -- Files tree, Concepts, Relations

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-034/STATE.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. Full mandate: `aid-execute/references/state-execute.md § MANDATORY:
> State-Write Protocol`.

**Type:** IMPLEMENT

**Source:** feature-009-accessible-table-view -> delivery-001 (Wave 4). Owner-directed,
2026-08-06, from reading the real rendered table.

**Depends on:** task-033 (the table-only page this task restructures)

---

## WHY THIS TASK EXISTS

The owner read the real table -- 3550 relationships over this repository's own Knowledge
Base -- and observed two things that turn out to be the same thing.

**First**, they wanted to stop seeing files that are not project source (tooling
directories, editor config, root metadata). That is being handled separately as a scan
exclusion rule, and the honest measured outcome is that it removes **71 rows of 3550, or
2%**. The table is not big because the scan is greedy. It is big because the project
really does have that many relationships.

**Second**, and this is the insight this task exists to act on, the owner proposed
splitting the page into a **Files** table and a **Relations** table, with each file's
properties shown once instead of on every row that mentions it. That is a normalisation
observation and the numbers support it strongly:

| | |
|---|---|
| relationship rows | 3550 |
| distinct nodes | 976 |
| cells describing nodes today | 14200 (kind + name, both ends, every row) |
| the same information listed once | 2008 |
| **duplication removed** | **86%** |

So the current ten-column table spends most of its cells restating node properties. A
node table plus an edge table says the same thing once. The owner's framing was exactly
right, and it also gives the checkbox surface they asked for ("a view somewhere with the
project structure that we could check or uncheck the files to be represented in the
graph") a natural home, because a file inventory is what that surface IS.

---

## THE NODE POPULATION, MEASURED -- and why there are three tables and not two

All 976 distinct nodes, by kind, from the live `relationships.md`:

| kind | count | has a path? | where it belongs |
|------|-------|-------------|------------------|
| `source-artifact` | 497 | yes | a node in the Files tree |
| `document` | 21 | yes (a KB file) | a node in the Files tree |
| `image` | 2 | yes | a node in the Files tree |
| `section` | 340 | no -- but it is INSIDE a document (`kb:README.md#change-log`) | nested under its document |
| `fact` | 84 | no -- also inside a document (`kb:architecture.md#fact:...`) | nested under its document |
| `concept` | 32 | **no, and it is inside nothing** (`kb:concept:aid-home`) | its own small table |

520 file-backed + 424 nested + 32 free-floating = 976. Every node has a home and none is
counted twice; that arithmetic is the completeness check for this task's design.

The 32 concepts are why this is three tables rather than two. A concept is a defined term,
not a location -- it has no path to sort into a tree and no document to nest under (a term
may be defined in several documents, which is precisely why the extraction emits it as its
own node). Putting concepts in the Files tree would require inventing a fake parent for
them. A 32-row flat table is smaller than any workaround, and unchecking a concept is the
single highest-leverage filter available, because concepts are the densest part of the
graph -- 820 relationship rows involve one.

---

## Scope

### A. Three tables on the table page

**A1. Files** -- the file-backed nodes as a collapsible tree.

- Folder structure shown by indentation with connecting lines, folders collapsible.
- One row per file, carrying that file's own properties: id, kind, name, provenance, and
  its coverage state (the same `kb-unbacked` / `artifact-undocumented` distinction the
  graph draws as a red or amber asterisk). These are the properties that currently repeat
  on every relationship row.
- Sections and facts nest UNDER their owning document, because their id already names it
  (`kb:<doc>#<slug>`). This is derived from the id, never from a new field.
- A checkbox per row. A folder's checkbox governs its subtree.

**A2. Concepts** -- the 32 concept nodes, flat, same property columns, same checkboxes.

**A3. Relations** -- the relationship rows, carrying ONLY relationship information:
source id, target id, both relation readings, provenance, observation. Node kind and node
name come out, because the Files and Concepts tables carry them now.

### B. What a checkbox means -- decided, and not negotiable within this task

**Unchecking HIDES a node from the view. It does NOT change the data.**

`relationships.md` is untouched, the coverage computation is untouched, and the gap
counts are untouched. The unchecked node disappears from the graph and from both tables.

**The owner chose this over "drop it from the data", and the reason is a measured one
from the same session.** Excluding a file that a KB document cites does not tidy the
graph -- it turns a satisfied claim into an UNBACKED one. Measured against the real file:
a blanket dot-path exclusion stripped every backing artifact from **32 of the 319 KB
claims that have any**, which would have surfaced as 32 new red gap badges caused
entirely by our own filter. A checkbox that silently did that would actively mislead the
reader about their own coverage. So the checkbox is a view control, and coverage
arithmetic stays a property of the data.

Consequence to honour, not to work around: the counts a lens reports must keep
distinguishing "hidden by the reader" from "not present". The page already states drawn
and hidden counts separately (`N nodes drawn, M hidden`); hidden-by-checkbox belongs in
the hidden count, not subtracted from the total.

### C. Persistence

- The selection survives a reload. That is the owner's stated purpose ("reduce the noise
  every time the graph is reload").
- Persist it per page origin, keyed so that two different projects' pages cannot read each
  other's selection.
- **A restore must never silently hide something the reader did not hide.** If a stored
  selection names ids that no longer exist (the extraction changed, files were renamed),
  drop those entries and keep the rest. If restoring would hide EVERYTHING, restore
  nothing and say so -- an empty graph that looks broken is worse than an unfiltered one.
- The graph page reads the same stored selection, because the owner's purpose is that the
  GRAPH is quieter on reload. The table page is where the selection is edited; the graph
  page consumes it.

### D. Reuse, and the seams that already exist

- The filter axes, the store, the lens and the notification path already exist in
  `graph-model.js` and `graph-controls.js`, and the table already re-renders from a
  projection on every lens change. A hidden-node set is another lens axis, not a new
  mechanism, and it must go through the same store so the graph and both tables cannot
  disagree.
- `graph-table.js` already implements the sort contract, the row-header semantics, the
  windowing (task-033) and the accessibility properties feature-009 was reviewed against.
  Extend it. Do not fork it.
- Windowing applies to the Relations table (3550 rows). The Files tree is 520 rows and the
  Concepts table is 32; neither needs a window, and adding one would be complexity with no
  failure mode behind it.

---

## What must NOT regress

- **The ten-column contract is NORMATIVE and this task changes it.** `TBL_COLUMNS.length`
  is read, never written as a literal, precisely so the count cannot drift by accident.
  Slimming the Relations table is therefore a **SPEC revision**, not an implementation
  tweak: revise feature-009's SPEC and the acceptance criteria that name ten columns, in
  the same change, and say in the SPEC why the columns moved rather than deleting the
  clause. A code change that leaves the SPEC saying ten is the failure mode this bullet
  exists to prevent.
- **Keyboard operability.** This page is the conforming alternate version for the graph
  (task-033). Every checkbox, every collapse toggle and the "Load more" button must be
  reachable and operable by keyboard alone, verified as such rather than merely present in
  the DOM. A tree that only opens on click is a regression on the one page that cannot
  afford one.
- **Screen-reader semantics of a tree.** Indentation and lines are presentation. The
  nesting must be conveyed structurally, and a collapsed folder's state must be
  announced -- the existing group toggles already carry `aria-expanded` and are the
  precedent to follow.
- `test-graph-table-view.sh` stays green, and gains assertions for the tree, the
  checkboxes, the persistence round-trip and the slimmed Relations columns.
- The single-module-scope rule: every declaration added to a view file carries that file's
  prefix. A duplicated top-level name is a SyntaxError that stops the whole page.
- The three defects fixed on the graph page's CSS stay fixed: no author `display` beating a
  `hidden` attribute, no sticky rule landing on a row header, no header offset measured
  against the wrong scroll container. `graph-css.css` documents all three at the
  relationship-table block; read it before writing tree CSS.

## Out of scope

- The scan exclusion rule (dot-path exclusions and their four carve-outs). Separate,
  in flight, and it changes the DATA where this task changes the VIEW.
- Any change to `relationships.md`'s format, to the extraction, or to the coverage
  computation. This task adds no field and removes none.
- The graph's own drawing performance (~70ms/frame at 976 nodes) and the aspect-blind
  force layout. Both are known, both are recorded, neither is this task.
- Fixing the KB citation defects this session surfaced (claims backed only by `CLAUDE.md`
  or `AGENTS.md`, and two KB documents citing a test fixture as evidence). Real, recorded,
  and not a table concern.

## Acceptance

1. The table page renders three tables from the real pipeline: a Files tree of the 520
   file-backed nodes with sections and facts nested under their documents, a Concepts
   table of the 32 concept nodes, and a Relations table of the relationship rows.
   The three populations partition the node set with no node missing and none duplicated
   -- assert that as arithmetic against the fixture, not by inspection.
2. The Relations table no longer carries node kind or node name, and the SPEC and its
   acceptance criteria are revised in the same change to match the new column set.
3. Unchecking a file hides it from both tables AND from the graph, while
   `relationships.md`, the coverage counts and the gap badges are provably unchanged --
   assert the coverage answer before and after are identical.
4. Unchecking a folder hides its whole subtree; re-checking restores exactly what was
   hidden and nothing else.
5. The selection survives a reload, and a stored selection naming ids that no longer exist
   restores the rest rather than failing or hiding the wrong things. A selection that
   would hide everything restores nothing and reports why.
6. Every checkbox and collapse toggle is operable by keyboard alone, verified by driving
   them, and a collapsed folder's state is exposed to assistive technology.
7. `test-graph-table-view.sh` is green and covers items 1, 3, 4, 5 and 6 with assertions
   shown to go red when the behaviour is broken.

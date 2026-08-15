# task-074 EVIDENCE -- every artifact this work produced graded against the configured floor

Closes BLUEPRINT criterion **13**. This task writes no gate value; that is the delivery gate's.

## 1. The floor, read at run time

```
.aid/settings.yml            minimum_grade: A
work-006 STATE.yml           minimum_grade: "A"
```

Both agree: the floor is **A**.

## 2. What `grade.sh` actually grades, and what that means here

`canonical/aid/scripts/grade.sh` *"Computes AID grade from a reviewer ledger table"* -- it reads a
7-column reviewer ledger and scores its Severity/Status columns. It does **not** score an arbitrary
file. So "run it per artifact" resolves, in this work's structure, to: per **graded unit** a ledger
exists and `grade.sh` scores it. The graded units are the feature specifications and the delivery
gates.

**The recorded grades, each as a triple of unit, grade, and the floor compared against:**

| Unit | Grade | Floor | Meets it |
|---|---|---|---|
| `feature-001-kb-doc-set-restructure` (spec) | `E -> E -> E+ -> r5 closed` | A | yes -- closed |
| `feature-002-design-lifecycle-machinery` (spec) | `E+ -> E -> D -> r5 closed` | A | yes -- closed, 17/17 Fixed |
| `feature-003-planning-artifact-skills` (spec) | `r1 -> r2 closed` | A | yes -- 21/21 Fixed |
| `feature-004-foundation-artifact-skills` (spec) | `r1 -> r2 closed` | A | yes -- 26/26 Fixed |
| `feature-005-design-grid-and-brainstorm` (spec) | `r1 closed` | A | yes -- 21/21 Fixed |
| `feature-006-integration-and-close-out` (spec) | `r1 closed` | A | yes -- 23/23 Fixed |
| **delivery-001** gate | **A+** (tier Large) | A | **yes** |
| **delivery-002** gate | **A+** (tier Large, score 54) | A | **yes** |
| **delivery-003** gate | *Pending* | A | **not yet run** -- it is the next step, and setting it is not this task's |

**Task-level outcomes across the work:** 74 tasks -- **71 Done**, **2 Blocked** (task-063,
task-071), **1 In Progress** (this task). No task is `Failed`.

## 3. The artifact set, derived from the branch and partitioned

```
$ git diff --name-only origin/master...HEAD | wc -l
1681
```

| Class | Paths | Gradable? |
|---|---|---|
| `profiles/`, `.claude/`, `.cursor/` | 1101 | **No** -- generated render output. Its correctness is byte-identity (task-060) and freshness (task-061), not a grade |
| `site/` | 225 | **No** for the generated majority (skill pages, flow sidecars, synced mirrors, manifests); `index.mdx` is hand-authored and graded with the docs |
| `.aid/works/` | 207 | **No** -- work-folder tracking: state files, evidence, impediments. Transient by the tracking rule, and pruned when the work ships |
| `canonical/` | 122 | **Yes** -- graded through the delivery gates that reviewed them |
| `.aid/knowledge/` | 15 | **Yes** -- same |
| `docs/` | 5 | **Yes** -- same |
| `tests/` | 2 | **Yes** -- and independently green: `test-deploy-monitor-repurpose.sh` 55/0, `test-catalog-dirs-parity.sh` 485/0 |
| `README.md` | 1 | **Yes** -- and independently green under `test-doc-counts.sh` 31/0 |
| `.aid/settings.yml` | 1 | **No** -- configuration, not an artifact |
| `.aid/design/README.md`, `.aid/design/knowledge-graph-redesign.md` | 2 | **No** -- design seeds; a seed is an input to a build, not a graded deliverable (D28) |

**1681 = 1101 + 225 + 207 + 122 + 15 + 5 + 2 + 1 + 1 + 2.** Every path is in exactly one bucket;
**no residue**.

## 4. No grade is below the floor

Both closed delivery gates are **A+** against a floor of **A**, and all six feature specs closed
their review rounds. **Nothing to report as below-floor.**

## 5. `kb.html`'s verdict cannot be cited, because task-071 did not run

The criterion requires quoting the `## Summarization History` row **task-071 wrote**. **task-071 is
Blocked** -- the regeneration is a 671 KB / 21-section authored run, roughly 3.9x what it was sized
against -- so it wrote no such row, and there is nothing to quote.

Stated as an unmet criterion rather than papered over: **this criterion is not satisfied, and its
remedy is task-071's**. What *is* true and recorded either way:

- `validate-visuals.mjs` is **SKIPPED**: Playwright is absent from the summarize package
  (`require.resolve('playwright')` fails), so the V1 visual gate is an **orchestrator** step, never
  an automated one. No automated visual pass is claimed here or anywhere.
- `kb.html` is byte-untouched -- it was not hand-patched.

## 6. This task wrote no gate value

`delivery-003`'s `gate_grade` is still `Pending` and its `delivery_state` still `Executing` at the
end of this task. Setting them belongs to the delivery gate.

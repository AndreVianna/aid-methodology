# task-072 EVIDENCE -- one whole-roster description sweep: mutual negative routing and triggering quality

Closes BLUEPRINT criterion **11**. **This task writes nothing** -- a finding here is reported, and
its fix belongs elsewhere.

## 1. The roster partition, re-derived from disk

```
curated directories with no catalog row : 17      (the DETAIL says 18)
rows with repurpose: true               : 60
rows without                            : 34
sum                                     : 111  ==  ls -1d canonical/skills/*/  ->  111   MATCH
```

The three strata sum correctly. The DETAIL's `18 + 60 + 34 -> 112` is the `aid-graph` off-by-one
task-050 established and logged for the delivery; **17 + 60 + 34 = 111**, and the guard's own
derivation in task-069 (`SKILLS=111`) agrees independently.

## 2. AC-12 check 1, over all 111 -- distribution, not just breaches

| | |
|---|---|
| over the 1024 cap | **0** |
| maximum | **944** (`aid-create-testing-strategy`) |
| median | **575** |
| mean | **547** |

Reporting the distribution is what makes a regression visible rather than only a breach: the
median sits at 56% of the cap, so the roster has headroom -- which is what AC-12's rationale
predicted, that the fix is a reallocation of the existing budget rather than an expansion.

## 3. AC-12 check 2, over the extracted description block

Asserted over the **description block**, never the whole file -- the bodies legitimately keep all
of these strings, and `test-catalog-dirs-parity.sh` depends on them doing so:

| Form | Count |
|---|---|
| `Direct-entry Lite-path shortcut` | **0** |
| `VERB=` | **0** |
| `ARTIFACT=` | **0** |
| arrow-separated transition sequence | **1** -- `aid-create-dashboard` |

**The one hit is reported, not fixed.** `aid-create-dashboard` is a *generated* doorway, so its
description leads with its catalog row's `intent`, which glosses the artifact as
`(source -> visualization -> publish/refresh)`. That is a **data flow**, not a state machine -- the
same ambiguity slice 3 resolved for the ADR, runbook, guideline and standard outlines by writing
them as prose, since no mechanical arrow check can tell the two apart. The fix is one edit to that
row's `intent` plus a regeneration, which is outside this task's declared writes (it writes
nothing) and was already logged by task-058.

## 4. The pair matrix -- per pair, per direction, with the neighbour and the file

The pair set was read at execution time from feature-004 §10 and feature-005 §7b/§7c, whose union
is what CC-9's ownership rule distributes. **Twelve mutual pairs, twenty-four cells, zero empty:**

| A | B | A names `/B` | B names `/A` | assigned by |
|---|---|---|---|---|
| `aid-research` | `aid-brainstorm` | yes | yes | FR-7 / f005 §7c |
| `aid-prototype-ui` | `aid-design-ui` | yes | yes | FR-6 / f005 §7b+c |
| `aid-design-document` | `aid-document` | yes | yes | f005 §7b+c |
| `aid-design-document` | `aid-create-document` | yes | yes | f005 §7b+c |
| `aid-design-test` | `aid-design-testing-strategy` | yes | yes | f005 §7c + f004 §10 |
| `aid-design-config` | `aid-design-stack` | yes | yes | f005 §7c + f004 §10 |
| `aid-design-infra` | `aid-design-cicd` | yes | yes | f005 §7c + f004 §10 |
| `aid-prototype` | `aid-design` | yes | yes | f005 §7a/b |
| `aid-create-architecture` | `aid-update-architecture` | yes | yes | f004 §10 *"each other"* |
| `aid-create-stack` | `aid-update-stack` | yes | yes | f004 §10 *"each other"* |
| `aid-create-testing-strategy` | `aid-update-testing-strategy` | yes | yes | f004 §10 *"each other"* |
| `aid-create-cicd` | `aid-update-cicd` | yes | yes | f004 §10 *"each other"* |

Every cell was read from the **YAML-parsed** description, not the raw block -- the oracle task-054
established after finding that a hyphen wrapped across a fold survives a raw grep but not the fold.

**A false-defect this sweep nearly reported.** A first pass modelled
`aid-design-<foundation>` <-> `aid-create-<foundation>` as four *mutual* pairs and reported **four
empty cells**. It is not mutual: feature-004 §10 assigns the `create` side to name *"each other ·
`/aid-document-<artifact>`"* and **not** the design side. So that direction is one-directional by
assignment, exactly like the fourteen grid rows, and reporting it as a defect would have been
wrong. Checked as such instead:

```
18 design rows naming their create counterpart:   18/18
create rows naming the design side:               only aid-create-document, which f005 §7b
                                                  explicitly assigns -- so assigned, not stray
```

**Reverse direction:** no description names a neighbour its tables do not assign. The single
`create -> design` occurrence is `aid-create-document -> /aid-design-document`, which feature-005
§7b assigns by name.

## 5. Two detector notes for whoever re-runs this

Both were logged by task-058 and both proved out here:

- **Match the directive, not the conjunction.** A `Use ... when` regex reports `aid-define` and
  `aid-monitor` as trigger-less. Both carry one, phrased with *once* and *after*/*whenever*, which
  is better English than a forced "when". 109 of 111 match the narrow pattern; **111 of 111** carry
  a trigger.
- **Read the folded value.** Every check above parses the YAML rather than grepping the block, for
  the reason in §4.

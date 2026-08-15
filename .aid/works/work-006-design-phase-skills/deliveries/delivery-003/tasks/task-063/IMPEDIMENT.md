# task-063 IMPEDIMENT -- the coverage baseline must be re-bootstrapped in CI, which this environment cannot do

**State: Blocked.** Nothing failed. The task requires a capability this environment does not have,
and the DETAIL already anticipates that: *"This is a hand-off, not a command."*

## 1. The blocker, precisely

The task's first acceptance criterion requires *"the `workflow_dispatch` run with `bootstrap:
true`, its run URL or id, and the `coverage-baseline` artifact it produced"*, and adds that **no
step of the capture may run on the authoring worktree**. Two independent reasons that cannot
happen here:

| Requirement | Status here |
|---|---|
| trigger `coverage-parity.yml` via `workflow_dispatch` | **not possible** -- the `gh` CLI in this environment is read-only and cannot create or modify resources, including workflow runs |
| `collect` needs `pwsh` + `node` + `python3` | `pwsh` **ABSENT**; `node v22.14.0` and `Python 3.12.3` present. `collect` would exit **3** (*required runtime absent*) |

The DETAIL attributes the local impossibility to *"the corpus hangs under the local Windows
shell"*. That reasoning does not apply here -- this is Linux -- but the conclusion is unchanged
for a different, verified reason: `pwsh` is simply not installed.

**Hand-editing the `.tsv` is not an available shortcut.** The runbook forbids it, and the reason
is structural: `.meta` is a provenance sidecar recording the capture commit, runner OS and the
three runtime versions, so a hand-edited `.tsv` desynchronises from its own record. The committed
baseline's header shows what happens when that rule is bent -- it carries a `# NOTE: hand-edited
when the aid-graph skill was removed, because no runtime-complete environment (pwsh) was
available`, which is the same corner, previously cut.

## 2. What *was* verified here, so the CI run has a predicted result to check against

The delta §4c predicts was measured against the live suite, using **the collector's own rule** --
`coverage-parity.sh:223` indexes only lines matching `^\s*(PASS|FAIL):`:

| key | committed baseline | after (measured) | delta |
|---|---|---|---|
| `CDP{i}a` | 59 | **95** | +36 |
| `CDP{i}b` | 59 | **95** | +36 |
| `CDP{i}c` | 59 | **95** | +36 |
| `CDP{i}d` | 58 | **94** | +36 |
| `CDP{i}e` | 34 | **34** | **0** |
| `CDP{i}f` | 34 | **34** | **0** |
| `CDP{i}g` | 34 | **34** | **0** |
| **total** | **337** | **481** | **+144** |

**Exactly the 144 rows and the unchanged `e`/`f`/`g` that §4c predicts.**

**The `e` class is the trap, and it was walked into once before being caught.** A first
measurement counted **94** `CDP{i}e` and would have reported the prediction as wrong. It is not:
a `repurpose: true` row emits `log "CDP{i}e ... exempted"` and `continue`s, and a `log` is neither
`PASS:` nor `FAIL:`, so the collector never indexes it. **60** such exemption lines exist and none
is collected. Counting raw output rather than collected output is the difference between a correct
report and a false one.

**The `e`/`f`/`g` figures are counts, not key identities.** Row insertion shifts every `CDP{i}`
index, so a `comm` over the two key sets legitimately reports both additions and removals among
them. A report claiming the key *sets* are identical would be false; the claim is that the three
*counts* are unmoved.

**The independent witness.** That unmoved 34 / 34 / 34 is a second confirmation, from the coverage
inventory rather than from `deriveSkillCounts`, that the `shortcuts` (emitting) quantity is still
**34**.

## 3. Preconditions this task owed its successors, all met

- **task-062 landed first**, which is the ordering reason this task exists here: `coverage-parity`
  fires on any `tests/**` change, and a baseline captured before task-062's edits would record the
  pre-edit corpus and go red on the next `tests/**` push. task-062 is committed.
- **Nothing was hand-edited.** `git diff --exit-code -- tests/coverage-baseline.tsv
  tests/coverage-baseline.meta` is clean; both files are exactly as inherited.
- **No secrets touched**: `.aid/connectors/.secrets/` unchanged.

## 4. The runbook, for whoever has CI access

From `.github/workflows/coverage-parity.yml`'s own header:

1. Run the `coverage-parity` lane via **`workflow_dispatch`** with **`bootstrap: true`**, on this
   work's branch.
2. Download the **`coverage-baseline`** artifact.
3. Commit **both** `tests/coverage-baseline.tsv` and `tests/coverage-baseline.meta` in **one**
   commit, and nothing else. The `.tsv` must be the artifact's bytes.
4. Confirm `.meta`'s `captured_utc`, `commit_sha`, `runner_os`, `pwsh_version`, `node_version` and
   `python3_version` all differ from the committed values, and that `commit_sha` resolves to a
   commit on this branch.
5. Check the new `.tsv` against the table in §2 -- `a`/`b`/`c` -> 95, `d` -> 94, `e`/`f`/`g` -> 34,
   and a **+144** line-count delta -- and that the `DMR` key count is **46**.
6. Confirm the lane exits **0** on a self-diff over the committed baseline.

Until step 3 lands, the `coverage-parity` lane is expected to be **red** on any `tests/**` push:
the workflow's *advisory* language applies only while the baseline file is absent, and it is
present.

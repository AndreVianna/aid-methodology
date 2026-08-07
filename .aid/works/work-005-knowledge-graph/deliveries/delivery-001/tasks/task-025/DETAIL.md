# task-025: feature-013's registration and discoverability suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-025/STATE.md.
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

**Type:** TEST

**Source:** feature-013-tests-and-docs -> delivery-001 (Wave 5)

**Depends on:** task-024

**Scope:**
- feature-013's `AC-T1` through `AC-T6`, over D1's derived discoverability surfaces.
- `AC-T1`/`AC-T2`: every hand-authored surface carrying an `/aid-summarize` roster slot checked **at
  slot granularity, not file granularity**, with placement asserted mechanically where the text
  decides it and read back where only a human can judge; any hand-authored file naming
  `/aid-summarize` that the SPEC has not classified fails **by name**, so the surface set cannot grow
  unnoticed.
- `AC-T3`: the diagram maintenance contract's skill-add trigger row, accurate for a **curated
  on-demand** skill.
- `AC-T4`/`AC-T5`: per-profile and dogfood set comparisons of shipped `aid-graph` files and shared
  graph scripts **against the set derived from `canonical/`** under the generator's own emission
  rules — never against another rendered tree and never against a manifest — with the canonical area
  asserted non-empty **first**, and the coverage predicate proven byte-identical to its canonical
  original.
- `AC-T6`: the generated per-skill-entry surfaces (site skill roster, synced methodology copy).
- **This is BLUEPRINT edge 7** — feature-013 asserts over every artifact the other twelve produce.

**Acceptance Criteria:**
- [ ] `AC-T1`'s by-name failure is real: an unclassified hand-authored file naming `/aid-summarize`
      turns the suite red, demonstrated with a temporary fixture
- [ ] **Every** hand-authored file that names `/aid-summarize` but **not** `/aid-graph` is
      **classified by name** — the set is **derived at execution time, never taken from this task as a
      literal**, because an earlier version of this criterion named "the three canonical templates"
      and that was a false universal: the set under `canonical/aid/templates/` alone is **thirteen**,
      and a repo-wide sweep returns more still — and how many more depends on which extensions the
      sweep admits, which is precisely why no count belongs here. Classifying three of thirteen would
      leave `AC-T1`'s clamp under-scoped by the very criterion meant to prove it bites.
      **Derivation (run it, do not trust this list):**
      `grep -rl 'aid-summarize' canonical/ docs/ README.md tests/ | while read -r f; do grep -q 'aid-graph' "$f" || echo "$f"; done`
      Each returned path is either a D1 class-4 exclusion **with its reason stated** or a real missing
      slot (and then filled). None is left silent
- [ ] `AC-T4`/`AC-T5` compare **sets**, not counts, and the comparison target is `canonical/` — a
      tree-against-tree or tree-against-manifest comparison is the L4 failure mode and is rejected
- [ ] The canonical script area is asserted **non-empty before** the set comparison, so an unbuilt
      area fails rather than trivially satisfying equality
- [ ] The coverage predicate's byte-identity across its two runtimes is asserted **with the
      precondition that makes the guarantee sound**, stated rather than assumed
- [ ] `AC-T6`'s generated surfaces each carry `/aid-graph` in the sibling's place, so a generation step
      that was never run fails here instead of shipping
- [ ] A `# COVERS:` manifest header; S1, S2, S4 honoured; S3 mutation cases behind `--self-mutate`;
      S5 proves the tree untouched
- [ ] Suite passes; total read from the script's own summary line
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass

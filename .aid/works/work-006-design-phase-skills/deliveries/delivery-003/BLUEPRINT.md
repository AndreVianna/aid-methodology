# Delivery BLUEPRINT -- delivery-003: Integration and Close-Out

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-003
> **Work:** work-006-design-phase-skills
> **Created:** 2026-08-09

---

## Objective

Everything that is an **aggregate over the finished set of thirty-six** — a directory
count, a row count, a byte-identity hash, a coverage inventory, a corpus guard, a
completeness sweep. Computed while deliveries 001 and 002 are still landing, each of these
produces a number that is correct for an hour and wrong afterwards, which is the whole
reason this delivery runs last rather than being distributed. It ends with AID's own
description of what it now has — the Knowledge Base, the methodology narrative, and the
generated summary that presents them (`kb.html`, rebuilt by re-running `/aid-summarize`)
— refreshed once, after the roster settles.

## Scope

- **feature-006-integration-and-close-out** — catalog validation; the build helper and the
  full render; both dogfood trees resynced and both byte-identity tuples green; the
  freshness oracle; the count-bearing surfaces (the guard, its `CLAIMS` extension, the
  replay, the eight catalog edit sites across two test files, and the
  `tests/coverage-baseline.tsv` re-bootstrap); the site card counts; the KB and methodology
  refresh; and the two closing sweeps.
- **The three stale count comments inside `canonical/aid/templates/shortcut-catalog.yml`**,
  handed here by delivery-001 and delivery-002 so three features do not collide on one file
  (feature-003 SPEC § *Verification*, V28). They are comments inside `canonical/`, so **no
  guard this delivery states can see them**: the surviving `tests/canonical/test-doc-counts.sh`
  scans only the public-facing docs and never `canonical/`, and the repo-wide count guard that
  once might have reached them was retired upstream (see `RESCOPE-COUNT-GUARD.md`). They are
  therefore reviewer-governed under criterion `G-01` and get their own criterion below — which
  is now the only thing that catches them.
- **The `kb.html` regeneration** — the final-state summary re-run, owned by feature-006
  § *KB and methodology refresh*.

**Out of scope:** writing a `release-tracking.md` version section: under the doctrine
delivery-001 installs, that file is purely historical and its version sections are written
at tag time by `release-aid`, from `backlog.md`, outside this work. Adding a template for
`roadmap.md` or `backlog.md`, which would move the seed off 14. **An automated visual gate
over the regenerated `kb.html`** — `validate-visuals.mjs` is SKIPPED because Playwright is
not installed in the summarize package, so V1 is an orchestrator step; this delivery does
not promise a gate that cannot run.

## Gate Criteria

- [ ] The catalog validates over the finished set: every row's `name` equals its directory
      name, `alias_of` is `null`, and hand-authored rows carry `repurpose: true`.
- [ ] `build-shortcut-skills.py` then the **full** `run_generator.py` — never a partial
      render — with both repo-root dogfood trees resynced from their profile sources
      (`.claude/` and `.cursor/`), and the byte-identity gate green over **both** tuples in
      all three directions.
- [ ] The render is provably **fresh**, not merely self-consistent: re-running the generator
      leaves `git diff -- profiles/` empty. This is the only oracle that can fail on a stale
      or partial render; byte-identity structurally cannot.
- [ ] Every count-bearing surface states **its own** new value — 112 directories, 94 catalog
      rows, 94 canonical names, 60 `repurpose` rows, 0 aliases — **and** the `shortcuts`
      (emitting) quantity is still 34 and untouched everywhere it is stated. The count guard
      exits 0 at its raised claim floor, and the stage-2 replay reports zero unclaimed
      occurrences of the old figures over the guard's own scanned trees.
- [ ] All eight catalog edit sites move together across the two test files: four assertions
      in `tests/canonical/test-deploy-monitor-repurpose.sh` — including the zero-alias
      assertion whose expected literal embeds the row total, and the `repurpose`
      decomposition message — plus the four comment blocks, two of them in
      `tests/canonical/test-catalog-dirs-parity.sh`, which is count-agnostic by design and
      whose assertions are **not** edited.
- [ ] The catalog's own three stale count comments are corrected, each against a count
      taken from the file rather than from this checkbox: the `repurpose` comment
      (`grep -c '^    repurpose: true$'` — `24` → `60`), the G4 create-family header
      (`grep -c '^  - name: aid-create'` — `16` → `23`) and the G5 update-family header
      (`grep -c '^  - name: aid-update'` — `15` → `22`). Stated explicitly because the
      first is reachable by the stage-2 replay and the **other two are reachable by no
      oracle in this delivery** — they are comments in phrasings no `CLAIMS` entry matches,
      carrying digits the replay does not scan.
- [ ] `tests/coverage-baseline.tsv` is **re-bootstrapped in CI** per the runbook (never
      hand-edited), `.tsv` and `.meta` committed together, the `coverage-parity` lane exits
      0, and the re-bootstrapped baseline still holds exactly 34 `CDP{i}e`, 34 `f` and 34
      `g` rows.
- [ ] The site needs no code change and proves it: `assignGroups` throws none of its four
      guards, and the published index holds exactly 22 cards in the `design` family and 1 in
      `brainstorm`.
- [ ] The KB and the methodology narrative describe the new family and state the new
      figures — capability inventory, architecture, module map, project structure, pipeline
      contracts, glossary, test landscape, decisions, tech-debt — with `INDEX.md`
      regenerated after them and `kb.html` last of all (its own criterion below), and the
      methodology Skill Inventory table and its independently hand-maintained site mirror
      both moved to a Total of 94. `tech-debt.md`'s W1-11 loses its `kb.html` half when
      that regeneration lands and stays open on its other survivor.
- [ ] `kb.html` is **regenerated, not hand-patched**: `/aid-summarize` is re-run after
      every other document in this delivery is final, `grep -c '75 skills'` and
      `grep -c '58-row'` over it are both `0` while `grep -c '34 verb-first'` is still
      `≥ 1`, the run's `section-manifest.txt` matches the resolved doc-set, and a new
      `## Summarization History` row in `.aid/knowledge/STATE.md` records the output and
      the **orchestrator-run** V1 verdict. Two things this criterion deliberately does not
      assert: an automated visual gate (Playwright is absent from the summarize package,
      so V1 is a human step) and a short runtime (the last full GENERATE took ~24 minutes —
      size it as its own task).
- [ ] The mutual-negative-routing sweep runs over the **complete** pair set and is reported
      per pair and per direction; a pair whose owning feature never wrote its side fails
      here as a defect.
- [ ] The pipeline is provably untouched: the `phase:` enum, the work/delivery/task
      hierarchy and the numbered sequence are unchanged in their defining files, **and** no
      new skill declares a `phase:`.
- [ ] Every artifact this work produced meets the configured minimum grade (`A`).
- [ ] All section-6 quality gates pass

## Tasks

Task numbering is GLOBAL across the work; delivery-003 holds task-050..task-074, continuing from
delivery-002's task-049 and completing the work at 74 tasks. **The numbering is allocation order,
not execution order** — the `Depends on:` field in each DETAIL.md, rendered as the execution graph
in `PLAN.md § Execution Graph`, is the sole authority on sequencing. Here the two coincide
exactly: ids were allocated in execution order, so delivery-003 contributes **no** edge from a
lower-numbered task to a higher-numbered one, and the partition of such edges in
`PLAN.md § Execution Graph` is unchanged by this delivery.

delivery-003 enters the graph through a single edge, `050 → 049` — delivery-002's leaf. That is
what makes every earlier task a transitive ancestor of every task here, and it is a real
read/write serialisation rather than a formality: task-050 validates the **finished** catalog and
the finished corpus, both of which delivery-002's last authoring tasks were still writing.

**delivery-003 is a total order.** Its twenty-five waves — 46 through 70 — hold one task each, so
there is no parallel group. The reason is in the resources, not in caution:
`build-shortcut-skills.py` walks the whole of `canonical/skills/` looking for orphaned generated
directories, every Knowledge Base authoring task reads the whole Knowledge Base to write one
document of it, and the confusable pairs the description slices must preserve cross slice
boundaries. `PLAN.md § delivery-003 / Execution Graph` states each of those with its source.

Each task has a full DETAIL.md at `tasks/task-NNN/DETAIL.md`.

| Task | Type | Title |
|------|------|-------|
| task-050 | TEST | Ninety-four catalog rows validated over the finished set |
| task-051 | IMPLEMENT | The generated doorway's description template -- one f-string, thirty-four doorways |
| task-052 | DOCUMENT | Nine curated pipeline and router descriptions given a trigger clause |
| task-053 | DOCUMENT | Nine curated on-demand descriptions, including the only two at or over the cap |
| task-054 | DOCUMENT | Twelve `document`-family and `query` descriptions |
| task-055 | DOCUMENT | Twelve collapse and kind-sibling descriptions, two of them suite-pinned |
| task-056 | DOCUMENT | Nine planning-artifact descriptions -- roadmap, backlog, mvp |
| task-057 | DOCUMENT | Twelve foundation-artifact descriptions -- architecture, stack, testing strategy, ci/cd |
| task-058 | DOCUMENT | Fifteen `design` grid and `/aid-brainstorm` descriptions |
| task-059 | DOCUMENT | The catalog's own three stale count comments, each re-derived from the file |
| task-060 | CONFIGURE | Build helper, full five-profile render, both dogfood trees resynced, byte-identity green |
| task-061 | TEST | The render proved fresh, which byte-identity structurally cannot do |
| task-062 | TEST | Eight catalog edit sites moved together across two test files |
| task-063 | CONFIGURE | The coverage baseline re-bootstrapped in CI, `.tsv` and `.meta` together |
| task-064 | CONFIGURE | The site's generated skill surface regenerated -- twenty-two design cards and one brainstorm |
| task-065 | DOCUMENT | Four "what AID has" Knowledge Base documents describe the design family |
| task-066 | DOCUMENT | Per-skill contracts, two glossary terms, and the two decisions this work made |
| task-067 | DOCUMENT | The test landscape and the tech-debt figures brought to the finished roster |
| task-068 | DOCUMENT | The methodology narrative, its Skill Inventory Total, and the four synced mirrors |
| task-069 | IMPLEMENT | The count guard extended, its two ratchets raised, and the replay driven to zero |
| task-070 | DOCUMENT | `INDEX.md` regenerated from the settled Knowledge Base |
| task-071 | DOCUMENT | `kb.html` regenerated by re-running `/aid-summarize`, with a recorded orchestrator V1 |
| task-072 | TEST | One whole-roster description sweep -- mutual negative routing and triggering quality |
| task-073 | TEST | The pipeline proved untouched -- three scoped diffs and the `phase:` grep |
| task-074 | TEST | Every artifact this work produced graded against the configured floor |

**Which task closes which gate criterion**, by the positional order of the checkboxes in § Gate
Criteria above. There are **fourteen** checkboxes: twelve substantive, then the standing grade-floor
row and the standing section-6 row. Criterion 14 is carried by every task's own final acceptance
criterion, which is why no single task is named against it.

| Criterion | Closed by |
|---|---|
| 1 — catalog validates over the finished set | task-050 |
| 2 — build helper, full render, both dogfood trees, byte-identity over both tuples | task-060 |
| 3 — the render is provably fresh | task-061 |
| 4 — every count-bearing surface at its own new value; guard exits 0 at the raised floor; replay to zero | task-069 closes it, over the per-file work of task-051, task-059, task-065, task-066, task-067 and task-068 |
| 5 — all eight catalog edit sites move together | task-062 |
| 6 — the catalog's own three stale count comments | task-059 |
| 7 — `coverage-baseline.tsv` re-bootstrapped in CI | task-063 |
| 8 — the site needs no code change and proves it | task-064 |
| 9 — the Knowledge Base and methodology narrative, `INDEX.md` after them | task-065, task-066, task-067, task-068, then task-070 for `INDEX.md`; `tech-debt.md`'s `W1-11` `kb.html` half closes in task-071 |
| 10 — `kb.html` regenerated, not hand-patched | task-071 |
| 11 — the mutual-negative-routing sweep over the complete pair set | task-072 |
| 12 — the pipeline is provably untouched | task-073 |
| 13 — every artifact meets the configured minimum grade | task-074 |
| 14 — all section-6 quality gates pass | every task, as its own last criterion |

**REQUIREMENTS AC-12** — the triggering-quality sweep over all 112 descriptions — has no gate
criterion of its own in this BLUEPRINT, because it was admitted to the work after this file was
written. It is authored by task-051 (the 34 generated, through one template edit) and task-052
through task-058 (the 78 hand-authored, in seven slices), and verified by task-072 **in the same
pass as criterion 11** — AC-12 and AC-8 are one sweep over one file set, which is what AC-12
itself requires. task-072 is therefore cited against both.

## Dependencies

- **Depends on:** delivery-002
- **Blocks:** -- (none)

## Notes

- Ordering inside this delivery is forced by data flow and should not be rearranged when
  tasks are cut: catalog validated → build helper → full render → dogfood resync (both
  trees) → byte-identity → render-drift → count surfaces (the catalog's three comments
  among them) → KB and methodology refresh → `INDEX.md` → **the `/aid-summarize` re-run
  that regenerates `kb.html`** → the two closing sweeps. The byte-identity → render-drift
  split is the subtlety: a consistently stale render passes the first and fails the second.
- **The `/aid-summarize` re-run is a task, not a step inside one.** It reads
  `.aid/knowledge/*.md`, so starting it before the KB refresh is final bakes in the
  pre-refresh figures; the last recorded full GENERATE took ~24 minutes; and its visual
  gate (V1) must be run by the orchestrator because Playwright is not installed in the
  summarize package. Budget it accordingly and record the run in
  `.aid/knowledge/STATE.md` § Summarization History like every prior one.
- **The coverage-baseline re-bootstrap is a hand-off, not a command.** It requires a
  runtime-complete Linux environment and cannot be run from this Windows worktree; it must
  be scheduled as its own task with a CI run rather than assumed. See cross-cutting risk 1
  in PLAN.md.
- **The most likely error mode here is over-application, not omission** — sweeping the
  `shortcuts` phrasings from 34. The negative oracle for that is part of the gate above and
  has a second, independent confirmation in the coverage baseline's unchanged `e`/`f`/`g`
  counts.
- feature-006's own spec records that this is the largest feature and names its split
  point if `/aid-detail` finds it oversized: the KB-and-methodology half, **not** the render
  half. The render half is comparable in size, not smaller, so a split must not be justified
  by that premise.
- Nothing lands on master before this delivery: the work merges as one pull request from a
  single `work-006` branch, which is what lets every count-bearing surface be deferred here.
  **The precondition is an action, not a property — open the PR only after this delivery
  closes.** `test.yml` and `coverage-parity.yml` both trigger on `pull_request` as well as
  on `push: branches: [master]`, and a `pull_request` trigger re-runs on every push to the
  PR head; a PR opened during delivery-001 therefore evaluates render-drift, byte-identity,
  the count guard and the coverage-parity lane against mid-flight states that are red by
  design. See the precondition paragraph in PLAN.md.

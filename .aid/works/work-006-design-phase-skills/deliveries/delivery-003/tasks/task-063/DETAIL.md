# task-063: The coverage baseline re-bootstrapped in CI, `.tsv` and `.meta` together

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-063/STATE.md.
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

**Type:** CONFIGURE

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-062

> **Count-guard re-scope (owner decision, 2026-08-14).** This DETAIL cites
> `tests/canonical/check-skill-counts.mjs`, which was **retired upstream** (deleted by
> work-004). Those citations are superseded by `../../RESCOPE-COUNT-GUARD.md`: public-facing
> doc counts are guarded by `tests/canonical/test-doc-counts.sh`, and counts inside
> `canonical/` / `.aid/knowledge/` are reviewer-governed under criterion `G-01`. Read that
> document before executing this task.

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §4c and its §10 row *Coverage
  inventory in parity*, plus PLAN.md cross-cutting risk 1. It closes BLUEPRINT criterion **7**.
- **It runs after task-062 for a reason, not for tidiness.** `.github/workflows/coverage-parity.yml`
  fires on any `tests/**` change (`:36-48`), and its `collect` step re-runs the whole canonical corpus
  to build the inventory. A baseline captured before task-062's edits would record the pre-edit corpus
  and the lane would go red on the very next `tests/**` push.
- **This is a hand-off, not a command.** `collect` needs a runtime-complete Linux environment (`pwsh`
  + `node` + `python3`) and the corpus hangs under the local Windows shell, which is why the baseline
  is captured in CI and never committed from an authoring worktree. The runbook is in the workflow's
  own header (`:22-30`): run the lane via `workflow_dispatch` with `bootstrap: true`, download the
  `coverage-baseline` artifact, and commit **both** `tests/coverage-baseline.tsv` and
  `tests/coverage-baseline.meta`. `.meta` is a provenance sidecar recording the capture commit, runner
  OS and the three runtime versions; hand-editing the `.tsv` would desynchronise it from that record.
- **The gate enforces today, so the default outcome of skipping this task is red.** The workflow
  header's *advisory* language (`:13-20`) applies only while the baseline file is **absent**, and it is
  present (`tests/coverage-baseline.tsv`, `tests/coverage-baseline.meta`). The exit-code contract is
  `0 clean | 1 parity violation | 2 usage | 3 required runtime absent`, with 1/2/3 surfacing as a job
  failure.
- **What the delta actually is, stated per key class so the report cannot claim the wrong thing.**
  `test-catalog-dirs-parity.sh` emits four per-row keys for every row -- `CDP{i}a` (directory exists),
  `CDP{i}b` (`aid-` prefix), `CDP{i}c` (`SKILL.md` exists), `CDP{i}d` (frontmatter `name` == directory
  == row) -- and three more, `CDP{i}e`/`f`/`g`, only for **non**-`repurpose` rows; a `repurpose: true`
  row logs `CDP{i}e` as an exemption and `continue`s (`:143-146`). The committed baseline holds 59 each
  of `a`/`b`/`c` (58 rows plus the `CDP00*` preflight), 58 `d`, and **34** each of `e`/`f`/`g`. After:
  95 / 95 / 95, 94, and **34** each. Net **144** new rows and **no** new `e`/`f`/`g` row.
- **The `e`/`f`/`g` claim is a claim about counts, not about key identity, and conflating the two would
  make this task's report wrong.** The key is the assertion-ID token -- `coverage-parity.sh`'s
  `normalize_key` step 2 (`:135-139`) returns the leading multi-letter ID and discards the message --
  so `CDP{i}e` is indexed by the row's **position** in the catalog. The thirty-six new rows land inside
  the G3, G4 and G5 sections rather than at end of file, so every row after the first insertion point
  shifts index, and the *set* of indices carrying `e`/`f`/`g` changes while its size stays 34. That is
  why the remedy is a wholesale re-bootstrap and not an accept-list, and why the assertion below is
  stated over the three **counts**.
- **The unchanged 34 is a second, independent witness for `shortcuts` = 34** -- reached from the
  coverage inventory rather than from `deriveSkillCounts`, so the two cannot fail together for a shared
  reason. If it moves, feature-006 §2 is wrong somewhere and that is the finding.
- **`DMR*` keys do not move**, and the same `normalize_key` rule is why: the baseline stores `DMR30`,
  not its message, so task-062's message edits cannot shift them. 46 before, 46 after.
- **feature-001 AC-3 is not violated by this write**, for the reason task-062 states once: AC-3's
  tree-scoped clean-diff over `tests/canonical/` is evaluated at feature-001's own close, and its
  substance is the seed-count suite set it enumerates -- none of which is touched here. This delivery's
  BLUEPRINT criterion 7 requires this write. `site/scripts/__tests__/` stays writer-free.
- Out of scope: hand-editing either file; `tests/canonical/check-skill-counts.mjs` (task-069);
  `tests/coverage-accepted-removals.tsv` and `tests/coverage-rehome-allowlist.tsv`, neither of which is
  the instrument for a corpus-wide delta; and running `collect` locally, which cannot work.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 7 -- the baseline was re-bootstrapped in CI, per the runbook.** The record
      names the `workflow_dispatch` run with `bootstrap: true`, its run URL or id, and the
      `coverage-baseline` artifact it produced. No step of the capture ran on the authoring worktree
- [ ] **Both files are committed together, in one commit.** `git show --name-only` for that commit
      lists `tests/coverage-baseline.tsv` and `tests/coverage-baseline.meta` and nothing else, and
      neither was hand-edited -- the `.tsv` is the artifact's bytes
- [ ] **`.meta` records the new capture.** Its `captured_utc`, `commit_sha`, `runner_os`,
      `pwsh_version`, `node_version` and `python3_version` fields all changed from the committed values
      and `commit_sha` resolves to a commit on this work's branch
- [ ] **The re-bootstrapped baseline holds the shape §4c predicts, asserted per key class.** Counting
      `CDP` keys by trailing letter over `tests/coverage-baseline.tsv` gives `a` -> `95`, `b` -> `95`,
      `c` -> `95`, `d` -> `94`, `e` -> `34`, `f` -> `34`, `g` -> `34`; and the `DMR` key count is `46`
- [ ] **The 144-row growth is asserted as a total too, so a per-class error cannot cancel out.** The
      new `.tsv` line count minus the committed one captured to a variable -> `144`
- [ ] **The three `e`/`f`/`g` figures are asserted as counts, never as key identity**, and the record
      says why: row insertion shifts `CDP{i}` indices, so a `comm` over the two key sets legitimately
      reports both additions and removals among them. A report claiming the key sets are identical
      would be false
- [ ] **The lane is green after the commit.** `coverage-parity` exits **0** on a run over the committed
      baseline -- a self-diff against the tree it was captured from -- and the record names that run
- [ ] **The independent witness is reported as such**: the unchanged 34 `e` / 34 `f` / 34 `g` is stated
      as a second confirmation of the `shortcuts` (emitting) quantity holding at 34, derived from the
      coverage inventory rather than from `deriveSkillCounts`
- [ ] **Configuration is idempotent**: re-running the diff step against the committed baseline changes
      nothing and exits 0, and no accept-list or re-home-allowlist row was added
- [ ] **No plaintext secrets**: nothing under `.aid/connectors/.secrets/` is created, modified or
      deleted, and the `.meta` provenance record carries no credential
- [ ] `git diff --name-only HEAD -- tests/` at the end of this task lists exactly the two baseline
      files, `git diff --exit-code -- site/scripts/__tests__/ canonical/ profiles/ .claude/ .cursor/`
      is clean, and `tests/canonical/check-skill-counts.mjs` is untouched
- [ ] All section-6 quality gates pass

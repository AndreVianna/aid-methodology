# task-039: Throwaway local dogfood render that makes the twenty-seven new skills invocable

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-039/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-038

**Scope:**
- Source: BLUEPRINT § Notes, *How the behavioral criteria above are exercised*. Gate criteria 4
  and 5 require **running** the new skills, but the render to the five profiles is deferred to
  delivery-003, so at this gate the twenty-seven skills exist only under `canonical/` and are
  invocable from no profile. The prescribed execution path is a **local render into the dogfood
  tree, run as a throwaway and not committed**, with
  `git status --porcelain profiles/ .claude/ .cursor/` clean again at the gate.
- **This task exists because that render is shared state, not per-task setup.** Every task that
  needs invocable skills is one of this task's descendants in the dependency graph, up to
  task-048; no list of them is kept here, because a list kept in two places drifts. Bundling the
  render into each consumer would (a) make any two of them unschedulable in parallel -- each
  render overwrites `profiles/` and `.claude/` wholesale and each revert wipes the other's -- and
  (b) multiply an expensive step by the number of consumers. Cut once, here: **exactly one**
  renderer, consumed read-only by its descendants, and **exactly one** reverter, task-048.
- Run, in this order (REQUIREMENTS C-5):
  `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`, then the **full**
  `run_generator.py` -- never a partial render -- then resync the dogfood `.claude/` from
  `profiles/claude-code/`.
- **`build-shortcut-skills.py` writes under `canonical/skills/`** (`:363-377` write
  `SKILLS_ROOT / name / "SKILL.md"` for every non-`repurpose` row), which is why this task
  declares that tree as a write rather than only reading it. All thirty-six rows this work adds
  are `repurpose: true`, so the helper must leave every one of the twenty-seven new bodies
  byte-identical; that is the **only** oracle for the `repurpose` field, which the parser does not
  enforce (`:354` reads it with `r.get("repurpose", False)`).
- **Record the pre-render state so task-048 can restore it, as content rather than as a commit:**
  the `git status --porcelain profiles/ .claude/ .cursor/` output (expected empty) and the
  `sha256sum` manifest of the three trees, written to this task's STATE.md notes. The HEAD sha is
  recorded as provenance only and is **never** a restoration target.
- **What the manifest is, and what it is not.** It records the *working tree* at this wave, and the
  restoration target it defines is *"tracked content equal to **current** `HEAD`, render-generated
  untracked files removed"* -- **not** "these exact bytes". The distinction is load-bearing because
  one tracked deliverable already lives inside these trees:
  `.claude/skills/release-aid/SKILL.md`, committed by delivery-001 (feature-001 AC-7/AC-8). It is
  named because it is the only committed artifact anywhere under the three trees, and it is a
  **path**, not a population. Restoring the manifest bytes literally would revert delivered work;
  restoring to current `HEAD` preserves it by construction and needs no enumeration to stay correct
  if a later pass adds a committer. The manifest's remaining job is a **cross-check**.
- **Every task that commits while this render is live stages explicit paths only.** The render sits
  uncommitted in `profiles/`, `.claude/` and `.cursor/` from this wave until task-048, so a
  `git add -A`, `git add .`, `git add -u` or `git commit -a` in any task inside the window would
  commit it, which BLUEPRINT § Notes and REQUIREMENTS C-5 forbid. Every task in the window carries
  the bound as its own acceptance criterion; this bullet is where the rule is stated once.
- **Nothing produced here is committed.** The rendered trees are working-tree state only, live for
  the duration of the waves this task gates, and are reverted by task-048 before the delivery gate.
  delivery-003 owns the committed render and runs it once against the settled canonical tree.
- Out of scope: committing any part of the render; editing `canonical/` beyond what the build helper
  itself rewrites (the twenty-seven bodies and their rows are already authored by task-026 through
  task-038); the byte-identity gate and the `coverage-parity` re-bootstrap, both delivery-003's; and
  every count-bearing assertion, `check-skill-counts.mjs` included -- its `MARKER_CAP` is `12`
  (`tests/canonical/check-skill-counts.mjs:319`) with no headroom, and touching it here would move a
  ratchet delivery-003 owns.

**Acceptance Criteria:**
- [ ] **feature-004 V3 and feature-005's `repurpose` half, at the point the render consumes the
      catalog:** `build-shortcut-skills.py` runs **first**, and afterwards
      `git diff --exit-code canonical/skills/aid-{design,create,update}-{architecture,stack,testing-strategy,cicd}/`
      and
      `git diff --exit-code canonical/skills/aid-design-{api,ui,theme,cli,data-model,data-pipeline,messaging,integration,job,config,infra,test,document,dashboard}/ canonical/skills/aid-brainstorm/`
      are both clean. A row that lost `repurpose: true` parses cleanly and is silently regenerated,
      and only this diff catches it
- [ ] The **full** `run_generator.py` is run, never a partial render (C-5), and the dogfood
      `.claude/` is resynced from `profiles/claude-code/` afterwards
- [ ] All twenty-seven new skills are present and invocable in the dogfood tree:
      `ls -d .claude/skills/aid-design-{api,ui,theme,cli,data-model,data-pipeline,messaging,integration,job,config,infra,test,document,dashboard} .claude/skills/aid-brainstorm .claude/skills/aid-{design,create,update}-{architecture,stack,testing-strategy,cicd}`
      returns 27 lines, exit 0
- [ ] **The engine edit reached every profile**, because task-047's comparison depends on it.
      `find profiles -path '*/aid/templates/shortcut-engine.md' | wc -l` captured to a variable ->
      `5`, and `grep -c '\.aid/design/{artifact}\.md'` captured per file -> `1` on each of the five:
      `profiles/claude-code/.claude/`, `profiles/codex/.codex/`, `profiles/cursor/.cursor/`,
      `profiles/copilot-cli/.github/` and `profiles/antigravity/.agent/`, each plus
      `aid/templates/shortcut-engine.md`. The profile path prefix is load-bearing -- three of the
      five bare root names do not exist at the repository root and a fourth is the GitHub config
      directory there. The resynced dogfood copy at `.claude/aid/templates/shortcut-engine.md`
      carries the same single hit
- [ ] **Configuration is idempotent**, evidenced by a command that can actually produce the
      evidence: capture
      `find profiles .claude .cursor -type f -print0 | sort -z | xargs -0 sha256sum` to a file,
      re-run `build-shortcut-skills.py` and the full `run_generator.py`, capture again, and `diff`
      the two captures -> empty. `git status --porcelain` is **not** the oracle here: it emits two
      status characters and a path per line and no content hash, so it cannot witness
      byte-identity
- [ ] **No plaintext secrets** are introduced: the render adds no file under
      `.aid/connectors/.secrets/` and no credential-bearing path
- [ ] The pre-render state is recorded in this task's STATE.md notes as **content** -- the
      pre-render `git status --porcelain profiles/ .claude/ .cursor/` output plus the `sha256sum`
      manifest of the three trees -- so task-048 can restore from that record without re-deriving
      it. The HEAD sha is provenance only and is **not** a restoration target
- [ ] The note recording the manifest **states the restoration target in words** -- tracked content
      equal to current `HEAD`, render-generated untracked files removed -- and names the one
      committed path that lies inside these trees, `.claude/skills/release-aid/SKILL.md`. A note
      that records only bytes hands task-048 an instruction that reverts delivered work
- [ ] Nothing is committed: `git diff --cached --name-only` is empty at the end of this task, and
      no count comment inside `canonical/aid/templates/shortcut-catalog.yml` is edited
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean -- the render touches
      neither tree, and `tests/coverage-baseline.tsv` is **not** re-bootstrapped here (that is a
      CI-only run owned by delivery-003)
- [ ] All section-6 quality gates pass

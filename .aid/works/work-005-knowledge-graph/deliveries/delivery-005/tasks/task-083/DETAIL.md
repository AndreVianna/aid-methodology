# task-083: Third-party renderer packaging gate

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

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-005, task-079

**Scope:**
- **Conditional. Firing condition:** this task fires **only if** delivery-001's
  rendering-approach decision record (task-005) actually adopted a third-party dependency. If the
  recommendation is hand-rolled, or vendored with no package manifest and no build step,
  feature-012 § D3's G1, G2, G3, G4 and G6 collapse to nothing and this task does not run. Read
  the decision record first; the trigger is that record, not a build-time judgement.
- If it fires, clear feature-012 § D3's gate conditions for whatever was adopted:
  - **G1 -- private and unpublished, inside the canonical script area.** The dependency is
    declared in a `private: true`, not-published dev/validator package under
    `canonical/aid/scripts/`, following the `canonical/aid/scripts/summarize/package.json`
    precedent. Never in `packages/npm/package.json` or `packages/pypi/pyproject.toml`, whose empty
    dependency sets keep the published wrappers supply-chain-light.
  - **G2 -- exact pin plus committed lockfile.** The version is pinned exactly (the precedent pins
    `"playwright": "1.61.1"`) and the lockfile is committed; provisioning is `npm ci`, never
    `npm install`.
  - **G3 -- `node_modules/` never ships.** Confirm `render.py`'s
    `_EXCLUDE_DIRS = frozenset({"node_modules", ".git"})` and `.gitignore` still cover it, so it
    appears in no profile tree and no emission manifest.
  - **G4 -- dependency monitoring.** `.github/dependabot.yml` gains an ecosystem entry for the new
    manifest directory; it currently tracks only `package-ecosystem: "github-actions"`, so a new
    npm manifest would otherwise go unmonitored.
  - **G5 -- licence and attribution recorded.** The licence text or SPDX id and the attribution
    the licence requires travel with the asset. A vendored library lives at
    `canonical/aid/templates/knowledge-graph/vendor/<name>/` carrying its upstream licence text
    verbatim alongside it.
  - **G6 -- Knowledge Base rows drafted, not landed.** Draft the `technology-stack.md`
    "Frameworks & Tooling" and "Key Dependencies" rows, the `infrastructure.md` build-step row in
    its render/build chain, and a `test-landscape.md` CI Lanes row if a lane is needed. These are
    **authored here and landed at ship time by task-095**; this task edits no file under
    `.aid/knowledge/`.
- **Out of scope:** G7, the graph preflight's actionable message when the toolchain is missing
  (feature-010's P5, task-026), and G8's recorded-prerequisite half -- both named in D3 so the
  gate reads complete, neither owned here. Also out of scope: the `S2 [N/A]` validation line
  (feature-011's contingency C1, task-076); the full profile render over any vendored tree
  (task-086); consuming the library in `graph-canvas.js` (tasks 079-082).

**Acceptance Criteria:**
- [ ] **If delivery-001's decision record did not adopt a third-party dependency, this task is a
      recorded no-op and the delivery gate records why**, citing the decision record. No manifest,
      lockfile or dependabot entry is created speculatively.
- [ ] Configuration is idempotent: re-running each packaging step changes no file.
- [ ] No plaintext secrets: no registry credential or token is committed.
- [ ] **G1** -- the manifest declares `"private": true`, is not published, and lives inside the
      canonical script area; `packages/npm/package.json` and `packages/pypi/pyproject.toml` still
      declare empty dependency sets.
- [ ] **G2** -- the dependency version is an exact pin and the lockfile is committed alongside it.
- [ ] **G3** -- `node_modules/` appears in no `profiles/<tool>/` tree and in no
      `emission-manifest.jsonl` record.
- [ ] **G4** -- `.github/dependabot.yml` carries an ecosystem entry for the new manifest
      directory.
- [ ] **G5** -- the licence text or SPDX id and the required attribution are committed beside the
      asset, and a vendored tree sits under
      `canonical/aid/templates/knowledge-graph/vendor/<name>/` with its upstream licence verbatim.
- [ ] **G6** -- the `technology-stack.md`, `infrastructure.md` and (if needed) `test-landscape.md`
      rows are drafted and handed to task-095, and **no file under `.aid/knowledge/` is edited by
      this task**.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).

# task-013: `gen:skills` threaded into the `prebuild`/`predev` chains

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-013. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-013/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-002 (feature-001-skill-detail-pages)

**Depends on:** task-012

**Scope:**
- Add `"gen:skills": "node scripts/gen-skills.mjs"` to `site/package.json` and insert `npm run gen:skills` into both existing chains, positioned **after `gen:reference`** and **before `fetch:release`**.
- The position is reasoned, not arbitrary: the two generators write disjoint outputs and neither reads the other's, so ordering is a diagnostics choice -- the older, better-understood drift error should be the first one a maintainer sees. `fetch:release` stays last because it reaches the network.
- This is the **only** edit to `site/package.json` in delivery-002, and it is purely additive. No dependency is added.
- This task also carries delivery-002's build-integration clause (a) verification, because it is the task that first makes `gen:skills` run inside a real `prebuild`.

**Acceptance Criteria:**
- [ ] `prebuild` and `predev` each run `gen:skills` after `gen:reference` and before `fetch:release`; exactly one `"prebuild"` key exists in the file.
- [ ] The four existing assertions in `gen-reference.test.mjs` over `prebuild` still pass: it contains `sync:docs`, contains `gen:reference`, contains `&&`, and the file has exactly one `"prebuild"` key.
- [ ] The edit is idempotent -- re-applying it adds no second script key and produces no further diff.
- [ ] `site/package.json` `dependencies` and `devDependencies` are both unmodified; no new dependency is introduced.
- [ ] No secret, token or credential appears in plaintext.
- [ ] **Build-integration clause (a):** a full `npm run prebuild` leaves `site/scripts/gen-reference.mjs` byte-unmodified, its throw-on-drift guard passing, and its four generated `reference/*.md` pages plus `site/scripts/.reference-manifest.json` byte-unchanged.
- [ ] `npm run prebuild` exits 0 on a clean checkout and produces one page per directory under `canonical/skills/`.
- [ ] All section-6 quality gates pass

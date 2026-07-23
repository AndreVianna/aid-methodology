# task-013: Terminal render (canonical -> 5 profiles) + dogfood resync

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

**Source:** work-023-ticket-integration -> delivery-003

**Depends on:** task-011

**Scope:**
- **R1 completeness check (BEFORE rendering; feature-005 §Feature-Flow (b) step 1; PLAN.md R1):** confirm every canonical edit from features 001-004 has landed -- the 3 new skills + shared `ticket-resolution.md` (task-001..004); the six PM-TOOL retractions (task-006); the rerouted read/comment seams + the aid-execute mirror removal + the aid-plan Step 4c split (task-007/008); the revised `consumption-protocol.md` (task-009) -- PLUS this delivery's `document-expectations.md` edit (task-011). A canonical edit missed at render time ships un-rendered.
- Run the FULL generator ONCE: `python .claude/skills/generate-profile/scripts/run_generator.py`. It renders `canonical/` into all five `profiles/*` trees (`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`), rewrites each `emission-manifest.jsonl`, and runs its own VERIFY (deterministic) byte-compare gate. Do NOT use a per-script renderer (render-drift fails on stale emission manifests); do NOT hand-edit `profiles/*` or the generator.
- Resync the dogfood `.claude/`: copy the freshly-rendered `profiles/claude-code/.claude/` tree over the repo-root `.claude/` (the install-path copy content, `lib/aid-install-core.sh`). The generator writes only `profiles/*` -- it does NOT touch the repo-root `.claude/`, so this is an explicit separate step. There is no repo-root `setup.sh`.
- This CONFIGURE task is the ONLY place that writes render outputs (`profiles/*`, dogfood `.claude/`); it makes NO `canonical/` source edit. The KB doc (task-012) is NOT rendered and is not an input to the render.

**Acceptance Criteria:**
- [ ] R1 completeness confirmed before the render: all features-001-004 canonical edits + the `document-expectations.md` edit are present in `canonical/` (feature-005 §Feature-Flow (b) step 1).
- [ ] The FULL `run_generator.py` runs once and renders `canonical/` into all five `profiles/*` trees, rewrites each `emission-manifest.jsonl`, and passes its own VERIFY (AC-12).
- [ ] The dogfood `.claude/` is resynced from `profiles/claude-code/.claude/`; the three `aid-*-ticket` skills and every features-001-004 edit are present in each of the 5 profiles and the dogfood tree.
- [ ] Configuration is idempotent (a second `run_generator.py` produces no `profiles/` diff) and introduces no plaintext secrets; `profiles/*` and the generator are not hand-edited.
- [ ] Only render outputs (`profiles/*`, dogfood `.claude/`) are written by this task -- no `canonical/` source edit here.
- [ ] All section-6 quality gates pass.

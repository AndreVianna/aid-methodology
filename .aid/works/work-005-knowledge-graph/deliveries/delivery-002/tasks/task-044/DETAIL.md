# task-044: Full profile render and render-drift confirmation for delivery-002

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

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-008, task-009, task-013, task-016, task-019, task-024, task-025, task-028, task-029, task-030, task-031

**Scope:**

- The **render barrier** for delivery-002. Every canonical artifact this delivery authors --
  `canonical/skills/aid-graph/` (`SKILL.md`, `README.md`, `references/agent-pass.md`, the nine
  `references/state-*.md` bodies), `canonical/aid/scripts/graph/*` (the schema library, the
  validator, the significance rules, the scanner, the three extraction scripts, the preflight,
  the staleness check, the write fence, the rubric orchestrator), and
  `canonical/aid/templates/graph/*` plus the amended
  `canonical/aid/templates/settings.yml` -- must be rendered into the five profile trees before
  the delivery can close. This task runs the render and proves it is complete and stable.
- **Run the FULL generator. Never a per-script renderer:**
  ```bash
  python .claude/skills/generate-profile/scripts/run_generator.py
  ```
  `.aid/knowledge/tech-debt.md` Gotchas is explicit -- "Render-drift needs the FULL generator …
  otherwise the render-drift gate fails on stale `profiles/` emission manifests". The full run
  renders all five trees, rewrites all five emission manifests, performs the manifest
  diff/deletion pass, and runs the verify spine.
- **Then confirm no render drift** with the documented command, whose two halves are deliberate:
  ```bash
  python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/
  ```
  A second render over an already-rendered tree must produce **byte-identical** output, so the
  command proves both that `profiles/` matches `canonical/` and that the render is stable.
- **All five emission manifests move together.**
  `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/emission-manifest.jsonl` are
  rewritten in the same run; a manifest left behind is the exact shape of the `[HIGH]`-severity
  lockstep debt item **L4** this delivery touches. None may be hand-edited.
- **This is the task that turns the knowingly-red render-drift gate green.** By owner decision
  delivery-001 does not render, so the gate is red from task-002 until this task. Record that
  transition in the delivery evidence.
- Two renderer facts worth confirming rather than assuming, because `/aid-graph` is the first
  skill of its shape:
  - `canonical/aid/scripts/` is a recognised asset kind in `canonical/EMISSION-MANIFEST.md`'s
    "Asset Kinds" table, so the new `graph/` subdirectory renders into all five profiles with **no
    renderer change**.
  - `render.py`'s `translate == "skills"` branch emits `SKILL.md` plus `references/*.md` and,
    when present, a verbatim copy of a skill's `scripts/` directory. No canonical skill ships one
    today; confirm whether `canonical/skills/aid-graph/` does, and that whichever is true renders
    correctly.
- The five hand-maintained `profiles/<tool>/README.md` files are **not** emitted by the generator
  and survive the render (`README` matches zero records in all five manifests, and the
  pure-mirror boundary only deletes paths a previous manifest recorded). Their count reconcile is
  **task-012's**, not this task's -- but confirm here that the render did not delete or rewrite
  them.
- Out of scope: authoring any canonical file (every dependency task above); the eleven
  `${SKILLS}` count surfaces and the `test-doc-counts.sh` gate (task-012); the `SKILL_GROUPS` /
  `CURATED_SKILL_NAMES` roster pair and the site test (task-010); the two stale count-claim
  surfaces (task-011); and the shipped-result registration suite
  `tests/canonical/test-graph-skill-registration.sh`, which is feature-013's (task-091) because
  it can only run once every tree exists.

**Acceptance Criteria:**

- [ ] The FULL generator was run -- `python .claude/skills/generate-profile/scripts/run_generator.py`
      -- and not a per-script or partial renderer. The command and its output are recorded in the
      delivery evidence.
- [ ] `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/`
      exits `0`: a second render over the already-rendered tree produces byte-identical output.
- [ ] **Configuration is idempotent** -- the byte-identical second render is exactly this
      property, and the drift gate is what asserts it. A third run is also asserted to leave
      `git diff --exit-code -- profiles/` clean.
- [ ] All five `profiles/<tool>/emission-manifest.jsonl` files are rewritten in the same run;
      none is stale, none was hand-edited, and each records the new
      `canonical/skills/aid-graph/` and `canonical/aid/scripts/graph/` file set.
- [ ] The five profile trees each contain the rendered `aid-graph` skill -- `SKILL.md`, the nine
      `references/state-*.md` bodies, and `references/agent-pass.md` -- plus the rendered
      `aid/scripts/graph/` script area and the amended `settings.yml` template.
- [ ] `canonical/skills/aid-graph/README.md` is confirmed to be canonical-only maintainer
      documentation: it is **not** emitted into any profile tree.
- [ ] No file under `profiles/`, `.claude/`, `.cursor/`, `.codex/`, `.agent/` or `.github/aid/`
      was hand-edited by this task or any of its dependencies (C-2; `module-map.md` Invariants).
- [ ] The five hand-maintained `profiles/<tool>/README.md` files are confirmed present and
      unmodified by the render.
- [ ] The render-drift gate, knowingly red from task-002 by owner decision, is recorded as
      **green** from this task.
- [ ] **No plaintext secrets** are introduced by this task: the render adds no credential, token,
      or key to any tree, and the amended `settings.yml` template carries only the `graph:
      ignore:` section seeded by task-013.
- [ ] `HOME="$(mktemp -d)" bash tests/run-all.sh` is green after the render, and no existing
      suite regresses.
- [ ] Code and authoring baseline per `.aid/knowledge/coding-standards.md` and
      `.aid/knowledge/authoring-conventions.md`; the delivery gate reaches this repository's
      resolved `minimum_grade` of **A+** (`review.minimum_grade` in `.aid/settings.yml`), i.e.
      zero ledger rows with Status `Pending` or `Recurred`. REQUIREMENTS.md section 6 holds only
      the six accessibility NFRs and is not a code baseline.

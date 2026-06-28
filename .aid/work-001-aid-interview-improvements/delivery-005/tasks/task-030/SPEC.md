# task-030: Extract-and-diff conformance sub-step + divergence classifier

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-005

**Depends on:** task-028, task-029

**Scope:**
- The detection crux of the conformance lane, authored as the NEW conformance sub-step in
  `canonical/skills/aid-housekeep/references/state-kb-delta.md` (after Step 2, before the no-drift exit),
  running over the set task-029 carved out. Author the four mechanism steps from the feature SPEC:
  - **Step 1 -- scope by the marker (deterministic):** enumerate the carved `source: forward-authored`
    docs; read each doc's concern from its `tags:` (the C0/C1/C3/C4/D ID). Empty set -> no-op.
  - **Step 2 -- shadow extraction (parameterized subagent reuse):** dispatch the aid-discover extraction
    subagents (Scout + the concern-matched deep-dive among Architect/Analyst/Integrator/Quality) with
    `output_root=.aid/.temp/conformance/as-built/` (the task-028 parameter), so `.aid/knowledge/` is NEVER
    written by this step -- the safety invariant is enforced BY CONSTRUCTION. Dispatch only the agents whose
    fixed bundle intersects the seed's declared concerns, then apply the **keep-only-in-scope filter**:
    retain only the in-scope as-built docs (C0/C1/C3/C4/D ->
    `architecture.md`/`domain-glossary.md`/`coding-standards.md`/`technology-stack.md`/`decisions.md`),
    discarding any out-of-scope docs the bundle also produced and ignoring the `.aid/generated/` side-output.
    For C4 the ranked as-built term universe is `harvest-coined-terms.sh --top 60`.
  - **Step 3 -- concern-keyed structured diff (agent-driven, at seed altitude):** match each forward-authored
    doc to its shadow as-built counterpart by concern (same `tags:` ID), compute an element-level (NOT
    textual-line) diff against the conformance model table, an `aid-architect`/`aid-reviewer`-class judgment
    (the same tier KB-DELTA Tier-2 already performs). C4 uses `harvest-coined-terms.sh` + `closure-check.sh`
    grounding; C1/C3/C0/D diff named elements (boundaries, invariants, rules, stack versions, decisions).
  - **Step 4 -- classify + altitude filter (false-positive control):** label each delta `design-ahead` |
    `placeholder-resolved` | `code-ahead` | `contradiction`. DROP `design-ahead` (forward-authoring leads --
    expected, not a finding). Carry forward only `placeholder-resolved` (low-friction) and `code-ahead` /
    `contradiction` (real divergence) into the reconciliation flow (task-031). Enforce the **seed-altitude
    filter**: an as-built detail BELOW the seed's declared altitude (an unnamed helper module, an
    implementation-only identifier) is NOT a `code-ahead` divergence -- only elements rising to the seed's
    altitude (a top-ranked spine term, a top-level boundary, a declared-rule contradiction, a pinned-but-TBD
    version) qualify. The exact altitude threshold is fixture-tuned at task-034 (DoD V5); author the filter
    here as the tunable knob, not a hard constant.
- Reuse KB-DELTA's existing extraction re-dispatch + harvest/closure calls; add no new script. Edit the
  canonical source form; host-tree propagation is task-032. ASCII-only.
- **Out of scope:** the carve/partition routing (task-029); the present-the-choice + Required-Q&A
  reconciliation (task-031); the `output_root` parameter definition (task-028); the render (task-032);
  verification + final altitude tuning (task-034).

**Acceptance Criteria:**
- [ ] The new conformance sub-step authors all four steps (scope-by-marker, shadow extraction, concern-keyed diff, classify+filter) over the carved set, after Step 2 and before the no-drift exit. *(FR-4; gate criteria 1, 3)*
- [ ] The shadow extraction dispatches the subagents with `output_root=.aid/.temp/conformance/as-built/` and NEVER writes `.aid/knowledge/` -- the invariant is stated as enforced by construction via the task-028 parameter. *(gate criterion 3; DoD V1)*
- [ ] The keep-only-in-scope filter retains only the C0/C1/C3/C4/D as-built docs and discards out-of-scope bundle docs + the `.aid/generated/` side-output; concern matching is by `tags:` ID. *(feature-005 Technical Spec Step 2/3)*
- [ ] The classifier emits the four classes and carries forward ONLY `placeholder-resolved`, `code-ahead`, and `contradiction`; `design-ahead` is dropped. *(feature-005 delta classes; gate criterion 1)*
- [ ] The seed-altitude filter suppresses sub-altitude as-built detail and qualifies only seed-altitude elements; it is authored as a tunable knob (final calibration fixture-tuned at task-034, DoD V5). *(DoD V5 false-positive control)*
- [ ] ASCII-only; skill reference is prose-executed (no inline unit test; IMPLEMENT unit-test default overridden -- the mechanism + altitude filter are exercised by task-034). All REQUIREMENTS.md §6 quality gates pass (heavy gates at task-034).

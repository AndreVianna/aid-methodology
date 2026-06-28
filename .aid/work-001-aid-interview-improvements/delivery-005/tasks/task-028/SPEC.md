# task-028: output_root dispatch parameter on the aid-discover extraction subagents

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-005

**Depends on:** -- (none)

**Scope:**
- The ONE additive edit that makes shadow extraction possible WITHOUT touching `.aid/knowledge/`. The
  aid-discover extraction subagents today hard-code their KB-doc destination as `.aid/knowledge/`
  (`canonical/skills/aid-discover/references/agent-prompts.md` -- the six dispatch-site write rules: 165
  Scout / 218 Architect / 260 Analyst / 309 Integrator / 355 Quality / 420 Grounding). Add an additive
  `output_root` dispatch parameter that parameterizes ONLY the KB-doc
  destination (default `.aid/knowledge/`), so each subagent's write rule becomes "write the KB docs to the
  dispatch-provided `output_root`".
- Thread the same `output_root` parameter through the dispatcher state
  (`canonical/skills/aid-discover/references/state-generate.md`): when /aid-discover and /aid-housekeep
  dispatch the subagents they pass the default `.aid/knowledge/`; document that a caller MAY pass an
  alternate root (the conformance lane will pass `.aid/.temp/conformance/as-built/`, wired in task-030).
- **Preserve the `.aid/generated/` side-output by construction.** The parameter governs the KB-doc root
  ONLY. The three sites that ALSO write `.aid/generated/` (Architect line 218, Integrator line 309,
  Grounding line 420) keep that secondary path UNCHANGED -- `output_root` does not touch the generated path.
- **Default preserves every existing caller.** With no `output_root` supplied (or the default), the rendered
  behavior of /aid-discover and /aid-housekeep is byte-equivalent to today (writes land in `.aid/knowledge/`,
  `.aid/generated/` side-output intact). No NEW extractor agent is introduced.
- Edit the canonical source form (`canonical/skills/aid-discover/references/...`); the host-tree propagation
  is task-032's render. ASCII-only; no new schema/enum.
- **Out of scope:** the conformance lane that DISPATCHES with the shadow root (task-030); the carve
  (task-029); the keep-only-in-scope filter prose (task-030, it lives in the housekeep lane, not here); the
  generator render (task-032); the verifying tests (task-033/034).

**Acceptance Criteria:**
- [ ] Each extraction subagent prompt in `agent-prompts.md` (the deep-dive agents + Scout) writes its KB docs to a dispatch-provided `output_root`, defaulting to `.aid/knowledge/`; the hard-coded `.aid/knowledge/` destination is replaced by the parameter at every one of the named sites. *(feature-005 Layers table; gate criterion 3)*
- [ ] `state-generate.md` threads `output_root` through the subagent dispatch, passing the default `.aid/knowledge/` for /aid-discover and /aid-housekeep and documenting the alternate-root entry point the conformance lane consumes. *(gate criterion 3)*
- [ ] The `.aid/generated/` side-output of Architect (line 218), Integrator (line 309), and Grounding (line 420) is left untouched -- `output_root` governs only the KB-doc destination (verify by diffing those sites' generated-path prose: unchanged). *(feature-005 Technical Spec Step 2; gate criterion 3)*
- [ ] Default-caller behavior is unchanged: with the default `output_root`, the rendered /aid-discover and /aid-housekeep dispatch is byte-equivalent to pre-edit (no NEW extractor; no `.aid/knowledge/` write removed for default callers). *(NFR-2 brownfield-intact; verified at task-033)*
- [ ] ASCII-only; skill reference is prose-executed (no inline unit test; IMPLEMENT unit-test default overridden -- the by-construction shadow-write invariant + default-caller-unaffected behavior are exercised by task-033). All REQUIREMENTS.md §6 quality gates pass (heavy gates at task-034).

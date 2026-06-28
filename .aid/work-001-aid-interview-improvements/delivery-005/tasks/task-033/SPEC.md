# task-033: output_root parameter conformance verification -- shadow-write isolation + caller invariance

**Type:** TEST

**Source:** work-001-aid-interview-improvements -> delivery-005

**Depends on:** task-032

**Scope:**
- Verify the `output_root` dispatch parameter (task-028) against its load-bearing behavioral guarantees.
  The extraction subagents are prose-executed (LLM-run, not unit-testable scripts), so this task combines a
  by-construction argument, a default-render diff, and a dogfood trace -- the AID AI + human-review DoD --
  authoring no new canonical content.
- **(A) Shadow-write isolation (gate criterion 3 / DoD V1):** dispatch the extraction subagents with
  `output_root=.aid/.temp/conformance/as-built/` (the conformance-lane invocation) on a fixture and confirm
  the as-built KB docs land ONLY under the shadow root -- `.aid/knowledge/` is NEVER written by the
  shadow extraction. Confirm the invariant is enforced by construction (the parameter governs the KB-doc
  root), not by convention.
- **(B) Default-caller invariance (NFR-2):** confirm that with the default `output_root` (or none supplied),
  the rendered /aid-discover and /aid-housekeep dispatch is byte-equivalent to pre-edit -- diff the
  default-render of `agent-prompts.md` + `state-generate.md` dispatch prose; run a brownfield /aid-discover
  dogfood and confirm it still writes `.aid/knowledge/` exactly as today (no NEW extractor, no removed
  write).
- **(C) Generated side-output preserved (DoD V6):** confirm the `.aid/generated/` side-output of the three
  sites that write it (Architect 218, Integrator 309, Grounding 420) is untouched by the parameter -- a
  default-root extraction still produces the `.aid/generated/` artifacts; the shadow-root extraction ignores
  them (only the KB docs feed the diff).
- Record results to this task's STATE.md / the delivery gate; file any [HIGH]/[CRITICAL] findings per the
  ledger schema. Out of scope: fixing parameter defects (loop back to task-028); the conformance-lane
  semantics + §6 heavy gates (task-034).

**Acceptance Criteria:**
- [ ] A shadow-root dispatch (`output_root=.aid/.temp/conformance/as-built/`) writes the as-built KB docs ONLY under the shadow root and NEVER writes `.aid/knowledge/` -- the by-construction isolation invariant holds. *(gate criterion 3, DoD V1)*
- [ ] Default-caller behavior is invariant: the default-render of `agent-prompts.md` + `state-generate.md` dispatch is byte-equivalent to pre-edit, and a brownfield /aid-discover dogfood still writes `.aid/knowledge/` as today (no NEW extractor, no removed write). *(NFR-2 brownfield-intact; gate criterion 4)*
- [ ] The `.aid/generated/` side-output of Architect (218), Integrator (309), and Grounding (420) is preserved under a default-root extraction and ignored (not consumed) under the shadow-root extraction. *(DoD V6)*
- [ ] Tests are deterministic with clean setup/teardown; the output_root guarantees (shadow-write isolation, default-caller invariance, generated-side-output preservation) are all covered. *(TEST defaults)*

# task-007: Delete dead emitter tests + CI de-wire

**Type:** REFACTOR

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** task-005, task-006

**Scope:**
- Delete the two now-dead format-branch conformance tests: `test_copilot_emitter.py` (conformance for the deleted `copilot-agent` branch) and `test_antigravity_emitter.py` (conformance for the deleted `antigravity-rule` branch) (feature-002 Layers — DELETE rows 12/13).
- Remove the dead emitter self-test invocations from `.github/workflows/test.yml` (the `generator-selftests` job — today lines 97-98) and `.github/workflows/release.yml` (today lines 166-167). **Verify the exact line references against the files at implementation time** (line numbers may drift).
- Re-point the surviving generator self-test invocations to `render.py --self-test` — replacing **both** the per-emitter `--self-test` calls **and** the `render_lib.py --self-test` / `render_canonical_scripts.py --self-test` invocations whose scripts are merged into `render.py` by task-005 (feature-002 "CI de-wiring").
- Confirm/drop any **rules-specific advisory CI invocation** (assumption A5) — the `verify_advisory.py` *code* edit is owned by task-005; this task only de-wires a rules-specific advisory invocation from CI if one is present.
- **Boundary:** the `render-drift` job (test.yml / release.yml) stays unchanged in shape (it still runs `run_generator.py` + `git diff --exit-code -- profiles/`). This task touches dead tests + workflow wiring only — it does not author the new dogfood byte-identity guard (task-008).

**Acceptance Criteria:**
- [ ] `test_copilot_emitter.py` and `test_antigravity_emitter.py` are deleted.
- [ ] No workflow file (`test.yml`, `release.yml`) references any deleted script (the dead emitter self-test invocations are removed; verified against the actual current line refs).
- [ ] The surviving generator self-test invocation is re-pointed to `render.py --self-test`.
- [ ] Any rules/extras-specific advisory **CI invocation** (A5) is confirmed present-or-absent and de-wired if present (the `verify_advisory.py` code edit is task-005's).
- [ ] CI is green after de-wiring (the canonical / generator-selftest / render-drift jobs pass).
- [ ] REFACTOR defaults: all tests pass before AND after (the surviving suite stays green); no behavior change to surviving generator output.
- [ ] All §6 quality gates pass.

# task-008: test-dogfood-byte-identity.sh §7a guard

**Type:** TEST

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** task-006, task-007

**Scope:**
- Author a NEW bash suite `tests/canonical/test-dogfood-byte-identity.sh` (feature-002 "The §7a / C2 Dogfood Byte-Identity Guard" / A8): T-prefixed assertions, sources `tests/lib/assert.sh`, auto-discovered by `tests/run-all.sh` glob (runs in the existing `canonical-tests` CI job — **no workflow YAML edit needed**).
- The suite asserts, via per-file `sha256sum` comparison, that repo-root `.claude/` and `profiles/claude-code/.claude/` are **byte-identical both directions** — every file under one has a byte-identical counterpart under the other, with **no extra or missing files** on either side (the whole `{agents, skills, aid}` shape, excluding nothing in the AID-owned tree).
- It must **fail loudly naming the first divergent path** (extra, missing, or content-mismatched file).
- **Boundary:** this task authors the guard only. The committed byte-identical trees it locks are produced by task-006; the CI de-wiring is task-007. No workflow YAML is edited (the suite is auto-discovered).

**Acceptance Criteria:**
- [ ] The suite passes against the committed trees (task-006's byte-twin `.claude/` and `profiles/claude-code/.claude/`).
- [ ] On a seeded mismatch (extra / missing / content-divergent file), the suite **fails loudly and names the divergent path**.
- [ ] The suite runs under `tests/run-all.sh` (auto-discovered, in the `canonical-tests` job) with **no workflow YAML edit**.
- [ ] The suite is ASCII-only (C3) and sources `tests/lib/assert.sh` with T-prefixed assertion IDs.
- [ ] It satisfies AC6's mechanized §7a / C2 byte-identity guard requirement.
- [ ] TEST defaults: tests are deterministic; clean setup/teardown (any seeded-mismatch fixture is fully torn down); all acceptance criteria from the source feature (AC6 §7a/C2) are covered.
- [ ] All §6 quality gates pass.

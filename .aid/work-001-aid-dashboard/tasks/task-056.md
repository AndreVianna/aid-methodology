# task-056: PT-1-H — cross-runtime byte-parity over the multi-repo shape (registry fixture; `/api/home` + per-`<id>` `/api/model` + traversal-refusal parity)

**Type:** TEST

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-050, task-051

**Scope:**
- Extend feature-003's PT-1 harness to **PT-1-H** (SEC-5, R9): prove the contract-level server rewrite did not let the Python and Node runtimes diverge over the NEW multi-repo shape. The d002 re-gate proved fixture-only parity can mask real cross-runtime bugs — so the fixture must exercise more than the happy path.
- **Registry fixture (checked-in):** a `registry.yml` pointing at **≥2 fixture repos** — one WITH `home.html`+`kb.html`, one WITHOUT (header/no-home repo) — PLUS one **unavailable** entry whose path does not exist (NFR10). The fixture repos carry the schema-floor `/api/model`-conforming `.aid/` state (reuse the delivery-006 fixture-from-real artifacts so per-repo `/api/model` parses clean). Include a STATE.md with literal `U+2028`/`U+2029` (R7).
- **Parity assertions, both runtimes:**
  - `GET /api/home` is **byte-identical** across runtimes **excluding** the runtime-/timestamp echoes `{generated_by, machine.cli_runtime, read.read_at}` (normalize/exclude those three).
  - **Each `/r/<id>/api/model`** is byte-identical across runtimes at the schema floor incl. the U+2028/U+2029 escape — and the `<id>` itself is byte-identical (the `sha256(CAN-1(path))[:8+]` derivation, DD-1/DD-5: a URL minted under one runtime resolves under the other).
  - The **SEC-2 traversal-refusal set** returns **identical refusals** from both runtimes: `..`, `%2e%2e`, absolute `/etc/passwd`, `/r/<id>/../settings.yml`, `/r/<id>/<workfolder>/STATE.md`, a symlinked leaf→outside, an unregistered `<id>`, a malformed `<id>` — all 404 identically.
- **Re-run the carried self-checks against the rewritten LC-MS (both runtimes):** the grep-level no-`0.0.0.0`/wildcard bind (SEC-1), the no-`fs.write*`/append/`os.remove`/`unlink` no-write check across N roots (SEC-3), and the no-agent/LLM-import check (SEC-4).
- **Harness shape:** keep feature-003's skip-if-runtime-absent posture (Linux box runs the Python half; the cross-runtime parity assertion runs only when both runtimes are present). Registered as a deliverable, not optional polish.

**Acceptance Criteria:**
- [ ] The PT-1-H registry fixture pins ≥2 repos (one with home+kb, one without) + one unavailable entry + a STATE.md with literal U+2028/U+2029; per-repo `/api/model` parses clean under the normalized reader.
- [ ] `/api/home` is byte-identical across Python and Node excluding `{generated_by, machine.cli_runtime, read.read_at}`; each `/r/<id>/api/model` is byte-identical incl. the U+2028/U+2029 escape; the `<id>` derivation is byte-identical (cross-runtime id parity proven — a one-runtime URL resolves under the other).
- [ ] The SEC-2 traversal/escape refusal set returns identical 404 refusals from both runtimes (including unregistered + malformed `<id>`).
- [ ] The SEC-1 (literal `127.0.0.1`-only / no wildcard), SEC-3 (no-write across N roots), and SEC-4 (no agent/LLM import) self-checks pass against the rewritten Python AND Node servers.
- [ ] The harness keeps the skip-if-runtime-absent shape; tests pass on both runtimes; no reader read-only/no-LLM invariant is violated by the harness.
- [ ] All §6 quality gates pass; existing PT-1 reader/server tests stay green.

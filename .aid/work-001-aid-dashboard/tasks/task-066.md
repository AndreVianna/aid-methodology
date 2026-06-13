# task-066: PT-1-H git-state-deterministic byte-parity + producer↔consumer kb-status / kb_baseline round-trip

**Type:** TEST

**Source:** feature-007-kb-dashboard → delivery-009

**Depends on:** task-064, task-063, task-060

**Scope:**
- Extend PT-1 / PT-1-H to prove the new `kb_state` fields are **byte-identical across runtimes** (R7/R12, SEC-A4) and add a producer↔consumer test for the kb-status derivation + the `kb_baseline` round-trip. Runs over the reader (task-064) with the dogfood-rendered producers (task-063) and the relocated `kb.html` path (task-060).
- **PT-1-H fixture extension (SEC-A4):** add to the parity fixture a `.aid/knowledge/` tree + a `<repo>/.aid/dashboard/kb.html` + a `kb_baseline` settings block, plus fixture variants that exercise each of the 5 derived states (`pending` no-KB, `generating` in-flight, `preparing` approved-no-summary, `approved` ready, `outdated` advanced-tip), so Python and Node emit byte-identical `kb_state` (incl. `status`/`summary_present`/`kb_baseline`).
- **Git-state determinism (residual #4/#5, R12):** make the live `git log` tip reproducible — either a fixture repo with a **frozen known commit** or **normalize/exclude** the non-deterministic tip field exactly like the existing `read_at`/`generated_by` echoes (DM-A3). The byte-parity assertion over `kb_state` must be reproducible across runs and runtimes.
- **`Z`-vs-`±HH:MM` normalization unit case (residual #5, R12):** a unit case feeding the same instant in two textual forms (`...Z` and `...±HH:MM`) proves Python's `datetime.fromisoformat(...).astimezone(utc)` and Node's `Date.parse`/`getTime` yield the **same** UTC instant and the same `approved`/`outdated` verdict — guarding the chronological-not-lexicographic compare at the offset boundary.
- **Producer↔consumer round-trip:** assert that a `kb_baseline` written by the producer write-idiom (the task-059 append-block shape) is parsed back by the reader into the same `{branch, tip_date}` (task-064 `parse`), and that the FF-A3 derivation over a known on-disk state yields the expected `status` — a contract test that a mutated producer key/shape fails (anti-drift, mirroring d006's task-042 contract test).
- **Degradation-matrix coverage:** at least the git-absent / not-a-git-repo / `kb_baseline`-absent branches assert SKIP → `approved` deterministically across both runtimes.
- Read-only / no-LLM throughout (NFR2/NFR7); the test observes, never mutates `.aid/`.

**Acceptance Criteria:**
- [ ] PT-1-H is extended with a `.aid/knowledge/` + `kb.html` + `kb_baseline` fixture covering all 5 derived states; Python and Node `/api/model` `kb_state` (incl. `status`/`summary_present`/`kb_baseline`) is **byte-identical** for each.
- [ ] The live git tip is made deterministic (frozen-commit fixture repo OR normalized/excluded field, DM-A3) so the parity assertion is reproducible across runs and runtimes (residual #4).
- [ ] A `Z`-vs-`±HH:MM` same-instant unit case proves Python and Node normalize to the **same** UTC instant and the same `approved`/`outdated` verdict (residual #5 / R12 — chronological, not lexicographic).
- [ ] A producer↔consumer round-trip asserts a producer-written `kb_baseline` parses back to the same `{branch, tip_date}` and the FF-A3 derivation yields the expected `status`; a mutated producer key/shape fails the contract (anti-drift).
- [ ] The git-absent / not-a-git-repo / `kb_baseline`-absent degradation branches each assert SKIP → `approved` deterministically in both runtimes; no `schema_version` bump is asserted (DM-A3).
- [ ] All §6 quality gates pass; the test mutates no `.aid/` (read-only, NFR2) and proves cross-runtime parity at the unchanged schema version.

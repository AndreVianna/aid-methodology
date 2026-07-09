# task-018: Reconcile diff orchestration (R0-R5) in the connector sub-phase

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-003

**Depends on:** task-001, task-005, task-006, task-008 (the former task-015 dependency is dropped — delivery-002 withdrawn, Q10)

**Scope:**
- Author the reconcile diff as an inline step in feature-002's connector sub-phase (the `state-generate.md` inline-bash house style), composing existing ops — no new twin, builder, or wiring code:
  - **R0 guard (STATE.md Q9):** branch on task-008's tool-step marker — `SKIPPED` (step not engaged) -> NO-OP (touch nothing under `.aid/connectors/`, no purge, registry left exactly intact); `DECLARED-EMPTY` (`D = {}`, step engaged with zero tools) -> every persisted connector falls into `P \ D` and is REMOVE-and-purged.
  - **R1** enumerate the persisted set `P` via task-001's `list` (NOT `read-setting.sh`, KI-001).
  - **R2** partition `D ∪ P` on the stem (field-equality splits `D ∩ P` into UPDATE vs NO-OP).
  - **R3** apply ADD / UPDATE / NO-OP / REMOVE; REMOVE = purge the local secret (task-006 `purge`, **aid-managed connectors only** — a clean no-op for tool-managed `mcp`) BEFORE deleting the descriptor (interrupt-safety). There is **no unwire step** (Q10 supersedes Q8 — AID wrote no host config). UPDATE overwrites the descriptor in place and preserves the stored secret.
  - **R4** regenerate `INDEX.md` via task-005's deterministic builder (header-only when the registry empties).
  - **R5** print a one-line diff summary (no secret value ever printed).
- Renders to all 5 profiles.

**Acceptance Criteria:**
- [ ] R0 branches on the Q9 marker: `SKIPPED` leaves the registry exactly intact (no writes, no purge); `DECLARED-EMPTY` removes-and-purges all persisted connectors
- [ ] ADD adds without touching existing entries/secrets; UPDATE overwrites the descriptor in place and preserves `.secrets/<stem>`; NO-OP writes nothing
- [ ] REMOVE purges the local secret (task-006, aid-managed connectors only) BEFORE deleting the descriptor; there is no unwire step (Q10)
- [ ] `INDEX.md` is regenerated via task-005's deterministic builder (header-only when the registry empties); no secret value is printed / logged / written to STATE
- [ ] The change renders identically into all 5 profiles; existing aid-discover suites + dogfood checks pass; build/render passes
- [ ] All §6 quality gates pass

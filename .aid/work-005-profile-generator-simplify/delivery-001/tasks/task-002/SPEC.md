# task-002: FR4 format decision section (AC4b gate)

**Type:** DESIGN

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** task-001

**Scope:**
- Write the **FR4 decision section INSIDE** `.aid/work-005-profile-generator-simplify/research/capability-study.md` (the single study doc — the separate `format-decision.md` was folded in per the intent-review correction; feature-001 Data Model "The decision section").
- Record a verdict per `(tool, asset-kind)`: **uniform markdown** OR a **documented native exception**, applying the 3-part **"provably required"** procedure (feature-001 Feature Flow S2): a native format is kept only when ALL of (1) a behavioral axis is `gap`/un-`translate`-able under uniform markdown AND the generator cannot translate it at render time, (2) AID actually relies on that behavior, and (3) the finding is `high` confidence (`docs` and, where feasible, `empirical`). If any of the three fails → commit uniform markdown (the FR4 default, verify-first).
- Each verdict **cites a study row** (from task-001's Capability Matrix) + **Finding D1** + the **E-CODEX-1 result**.
- State which branch **Codex agent-format** landed on: **uniform markdown** if E-CODEX-1 is `high`-confidence PASS, or the **dormant-TOML** fallback if E-CODEX-1 is not `high` (verify-first means the TOML branch is not deleted until the row is `high`; feature-001 "The Codex Resolution").
- For every retained exception, state which of the three conditions it satisfies; for every uniform-markdown verdict, state that condition (1) or (2) failed (behavior is preserved/translatable, or AID does not rely on it).
- **Boundary:** this section IS the **AC4b gate** — it discharges "the study is produced + documented before any branch is deleted; the FR4 decision cites it." No generator, `profiles/*`, or `.aid/knowledge/` edits.

**Acceptance Criteria:**
- [ ] Every `(tool, asset-kind)` verdict cites a study row (task-001) + Finding D1 + the E-CODEX-1 result.
- [ ] The 3-part "provably required" procedure is recorded per verdict (which conditions hold / which failed).
- [ ] The Codex agent-format verdict reflects task-001's actual E-CODEX-1 outcome (uniform markdown on a `high` PASS, dormant-TOML fallback otherwise).
- [ ] **AC4b is discharged**: the decision section exists, is documented before any branch deletion (task-003/004/005/006 depend on this task), and the FR4 decision cites the study.
- [ ] DESIGN defaults: design tokens used (here = the fixed Capability-Matrix / verdict-table schema reused, not a UI token set, as this is a research/decision feature with no rendered UI per feature-001 §UI Specs N/A); responsive behavior shown if applicable (N/A — no rendered UI; recorded as N/A with rationale).
- [ ] All §6 quality gates pass.

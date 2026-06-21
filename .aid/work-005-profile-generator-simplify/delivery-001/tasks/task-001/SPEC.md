# task-001: Per-tool capability study

**Type:** RESEARCH

**Source:** work-005-profile-generator-simplify -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Author `.aid/work-005-profile-generator-simplify/research/capability-study.md` with **one section per supported tool** (5 today: Claude Code, Cursor, Codex, GitHub Copilot CLI, Antigravity), extensible to a 6th (NFR5) via the fixed column shape (feature-001 Data Model).
- Each tool section carries the fixed **Capability Matrix** table — one row per behavioral **axis** (`discovery`, `execution-model`, `activation`, `capability/permissions`, `dispatchability`), with columns: `Native mechanism`, `Native format`, `Uniform-markdown encoding`, `Preserve/Translate/Gap`, `Verification`, `Confidence` (feature-001 Data Model, the Per-tool Capability Matrix column schema).
- Each tool section also carries a short **prose header**: tool + version pinned, asset kinds supported (agents / skills / rules), and the **always-on guarantee** verdict (the FR3/A1 question — does the root context file load on every request), including the **Cursor background-agent caveat** and the **Antigravity v1.20.3+** check.
- Seed Findings **D1** and **D2** as `high`-confidence `empirical:codebase` rows (feature-001 AI Enhancements): D1 — AID dispatches agents by name through the host's generic `Agent(subagent_type: aid-<name>, …)` tool, NOT any tool's native named-dispatch primitive; D2 — `dispatchability` reduces to "can the tool resolve `aid-<name>` to the agent definition?".
- Enter the prior 5-tool "Early inputs" as **DRAFT rows** and re-verify each **vendor-side** row against live vendor docs; a verified row supersedes its draft, a contradicted row is corrected with a change-log note (feature-001 Telemetry & Tracking).
- Record a per-tool **always-on verdict** (Cursor background-agent + Antigravity v1.20.3+ caveats).
- Include the **E-CODEX-1 row** — the Codex markdown-agent discovery probe (does Codex *read* a markdown agent's instructions + `model_reasoning_effort` from frontmatter?). If the probe is not runnable locally, record it as `docs`-only / `medium` confidence and name the residual risk explicitly (feature-001 "The Codex Resolution" + E-CODEX-1 definition).
- **Boundary:** read-only on code. This task does NOT modify the generator (`.claude/skills/generate-profile/scripts/*`), any `profiles/*` tree, or any `.aid/knowledge/` file — those are read only as study evidence (KB promotion is deferred to delivery-003 / feature-004).

**Acceptance Criteria:**
- [ ] Every `(tool, axis)` row in `capability-study.md` carries both a `Verification` value (`docs:<citation>` / `empirical:<test-id>` / `both`) and a `Confidence` value (`high`/`medium`/`low`) — no row left as an unverified draft (feature-001 S1 gate).
- [ ] Findings **D1** and **D2** are present as `high`-confidence `empirical:codebase` rows and are cited.
- [ ] The **E-CODEX-1 row** is present with an explicit verdict; if the probe is not runnable locally, it is recorded as `docs`-only / `medium` confidence with the residual risk named explicitly.
- [ ] Per-tool **always-on guarantee** verdict recorded for all 5 tools, including the Cursor background-agent caveat and the Antigravity v1.20.3+ check.
- [ ] The fixed Capability-Matrix column schema is used for every tool section (a 6th tool would slot in identically — NFR5).
- [ ] No generator, `profiles/*`, or `.aid/knowledge/` file is modified by this task.
- [ ] RESEARCH defaults: at least 2 alternatives compared (uniform markdown vs documented native exception, per axis where it applies); sources cited (live vendor doc URLs + access dates, plus `empirical:codebase`); actionable recommendation surfaced per tool.
- [ ] All §6 quality gates pass.

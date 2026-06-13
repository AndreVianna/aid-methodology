# task-040: Reader reconciliation (Python + Node byte-parity) — PF-2/3/5/6/7 parse rules, TaskModel short_name/delivery/lane, schema_version 2→3

**Type:** IMPLEMENT

**Source:** feature-009-producer-state-emission → delivery-006

**Depends on:** task-038, task-039

**Scope:**
- Reconcile the reader (Python `dashboard/reader/*.py` ∥ Node `dashboard/server/reader.mjs`) to the real canonical producer formats pinned by task-038/task-039. Both runtimes change in **lockstep**; every new regex/edge-case/null path is a literal Python↔Node twin guarded by PT-1 byte-parity.
- **PF-2** (`parse_requirements_md` / `parseRequirementsMd`): while accumulating the `## 1. Objective` (or `## Objective`) body, **drop any line whose `strip()` matches `^>\s*_.*_\s*$`** (the `> _Status: ..._` status-footer blockquote). Producer-neutral (does not remove the footer from REQUIREMENTS.md). Identical regex both runtimes.
- **PF-3** (NEW `parse_task_short_name` Python / twin in `reader.mjs`): for each `tasks/task-NNN.md`, read the first non-blank line and parse `^#\s+task-0*\d+\s*:\s*(.+)$` (case-insensitive); capture = short-name, strip trailing period; absent/unparseable → `None`. First-line-bounded read where the runtime allows.
- **PF-5** (NEW `parse_execution_graph` Python / twin): scan `PLAN.md` for ` ```wave-map``` ` blocks (PF-5a normalized path) → read `delivery: NNN` + `wave N: ...` lines → build `task_id → {delivery, lane}`; when no wave-map exists for a delivery, **legacy prose fallback** (PF-5b): `^\s*-\s*Wave\s+(\d+)\b` opens lane N, collect every `task-\d+` token on that heading line and its more-indented sub-bullets (until next `- Wave` or dedent), `∥`/`→`/`(a ∥ b)` decorations ignored for grouping; un-graphed task → `lane = None`. **Delivery key always from real STATE `## Tasks Status` Wave `delivery-NNN`** (PF-5c — STATE wins for delivery; wave-map/prose contributes only the lane); `delivery: Optional[int]` parsed from that `delivery-NNN`.
- **PF-4** (reader phase audit, both runtimes): the reader derives `phase` **solely** from the typed `## Pipeline Status` block's `- **Phase:**` field — no secondary or inferred phase source anywhere in the normalized path (no STATE blockquote `> **Phase:** ...`, no PLAN/wave heuristic). When the `## Pipeline Status` block is **absent** (the bootstrap/legacy case), `phase = None` (graceful null, never an `"unknown"`/sentinel string); the fallback lifecycle/other derivations are unaffected. Identical single-source rule both runtimes.
- **PF-6** (`parse_project_name` / `parseProjectName`): after extracting the `name:` scalar, strip an inline YAML comment (drop from first unquoted `#` to EOL), then `strip()` and strip surrounding quotes → `AID` from `name: AID  # set during /aid-config INIT`. Identical both runtimes.
- **PF-7** (null sentinels): every absent producer field serializes as `null` (no garbage substitution at the reader); front-end placeholder mapping is task-041.
- `TaskModel` (`dashboard/reader/models.py` + the Node task shape): add `short_name: Optional[str]`, `delivery: Optional[int]`, `lane: Optional[int]`.
- `_read_work` (`dashboard/reader/reader.py`) + `_readWork` twin (`reader.mjs`): read `PLAN.md` once per work, read each task-file first line, join `(delivery, lane, short_name)` into each `TaskModel`; keep STATE Wave as the delivery key (PF-5c). New reads accounted in `ReadMeta.bytes_read` (NFR4).
- **schema_version 2 → 3**: bump `dashboard/server/server.py` (`"schema_version": 2`) and `dashboard/server/server.mjs` (`schema_version: 2`); update the DM-3 serializer key order in both servers to include the new task fields `short_name`/`delivery`/`lane` deterministically (compact, integers-only, `ensure_ascii=False`, U+2028/U+2029 escape preserved — R7).
- Reader stays **read-only / no-LLM** throughout (NFR2/NFR7/C5): only parse rules + bounded reads added; no write/lock/subprocess/agent call.

**Acceptance Criteria:**
- [ ] Objective parse skips `^>\s*_.*_\s*$` status blockquote(s) in both runtimes; a fixture with one and with multiple trailing status blockquotes yields an `objective` with none of them (PF-2 / T-2).
- [ ] `parse_task_short_name` (and Node twin) parses `# task-NNN: <title>` first lines (strips trailing period); a bare `# task-007` with no title → `short_name = None` (PF-3 / T-3).
- [ ] `parse_execution_graph` resolves `(delivery, lane)` from `wave-map` blocks (T-5) and via the legacy prose fallback when absent (T-6); un-graphed task → `lane = None`; delivery key always the STATE `delivery-NNN` and STATE wins on any wave-map disagreement (PF-5c); **no** task yields `delivery = 0`.
- [ ] Phase is derived **solely** from the `## Pipeline Status` `- **Phase:**` field in both runtimes (PF-4 / T-4): a fixture WITH the block yields the typed phase; a fixture WITHOUT the block (bootstrap) yields `phase = None` (rendered as null, no `"unknown"`/sentinel); a structural check confirms no secondary/inferred phase source (STATE blockquote / PLAN heuristic) feeds `phase`.
- [ ] `parse_project_name` / `parseProjectName` strips the inline `#` comment → `AID`; quoted scalars and `#`-in-quotes handled identically both runtimes (PF-6 / T-7).
- [ ] `TaskModel` carries `short_name`/`delivery`/`lane`; absent producer fields serialize as `null`, not garbage (PF-7); both servers emit `schema_version: 3` with the new task fields in deterministic DM-3 key order and U+2028/U+2029 escaped (PT-1 / R7).
- [ ] Python and Node `/api/model` over the reader's fixtures are **byte-identical** at `schema_version: 3`; structural self-checks confirm the reader performs no write/lock/subprocess/agent-LLM call (no-LLM / read-only — NFR2/NFR7/C5).
- [ ] All §6 quality gates pass; IMPLEMENT default — unit tests for each new parse rule added in both runtimes; existing reader tests pass (cross-runtime parity + fixture-from-real are task-042).

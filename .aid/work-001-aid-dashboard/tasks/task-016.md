# task-016: Python thin server (server.py) — bind 127.0.0.1, / + /api/model, serialize DM-1/DM-3

**Type:** IMPLEMENT

**Source:** feature-003-pipeline-dashboard-app → delivery-002

**Depends on:** task-014, task-010

**Scope:**
- Implement the Python thin server `server.py` (feature-003 LC-S, stdlib-only `http.server` / `ThreadingHTTPServer` + `BaseHTTPRequestHandler`; zero third-party deps), per the LC-1 contract (task-014): accept `--root <target> --host 127.0.0.1 --port <n>`.
- Bind the literal `127.0.0.1` (C1/C2 hard — never `0.0.0.0`/`::`/wildcard, never read from config). Closed route allowlist: `GET /` → static `index.html`; `GET /api/model` → `read_repo(aid_root)` (feature-002, Python runtime) serialized to the DM-1 envelope `{ schema_version: 1, generated_by: "python", model }`; everything else → 404; non-GET → 405.
- Serialize deterministically (DM-3): fixed declared key order, `works` sorted by `work_id`, compact separators `(",",":")`, `ensure_ascii=False`, integers only — AND the U+2028/U+2029 post-process `.replace(" ","\\u2028").replace(" ","\\u2029")` so output matches Node's default escaped form (PT-1 / R7).
- No-write + no-LLM invariants structural (no write/append/`os.remove` primitive; no agent/LLM import).

**Acceptance Criteria:**
- [ ] The server binds the literal `127.0.0.1` only (a self-check asserts no `0.0.0.0`/wildcard-bind token in the source); the bind address is never read from config (C1/C2/AC5).
- [ ] `GET /` serves `index.html`; `GET /api/model` returns `200 application/json; charset=utf-8` with the DM-1 envelope (`schema_version:1`, `generated_by:"python"`, serialized `RepoModel`); other paths 404, non-GET 405.
- [ ] Serialization follows DM-3 (key order, `works` sorted by `work_id`, compact, integers-only, `ensure_ascii=False`) and post-processes `U+2028`/`U+2029` to the escaped canonical form (PT-1 prerequisite).
- [ ] A self-check asserts the server source contains no write/append/remove primitive and no agent/LLM import (NFR2/NFR7).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit tests for the new server's public routes/serialization added; existing tests pass; build passes (cross-runtime parity is task-018).

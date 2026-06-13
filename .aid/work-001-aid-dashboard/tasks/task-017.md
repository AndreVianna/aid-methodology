# task-017: Node thin server (server.mjs) — bind 127.0.0.1, / + /api/model, serialize DM-1/DM-3

**Type:** IMPLEMENT

**Source:** feature-003-pipeline-dashboard-app → delivery-002

**Depends on:** task-014, task-010

**Scope:**
- Implement the Node thin server `server.mjs` (feature-003 LC-S, built-in `http`/`fs` only; zero third-party deps), per the LC-1 contract (task-014): accept `--root <target> --host 127.0.0.1 --port <n>`.
- Bind the literal `127.0.0.1` (C1/C2 hard — never `0.0.0.0`/wildcard, never from config). Closed route allowlist: `GET /` → static `index.html`; `GET /api/model` → `read_repo(aid_root)` (feature-002, Node runtime) serialized to the DM-1 envelope `{ schema_version: 1, generated_by: "node", model }`; else 404; non-GET 405.
- Serialize deterministically (DM-3): object literals built in declared field order (V8 insertion order), `works` sorted by `work_id`, `JSON.stringify` compact output, integers only. Node's default `JSON.stringify` already escapes `U+2028`/`U+2029` — MUST NOT special-case them (the canonical form is the escaped form; PT-1 / R7).
- This is a sibling implementation, not a port — it shares the contract (DM-1/DM-3) with `server.py`, not code; held to it by PT-1.
- No-write + no-LLM invariants structural (no `fs.write*`/append; no agent/LLM import).

**Acceptance Criteria:**
- [ ] The server binds the literal `127.0.0.1` only (self-check asserts no `0.0.0.0`/wildcard token); bind address never from config (C1/C2/AC5).
- [ ] `GET /` serves `index.html`; `GET /api/model` returns the DM-1 envelope (`schema_version:1`, `generated_by:"node"`, serialized `RepoModel`); other paths 404, non-GET 405.
- [ ] Serialization follows DM-3 (declared key order, `works` sorted by `work_id`, compact, integers-only) and leaves `U+2028`/`U+2029` in their default-escaped form (no special-casing).
- [ ] A self-check asserts the server source contains no `fs.write*`/append/remove primitive and no agent/LLM import (NFR2/NFR7).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit tests for the new server's public routes/serialization added; existing tests pass; build passes (cross-runtime parity is task-018).

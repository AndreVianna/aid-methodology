# task-051: Multi-repo server rewrite — Node (`server.mjs`) LC-MS twin (byte-parity sibling of task-050)

**Type:** IMPLEMENT

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-047, task-048

**Scope:**
- Rewrite the delivered feature-003 Node server (`dashboard/server/server.mjs`) into the **LC-MS multi-repo server** — the **byte-parity sibling** of task-050 (Python). Same NEW closed allowlist, same `/api/home` + per-`<id>` routes, same registry resolution, same construct-not-sanitize discipline, same invariants — implemented in Node built-ins only (no third-party deps). The two share **no code** but share the **contract** (DM-1/DM-2/DM-3) and are held to it by PT-1-H (task-056).
- **NEW closed allowlist:** `GET /` → CLI-home `index.html` (resolved relative to `$AID_HOME/dashboard/`, mirroring the relocated `../index.html` sibling); `GET /api/home` → DM-2 model; `GET /r/<id>/{home.html,kb.html}` → constructed static leaf; `GET /r/<id>/api/model` → `readRepo(repo(id))` → feature-003 DM-1 envelope; else 404; non-GET 405.
- **Registry resolution:** `loadRegistry()` line-scan twin (`^\s*-\s`), mtime+size-cached `<id>`↔path map, `sha256(CAN-1(path))[:8+]` — hashing the **identical stored CAN-1 byte-string** as the Python server so the id is cross-runtime-identical (DD-1/DD-5). Tolerant of torn/higher-schema/absent (NFR10).
- **Construct-not-sanitize (SEC-2):** served path = `registry[id] + "/.aid/dashboard/" + leaf`, leaf from the fixed 2-element static allowlist; request contributes only the hex `<id>`. Same refusal matrix as task-050.
- **`/api/home` builder (DM-2):** identical field derivation as task-050 (machine panel from `$AID_HOME`, per-repo live reads from `settings.yml`/manifest/`stat`, `repos` sorted by `path`, best-effort nulls for unavailable).
- **Serialization (DM-3):** Node `JSON.stringify` in declared key order with the same compaction; Node's default already escapes U+2028/U+2029 — match the Python post-processed form exactly (R7). Parity-excluded set `{generated_by, machine.cli_runtime, read.read_at}`.
- **Invariants:** bind literal `127.0.0.1` only (SEC-1, `server.mjs:72`-class loopback gate, never `0.0.0.0`); no `fs.write*`/`appendFile`/`unlink` (SEC-3); no agent/LLM import (SEC-4); same-origin only.

**Acceptance Criteria:**
- [ ] All routes, refusals, and the closed-allowlist 404/405 behavior match task-050 exactly; `GET /api/home` and `GET /r/<id>/api/model` return the DM-2 / feature-003 DM-1 envelopes; static leaves are served by construction.
- [ ] The Node `<id>` derivation byte-matches the Python one for the same stored CAN-1 path (a `/r/<id>/…` URL minted under one runtime resolves under the other) — the DD-1/DD-5 cross-runtime id parity prerequisite (proven in task-056).
- [ ] Self-checks assert: literal `127.0.0.1`-only bind (no `0.0.0.0`/wildcard token); no `fs.write*`/`appendFile`/`unlink`/append primitive (SEC-3); no agent/LLM import (SEC-4); the static handler resolves only the constructed `registry[id]/.aid/dashboard/{home.html,kb.html}` and 404s the crafted traversal/escape set (SEC-2).
- [ ] Unregistered `<id>` → 404; registered-but-gone → 404 static / empty `RepoModel` for `/api/model`; torn/higher-schema/absent registry degrades best-effort (never 500).
- [ ] Serialization (DM-3) byte-matches the Python form incl. the U+2028/U+2029 escape (PT-1-H prerequisite).
- [ ] All §6 quality gates pass; IMPLEMENT default — Node unit tests for routes/resolution/serialization/refusals added; existing tests pass (cross-runtime parity is task-056).

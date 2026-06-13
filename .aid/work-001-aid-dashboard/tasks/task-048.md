# task-048: Registry contract + CAN-1 + DD-1 `<id>` seam (DESIGN — the shared layout all writers/readers resolve against)

**Type:** DESIGN

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** —

**Scope:**
- Pin the cross-cutting contracts every other d008 area builds on, as a single design artifact (the seam that must be agreed *before* the registry writer, both servers, and the CLI home are implemented in parallel). No production code (DESIGN).
- **DM-1 `$AID_HOME/registry.yml` schema:** the exact file shape (`schema: 1` + `repos:` block-sequence of absolute paths), the leading managed-by comment, the lazy-create/absent≡empty semantics, the higher-`schema` tolerant-read posture (NFR10), and the **paths-only** rule (no name/desc/version duplicated).
- **CAN-1 — the one canonicalization rule, four sites:** `cd "$path" && pwd` (absolutize + collapse `.`/`..`/`//`, **NOT** `-P` — symlinks not resolved; the existing `--target` semantics at `bin/aid:1255`/`:804`, deliberately NOT the `pwd -P` `$AID_HOME` self-resolve at `bin/aid:43`). Specify it applied **identically** at (1) the writer (`registry_register`/`unregister`), (2) storage (`repos[]` stored already-canonical), (3) the Python server id→path map, (4) the Node server id→path map; plus the PowerShell-twin equivalent (absolute, no symlink-follow).
- **DD-1 `<id>` addressing:** `id(path) = sha256(CAN-1(path))[:8+]` hex; URL grammar `/r/<id>/<fixed-leaf>` with `<id>` = `[0-9a-f]{8,}` (no `.`/`/`/`%`) and leaf ∈ {`home.html`,`kb.html`,`api/model`}; cross-runtime id parity (both runtimes hash the identical stored CAN-1 byte-string, DD-5); the mtime+size-keyed map cache (rebuild only on registry change, NFR4); the 8-hex collision-lengthen policy (residual #3).
- **DD-3 atomic write contract:** read-modify-write under `mktemp`+`mv` (PS twin `Move-Item -Force`); torn-read tolerance (reader sees old-or-new whole file, degrades to best-effort + parse note, never 500).
- **YAML line-scan parse posture (DD-REG-FMT):** `grep -E '^\s*-\s'` → strip `- ` prefix; zero YAML-library on either runtime.
- Output is a design artifact under `.aid/work-001-aid-dashboard/design/` that tasks 049/050/051/053 cite verbatim, so the writer, both servers, and the home page resolve the *same* id/path/registry contract.

**Acceptance Criteria:**
- [ ] The DM-1 registry schema is pinned (file bytes, comment, `schema:`+`repos:` shape, lazy-create/absent≡empty, tolerant higher-`schema` read, paths-only) — concrete enough that tasks 049/050/051 implement against it without re-deciding.
- [ ] CAN-1 is specified as one rule (`cd && pwd`, no `-P`) applied at all four sites + the PS-twin equivalent, with the explicit contrast to the `$AID_HOME` `pwd -P` self-resolve so the two are never conflated (MEMORY "pause on red flags": folder-path vs repo-slug look-alike discipline).
- [ ] DD-1 `<id>` derivation, URL grammar, cross-runtime parity, the mtime-cached map, and the collision-lengthen policy are pinned; the grammar structurally excludes traversal (hex-only id + fixed 3-leaf allowlist).
- [ ] DD-3 atomic-write + torn-read contract and the YAML line-scan posture are specified for both runtimes + the PS twin.
- [ ] No production code modified; the artifact is the authoritative seam cited by the parallel Slice-2 tasks (DESIGN).

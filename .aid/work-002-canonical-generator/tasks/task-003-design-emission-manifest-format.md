# task-003: Design the emission-manifest on-disk format

**Type:** DESIGN

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Author `canonical/EMISSION-MANIFEST.md` (a short design note, ~40–60 lines) specifying the on-disk shape of the per-profile emission manifest the SPEC describes at §170–§180. The format is **JSON Lines (`.jsonl`)**, one record per emitted path, committed alongside each install tree.
- Specify:
  - **Filename and location** — each profile emits one manifest at `{profile.layout.output_root}/emission-manifest.jsonl` (committed alongside the rest of the tree).
  - **Record schema** — every line is a JSON object with exactly four keys: `profile` (string, the profile name), `src` (string, repo-relative path inside `canonical/`), `dst` (string, repo-relative path inside the install tree), `sha256` (string, lowercase hex of the rendered file's bytes).
  - **Ordering** — records are emitted sorted lexicographically by `dst` so the manifest itself is byte-stable across re-runs (preserves the AC2 determinism guarantee for the manifest itself).
  - **No trailing-newline ambiguity** — exactly one `\n` terminates each record, including the last; `LF` line endings even on Windows (write in binary mode in the Python helper).
  - **Versioning** — a sentinel first line `{"_manifest_version": 1}` is reserved so a future schema change is recognizable; renderers in this work item emit version `1`.
  - **Safety boundary** — the manifest is the authoritative answer to "which install-tree paths are owned by the generator." Pure-mirror deletion considers only paths present in the *previous* run's committed manifest and absent from the current run's. Files outside any manifest are never touched.
- Justify the JSONL choice in 3–5 lines: streamable (one record per line, no full-file parse to append), greppable, diff-friendly, deterministic (sorted), and natively serializable by Python's `json` stdlib (no end-user runtime dependency — written by the maintainer-only generator).
- Reject alternatives briefly (TOML — verbose for a flat list of records; YAML — ordering and quoting ambiguity hurts determinism; SQLite — binary, not diff-friendly, overkill).
- Reference SPEC §170–§180 and REQUIREMENTS §3 ("Pure-mirror RENDER bounded by a per-run emission manifest") as the inputs.

**Acceptance Criteria:**
- [ ] `canonical/EMISSION-MANIFEST.md` exists and specifies: filename, on-disk location per profile, record schema (four keys + types), sorting rule, line-ending rule, versioning sentinel, and the safety-boundary semantics.
- [ ] A worked example block shows 3–4 sample records (one for an agent, one for a skill `SKILL.md`, one for a `references/*.md`, one for a template).
- [ ] The format choice (JSONL) is justified in ≤5 lines and at least 2 alternatives are listed with the reason they were rejected.
- [ ] The document is concrete enough that task-022 (manifest implementation) and task-023 (VERIFY-4a) can be written without re-deriving any of these decisions.
- [ ] **Default baked in:** one manifest per profile, placed at the deepest common parent of the profile's output roots (Codex: `codex/emission-manifest.jsonl`; Claude Code: `claude-code/emission-manifest.jsonl`; Cursor: `cursor/emission-manifest.jsonl`). Records carry a `dst` path relative to the profile's deepest common parent so the safety boundary covers both Codex output roots from one manifest. (Resolves OQ2.)

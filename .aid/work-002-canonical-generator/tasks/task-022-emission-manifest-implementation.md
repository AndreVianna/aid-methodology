# task-022: Implement the emission manifest mechanism

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-003, task-018

**Scope:**
- **Sequencing note (resolves Reviewer Finding C, Option B):** this task ships **before** the renderers (019, 020, 021), not after. The renderers add task-022 to their `Depends on` so they can call into the manifest API at first emission. Wiring is therefore baked into the renderers' own scope (see task-019 / task-020 / task-021), not retro-fitted by this task.
- Implement the `EmissionManifest` class declared in task-018's `harness.py` skeleton to the full semantics specified in task-003's `canonical/EMISSION-MANIFEST.md`.
- API (this is the contract renderers in tasks 019–021 will call into):
  - `add(profile: str, src: str, dst: str, content: bytes) -> None` — computes `sha256` internally; appends record to in-memory list.
  - `write(path: str) -> None` — sorts records lexicographically by `dst`, prepends the `{"_manifest_version": 1}` sentinel line, writes JSONL in binary mode with `\n` line endings, exactly one terminating newline per record.
  - `load(path: str) -> EmissionManifest` — classmethod for reading a prior run's manifest from disk.
  - `diff(prev: EmissionManifest, curr: EmissionManifest) -> tuple[list[str], list[str], list[str]]` — returns `(added_dst, removed_dst, changed_dst)`. `removed_dst` is the safety-boundary input: the deletion candidate set for the next RENDER pass.
- Manifest placement: **one manifest per profile** at the deepest common parent of the profile's output roots (`{profile.layout.common_parent}/emission-manifest.jsonl` — Codex: `codex/emission-manifest.jsonl`; Claude Code: `claude-code/emission-manifest.jsonl`; Cursor: `cursor/emission-manifest.jsonl`). Resolves OQ2 per task-003's baked-in default. Record paths in the manifest are relative to that common parent so a single manifest covers both Codex output roots.
- Wire the orchestration (task-025) to:
  1. Load the previous run's committed manifest (if any) at the per-profile path above.
  2. Run the renderers (which call `manifest.add(...)` to populate the current run's manifest).
  3. Compute `diff(prev, curr)`; for each `removed_dst`, `os.remove()` the file (and prune empty parent directories within the generator-owned subtree).
  4. Write the current manifest to disk.
- **Safety boundary tests** (must be part of this task's deliverable):
  - Put a user-created file inside an install tree (e.g. `claude-code/.claude/USER-NOTES.md`) that is NOT in any prior manifest. Run the generator. Confirm the file is **not** touched.
  - Remove a `canonical/skills/aid-*/references/*.md` file; re-run the generator. Confirm the corresponding install-tree file is deleted (it was in the prior manifest and is not in the current one).
- Determinism: sorting + line-ending discipline + no timestamps anywhere in the manifest.

**Acceptance Criteria:**
- [ ] `EmissionManifest.add/write/load/diff` implemented per task-003's spec.
- [ ] The two safety-boundary tests pass: user file untouched; canonical-removal cascades to install-tree deletion.
- [ ] Manifest JSONL is byte-identical across two consecutive runs with the same inputs (sentinel + sorted + LF).
- [ ] The `EmissionManifest` API is stable and ready for renderers (019, 020, 021) to import and call — the contract is what those tasks' `Depends on: task-022` consumes.
- [ ] One-manifest-per-profile placement is implemented at `{common_parent}/emission-manifest.jsonl` (resolves OQ2; Codex's split layout produces a single manifest at `codex/emission-manifest.jsonl`).

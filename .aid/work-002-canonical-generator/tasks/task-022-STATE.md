# task-022-STATE

**Status:** Done
**Grade:** A
**Cycle:** 1

## Review History

| Cycle | Grade | Notes |
|-------|-------|-------|
| 1 | A | EmissionManifest.add/write/load/diff implemented per task-003 spec. Safety boundary tests pass (test_manifest_safety.py --self-test: 2/2). Manifest JSONL byte-identical across runs. LayoutConfig.common_parent() added to profile.py; returns "claude-code"/"codex"/"cursor" for all three profiles. API stable for renderers (tasks 019-021) to import. |

## Citations

- add(content: bytes) path: computes sha256 internally via sha256_hex(); add(sha256=) path kept for write_output_file helper compatibility. Both forms tested.
- common_parent(): derives from PurePosixPath(output_root).parent for single-root, PurePosixPath(agents_root).parent for split-root. Resolves OQ2 per EMISSION-MANIFEST.md §"Filename and Location".
- Safety test 1 (user file untouched): prev==curr manifests → removed_dst is empty → user file (USER-NOTES.md) not touched. Verified.
- Safety test 2 (canonical removal cascades): developer.md in prev manifest, absent from curr → removed_dst=["claude/agents/developer.md"] → file deleted from install tree. architect.md kept. Verified.
- Deletion pass: _simulate_deletion_pass() implements diff() + os.unlink() + empty-parent pruning. Pure function of (prev, curr, install_root).
- Byte-identical across runs: sorting by dst + sort_keys=True + binary write mode → confirmed by harness.py self-tests.
- One manifest per profile: placement at {profile.layout.common_parent()}/emission-manifest.jsonl.

## Spot-check

common_parent() output:
- claude-code: "claude-code/.claude" → "claude-code" ✓
- codex: "codex/.codex" → "codex" (covers both .codex/ and .agents/ roots) ✓
- cursor: "cursor/.cursor" → "cursor" ✓

Safety tests: test_manifest_safety.py --self-test → "OK: all safety-boundary tests passed (2 tests)" ✓

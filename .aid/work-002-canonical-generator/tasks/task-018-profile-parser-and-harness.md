# task-018: Write the profile parser + render-script harness (Python)

**Type:** IMPLEMENT

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-015, task-016, task-017

**Scope:**
- Create `.claude/skills/aid-generate/scripts/` (the maintainer-tooling location for the generator — see Open Questions / SPEC §234 resolution: the AID repo dogfoods Claude Code, and the generator is maintainer-only tooling that never ships in any install tree). All Python render scripts and helpers live here.
- Author `.claude/skills/aid-generate/scripts/profile.py`:
  - Top-level `load_profile(path: str) -> Profile` using `tomllib` (Python 3.11+ stdlib).
  - A `Profile` dataclass with typed fields mirroring the TOML schema: `layout`, `agent`, `skill`, `model_tiers`, `tool_names`, `filename_map`, `extras`, `capabilities`.
  - A `validate(profile: Profile) -> list[str]` that returns a list of validation errors (empty list = valid). Checks: required tables present; every model-tier alias resolves; `[filename_map]` carries the three canonical keys; `[layout]` paths are relative (no leading `/`).
- Author `.claude/skills/aid-generate/scripts/harness.py` providing the shared helpers every renderer uses:
  - `read_canonical_file(path)` / `write_output_file(path, content, manifest)` — `write_output_file` records into the manifest as a side effect.
  - `substitute_filenames(body: str, filename_map: dict) -> str` — replaces `{project_context_file}`, `{reviewer_output_file}`, `{open_questions_file}` placeholders established in task-004.
  - `sha256_hex(data: bytes) -> str` — for the manifest.
  - `EmissionManifest` class: `add(profile, src, dst, sha256)`; `write(path)` (sorts records, emits JSONL with sentinel version line per task-003).
- All scripts have shebang `#!/usr/bin/env python3`, `from __future__ import annotations`, and Python equivalents of the shell `set -euo pipefail` safety idiom: a `main() -> int` entry point invoked under `if __name__ == "__main__": sys.exit(main())`; uncaught exceptions propagate to a top-level handler that prints to `stderr` and exits with code `1` (covers the `-e` "exit on error" half); `argparse` with `required=True` on positional args (covers the `-u` "unset variable" half — every input is explicit). Mirror the shell-script conventions from `coding-standards.md §6` insofar as Python permits: comment-block header (script name + purpose + usage), long-flag `argparse` parsing, `-h|--help` echoes the header.
- The scripts are **pure functions of `(canonical/, profile)`** — no `datetime.now()`, no UUIDs, no temp-file paths in output, no env-var dependence (NFR / AC2 byte-identical re-run).
- This task does NOT implement the per-asset renderers — those are tasks 019–021. Harness + parser + validation only.

**Acceptance Criteria:**
- [ ] `.claude/skills/aid-generate/scripts/profile.py` and `harness.py` exist; both are valid Python 3.11+ (`python -m py_compile` succeeds on each).
- [ ] `load_profile()` correctly round-trips all three profiles authored in tasks 015–017 (loads → dataclass → re-serializes to TOML loss-lessly for the structural fields).
- [ ] `validate(profile)` returns `[]` for all three profiles.
- [ ] `substitute_filenames()` correctly replaces the three placeholders and leaves unrelated `{...}` strings alone (e.g. `{step/total}` print-progress markers from `coding-standards.md §1.5` must not be substituted).
- [ ] `EmissionManifest.write()` produces JSONL byte-identical across two consecutive runs with the same inputs (sort + LF discipline from task-003).
- [ ] Both scripts have the documented header + `-h|--help` that echoes it.

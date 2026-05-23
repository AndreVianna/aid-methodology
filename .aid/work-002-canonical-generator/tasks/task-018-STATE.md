# task-018-STATE

**Status:** Done
**Grade:** A
**Cycle:** 1

## Review History

| Cycle | Grade | Notes |
|-------|-------|-------|
| 1 | A | profile.py and harness.py exist at .claude/skills/aid-generate/scripts/. Both compile cleanly. validate() returns [] for all three profiles. substitute_filenames() leaves unrelated {…} tokens untouched. EmissionManifest.write() is byte-identical across two runs. Both scripts have header + --help. |

## Citations

- script location: task-018 scope (.claude/skills/aid-generate/scripts/) — generator is maintainer-only tooling, never ships in install trees.
- Profile dataclass schema: mirrors TOML schema of tasks 015-017. LayoutConfig supports both single-root (output_root) and split-root (agents_root + assets_root) layouts.
- ModelTierSimple vs ModelTierDetailed: handles both flat-string tiers (Claude Code/Cursor) and sub-table tiers with reasoning_effort (Codex).
- validate() checks: required tables present; all three filename_map keys present; layout paths relative; agent.format in {markdown,toml}; skill.decomposition in {references}; all tier aliases in {large,medium,small}.
- substitute_filenames(): regex anchored to exactly the three known placeholder keys — {project_context_file}, {reviewer_output_file}, {open_questions_file} — leaves all other {…} tokens (e.g. {step/total}) untouched per AC requirement.
- EmissionManifest: sentinel {"_manifest_version": 1} first line; records sorted by dst; json.dumps(sort_keys=True); binary write mode (wb) for LF discipline on Windows; every line terminated by exactly one \n including last.
- Pure functions: no datetime.now(), no UUIDs, no env-var dependence — deterministic by construction.
- Safety idiom: main() -> int + sys.exit(main()) + argparse required=True on positional args.

## Spot-check

All three profiles validated:
- claude-code: output_root="claude-code/.claude", format="markdown", tiers={large:"opus",medium:"sonnet",small:"haiku"}, filename_map has all 3 keys — validate()=[] ✓
- codex: two-root layout agents_root="codex/.codex"+assets_root="codex/.agents", format="toml", tiers={large:{model:"gpt-5.5",reasoning_effort:"high"},…} — validate()=[] ✓
- cursor: output_root="cursor/.cursor", rules_dir="rules", tool_names={Bash:"Terminal"}, extras.rules=[aid-methodology.mdc, aid-review.mdc] — validate()=[] ✓

Harness self-test: 14 checks passed (sha256_hex determinism, substitute_filenames 3 cases, EmissionManifest determinism/sentinel/sort/LF/termination/load-round-trip/diff).

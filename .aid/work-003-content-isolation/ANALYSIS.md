# Content Isolation (work-003) — Grounded Analysis

Read-only map (branch `aid/dashboard-polish`). Confidence: CONFIRMED / LIKELY / UNCERTAIN.

## Model
- **AID-own folders** (generic names AID invented; host does NOT require the path) → **nest under `aid/`**: `scripts/`, `templates/`, `recipes/`.
- **Tool-native folders** (host requires the exact path) → keep; isolate the AID files inside by the `aid-` prefix + prune: `agents/`, `skills/`, `rules/` (cursor + antigravity).
- **Root-agent files** (`CLAUDE.md`/`AGENTS.md`) → AID:BEGIN/END boundary in the committed source; installer updates only that region.

## Per-profile classification (assets root in brackets)
| Profile [root] | tool-native (keep; prune `aid-*`) | AID-own (→ `aid/`) |
|---|---|---|
| claude-code [.claude] | agents/ (`aid-*.md`), skills/ (`aid-*/`) | scripts, templates, recipes |
| codex [.codex + .agents] | .codex/agents/ (`aid-*.toml`), .agents/skills/ | .agents/{scripts,templates,recipes} (nest under `.agents/aid/`, NOT `.codex/`) |
| cursor [.cursor] | agents/, skills/, rules/ (`aid-*.mdc`) | scripts, templates, recipes |
| copilot-cli [.github] | .github/agents/ (`aid-*.agent.md`), .github/skills/ | .github/{scripts,templates,recipes} |
| antigravity [.agent] | rules/ (`aid-*.md` — reshaped personas + methodology; NO agents/ dir), skills/ | scripts, templates, recipes |

## Risks / decisions
- **R1 (HIGH):** `.github/` is shared GitHub user content — isolation must scope to `.github/{agents,skills,aid/}` ONLY; never treat the `.github` root as AID-own. (Empty-prune on uninstall already guarded.)
- **R2 (HIGH):** `profiles/{claude-code,codex,cursor}/.../skills/README.md` is AID content WITHOUT the `aid-` prefix → a prefix-only prune ignores it / can't manage it. **Decision: rename to `aid-README.md`** (prefix-isolate it) in the generator + profiles, so the cornerstone holds (everything `aid-`-prefixed or under `aid/`).
- **R3 (HIGH):** the toml `[layout]` `*_dir` keys (`scripts_dir`/`templates_dir`/`recipes_dir`) and `render_lib._CANONICAL_PATH_DIRS` (`:57`) + `rewrite_install_paths` (`:122-177`) MUST stay lockstep — the nest splits AID-own (rewrite → `<root>/aid/<x>/`) from tool-native (unchanged).
- **R4 (MED):** `templates/generated-files.txt` hardcodes `.claude/scripts/kb/...` as DATA lines (exempt from rewrite) → update under the nest.
- **R6 (MED):** codex split — nest applies to `.agents/`; `.codex/` ships only `agents/`.
- **R7 (HIGH):** NO install-time prune exists today in bash (`install_tool` `:1477-1609`) OR PS (`Install-Tool`) — `copy_dir` overlays the whole staged tree, `manifest_write` merges. The prune is net-new in BOTH (lockstep).
- **R8:** root-agent files are NOT generated (`run_generator.py:43-47` has no pass) → markers go in committed `profiles/*/CLAUDE.md` + `AGENTS.md`; consumer is `_copy_root_agent_file` (FR11, `:374-431`) + PS mirror.
- **Prune basis:** per the user, prune is **`aid-`-prefix + new-manifest membership** (NOT an old-manifest diff). The nested `aid/` tree is wholly AID-owned (prune anything under it not in the new manifest). `aid-README.md` (R2) then falls under the prefix rule.

## Migration (root-agent, NO `.aid-new`)
On update: if AID:BEGIN/END present → replace only between markers, preserve outside. If absent → inject markers in place: clean rewrite when the file still matches the AID-recorded sha; else excise the known AID-managed sections (`## Knowledge Base`, `## Review output format`, `## Permissions`) and re-insert them wrapped in markers, preserving `## Project`/`## Project Overview` + user content. Never write a backup file.

## Central wiring points
- `render_lib.py:57` `_CANONICAL_PATH_DIRS` + `:122-177` `rewrite_install_paths` — the single canonical-path rewrite chokepoint.
- `render_canonical_scripts.py:53-62`, `render_templates.py:62-72`, `render_recipes.py:58-71` — AID-own dst builders.
- `aid_profile.py:37-43` dir defaults + per-profile `*.toml [layout]`.
- `lib/aid-install-core.sh` (`install_tool:1477`, `copy_dir:345`, `_copy_root_agent_file:374`, `manifest_write:604`, `uninstall_tool:1619`) + `lib/AidInstallCore.psm1` (`Install-Tool`, AID-dir map `:1165`, detect `:128-146`).
- Root-agent sources: `profiles/claude-code/CLAUDE.md`, `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md`.

## Reference / blast radius (auto-rewritten if the chokepoint is updated)
canonical bodies: `canonical/scripts/` 219 refs/70 files; `canonical/templates/` 135/58; `canonical/recipes/` 17/5. Manual-update sites: `generated-files.txt` (R4), `bin/aid` (1, triage), `docs/` (~16), `tests/` (~57 scripts + ~22 install-root, triage per-test), KB docs (text-only). Each profile's `emission-manifest.jsonl` dst paths change (dev deletion pass handles old→new on first regen).

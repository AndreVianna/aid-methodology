# Emission Manifest — Design Specification

> **Source:** task-003 (work-002-canonical-generator delivery-001)
> **References:** SPEC §170–§180, REQUIREMENTS §3 ("Pure-mirror RENDER bounded by a per-run emission manifest")

## Purpose

The emission manifest is the **authoritative safety boundary** for the generator's pure-mirror
deletion logic. It answers the question "which install-tree paths are owned by the generator?"
Every file the generator emits is recorded in the manifest. When a canonical source or profile
changes, the manifest diff (`removed_dst`) is the only set of paths the generator is allowed
to delete — files outside any manifest are never touched.

## Filename and Location

One manifest per profile, placed at the **deepest common parent** of the profile's output roots:

| Profile | Manifest location |
|---------|-------------------|
| `profiles/claude-code.toml` | `claude-code/emission-manifest.jsonl` |
| `profiles/codex.toml` | `codex/emission-manifest.jsonl` |
| `profiles/cursor.toml` | `cursor/emission-manifest.jsonl` |

For Codex (split layout: `profiles/codex/.codex/` + `profiles/codex/.agents/`), the single manifest at
`codex/emission-manifest.jsonl` covers both output roots. Record paths in the manifest
are relative to that common parent (`codex/`) so the safety boundary covers both roots from
one manifest. (Resolves OQ2 — one manifest per profile.)

The manifest is **committed alongside the install tree** it describes. It is a generated
artifact, not a source file.

## Record Schema

The manifest is a JSON Lines (`.jsonl`) file. Every line is a JSON object with exactly
four keys:

| Key | Type | Description |
|-----|------|-------------|
| `profile` | `string` | Profile name (e.g. `"claude-code"`, `"codex"`, `"cursor"`) |
| `src` | `string` | Repo-relative path inside `canonical/` (the generator's input) |
| `dst` | `string` | Repo-relative path inside the install tree (relative to the manifest's directory) |
| `sha256` | `string` | Lowercase hex SHA-256 of the rendered file's bytes |

## Ordering

Records are sorted **lexicographically by `dst`** before writing. This deterministic ordering
ensures the manifest file itself is byte-stable across re-runs — preserving the AC2
(byte-identical re-run) guarantee for the manifest as well as the generated files.

## Line-Ending and Trailing-Newline Rule

- Line endings: **`LF` (`\n`) only**, even on Windows.
- Termination: exactly one `\n` terminates **every** record, including the last.
- Implementation note: write in **binary mode** (`open(path, "wb")`) in the Python helper
  to prevent OS-level CRLF injection on Windows.

## Versioning Sentinel

The **first line** of every manifest is a sentinel:

```json
{"_manifest_version": 1}
```

This is a reserved object that allows future schema changes to be recognized without
ambiguity. Renderers in this work item emit version `1`. A future consumer that reads
`_manifest_version: 2` knows to use a different parser.

## Safety-Boundary Semantics

The manifest is the input to the pure-mirror deletion logic:

1. Before each render run, **load the previous run's committed manifest** from disk (if any).
2. Run all renderers — each emitted file is `add()`-ed to the current run's in-memory manifest.
3. Compute `diff(prev, curr)`:
   - `added_dst`: paths new in `curr` — no action needed (they will be written by the renderer).
   - `removed_dst`: paths in `prev` but absent from `curr` — **these and only these** are deleted.
   - `changed_dst`: paths in both, sha256 differs — overwritten by the renderer.
4. Delete each file in `removed_dst` from disk; prune empty parent directories within the
   generator-owned subtree.
5. Write `curr` to disk as the new committed manifest.

Files outside any manifest (user-created, hand-maintained) are **never touched**.

## Format Choice Justification (JSONL)

JSON Lines was chosen because it is:

1. **Streamable** — one record per line, no full-file parse to append or read incrementally.
2. **Greppable** — `grep dst emission-manifest.jsonl` works without a JSON parser.
3. **Diff-friendly** — sorted records produce stable, meaningful diffs in `git diff`.
4. **Deterministic** — sorting by `dst` + `json.dumps(..., sort_keys=True)` produces identical
   output across Python versions and platforms.
5. **Zero runtime dependency** — Python's `json` stdlib handles both serialization and
   deserialization; no end-user dependency added (the generator is maintainer-only tooling per NFR5).

**Rejected alternatives:**
- **TOML** — verbose for a flat list of records; no native streaming; harder to diff when records
  span multiple lines.
- **YAML** — ordering and quoting ambiguity hurts determinism; YAML anchors/aliases add
  unnecessary complexity for a simple tabular structure.
- **SQLite** — binary format, not diff-friendly; overkill for a simple sequential list; adds a
  runtime dependency.

## Asset Kinds

The generator recognises the following canonical asset kinds. Each kind maps to
an install-tree sub-directory per the profile's layout configuration.

| Canonical source | Claude Code | Codex (split) | Cursor | Renderer |
|-----------------|-------------|---------------|--------|----------|
| `canonical/agents/` | `.claude/agents/` | `.codex/agents/` | `.cursor/agents/` | `render_agents.py` |
| `canonical/skills/` | `.claude/skills/` | `.agents/skills/` | `.cursor/skills/` | `render_skills.py` |
| `canonical/templates/` | `.claude/templates/` | `.agents/templates/` | `.cursor/templates/` | `render_templates.py` |
| `canonical/recipes/` | `.claude/recipes/` | `.agents/recipes/` | `.cursor/recipes/` | `render_recipes.py` |

### Recipes asset kind (FR8 — feature-011-recipes back-port, work-001)

`canonical/recipes/` holds pre-filled lite-path templates with `{{slot}}`
placeholders. Recipes are plain Markdown files (passthrough renderer — no
format conversion or frontmatter injection). They follow the same profile-
emission contract as templates:

- **Single-root profiles** (Claude Code, Cursor): emit under `{output_root}/recipes/`
- **Split-root profile** (Codex): emit under `{assets_root}/recipes/`
- **Idempotent**: if `canonical/recipes/` is empty or absent, the generator
  emits nothing and records no manifest entries for this kind.
- **Mirror-deletion**: removing a recipe and re-running the generator deletes
  the rendered copy from all 3 install trees via the normal manifest diff.

## Worked Example

```jsonl
{"_manifest_version": 1}
{"profile": "claude-code", "src": "canonical/agents/architect.md", "dst": ".claude/agents/architect.md", "sha256": "a1b2c3d4e5f6..."}
{"profile": "claude-code", "src": "canonical/recipes/new-feature.md", "dst": ".claude/recipes/new-feature.md", "sha256": "e5f6a1b2c3d4..."}
{"profile": "claude-code", "src": "canonical/skills/aid-deploy/SKILL.md", "dst": ".claude/skills/aid-deploy/SKILL.md", "sha256": "b2c3d4e5f6a1..."}
{"profile": "claude-code", "src": "canonical/skills/aid-discover/references/agent-prompts.md", "dst": ".claude/skills/aid-discover/references/agent-prompts.md", "sha256": "c3d4e5f6a1b2..."}
{"profile": "claude-code", "src": "canonical/templates/grading-rubric.md", "dst": ".claude/templates/grading-rubric.md", "sha256": "d4e5f6a1b2c3..."}
```

The five example records cover:
1. An agent file
2. A recipe file (new — FR8)
3. A skill `SKILL.md`
4. A skill `references/*.md` sub-file
5. A template

For Codex (split layout), records under `.codex/` and `.agents/` both appear in
`codex/emission-manifest.jsonl` with `dst` values like `.codex/agents/architect.toml`,
`.agents/recipes/new-feature.md`, and `.agents/skills/aid-deploy/SKILL.md` — all
relative to `codex/`.

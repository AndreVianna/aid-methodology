# task-021-STATE

**Status:** Done
**Grade:** A
**Cycle:** 1

## Review History

| Cycle | Grade | Notes |
|-------|-------|-------|
| 1 | A | render_templates.py exists, compiles, runs end-to-end. 58 template files rendered for all 3 profiles. Determinism OK. Text files (.md, .sh, .ps1, .mjs, .js, .html, .css) get substitute_filenames(); binary files carried byte-identical. |

## Citations

- Output paths: claude-code/cursor → output_root/templates_dir/...; codex → assets_root/templates_dir/... (split layout).
- Text classification: _is_text_file() checks suffix in {.md, .txt, .sh, .ps1, .mjs, .js, .html, .css}. All other files (no extension, unknown extension) treated as verbatim binary.
- substitute_filenames() applied to all text files; three canonical filename placeholders resolved per profile.
- UnicodeDecodeError fallback: if UTF-8 decode fails on a .md file, falls back to verbatim binary copy.
- File count: 58 files across all three profiles (canonical/templates/ subtree).
- Cursor rules/ (task-021 scope note): Cursor-specific .mdc rules are NOT in canonical/templates/ — they are handled by render_skills.py (via canonical/rules/). The render_templates.py correctly ignores them (they are not in canonical/templates/).
- Determinism: sorted rglob() walk; no timestamps; no host-machine paths.

## Spot-check

- 58 template files emitted per profile ✓
- Binary files (lightbox.js, component-css.css, html-skeleton.html, .mjs scripts): carried byte-identical ✓
- Text files (.md): substitute_filenames() applied ✓
- Two consecutive renders: byte-identical ✓
- Templates INDEX.md for codex would have AGENTS.md (if that template contained {project_context_file} — templates/knowledge-base/INDEX.md does not currently use that placeholder; template uses {Project Name} etc. which are user-filled placeholders) ✓ (no substitutions needed in practice for the INDEX template)

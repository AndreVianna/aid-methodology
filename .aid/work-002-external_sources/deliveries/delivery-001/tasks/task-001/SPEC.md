# task-001: Connectors registry frontmatter-accessor twin

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** -- (none)

**Scope:**
- New Bash+PowerShell twin under `canonical/aid/scripts/connectors/` that (a) `list`s connector descriptor stems under `.aid/connectors/` (excluding `INDEX.md`, `.gitignore`, and `.secrets/`) and (b) `read`s a single named frontmatter field from a `<connector>.md` descriptor.
- Deliberately NOT a reuse of `read-setting.sh` (it resolves only 2-level `section.key` dotted paths — KI-001); this is a dedicated descriptor frontmatter accessor.
- Carries a header block (Purpose/Usage/Exit codes); prints the result to stdout and diagnostics to stderr; renders to all 5 profiles + the dogfood `.claude/` tree.

**Acceptance Criteria:**
- [ ] `list` returns one line per `.aid/connectors/*.md` stem, excluding `INDEX.md` and the non-descriptor `.gitignore` / `.secrets/`
- [ ] `read <stem> <field>` prints the descriptor frontmatter value to stdout; a missing field or descriptor exits non-zero with an stderr diagnostic
- [ ] Both twins are behavior-equal; shipped PowerShell is WinPS-5.1-compatible and ASCII-only (no ternary / null-coalescing / `$IsWindows`)
- [ ] Unit tests cover the `list` + `read` surface and the non-zero error paths; all existing tests still pass; build/render passes
- [ ] All §6 quality gates pass

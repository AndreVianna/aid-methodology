# task-023: Write VERIFY-4a — the deterministic hard gate

**Type:** TEST

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-019, task-020, task-021, task-022

**Scope:**
- Author `.claude/skills/aid-generate/scripts/verify_deterministic.py`.
- Three sub-checks, all hard pass/fail:
  1. **Byte-identical re-render.** Run the full generator (all renderers, all three profiles) into a temporary scratch directory `A`; run it again into a separate scratch directory `B`; `diff -r A B` must produce empty output. Implementation: `subprocess` two render passes into `tempfile.mkdtemp()` dirs; recursive byte-compare with `filecmp.dircmp` (with a custom recursive walk because `dircmp` by default doesn't recurse fully).
  2. **File-presence audit against the manifest.** For each profile, walk the emitted output tree; the set of files on disk must exactly equal the set of `dst` entries in the manifest (no missing files, no extra files outside the manifest within the generator-owned subtree). Tolerates user-added files outside the manifest's coverage per the safety-boundary semantics.
  3. **Frontmatter parses for every emitted file.** For every `*.md` emitted: split on `---`, parse the frontmatter block as YAML (using `pyyaml`, an acceptable maintainer-only dep — or, simpler, a hand-rolled YAML subset parser since the frontmatter shape is constrained per `coding-standards.md §1.1` / §2.1). For every `*.toml` emitted: load with `tomllib`. Any parse failure is a VERIFY-4a fail.
- Output: a short report (stdout + a structured JSON summary at `.aid/work-002-canonical-generator/verify-4a-report.json` for the orchestration to consume).
- Exit code: 0 on pass; non-zero on any sub-check fail. This is the **hard gate** — any failure here blocks the render run (per SPEC §188 "Run by scripts. A failure here blocks.").

**Acceptance Criteria:**
- [ ] `.claude/skills/aid-generate/scripts/verify_deterministic.py` exists; compiles; runs end-to-end against a successful render.
- [ ] All three sub-checks pass when the generator is in a clean / correct state.
- [ ] Forced-failure smoke tests: (a) deliberately introduce a non-determinism (e.g. add `time.time()` into a renderer's output); the byte-identical-re-render check fails with a non-zero exit. (b) Delete a file from the rendered tree post-render; the presence-audit fails. (c) Inject malformed frontmatter into one canonical agent; the parse check fails. All three failure modes are detected and reported.
- [ ] The JSON report at `verify-4a-report.json` is well-formed and lists exactly which sub-check passed/failed and (on failure) the first 10 offending paths.
- [ ] Exit code is 0 on pass, non-zero on fail.

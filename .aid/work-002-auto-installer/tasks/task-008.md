# task-008: Remove `setup.sh`/`setup.ps1` and update all references

**Type:** REFACTOR

**Source:** feature-001-shared-install-core-and-bootstrap → delivery-001

**Depends on:** task-004, task-006

**Scope:**
- Remove the legacy `setup.sh` and `setup.ps1` scripts (superseded by `install.sh`/`install.ps1` + `lib/*`).
- Re-run `grep -rl 'setup\.\(sh\|ps1\)'` at build time, excluding `.aid/knowledge/` and `profiles/`, and update **every** hand-maintained hit (the live grep is the source of truth) — including `README.md`, `CONTRIBUTING.md`, `docs/faq.md`, `examples/greenfield/README.md`, `examples/brownfield-full-path/README.md`, `methodology/aid-methodology.md` (pipeline diagram node + multi-tool prose, rewording last-writer-wins → per-tool + protect-on-diff), `tests/README.md`, and repo-root `.claude/settings.json` (the `./setup.sh` permission allow-rule).
- Update the maintainer/methodology re-render **sources** that name the scripts (`canonical/skills/aid-discover/SKILL.md`, `canonical/templates/rough-time-hints.md`, `canonical/templates/knowledge-summary/section-templates/agentic-pipeline.md`) in `canonical/` only — the `.claude/*` and `profiles/*` copies re-render from these and are NOT hand-edited.
- Do NOT hand-edit the `.aid/knowledge/` and rendered `profiles/*` carve-outs (KB-housekeep / render cycles own those).

**Acceptance Criteria:**
- [ ] `setup.sh` and `setup.ps1` no longer exist; `install.sh`/`install.ps1` are the only installer entry points.
- [ ] A fresh `grep -rl 'setup\.\(sh\|ps1\)'` (excluding `.aid/knowledge/` and `profiles/`) returns zero hand-maintained references — every doc, example, `tests/README.md`, `.claude/settings.json` allow-rule, and the three `canonical/` re-render sources are updated. Carve-out: the `tests/canonical/test-setup*.sh` suite files are out of this grep's domain — `test-setup.sh` is renamed/removed by task-004 (bash) and `test-setup-ps1.sh` by task-006 (ps), so this task neither edits nor counts them (no double-ownership).
- [ ] `methodology/aid-methodology.md` reflects per-tool install + protect-on-diff (the removed last-writer-wins prose is reworded), and the pipeline-diagram installer node names `install.sh`/`install.ps1`.
- [ ] No edits land inside `.aid/knowledge/` or rendered `profiles/*` (those carve-outs are deferred to their owning cycles); `python run_generator.py` shows no render-drift after the `canonical/` source edits.
- [ ] All §6 quality gates pass.

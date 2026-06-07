# task-025: Verify guides — links resolve, Mermaid renders

**Type:** TEST

**Source:** feature-007-pipeline-and-maintainer-guides → delivery-004

**Depends on:** task-024

**Scope:**
- Build `site/` and verify `guides/pipeline` and `guides/maintainer` render and are navigable in the Guides section (AC3-partial).
- Run the internal link/anchor checker over both guides and confirm every cross-link resolves to a live route (`/concepts/methodology`, `/reference/cli`, `/reference/skills`, `/reference/agents`, `/reference/repository-structure`, `/guides/installation`, `/releases/changelog`) (AC5-partial). If a delivery-003 target is absent at run time, confirm the anchor is stubbed rather than broken.
- Verify all `mermaid` fences in the guides render as SVG and are horizontally scrollable (AC5-partial).
- Spot-check the maintainer "Regenerate trees" runbook commands against `.claude/skills/aid-generate/SKILL.md` and the "Cut a release" content against `docs/release.md` for fidelity.

**Acceptance Criteria:**
- [ ] Both guides render and are navigable under Guides (AC3-partial).
- [ ] Internal link/anchor check passes; cross-links resolve to live routes.
- [ ] Guide Mermaid diagrams render as SVG and scroll horizontally (AC5-partial).
- [ ] Maintainer runbook commands match aid-generate / `docs/release.md` (fidelity spot-check passes).
- [ ] Tests are deterministic with clean setup/teardown; all feature-007 acceptance criteria covered.
- [ ] All §6 quality gates pass.

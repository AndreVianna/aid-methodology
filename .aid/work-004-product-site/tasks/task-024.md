# task-024: Pipeline & Maintainer guides — `guides/pipeline.mdx` + `guides/maintainer.mdx`

**Type:** IMPLEMENT

**Source:** feature-007-pipeline-and-maintainer-guides → delivery-004

**Depends on:** task-009

**Scope:**
- Author `site/src/content/docs/guides/pipeline.mdx` (hand-authored `.mdx`, D1, replaces feature-001 stub) at `guides/pipeline`: task-oriented walkthrough of `aid-config` + the six numbered phases (Discover → Execute) with the optional Deliver skills, per methodology v3.2; phase→skill names taken verbatim from `canonical/skills/` (D5). Sections: Before you start, The pipeline at a glance (`mermaid` flow), Step 0 Configure (`<Steps>`), The six phases (H3 per phase + `<LinkCard>` to `/reference/skills` root), Delivering (deploy/monitor), Lite vs full, Next steps. Use Starlight `<Steps>/<Tabs>/<Aside>/<CardGrid>/<LinkCard>`.
- Author `site/src/content/docs/guides/maintainer.mdx` (hand-authored `.mdx`, D2/D3/D6, replaces feature-001 stub) at `guides/maintainer`: ONE page, two H2 runbooks. "Cut a release" derived faithfully from `docs/release.md` (CI path vs manual `release.sh` path in `<Tabs syncKey="release-path">`, `<Steps>` for the tag-push flow, `<Aside type="caution">` recovery/idempotency, verbatim flag/exit-code tables). "Regenerate the host-tool trees/profiles" grounded 1:1 in `.claude/skills/aid-generate/SKILL.md` (LOAD→VALIDATE→RENDER→VERIFY→REPORT, full `run_generator.py` + drift assertion, `/aid-generate` `--tool`/`--dry-run` skill interface, five profiles, emission-manifest boundary).
- All cross-links target live Starlight routes only (D8); neither page is added to feature-005's sync manifest.

**Acceptance Criteria:**
- [ ] `guides/pipeline.mdx` documents `aid-config` + the six numbered phases (Discover → Execute) with optional Deliver skills per v3.2; phase→skill names match `canonical/skills/` (AC3-partial).
- [ ] `guides/maintainer.mdx` "Cut a release" H2 faithfully reflects `docs/release.md` (every command/table/exit-code/recovery step), with CI vs manual paths tabbed.
- [ ] `guides/maintainer.mdx` "Regenerate trees" H2 documents the canonical render/generate workflow (full `run_generator.py` + render-drift convention, skill `--tool`/`--dry-run`).
- [ ] All internal cross-links target live routes; any Mermaid fences render as SVG (AC5-partial).
- [ ] Build passes; all existing tests still pass.
- [ ] All §6 quality gates pass.

# task-004: D2 — discovery-quality: add the `infrastructure.md` Output Document skeleton

**Type:** DOCUMENT

**Source:** work-002-canonical-bug-fixes → delivery-001

**Depends on:** — (none)

**Scope:**
- `canonical/agents/discovery-quality/AGENT.md` states it produces `.aid/knowledge/infrastructure.md`
  (line ~69) but its `## Output Documents` section (line ~86) embeds inline skeletons only for
  `test-landscape.md` and `tech-debt.md`. Add an `### .aid/knowledge/infrastructure.md` skeleton in
  the same inline style as its two siblings.
- Use the canonical KB template `canonical/templates/knowledge-base/infrastructure.md` as the source
  of truth for the skeleton's sections (hosting/networking/environments, deployment, source control,
  CI/CD, project management, etc.) so the embedded skeleton matches the KB template and the
  doc-ownership map (`skills/aid-discover/references/doc-set-resolve.md` assigns `infrastructure.md`
  to `discovery-quality`).

**Acceptance Criteria:**
- [ ] `discovery-quality/AGENT.md` `## Output Documents` contains an `infrastructure.md` skeleton
      consistent in style with the existing `test-landscape.md` / `tech-debt.md` skeletons.
- [ ] The skeleton's sections align with `templates/knowledge-base/infrastructure.md` (no invented or
      missing top-level sections).
- [ ] All §6 quality gates pass.

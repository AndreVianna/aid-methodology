# task-089: Re-inject AID's evicted depth (host-tool matrix, exit-codes) + regen INDEX

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-089/STATE.md.

**Type:** DOCUMENT

**Source:** work-001-kb-skills-improvement -> delivery-016

**Depends on:** task-088

**Scope:**
- Realize the **first-beneficiary** half of feature-016 Change 3 (FR-56): re-inject into **AID's own
  KB docs** the load-bearing operational depth the over-broad altitude rule evicted, under the new
  signature exception (task-088). DOCUMENT — this edits AID's `.aid/knowledge/*` doc **content**, not
  skill/script sources. This is the **only** feature-016 task that edits AID's own KB docs.
- **Re-inject the host-tool capability matrix** (the deleted `host-tool-capabilities.md` content /
  equivalent) and the **exit-codes** depth (schemas field-types 16->1, exit-codes 38->17) **inline or
  with a precise grep-recoverable anchor** into the relevant `.aid/knowledge/*.md` docs — stated as
  work-critical contracts an agent must honor to ACT, per the signature exception. (The
  assertiveness gate in task-090 would otherwise FAIL on the REACH for them.)
- **Regenerate `.aid/knowledge/INDEX.md`** via the **canonical** index builder
  (`canonical/aid/scripts/kb/build-kb-index.sh`, NOT the `.claude/` copy — the INDEX-md-canonical-regen
  lesson) so the KB-hygiene CI check passes on the embedded script path.
- Keep edits within AID's KB doc content; honor the dual-audience authoring standard (single-concern,
  junior-clear, tables-not-diagrams, classified, frontmatter -> index -> content -> changelog). This
  task **produces the depth**; task-090 **gates it** via the dogfood.

**Acceptance Criteria:**
- [ ] AID's previously altitude-rule-evicted depth — the **host-tool capability matrix** + the
  **exit-codes / field-types** contracts — is **re-injected** into the relevant `.aid/knowledge/*.md`
  docs **inline or with a precise grep-recoverable anchor** (never a bare `sources:` pointer), per
  the signature exception. *(FR-56)*
- [ ] `.aid/knowledge/INDEX.md` is **regenerated via the canonical builder**
  (`canonical/aid/scripts/kb/build-kb-index.sh`), not the `.claude/` copy. *(INDEX-canonical-regen lesson)*
- [ ] The re-injected content honors the **dual-audience authoring standard** (single-concern,
  junior-clear, classified, frontmatter/changelog). *(feature-014 authoring standard)*
- [ ] **DBI / doc-content sync:** the `.aid/knowledge/*` doc-content sync is clean (this delivery is
  the **only** one editing AID's own KB doc content); **KB-hygiene + INDEX-fresh** CI is green after
  the re-injected depth + regenerated INDEX. *(section-6)*
- [ ] All section-6 quality gates pass.

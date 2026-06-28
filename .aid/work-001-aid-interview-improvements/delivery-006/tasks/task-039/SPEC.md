# task-039: Full generator render of both new dirs + orphan-prune + mirror/manifests/docs regen

**Type:** CONFIGURE

**Source:** work-001-aid-interview-improvements -> delivery-006

**Depends on:** task-038

**Scope:**
- Execute Flow steps 4-6 (render side) of the feature SPEC: after the canonical carve (task-037) and
  the external sweep + count edits (task-038) are merged, run the generators ONCE to propagate the
  split to every host tree + the dogfood mirror, orphan-prune the old dir, and regenerate the
  docs-site outputs. This task authors NO content -- it only renders/propagates what 037/038 wrote.
- **(1) FULL host-tree render + orphan-prune.** Run `python
  .claude/skills/generate-profile/scripts/run_generator.py` (the FULL generator, NOT per-script
  renderers -- render-drift CI keys on the full emission manifests). The render emits
  `profiles/{antigravity/.agent,claude-code/.claude,codex/.codex,copilot-cli/.github,cursor/.cursor}/
  skills/aid-describe/` AND `.../aid-define/` byte-identically and PRUNES the now-absent
  `profiles/*/skills/aid-interview/` from each tree; each `profiles/*/emission-manifest.jsonl` is
  rewritten to reflect the swap (two new dirs in, one out).
- **(2) Dogfood mirror sync.** The generator also regenerates the `.claude/` dogfood mirror -- confirm
  `.claude/skills/aid-describe/` + `.claude/skills/aid-define/` exist (byte-identical to the
  claude-code profile tree) and `.claude/skills/aid-interview/` is gone.
- **(3) Dogfood install manifest path-replace (NOT generator-emitted).** `.aid/.aid-manifest.json` is
  not written by `run_generator.py`; hand-update it -- replace every `.claude/skills/aid-interview/...`
  path with the correct `.claude/skills/aid-describe/...` or `.claude/skills/aid-define/...` path (two
  entry sets in, one removed), matching the new mirror.
- **(4) Docs-site regen.** Regenerate the generated docs from the task-038 `gen-reference.mjs` source
  edit: run the site generator so `site/src/content/docs/reference/skills.md` (do-not-edit generated
  file) is regenerated with the two new entries and the count `14`; run `sync-docs.mjs` to sync
  `docs/aid-methodology.md` -> `site/.../concepts/methodology.md` (so the spelled-out + numeric counts
  stay in lockstep). The `gen-reference.mjs` skills-drift guard must pass against the on-disk
  `canonical/skills/` listing (it throws if SKILL_GROUPS != disk).
- **(5) Idempotency + integrity.** Re-running the generators yields NO diff (render-drift clean,
  deterministic); ASCII-only preserved through the render; no plaintext secrets introduced.
- **Out of scope:** authoring/altering any canonical or source CONTENT (tasks 037/038 own that); the
  verification runs incl. DBI + substring guard + CI green (task-040).

**Acceptance Criteria:**
- [ ] FULL `run_generator.py` executed: each `profiles/*/skills/aid-describe/` + `aid-define/` exists,
  each `profiles/*/skills/aid-interview/` is orphan-pruned, and each `emission-manifest.jsonl` reflects
  the two-in/one-out swap. *(gate criterion 2 / AC-2, DoD 4)*
- [ ] The `.claude/` dogfood mirror has `aid-describe/` + `aid-define/` (byte-identical to the
  claude-code profile) and no `aid-interview/`; `.aid/.aid-manifest.json` paths are replaced for both
  new dirs with the old removed. *(gate criterion 2,3 / AC-2,AC-3)*
- [ ] Docs-site regenerated: `site/src/content/docs/reference/skills.md` shows the two new entries +
  count `14`; the `gen-reference.mjs` skills-drift guard passes against disk; methodology site copy is
  synced from `docs/` (spelled-out + numeric counts consistent). *(gate criterion 3 / AC-3, DoD 6)*
- [ ] Render is idempotent/deterministic -- re-running both generators produces NO diff (render-drift
  CI clean). *(CONFIGURE idempotent default)*
- [ ] Configuration is idempotent; no plaintext secrets; shipped content stays ASCII-only through the
  render. *(CONFIGURE defaults)*
- [ ] All REQUIREMENTS.md §6 quality gates apply at task-040 (DBI byte-identity + the master-only heavy
  gates are asserted there).

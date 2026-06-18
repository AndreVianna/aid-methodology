# task-010: Wire the cornerstone into the reviewer's standing criteria

**Type:** DOCUMENT

**Source:** work-003-content-isolation → delivery-001

**Depends on:** task-009

**Scope:**
- Wire the content-isolation cornerstone into the reviewer's standing criteria so future changes are checked for AID/user isolation. The reviewer evaluates against "KB conventions"; make the cornerstone discoverable and citable as a standing check (add a concrete check item referencing the task-009 KB doc).
- Edit target: the reviewer persona source is `canonical/agents/aid-reviewer/AGENT.md` (a CANONICAL source — wire the check there, NOT in a one-off rendered `.claude/` copy). Per the render-drift rule, after editing canonical run the FULL generator (`.claude/skills/generate-profile/scripts/run_generator.py`) so the change re-renders into every profile's reviewer agent; do not hand-edit rendered profile copies.
- The check item: any new AID-delivered file is either nested under `aid/` or `aid-`-prefixed; flag any un-prefixed AID file outside an `aid/` subtree, and any AID-own dir (`scripts`/`templates`/`recipes`) emitted outside the `aid/` nest.

**Acceptance Criteria:**
- [ ] The reviewer's standing criteria reference the content-isolation cornerstone and the task-009 KB doc as the citable source.
- [ ] The added check item explicitly covers: `aid/`-nest for AID-own dirs, `aid-` prefix for tool-native AID files, and flagging un-prefixed AID files outside an `aid/` subtree.
- [ ] The wiring is consistent with how the reviewer currently cites KB conventions (no new bespoke mechanism).
- [ ] The check is added to the canonical source `canonical/agents/aid-reviewer/AGENT.md` and the FULL generator was re-run so every profile's reviewer agent reflects it (render-drift clean); no rendered `.claude/` copy was hand-edited.
- [ ] All §6 quality gates pass.

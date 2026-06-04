# task-013: Update KB + agent-count/tier docs (FR8)

**Type:** DOCUMENT

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-006

**Scope:**
- Refresh every agent-count / tier / roster statement to the new roster, with literals derived from the post-rollout `canonical/agents/` count and the new `proposed_tier` distribution (feature-002 SPEC → KB & Count Updates; AC6). Known sites:
  - `module-map.md` line 6; line 15 (T1 fact); lines 98–146 (§2a/2b/2c per-tier rosters+counts and the line-146 boilerplate-presence claim — reconcile with the Format decision and the disk-measured A5/B6 truth).
  - `architecture.md` lines 38, 64 (counts; AGENT.md+README.md shape only if the Format decision keeps it); lines 190–197 §3 tier model/diagram.
  - `README.md` lines 231, 323, 369 (agent counts).
- Discover any other agent-describing KB doc via `.aid/knowledge/INDEX.md` and grep for the literal old count ("22 agent") and OLD agent names; update each.
- Extend the proactive scan beyond KB docs to the non-KB count/name-bearing docs named by the SPEC's FR8/AC6: `coding-standards.md` and `CONTRIBUTING.md` (architecture.md, module-map.md, README.md are already enumerated above). The update-set must equal task-014's verify-set so no OLD name or stale count first surfaces only at the terminal sweep — scan and update these here.
- If `INDEX.md` is regenerated, regenerate it via `canonical/scripts/kb/build-kb-index.sh` (not the `.claude/` copy) so the KB-hygiene CI check stays green.
- Documentation update only; no source rewire, no generator run, no generated-tree or repo-root `.claude/` dogfood edits. Derives values from the new roster (task-006), not from rendered trees, so it may run in parallel with task-012.

**Acceptance Criteria:**
- [ ] AC6: every site in the KB & Count Updates table shows the new count + tier split; no stale "22 agent" literal or OLD agent name survives in `.aid/knowledge/**`, `README.md`, `coding-standards.md`, or `CONTRIBUTING.md`.
- [ ] The line-146 boilerplate-presence claim is reconciled with the Format decision and the disk-measured truth (B6).
- [ ] Any `INDEX.md` regen used `canonical/scripts/kb/build-kb-index.sh`; KB-hygiene CI check stays green.
- [ ] DOCUMENT baseline: every literal is derived from the post-rollout roster (B5), not a pre-assumed count.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.

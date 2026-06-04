# task-014: Repo-wide consistency sweep + determinism + build validation (FR9)

**Type:** TEST

**Source:** feature-002-roster-rollout → delivery-002

**Depends on:** task-012, task-013

**Scope:**
- Run the FR9 repo-wide consistency sweep + the AC5 build/determinism gates as the terminal verification (feature-002 SPEC → Consistency Check Method; Regeneration & Build Validation; AC4/AC5).
- Build the OLD-name sweep set from `design/migration-map.md` = every `old_agent` with disposition ∈ {merge, rename, drop} (`keep` excluded); word-boundary-grep each across SOURCE (`canonical/**`, the `aid-generate` SOURCE-exception), KB (`.aid/knowledge/**`, `README.md`, `CONTRIBUTING.md`, `coding-standards.md`), and all five `profiles/<tool>/` rendered trees. The repo-root `.claude/` dogfood tree is EXCLUDED (B2 — not a generator output, no in-repo sync).
- Assert zero matches; for any match, attribute it (generated-tree → re-render is task-012; count-doc → task-013 missed; `canonical/` → a rewire task missed) and flag back to the owning task; re-run until clean.
- Run the build gates: `verify_deterministic.py --canonical-root .` exits 0 (byte-identical re-render + presence audit + frontmatter parse); `render_agents.py --self-test` passes for all five profiles; `canonical/scripts/grade.sh` + CI `test.yml`/`tests/run-all.sh` pass; KB-hygiene check green.
- Closure check: `canonical/agents/` directory set == `proposed_agent` set from `target-roster.md`.
- Verification only — this task does not author, rewire, or regenerate; it asserts and flags.

**Acceptance Criteria:**
- [ ] AC4: the sweep returns zero matches for every OLD-name across SOURCE + KB + templates + recipes + all five `profiles/<tool>/` trees (repo-root `.claude/` excluded per B2); closure check passes.
- [ ] AC5: `/aid-generate` build gates pass — `verify_deterministic.py` exits 0, `render_agents.py --self-test` passes for all five profiles, `grade.sh` + CI `test.yml`/`tests/run-all.sh` pass.
- [ ] All matching/grep uses word-boundary matching (no `architect` ⊂ `discovery-architect` false positives); `keep` names are correctly excluded from the sweep set.
- [ ] TEST baseline: the sweep + gates are deterministic and reviewer-runnable, cover the source ACs (AC4 + AC5), and any failure is attributed to the owning task.
- [ ] All REQUIREMENTS.md §6 (Non-Functional Requirements) baseline criteria are met.

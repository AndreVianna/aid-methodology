# task-001: Deployment-mechanism comparison + scored recommendation

**Type:** RESEARCH

**Source:** work-002-auto-installer → delivery-001

**Depends on:** — (none)

**Scope:**
- Produce a written, scored comparison of candidate deployment mechanisms for installing
  AID into an adopter repo: `curl … | bash` / `irm … | iex` one-liner hosted off GitHub;
  versioned GitHub Release tarball + tiny bootstrap; `npx` / `pipx` published CLI;
  `gh` extension; `degit` / sparse-checkout.
- Score each against the SPEC's eight axes: zero-clone footprint, host-tool detection,
  cross-platform (bash + PowerShell), update path, uninstall, online/offline support,
  minimal-dependency fit, and maintainer upkeep.
- Check each candidate against AID's actual constraints from the KB: no third-party
  runtime deps (`technology-stack.md`); no existing release/package-registry pipeline
  (`infrastructure.md` — the canonical→5-profile render is the only build artifact
  pipeline); git/curl/tar and PowerShell as the available baseline toolchain; the
  installer fetches one rendered profile tree, not the whole repo (the five trees are
  claude-code `.claude/`, codex `.agents/`(+`.codex/`), cursor `.cursor/`,
  copilot-cli `.github/`+root `AGENTS.md`, antigravity `.agent/`+root `AGENTS.md`).
- End with exactly ONE recommended mechanism plus rationale.
- Produces a decision artifact only — no installer code. This decision gates task-002,
  task-003, and task-004.

**Acceptance Criteria:**
- [ ] A written comparison of the candidate mechanisms exists, each scored against the eight SPEC axes. (SPEC AC-2)
- [ ] The comparison ends in a single recommended mechanism with explicit rationale grounded in AID's KB constraints (minimal deps, no release pipeline, fetch-one-tree). (SPEC AC-2, de-risks AC-6 and AC-8)
- [ ] The recommendation explicitly states whether the chosen mechanism supports both online and offline modes and how. (SPEC AC-8)
- [ ] A checkpoint note states whether the recommendation keeps the work within the lite 4-task scope or warrants escalation to the full path (e.g., if it forces packaging/registry publishing). (Process safeguard feeding the SPEC re-plan checkpoint; intentionally not traced to a SPEC acceptance criterion.)
- [ ] The recommendation document passes review — clear, complete, and grounded in the KB constraints. (This RESEARCH task produces a decision artifact, not code, so the gate is documentation-quality review, not build/test gates.)

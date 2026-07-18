# State: IDLE

No active release; assess eligible deliveries and transition to SELECTING.

### Step 1: Assess

Read all inputs. Build a picture:
- Which deliveries are complete (all tasks done, all grades ≥ minimum)?
- Which deliveries are partially complete?
- Which deliveries are already shipped (from prior packages)?
- What does infrastructure.md § Deployment say about packaging?
  - Build output type (executable, container, package, library, static site, installer)
  - Target (app store, registry, cloud, on-prem, CDN)
  - CI/CD pipeline (if any)
  - Versioning scheme (semver, calver, custom)
  - Environment details (runtime, config, secrets, dependencies)

If infrastructure.md has no Deployment section or it's a placeholder:
→ Ask the user how this project gets packaged and deployed.
→ Write a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` to capture the answer.

Update work `STATE.md` `## Deploy State`: Status → Selecting.

Emit pipeline lifecycle state (silent state-write only — no output, no gate). Deploy is a
separate path, not a numbered phase, so this does NOT change the work's `Phase` (it stays at
`Execute`); it only marks the Running lifecycle + active skill so the work-initiation gate can
resume an interrupted deploy via `active_skill: aid-deploy`:
```
bash .claude/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .claude/aid/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value aid-deploy
bash .claude/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Advance:** **CHAIN** → [State: SELECTING] (continue inline).

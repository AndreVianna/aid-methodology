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

If infrastructure.md has no Deployment section or it's a placeholder, SELECTING asks how this
project gets packaged and deployed, in the same question exchange (see `references/state-selecting.md`).

Update work `STATE.md` `## Deploy State`: Status → Selecting.

Emit pipeline lifecycle state (silent state-write only — no output; a failed write stops the run). Deploy is a
separate path, not a numbered phase, so this does NOT change the work's `Phase`; it only marks the
Running lifecycle + active skill so the work-initiation gate can
resume an interrupted deploy via `active_skill: aid-deploy`:
```
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .aid/runtime/scripts/execute/writeback-state.sh --step --skill aid-deploy --name IDLE
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Advance:** **CHAIN** → [State: SELECTING] (continue inline).

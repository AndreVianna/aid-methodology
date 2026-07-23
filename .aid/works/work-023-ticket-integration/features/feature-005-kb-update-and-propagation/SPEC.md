# KB Update & Canonical Propagation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | Feature identified from REQUIREMENTS.md §5 FR-12, FR-13; §4 | /aid-define |
| 2026-07-22 | Cross-ref cycle-1 FIX: added the discovery-guidance site (document-expectations.md), dropped PM-tool "entity mapping"; reframed KB citation off a literal § heading (implementer confirms on-disk section) | /aid-define (cross-reference) |
| 2026-07-22 | Technical Specification authored | /aid-specify |
| 2026-07-22 | Review cycle-1 FIX: regrounded the no-context-file citation rule in AC-13 (not authoring-conventions.md); corrected test-aid-cli-parity.sh CI lanes (ubuntu bash-harness + canonical-tests, not native-ps1) | /aid-specify (review-fix) |

## Source

- REQUIREMENTS.md §5 FR-12, FR-13; §4 Scope

## Description

Finalize the work by updating the knowledge base and propagating every change through AID's
build chain. On the guidance side, `aid-discover/references/document-expectations.md`'s
Project-Management investigation prompt drops the PM-tool "entity mapping" (Epic/Story/Task
automation-hierarchy) item while keeping "which project-management tool (or none) + access method"
— which now feeds the connector model; and the KB's project-management guidance documents the new
connectors + dedicated-skills model instead of automated ticket operations, cited by its actual
on-disk section/role (the implementer confirms the real heading — the `infrastructure.md` template
carries no literal "Project Management" heading), citing only other KB docs or source, never a
context file. A per-project `infrastructure.md` still records the project's tracker; the automated-
operation instructions lived in the skills and are retired by feature-002. All edits across the
work are authored in `canonical/` and re-emitted through the generator to every `profiles/*` tool
profile, and the dogfood `.claude/` tree is resynced from `profiles/claude-code/`. The byte/path-
parity and CLI-parity test suites confirm the generated copies differ from canonical only by the
path-prefix rewrite, so the whole change ships consistently across every host tool.

## User Stories

- As a KB owner, I want the discovery guidance and KB project-management guidance to describe the
  connectors + dedicated-skills model instead of PM-tool automation so that the docs reflect how
  tracker interaction actually works now.
- As an AID methodology maintainer, I want every edit authored in `canonical/` and re-emitted to
  all profiles with the dogfood tree resynced so that all host tools receive the identical change.
- As an AID methodology maintainer, I want the byte/path-parity and CLI-parity suites to stay green
  so that I know the generated profiles match canonical exactly except for the path rewrite.

## Priority

Must

## Acceptance Criteria

- [ ] Given the work is complete, when the build is run, then all edits were authored in
  `canonical/`, re-emitted to every `profiles/*`, and the dogfood `.claude/` is resynced, and the
  byte/path-parity and CLI-parity tests are green.
- [ ] Given the KB update is complete, when the discovery guidance and KB project-management
  guidance are reviewed, then `document-expectations.md` no longer prompts for PM-tool automation
  "entity mapping" (it retains "which tracker (or none) + access method") and the KB documents the
  connectors + dedicated-skills model, cited by its actual on-disk section, with no KB citation to
  a context file.

---

## Technical Specification

> Grounded in `architecture.md` ("Build & Distribute Architecture (canonical -> profiles -> packages)"; the "VERIFY (deterministic)" byte-compare gate; the render-drift Invariant; the "`generate-profile` is maintainer-only" Gotcha), `infrastructure.md` ("The Build: Multi-Profile Render"; the `## Project Management Tooling` section), `test-landscape.md` ("Render-Drift and Generator Self-Tests"; the dogfood byte-identity + CLI-parity suites; "CI Lanes and Where They Run"), `authoring-conventions.md` (the Citation Rule for durable anchors; "INDEX regeneration"), and `integration-map.md` (the `## Connectors` catalog model). This feature is the **terminal** step of the work: it makes the two guidance edits, then renders the FULLY-edited `canonical/` tree (features 001-004 + this feature's discovery-guidance edit) once through the generator and resyncs the dogfood `.claude/`.

### Data Model

**None.** Feature-005 introduces no schema, field, or template change. The `document-expectations.md` change is a prose deletion; the KB change is prose added to an existing section; the render/resync moves bytes only. The `ticket_ref` LOCAL-LINK and every state/spec template are untouched (they are feature-004 / FR-11 concerns). No migration.

### Feature Flow

Two guidance edits (a), then the render + resync propagation (b). There is no runtime surface — these are authoring + build actions performed during `/aid-execute`.

**(a) Guidance edits.**

- **Discovery guidance (canonical, rendered).** In `canonical/skills/aid-discover/references/document-expectations.md`, the `### infrastructure.md` block's investigation parenthetical currently reads `Project Management section -- tool or "none", access method, entity mapping if applicable`. Drop only the PM-tool automation clause — `, entity mapping if applicable` — leaving `Project Management section -- tool or "none", access method`. The block's lead open question ("what project management tool is used (or say 'none')?") and its red flag ("Project Management section absent -- should explicitly say 'none' if no tool is used") are KEPT verbatim: "which tracker (or none) + access method" now feeds the connector model (a tracker maps to a registered `issue-tracker` connector), while the dropped "entity mapping" (the Epic/Story/Task automation-hierarchy the retired PM-TOOL writes consumed) has no consumer after feature-002.
  - **Contract (exact edit):** delete the single `, entity mapping if applicable` clause from that one parenthetical; no other line in the `### infrastructure.md` block changes. Durable anchor: `document-expectations.md` `### infrastructure.md`, the "Project Management section" investigation slot.

- **KB project-management guidance (dogfood KB, NOT rendered).** The doc is `.aid/knowledge/infrastructure.md`; the actual on-disk section is `## Project Management Tooling` (confirmed on disk — this is the real heading). No heading is titled exactly "Project Management" (the KB doc's is `## Project Management Tooling`; the `document-expectations.md` template refers to a "Project Management section" only in prose), so the retired PM-TOOL model's `infrastructure.md § Project Management` label never named a real section — cite the real one, `## Project Management Tooling`. Update that section to document the current model: outward tracker interaction happens through AID's connectors registry plus the three dedicated skills (`/aid-read-ticket`, `/aid-create-ticket`, `/aid-update-ticket`) — never through automated ticket writes embedded in pipeline skills. Keep the existing statement that AID itself uses no external tracker and tracks its own work in-repo (that is AID's own reality; the added note describes how a project that DOES have a tracker now interacts with it).
  - **Citation contract (AC-13):** cite the connector catalog by the KB->KB durable anchor `integration-map.md` `## Connectors`; cite the skills by KB->source anchors (`canonical/skills/aid-read-ticket/`, `canonical/skills/aid-create-ticket/`, `canonical/skills/aid-update-ticket/`) and the shared ladder `canonical/aid/templates/connectors/ticket-resolution.md` (feature-001). NEVER cite the root context file (`CLAUDE.md` / `AGENTS.md`) — even though it also mentions connectors, the KB cites KB->KB / KB->source only. Add a `## Change Log` row (Change Log stays the last section per the KB layout).

**(b) Propagation (the terminal render).**

1. Confirm every canonical edit from features 001-004 has landed (the 3 new skills + shared `ticket-resolution.md`; the retired PM-TOOL writes; the rerouted read/comment seams; the revised `consumption-protocol.md`) plus this feature's `document-expectations.md` edit.
2. Run the FULL generator once: `python .claude/skills/generate-profile/scripts/run_generator.py`. It renders `canonical/` into all five `profiles/*` trees (`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`), rewrites each `emission-manifest.jsonl`, and runs its own VERIFY (deterministic) byte-compare gate.
3. Resync the dogfood `.claude/`: copy the freshly-rendered `profiles/claude-code/.claude/` tree over the repo-root `.claude/` (the same content the installer copies via `lib/aid-install-core.sh`).
4. Verify (see Testing).

**Reality / gotchas (do not trip these):**
- **Run the FULL `run_generator.py`, not a per-script renderer** — otherwise render-drift fails on stale emission manifests (`architecture.md` Gotchas; `test-landscape.md` closing note).
- **The generator writes only `profiles/*`; it does NOT touch the repo-root dogfood `.claude/`.** There is no repo-root `setup.sh` script — the "setup.sh" the requirements/assumptions reference is shorthand for the install-path copy (`lib/aid-install-core.sh`). The dogfood resync is therefore an explicit, separate step (step 3), and `test-dogfood-byte-identity.sh` is what proves it was done.
- **The KB doc edit is a direct dogfood-KB edit — NOT rendered from `canonical/` and NOT part of byte-parity** (the KB under `.aid/knowledge/` is hand-authored working state, not a render output). Do not place it in `canonical/`; do not expect it to appear in `profiles/`.

### Layers & Components

| Artifact | Kind | Edited how | Verified by |
|---|---|---|---|
| `canonical/skills/aid-discover/references/document-expectations.md` (`### infrastructure.md` block) | canonical source (rendered to all 5 profiles) | drop the `, entity mapping if applicable` clause | render-drift + `test-dogfood-byte-identity.sh` |
| `.aid/knowledge/infrastructure.md` (`## Project Management Tooling`) | dogfood KB doc (NOT rendered; NOT `INDEX.md`) | document the connectors + dedicated-skills model; add a Change Log row | `test-kb-citation-lint.sh`, `test-frontmatter-lint.sh`, KB-hygiene INDEX freshness |
| `python .claude/skills/generate-profile/scripts/run_generator.py` | maintainer-only generator (lives only in `.claude/`, not a shipped `canonical/skills/`) | invoked, never edited | its own VERIFY gate + the `render-drift` CI job |
| `profiles/*` (5 trees) + repo-root `.claude/` dogfood | build output | regenerated / resynced, never hand-edited | `test-dogfood-byte-identity.sh` + render-drift |
| `tests/canonical/test-aid-cli-parity.sh` | CLI-parity suite | not edited — must stay green | ubuntu `bash-harness` (`installer-tests.yml`) + `canonical-tests` (`test.yml`, via `run-all.sh`) |

- The generator is **maintainer-only** (`architecture.md` "generate-profile is maintainer-only") — it is not one of the shipped `canonical/skills/`.
- `.aid/knowledge/INDEX.md` is **generated** (`authoring-conventions.md` "INDEX regeneration"); never hand-edit it. If the infrastructure.md doc summary shifts, regenerate via `canonical/aid/scripts/kb/build-kb-index.sh` — but a small addition to an existing section is not expected to change the 2-3 line summary.

### Migration Plan / Sequencing

Feature-005 is **terminal by construction.** The generator renders the whole `canonical/` tree in one pass, and the byte-identity + render-drift gates compare the ENTIRE `profiles/*` against a fresh render — so the render must run ONCE, over the FULLY-edited canonical tree, only after features 001-004's canonical edits AND this feature's `document-expectations.md` edit are all in place. Rendering earlier produces profiles that will not match the final canonical and forces a re-run.

Order:
1. Features 001-004 land all canonical edits (skills, PM-TOOL retractions, seam reroutes, `consumption-protocol.md`).
2. Feature-005 makes the `document-expectations.md` edit.
3. Run `python .claude/skills/generate-profile/scripts/run_generator.py` (single pass; renders + VERIFY).
4. Resync the dogfood `.claude/` from `profiles/claude-code/.claude/`.
5. Make the KB doc edit (`.aid/knowledge/infrastructure.md § Project Management Tooling`) — independent of the render; it may be done in parallel, but it ships in this feature.
6. Run the full gate (Testing). Commit `canonical/` + `profiles/*` + the dogfood `.claude/` + the KB doc together, so render output always travels with its source and render-drift stays green on every commit.

No data migration; no backward incompatibility (NFR-3) — a project with no `issue-tracker` connector and no `ticket_ref` is unaffected by the guidance/KB text.

### Testing

The heavy correctness gates run master-only / on release tags (`test-landscape.md` "CI Lanes and Where They Run"); run them locally before claiming green, HOME-pinned so the migration scan cannot touch real repos: `HOME="$(mktemp -d)" bash tests/run-all.sh`.

**AC-12 — canonical re-emitted to every profile + dogfood resynced; byte/path- and CLI-parity green:**
- **Render-drift (the load-bearing gate):** `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/` — a fresh render must equal the committed `profiles/*` (`test-landscape.md` "Render-Drift and Generator Self-Tests"; `test.yml` `render-drift`, mirrored in `release.yml` `gate`).
- **Byte/path parity:** `bash tests/canonical/test-dogfood-byte-identity.sh` — asserts the repo-root dogfood `.claude/` is byte-identical to `profiles/claude-code/.claude/` for every generator-owned manifest path (its three-direction guard: forward, reverse, orphan-sweep).
- **CLI parity:** `bash tests/canonical/test-aid-cli-parity.sh` — bash<->PowerShell behavior parity. It runs on the ubuntu `bash-harness` lane (`installer-tests.yml`) and the `canonical-tests` job (`test.yml`, via `run-all.sh`) — never on a Windows CI runner (the `native-ps1` matrix runs only `Test-AidInstaller.ps1` / `Test-InstallProvisioning.ps1`). This change does not touch the CLI, so the suite must simply stay green; a regression here would flag an unexpected side effect. NFR-4 names both `test-dogfood-byte-identity` and the CLI-parity suite.
- Both suites are glob-discovered by `tests/run-all.sh` (no runner edit needed). Confirm the three new `aid-*-ticket` skills and every features-001-004 edit are present in each of the 5 profiles and the dogfood tree.

**AC-13 — guidance/KB text correct + citation-clean:**
- Per-site check (not only a grep): `document-expectations.md` `### infrastructure.md` no longer contains `entity mapping`, and still contains `tool or "none"` + `access method`.
- `.aid/knowledge/infrastructure.md § Project Management Tooling` documents the connectors + dedicated-skills model.
- Citation discipline: `bash tests/canonical/test-kb-citation-lint.sh` enforces the durable-anchor form (`authoring-conventions.md` Citation Rule; rejects a bare `file:LINE`) + `bash tests/canonical/test-frontmatter-lint.sh`. The KB->KB / KB->source-only + no-citation-to-a-context-file rule comes from this work's **AC-13** (and FR-13) — not from `authoring-conventions.md`, whose Citation Rule covers only durable-anchor-vs-bare-line form — and is review-verified: grep the KB edit for any `CLAUDE.md` / `AGENTS.md` citation and confirm zero.
- INDEX freshness: the KB-hygiene CI lane checks the generated `INDEX.md`; if the doc summary changed, regenerate via `build-kb-index.sh` (canonical path), never hand-edit.

### Boundaries (this feature only)

Feature-005 does NOT author the three ticket skills or the shared `ticket-resolution.md` (feature-001), does NOT retract the PM-TOOL writes (feature-002), does NOT reroute the read/comment seams or remove `aid-execute`'s status-mirror / `aid-plan` Step 4c write half (feature-003), and does NOT revise `consumption-protocol.md` (feature-004). It makes the two guidance edits (`document-expectations.md` + the KB `## Project Management Tooling` section) and runs the single terminal render + resync + parity pass that propagates the ENTIRE work across all five profiles and the dogfood tree. Changing the connector-descriptor schema, the preset catalog, `grade.sh`, or the CLI is out of scope (REQUIREMENTS §4 Out of Scope).

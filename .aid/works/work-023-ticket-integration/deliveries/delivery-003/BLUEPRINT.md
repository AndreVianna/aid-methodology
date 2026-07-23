# Delivery BLUEPRINT -- delivery-003: KB update + canonical propagation

> **Delivery:** delivery-003
> **Work:** work-023-ticket-integration
> **Created:** 2026-07-22

---

## Objective

Finalize and ship the work. Make the two guidance edits -- drop the PM-tool automation "entity
mapping" clause from the discovery guidance (`canonical/skills/aid-discover/references/document-expectations.md`,
keeping "which tracker (or none) + access method"), and update the KB's `## Project Management
Tooling` section (`.aid/knowledge/infrastructure.md`) to document the connectors + dedicated-skills
model with KB->KB / KB->source citations only -- then run the generator ONCE over the FULLY-edited
`canonical/` tree (every features-001-004 canonical edit plus this feature's discovery-guidance
edit), resync the dogfood `.claude/` from `profiles/claude-code/.claude/`, and confirm the
byte/path-parity + CLI-parity suites stay green so the whole change ships consistently across all
five host-tool profiles. This delivery is terminal by construction: the render + byte-identity gates
compare the ENTIRE `profiles/*` against a fresh render, so the single render must run only after all
prior deliveries' canonical edits are in place.

## Scope

**In scope (feature-005-kb-update-and-propagation):**
- **Discovery-guidance edit (canonical, rendered):** delete the single `, entity mapping if
  applicable` clause from the `### infrastructure.md` block's "Project Management section"
  investigation parenthetical in `document-expectations.md`; keep the lead open question and the
  red flag verbatim.
- **KB project-management guidance (dogfood KB, NOT rendered):** update
  `.aid/knowledge/infrastructure.md` `## Project Management Tooling` to document the connectors +
  dedicated-skills model (outward interaction via the connectors registry + the three skills, never
  automated ticket writes); keep the statement that AID itself uses no external tracker; add a
  Change Log row. Cite by KB->KB (`integration-map.md` `## Connectors`) + KB->source
  (`canonical/skills/aid-{read,create,update}-ticket/`, `ticket-resolution.md`); never cite a
  context file (`CLAUDE.md`/`AGENTS.md`).
- **Terminal render + resync + gate:** confirm all features-001-004 canonical edits landed, run
  `python .claude/skills/generate-profile/scripts/run_generator.py` once (renders all five profiles,
  rewrites emission manifests, runs its own VERIFY), resync dogfood `.claude/` from
  `profiles/claude-code/.claude/`, then run the full gate.

**Out of scope:** authoring the three skills / shared ladder (feature-001 / delivery-001);
retracting PM-TOOL writes (feature-002 / delivery-002); rerouting seams or removing the status-mirror
/ splitting `aid-plan` Step 4c (feature-003 / delivery-002); revising `consumption-protocol.md`
(feature-004 / delivery-002). Changing the connector-descriptor schema, the preset catalog,
`grade.sh`, or the CLI. Hand-editing any `profiles/*` or the generator. Regenerating `INDEX.md` is
only needed if the doc summary shifted (small addition to an existing section is not expected to).

## Gate Criteria

- [ ] **Discovery-guidance edit (AC-13):** `document-expectations.md` `### infrastructure.md` no
  longer contains `entity mapping`, and still contains `tool or "none"` + `access method`; no other
  line in that block changed.
- [ ] **KB guidance + citation discipline (AC-13):** `.aid/knowledge/infrastructure.md`
  `## Project Management Tooling` documents the connectors + dedicated-skills model, cited by its
  actual on-disk section; `test-kb-citation-lint.sh` + `test-frontmatter-lint.sh` pass; a grep of
  the KB edit for any `CLAUDE.md` / `AGENTS.md` citation returns zero; a Change Log row is added and
  Change Log remains the last section; `INDEX.md` freshness holds (regenerate via
  `build-kb-index.sh` only if the summary shifted -- never hand-edit).
- [ ] **Terminal render completeness (feature-005 §Migration/Sequencing; PLAN.md R1):** all
  features-001-004 canonical edits (the 3 new skills + shared `ticket-resolution.md`; the six
  PM-TOOL retractions; the rerouted read/comment seams + the `aid-execute` mirror removal + the
  `aid-plan` Step 4c split; the revised `consumption-protocol.md`) are confirmed present BEFORE the
  render; the FULL `run_generator.py` runs ONCE and renders `canonical/` into all five `profiles/*`
  trees, rewrites each `emission-manifest.jsonl`, and passes its own VERIFY.
- [ ] **Dogfood resync:** the dogfood `.claude/` is resynced from `profiles/claude-code/.claude/`
  (the install-path copy content); the three `aid-*-ticket` skills and every features-001-004 edit
  are present in each of the 5 profiles and the dogfood tree.
- [ ] **Byte/path-parity + render-drift (AC-12, NFR-4):** a fresh render equals the committed
  `profiles/*` (`run_generator.py && git diff --exit-code -- profiles/`);
  `test-dogfood-byte-identity.sh` is green (dogfood `.claude/` byte-identical to
  `profiles/claude-code/.claude/` for every generator-owned path).
- [ ] **CLI parity (AC-12, NFR-4):** `test-aid-cli-parity.sh` stays green (this change does not
  touch the CLI -- a regression would flag an unexpected side effect).
- [ ] **Backward compatibility (NFR-3):** a project with no `issue-tracker` connector and no
  `ticket_ref` is unaffected by the guidance/KB text.
- [ ] All section-6 quality gates pass (`minimum_grade` A+).

## Tasks

_none yet_ (aid-detail fills this later)

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-002 (which itself depends on delivery-001) -- the terminal render must
  capture ALL prior canonical edits; rendering before features 001-004 land produces profiles that
  will not match the final canonical and forces a re-run.
- **Blocks:** -- (none) -- terminal delivery

## Notes

- **Terminal by construction (PLAN.md Cross-Cutting Risk R1).** Run the FULL `run_generator.py`,
  NOT a per-script renderer (else render-drift fails on stale emission manifests). The generator
  writes only `profiles/*` -- it does NOT touch the repo-root dogfood `.claude/`; the resync is an
  explicit separate step (there is no repo-root `setup.sh` -- the resync is the install-path copy
  content, `lib/aid-install-core.sh`). The KB doc edit is a DIRECT dogfood-KB edit -- NOT rendered
  from `canonical/`, NOT part of byte-parity; do not place it in `canonical/`.
- Commit `canonical/` + `profiles/*` + the dogfood `.claude/` + the KB doc together so render output
  always travels with its source and render-drift stays green on every commit.
- Heavy gates run master-only / on release tags; run locally HOME-pinned before claiming green
  (`HOME="$(mktemp -d)" bash tests/run-all.sh`).
- No `issue-tracker` connector is catalogued for THIS repo, so the delivery's own `ticket_ref` is `--`.

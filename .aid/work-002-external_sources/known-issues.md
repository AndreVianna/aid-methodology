# Known Issues

<!-- Scoped to this work. Only issues that affect features in this work. -->
<!-- Created/updated by aid-specify during codebase exploration. -->
<!-- Consumed by aid-plan for deliverable sequencing. -->

<!-- Entry format:
## KI-NNN: {Title}
- **Type:** Bug | Security | Deprecated Dependency | Breaking API Contract
- **Severity:** Critical | High | Medium
- **Affects:** feature-NNN-{name}, feature-NNN-{name}
- **Source:** {file path}:{line} or {dependency}:{version}
- **Description:** {what's wrong and why it matters for the affected features}
- **See also:** tech-debt.md #TD-NNN (if already catalogued in KB)
-->

## KI-001: read-setting.sh resolves only 2-level dotted paths

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-001-integration-store-placement, feature-005-registry-persistence-and-consumption, feature-006-idempotent-reconcile
- **Source:** `canonical/aid/scripts/config/read-setting.sh` (usage block: `--path <dotted.path>`; validation rejects non-`A.B` paths) — confirmed by `canonical/skills/aid-discover/references/state-generate.md` (Step 5b hand-greps `discovery.closure.*` because "`read-setting.sh` … resolves only 2-level `section.key` paths").
- **Description:** The standard config accessor cannot read a nested registry. Any design that assumes the connectors registry is read via `read-setting.sh` will fail. feature-001 therefore specifies a dedicated Bash+PowerShell twin frontmatter accessor for `.aid/connectors/` descriptors, NOT `read-setting.sh` reuse.

## KI-002: root `.gitignore` carries a duplicated ignore set (resolved-by-design for this work)

- **Type:** Bug
- **Severity:** Medium
- **Affects:** pre-existing repo debt — NOT in this work's write path (see Resolution)
- **Source:** `.gitignore` — manual entries (`.aid/.temp/`, `.aid/.trash/`, `.aid/.heartbeat/`, `.aid/generated/`, `.aid/knowledge/.cache/`) are repeated inside the `# >>> AID managed -- do not edit (aid add/update maintains this block) >>>` block.
- **Description:** The root `.gitignore` duplicates several `.aid/` ignore entries across its manual section and the installer's AID-managed block — two writers touching overlapping entries.
- **Resolution (feature-001):** feature-001 does NOT add the secret-store ignore to the root `.gitignore` at all. `.aid/connectors/.secrets/` is ignored by a committed connectors-local `.aid/connectors/.gitignore` whose single writer is the P7-exempt discover state, written as its first action before any secret. This closes the double-writer hazard and the leak window on an un-updated repo by construction (no dependence on `aid add`/`aid update`). The root-`.gitignore` duplication is left as unrelated pre-existing debt (harmless; not touched here).

## KI-003: `kb-citation-lint` may reject registry endpoints/URLs

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-001-integration-store-placement, feature-005-registry-persistence-and-consumption
- **Source:** `canonical/aid/scripts/kb/kb-citation-lint.sh`; invoked at `canonical/skills/aid-discover/references/state-generate.md` "Step 5a: Citation Lint Gate" (rejects `file.ext:LINE` forms, requires durable `file:symbol` anchors).
- **Description:** The citation gate runs over `.aid/knowledge/`. The connectors registry lives in `.aid/connectors/` (NOT `.aid/knowledge/`), so the KB gate does not scan it by default — but if a connectors lint is modeled on it, endpoint/URL/`file:` reference tokens in descriptors could trip an anchor check. feature-001 keeps the registry outside `.aid/knowledge/`, so the KB citation gate is not in-path; any connector-side lint must be aware endpoints/references are content, not citations.

## KI-004: connectors `external-sources.md` routing summary is baked to "none provided"

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-002-source-and-tool-elicitation, feature-005-registry-persistence-and-consumption
- **Source:** `.aid/knowledge/INDEX.md` (external-sources.md row summary) and `.aid/knowledge/external-sources.md` frontmatter `summary:` ("No external documentation was provided during discovery").
- **Description:** `INDEX.md` is auto-composed from frontmatter by `canonical/aid/scripts/kb/build-kb-index.sh`. Once source elicitation populates `external-sources.md`, the frontmatter `summary:` must be updated or the RAG routing table will actively mislead agents into thinking no sources exist. Not a feature-001 concern directly (sources land in the KB, not `.aid/connectors/`), but flagged because it is the closest prior-art doc feature-001's schema mirrors.

## KI-005: the documented "fed by aid-config" external-docs pipe does not exist

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-002-source-and-tool-elicitation
- **Source:** `canonical/aid/templates/discovery-state-template.md` (`## External Documentation` table) and `canonical/skills/aid-discover/references/state-generate.md` (Step 0b "Read `.aid/knowledge/STATE.md` `## External Documentation` for paths from `aid-config`") vs `canonical/skills/aid-config/SKILL.md` (no external-doc elicitation — grep for `External Documentation`/`external doc`/`external source` returns no matches).
- **Description:** The `## External Documentation` STATE table is scaffolded empty by the template and never interactively populated by `aid-config`; the pre-scan (`references/agent-prompts.md ## Scout`) reads whatever paths are present (none). feature-002 builds the elicitation from zero — it is not reconnecting a live feed. The spec prose should say "build" not "restore a feed".

## KI-006: Codex TOML MCP-config write — OBSOLETED (Q10, 2026-07-09)

- **Status:** OBSOLETED by Q10. AID no longer wires any host MCP config (feature-004 rewritten to a no-code catalog/consumption feature; delivery-002 withdrawn), so the codex TOML-writer gap and the codex-wiring risk no longer apply to this work. A `codex`-provided MCP is now tool-managed: the agent requests it from Codex, which owns its own `config.toml` and auth.

## KI-007: Out-of-repo host-config writes / unconfirmed per-host mechanisms — OBSOLETED (Q10, 2026-07-09)

- **Status:** OBSOLETED by Q10. AID writes no host MCP config, so the out-of-repo (user-home) write path and the unconfirmed per-host MCP mechanisms (copilot-cli / antigravity / codex) no longer exist in this work's scope. Tool-managed connectors are requested from the host tool, which owns its own config file and handles auth; AID only catalogs availability.

## KI-008: Scout pre-scan skips when `external-sources.md` already exists

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-002-source-and-tool-elicitation, feature-006-idempotent-reconcile
- **Source:** `canonical/skills/aid-discover/references/state-generate.md` Step 1 ("Produces `project-structure.md` and `external-sources.md` … **Skip** if both already exist").
- **Description:** The Scout pre-scan — the single writer of `external-sources.md` — is skipped whenever the file already **exists** (Step 1's predicate is a bare existence test, NOT a content check). So on a re-run, source references newly added/changed via the `ELICIT` state (feature-002) would never be inventoried, and the stale "none provided" summary (KI-004) would persist. **Correction (was wrong in an earlier draft):** resetting `external-sources.md` to `Pending` does NOT by itself re-run Scout, because a `Pending` file still exists on disk — GENERATE does not "already honour" `Pending` at Step 1. **Resolution (feature-002 SPEC, per STATE.md Q7 item 4):** feature-002 SPECIFIES a Step-1 change making the skip **content-aware** — skip only when both foundation docs exist *with real content* (a `Pending`-only `external-sources.md` is treated as missing, reusing the Step-0 doc-set convention). Only with that change does E1's `Pending` reset force re-inventory. feature-006's reconcile design depends on this content-aware skip, not on unconditional Scout re-runs.
- **See also:** KI-004 (baked "none provided" summary), KI-005 (missing elicitation feed)

## KI-009: P7 "hard guard in the skill's pre-flight" is prose-only, not script-enforced

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-002-source-and-tool-elicitation, feature-001-integration-store-placement
- **Source:** `canonical/aid/templates/kb-authoring/principles.md` P7 ("Modifying repo code, configs, skills, templates, or installers from within a `/aid-discover` cycle is … a hard guard in the skill's pre-flight") vs `canonical/aid/scripts/kb/discover-preflight.sh` (checks only STATE.md presence + Plan Mode — no write-scope allowlist).
- **Description:** P7 claims a pre-flight hard guard, but the pre-flight script implements no write-scope enforcement; P7 is upheld by agent adherence to the principle, not by code. Implication for the P7 carve-out feature-002/feature-001 depend on: the exemption is a **principles.md prose edit only** — there is no code guard to relax. This prevents a downstream Detail/Execute task from hunting for a nonexistent script allowlist to patch. (Premise validated against disk: `discover-preflight.sh` is the only aid-discover pre-flight script and contains no such check.)

## KI-010: `build-kb-index.sh` embeds a run timestamp, so it is NOT byte-reproducible

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-005-registry-persistence-and-consumption, feature-006-idempotent-reconcile
- **Source:** `canonical/aid/scripts/kb/build-kb-index.sh` — the `TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"` assignment, emitted in the output's `<!-- AUTO-GENERATED $TS by canonical/aid/scripts/kb/build-kb-index.sh -->` marker and its `Generated at: $TS.` line.
- **Description:** The KB index builder stamps every run with a UTC timestamp, so two runs on identical input produce files that differ at the timestamp lines (`diff` shows only those lines change). feature-001 says the connectors INDEX builder "follows the `build-kb-index.sh` pattern" (it reuses the `--root`/`--output` shape), but copying the timestamp behavior verbatim would make `.aid/connectors/INDEX.md` churn on every reconcile even when nothing changed — breaking feature-006's idempotence guarantee (AC-6: a re-run against an unchanged declared set must produce no spurious diff). Resolution (STATE.md `## Cross-phase Q&A` Q7 CF-INDEX / item 5): feature-005's connectors INDEX builder is DETERMINISTIC — it omits the run timestamp — so regenerating from unchanged descriptors is byte-identical. feature-006 relies on this determinism for its no-churn idempotence proof; feature-005 owns the builder and MUST NOT copy the `date -u` stamp.

# Work State -- work-002-external_sources

> **State:** Detailing
> **Phase:** Detail
> **Minimum Grade:** A
> **Started:** 2026-07-07
> **User Approved:** yes

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, per-task SPEC.md) keep their
inline `## Change Log` sections -- that is content history (what changed in the document),
distinct from process state (where are we in the workflow). Both are useful; they live in
different places.

---

## Pipeline State

<!-- AUTHORED -- written ONLY by `writeback-state.sh --pipeline ...` at every phase/state
     transition the pipeline performs. Never hand-edited. All values are closed enums so a
     deterministic reader needs no inference. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
> Active Skill enum: aid-{skill} | none

- **Lifecycle:** Running
- **Phase:** Specify
- **Active Skill:** none
- **Updated:** 2026-07-09T00:27:35Z

---

## Triage

<!-- AUTHORED -- populated by `aid-describe` TRIAGE state for lite-path works.
     Left empty for full-path works (aid-describe runs the full interview flow instead). -->

- **Path:** full
- **Opener:** Restore the "external sources" elicitation that aid-init used to do (lost in the migration to settings.yml/aid-config) into aid-discover and land it in the KB properly; extend it to external *tools*/integrations (Jira, Slack, GitLab/GitHub, Confluence, Notion, Jenkins, Docker, …), with a way to connect (MCP, API, SSH, URL, …) and register required auth locally only, so the repo's agents can use them.
- **Decision rationale:** description → user directed full path (multi-activity: restore source capture in aid-discover + KB landing + external-tool integration + connection/local-auth registration + agent consumption) → full

---

## Interview State

<!-- AUTHORED -- updated by `aid-describe` as each section is completed. -->

**State:** Approved  **Grade:** — (human-approved; interview not rubric-graded)

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-07-07 |
| 2 | Problem Statement | Complete | 2026-07-07 |
| 3 | Users & Stakeholders | Complete | 2026-07-07 |
| 4 | Scope | Complete | 2026-07-07 |
| 5 | Functional Requirements | Complete | 2026-07-07 |
| 6 | Non-Functional Requirements | Complete | 2026-07-07 |
| 7 | Constraints | Complete | 2026-07-07 |
| 8 | Assumptions & Dependencies | Complete | 2026-07-07 |
| 9 | Acceptance Criteria | Complete | 2026-07-07 |
| 10 | Priority | Complete | 2026-07-07 |

---

## Lifecycle History

<!-- AUTHORED -- append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-07 | Work created | -- | Initial scaffold by aid-describe (FIRST-RUN) |
| 2026-07-07 | Interview → Approved | -- | All 10 sections Complete; requirements approved by user |
| 2026-07-07 | Feature Decomposition (aid-define) | -- | 6 features created in features/ (F1..F6); aid-architect |
| 2026-07-07 | Cross-Reference (aid-define) | A+ | aid-reviewer graded C (3 MED + 3 LOW); Q1–Q5 resolved with user; all 6 findings fixed; regraded A+ |
| 2026-07-08 | Specify feature-001 (aid-specify) | A+ | Keystone spec authored; A+ gate found 6 (1 HIGH + 4 MED + 1 LOW), all fixed; regraded A+; Q6 keystone decisions locked |
| 2026-07-08 | Specify features 002-006 (aid-specify) | A+ | Drafted in parallel vs frozen keystone; A+-gated each; cross-feature ownership matrix pinned (Q7); all fixed + re-gated A+ (002 D→C+→A+, 003 C+→A+ 2 cycles, 004 C+→A+, 005 C+→A+, 006 D+→A+); feature-001 coherence touch-ups re-verified A+ |
| 2026-07-08 | Specify → DONE (aid-specify) | A+ | All 6 features Ready at A+; cross-feature coherence confirmed; paused for /aid-plan |
| 2026-07-08 | Plan (aid-plan) | A+ | 3 deliverables sequenced (d1={001,002,003,005}, d2={004}, d3={006}); delivery folders created (Pending-Spec); review C+ → 2 findings fixed → A+; Q8 (unwire-on-remove) approved + applied to f004/f006/f001, re-gated A+ |
| 2026-07-08 | Plan → DONE (aid-plan) | A+ | PLAN.md + 3 delivery folders complete; paused for /aid-detail |
| 2026-07-08 | Detail (aid-detail) | A+ | 19 tasks across 3 deliveries (d1=12, d2=5, d3=2); typed + execution graphs in PLAN.md; per-delivery A+ gates (d1 C+→A+ [task-004 repo-root AGENTS.md fix], d2 A+, d3 A+); Q9 (skip-vs-empty) applied to task-008/task-018 |
| 2026-07-08 | Detail → DONE (aid-detail) | A+ | All 19 tasks seeded (State: Pending); delivery Tasks tables backfilled; paused for /aid-execute |
| 2026-07-08 | Execute delivery-001 (aid-execute) | A+ | 12 tasks Done (Wave1 ‖ 7, Wave2 4, Wave3 1); single-branch serial+parallel dispatch; consolidation render→5 profiles + dogfood sync (byte-identity 587/587); Large-tier gate A+ in 3 cycles (5 findings all Fixed: 2 MED + 1 LOW + 2 MINOR) |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy` at each delivery deploy (single writer; one row
     per delivery). One row per delivery from /aid-deploy. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The sections below are assembled at READ TIME from per-delivery and per-task STATE.md files.
     They are NEVER written directly. Agents MUST target the per-unit STATE.md files instead.
     ============================================================ -->

## Features State

<!-- DERIVED -- read-only view assembled from features/{feature}/SPEC.md progress. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 1 | feature-001-integration-store-placement | Ready | A+ | — | Keystone: `.aid/connectors/` layout + registry/descriptor schema + secret store + connectors index + context-file wiring. A+ (6 findings fixed + coherence touch-ups) |
| 2 | feature-002-source-and-tool-elicitation | Ready | A+ | — | New P7-exempt ELICIT state; sources→external-sources.md (Scout), tools→registry; skippable; presets+generic; URL cataloguing. A+ (D→C+→A+) |
| 3 | feature-003-local-auth-registration | Ready | A+ | — | feature-003-owned connector-secret twin (write+purge, path-confined); reference-not-value; no echo/persist. A+ (2 fix cycles) |
| 4 | feature-004-connection-wiring | Ready | A+→(Q10 rewrite) | — | **Q10-reframed → "Connection Modes & Consumption"** (no code): management mode derived from connection_type (mcp=tool-managed → request from host tool, tool handles auth, no AID cred/wiring; api/ssh/url/cli=aid-managed → descriptor + local auth). AID wires nothing. Realized within delivery-001. (Pre-Q10: multi-host MCP wiring — retracted.) |
| 5 | feature-005-registry-persistence-and-consumption | Ready | A+ | — | Owns INDEX builder (deterministic) + regen + consumption contract; producers write; Scout writes sources. A+ |
| 6 | feature-006-idempotent-reconcile | Ready | A+→(Q10 touch) | — | Re-run add/update/remove; purge-before-delete (interrupt-safe); REMOVE = delete descriptor + 003's purge (aid-managed only) + 005's INDEX rebuild. **No unwire (Q10 supersedes Q8).** |

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Cross-phase Q&A section plus
     any work-owner-authored Q&A entries on this work's active branch (work owner is the single
     writer here). -->

### Q1

- **Category:** Architecture / Integration
- **Impact:** High
- **Status:** Pending
- **Context:** FR-4 / AC-4 say "wire into `.mcp.json`", but `.mcp.json` is Claude-Code-specific. AID renders into 5 host profiles (claude-code, codex, cursor, copilot-cli, antigravity) with differing MCP mechanisms, and no MCP-config wiring exists in `canonical/` + `profiles/` today. Surfaced by /aid-define (cross-reference), finding #1 (MEDIUM).
- **Suggested:** Reword FR-4/AC-4 to "the host's MCP configuration (location resolved per host profile)"; scope the initial MCP wiring to Claude Code (`.mcp.json`) with per-host resolution as a /aid-specify concern — unless broad multi-host support is explicitly in scope.
- **Status:** Answered
- **Answer:** Broad multi-host MCP wiring is IN SCOPE — all 5 host profiles (claude-code, codex, cursor, copilot-cli, antigravity), each via its own MCP-config mechanism. FR-4/AC-4 to be reworded to "the host's MCP configuration, per host profile"; feature-004 scope enlarged accordingly; a /aid-specify research item will map each host's MCP mechanism (none exist in the codebase yet).
- **SUPERSEDED by Q10** (2026-07-09): retracted. AID does NOT wire MCP configs at all — the premise that AID writes MCP server entries into host profiles is wrong. See Q10 (catalog, not manager).

### Q2

- **Category:** Requirements / Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** §7 forbids a parallel mechanism. An external-doc mechanism already exists (the `external-sources.md` KB doc + a STATE "External Documentation" table, fed today by aid-config's pre-scan). FR-1 restores interactive source elicitation and must reconcile with it. Surfaced by /aid-define (cross-reference), finding #3 (MEDIUM).
- **Suggested:** Integrate — restored source elicitation populates the existing `external-sources.md` (+ the STATE External Documentation table); only the tool/integration registry is net-new (its home decided by feature-001).
- **Status:** Answered
- **Answer:** Differentiate the two concepts explicitly. (a) **External sources** = docs / vendor specs / reference URLs → land in the existing `external-sources.md`; the doc exists but its gather/populate/maintain PROCESS does not — building that process is the point (it is what was lost), so this is not a "parallel mechanism". (b) **Tool integrations** = connectable tools + connection type + endpoint + local auth reference → a separate, net-new registry (home per feature-001). REQUIREMENTS must state the source vs. tool-integration distinction explicitly; features keep them separate (elicitation captures both but differentiates; persistence routes sources → `external-sources.md` and the tool registry → its own home).

### Q3

- **Category:** Security / Behavior
- **Impact:** Medium
- **Status:** Pending
- **Context:** FR-7 / feature-006 guarantee that *other* entries' secrets survive a reconcile, but the fate of a *removed* tool's local secret is unspecified. Surfaced by /aid-define (cross-reference), finding #6 (LOW).
- **Suggested:** Retain by default (safe re-add) but surface orphaned secrets to the user; or purge on explicit confirmation.
- **Status:** Answered
- **Answer:** PURGE. When a tool is removed during reconcile, purge any secret associated with that tool from the local store. FR-7 / feature-006 to state that removal purges the associated local secret (in addition to preserving surviving entries' secrets).

### Q4

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Pending
- **Context:** feature-005 defers non-MCP agent-side descriptor consumption (the lean F5 scope approved at decomposition), but REQUIREMENTS §10 says "no deferred phase; delivered complete" and FR-6 reads as an unqualified Must — a doc inconsistency. Surfaced by /aid-define (cross-reference), finding #2 (MEDIUM).
- **Suggested:** Confirm the approved lean scope; reword FR-6 to "consumable (machine-readable registry + documented contract; MCP-wired tools usable)" and add an explicit §4 Out-of-Scope bullet (non-MCP agent rewiring) so it reads as out-of-scope, not a deferred phase.
- **Status:** Answered
- **Answer:** Accepted. Reword FR-6 to "consumable (machine-readable registry + documented consumption contract; MCP-wired tools directly usable via each host's MCP config)"; add a §4 Out-of-Scope bullet "rewiring individual agents to actively consume non-MCP connection descriptors". Reframed as out-of-scope (clean boundary), not a deferred phase, so §10 "delivered complete" holds.

### Q5

- **Category:** Security / Scope
- **Impact:** High
- **Status:** Answered
- **Context:** User-directed scope clarification during cross-reference Q&A — the boundary of this feature's secret-handling responsibility.
- **Answer:** (a) The local-only / never-committed guarantee is scoped to the secrets THIS mechanism registers. (b) Pre-existing secrets already committed in the project's source/codebase are OUT OF SCOPE for this feature's cleanup — they are flagged as tech-debt / risk by the discovery phase (`aid-discover`), not remediated here. (c) ABSOLUTE RULE: under no circumstance does the KB (or the committed registry) expose any secret — ours or any encountered during elicitation/scanning. (d) AC-3 scope clarified: it verifies OUR registered secret never leaks into repo/KB/STATE/transcript; it is NOT a repo-wide pre-existing-secret scan. To be applied to §4 (out-of-scope bullet), §6 (hard KB-no-secrets rule), and AC-3 wording in the FIX pass.

### Q6

- **Category:** Architecture / Placement (aid-specify keystone)
- **Impact:** High
- **Status:** Answered
- **Context:** aid-specify question harvest (feature-001 keystone). Two collisions the requirements did not resolve: (1) aid-discover's read-only guard (KB principle P7 — MUST NOT write outside `.aid/knowledge/`, `.aid/generated/`, `.aid/.temp/`, enforced as a hard pre-flight guard) vs this feature's need to write a secret store, host MCP configs, and `.gitignore`; (2) the physical home + format of the integration registry (AC-7 deliberately left open).
- **Answer:** (a) New folder **`.aid/connectors/`** is the single home for everything connector/integration-related, and is a NEW exemption to the P7 read-only rule (aid-discover may write there — narrow, declared scope). (b) Inside it: committed registry + connection descriptors (references only — safe to commit) + a git-ignored `.aid/connectors/.secrets/` for the actual secret values (never committed). (c) Connectors get their **own index** — markdown, mirroring the KB `INDEX.md` format — referenced in **`CLAUDE.md` and `AGENTS.md` the same way the KB index is**; **`.aid/settings.yml` is also referenced** in `CLAUDE.md`/`AGENTS.md`. (d) All YAML deferred: the connectors index is markdown for now. (e) FUTURE WORK (separate, NOT this work): convert the KB `INDEX.md` to a YAML index and unify index formats. (f) Context-file changes flow through the canonical→profiles render across all 5 profiles. Soft defaults for drafting (from the harvest, no user Q needed): per-host MCP mechanism executed as the Q1-authorized spike; wire only hosts present in `settings.yml tools.installed`; elicitation as a new P7-exempt aid-discover state.

### Q7

- **Category:** Architecture / Cross-feature ownership (aid-specify coherence pass)
- **Impact:** High
- **Status:** Answered
- **Context:** The six feature specs were drafted in parallel against the frozen feature-001 keystone; the A+ gates surfaced consistent cross-feature ownership drifts (each drafter could see feature-001 but not the sibling drafts). This is the authoritative ownership matrix + coherence decisions all specs are reconciled to. Anchored on feature-001's frozen Feature Flow (002/003/004 = producers, 005 = persistence + consumption/reader, 006 = reconcile).
- **Answer (ownership matrix):**
  1. **Tool descriptor files** `.aid/connectors/<connector>.md` — AUTHORED by feature-002 (elicitation is the producer). feature-004 UPDATES wiring-related fields when wiring an `mcp` connector. feature-006 updates/removes on reconcile. There is NO central "feature-005 descriptor-writer that producers call"; producers write their own artifacts.
  2. **Secret VALUES** `.aid/connectors/.secrets/<stem>` — written AND purged by ONE secret twin owned by **feature-003** (`connector-secret.{sh,ps1}`, `write` + `purge` ops). feature-006 CALLS the purge op on REMOVE; it does NOT define its own purge twin. (resolves the 003↔006 drift.)
  3. **Secret use-time RESOLUTION** — owned by **feature-005**'s consumption contract / the consuming agent (resolves the reference at use-time). There is NO "feature-003 resolver". feature-004 records the reference (e.g. `env:VAR`) into the host MCP config; the host/agent resolves it. (resolves the feature-004 drift.)
  4. **External SOURCES** `external-sources.md` — SINGLE writer remains the existing **Scout** back-end. feature-002 ELICIT feeds the `## External Documentation` STATE table and makes Scout's Step-1 skip **content-aware** (skip only if real content, not `Pending`). feature-005 does NOT own a separate source-writer; it defers to Scout. §7 (no parallel mechanism) honored.
  5. **Connectors `INDEX.md`** — contract DEFINED by feature-001 (columns / frontmatter / regeneration); the builder is **DETERMINISTIC (no run timestamp)** so reconcile does not churn (unlike `build-kb-index.sh`). Regeneration OWNED by feature-005; feature-002 (on author), feature-004 (on wire), feature-006 (on reconcile) trigger it via feature-005's builder.
  6. **feature-005 scope** — owns INDEX regeneration + the documented consumption contract + the machine-readable serialization/consumption VIEW. NOT a descriptor/secret writer the producers call. The FR-6 consumption contract lives in the `## Connectors` context-file section (bound to feature-001's wiring), NOT an INDEX.md preamble.
  7. **auth-downgrade orphan** — a SURVIVING connector whose `auth_method` drops to `none` has its now-unreferenced secret disposed by **feature-003**'s secret lifecycle. feature-006 purges only on full REMOVE.
- **feature-001 coherence touch-ups (keystone re-touch, then re-verify):** (CF4) fix the stray "user-profile location" wording — the store is repo-relative `.aid/connectors/.secrets/` per feature-001's own layout diagram; (CF5) note that non-Claude-Code hosts' MCP configs land OUTSIDE the repo tree (user-home), beyond the `.aid/connectors/` P7 carve-out — deferred (only `claude-code` installed today → repo-root `.mcp.json`, in-repo); (CF-INDEX) connectors index builder is deterministic (no timestamp). Also: Q6(f) "context files flow through the render" was CORRECTED during drafting — `CLAUDE.md`/`AGENTS.md` are hand-maintained (installer in-place managed-region updater + FR12 AGENTS.md byte-identity), only `principles.md` is a rendered canonical asset.

### Q8

- **Category:** Architecture / Cross-feature ownership (aid-plan REVIEW)
- **Impact:** Medium
- **Status:** Answered
- **Context:** aid-plan REVIEW found a cross-feature gap: delivery-003's "unwire-on-remove" gate criterion + the delivery-003 → delivery-002 dependency assumed feature-006 unwires an `mcp` tool's host config on removal — but feature-006's spec only purged the secret + deleted the descriptor (no unwire), while feature-004's spec asserted feature-006 does it. FR-7/AC-6 never explicitly required unwire; leaving it out strands a dead MCP entry (a launch spec for a removed tool) in host configs on removal.
- **Answer (user-approved):** YES — reconcile unwires on removal. Extends Q7: **feature-004 owns BOTH a `wire` and an `unwire` op** on its host-MCP-config twin (unwire removes the connector's `mcpServers`/equivalent entry from each installed host's config, idempotent, preserving other servers). **feature-006's REMOVE composes feature-004's `unwire` op** for an `mcp`-typed connector — mirroring how it composes feature-003's `purge`. So REMOVE = purge secret (feature-003) + unwire host config (feature-004, mcp only) + delete descriptor + regenerate INDEX (feature-005), with purge/unwire BEFORE descriptor-delete for interrupt-safety. This backs delivery-003's unwire gate criterion + the d3→d2 dependency. feature-004 + feature-006 specs re-touched + re-gated A+.
- **SUPERSEDED by Q10** (2026-07-09): retracted. AID neither wires nor unwires host MCP configs, so there is nothing to unwire on removal. Reconcile REMOVE = delete descriptor + purge the local secret (aid-managed connectors only) + regenerate INDEX. See Q10.

### Q9

- **Category:** Behavior (aid-detail)
- **Impact:** Medium
- **Status:** Answered
- **Context:** aid-detail found a spec ambiguity at the feature-002 ↔ feature-006 seam: reconcile (feature-006 R0) must distinguish a tool-step SKIP (registry untouched) from an authoritative EMPTY declaration (remove all), but feature-002's `## Discovery Elicitation` record did not unambiguously encode the difference (E2 read "skip or empty: record `tools: none`").
- **Answer (user-approved):** DISTINGUISH them. feature-002's ELICIT `## Discovery Elicitation` record MUST carry an explicit marker: **SKIPPED** (tool step not engaged) → declared-set undefined → reconcile is a NO-OP (registry untouched — the safe default); **DECLARED-EMPTY** (step engaged, zero tools) → declared-set = `{}` → reconcile REMOVEs all persisted connectors (purge + unwire(mcp) + delete). Applied to task-008 (ELICIT writes the skip-vs-empty marker into the record) and task-018 (reconcile R0 branches on it).
- **Amended by Q10** (2026-07-09): the marker still stands, but REMOVE no longer includes `unwire(mcp)` (AID does not wire) — REMOVE = delete descriptor + purge secret (aid-managed only) + regenerate INDEX.

### Q10

- **Category:** Architecture / Scope (mid-Execute reframe — user-directed)
- **Impact:** High
- **Status:** Answered
- **Context:** During delivery-002 (MCP host wiring) execution — at the task-015 dispatch — the user identified that the whole work had baked in a wrong premise: AID was designed to *provision / wire / manage* connections (write MCP server entries into each host's MCP config, store creds for them). That is not the intent. Supersedes Q1 (broad multi-host MCP wiring in scope) and Q8 (unwire-on-remove); amends Q9 (REMOVE no longer unwires).
- **Answer (user-directed):** The connectors registry is a **CATALOG** that informs the repo's agents what external connections are available and how to use each — AID does **NOT** provision, wire, or manage the connections themselves. Every connector entry carries one of two **management modes**:
  1. **tool-managed** (the common case): the host tool (claude-code / codex / cursor / copilot-cli / antigravity) already provides its own MCP server or plugin for the target (e.g. Jira, GitHub). The catalog records that the connection is available via the host tool's own MCP/plugin and instructs the agent to **request it from the tool**; the **tool handles auth**. AID writes **no** host MCP config and stores **no** credential for it.
  2. **aid-managed** (the rarer case): the target is reached by a direct `api | ssh | url | cli` the host tool does **NOT** provide (e.g. Microsoft 365 via its REST API when no MCP exists). The catalog records a connect-sufficient descriptor (endpoint/target, connection_type, auth reference) **and** AID stores the required credential in the local git-ignored store, so the agent uses it directly.
  Local credential storage exists **ONLY** for aid-managed connectors; tool-managed connectors never have an AID-stored credential.
- **Consequences (applied by this loopback, 2026-07-09):**
  - **Supersedes Q1** (no AID-side MCP-config wiring at all) and **Q8** (nothing to unwire); **amends Q9** (REMOVE drops the unwire step).
  - REQUIREMENTS: Description + §1 + §4 de-wired; **FR-4** rewritten (record management mode + how the agent connects, not wiring); **FR-6** consumption split by mode; **§8** dependencies de-wired; **AC-4/AC-5** rewritten.
  - **feature-004** rewritten "connection wiring" → "connection-mode catalog & consumption"; **feature-001/002/005** touched where they encode `mcp` = AID-wired (feature-002 ELICIT captures the management mode and prompts for a secret only when aid-managed; feature-005 consumption contract splits the two modes).
  - **delivery-002** collapses (the wire/unwire twin, wire-on-declare hook, and wiring tests are dropped; the mechanism spike/table become at most informational, likely reverted); **delivery-003** loses the unwire path.
  - **delivery-001** (already shipped) `## Connectors` consumption text corrected (`mcp` = "request from the tool", not "already wired"); the descriptor model gains the management-mode axis; task-013/014 (wiring mechanism spike + table) reverted or repurposed.

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries. One row per dispatch. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._

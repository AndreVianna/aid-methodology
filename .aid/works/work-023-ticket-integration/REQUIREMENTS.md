# Requirements

- **Name:** Ticket-Tracker Integration Skills + PM-Tool Retirement
- **Description:** Add explicit `/aid-read-ticket`, `/aid-create-ticket`, `/aid-update-ticket` skills as the single user-invoked, tool-agnostic surface for ticket-tracker interaction, and retire all automated ("PM-Tool") ticket writes embedded in other skills.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | Initial capture — seeded from the design conversation (naming, grammar, connector-resolution ladder, MCP-first scope, PM-TOOL full retirement all owner-confirmed interactively). Requirements owner-approved. | /aid-describe (seeded) |
| 2026-07-22 | Cross-reference cycle-1 FIX (all traced to prior owner rulings): FR-7 carve-out (aid-deploy Release / Epic / Sprint-link removed outright — no ticket analog, no suggestion); AC-7 → per-site check + illustrative/expanded signature set; FR-13/AC-13/§7 add `aid-discover/references/document-expectations.md` discovery-guidance site + reframe off a literal `§ Project Management` heading; FR-8/FR-9/AC-8 split `aid-plan` Step 4c (record-ref-for-existing half kept + rerouted, new-ticket-filing write retired); FR-2/FR-4 create-grammar disambiguation rule. | /aid-define (cross-reference) |
| 2026-07-22 | Specify cross-check FIX: §8 corrected — there is no repo-root `setup.sh`; the dogfood resync is the `lib/aid-install-core.sh` install-path copy (surfaced by the feature-005 SPEC review as an OOS-to-REQUIREMENTS observation; feature-005's own spec already handled the reality). | /aid-specify (review-fix) |
| 2026-07-22 | Post-Specify change request (owner): FR-2 gains `--level` (epic\|story\|task; **no default — ask at the confirm gate when absent/uninferable**; canonical tier resolved to the tracker's real issue-type at runtime, graceful degradation) + `--parent` (optional native hierarchy link); grammar switched to flags (`--connector`/`--level`/`--parent`). Added FR-2a/FR-2b; AC-2 updated. Folded into feature-001 for re-gate. | owner change request |
| 2026-07-22 | Re-gate cycle-1 FIX: dropped the per-connector `level_map` override (would need a new connector-descriptor field → §4 out-of-scope + contradicts feature-001 "no schema changes"; deferred — runtime synonyms + literal passthrough suffice); removed the bare-leading-token connector heuristic for create (redundant + ambiguous under flag grammar). | /aid-specify (review-fix) |
| 2026-07-22 | Re-gate cycle-2 sync: FR-4 + AC-5 updated to match FR-2's no-bare-leading-token rule for create (connector via `--connector` or the ladder) — closes the OOS cross-doc drift the feature-001 re-gate flagged. | /aid-specify (review-fix) |

## 1. Objective

Give AID users three explicit, user-invoked skills to interact with whatever ticket/issue tracker the project has integrated (Jira, GitHub Issues, Remedy, Linear, Azure Boards, …) — **tool-agnostically**, resolved through AID's existing connector layer rather than any tool name baked into the skill:

- `/aid-read-ticket` — fetch and display a ticket's fields.
- `/aid-create-ticket` — file a new ticket.
- `/aid-update-ticket` — change a ticket's description, add a comment, or set its status.

Simultaneously, make these three skills the **only sanctioned outward interaction surface** for ticket trackers: **retire the automated ticket writes currently embedded in other skills**, so no skill silently creates or mutates a tracker item. Any outward interaction not started via these three skills must be validated with the user; internal `ticket_ref` traceability is kept.

## 2. Problem Statement

Two problems:

**(a) No explicit user control.** There is no user-invoked way to read, create, or update a tracker item on demand. Reading only happens implicitly (ingest/enrich seams); status writes only happen automatically (mirroring); creating is not possible at all through a dedicated surface.

**(b) Silent, tool-coupled automated writes, split across two overlapping generations.** An audit (2026-07-22) found ~40 integration touch-points across skills, agents, and templates, in **two generations**:
- **PM-TOOL** — the older model keyed off `infrastructure.md § Project Management`, which freely performs outward WRITES: `aid-describe` "create an Epic", `aid-detail` "create Tickets/Work Items", `aid-plan` "create Sprint/Iteration entries", `aid-execute` "update ticket to In Progress/Done + add comment", `aid-deploy` "create a Release / mark tickets Done/Closed / link Epic", `aid-monitor` "create tickets for BUG tasks".
- **CONNECTORS** — the newer MCP-first model keyed off `.aid/connectors/` + `consumption-protocol.md` (`ticket_ref`, `issue-tracker`, wired seams), which is mostly read/record-only but still carries `aid-execute`'s automatic status-mirror and `aid-plan`'s auto create/register, plus human-gated comment writes in `aid-review`/`aid-research`/`aid-report`.

Three skills (`aid-describe`, `aid-plan`, `aid-execute`) carry **both** generations at once — `aid-execute` literally double-pushes the same status transitions. Users have no visibility or veto over any of these outward writes.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID adopter / developer | Runs the pipeline; wants to read/file/update tracker items on their own terms | Explicit, tool-agnostic ticket commands; no skill touching a tracker without them starting it |
| Project lead / PM | Cares the tracker reflects reality | Tracker stays useful, but every outward change is user-initiated and previewed — no silent edits |
| AID methodology (this repo) | Dogfoods and ships the skills to adopters | One coherent integration model (connectors + dedicated skills); the two-generation conflict removed; byte/path parity + quality gate preserved |

## 4. Scope

### In Scope

- **Three skills** — `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket` — with the locked grammar (§5), connector-resolution ladder (FR-4), MCP-first consumption (FR-5), and write-preview/confirm (FR-2/FR-3).
- **Retire the PM-TOOL generation entirely** — remove the `infrastructure.md § Project Management`-driven writes from `aid-describe`, `aid-detail`, `aid-plan`, `aid-execute`, `aid-deploy`, `aid-monitor` (replace with a printed suggestion where a ticket-scoped analog exists; remove outright where there is none — FR-7).
- **Consolidate onto one outward surface** — reroute the CONNECTORS reads through `aid-read-ticket`; reroute the human-gated comment writes (`aid-review`/`aid-research`/`aid-report`) through `aid-update-ticket`; remove `aid-execute`'s auto status-mirror and the outward-write half of `aid-plan`'s Step 4c.
- **Revise `consumption-protocol.md`** — drop the automated file/mirror/comment capability; keep the `ticket_ref` multi-level linkage + nearest-ancestor resolution (LOCAL-LINK); document that reads delegate to `aid-read-ticket` and writes go via the dedicated skills.
- **Keep** internal `ticket_ref` traceability + all LOCAL-LINK templates unchanged.
- **KB + discovery-guidance + propagation** — retire the PM-tool *automation* framing in the discovery guidance (`document-expectations.md`) and the KB project-management guidance while keeping "which tracker is used"; author in `canonical/`, re-emit to every `profiles/*`, resync dogfood `.claude/`; tests.

### Out of Scope

- **Live consumption of aid-managed `api`/`ssh`/`cli` connectors** (the `connector-secret resolve` primitive + the accompanying security pass). Skills are **MCP-first**; an `api`-type registered connector (Jira's default preset) is not live-consumable and falls through the resolution ladder. This remains the deferred follow-up already noted in `consumption-protocol.md`.
- Changing the connector-descriptor schema or the catalog lifecycle (`reconcile.md`, `preset-catalog.md`, `aid-set-connector`/`aid-unset-connector`).
- Adding new tracker presets.
- Changing `grade.sh`, the f005 review panel, or the human-commit invariant.

## 5. Functional Requirements

- **FR-1 — `aid-read-ticket`.** Grammar `/aid-read-ticket [<connector>:]<ticket-id>`. Resolves the connector (FR-4), fetches the ticket via the connector's MCP (FR-5), and displays its fields. Non-destructive → **no confirmation prompt**. The `<connector>:` prefix, when present, selects the connector directly.
- **FR-2 — `aid-create-ticket`.** Grammar `/aid-create-ticket [--connector <stem>] [--level epic|story|task] [--parent <ref>] <description>`. Resolves the connector (FR-4), determines the ticket **level** (FR-2a) and any **parent** link (FR-2b), then — after a **preview of exactly what will be sent and explicit user confirmation** — files the ticket and returns the new `<connector-stem>:<external-id>`. Flags may appear in any order before the trailing free-text `<description>`; `--connector` is the explicit connector selector. There is **no bare-leading-token connector heuristic for create** — the whole non-flag remainder is the `<description>`; the connector is chosen via `--connector` or the FR-4 resolution ladder. (read/update keep their `[<connector>:]<ticket-id>` colon-prefix form, which is unambiguous.)
- **FR-2a — Ticket level (no default; ask when absent).** `--level` takes a canonical tier `epic | story | task` (broad → granular). Determination precedence: (1) explicit `--level`; (2) else **inferred from the description** (e.g. "this epic…", "bug:") and **surfaced in the confirm gate** for confirmation, never silently applied; (3) else **no default — the confirm gate requires an explicit pick** (`epic`/`story`/`task`); nothing is silently assumed. The canonical tier is mapped to the tracker's **real issue-type at runtime**: query the tracker's available types via its MCP and match by an ordered synonym set (`epic`→Epic/Initiative/Feature…, `story`→Story/User-Story/Issue…, `task`→Task/Sub-task/To-do…; first available wins). A tracker with no matching tier **degrades gracefully** (files a plain issue, optionally a `type:<tier>` label) and the **preview shows the concrete resolved type**. A literal provider-type passthrough (`--level "Sub-task"`) is supported for exact control. A *persistent per-connector* tier→type override is a **deferred follow-up** — it would require a new connector-descriptor field, which §4 puts out of scope; the runtime synonym match + the literal passthrough cover the need without it.
- **FR-2b — Parent link (optional).** `--parent <ref>` (or a description inference such as "under PROJ-123") links the new ticket to a parent in the **same** tracker via the provider's native hierarchy (Jira parent/epic-link, Azure parent-child, GitHub sub-issue, …), **best-effort**; a tracker with no hierarchy is noted in the preview rather than failing. The parent is shown in the preview and applied only after confirm.
- **FR-3 — `aid-update-ticket`.** Grammar `/aid-update-ticket <part> [<connector>:]<ticket-id> <content>`, where `<part> ∈ {description, comment, status}`. `description` **replaces** the field; `comment` **appends** a new comment; `status` **sets** the state, validated against the tool's available transitions (an invalid target lists the valid options). Mutating parts are outward writes → **preview + explicit confirm before writing**. `<part>` is a closed enum and the ref is a single whitespace-delimited token, so the free-text `<content>` (everything after the ref) parses unambiguously.
- **FR-4 — Connector-resolution ladder (all three skills).** In order: (1) an **explicit `<connector>`** (a `<stem>:` prefix for read/update; the `--connector <stem>` flag for create) always wins; (2) else scan `.aid/connectors/` for connectors tagged `issue-tracker` — exactly one → use it silently, two or more → **ask the user which**; (3) else try the **host tool's own MCP** for an issue tracker; (4) else **notify** the user *"no issue-tracker connector found."* A bare `<ticket-id>` with no prefix follows the same ladder to pick the connector. For `create` (which has no id and **no bare-leading-token heuristic** — FR-2), the connector comes from `--connector` or this ladder.
- **FR-5 — MCP-first consumption.** Consume the resolved connector via `consumption-protocol.md`'s MCP-first recipe (request the connection from the host tool's own MCP; AID resolves no credential). An `api`/`ssh`/`cli`-type registered connector is **not** live-consumable in this work → it falls through the ladder (step 3/4). No new runtime scripts for `api` consumption.
- **FR-6 — Single outward surface.** The three skills are the only sanctioned outward tracker interaction. **Any outward interaction not started via them must be validated with the user first** (or rerouted to go through one of them). Internal `ticket_ref` recording is not an outward interaction and needs no validation.
- **FR-7 — Retire PM-TOOL writes.** Remove every `infrastructure.md § Project Management`-driven write across the six sites: `aid-describe/references/state-completion.md` (create Epic), `aid-detail/references/task-decomposition.md` (create Tickets/Work-Items + link Sprint/Epic), `aid-plan/SKILL.md` (create Sprint/Iteration + map deliveries), `aid-execute/SKILL.md` (update ticket In Progress/Done + comment), `aid-deploy/references/state-packaging.md` Step 8 (create Release / mark tickets Done-Closed / link release to Epic), `aid-monitor/references/state-route.md` (create tickets for BUG tasks + link Sprint/Epic). **Replacement rule:** where a removed write has a **ticket-scoped analog**, replace it with a **printed suggestion** to invoke the dedicated skill (status changes / mark-Done-Closed → `/aid-update-ticket status`; create-ticket/epic/work-item/bug-ticket → `/aid-create-ticket`), mirroring the existing `aid-report`/`aid-research` "never auto-invoked" HANDOFF pattern. Where a removed action has **no ticket-scoped analog** — specifically aid-deploy's *"Create a Release in the PM tool"* and *"Link the release to the Epic"*, and any *link-to-Sprint/Epic* hierarchy action — it is **removed outright with no suggestion** (a Release/Epic/Sprint is not a ticket; AID's own `## Deploy State` already records the release).
- **FR-8 — Reroute reads through `aid-read-ticket`.** The CONNECTORS read seams delegate to `aid-read-ticket` instead of re-implementing a fetch: `aid-describe/references/state-first-run.md`, `aid-specify/references/state-initialize.md`, `aid-plan/references/first-run-loop.md` (Step 4c's *record-`ticket_ref`-for-an-existing/named-item* half — see FR-9), `aid-fix` + the shared `shortcut-engine.md`, `aid-query-kb/SKILL.md`, `aid-review/SKILL.md`, and the `aid-developer` / `aid-researcher` agent definitions. A user-supplied ref (e.g. `/aid-describe PROJ-123`) is the authorization; reads are non-destructive → no extra prompt.
- **FR-9 — Retire/reroute connector writes.** Remove `aid-execute`'s automatic status-mirror (`state-execute.md`). For `aid-plan` (`first-run-loop.md` Step 4c) the branch is **split**: retire **only the outward write** — the *"the team wants one filed → create/register it via a catalogued connector"* branch (→ printed suggestion to run `/aid-create-ticket`); its *record-`ticket_ref`-for-an-existing/named-item* half is **preserved and rerouted** through `/aid-read-ticket` (FR-8), with the `ticket_ref` recording kept (FR-11) — that half is an Ingest read + LOCAL-LINK, not an outward write. Reroute the human-gated comment writes in `aid-review` (`SKILL.md` PUBLISH-on-approval), `aid-research`, and `aid-report` through `aid-update-ticket` so there is one write surface; they remain user-authorized, never auto-invoked.
- **FR-10 — Revise `consumption-protocol.md`.** Remove the automated file-a-ticket / mirror-transition / post-comment capability from the wired-seams model (lines defining WRITE at `:48`, the `aid-execute` Target row `:134`, and the worked-example mirror `:160-163`). **Keep** the `ticket_ref` multi-level linkage + nearest-ancestor resolution as LOCAL-LINK. Restate the protocol as: reads may be delegated by any seam via `aid-read-ticket`; all writes flow through the dedicated skills.
- **FR-11 — Keep traceability.** `ticket_ref` remains a local link, populated **only from a user-supplied ref, never auto-created/auto-discovered**. The state/spec templates (`work-state-template.md`, `delivery-state-template.md`, `task-state-template.md`, `specs/spec-template.md`) are unchanged.
- **FR-12 — Propagation.** All edits authored in `canonical/`; re-emitted via the generator to every `profiles/*`; dogfood `.claude/` resynced from `profiles/claude-code/` (test-dogfood-byte-identity stays green).
- **FR-13 — KB & discovery-guidance update.** Retire the PM-tool *automation* framing from the KB/discovery guidance while preserving *which tracker is used*: `aid-discover/references/document-expectations.md`'s Project-Management investigation prompt drops the PM-tool *"entity mapping"* (Epic/Story/Task automation-hierarchy) item but keeps *"which project-management tool (or none) + access method"* — which now feeds the connector model. The KB's project-management guidance documents the connectors + dedicated-skills model instead of automated ticket operations, cited **by its actual on-disk section/role** (the implementer confirms the real heading — the `infrastructure.md` template carries no literal `Project Management` heading), with KB → KB / KB → source citations only, never a context file. A per-project `infrastructure.md` still records the project's tracker; the automated-operation instructions lived in the skills and are retired by FR-7.

## 6. Non-Functional Requirements

- **NFR-1 — Tool-agnostic.** No skill name or logic encodes a specific tool; the tool binding comes only from the registered connector.
- **NFR-2 — No silent outward interaction.** Every write previews and confirms before sending; every read is authorized by an explicit/user-supplied ref; nothing reaches a tracker without the user starting it via a dedicated skill (or validating it).
- **NFR-3 — Backward compatibility.** A project with no `issue-tracker` connector and no `ticket_ref` behaves **exactly as before** — every seam silently skips (no error), identical to pre-change behavior.
- **NFR-4 — Byte/path parity.** Generated `profiles/*` copies differ from `canonical/` only by the path-prefix rewrite; `test-dogfood-byte-identity` and CLI-parity suites stay green.
- **NFR-5 — Quality floor.** `minimum_grade` resolves to the project floor `A+`.

## 7. Constraints

- Edits land **only** in `canonical/` (per-tool source); generated copies are never hand-edited.
- Skills stay markdown state-machines driven by reference docs + the global review-output schema (`reviewer-ledger-schema.md`); MCP-first only, no new runtime scripts for `api` consumption.
- Follow AID skill conventions: `SKILL.md` + `references/`, one clear action per skill, the global "review output format" rule.
- The audit inventory (2026-07-22, ~40 sites classified WRITE/READ/LOCAL-LINK × PM-TOOL/CONNECTORS) is the authoritative site list for FR-7/FR-8/FR-9/FR-10, **as amended by the cross-reference cycle-1 review**: add `aid-discover/references/document-expectations.md` (PM investigation prompt) under FR-13, and treat `aid-plan/references/first-run-loop.md` Step 4c as **split** (record/read half → FR-8, new-ticket-filing write → FR-9). Re-verify against disk before editing (fix-everywhere: grep the signature, don't fix only the cited line).

## 8. Assumptions & Dependencies

- The connectors model + `consumption-protocol.md` + the `ticket_ref` convention in the state/spec templates already exist (feature-001..006; work-003 state schema).
- The generator renders `canonical/` → `profiles/<tool>/…`; the dogfood `.claude/` is synced from `profiles/claude-code/` via the install-path copy (`lib/aid-install-core.sh`) — there is **no repo-root `setup.sh`** script.
- The host tool may expose an issue-tracker MCP (e.g. an Atlassian/Jira MCP, GitHub MCP); a project may register such a tracker as an `mcp`-type connector.
- `aid-developer` (sonnet), `aid-tech-writer` (sonnet), `aid-reviewer` (sonnet), `aid-architect` (opus) are available with pinned models.
- **D1 (resolved):** `api`-type connector consumption stays deferred (MCP-first now); the dedicated skills work today only against an `mcp`-type issue-tracker connector.

## 9. Acceptance Criteria

- **AC-1** `/aid-read-ticket PROJ-123` (or `/aid-read-ticket jira:PROJ-123`) displays the ticket's fields; performs no external write; shows no confirmation prompt.
- **AC-2** `/aid-create-ticket` files a ticket **only after** a preview + explicit user confirmation, and returns the new `<stem>:<external-id>`. The **level** is never silently defaulted: with `--level` absent and none inferable from the description, the confirm gate requires an explicit `epic|story|task` pick; an inferred level is surfaced for confirmation; and the canonical tier is shown resolved to the tracker's concrete issue-type in the preview (with graceful degradation noted when the tracker lacks that tier). An optional `--parent <ref>` (or an inferred parent) is shown in the preview and linked via the provider's native hierarchy best-effort (noted when the tracker has none). Flags (`--connector`/`--level`/`--parent`) may precede the free-text description in any order.
- **AC-3** `/aid-update-ticket {description|comment|status} …` mutates **only** the named part after preview + confirm; a `status` target is validated against the tool's available transitions (invalid → valid options listed).
- **AC-4** With exactly one `issue-tracker` connector and no explicit connector, the skill uses it silently; with two or more and no explicit connector, the skill **asks which**.
- **AC-5** An explicit `<connector>` — a `<stem>:` prefix (read/update) or the `--connector <stem>` flag (create) — always overrides the scan.
- **AC-6** No registered `issue-tracker` connector → the host tool's MCP is attempted; if none is available → the user is notified *"no issue-tracker connector found."*
- **AC-7** Each of the six FR-7 sites is confirmed retired (a per-site check, not only a grep), and a grep for the automated-write signatures returns **zero**. The illustrative (non-exhaustive) signature set includes "create an Epic", "create Tickets/Work Items", "create Sprint/Iteration", "update … ticket to In Progress/Done", "add comment to ticket", "mark as Done/Closed", "Create a Release in the PM tool", "create tickets for BUG", "link … Epic". Retired writes with a ticket-scoped analog leave a printed dedicated-skill suggestion; Release/Epic/Sprint-link actions (no analog) are removed with none.
- **AC-8** `aid-execute` no longer auto-mirrors status; `aid-plan` no longer auto-files a new tracker item (its *record-ref-for-an-existing-item* half is preserved and rerouted via `/aid-read-ticket`); those outward actions occur only via `/aid-create-ticket` / `/aid-update-ticket`.
- **AC-9** Every remaining ticket READ in another skill/agent (including `aid-plan`'s Step 4c record half) routes through `/aid-read-ticket`; none re-implements a direct fetch.
- **AC-10** `ticket_ref` local traceability is preserved and only ever populated from a user-supplied ref; a work with no `ticket_ref` and no connector behaves identically to before (silent skip).
- **AC-11** `consumption-protocol.md` is revised: no automated file/mirror/comment seam remains; the `ticket_ref` linkage + nearest-ancestor resolution are retained; reads are documented to delegate to `aid-read-ticket` and writes to the dedicated skills.
- **AC-12** Edits are authored in `canonical/`, re-emitted to every `profiles/*`, and the dogfood `.claude/` is resynced; byte/path-parity + CLI-parity tests are green.
- **AC-13** `aid-discover/references/document-expectations.md` no longer prompts for PM-tool automation "entity mapping" (it retains "which tracker (or none) + access method"); the KB's project-management guidance documents the connectors + dedicated-skills model, cited by its actual on-disk section, with no KB citation to a context file.

## 10. Priority

Must.

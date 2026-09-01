---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-08-08"
minimum_grade: "A"
user_approved: no
lifecycle: Running
phase: Specify
active_skill: aid-specify
updated: '2026-09-01T00:00:00Z'
pause_reason: --
block_reason: --
block_artifact: --
ticket_ref: "--"
---

# Work State -- work-007-agent-chat

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into three zones:
  FRONTMATTER (single-writer, machine-parsed scalars) -- the YAML block above: pipeline
    identity, work-level lifecycle/phase/approval scalars, and (for flattened single-delivery
    works only) the delivery lifecycle/gate scalars. Written ONLY by `writeback-state.sh`
    (surgical YAML-block rewrite; the markdown body is never touched by that write).
  AUTHORED (single-writer, markdown body) -- Interview State, Lifecycle History,
    Deploy State, the narrative remainder of Delivery Lifecycle (incl. its Tasks lifecycle
    subsection) and Delivery Gate (Updated/Block Reason/Block Artifact/Issue List -- the
    values that don't fit a flat frontmatter scalar).
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.
Inferred values (`number` from the folder name, `branch` from the git worktree,
`title`/`description`/`objective` from REQUIREMENTS/SPEC content files) and derived values
(counts, readiness/execution %, `source_mode`) are NEVER authored here -- computed at read time.

The AUTHORED `## Delivery Lifecycle` / `### Tasks lifecycle` / `## Delivery Gate` sections
(singular) apply ONLY to single-delivery flattened works (no `deliveries/`/`delivery-NNN/`
wrapper -- see each section's own note). They are promoted verbatim from
`delivery-state-template.md` / `task-state-template.md` and are distinct from the plural DERIVED
`## Delivery Gates` / `## Plan / Deliveries` / `## Tasks State` union views below -- no heading
collision (singular vs. plural, and `### Tasks lifecycle` differs in both text and heading level
from `## Tasks State`). Left unused for full multi-delivery works, where each delivery's own
lifecycle/gate lives in its `delivery-NNN/STATE.md` and each task's own state lives in its
`delivery-NNN/tasks/task-NNN/STATE.md` instead.

Optional `ticket_ref` scalar (frontmatter, top-level, both layouts): links this work to an
external tracker item (`<connector-stem>:<external-id>`, e.g. `jira:PROJ-123`). Left `--` when
this work is not linked; readers/dashboard ignore it. Nearest-ancestor resolution + MCP-first
consumption contract: `.claude/aid/templates/connectors/consumption-protocol.md`. Coordinate
with the in-flight `work-003-state-schema` frontmatter conventions when both touch this file's
frontmatter block. `ticket_ref` is a lifecycle-unit field only -- the connector descriptor schema
is unchanged.

<!-- STATE ADVANCEMENT ORDERING (authoritative source; schemas.md inline copy is downstream)

Ordered from most-advanced to least-advanced:
  1. Done           -- task completed and accepted; all subtasks resolved
  2. Canceled       -- resolved terminal (explicitly abandoned); ranks just below Done
  3. In Review      -- work submitted; awaiting reviewer decision
  4. In Progress    -- actively being executed on its delivery branch
  5. Blocked        -- attempted but impeded; recoverable-in-place; more actionable than Failed
  6. Failed         -- completed attempt rejected; a parallel branch may have superseded
  7. Pending        -- not yet started

Rationale: the dashboard "most-advanced wins" reconcile answers "how far has this work
gotten across all worktree branches." Done/Canceled are terminal-resolved and rank highest.
In Review outranks In Progress (review is a later pipeline stage). Blocked outranks Failed
because a blocked task is recoverable-in-place and signals "needs attention now," whereas a
failed task represents a completed-but-rejected attempt that a parallel branch may have already
superseded -- surfacing "blocked" is the more actionable signal. Both Blocked and Failed rank
above Pending because they represent work that was attempted and surfaced information (more
informative than "not started").

Closed enum VALUES (unchanged): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

This ordering is encoded ONCE here. Both reader twins (Python + Node) reference schemas.md for
the ordered list at runtime; schemas.md carries an inline copy derived from this source.
-->

> **State:** Describing | Defining | Specifying | Planning | Detailing | Executing
> **Phase:** Describe | Define | Specify | Plan | Detail | Execute

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/works/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files carry **no** inline `## Change Log` section. Content history -- what changed in a
document -- is exactly what git records, with author, date and full diff, and without drift.
Process state (where are we in the workflow) is what THIS file is for, and it stays here.

> **Superseded 2026-09-01.** This paragraph previously said the opposite: that
> `REQUIREMENTS.md`, per-feature `SPEC.md`, `PLAN.md` and per-task `DETAIL.md` *keep* their
> change logs. Both halves of that are now wrong -- the rule inverted repository-wide, and
> per-feature `SPEC.md` no longer exists (features are `### Feature NNN` sections of
> `REQUIREMENTS.md § 11`). `REQUIREMENTS.md`'s 48-line change log was deleted when the features
> were folded; its content is in git and, for the decisions that mattered, in this file's own
> Review History and Q&A, which are process records and are kept in full.

---

## Pipeline State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file
     (`lifecycle`, `phase`, `active_skill`, `updated`, `pause_reason`, `block_reason`,
     `block_artifact`), written ONLY by `writeback-state.sh --pipeline ...` at every
     phase/state transition the pipeline performs (surgical frontmatter rewrite; never
     hand-edited). All values are closed enums so a deterministic reader needs no
     inference. This section retains the enum reference below for human readability. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute
> Active Skill enum: aid-{skill} | none

---

## Interview State

<!-- AUTHORED -- updated by `aid-describe` as each section is completed. -->

**Interview State:** Revising  **Grade:** A+ (earned 2026-08-09; it stands for the message
model, which this revision does not reopen)

> **Scope reset — 2026-08-10, the runtime decision.** The approved requirements assumed a
> **Python** node carrying two third-party dependencies (`mcp`/FastMCP for the façade,
> `zeroconf` for mDNS). That assumption is withdrawn. The adopter-facing runtime moves to
> **Node**, and three consequences cascade from it, each removing scope rather than adding it:
>
> 1. **The store is `node:sqlite`** — SQLite compiled into the Node binary, zero dependencies,
>    zero compilation. Every clause of the D-2 store contract was verified by execution on
>    Node v24.19.0 and v26.7.0: WAL engages and persists, `synchronous=FULL` sticks, the partial
>    unique index rejects a duplicate while two NULLs coexist, `ON DELETE CASCADE` fires, a
>    reader held a transaction open for 3 s while a writer committed 49 sends (slowest 3 ms),
>    and a `SIGKILL` mid-transaction left 10 committed rows, discarded the uncommitted one and
>    passed `integrity_check`. Two findings go into the SPEC: the default `busy_timeout` is
>    **0**, so a non-zero value is required rather than advisable, and there is no
>    `db.transaction()` helper.
> 2. **The MCP façade is dropped.** §7 rested the choice on two reasons "and no broader one",
>    and named the second decisive: that MCP "reaches a session that is not running AID at
>    all". **That reason is void** — AID must be present for the chat to exist, and the `aid`
>    CLI is on PATH globally, so the CLI already reaches any session a skill could not. What
>    remains is discoverability, and a **rendered chat skill** serves it better on the
>    document's own evidence: all five host dialects automatically versus MCP's "confirmed for
>    two", zero third-party dependencies, and no per-host configuration snippet for the user to
>    install (FR-0.4 disappears with it).
> 3. **The node stops being a separate distributable.** FR-7.6 justified that on the node
>    needing third-party libraries. With `zeroconf` replaced by a stdlib `node:dgram` beacon
>    and the MCP SDK gone, **the node has zero dependencies**, so it ships inside the `aid`
>    payload on the `dashboard/` precedent. This deletes `aid chat deploy` and with it the
>    fetch path, exit codes 3/4/9, `--from-bundle`, `--version`, AC-7's install half, and
>    the Q20 question deferred to `/aid-specify` — closed by deletion rather than answered.
>    **AC-23 is *not* in that list: it is restated, not deleted** — it now names Node and
>    `start` where it named Python and `deploy`, but the property it tests (a missing runtime
>    fails with an explicit message, and unrelated `aid` commands keep working) is exactly the
>    promise the runtime-free CLI still makes, so it survives the change that renamed it.
>
> **What is NOT reopened, and why.** §1–§3, §6, the store schema, and the §8 host wake research
> are runtime-independent and survive intact; the store schema was verified to work verbatim on
> `node:sqlite`. Fourteen cross-reference cycles were spent on the message model and none of
> that work is invalidated by a change of runtime. Reopening it would re-litigate the half that
> is right and risk re-introducing the defects those cycles closed.
>
> **Nothing was implemented and nothing needed reverting:** no `PLAN.md`, no deliveries, no
> tasks, no `chat-node/`, and zero commits on the `work-007` branch. The reset lands before
> Plan, at the cheapest point available.

### Cross-Reference

**State:** Complete  **Grade:** A+  **Minimum:** A  **Cycles:** 14

Fourteen adversarial cycles against `REQUIREMENTS.md` and the twelve feature `SPEC.md` files
**as they stood on 2026-08-09** (that per-feature file no longer exists — the eleven survivors
were folded into `REQUIREMENTS.md § 11 Features` on 2026-09-01; see the coverage note below),
each dispatched to a clean-context `aid-reviewer`. **93 findings raised; 91 fixed, 2 routed
out of scope** (both belong to other artifacts — `STATE.md`'s own section-status text and the
KB's host-source coverage, the latter for `/aid-discover`). Cycle 14 found nothing and
confirmed no closed finding had reopened.

Ledger: `.aid/.temp/review-pending/interview-work-007-agent-chat-cross-ref.md`.

**Grade trajectory:** D- → E+ → D → D+ → C- → D → D+ → B- → B → C → C+ → C+ → B+ → **A+**.

The non-monotonic middle is the honest record of one recurring fault: a fix applied to the
line a finding named rather than to the class it belonged to, which twice re-opened findings
already closed and twice introduced a false disk claim. Two structural changes ended it —
replacing enumerated checks with property checks (AC-20 went from a list of six files to a
meaning-based search of every tracked file, after being wrong six times), and instructing each
reviewer to re-verify its own prior evidence rather than carry it forward.

**Coverage as verified at cycle 14 (2026-08-09), superseded 2026-08-10:** 25 acceptance criteria,
each mapped exactly once in §10, each claimed by exactly one feature, each passable at its
assigned stage; every requirement sub-item FR-0.1–FR-8.7 and every §6 parameter both claimed and
verified; all twelve SPECs schema-conformant.

> **This block is dated, not current.** It is kept because it is the record of what cycle 14
> actually established, and rewriting it would falsify that. But it is a **present-tense
> coverage claim**, not a changelog row, so a reader would otherwise take it for today's state.
> Three of its figures have moved:
>
> | Cycle-14 figure | Today (2026-08-10) |
> |---|---|
> | 25 acceptance criteria | **22 live** — AC-20, AC-24, AC-25 withdrawn with FR-8 |
> | twelve feature SPECs | **eleven** — `feature-002` deleted; `feature-008` renamed and rewritten |
> | FR-0.1–FR-8.7 sub-items | FR-8.1–8.7 withdrawn; **eleven** others restated or inverted — the authoritative enumeration is the §5 row of the section-status table above, deliberately not repeated here |
>
> **The coverage *property* was not re-established by the reset — and it has now been
> re-established by the 2026-09-01 fold, mechanically rather than by assertion.** Cycle 14 proved
> every criterion mapped once, owned once and passable at its stage; three criteria and one
> feature were then removed, so that proof stopped covering the current set. Folding the features
> into §11 forced the check, because every `**Criteria:**` bullet had to be derived and then
> reconciled against §9 and §10. Result: **22 live criteria, each owned by exactly one feature,
> agreeing with §10 stage for stage, and all 40 §5 sub-requirements mapped to at least one
> feature.** Verified by script over the folded document, not by reading.
>
> **Two limits on that claim, stated so it is not read as more than it is.** It re-establishes
> *mapping* and *ownership*; it does **not** re-establish "passable at its assigned stage", which
> is a judgement per criterion rather than a countable property. And three features still await
> re-specification (003, 006, 009) — their criteria are owned and mapped, but the specifications
> that must satisfy them are not yet current.

### Review History

| Date | Event | Outcome | Notes |
|------|-------|---------|-------|
| 2026-08-08 | Interview opened | — | Sections 1–10 seeded from a completed-but-unapproved interview in another repository; 6 carried open items logged as Q1–Q6 |
| 2026-08-09 | Cross-phase Q&A | 11 answered, 0 skipped | Q1–Q5, Q7–Q12. Two carried decisions overturned by the stakeholder (all authentication removed; no message size limit) and one carried premise retired as false (the §5/§7 "contradiction" — AID installs into all five host profiles, so no un-served user existed) |
| 2026-08-09 | Stakeholder comment review | 8 applied | Including the addressing model replacement (names → chats, with mention and whisper) and the wake-model correction |
| 2026-08-09 | Host research | — | Cursor, Copilot and Antigravity checked against vendor documentation; catalogued in `external-sources.md`. Corrected an analyst claim that a long-lived subscriber could not notify an idle session |
| 2026-08-09 | Quality check | 4 gaps found, 4 fixed | Unverified FRs given criteria; retired group/queue vocabulary swept; peer pairing removed as a leftover of the deleted pre-shared key |
| 2026-08-09 | KB hydration | 2 docs written | `external-sources.md` (9 vendor sources), `tech-debt.md` (M5). Forward-looking content withheld: the KB states current source state, and neither the 3.12 floor nor the chat vocabulary is true yet |
| 2026-08-09 | **Approval gate** | **Approved** | Scope widened at the gate — the repository Python 3.12 bump brought in (FR-8, AC-20, stage P0b) |
| 2026-08-09 | Cross-reference cycle 1 | **D-** — 20 findings (2 out of scope) | 18 fixed; 5 stakeholder decisions taken as Q13–Q17 |
| 2026-08-09 | Cross-reference cycle 2 | **E+** — 17 of 20 cycle-1 findings verified Fixed; 14 new (1 CRITICAL) | The CRITICAL was self-inflicted: applying Q13 added a "not a prerequisite" statement to §8 without sweeping the three places that said the opposite. Three cycle-1 findings were partial fixes of the same class — the named line corrected, the rest of the class left. Resolved by three stakeholder decisions (Q18–Q20) plus a full sweep |
| 2026-08-09 | Cross-reference cycles 3–13 | 71 further findings, all fixed | Cycles 3–7 were dominated by fix-the-line-not-the-class: three counts wrong in succession (six → eleven → thirteen → fourteen floor statements), two false disk claims propagated from reviewer evidence I had not re-verified, and four findings re-opened by my own corrections. Cycles 8–13 converged as brittle enumerations were replaced with property checks |
| 2026-08-09 | Cross-reference cycle 14 | **A+ — zero findings** | Full end-to-end acceptance sweep, not a delta check. Confirmed no closed finding reopened, and re-measured every load-bearing disk fact rather than carrying it forward |
| 2026-08-09 | Feature Decomposition | **12 features created** | Proposed by `aid-architect`, then revised twice by the stakeholder: feature names corrected to the repository's short-noun-phrase convention (five had used "and" to staple two concerns together, which split `retention-enforcement` from `operator-visibility`), and the P0 spike promoted from a spike-gate on the waker feature to `feature-001`, so that "before everything" is enforced by a real dependency rather than by plan-wave convention. Decomposition surfaced four defects in the approved requirements, all fixed before the stubs were written: AC-1 could not pass at its assigned stage (split into AC-1/AC-1b), FR-7.3 claimed an enforcement the design cannot provide (restated as a surface boundary), FR-3.1 left stage P1 with no way to name a chat (split local/network), and P0 had no acceptance criterion at all (AC-21 added) |
| 2026-08-10 | **Runtime decision — scope reset** | **Requirements reopened (6 of 10 sections)** | Stakeholder decision after a research pass: the adopter-facing runtime moves from Python to **Node**, and PyPI is dropped as a publication channel. Three cascading scope *reductions* follow — the store becomes `node:sqlite` (zero dependencies, verified by execution on v24.19.0 and v26.7.0); the MCP façade is dropped because §7's own "decisive" reason is void (AID must be present for the chat to exist, and the `aid` CLI is already global), replaced by a rendered chat skill that covers all five hosts with no per-host user setup; and the node stops being a separate distributable because FR-7.6's dependency premise is now false, which deletes `aid chat deploy` and the whole fetch path. **Two features are deleted** (`feature-002` Python floor, `feature-008` MCP façade — the latter's slot repurposed to `feature-008-chat-skill`, rewritten). **Three features STILL REQUIRE re-specification and have NOT been touched: 003, 006, 009.** `feature-003` is the largest — its Technical Specification still describes stdlib `sqlite3`, a separate `chat-node/` distributable with its own `pyproject.toml`, a Python prerequisite, and `aid chat deploy` idempotence, every one of which the reset contradicts; `feature-006` and `feature-009` have no Technical Specification at all yet, so for them "re-specify" means their Description and criteria only. **Six more await a sweep** (001 partially done — one paragraph, 004, 005, 007, 010, 011, 012). §1–§3 and the store schema stand — the schema was verified to work verbatim on `node:sqlite`. Nothing had been implemented: no `PLAN.md`, no deliveries, no tasks, no `chat-node/`, zero commits |

**No grade was computed.** `aid-describe` runs no reviewer and no grading step; the
`minimum_grade: A` in frontmatter applies to later phases that do.

| # | Section | State | Last Updated | Reopened by the runtime decision? |
|---|---------|-------|--------------|-----------------------------------|
| 1 | Objective | Complete | 2026-08-08 | No — runtime-independent |
| 2 | Problem Statement | Complete | 2026-08-08 | No — the turn-boundary analysis holds on any runtime |
| 3 | Users & Stakeholders | Complete | 2026-08-08 | No |
| 4 | Scope | **Revising** | 2026-08-10 | Yes — the Python floor leaves scope; the node stops being a separate distributable |
| 5 | Functional Requirements | **Revising** | 2026-08-10 | Yes. **This cell is the authoritative list of what the runtime decision touched in §5; every other mention of it in this file points here rather than repeating it, because two copies of a list drift.** **Eleven sub-items restated or inverted:** FR-0.1 (one core, stated without naming a second face), FR-0.2, FR-0.3, FR-0.4 (the agent surface becomes a rendered skill; the no-host-configuration rule broadens beyond MCP), FR-1.1 (no installation step), FR-6.1 (discovery stated as an outcome, not as mDNS), FR-7.2 (`deploy` deleted from the administrative list), FR-7.3 (surface boundary described for a skill), FR-7.4 (every face invokes the CLI; no client library), **FR-7.6 (inverted — the node ships inside the `aid` payload)**, FR-7.7 (the prerequisite becomes Node). **Seven withdrawn:** FR-8.1–FR-8.7 |
| 6 | Non-Functional Requirements | Complete | 2026-08-09 | **No — swept and confirmed clean.** Every parameter is runtime-independent and no mechanism had leaked in; the store schema these parameters imply was verified to run verbatim on `node:sqlite` |
| 7 | Constraints | **Revising** | 2026-08-10 | Yes — the MCP bullet's decisive reason is void |
| 8 | Assumptions & Dependencies | **Revising** | 2026-08-10 | Yes — Toolchain rewritten; the Q20 deferral closes by deletion |
| 9 | Acceptance Criteria | **Revising** | 2026-08-10 | Yes — AC-3, AC-7, AC-15, **AC-23** restated; AC-20, AC-24, AC-25 withdrawn. **AC-23 is restated, not withdrawn** (it now names Node and `start` instead of Python and `deploy`, but the property it tests is unchanged); AC-11 needed no change |
| 10 | Priority | **Revising** | 2026-08-10 | Yes — stage P0b removed; P2 loses the façade |

**Four sections stand as approved (§1, §2, §3, §6); six are reopened by the runtime decision
(§4, §5, §7, §8, §9, §10).** §6 was initially marked as needing a sweep and **has since been
swept and confirmed clean** — every parameter in it is runtime-independent, and the store schema
those parameters imply was verified to run verbatim on `node:sqlite`. It is therefore one of the
four that stand, and the table above says so.

The reopening is a change of *mechanism*, not of understanding: no reopened section is being
re-interviewed from zero, and **every section that stands is one whose content does not depend on
which runtime is chosen.** For §1–§3 that is because they describe the problem rather than a
solution. **§6 is different and is the more interesting case:** it *does* describe the solution —
durability, ordering, per-member positions, retention thresholds, the long-poll timeout — but
every one of those is a property a store must have rather than a mechanism for having it, and the
schema they imply was verified to run verbatim on `node:sqlite`. It survives by being specified
at the right altitude, not by being abstract.

Every question that once held a section Partial remains Answered — Q1 (§5/§7 admin-surface
ownership), Q7 (§5 MCP registration owner), Q5 (§6 long-poll default), Q4 (§8 toolchain), Q2
(§9 criterion ratification) and Q3 (identity) — and Sections 5, 6, 8, 9 and 10 carry the
corrections made during the `/aid-define` cross-reference pass.

**Eight Q entries are affected, and every one is annotated in place in `## Cross-phase Q&A`
rather than deleted** — three superseded, three closed by deletion, one inverted, one restated:

| Q | Was | Now | Why |
|---|---|---|---|
| Q13 | Answered | **Inverted** | It authored FR-7.6 (node as its own distributable *because* it needed third-party libraries); the node now has zero dependencies, so it ships inside the `aid` payload. The premise fell, not the reasoning — and D10 ends up preserved more literally than Q13 asked |
| Q14 | Answered | **Restated** | It made a runtime a prerequisite of the node rather than of AID, checked with an actionable error. All of that holds; only the runtime (Node, not Python) and the verb (`start`, not `deploy`) change |
| Q4 | Answered | **Superseded** | The toolchain it settled was Python 3.12 |
| Q7 | Answered | **Superseded** | There is no MCP registration to own once the façade is dropped |
| Q21 | Answered | **Superseded** | The eighth CI pin has nothing to pin; FR-8.2, AC-20, P0b and `feature-002` are all withdrawn |
| Q20 | **Pending** | **Closed** | Where `deploy` obtains the node — the node ships in the `aid` payload, so there is nothing to fetch on any channel, air-gapped included |
| Q24 | **Pending** | **Closed** | The node's own version carrier — it has no separate manifest, so it carries `VERSION` and no fifth carrier exists |
| Q25 | **Pending** | **Closed** | Whether the node's dependencies may ship compiled wheels — it has no dependencies |

**Three of the four questions that were still open are closed by this decision rather than
answered by it**, which is the clearest single measure of how much scope the reset removed.
Of the questions open before the reset only **Q23** (one-hop versus two-hop LAN coverage in the
spike) remains Pending, and it is untouched — it is a question about test coverage, not about
runtime. **Three further questions were opened afterwards, by the 2026-09-01 `master` merge, and
are Pending: Q26 (re-shaping into the v3.0.0 artifact set), Q27 (two premises the reset asserted
that the repository has not acted on), Q28 (the declared Node floor admits versions with no usable
`node:sqlite`).** Q26 is the one that blocks: no pipeline skill can advance this work until it is
answered.

Two defects those entries surfaced **outlive their questions and must not be lost with them**:
`test.yml`'s `canonical-tests` job still runs on every pull request with no interpreter pin
(from Q21), and the protocol-version handshake must now be stated independently of `VERSION`
rather than inferred from it (from Q24). The first **has been written to
`.aid/knowledge/tech-debt.md` as `W7-1`** — a durable home was required precisely because this
work folder is prunable, so prose here would have died with it; the second is a constraint on
`feature-009`, recorded in Q24's own entry.

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-08-08 | Work created | -- | Initial scaffold by aid-describe (FIRST-RUN) |
| 2026-08-09 | Describe → approved | -- | REQUIREMENTS.md approved by the stakeholder; 11 Q&A entries resolved, 8 comments applied, KB hydrated. Next: /aid-define |
| 2026-08-09 | Define → decomposed | -- | 12 features created; the P0 spike promoted to `feature-001` so "before everything" is a real dependency rather than a plan-wave convention. Decomposition found four defects in the approved requirements and fixed them before the stubs were written |
| 2026-08-09 | Define → cross-referenced | **A+** | 14 adversarial cycles, 93 findings (91 fixed, 2 out of scope), 8 further stakeholder decisions taken as Q13–Q20. Final cycle a full end-to-end sweep with zero findings. Next: /aid-specify work-007 |
| 2026-08-10 | **Specify → requirements reopened** | -- | Stakeholder scope reset on the runtime decision (Python → Node; PyPI dropped). Phase held at **Specify** rather than reverted to Describe, on this work's own precedent — its log already carries two mid-phase scope widenings ("Scope widened at the approval gate" and Q21 during `/aid-specify`). This is the same move, larger. `user_approved` stays `no`. Requirements are amended in place, not re-interviewed: §1–§3 and §6's parameters are untouched, so no elicitation is required. Next: amend REQUIREMENTS.md, delete `feature-002` + `feature-008`, re-specify `feature-003`/`006`/`009` |
| 2026-08-10 | Requirements amended + reviewed | **8 findings (2 CRITICAL)** | REQUIREMENTS.md amended, `feature-002` deleted, `feature-008` repurposed to `chat-skill`. Reviewed by a dispatched `aid-reviewer`; ledger at `.aid/.temp/review-pending/interview-work-007-runtime-reset.md`. **Both CRITICALs were self-inflicted and both were the same class this document has failed on for fourteen cycles — a correction applied where a finding pointed and not to the class it belonged to.** (1) §1 Objective still said sessions reach the node "through **both** an MCP façade and the CLI" — and it was missed *because* the section-status table had marked §1 "runtime-independent, no sweep needed", so the one section exempted from sweeping was the one that contradicted §4, §5, §7 and `feature-008`. (2) A Review History row asserted three features were "re-specified" when none had been touched, which is the false-completion claim the IMPERATIVE tracking rule exists to prevent. Fixing the reviewer's finding on stale `Status` fields (Q18/Q19) then exposed **three more instances of the same field-versus-body contradiction in text I had just written** — Q20/Q24/Q25 read `Pending` while their own bodies said "Pending → Closed". 6 findings fixed, 2 ruled Invalid (stale rows in the DERIVED, self-regenerating Features State view), 1 routed out as repository tech debt with no owner in this work. **Still pending: features 003, 006, 009 re-specification and the six-feature sweep** |
| 2026-09-01 | **master merged — resume state invalidated** | -- | 529 commits of `master` merged in, including the **v3.0.0** major release, whose own notes say a breaking change "folds away" the per-feature `SPEC.md` and per-delivery `BLUEPRINT.md` so that "an in-flight work finds them gone". This work is that in-flight work. **Three shape breaks, none of them content problems.** (1) A feature is now a `### Feature NNN` subsection of `REQUIREMENTS.md § 11 Features` — "features are sections, not folders" (`aid-define/references/feature-decomposition.md`:6,:94) — so the eleven `features/feature-NNN/SPEC.md` files have no home, and this work's `REQUIREMENTS.md` stops at §10 with no §11 at all, which is the exact condition `/aid-specify` exits on ("run /aid-define"). (2) Work state is now pure-YAML `STATE.yml`, not this markdown-plus-frontmatter `STATE.md`. (3) §9 criteria are now cited by `AC-N` id and stated in exactly one place, whereas the eleven SPECs restate criterion *text* as checkbox lists; `BLUEPRINT.md § GATE CRITERIA`, which the `## Delivery Gate` section below points at, no longer exists, and the execution graph is derived from each task's `**Depends on:**` field rather than stored. Merge conflicts were confined to three KB docs and are resolved: this work's `external-sources.md` host-harness catalogue survives, `INDEX.md` was regenerated, and `tech-debt.md` keeps `M5` + `W7-1` (both re-verified against the merged tree, line cites corrected) alongside master's rows. **The automated migration path is blocked by a repository defect, now filed as `W7-2`:** `aid __migrate-repo` refuses this `STATE.md` because `## Features State` holds real rows and the converter classes that section DERIVED, and the remedy its error names (`migrate-work-hierarchy`) exits 3 on a work with no `tasks/`. **Content survives better than shape.** The D-2 store contract was re-executed clause by clause on Node 22.14.0 — WAL, `synchronous=FULL`, the partial unique index rejecting a duplicate while two NULLs coexist, `ON DELETE CASCADE`, `integrity_check`, plus both original findings (default `busy_timeout` is `0`; no `db.transaction()` helper) — and every clause holds, so `node:sqlite` is confirmed on the floor master actually declares rather than only on the 24/26 it was verified against. Two premises the reset leaned on are **not** backed by the merged tree and must stop being assumed: PyPI is still a live channel with `requires-python = ">=3.8"` on disk and no drop recorded in `backlog.md` or `roadmap.md`, and the dashboard Node/Python twin that Q14 called "being retired rather than copied" still exists with no retirement planned. Three new questions carry what this merge opened: **Q26** (how the eleven SPECs and this `STATE.md` are re-shaped), **Q27** (the two unbacked premises), **Q28** (the declared Node floor admits versions with no usable `node:sqlite`). **Nothing is implemented, so the cost is re-shaping documents, not reverting code.** |
| 2026-09-01 | **§11 fold — the eleven features are sections now** | **coverage re-established** | Q26 answered and executed. The eleven surviving `features/feature-NNN/SPEC.md` files are folded into `REQUIREMENTS.md § 11 Features` as `### Feature NNN` subsections, and `features/` is deleted. Descriptions, User Stories and Technical Specifications carried **verbatim**, heading levels re-based two deeper for their new nesting and fence-aware so `#` comments inside code blocks were not rewritten into headings. Each `## Source` line became `**Requirements:**` + `**Criteria:**`, every clause-level carve-out preserved. **The coverage property is re-established mechanically, which is the substantive gain rather than the tidier layout:** 22 live criteria, each owned by exactly one feature, agreeing with §10 stage for stage, and all 40 §5 sub-requirements mapped — verified by script, and it is the check the reset owed since it withdrew three criteria and a feature. Retired feature-level `## Acceptance Criteria` lists became `##### BDD Scenarios` under each Technical Specification rather than being deleted: §9 is now the only place a criterion is stated, but many of those checkboxes were authored by the cross-reference cycles to cover a claimed FR clause that no §9 criterion reaches, so deleting them would have lost real coverage. Three features carry a `Re-specification pending` banner naming exactly what contradicts what (003's four dead premises, 006's stale FR-7.4 carve-out, 009's zero-configuration discovery against FR-6.1/AC-3) — **flagged in place rather than silently imported or silently fixed**, because a shape migration is the wrong place to change content. FR-7.4's three-way ownership dispute is settled and recorded. Ride-alongs: `REQUIREMENTS.md`'s 48-line `## Change Log` deleted (work artifacts now carry none); the spike's `throwaway/` and `FINDINGS.md` re-homed to the work root; a dangling citation to the withdrawn AC-20 removed; 114 `` `feature-NNN` `` backticks normalised to `Feature NNN`. **`STATE.md` is deliberately still markdown** — the conversion is blocked by `W7-2` and unblocking it is a repository schema decision, not this work's; folding first was also the right order, since the fold changes what Features State says. **Next: re-specify 003, then 006 and 009; then sweep the six untouched features. `/aid-specify` cannot run until `W7-2` is resolved.** |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy` at each delivery deploy (single writer; one row
     per delivery). Never derived from child files; aid-deploy is the sole author. Future work
     may migrate this to a per-delivery hierarchy view, but until then it is AUTHORED here.
     One row per delivery from /aid-deploy. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

## Delivery Lifecycle

<!-- AUTHORED -- single-delivery FLATTENED works only (no `deliveries/`/`delivery-NNN/` wrapper;
     `tasks/task-NNN/DETAIL.md` directly under the work root). Promoted VERBATIM from
     `delivery-state-template.md ## Delivery Lifecycle` (A-8): with exactly one delivery there is
     exactly one writer, so the disjoint-write rule that forces a separate `delivery-NNN/STATE.md`
     no longer applies and this section is authored directly here instead. Single writer: this
     work's active branch only. Written by aid-plan, aid-specify, aid-execute across the delivery
     pipeline for the synthesized `delivery-001`. Never derived from task rollup. Left absent
     (section omitted) for full multi-delivery works, where each delivery's own lifecycle lives in
     its `delivery-NNN/STATE.md` instead (unioned by the DERIVED `## Plan / Deliveries` view
     below). The enum below is byte-identical to `delivery-state-template.md` -- both reader twins
     and `writeback-state.sh` bind to the exact strings (no byte-stability break).

     The **State** scalar lives in the YAML frontmatter block at the top of this file
     (`delivery_state`) -- see the frontmatter's "Flattened single-delivery works only" group.
     Updated/Block Reason/Block Artifact stay here as markdown body (not relocated by
     work-003-state-schema task-001; see the task's schema note). -->

- **Updated:** {YYYY-MM-DDTHH:MM:SSZ}
- **Block Reason:** {short text} | --     (present only when State = Blocked)
- **Block Artifact:** {relative path} | --

### Tasks lifecycle

<!-- AUTHORED -- single-delivery FLATTENED works only (see ## Delivery Lifecycle note above).
     The single-writer home for per-task mutable state cells, REPLACING the now-absent per-task
     `STATE.md` (each task is `tasks/task-NNN/DETAIL.md` only -- immutable, no sibling STATE.md).
     Written by `writeback-state.sh --task-id NNN --field State --value V` (flattened branch),
     targeting this table instead of a `delivery-NNN/tasks/task-NNN/STATE.md`. Mirrors the REAL
     fields of `task-state-template.md ## Task State` (State/Review/Elapsed/Notes), one row per
     task-NNN. This is a `###` subsection of ## Delivery Lifecycle, distinct from the plural
     DERIVED `## Tasks State` view below (different heading text AND level -- no collision). Left
     absent (section omitted) for full multi-delivery works, where each task's own state lives in
     its `delivery-NNN/tasks/task-NNN/STATE.md` instead (unioned by that DERIVED view). The enum
     below is byte-identical to `task-state-template.md` -- no byte-stability break.

     State enum (closed; single source of truth):
       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

     MANDATORY (aid-execute/references/state-execute.md § State-Write Protocol):
     each row's State cell MUST be written the INSTANT that task's state
     changes -- In Progress before work starts, In Review before the reviewer
     is dispatched, a terminal value (Done/Failed) when finished. Binds
     whoever executes the task -- the main/orchestrator agent running it
     directly, or a dispatched sub-agent -- with no exception either way.
     (Blocked is a distinct, orchestrator-assigned value for a different,
     downstream task that depends on a failed one -- never self-written by
     the task being executed.) -->

| Task | State | Review | Elapsed | Notes | Name |
|------|-------|--------|---------|-------|------|
| _none yet_ | | | | | |

---

## Delivery Gate

<!-- AUTHORED -- single-delivery FLATTENED works only (see ## Delivery Lifecycle note above).
     Promoted VERBATIM from `delivery-state-template.md ## Delivery Gate` (A-8). Single writer:
     the delivery-gate closing step of `aid-execute` on this work's active branch, written via
     `writeback-state.sh --delivery-id 001 --block ...`. Distinct from per-task quick-check
     findings -- the gate aggregates those deferred [HIGH] rows (via
     `.aid/works/{work}/delivery-001-issues.md`; see `.claude/aid/templates/delivery-issues.md`) and runs
     a full grade.sh pass. The gate's criteria are read from this work's `BLUEPRINT.md § GATE
     CRITERIA`, NOT from this STATE.md. Left absent (section omitted) for full multi-delivery
     works, where each delivery-NNN/STATE.md carries its own gate block (unioned by the DERIVED
     ## Delivery Gates view below). The enum below is byte-identical to
     `delivery-state-template.md` -- no byte-stability break.

     Reviewer Tier / Grade / Timestamp live in the YAML frontmatter block at the top of this
     file (`gate_tier`, `gate_grade`, `gate_timestamp`) -- see the frontmatter's "Flattened
     single-delivery works only" group. Issue List stays here as markdown body (a
     variable-length inline list doesn't fit a flat frontmatter scalar). -->

- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The sections below are assembled at READ TIME from per-delivery and per-task STATE.md files.
     They are NEVER written directly. Agents MUST target the per-unit STATE.md files instead.
     Dashboard readers union the child contributions; no agent writes to these sections.
     ============================================================ -->

## Features State

<!-- AUTHORED -- one row per feature, hand-maintained by `/aid-specify` as each feature
     advances (references/state-initialize.md Step 3 "update the ## Features State table",
     state-continue.md "Set feature status to `Ready` ... in work STATE.md ## Features State").
     CORRECTED 2026-08-10: this block previously read "DERIVED -- read-only view assembled from
     features/{feature}/SPEC.md progress. Never written here." That was false and it caused a
     real defect -- a reviewer finding about two stale rows was wrongly dismissed as
     self-regenerating on the strength of this comment. NOTHING derives this table:
     `writeback-state.sh` references `## Features State` only as a positional anchor for a `---`
     rule, and no other script mentions it. The AID-side defects behind that -- a false DERIVED
     marker, and `/aid-specify`'s own column list (Feature | State | Sections | Started | Last
     Updated | Notes) not matching the columns actually used below -- are repository issues
     outside this work's scope, recorded here so the next reader is not misled the same way.
     2026-09-01: the false DERIVED marker is no longer only a documentation defect -- the
     STATE.md -> STATE.yml converter classes this section DERIVED and therefore REFUSES to
     convert this file, which is what blocks this work's migration to the v3.0.0 state format.
     It now has a durable home as `W7-2` in `.aid/knowledge/tech-debt.md`, because this work
     folder is prunable and the defect outlives it. -->

> **What a row's `#` now points at (changed 2026-09-01).** A feature is a `### Feature NNN`
> subsection of `REQUIREMENTS.md § 11 Features`, not a `features/feature-NNN-{name}/` folder with
> its own `SPEC.md`. The `Feature` column below keeps its short slug because it is how fourteen
> cross-reference cycles, the review ledgers and the §10 stage rows all refer to these features,
> and renaming it would break that trail for no gain — but it names a **section**, and the title
> in §11 is the authoritative one. "Spec State" and "Spec Grade" refer to that section's
> `#### Technical Specification`.

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 001 | wake-feasibility-spike | Ready | **A+** (cycle 5) | 1 | Stage P0 — the spike. Runs first. **DONE — clears the A minimum.** 5 cycles, trajectory C+ → B+ → B+ → A+. All 9 ledger rows Fixed, 0 open. Reviewer confirms the protocol is executable end-to-end with no unstated implementer decisions. The `.gitignore` overlap it once shared with the withdrawn Feature 002 is moot. **Folded into §11 2026-09-01 with its A+ Technical Specification intact**; its `throwaway/` directory and `FINDINGS.md` re-homed to the work root, and a dangling citation to the withdrawn AC-20 removed from its git-disposability argument |
| ~~002~~ | ~~repository-python-floor~~ | **DELETED 2026-08-10** | ~~A+ (cycle 4)~~ | 1 | **Feature deleted by the runtime decision.** No §11 section exists for it, and the number is not reused. It raised the repository Python floor to 3.12; with the adopter-facing runtime moving to Node and the PyPI channel slated to be dropped, the declaration it moved is slated to go with it (the file is still on disk today — see REQUIREMENTS.md's FR-8 withdrawal note on premise versus deliverable). Its A+ was genuine and is struck rather than erased, so the grade history reads honestly. Withdrawn with FR-8, stage P0b, AC-20, AC-24 and AC-25 |
| 003 | node-service-lifecycle | In Review (PAUSED at user request) | D (cycle 3) | 2 | Stage P1 — keystone. Cycle 3: **8 of 8 prior findings Fixed**, but **12 new open** (2 HIGH, 4 MEDIUM, 4 LOW, 2 MINOR) and **8 of the 12 were introduced by cycle 2's own fixes** — third consecutive cycle of that pattern. HIGH-15: exit `5` is also taken (`docs/install.md`:742 protect-on-diff) — the same class of error as the exit-10 miss, made again while explicitly dismissing that table as non-authoritative. HIGH-16: `id INTEGER PRIMARY KEY` without `AUTOINCREMENT` is a rowid alias, so SQLite **reuses a reaped member's id** — a later member inherits every message the reaped one sent, silently. Wave-3 verdict: **Feature 004 GO unconditionally; Feature 005 NO-GO until row 16 closes here** (`001_p1.sql` is declared unchangeable without reopening this specification, so Feature 005 cannot route around it). **Folded into §11 on 2026-09-01 carrying a `Re-specification pending` banner** that names the four dead premises its Technical Specification still rests on (stdlib `sqlite3`; a separate `chat-node/` distributable with its own `pyproject.toml`; a Python prerequisite; `aid chat deploy`). The spec text was carried rather than reset to a placeholder, because parts of it are verified-good and these twelve findings cite it — a reversible choice |
| 004 | session-registration | Pending | — | 0 | Stage P1. Folded into §11 2026-09-01; owns AC-2 |
| 005 | durable-chat-messaging | Pending | — | 0 | Stage P1. Folded into §11 2026-09-01; owns AC-5, AC-5b, AC-6, AC-9, AC-12, AC-22 — the largest criterion set of any feature. Still gated on Feature 003's HIGH-16 |
| 006 | push-subscription | Pending | — | 0 | Stage P2. Folded into §11 2026-09-01 with a `Re-specification pending` banner — one stale FR-7.4 carve-out, now settled by the ownership note under Feature 003 |
| 007 | host-waker-adapters | Pending | — | 0 | Stage P2 — shaped by Feature 001's measured number. Folded into §11 2026-09-01; owns AC-1, the headline criterion |
| 008 | **chat-skill** | Ready (Description + criteria) | — | 0 | Stage P2. **Renamed and rewritten 2026-08-10** from `mcp-message-facade`: the MCP façade is withdrawn and a rendered chat skill takes the slot. Its 8 feature-level criteria became `##### BDD Scenarios` in the fold and its single owned criterion is AC-15; its 12-row Change Log was dropped with every other one. **Technical Specification still pending** — `/aid-specify` has not run on it |
| 009 | lan-federation | Pending | — | 0 | Stage P3 — the target case. Folded into §11 2026-09-01 with a `Re-specification pending` banner: its Description and one scenario still state discovery as zero-configuration announcement, which FR-6.1 (an outcome) and AC-3 (satisfiable by the guaranteed path alone) no longer support. Also carries the Q24 constraint — the protocol version is its own number, never inferred from `VERSION` |
| 010 | directed-chat-messages | Pending | — | 0 | Stage P4. Folded into §11 2026-09-01; owns AC-17, AC-18 |
| 011 | retention-enforcement | Pending | — | 0 | Stage P4. Folded into §11 2026-09-01; owns AC-10 |
| 012 | operator-visibility | Pending | — | 0 | Stage P4. Folded into §11 2026-09-01; owns AC-13 |

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields.
     Never written here; the delivery-level STATE.md is the authoritative source.
     One row per delivery from PLAN.md. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files
     (delivery-NNN/tasks/task-NNN/STATE.md). Never written directly into this file.
     The state reader unions all delivery branches using the ordering (most-advanced wins).
     One row per task from PLAN.md execution graph.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section.
     The per-delivery gate block is the authoritative source (single writer per delivery branch).
     Never written here. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of:
       (a) each delivery-NNN/STATE.md ## Cross-phase Q&A section (delivery-gate Q&A), and
       (b) any work-owner-authored Q&A entries in this work's active branch (written below
           this comment by the work owner only; the work owner is the single writer here).
     Delivery branches write Q&A into their OWN delivery-NNN/STATE.md, not here.
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

### Decisions carried from the originating interview

Settled in a prior `/aid-describe` run conducted in another repository, and carried here
with the requirements. Recorded as rationale, not as re-openable questions — but none has
passed this work's approval gate, so any may be revisited.

| # | Decision | Rejected alternative & why |
|---|---|---|
| D1 | **MCP cannot wake an idle session.** MCP is pull-only — invoked *by* an agent, *during* a turn. Server→client notifications and `sampling` exist in the protocol, but no host maps them to "start a turn" | Hosted MCP bus as the whole solution — architecturally cannot notify an idle session |
| D2 | **Local node per machine**, deployed by the CLI | Hosted central broker — cannot reach into a local process, and a hosted service that spawns local processes is remote code execution by design |
| D3 | **Wake = in-tool subscriber.** A skill arms a background process; the host's own background-completion notification produces the turn | External waker (`claude -p --resume` + `flock`) — per-host fragmentation, session-id capture, two-processes-on-one-tree conflicts. Also `Stop`-hook mailbox — never fires once a session is fully idle |
| D4 | **Pull floor retained** — a session with no subscriber reads `inbox()` at its own turn boundaries | Subscriber-only. Rejected because the floor is *free*: a woken session must read its mail anyway, so the read tool exists regardless |
| D5 | **No spawning or resumption in the product** | Channel-owns-launching — the operator's orchestrator already launches sessions; a dead session is a launch problem, not a wake problem |
| D6 | **Address by stable name**, session id internal; queue binds to the name | Session-id addressing — sessions restart constantly (context limits, crashes, `/clear`), orphaning undelivered mail and forcing senders to re-discover ids |
| D7 | **Async request/reply** via `correlation_id`; **no blocking API** | Synchronous `ask(timeout)` — couples two turn-based agents' timelines; the asking agent stalls while the peer may not even be awake, and any timeout is a guess |
| D8 | **Durable queue, at-least-once, per-subscriber cursor, explicit ack** | Fire-and-forget. The re-arm gap then becomes *latency*, not loss — standard consumer-offset semantics |
| D9 | **Reject on overflow; hard-reject oversized payloads** — **oversized-payload half OVERRIDDEN, see Q10** | Drop-oldest / truncate — a full queue means a broken consumer and the sender must learn it. Silent truncation was already recorded as tech debt in the originating workspace |
| D10 | **All limits configurable via the CLI** | Hardcoded constants |
| D11 | **CLI is the complete admin interface; privilege boundary is absolute** — no admin operation reachable from the agent surface | Exposing admin over MCP — an agent could pair an unknown peer or stop the node |
| D12 | **Both CLI and MCP for the message plane, one shared core** (MCP is a façade) — **THE MCP HALF IS OVERRIDDEN ENTIRELY, 2026-08-10 (runtime decision); see §4 Out of Scope.** The façade is withdrawn and a rendered chat skill takes its place. **Note what this does to the rejected alternative recorded opposite:** it was "CLI-only — skills are the least portable layer and would need hand-authoring per host", and that objection is now known to be false for this repository, which renders one canonical skill into all five host dialects automatically. The surviving half of D12 — one shared core, no second implementation — is unchanged and is now FR-0.1 | CLI-only — skills are the least portable layer and would need hand-authoring per tool, forever, including future ones. MCP-only — leaves hosts with weak MCP config stranded |
| D13 | **v1 = same machine + trusted LAN** (mDNS + PSK) — **PSK element OVERRIDDEN, see Q8; mDNS element OVERRIDDEN 2026-08-10 (runtime decision), see FR-6.1.** Discovery is now stated as an outcome, with no mechanism named: research found no single mechanism reaches every environment users are in, and of eleven comparable tools surveyed only two make mDNS primary while all eleven ship a manual backstop. **The surviving core of D13 — v1 is same-machine plus a trusted LAN, with no NAT traversal and no relay — is unchanged.** Noted because D12's MCP half was marked in an earlier cycle and this half, the same class, was missed | Same-machine-only (loses federation the stakeholder wanted); full NAT traversal/relay (all the risk, none of the core value) |
| D14 | **Risk-first priority**, P0 spike before any build | Folding validation into P2 — would build federation atop a wake mechanism that may not exist on three of four target hosts |

### Q1

- **Category:** Architecture
- **Impact:** Required
- **Status:** Answered
- **Context:** Carried in as open item O1, which framed §5 FR-7.2/FR-7.4 (a CLI is the complete admin interface) as contradicting §7 (host-agnosticism as a hard constraint), on the grounds that a Cursor or Copilot user who does not use AID would need a node they cannot administer. **That framing is retired — the premise is false.** AID renders one canonical source into five host-tool profiles: `claude-code`, `cursor`, `copilot-cli`, `antigravity`, `codex` (`architecture.md:86`, `:100`; `integration-map.md:76`; `profiles/` on disk). Every host named in §3 is a profile target, so AID skills exist inside Cursor or Copilot only because the `aid` CLI installed them there. A user with the in-tool surface and no `aid` does not exist. O1 also claimed AID's install model is repo-scoped; that is only half true — the *methodology* install is per-repo, but AID's state home `AID_HOME` (default `~/.aid`, `/var/lib/aid` for shared installs — `domain-glossary.md:264`) and its dashboard service are machine-scoped. What remains genuinely open is not a contradiction but a **design choice**: how much surface the node owns.
- **Suggested:** The node has **no CLI of its own** and a single responsibility — message exchange. All administration goes through the `aid` CLI. Precedent: the local dashboard server is exactly this shape — a loopback-bound background service with no CLI of its own, administered through `aid`, state under `$AID_HOME` (`infrastructure.md:231`).
- **Answer:** Accepted as suggested. The node has **no CLI of its own** and a single responsibility — message exchange. All administration goes through the `aid` CLI, following the local dashboard server's precedent. Applied to REQUIREMENTS.md §1 and §5 FR-7 (preamble + new FR-7.5).

### Q2

- **Category:** Requirements
- **Impact:** High
- **Status:** Answered
- **Context:** AC-8 through AC-16 were authored during a quality check in the originating interview and were never explicitly accepted by the stakeholder. They are currently load-bearing — the P0–P4 priority table maps stages to them. Carried in as open item O2.
- **Suggested:** Ratify all nine as-is. Each is the observable form of a decision already taken in D1–D14 rather than new scope: AC-8←D13 (PSK trust), AC-9/AC-11←D8 (durable queue, cursor), AC-10←D9/D10 (retention, configurable), AC-12←FR-3.3 (topics), AC-13←D11 (operator visibility), AC-14←D9 (hard-reject), AC-15←D11 (privilege boundary), AC-16←FR-6.4 (version negotiation).
- **Answer:** Resolved in pieces rather than as a block, because the stakeholder reviewed the nine individually. **Deleted:** AC-8 (Q8, no authentication anywhere) and AC-14 (Q10, no size limit). **Rewritten:** AC-12 (chat delivery, with the control gap closed by Q11) and AC-16 (Q9, semantic versioning). **Ratified as-is on this turn:** AC-9, AC-11, AC-13. **Already backed by stakeholder decisions:** AC-10 (Q12 retention values) and AC-15 (Q11 privilege split). The block is now fully owned; no criterion remains unratified.
- **Not part of this entry:** AC-5b, AC-17, AC-18 and AC-19 were authored from the stakeholder's own comments 4 and 5, so they are derived instructions rather than analyst-invented criteria. Offered for review and not challenged.

### Q3

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Answered
- **Context:** Work name and description are proposed but unconfirmed; REQUIREMENTS.md carries `*(pending)*` in both identity fields. Carried in as open item O3. Resolved at COMPLETION Step 3, which requires explicit confirmation.
- **Suggested:** Name "Agent Chat Channel"; Description "Delivers a local, CLI-administered node that lets AI coding-assistant sessions message one another across repositories, tools, and LAN-connected machines."
- **Answer:** Both accepted as proposed and written into the REQUIREMENTS.md identity block, replacing the `*(pending)*` seeds. Name is Title Case with no trailing period; Description is one sentence ending with a period — the parse format COMPLETION Step 3 requires.
- **Alternative offered and declined:** "Agent Chat" / "Agent Chat Rooms" were raised because "Channel" predates the chats-only model (Q11/comment 4) and reads as a single pipe rather than many chats. The stakeholder kept "Agent Chat Channel".

### Q4

- **Category:** Architecture
- **Impact:** High
- **Status:** Answered
- **Context:** The toolchain in §8 (Python >=3.13, uv/uvx, mcp/FastMCP, zeroconf) was chosen for consistency with the originating workspace, not this repository. Carried in as open item O4. Depends on Q1 — the amount of surface the node owns decides whether it ships on AID's channels or its own.
- **Revalidation performed:** this repo's floors are Python **>=3.8** with CI pinned to **3.11**, and Node **>=22** with CI pinned to **24** (`technology-stack.md:68`, `:72`); packaging is pip/pipx and npm (`technology-stack.md:118`, `:119`), not `uv`/`uvx`. If the node ships from AID, the carried `>=3.13` is a **live conflict**, not a formality.
- **Suggested:** Ask after Q1 is answered. If the node ships inside AID, either target Python `>=3.8` to match the existing floor, or raise AID's floor deliberately as part of this work — but not inherit `>=3.13` silently from another workspace.
- **Answer (superseded first answer):** **Python 3.12**, and the repository is raised to 3.12 as its own separate work. The carried `>=3.13` is dropped, and `uv`/`uvx` with it: FR-7.5 puts packaging and distribution under the `aid` CLI, so the node uses the repository's existing pip/pipx channels. An initial answer of 3.11 was recorded and then revised by the stakeholder after reviewing the blast radius.
- **Evidence gathered before the decision:** the floor is declared in exactly one place (`packages/pypi/pyproject.toml:10`, `>=3.8`); CI pins `3.11` in seven places across four workflows; six documentation statements say `>=3.8`. 82 Python files exist, 55 of them tests. The mechanical change is roughly 14 edits.
- **Defect surfaced:** the repository declares `>=3.8` but tests only `3.11`, so the declared floor is unverified — a claim rather than a guarantee. To be fixed by the same bump.
- **Why 3.12 and not 3.13:** equally modern and equally honest, but does not exclude systems pinned to 3.12, notably Ubuntu 24.04 LTS (supported into 2029). The stakeholder considered 3.13 twice and settled on 3.12.
- **SUPERSEDED 2026-08-10 (runtime decision).** The toolchain this question settled — Python 3.12, plus the repository bump that followed from it — is replaced by Node. Kept rather than deleted, because the *evidence* it gathered is still what made the reversal cheap: it established that the floor is declared in exactly one place, and that place (`packages/pypi/pyproject.toml`) goes with the PyPI channel, which is why FR-8 could be withdrawn outright instead of re-scoped. **The deletion has not happened** — the file still reads `>=3.8` on disk — so the withdrawal rests on the decision being settled, not on the work being done. Its "defect surfaced" note also stands as the origin of the tech-debt entry that should now be re-validated and closed as Not Applicable.
- **Scope boundary — SUPERSEDED at the approval gate.** Originally the repository bump was excluded from this work and recorded only as a dependency in §8, on the grounds that a breaking change should not ride along inside a feature. The stakeholder reversed this at COMPLETION Step 5 and brought the bump into scope. Now expressed as FR-8.1–8.6, AC-20, and stage P0b, with the original concern answered by structure rather than separation: P0b shares no code with the messaging work, gates only P1, may run in parallel with P0, and is versioned and announced as a breaking change in its own right (FR-8.6). No work number was ever reserved for it.

### Q5

- **Category:** Requirements
- **Impact:** Low
- **Status:** Answered
- **Context:** §6 declares the long-poll timeout configurable but chooses no default, while every other parameter in that table has one. Carried in as open item O5.
- **Suggested:** 30 s — long enough that re-arm churn is negligible against the p95 ≤ 3 s same-machine wake target, short enough to sit inside common proxy and firewall idle timeouts. Configurable per D10, so the default is a starting point, not a ceiling.
- **Answer:** **30 s**, accepted as suggested and written into the §6 limits table. It governs only how often an idle connection recycles, never delivery latency — a message arriving mid-window is delivered immediately. The suggestion's original justification cited the p95 ≤ 3 s wake target, which no longer exists (comment 7 removed all performance targets); the value stands on the proxy/firewall idle-timeout reasoning alone. Configurable per D10.

### Q6

- **Category:** Process
- **Impact:** Required
- **Status:** Answered
- **Context:** The originating interview reached all ten sections Complete but halted at its approval gate and was never ratified — the halt was caused by the repo question itself. Nothing in this work has been approved by a human. Carried in as open item O6.
- **Suggested:** Re-run the whole-picture read-back and approval here at COMPLETION, once Q1–Q5 and Q7 are resolved. This satisfies the interview's own read-back invariant rather than inheriting an unratified document.
- **Answer:** Done as suggested. The assembled requirements were read back in full twice during the interview and once more at the gate, with the open assumptions surfaced for re-confirmation each time. The stakeholder approved on 2026-08-09, having widened scope at the gate to include the repository Python 3.12 bump. Nothing was inherited as approved from the originating interview — every carried decision was either re-ratified, overturned, or retired here.

### Q7

- **Category:** Architecture
- **Impact:** High
- **Status:** Answered
- **Context:** Found during this work's quality check; not carried from the originating interview. FR-0.2 puts the agent-facing message plane on MCP, and §7 argues MCP is the portable surface because "all four named hosts already speak it." But this repo's KB records the opposite of a wiring guarantee: **AID writes, wires, and manages no host tool's MCP configuration** — host tools own their own MCP servers and auth (`architecture.md:105`, `:111`, decision Q10). Nothing in the requirements says who registers the node's MCP server into each host, so the portability argument for MCP currently has no owner.
- **Suggested:** Treat MCP registration as the user's own step, documented but not automated — consistent with the existing decision that AID manages no host MCP config — and lean on FR-0.3 (full message plane over the CLI) as the surface that works with no wiring at all.
- **Answer:** Accepted as suggested. MCP registration is the **user's own step**: the product publishes the exact per-host configuration snippet and automates nothing, preserving the existing decision that AID writes, wires, and manages no host tool's MCP configuration. FR-0.3 remains the zero-setup path — the full message plane is reachable over the CLI with no wiring at all, so an unwired host is degraded in convenience only, never in capability. Applied to FR-0.2 and §8.
- **SUPERSEDED 2026-08-10 (runtime decision).** There is no MCP registration to own: the façade is withdrawn and a rendered chat skill takes its place, arriving through AID's own render pipeline with no user step at all. **The principle this question established survives and is now stronger** — AID writes, wires and manages no host tool's configuration — because a skill gives it nothing to manage rather than requiring restraint. Note the irony worth keeping: this question's own answer conceded that MCP "is not *zero* per-host work", and that concession is one of the reasons the façade lost.

### Q8

- **Category:** Security
- **Impact:** Required
- **Status:** Answered
- **Context:** Raised by the stakeholder while reviewing AC-8. Two problems were found. (a) AC-8's second half required that a live session's name could not be hijacked, but no requirement backed it — FR-2.1 `register()` takes no credential and FR-2.2 makes re-registering an existing name *reattach* to its queue, so any local process could claim a name and read its mail. AC-8 and FR-2.2 were in direct contradiction. (b) The carried pre-shared key (§4, FR-6.2, D13) was never specified by this stakeholder, and neither key generation nor distribution was defined anywhere, despite FR-7.2 listing "peer pairing" as an admin operation.
- **Answer:** **Remove all authentication from the product.** No key, password, login, or session credential — for peer nodes or for sessions. Trust is implicit in network membership: reachable on the trusted LAN means allowed to participate. Applied by deleting the pre-shared key from §4 In Scope, FR-6.2, AC-3, and §10 P3; deleting AC-8 entirely; and restating §4 Out of Scope and §8 so the network is named explicitly as the security boundary. Overrides the PSK element of D13.
- **Residual noted, not acted on:** FR-7.2 still lists "peer pairing" as an admin operation and AC-15 still forbids a session from pairing a peer. With no credential to exchange, what pairing now *does* is undefined.

### Q9

- **Category:** Architecture
- **Impact:** High
- **Status:** Answered
- **Context:** Raised by the stakeholder while reviewing AC-16. The carried wording ("incompatible nodes negotiate a common version or fail") never said what makes two nodes incompatible, so any version difference could be read as grounds to refuse a connection.
- **Answer:** Bind compatibility to **semantic versioning**. Nodes sharing a major version interoperate; minor and patch differences are compatible by contract. Only a major-version difference — which by definition means a breaking change — fails the handshake, and it fails with an explicit error. Applied to FR-6.4 and AC-16.

### Q10

- **Category:** Requirements
- **Impact:** High
- **Status:** Answered
- **Context:** Raised by the stakeholder while reviewing AC-14. The 256 KB max payload size in §6 was carried from the originating interview and never set by this stakeholder.
- **Answer:** **No message size limit.** A message is never rejected or truncated for being large. Applied by setting §6 max payload to "none", deleting AC-14, and rewording the §6 overflow rationale (which had justified overflow-reject by analogy to never-truncate). Overrides the oversized-payload half of D9; the overflow-reject half stands.
- **Consequence recorded in §6:** mailbox storage is now bounded by message *count* only, not by bytes. Max queue depth caps how many messages may wait, not how large they are — so the queue-depth default (still carried, not yet set by the stakeholder) is the only thing bounding disk.

### Q11

- **Category:** Requirements
- **Impact:** High
- **Status:** Answered
- **Context:** Raised by the stakeholder while reviewing AC-12, and agreed as a real gap. FR-3.3 says broadcast topics are supported and FR-4.1 lets a sender address a topic, but no requirement defines how a session **joins or leaves** a topic. The session-facing surface is `send` / `inbox` / `ack` / `wait` only (FR-0.2, FR-7.3) — none of which subscribes. AC-12 therefore asserts delivery to "every subscriber to that topic" while nothing in §5 lets a session become one. The stakeholder accepts AC-12 itself; only the missing controls are in question.
- **Suggested:** Sessions manage their own membership — add `subscribe(topic)` / `unsubscribe(topic)` to the message plane (MCP and CLI), with a topic created implicitly on first subscribe. Joining a group is not an administrative power, so FR-7.3's privilege boundary is unaffected. Fan-out copies each topic message into the member's own durable queue, so topics inherit AC-9 durability with no new machinery.
- **Answer:** The suggestion was **not** taken as offered. The stakeholder chose the CLI-owned model with a session-usable subset: the `aid` CLI holds the complete group mechanism — create, delete, add or remove any member, see all groups — and a session may manage **only its own** membership (`subscribe`, `unsubscribe`, list-my-topics). Implicit topic creation was explicitly rejected: subscribing to a topic that does not exist **fails with an explicit error**, so group creation cannot drift out of the CLI. The durable fan-out half of the suggestion was kept. Applied to FR-3.3, new FR-3.4, FR-0.2, FR-7.2, FR-7.3, AC-15.
- **Revisit marker:** the stakeholder qualified the no-implicit-creation rule as "ok **for now**" — recorded as provisional, not settled.

### Q12

- **Category:** Requirements
- **Impact:** High
- **Status:** Answered
- **Context:** The four remaining §6 retention parameters — message TTL, max queue depth per name, overflow policy, and stale-session threshold — were carried from the originating interview and never set by this stakeholder, the same defect that removed the payload limit (Q10). AC-10 tests them, so they cannot stay unowned.
- **Answer:** Ratified as-is, explicitly **as changeable defaults rather than constants**: TTL 24 h, max queue depth 1,000 messages, overflow rejects the new send, stale threshold 15 min. §6 already declares the whole table configurable (D10), so no requirement text changed — what changed is that the values now have an owner.
- **Load-bearing note:** with the payload limit removed in Q10, max queue depth is now the **only** bound on a mailbox's size on disk.

### Q13

- **Category:** Architecture
- **Impact:** Required
- **Status:** Answered
- **Context:** Surfaced by `/aid-define` cross-reference. §8 selects `mcp`/FastMCP and `zeroconf` — two third-party Python runtime dependencies — and says packaging follows the existing pip/pipx channels. `decisions.md` D10 ("Polyglot, dual-channel, **zero-dependency** distribution … declare zero runtime dependencies", **Status: Accepted**) is enforced on disk today: `packages/pypi/pyproject.toml` has `dependencies = []` and `packages/npm/package.json` has `"dependencies": {}`. `technology-stack.md` gives the rationale as keeping install "fast and supply-chain-light". Q4 caught the analogous Python-version conflict and called it "a live conflict, not a formality"; **the dependency set was never re-checked.** Verified against disk during this pass — both manifests are empty and D10 is Accepted, not superseded.
- **Suggested:** Ship the node as a **separate distributable with its own dependency set**, leaving `aid-installer` at zero dependencies. Preserves an Accepted decision without amending it, and keeps the cost on users who opt into chat. Alternatives: declare them optional extras (`pip install aid-installer[chat]`), or amend D10 explicitly with a stated supersession.
- **Answer:** Accepted as suggested. The node is **its own distributable, carrying its own dependencies**; `aid-installer` stays at zero. D10 is preserved rather than amended. Applied as new **FR-7.6**, with §8's toolchain paragraph rewritten to state the dependency cost as the reason for the separation.
- **INVERTED 2026-08-10 (runtime decision).** This answer authored FR-7.6, and FR-7.6 now says the opposite: the node ships **inside** the `aid` payload. **The reasoning is not overturned — its premise is.** This answer was correct given a node needing two third-party libraries; with `zeroconf` replaced by a standard-library discovery design and the MCP SDK gone with the façade, the node has **zero** dependencies, so there is no cost to keep away from uninterested users and nothing to separate. **The goal this answer protected is met more completely than it asked:** D10 (zero runtime dependencies) is preserved *literally*, with no separate-distributable carve-out needed at all. Note what the inversion also deleted — `aid chat deploy`, the fetch path, and Q20/Q24/Q25, all of which existed only because the node was a separate artifact.
- **Consequences:** (a) FR-7.5 previously assigned packaging and distribution to the `aid` CLI — corrected: `aid` installs and administers the node but does not vendor it; (b) **feature-002's justification changes.** The repository Python floor was in scope as a prerequisite for a node shipping inside the installer. A separately-distributed node could declare its own floor, so the bump now stands only on its own merit — `>=3.8` is untested and past end of life. It remains in scope by stakeholder decision, not by necessity; (c) Q14 (install channels) is directly shaped by this and is asked next-but-one.

### Q14

- **Category:** Architecture
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by `/aid-define` cross-reference. FR-7.5 puts the node's packaging and distribution under the `aid` CLI, which ships through four channels — GitHub Releases, npm, PyPI, and the curl/irm bootstrap. **Only the PyPI channel guarantees a Python runtime.** The precedent §7 leans on — the dashboard server — resolves exactly this by shipping **twins**: `server.mjs` and `server.py`, with `aid dashboard start` requiring an explicit `node` or `python` choice. A Python-only node inherits an unstated Python prerequisite for npm and bootstrap users. Depends on Q13: a separately distributed node may sidestep this entirely.
- **Suggested:** Answer after Q13. If the node ships through the `aid` channels, either state a Python prerequisite for non-PyPI users in §7, or follow the dashboard precedent with a Node twin. Either way, record it — this is discovered at packaging time otherwise.
- **Answer:** **Python is a stated prerequisite of the node, not of AID.** Documented, and checked at deploy time with an explicit actionable error rather than a stack trace. A user who never enables chat is unaffected. Applied as **FR-7.7** and **AC-23**, with the criterion carried by `feature-003`.
- **RESTATED 2026-08-10 (runtime decision).** The runtime is **Node**, not Python, and the check happens at `start` rather than at `deploy` (which no longer exists). **The shape of this answer survives intact and is the reason it is restated rather than superseded:** a runtime is a prerequisite of the *node*, never of *AID*; it is checked before any side effect with an explicit actionable error rather than a stack trace; and a user who never enables chat is unaffected. FR-7.7 and AC-23 both still carry it. **Its rejection of a second implementation also survives and has hardened into policy** — §4 Out of Scope now rejects a node twin outright. **One clause of this note was false and is corrected (2026-09-01):** it claimed the dashboard twin this answer cited as the expensive precedent "is being retired rather than copied". It is not. `dashboard/server/` still holds both `server.mjs` and `server.py`, and no retirement appears in `backlog.md` or `roadmap.md`. The rejection never needed that claim — it rests on this work's own cost argument, that a node carrying durable storage, federation and per-host adapters is a far worse thing to mirror than a small server — and §4 Out of Scope states the twin's size in the present tense, correctly. Tracked as Q27.
- **Rejected, with the reason recorded so it is not re-proposed:** twin Node and Python implementations, following the local dashboard server's precedent. That server is small; this node carries durable storage, federation and per-host adapters. Two of those kept in step forever is a permanent cost paid to avoid one documented prerequisite on an optional feature.

### Q15

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Answered
- **Context:** Surfaced by `/aid-define` cross-reference. AID renders **five** host profiles — `antigravity`, `claude-code`, `codex`, `copilot-cli`, `cursor` — and `external-sources.md` says so. §3, §7 and §8 name four. A case-insensitive search for "codex" across REQUIREMENTS.md and all twelve feature specs returns zero hits. Codex is neither included nor explicitly excluded; it is simply absent.
- **Suggested:** Add Codex to §3 with a status — a named target like Antigravity and Copilot, not a v1 gate — and a row in §8's host-research table marked as unresearched. An explicit "out of scope, because…" is equally acceptable; silence is not.
- **Answer:** Accepted as suggested. Codex is a **named target, not a v1 gate** — the same status as Antigravity and Copilot CLI. Added to §3's participant table, to §8's host-research table with confidence "None — not researched", and to §7's host-agnosticism constraint. §10's "why these two hosts" paragraph now names all three non-gate hosts and marks Codex as the weakest-known of them.
- **Why the honest gap is recorded rather than quietly filled:** the other three hosts each have at least a documented route; Codex has nothing. Writing "unknown" makes it a stated gap that the adapter contract (FR-5.2) is expected to absorb, instead of an absence that reads as an oversight — which is what it was.

### Q16

- **Category:** Requirements
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by `/aid-define` cross-reference. `feature-010`, `feature-011` and `feature-012` carry Priority **Should** while features 001–009 carry Must. REQUIREMENTS.md contains no MoSCoW scale anywhere — the priorities were derived from stage order during decomposition. Those three features own AC-10, AC-13, AC-17 and AC-18, all ratified §9 release conditions, and §4 In Scope names mention and whisper explicitly. A "Should" invites stage P4 to be dropped at planning, taking ratified criteria with it.
- **Suggested:** Promote all three to **Must**. Everything in §9 is a ratified release condition and §4 lists none of this as optional. If P4 is genuinely post-v1, that belongs in §9 and §10 as an explicit statement, not implied by a priority field the requirements never defined.
- **Answer:** Accepted as suggested. All twelve features are now **Must**. §10 additionally states outright that the stages are a delivery order rather than a priority scale, that every stage is required, and that nothing may be dropped at planning time without reopening §9 — so the correction cannot be re-derived by the next reader.
- **Root cause worth remembering:** the priority values were invented during decomposition from stage order, because the feature template requires a MoSCoW field and REQUIREMENTS.md defines no such scale. The template forced a judgement the requirements never authorised.

### Q17

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Answered
- **Context:** Surfaced by `/aid-define` cross-reference. §6 defines one threshold — 30 minutes without heartbeat marks a session stale, and its position "is retained until TTL". `feature-004` confirms that being marked stale "discards nothing". But AC-10 requires that a **reaped** member stops holding its chat's log from being trimmed, and `feature-011` tests reaping "past the configured threshold" — a threshold §6 never defines. Stale and reaped are two different states and only one has a trigger.
- **Suggested:** Add a second §6 parameter, a reap threshold, defaulting to at least the 24 h TTL — long enough that a session paused overnight is not reaped, short enough that an abandoned one stops blocking the trim within a day. Then align `feature-011`'s criterion to name it.
- **Answer:** Accepted as suggested. **Reap threshold, default 24 h**, added to the §6 limits table as a setting distinct from the 30-minute stale threshold and independently configurable. §6 now states plainly what the two states differ on — stale is a display state that releases nothing, reaping drops the member's claim so the trim point can move — and why the default matches the TTL: by the time a member is given up on, the messages it never read were expiring anyway.
- **Rejected:** welding reaping to TTL expiry with no separate setting. Simpler, but it would make message lifetime and dead-session patience impossible to tune apart.
- **Applied to:** §6 (limits table + prose), AC-10, `feature-011` (three criteria, replacing one that referenced an undefined threshold), `feature-004` (stale vs reaped now distinguished, and registration explicitly disclaims releasing anything).

### Q18

- **Category:** Requirements
- **Impact:** Required
- **Status:** Answered  <!-- corrected 2026-08-10: the field read Pending while this entry carried a complete Answer, Rejected and Applied-to recorded 2026-08-09. A stale field, not an open question. -->
- **Context:** Surfaced by `/aid-define` cross-reference cycle 2, ledger row 23 `[CRITICAL]`. Applying the Q13 answer added to §8 "The floor moves on its own merit, not as a prerequisite … Nothing in the messaging work depends on it", but three surviving statements say the opposite: the FR-8 preamble ("is what lets the node target 3.12 at all"), §10 ("It gates P1 — the node cannot target 3.12 while the repo is declared at 3.8") and `feature-002/SPEC.md:30-31`. `/aid-plan` derives the delivery graph from exactly this, and the two readings produce different graphs.
- **Suggested:** P0b does **not** gate P1. FR-7.6 makes the node a separate distributable that declares its own Python version, so the repository's declared floor has no bearing on what the node targets. Restate the FR-8 preamble, §10 and `feature-002` accordingly and mark P0b fully parallel.
- **Answer:** Accepted as suggested. **The repository floor raise does not gate any messaging stage.** P0b is an independent, fully parallel stage: it is in this work because it is due, not because chat needs it. The node is a separate distributable (FR-7.6) and declares its own Python requirement (FR-7.7), so what the AID repository declares does not reach it. §8's statement stands; the FR-8 preamble, §10 and `feature-002` are the statements that were wrong.
- **Rejected:** making P0b a hard predecessor of P1. It would idle the entire messaging effort behind eleven floor statements, seven CI pins and five components, buying nothing — the node's Python version is its own declaration either way.
- **Applied to:** §5 FR-8 preamble, §10 (stage P0b), `feature-002/SPEC.md` (Description + dependency wording).

### Q19

- **Category:** Requirements
- **Impact:** High
- **Status:** Answered  <!-- corrected 2026-08-10: the field read Pending while this entry carried a complete Answer, Rejected and Applied-to recorded 2026-08-09. A stale field, not an open question. -->
- **Context:** Surfaced by `/aid-define` cross-reference cycle 2, ledger row 25 `[HIGH]`. §6 says a message is removed once past its 24 h lifetime, and also that a chat's log is trimmed no further than the point every member has read. `feature-011` carries one acceptance criterion for each. For a message that is past 24 h and that some member has never read, the two criteria demand opposite outcomes and cannot both pass.
- **Suggested:** TTL wins — 24 h is a hard expiry regardless of read position, so storage is bounded by time even when a session is abandoned. The trim point then governs only messages still inside their lifetime.
- **Answer:** **Delivery wins over age.** A message is removed when it is past its lifetime **and** every member has read it — never before. The 24 h lifetime is an eligibility condition for removal, not a hard expiry. No message is ever destroyed unread. Storage stays bounded by the other two mechanisms already required, not by the TTL: the unread cap rejects further sends to a chat once any member is the configured number of messages behind, and the reap threshold drops an abandoned member's claim after 24 h of silence, at which point the trim point moves and the expired messages go. The residual is explicit and accepted: a chat holding an unread message for a crashed member keeps that message, and may stop accepting new sends once the unread cap is hit, until that member is reaped.
- **Rejected:** a hard 24 h expiry independent of read position. Simpler and bounded by time alone, but it silently destroys a message that was sent, never delivered, and never reported as undelivered — the same failure the unread cap exists to prevent, arriving by a different door.
- **Applied to:** §6 (retention prose — removal is TTL **and** fully-read, and what actually bounds storage), `feature-011` (the TTL criterion, restated so it no longer contradicts the trim-point criterion; the reap and unread-cap criteria are what carry the bound).

### Q20

- **Category:** Deployment
- **Impact:** Medium
- **Status:** Closed  <!-- 2026-08-10 runtime decision: closed by deletion, not answered. The field is flipped here to match the annotation in this entry's Answer; leaving it Pending contradicted the entry's own body. -->
- **Context:** Surfaced by `/aid-define` cross-reference cycle 2. FR-7.6 makes the node a separate distributable that `aid` installs but does not vendor, which leaves unstated where `aid deploy` obtains it from. One of AID's install channels serves offline/air-gapped machines, where a fetch from a package index is not available.
- **Suggested:** Defer to `/aid-specify` — this is a distribution-mechanism decision, not a requirement, and `feature-003`'s criteria hold either way.
- **Answer:** **Deferred to `/aid-specify`.** Where `aid chat deploy` obtains the node from, and how that works on a machine with no network, is an install-mechanism decision that belongs with the technical specification. No requirement or acceptance criterion in this work depends on the answer, and `feature-003`'s criteria hold under any of them. To be re-raised at `/aid-specify` for `feature-003`.
- **Rejected:** writing the distribution mechanism into requirements now. It would fix a plumbing choice before the node's shape is known — one file or a package — and requirements would then encode a guess.
- **Applied to:** nothing yet; carried forward as an open item for `/aid-specify` on `feature-003`.
- **CLOSED BY DELETION 2026-08-10 (runtime decision) — Status: Pending → Closed.** The question no longer has a subject. FR-7.6 is inverted: the node has zero third-party dependencies, so it ships **inside** the `aid` payload, and `aid chat deploy` is deleted along with the entire fetch path. There is nothing to obtain, on any channel — **including the air-gapped one this question turned on**, which is now served by the same mechanism as every other channel. Recorded as closed rather than removed so the deferral is visibly resolved rather than silently dropped. The deferral itself was sound: it declined to encode a plumbing guess into requirements before the node's shape was known, and the shape then changed enough to remove the plumbing.

### Q21

- **Category:** Requirements
- **Impact:** High
- **Status:** Answered
- **Context:** Surfaced by `/aid-specify` on `feature-002`. FR-8.2 and AC-20 both state **seven** CI pins, verified correct on disk many times. But `test.yml`'s `canonical-tests` job carries **no `setup-python` step at all** — it runs `tests/run-all.sh` on `ubuntu-24.04` using the image's system `python3`. That is the lane that runs on every pull request. After the migration the seven pinned lanes prove 3.12 while the PR lane proves whatever the image ships, and FR-8.5's anti-drift check is **structurally blind to it**, since a check over pins cannot see a job that has none. The dashboard reader and server suites would then be proven on 3.12 only at tag time via `release.yml`.
- **Suggested:** Add an eighth pin to `canonical-tests`, making the anti-drift check total rather than partial, and restate FR-8.2 / AC-20 from seven to eight.
- **Answer:** Accepted as suggested. **An eighth pin is added.** FR-8.5 exists so the floor cannot drift again, and an unpinned lane is precisely the hole it is meant to close — leaving it would ship the check partial on day one, with the gap sitting in the job that gates every pull request. The count moves seven → eight in FR-8.2, AC-20, §8's P0b scope list, §10's P0b row and `feature-002`'s Description, criteria and Technical Specification, and `PIN_FLOOR` in the new checker is set accordingly.
- **Rejected:** shipping at seven and recording the unpinned job as debt. It would leave the one lane developers actually feel — the PR lane — outside the guarantee, and the debt entry would describe a hole created by the very change that was supposed to close it.
- **Applied to:** §5 FR-8.2, §9 AC-20, §8 (P0b scope list), §10 (stage P0b), `feature-002/SPEC.md` (Description, Acceptance Criteria, Technical Specification).
- **SUPERSEDED 2026-08-10 (runtime decision).** Every artifact this answer was applied to is withdrawn: FR-8.2, AC-20, stage P0b and `feature-002` are all gone with FR-8, so the eighth pin has nothing to pin. **The underlying defect it found is real and outlives this work** — `test.yml`'s `canonical-tests` job runs on every pull request with no `setup-python` step, using whatever interpreter its runner image ships. That was true before this work and stays true after it. It is now a plain repository defect with no owner here, and **has been captured as `W7-1` in `.aid/knowledge/tech-debt.md`** rather than lost with the requirement that happened to surface it — this work folder is prunable, so a defect recorded only in this file would have been deleted along with the record of why it mattered.

### Q22

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Answered
- **Context:** Surfaced by `/aid-specify` on `feature-001`. AC-21 requires the spike's four answers to be written down, and the spec records them in a `FINDINGS.md` beside the SPEC — which satisfies the criterion and every consumer inside this work. But **work folders are prunable by rule** (CLAUDE.md), and one of the four answers — the measured limit on how long a Cursor `stop` hook may block — is a durable fact about a third-party host harness, not pipeline state. `feature-007`'s adapter design turns on that number, and anyone who later asks "how long can a Cursor hook block?" will find the answer deleted with the folder. `.aid/knowledge/external-sources.md` is the natural home (it already distinguishes first-hand from cited claims for exactly these harnesses), but promoting it there is a Knowledge Base change no requirement asks for.
- **Suggested:** Promote the measured number, and the Claude Code wake result, into `external-sources.md` when the spike completes — recorded as first-hand measurement with the date and method, matching how that document already handles the Claude Code harness claim. Leave the full run record in `FINDINGS.md` to be pruned with the folder.
- **Answer:** Accepted as suggested. **The measured results are promoted to `.aid/knowledge/external-sources.md` when the spike completes.** They are facts about third-party host harnesses, not pipeline state: the Cursor blocking limit is what `feature-007`'s adapter design turns on, and re-measuring it costs hours of a person's time. That document already draws the first-hand-versus-cited distinction for these exact hosts, so the entries land as first-hand measurements carrying the date, the method and the confidence bound. The full run record stays in the work folder's `FINDINGS.md` and is pruned with it. **Constraint on the KB entry (CLAUDE.md):** it states the measurement and its method only — **no work id and no work-folder path**, in prose, table or frontmatter.
- **Rejected:** leaving the number in the work folder alone. It is deleted by rule when the work ships, taking with it the one durable output of a stage whose entire purpose was to produce it.
- **Applied to:** `feature-001/SPEC.md` (Recording the Answers — the promotion step and its no-work-id constraint). The KB edit itself happens at execute time, when the numbers exist.

### Q23

- **Category:** Requirements
- **Impact:** Medium
- **Status:** Pending
- **Context:** Surfaced by `/aid-specify` on `feature-001`. AC-21's fourth question asks whether the exchange holds across two machines on the LAN. With the stub on machine A, only one of the two waiters actually crosses the network — the other is loopback on the stub's own machine. Testing both hops needs a third machine. The spec puts the hop under Cursor, the weaker-known host, and says so explicitly.
- **Suggested:** Accept one-hop coverage. The hop being tested is the one that can fail (Cursor's blocking hook over a network path), and a third machine buys a symmetric result at real setup cost for a stage whose output is thrown away.
- **Answer:** _pending_

### Q24

- **Category:** Architecture
- **Impact:** Medium
- **Status:** Closed  <!-- 2026-08-10 runtime decision: closed by deletion, not answered. The field is flipped here to match the annotation in this entry's Answer; leaving it Pending contradicted the entry's own body. -->
- **Context:** Surfaced by `/aid-specify` on `feature-003`. The node is its own distributable with its own `pyproject.toml` (FR-7.6), which means it has its own version number. AID already has four version carriers kept in lockstep by `check-version-sync.sh`, enforced at the release gate. If the node's version is meant to track `VERSION`, that script must gain it as a fifth carrier — otherwise the release gate silently stops covering the one artifact users install separately. If it is meant to version independently, nothing changes but that must be stated, or the omission reads as an oversight later.
- **Suggested:** Version the node **independently** of `VERSION`. It ships on its own cadence to people who opted into chat, and its compatibility contract with other nodes is already major-version-based (FR-6.4, AC-16) — a number tied to AID's release train would carry no information about that.
- **Answer:** **CLOSED BY DELETION 2026-08-10 (runtime decision) — Status: Pending → Closed.** The question presupposed the node being its own distributable with its own manifest and therefore its own version number. FR-7.6 is inverted: the node ships inside the `aid` payload, so it **carries `VERSION` like every other payload component** and there is no fifth carrier to add. `check-version-sync.sh` is unaffected and the release gate keeps covering everything it covered before. **The suggestion is therefore not adopted, and the reason it was attractive is worth keeping:** it argued the node ships on its own cadence to opted-in users, which was true of a separately-fetched artifact and is false of a payload component. **One consequence needs carrying into `feature-009` rather than dropping:** the protocol-version handshake (FR-6.4, AC-16) is now **independent of the artifact version**, so a node's compatibility contract must be stated by its own protocol number and never inferred from `VERSION`.

### Q25

- **Category:** Architecture
- **Impact:** Medium
- **Status:** Closed  <!-- 2026-08-10 runtime decision: closed by deletion, not answered. The field is flipped here to match the annotation in this entry's Answer; leaving it Pending contradicted the entry's own body. -->
- **Context:** Surfaced by `/aid-specify` on `feature-003`. The node may carry third-party dependencies (FR-7.6). Whether they may ship **compiled** wheels is a real constraint with downstream reach: a pure-Python rule keeps the offline/air-gapped bundle a single platform-independent file forever, while allowing compiled wheels means one bundle per platform and per Python minor. It directly constrains `feature-009`'s mDNS library choice and `feature-008`'s MCP server choice — both due in later waves.
- **Suggested:** **Pure-Python wheels only.** One of AID's four install channels serves air-gapped machines, and a platform-matrix bundle is a distribution problem that grows without bound; the libraries in question have pure-Python implementations.
- **Answer:** **CLOSED BY DELETION 2026-08-10 (runtime decision) — Status: Pending → Closed.** The node carries **no third-party dependency at all**, so there are no wheels, compiled or otherwise, and the platform-matrix bundle problem does not arise. Both libraries this question was about are gone: the mDNS one is replaced by a standard-library discovery design (FR-6.1) and the MCP one left with the façade. **The instinct behind the suggestion was right and was in effect honoured** — it wanted to protect the air-gapped, platform-independent single-file bundle, and a zero-dependency component protects it absolutely rather than by policy. **One echo of it survives as a real constraint on `/aid-specify`:** the store is the runtime's *built-in* SQLite rather than a compiled binding precisely because that keeps the no-native-code, no-platform-matrix property, and if the documented fallback to a pinned third-party binding is ever taken, this question's concern returns with it and must be re-answered rather than re-discovered.

### Q26

- **Category:** Process
- **Impact:** Required
- **Status:** Pending
- **Context:** Surfaced by merging `master` (v3.0.0) on 2026-09-01. The artifact set this work is built out of was retired by a breaking change: a feature is now a `### Feature NNN` subsection of `REQUIREMENTS.md § 11 Features` rather than a folder with its own `SPEC.md` ("features are sections, not folders" — `aid-define/references/feature-decomposition.md`:6,:94), and work state is pure-YAML `STATE.yml`. On disk this work still has eleven `features/feature-NNN/SPEC.md` files, a `REQUIREMENTS.md` that ends at §10, and a markdown `STATE.md`. `/aid-specify` resolves its target inside §11 and exits with "run `/aid-define`" when §11 is absent, so **no pipeline skill can advance this work in its present shape**. The automated half of the move is blocked by `W7-2`. Note what is *not* at stake: nothing was implemented, so this is a document re-shaping, not a revert.
- **Suggested:** Re-shape in place rather than re-deciding anything. Fold each surviving SPEC into a §11 subsection, converting its restated criterion text into `**Criteria:** AC-N` citations against §9 (which is unchanged and already carries the ids), drop the `## Change Log` sections that the current authoring rule forbids, and convert `STATE.md` by hand since the shipped converter refuses it. Carry `feature-003`'s twelve open findings across unchanged — they are defects in the *content*, which the fold does not touch, and losing them would re-open two HIGHs that took three cycles to surface. The alternative worth naming and rejecting: re-running `/aid-define` from the approved §5, which produces a well-formed §11 but discards the decomposition history, the fourteen cross-reference cycles' corrections, and `feature-001`'s A+ spike protocol.
- **Answer:** **Accepted as suggested, and the §11 half is done (2026-09-01).** The eleven SPECs are folded into `REQUIREMENTS.md § 11 Features`, `features/` is deleted, and the state conversion is deliberately **not** part of it — see the split recorded below. Coverage was re-established mechanically rather than asserted: **22 live criteria, each owned by exactly one feature, matching §10 stage for stage, and all 40 §5 sub-requirements mapped.** That closes the coverage debt the reset opened, which was the strongest argument for folding before doing anything else.
- **What the fold moved, and where:** Description and User Stories carried verbatim. Technical Specifications carried verbatim with heading levels re-based two deeper for their new nesting (`###` → `#####`), fence-aware so that `#` comments inside code blocks were not rewritten as headings. Each SPEC's `## Source` line became the `**Requirements:**` and `**Criteria:**` bullets, with every clause-level carve-out preserved.
- **The one judgement the schema forced, stated because it is the least obvious thing here.** The retired schema gave each feature its own `## Acceptance Criteria`; the current one states a criterion **once**, in §9, and has features cite ids. But those checkbox lists were never restatements — the cross-reference cycles authored many of them to cover a claimed FR clause that no §9 criterion reaches (leaving a chat, reply correlation, the operator placing another session). Deleting them would have lost coverage fourteen cycles built. They are therefore folded into `##### BDD Scenarios` under each feature's Technical Specification — a **sanctioned conditional heading** in `technical-specification-template.md` — carrying a provenance note that they are verification detail and an input to `/aid-specify`, not criteria. Nothing was deleted and nothing was invented.
- **Three features carry a `Re-specification pending` banner naming exactly what contradicts what**, rather than having their stale text quietly imported or quietly fixed: **Feature 003** (its Technical Specification rests on four dead premises — stdlib `sqlite3`, a separate `chat-node/` distributable with its own `pyproject.toml`, a Python prerequisite, and `aid chat deploy` — and it carries twelve open findings at grade D); **Feature 006** (one stale FR-7.4 carve-out); **Feature 009** (its Description and one scenario still describe discovery as zero-configuration announcement, which FR-6.1 and AC-3 no longer support). **Feature 003's spec was carried rather than reset to a placeholder** — a reversible choice, made that way because parts of it are verified-good (the store schema runs verbatim on `node:sqlite`) and twelve live findings cite it. Resetting it later is one edit; recovering it later is not.
- **FR-7.4's three-way ownership dispute is settled by the fold** and recorded under Feature 003: the retired SPECs disagreed about who owned which clause because Feature 008 was rewritten from an MCP façade into the chat skill *after* the carve-outs were written. As folded — Feature 003 owns *no client library*, Feature 008 owns *the skill's instructions are CLI invocations*, Feature 006 owns *the subscriber is a CLI invocation*.
- **Ride-alongs, each a one-line consequence of text already being rewritten:** `REQUIREMENTS.md`'s 48-line `## Change Log` deleted (the current rule is explicit that work artifacts carry none, and git plus this file's own Review History hold the same history at higher fidelity); the spike's `throwaway/` directory and `FINDINGS.md` re-homed to the work root, since there is no per-feature folder to nest them in; a dangling citation to the **withdrawn AC-20** removed from the spike's git-disposability argument; 114 `` `feature-NNN` `` backtick references normalised to `Feature NNN`, because they named folders that no longer exist.
- **Not done here, deliberately:** the `STATE.md` → `STATE.yml` conversion. It is blocked by `W7-2`, and unblocking it is a repository schema decision (does Features State get a real key, or is per-feature state derived from whether §11's Technical Specification is filled?) touching the three state templates, `bin/aid`, both dashboard readers and their tests. Exempting the section from the converter's DERIVED guard would make conversion **silently drop** the Feature 003 row — grade D, twelve findings — so the cheap fix is the wrong one. Folding first was also the correct order independently: the fold changes what Features State says, so converting first would have meant rewriting the YAML afterwards.

### Q27

- **Category:** Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** Surfaced by merging `master` (v3.0.0) on 2026-09-01. The runtime reset rested on two statements about the repository's direction that the merged tree does not support. (a) "PyPI is dropped as a publication channel" — the premise under which FR-8, AC-20, AC-24, AC-25, stage P0b and `feature-002` were all withdrawn, and under which Q4's tech-debt entry was to be "re-validated and closed as Not Applicable". PyPI is still live: `packages/pypi/pyproject.toml` declares `requires-python = ">=3.8"` on disk, `technology-stack.md`:130 states all four channels ship the same CLI, and neither `backlog.md` nor `roadmap.md` records a drop. The debt entry is correspondingly still live and re-verified as `M5`. (b) Q14's note that "the dashboard twin this answer cited as the expensive precedent is being retired rather than copied" — `dashboard/server/` still holds both `server.mjs` and `server.py`, and no retirement appears in the backlog or roadmap. **Neither premise changes a decision this work took**, which is why this is one question and not a reopening: the node is Node either way, and the rejection of a node twin stands on its own cost argument. What is wrong is that two load-bearing paragraphs assert repository futures as settled fact.
- **Suggested:** Keep both decisions and restate both premises as what they are. FR-8's withdrawal should rest on the reason that survives independently — the floor raise was never a prerequisite for the messaging work (Q18 established exactly that, and it is the reasoning `feature-002` was deleted on), not on a channel removal that has not been agreed. Q14's twin note should cite its own cost argument and drop the claim about the dashboard's future.
- **Answer:** _pending_

### Q28

- **Category:** Architecture
- **Impact:** High
- **Status:** Pending
- **Context:** Surfaced by merging `master` (v3.0.0) on 2026-09-01, which raised every adopter-facing Node requirement to **`>=22`** (`packages/npm/package.json` `engines.node`). FR-7.6 puts the node inside the `aid` payload, so the node inherits that floor rather than declaring its own — and `>=22` admits versions where the store this work chose does not work. Per the vendor history (`nodejs.org/api/sqlite.html`, accessed 2026-09-01): `node:sqlite` was **added in v22.5.0** behind `--experimental-sqlite`, and the flag requirement was **removed in v22.13.0** (and v23.4.0). So on 22.0–22.4 the module does not exist at all, and on 22.5–22.12 it exists only behind a flag. The **effective floor for the node is 22.13.0**, not 22. Verified first-hand on v22.14.0: `node:sqlite` imports unflagged and every clause of the D-2 store contract holds — WAL persists, `synchronous=FULL` sticks, the partial unique index rejects a duplicate while two NULLs coexist, `ON DELETE CASCADE` fires, `integrity_check` returns `ok`, the default `busy_timeout` is `0`, and there is no `db.transaction()` helper. It also still emits an `ExperimentalWarning` on stderr on 22.x, since release-candidate status arrives only in v24.15.0. **This is the `M5` pattern arriving from a new direction** — a declared floor that is not the floor anything was demonstrated on — and this work's own record calls that class out as a defect, so inheriting it silently would be the same error made twice.
- **Suggested:** State the node's Node requirement as **`>=22.13.0`** rather than inheriting `>=22`, checked at `start` with the explicit actionable error FR-7.7 and AC-23 already require — which is where the check already lives, so this costs a version constant rather than a mechanism. Decide separately, and record either way, whether the `ExperimentalWarning` on 22.x/23.x is acceptable on a service the operator starts or is to be suppressed; a warning on stderr at every start is the kind of thing that gets filed as a bug by someone who never reads a release note.
- **Answer:** _pending_

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries from
     delivery-NNN/tasks/task-NNN/STATE.md files.
     Appended by dispatchers at subagent completion (L1+L2+L3 traceability; always-on).
     One row per dispatch. Never written directly here; assemble from per-task logs at read time. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     delivery-NNN/tasks/task-NNN/STATE.md ## Dispatch Log sections.
     Never written here; one sub-section per task that triggered at least one dispatch.
     Updated by the dispatcher on subagent completion alongside the Calibration Log row. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._

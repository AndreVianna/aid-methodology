# Requirements

- **Name:** Agent Chat Channel
- **Description:** Delivers a local, CLI-administered node that lets AI coding-assistant sessions message one another across repositories, tools, and LAN-connected machines.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-08 | Initial interview started | /aid-describe |
| 2026-08-08 | Sections 1–10 seeded from a completed-but-unapproved interview conducted in the `PWF_MCPs` repo; decisions and open items carried into STATE.md | /aid-describe (handoff) |
| 2026-08-08 | Node scoped to a single responsibility (message exchange) with no CLI of its own; `aid` CLI confirmed as the sole administrative interface — §1 and §5 FR-7 updated, FR-7.5 added | /aid-describe (IQ1) |
| 2026-08-08 | All authentication removed — pre-shared key dropped from §4, FR-6.2, AC-3 and §10; AC-8 deleted. Trust is now implicit in LAN membership; §4 and §8 restated to say the network *is* the security boundary | /aid-describe (stakeholder) |
| 2026-08-08 | Version compatibility bound to semantic versioning — only a major-version difference fails the handshake; minor and patch are compatible by contract (FR-6.4, AC-16) | /aid-describe (stakeholder) |
| 2026-08-08 | Message size limit removed — §6 max payload set to none, AC-14 deleted; recorded that mailbox storage is now bounded by message count only | /aid-describe (stakeholder) |
| 2026-08-08 | Group mechanism defined and split: CLI holds it in full, a session manages only its own membership, joining a non-existent group fails (FR-3.4, FR-0.2, FR-7.2, FR-7.3, AC-15) | /aid-describe (IQ on AC-12) |
| 2026-08-08 | §6 retention defaults ratified as changeable defaults — TTL 24 h, max queue depth 1,000, overflow reject, stale threshold 15 min | /aid-describe (stakeholder) |
| 2026-08-09 | Stale threshold 15 min → 30 min; all §6 performance targets removed (none for v1) | /aid-describe (comments 6, 7) |
| 2026-08-09 | Wake model corrected — subscriber no longer required to exit; FR-5 rewritten around a push subscription, a per-host waker adapter contract, explicit idle/busy paths, and a token-free wait (FR-5.1–5.5) | /aid-describe (comments 1–3 + host research) |
| 2026-08-09 | §8 rewritten with per-host wake research and confidence levels; MCP confirmed unusable as a waker | /aid-describe (host research) |
| 2026-08-09 | P0 redefined as a 4-test POC on Claude Code + Cursor with stated expectations and a disposable-code rule; §3 marked the v1 proving pair and the target case | /aid-describe (comment 8) |
| 2026-08-09 | **Addressing model replaced.** Names retired as addresses; the chat is the only addressing unit and a two-member chat is a direct message. Mention and whisper added. FR-2, FR-3, FR-4 rewritten; storage moves from per-name queue to per-chat log with a per-member position | /aid-describe (comment 4) |
| 2026-08-09 | Chat ids are machine-qualified; omitting the machine resolves local-only with a hard not-found, and every chat has a home machine (FR-3.2, FR-3.3, AC-19) | /aid-describe (comment 5) |
| 2026-08-09 | Propagated the chat model into §6 and the admin/AC surface — durability, ordering, retention, and limits are now per-chat with a per-member position; FR-6.3, FR-7.1, AC-4, AC-10, AC-13 restated | /aid-describe (consistency sweep) |
| 2026-08-09 | AC-9, AC-11, AC-13 ratified — every acceptance criterion is now stakeholder-owned | /aid-describe (IQ2) |
| 2026-08-09 | Toolchain set to Python 3.12; `>=3.13` and `uv` dropped. Recorded a dependency on raising the repository floor to 3.12 as separate work, plus the unverified-floor defect it exposes | /aid-describe (IQ4) |
| 2026-08-09 | MCP registration assigned to the user — documented per host, never automated (new FR-0.4); the CLI stays the zero-setup path | /aid-describe (IQ7) |
| 2026-08-09 | Identity confirmed — Name "Agent Chat Channel", Description written into the identity block | /aid-describe (IQ3) |
| 2026-08-09 | Long-poll timeout default set to 30 s — the last open question closed | /aid-describe (IQ5) |
| 2026-08-09 | KB hydrated with what is true today — host agent-tool vendor docs catalogued in `external-sources.md`, the unverified Python floor recorded in `tech-debt.md` as M5, `INDEX.md` regenerated. Forward-looking content deliberately withheld | /aid-describe (KB hydration) |
| 2026-08-09 | Pre-approval consistency sweep — §4 delivery bullet restated to the corrected wake model; AC-15 and AC-9 moved off the retired group/queue vocabulary; peer pairing removed from FR-7.2/FR-7.3 as a leftover of the deleted pre-shared key | /aid-describe (COMPLETION Step 1) |
| 2026-08-09 | **Scope widened at the approval gate** — the repository Python 3.12 bump is brought into this work rather than deferred. New FR-8 (six requirements), AC-20, and stage P0b; §4 and §8 restated from "separate work" to in-scope | /aid-describe (stakeholder, COMPLETION Step 5) |
| 2026-08-09 | Interview complete — approved | /aid-describe |
| 2026-08-09 | AC-21 added — the P0 spike gains an acceptance criterion (four recorded answers, one a measured number); P0 was the only stage nothing verified | /aid-define (decomposition) |
| 2026-08-09 | Four defects found by decomposition and fixed: AC-1 split into AC-1 (P2, same machine) and AC-1b (P3, the target case) because AC-1 could not pass at its assigned stage; FR-7.3 restated as a surface boundary rather than a false enforcement claim; FR-3.1 split into a local half at P1 and a network half at P3, since P1 previously offered no way to name a chat; §10 stage/criterion mapping corrected | /aid-define (decomposition) |
| 2026-08-09 | Cross-reference decisions applied (Q13–Q17): node is its own distributable carrying its own dependencies, so AID's zero-dependency decision is preserved rather than amended (new FR-7.6); Python stated as the node's prerequisite with a clear deploy-time error, twins rejected (new FR-7.7, AC-23); all twelve features promoted to Must and §10 restated as a delivery order rather than a priority scale; Codex added as a named target marked not-researched; reap threshold added at 24 h, distinct from the 30-minute stale threshold | /aid-define (cross-reference Q&A) |
| 2026-08-09 | Cross-reference pass (grade D-) — 18 findings fixed. Corrected wrong disk facts: FR-8.3's floor statements were six, actually eleven (five more are hand-authored on the docs site and would not have moved); FR-8.4's Python components were three, actually five. Removed a `wait` operation from FR-7.3 that no requirement defined — a leftover of the pre-correction wake model. Replaced the §9 footnote, which still called the criteria unratified and cited two deleted ones. Corrected §8's claim that every host was checked against vendor documentation — Claude Code's row is first-hand, not cited. Reconciled the §5 preamble and the §7 MCP justification with the requirements beneath them. Removed an undefined "max chat-log depth" bound. Added AC-22 for chat lifecycle, which nothing verified. Reordered §9. Moved fan-out (AC-12) from P4 to P1, where it is actually built | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference decisions applied (Q18–Q20). **Q18 — the repository Python floor gates nothing:** the node declares its own Python requirement, so P0b is fully parallel to every messaging stage; the FR-8 preamble and §10 said the opposite and are corrected. **Q19 — delivery beats age:** a message is removed only when past its TTL *and* read by every member, so no message is ever destroyed unread; the TTL is an eligibility condition, and storage is bounded by the unread cap plus reaping instead of by time (§6, AC-10). **Q20 — where deploy obtains the node is deferred to `/aid-specify`**, recorded in §8 as a deferral rather than left silent | /aid-define (cross-reference Q&A) |
| 2026-08-09 | Cross-reference cycle 2 (grade E+) — remaining findings fixed. Cleared the critical contradiction where P0b was stated as both gating and not gating P1. Swept the three surviving "six floor statements" claims that contradicted the corrected eleven. Removed a co-location premise §7 attributed to FR-7.5, which FR-7.5 does not state and FR-7.6 contradicts. Replaced FR-7.7's false "that server is small" premise with the measured size of the dashboard twin (~8.3k lines of Node against ~10.1k of Python). Mapped AC-23 to stage P1, which nothing had claimed. Corrected two stale host counts left by adding Codex, and the claim that every stage is independently usable, which P0 explicitly is not | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 3 (grade D) — all 17 outstanding findings verified fixed, 10 new found and fixed. The floor-statement count was **still** wrong: thirteen, not eleven — two site statements were excluded because they sit in a synced manifest, but the sync script only runs when somebody types `npm run sync:docs` and no workflow does, so AC-20 could have passed with the site still advertising 3.8. FR-8.5's anti-drift property was verified by nothing; AC-24 added. Three unhedged "Claude Code's wake is proven" claims survived the cycle-2 correction and made P0's first test vacuous. FR-7.7 named an install channel that does not exist and omitted the offline-bundle one the §8 deferral turns on. The unread guarantee was stated as an absolute that reaping contradicts — now bounded to live members, with reaping named as the deliberate exception. Added the missing criteria for reply correlation, leaving a chat, and joining a non-existent chat over MCP. Corrected §10's P1/P2 boundary, which attributed to P2 three requirements that ship at P1 | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 4 (grade D+) — all 10 cycle-3 findings verified fixed, 7 new found and fixed. **A premise introduced in cycle 3 was itself false and had to be retracted:** the docs-site sync is *not* manual-only — `sync-docs.mjs` is wired to `prebuild`, so every site build re-syncs it, and CI builds the site. Two site statements are therefore generated copies that must be **verified, not edited**, and telling an implementer otherwise would have had them hand-edit generated files against a standing repository rule. A fourteenth statement was found in `tests/ui/README.md`, outside both enumerated trees, so AC-20's check is now a repository-wide grep rather than a file list — a file list is what let statements be missed twice. FR-2.3 still conflated stale with reaped and now states both, at their two thresholds. FR-7.4's two clauses were owned by two features at two stages and verified by neither; split, and the subscriber-is-a-CLI-invocation clause given a criterion. §10 claimed FR-0.3 completed at P1 when its subscriber half cannot exist until P2. Two count slips corrected | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 5 (grade C-, no CRITICAL and no HIGH) — 6 of 7 cycle-4 findings verified fixed, 10 open resolved. **New FR-8.7 and AC-25:** the Knowledge Base states the old floor in six places, correct only until FR-8.1 lands and wrong immediately after, and nothing in the work updated it — AC-20 had been excusing residue on a rationale that expires at the moment of the change. AC-20's grep is now over **tracked files** with untracked working state as its one stated exclusion, since this work's own folder legitimately states the old floor. The fourteen statements re-split correctly: **twelve** hand-edited, two generated — and the two generated ones do require an action after all (re-run the sync and commit; a drift test fails the build otherwise). Four unqualified "nothing of the member's is deleted" statements corrected — reaping *does* make unread messages removable, which is its purpose; what survives is the name. Added the missing criterion for the operator changing another session's membership. Restated a stage-P1 criterion that was framed on two machines, and moved the cross-machine half to P3. Retired a dead `D1` citation that collided with the real decision registry, and softened an "every named host speaks MCP" absolute the document's own unresearched-Codex rows contradict | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 6 (grade D) — 9 of 10 open findings verified fixed, and **two previously-closed findings recurred through my own new text**: the §9 footnote still counted four later-added criteria after AC-25 made five, and FR-8.7's Knowledge Base scope was six when the true count is **eleven** — four more sit in the KB's generated HTML summary, the same generated-copy shape already handled correctly for the documentation site one cycle earlier. Both fixed, and the KB now carries the same two-category treatment: six hand-edited, four regenerated, one debt entry deleted. §4 In Scope restated to include the Knowledge Base. Swept the "every named host speaks MCP" absolute properly this time — §7 had been softened but `feature-008` still carried it, and neither claim is established anywhere, since the host research asked about wake mechanisms rather than protocol support. FR-7.2's other-session-membership clause was claimed by no feature at all despite two criteria testing it. A P3 criterion reworded off "addressed", which reintroduced the retired names-as-addresses model | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 7 (grade D+, no recurrences) — all 7 open findings fixed, 6 new found and fixed. §8's scope restatement still said the Knowledge Base holds **six** floor statements after the requirement, criterion and feature had all moved to eleven — the same one-place-missed class, now swept. FR-8.7's headline double-counted the debt entry, which made `feature-002`'s criterion demand that a deleted entry read 3.12; the KB is now stated as **eleven places handled three ways** (six edited, four regenerated, one deleted). The §9 later-added disclosure was incomplete and mis-attributed: it named five cross-reference criteria but omitted AC-1b, which decomposition authored, and credited AC-21 to the wrong pass — now seven criteria in two labelled groups. §7's MCP bullet led with a comparative its own body retracted; it now leads with the two reasons that actually hold, and the coverage claim is stated at the strength the evidence supports (confirmed for two of five, three hosts catalogued). Two Change Log inversions and one grammatical fragment corrected | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 8 (grade B- — first cycle with no CRITICAL, HIGH or MEDIUM finding) — all 6 open findings fixed, 7 more found and fixed. §8's "The scope is…" read as exhaustive while omitting two of FR-8's seven requirements, including the anti-drift check that is the difference between a one-time edit and a property that holds; it is now an explicit seven-item list. The KB's six hand-edited statements were described as six *documents* — they live in four. The §9 provenance footnote applied its own inclusion rule unevenly: it disclosed the re-scoping of AC-20 but not the pipeline rewrites of AC-1 and AC-10, so it now names **nine** criteria whose wording is `/aid-define`'s rather than the stakeholder's. The clause-splitting sweep had stopped at §5 and never reached §6, leaving the stale threshold, the long-poll timeout and the Retention row each reading as claimed by two features. `feature-008`'s Source cited §7 for a claim §7 makes the opposite of. One Change Log row was out of sequence in this document, the same defect corrected in two feature SPECs a cycle earlier | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 9 (grade B) — all 7 open findings fixed, 4 more found and fixed. **FR-8.5 now states the mechanism it always implied:** two places credited it with requiring a CI check, but its own text asked only that the floor and the tested version "move together", which is a wish rather than a requirement — it now requires the check, and AC-24 verifies it. The old floor is **not written one way**: `>=3.8`, `3.8+`, `≥3.8` and "3.8 or later" all appear, so AC-20's search matches the meaning rather than a literal, which a single-literal grep would have missed on three of the fourteen. The §9 provenance footnote named AC-25 as the only criterion verifying a same-pass requirement; AC-23 and AC-10 are too, and all three are now flagged — with AC-25 marked as the one that genuinely extends scope rather than merely carrying a stakeholder decision. The Copilot host was named two ways across five places; it is **Copilot CLI** throughout, matching the profile AID renders into | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 10 (grade C) — all 4 open findings fixed, 5 more found and fixed, **two of them created by the previous cycle's own fixes.** Rewriting FR-8.5 to require a CI check made AC-24 a criterion verifying same-pass text, which the footnote written in that same pass did not list; and the paragraph added to fix the footnote said the Knowledge Base holds "six" floor statements when it holds ten. Both corrected — the footnote now flags four criteria, not three. **The floor search stops enumerating spellings:** `>=3.8` covers only eleven of the fourteen, and the Knowledge Base adds a spaced and an HTML-escaped variant that a four-form list still missed, so AC-20 now tests the *meaning* and treats any list of forms as illustration. FR-7.6 — the requirement protecting AID's zero-dependency decision — was verified by no criterion at all, nor was FR-7.4's in-tool-skills clause; both now are. §8 called Claude Code "the only host rated as a proven wake" four lines above stating nothing is proven; nothing is, and it now says so in both places | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 11 (grade C+) — 4 of 5 open findings fixed, 3 more found and fixed. The §9 footnote's substance was corrected last cycle but its **headline count was not**: it still said three same-pass criteria above four bullets. The "proven wake" retraction had **overshot** — §8 said FR-5 would have no *plausible* instance, when its own table rates the Cursor and Copilot CLI blocking-hook route as viable; the true claim is no *demonstrated* instance, which is what `feature-001` had said all along. `feature-003`'s new FR-7.4 criterion tested an in-tool chat skill, and this work ships none, so it was unpassable as written; it now tests the containment FR-7.4 actually asks for — the node's transport is reachable only through the CLI | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 12 (grade C+) — both open findings fixed. The FR-7.4 criterion written one cycle earlier **over-reached**: "reachable only through the CLI" holds at P1 and becomes false at P2 when the MCP façade ships, and it claimed a transport clause `feature-006` already owns. Retargeted onto the clause `feature-003` actually owns — the node publishes no client library, so a skill written later has nothing to reimplement against. Separately, FR-0.4's "automates nothing" clause — a standing repository rule that AID writes and manages no host tool's MCP configuration — was verified by no criterion anywhere; `feature-008` now tests it | /aid-define (cross-reference) |
| 2026-08-09 | Cross-reference cycle 13 (grade B+, full end-to-end sweep) — both open findings fixed, one found and fixed. The FR-7.4 criterion still carried an exclusivity clause — "the CLI is the only integration point published" — that the MCP façade contradicts from stage P2 onward; the criterion now rests on the no-client-library test alone, which holds at every stage. Coverage verified complete and exact from scratch: 25 criteria each mapped once and owned once, every requirement sub-item and every §6 parameter both claimed and verified, no clause claimed-but-unverified, and every load-bearing count re-measured against disk | /aid-define (cross-reference) |
| 2026-08-09 | **Scope widened during `/aid-specify` (Q21) — the CI pin count moves seven → eight.** Specifying `feature-002` surfaced that `test.yml`'s `canonical-tests` job, the lane that runs on every pull request, carries no `setup-python` step at all and uses whatever Python its runner image ships. It is not a wrong pin but a lane outside the guarantee, and FR-8.5's anti-drift check cannot see it, since a check over pins is blind to a job with none. Without the eighth pin the check would ship partial on day one, with the hole in the lane developers actually feel. FR-8.2, AC-20, §8's scope list and §10's P0b row restated | /aid-specify (stakeholder) |
| 2026-08-10 | **Runtime decision — scope RESET, and it reduces scope rather than widening it.** The adopter-facing runtime moves from **Python to Node** and the **PyPI channel is dropped**. Three cascading deletions follow, each because a stated premise turned out to be false rather than because a preference changed. **(1) FR-8 and stage P0b are withdrawn entirely** (with AC-20, AC-24, AC-25): they raised the repository's Python floor to 3.12, and the file carrying that declaration is slated for deletion by that same decision, so the subject is going rather than the work being deferred (the file still exists on disk; see the FR-8 withdrawal note on premise versus deliverable). **(2) The MCP façade is withdrawn** (§4 Out of Scope; FR-0.2/0.3/0.4 and FR-7.3 restated around a rendered chat skill). §7 rested that choice on two reasons "and no broader one" and called the second decisive — that MCP reaches a session "not running AID at all". **The stakeholder identified that as void:** AID must be present for a chat to exist, and the `aid` CLI is global, so the CLI already reaches any session a skill could not. On the document's own evidence the skill route dominates — all five hosts by construction versus "confirmed for two", no third-party dependency, and no per-host snippet for the user to install. **(3) FR-7.6 inverts and `aid chat deploy` is deleted.** FR-7.6 made the node a separate distributable *because* it needed third-party libraries; with `zeroconf` replaced by a standard-library discovery design and the MCP SDK gone, **the node has zero dependencies**, so it ships in the `aid` payload on the `dashboard/` precedent. That deletes the fetch path, `--from-bundle`, `--version`, AC-7's install half, and **closes the Q20 deferral by deletion rather than by answering it**. FR-6.1 and AC-3 are restated as **outcomes** rather than naming mDNS, because research found no discovery mechanism reaches every environment users are in and that only two of eleven comparable tools make mDNS primary while **all eleven** ship a manual backstop. FR-7.7 now states a **Node** prerequisite for runtime components while the CLI stays runtime-free. §1–§3 and §6 are untouched: the store schema was verified to run **verbatim** on `node:sqlite` (Node v24.19.0 and v26.7.0), so the message model this document spent fourteen cross-reference cycles on is unaffected by the change of runtime | /aid-specify (stakeholder) |

## 1. Objective

Provide a communication channel that lets one AI coding-assistant session send messages or
notifications to another. The sessions work in **different repositories**, and are started
by the operator's own orchestrator rather than by a lead-spawns-teammates framework.

Sessions talk in **chats**. A chat is the only thing a message is addressed to, and the
smallest chat — two members — *is* a direct message. Larger chats add **mention** (aimed at
someone, visible to all) and **whisper** (visible only to one member).

The channel is delivered as a **local node** — a service deployed and administered by the
`aid` CLI, running on each machine and serving every session on it, regardless of tool. The
node itself has a single responsibility, message exchange, and ships no operator surface of
its own. Nodes federate to other machines over a trusted LAN. Sessions reach the node
**through the `aid` CLI**, which carries the whole message plane over one core; a **rendered
chat skill** makes that surface discoverable to a session without being a second surface of its
own (§4, FR-0). An MCP façade was specified here and **withdrawn on 2026-08-10** — see §4 Out of
Scope for why.

A hosting server is available but is **deliberately unused in v1**; it is held in reserve
for a later delivery, should NAT traversal or relay ever be required.

## 2. Problem Statement

An AI coding-assistant session is **turn-based, not a server**. It has no event loop that
can be pushed to, and receives nothing asynchronously mid-turn; between turns it is idle,
waiting for input. Consequently the transport is not the hard part — **getting a message
into a turn is**.

Delivery splits by the recipient's lifecycle at the moment the message arrives:

| Recipient state | What "notify" actually means |
|---|---|
| Idle (finished its task, sitting there) | A turn must be **started** for it |
| Actively running its own loop | It can only be handed the message at its **next turn boundary** |
| Not yet started | The notification *is* the **launch** |

This is why named pipes, Unix sockets, and Redis pub/sub feel correct but do not by
themselves solve the problem: nothing inside the recipient is listening on the socket,
because these tools expose no listener loop. The pattern must be chosen by the recipient's
lifecycle, not by the IPC technology.

Today there is no shared mechanism for this coordination.

### Prior art considered (input, not a decision)

1. **Resume an idle instance** — `claude -p --resume <session-id> "<message>" --bare`,
   serialized with `flock`. Lands as a real user turn with context intact; no live process
   or relay daemon; survives reboot. Caveat: `--resume` spawns a *new* process continuing
   the session, so a still-live original on the same working tree causes conflicts. Saved
   mid-session hook output replays stale; only `SessionStart` hooks re-run
   (`source=resume`).
2. **File inbox + `Stop`-hook turn-guard** — sender appends to a JSONL inbox; the
   recipient's `Stop` hook blocks turn-end when mail is unread. Requires the
   `stop_hook_active` guard or it loops forever. Limitation: only fires while the recipient
   is still taking turns; a fully idle recipient never picks the mail up.
3. **Persistent bidirectional streaming** — `claude -p --input-format stream-json
   --output-format stream-json`. The only CLI mechanism for bidirectional programmatic
   comms in print mode, but underdocumented and subject to a block-buffering bug when
   piped. Amounts to building and babysitting a daemon.
4. **First-party Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) — mailbox +
   `SendMessage` + shared task list, but modeled as one lead spawning teammates on a
   *shared* codebase, experimental, and token-heavy. Its *mechanism* (file inbox,
   between-turn pickup) is applicable; its framing is not.

## 3. Users & Stakeholders

**Participants (the messaging endpoints).** AI coding-assistant sessions, explicitly not
one vendor:

| Participant | Status |
|---|---|
| Claude Code | **v1 proving pair.** Reference host; wake mechanism understood first-hand but **not yet proven — the P0 spike tests it first** (§8) |
| Cursor | **v1 proving pair.** Wake route identified, one measurement outstanding (P0) |
| Antigravity | Named target; not a v1 gate. Researched, but its documentation is **silent** on external wake — no route known |
| Copilot CLI | Named target; not a v1 gate. Wake route documented (`agentStop`), unmeasured. (GitHub Copilot CLI — named **Copilot CLI** throughout, matching the profile AID renders into) |
| Codex | Named target; not a v1 gate. **Not researched at all** — the only host nobody has looked at, which is a different gap from Antigravity's, where the looking was done and found nothing |
| Future/unknown tools | Must be supportable without redesign — via the FR-5.2 adapter contract |

**The target case:** a developer in Cursor on one machine exchanging messages with a
developer in Claude Code on another machine on the same network. Every other case — both
sessions on one machine, both in the same tool, one-way only — is a subset of it. Solving
the target case solves them all.

**Operator.** The human running the fleet, who launches sessions via their own
orchestrator and needs to see and audit what was sent between them.

## 4. Scope

### In Scope

- **Chat-based messaging between sessions**, regardless of which tool hosts each session.
  A chat is the only addressing unit; a two-member chat is a direct message. Within a chat
  of more than two, a message may **mention** members (visible to all) or **whisper** to one
  (visible only to them).
- A **local service (node)**, deployed by the CLI, that all local sessions connect to.
- **Cross-machine** connection between nodes on a **trusted LAN**: peers **find each other**,
  and store-and-forward at the sending node so a peer whose machine is offline still
  receives its messages. **The discovery mechanism is deliberately not named here** — it is
  stated as an outcome, because the research behind FR-6.1 found that no single mechanism
  works everywhere users actually are.
- **Delivery to a live session that is not currently taking a turn**, via an in-tool
  subscriber that holds a token-free wait open and turns an arriving message into a turn
  (FR-5.2). An idle session is woken on arrival; a busy one receives at its next turn
  boundary. **Pull remains the universal floor** — a session with no subscriber armed reads
  its inbox at its own turn boundaries using the same read tool.
- **No process spawning or session resumption anywhere in the product.** Launching a
  session that is closed or does not yet exist remains the responsibility of the
  operator's existing orchestrator.
- **A rendered chat skill**, in the repository's existing canonical-skill form, so that a
  session *discovers* the chat exists. The `aid` CLI is on PATH but is not advertised to a
  model; a skill is. It renders into all five host dialects through machinery this repository
  already has, invokes the CLI (FR-7.4), and reimplements nothing.

### Out of Scope

- **An MCP façade.** Dropped on 2026-08-10. §7 rested the choice on two reasons "and no
  broader one" and named the second decisive — that MCP reaches a session "not running AID at
  all". **That reason does not hold:** AID must be present for the chat to exist, and the
  `aid` CLI is installed globally on PATH, so the CLI already reaches every session a rendered
  skill could not. What was left was discoverability, and the skill above serves it on better
  terms — all five hosts by construction rather than "confirmed for two", no third-party
  dependency, and no configuration snippet for the user to install by hand.
- **Raising the repository's Python floor.** Removed from scope on 2026-08-10, and this is a
  deletion rather than a deferral: with the adopter-facing runtime on Node and the PyPI
  channel dropped, no shipped code will declare a Python floor to raise. (Dropping that channel
  is a settled decision arriving as a premise, not work this document performs — see the FR-8
  withdrawal note.) The maintainer-only
  profile renderer stays on Python and is a separate, maintainer-scoped concern.
- **A second implementation of the node.** One runtime, one implementation. The local
  dashboard server's Node/Python twin is a precedent this work declines to follow — roughly
  8,300 lines mirroring roughly 10,100, kept in step by a dedicated CI parity gate. A node
  carrying durable storage, federation and per-host adapters would be worse.

- **NAT/firewall traversal** and any internet-scale or cross-network reach. v1 assumes a
  flat, trusted LAN.
- **Relay / rendezvous infrastructure.** The available hosting server is deliberately
  unused in v1 and held in reserve for a later delivery.
- **Untrusted or public networks.** Trust is implicit in network membership: being on the
  LAN is the only condition for participating. There is no key, password, or login
  anywhere in this product — so the network itself must be a controlled one.
- **Launching or resuming sessions.**

## 5. Functional Requirements

**One surface, one core.** The **`aid` CLI** is the whole product surface — administration,
the subscriber, and the full message plane. HTTP is the node's internal transport, not a
second public surface: the subscriber reaches it through a CLI invocation (FR-7.4), so
nothing outside the product calls it directly.

A **rendered chat skill** sits above the CLI as *documentation the model can find*, not as a
second surface. It carries no logic and holds no state: every operation it describes is an
`aid chat` invocation.

### FR-0 — Surface

| # | Requirement |
|---|---|
| FR-0.1 | There is **one core implementation** of the message plane. No face may reimplement it, and a face that cannot be expressed as a call into that core is not added |
| FR-0.2 | **A session reaches the message plane through the CLI** — `send`, `inbox`, `ack`, plus its own chat membership (`join`, `leave`, list-my-chats; FR-3.4). Administrative operations exist on the same CLI and are **not** described by the chat skill (see FR-7.3) |
| FR-0.3 | The CLI covers administration, the subscriber, **and** the full message plane, so the product is fully functional on every host, with no per-host protocol support required of anyone |
| FR-0.4 | **The product writes no host tool's configuration.** It renders a skill into the host dialects it already supports, through the same pipeline as every other AID skill, and touches nothing else — no MCP registration, no settings file, no hook wiring. A host whose skill is absent loses discoverability, never capability: the full message plane stays reachable over the CLI per FR-0.3 |

### FR-1 — Node lifecycle

| # | Requirement |
|---|---|
| FR-1.1 | **The node needs no installation step.** It ships inside the `aid` payload (FR-7.6), so there is nothing to fetch, resolve, verify or install: the CLI **starts** it, and starting it is safe to run without checking whether it is already running |
| FR-1.2 | The node runs as a background service, independent of any session's lifetime |
| FR-1.3 | The CLI reports node status and can stop it |

> **One sub-decision is deliberately left to `/aid-specify`, and named rather than assumed.**
> FR-1.1's "safe to run without checking" was previously carried by `deploy`, which was
> idempotent; `start` was not, and returned a distinct code when the node was already running,
> matching `aid dashboard start`. With `deploy` deleted there is no longer a verb holding that
> property, so `start` must either **absorb it** (already-running becomes success) or **keep the
> distinct code** and leave FR-1.1 satisfied by the absence of an install step alone. The
> dashboard precedent points one way and this requirement's original wording points the other.
> Nothing else in this document depends on the answer.

### FR-2 — Session registration

| # | Requirement |
|---|---|
| FR-2.1 | A session registers with `register(name, tool, cwd, capabilities)`, binding itself to a **stable name**. The name is an **identity, not an address** — it is how a session is recognised inside a chat, mentioned, and whispered to; it is never a destination on its own |
| FR-2.2 | A session's full id is **machine address + session name**, mirroring the chat rule in FR-3.2. Names are unique per machine. Re-registering an existing name **reattaches** that session to its existing chat memberships and positions |
| FR-2.3 | **Liveness is tracked** (heartbeat or connection), and drives **two distinct states at two thresholds** (§6). **Stale** — quiet past the stale threshold — is a *display* state: the member is shown as probably gone and **nothing is released**. **Reaped** — quiet past the longer reap threshold — is the node giving the member up for good: its registration is released and it **stops counting toward its chats' trim points**, which is what lets those logs be trimmed again — **including messages it never read.** Its identity is not destroyed: the name is free and re-registering it is accepted at any time. Tracking and stale-marking belong to registration; reaping belongs to retention |

### FR-3 — Chats and addressing

**The chat is the only addressing unit.** There is no direct-to-session address. A message
is always sent *to a chat*, and a chat always has at least two members. A two-member chat
**is** a direct message — the same mechanism, not a special case. This is deliberate: one
concept instead of two, with private conversation as its smallest instance.

| # | Requirement |
|---|---|
| FR-3.1 | **Listing has a local half and a network half, and they ship at different stages.** *Local* — list the chats hosted on this machine, and the chats the calling session belongs to. Needs no network and is available from the first usable release, because a session cannot join a chat it has no way to name. *Network* — list machines on the network and, for a given machine, the chats it hosts and their members, with tool, liveness, and declared capabilities. Arrives with federation |
| FR-3.2 | A chat's full id is **machine address + chat name**. When the machine address is omitted, resolution is **local-machine-only**: if no chat of that name exists on this machine the result is **not found**, even when a chat of that name exists on another machine. There is no silent remote fallback |
| FR-3.3 | Every chat has a **home machine** — the machine in its id. Members on other machines take part remotely; the chat itself lives in one place |
| FR-3.4 | **Chat control is split.** Chat *existence* (create, delete) and any change to *another* session's membership are administrative and CLI-only (FR-7.2). A session may manage **only its own** membership: `join(chat)`, `leave(chat)`, and listing the chats it belongs to. Joining a chat that does not exist **fails with an explicit error** — a session never creates a chat implicitly |
| FR-3.5 | **Mention** — a message may flag one or more members by name. The message stays visible to the whole chat; the flag marks who it is aimed at |
| FR-3.6 | **Whisper** — a message may be directed to exactly one member, and is then visible **only** to that member and its sender. Other members never see it, in delivery or in history |
| FR-3.7 | Mention and whisper are meaningful only in a chat of **more than two** members. In a two-member chat every message already has exactly one recipient, so neither is required — and a whisper there is equivalent to an ordinary message |

### FR-4 — Messaging

| # | Requirement |
|---|---|
| FR-4.1 | `send(chat, body, kind?, idempotency_key?, mention?, whisper_to?)` delivers to a chat. `mention` flags members without restricting visibility; `whisper_to` restricts visibility to one member (FR-3.5, FR-3.6). The two are mutually exclusive on a single message |
| FR-4.2 | Each **chat** owns a **durable message log** that persists across session restarts and node restarts, and each **member holds its own position** in that log. A session in several chats holds one position per chat |
| FR-4.3 | `inbox(chat?, cursor?)` returns messages after the caller's position — for one chat, or across every chat the caller belongs to when `chat` is omitted. Whispers not addressed to the caller are never returned |
| FR-4.4 | `ack(chat, cursor)` advances the caller's committed position in that chat |
| FR-4.5 | Delivery is at-least-once; recipients dedupe on the idempotency key |
| FR-4.6 | Messages carry a `kind` and an optional `correlation_id` / `reply_to` |
| FR-4.7 | A reply is an **ordinary asynchronous message** that wakes the requester through the normal path. The API exposes **no blocking operation** — no session's turn ever stalls waiting on another session |

### FR-5 — Wake and subscription

| # | Requirement |
|---|---|
| FR-5.1 | The node offers a **push subscription** — a connection a subscriber holds open and the node pushes to on arrival (WebSocket, or a long-poll for hosts that cannot hold a socket). The subscriber is **not required to exit** to deliver |
| FR-5.2 | **Waker adapter, one per host tool.** Every adapter satisfies one contract: *wait without consuming model tokens, and turn an arriving message into a turn.* The node, the store, and the wire protocol are identical across hosts; only the adapter differs. A host with no viable adapter degrades to FR-5.3, it does not block the product |
| FR-5.3 | **Pull floor:** reading the inbox is fully usable with no subscriber armed |
| FR-5.4 | **Idle and busy are different paths, both required.** *Idle* — the adapter produces a turn as soon as a message arrives. *Busy* — messages accumulate and are delivered at the session's next turn boundary. Neither path loses a message; the busy path only delays it |
| FR-5.5 | **The wait must be free.** An adapter blocks in a process outside the model, never by keeping the model in a poll loop. Cost while idle is zero tokens |

### FR-6 — Cross-machine (trusted LAN)

| # | Requirement |
|---|---|
| FR-6.1 | **Nodes find each other on the LAN.** This is stated as an *outcome*, not a mechanism, and the change is deliberate: the mechanism was previously fixed as mDNS, and research established that no single mechanism reaches every environment users are actually in — WSL2 host-to-distro multicast is an open upstream defect, access-point client isolation and VLAN splits defeat broadcast and multicast alike, and macOS 15+ gates both silently for a per-user agent. Of eleven comparable local-first tools surveyed, only two make mDNS their primary mechanism, and **every one of them ships a manual path as the backstop.** The requirement is therefore that discovery **works**, with a guaranteed path that depends on no network feature, and zero-configuration discovery layered above it as best-effort. `/aid-specify` fixes the layers; this requirement fixes only that the outcome is reached and that no layer is load-bearing alone |
| FR-6.2 | Node-to-node trust is **implicit in network membership** — a node reachable on the trusted LAN participates. No key, password, or login is required, of a peer node or of a session |
| FR-6.3 | The **sending** node stores and forwards a message whose destination chat's **home machine** is offline, delivering it once that machine returns |
| FR-6.4 | The handshake compares protocol versions by **semantic versioning**: nodes sharing a **major** version interoperate, and minor or patch differences are compatible by contract. Only a **major** difference — which by definition means a breaking change — fails the handshake, and it fails with an explicit error |

### FR-7 — Administration and the privilege boundary

The **`aid` CLI is the complete administrative interface** to the local node. All service
management goes through it; sessions reach only the message plane.

"The CLI" throughout this document means **the `aid` CLI**. The node itself ships no
operator-facing command — it is a service, administered from outside. This mirrors the
existing local dashboard server: a loopback-bound background service with no CLI of its
own, administered through `aid`, with state under `$AID_HOME`.

| # | Requirement |
|---|---|
| FR-7.1 | The CLI shows machines and registered sessions, the chats on this machine with their members, each member's unread depth per chat, and a message audit log |
| FR-7.2 | All service management — start, stop, status, configuration, retention policy, **chat lifecycle (create, delete) and any change to another session's chat membership** — is performed **through the CLI only**. The CLI holds the complete chat mechanism, including everything a session can do for itself. **`deploy` was the first item on this list and is deleted, not moved:** the node ships in the `aid` payload (FR-7.6), so there is no install operation to administer. There is no peer-pairing operation either: trust is implicit in network membership (FR-6.2), so there is nothing to exchange or approve |
| FR-7.3 | **The agent-facing surface describes the message plane and nothing else.** The chat skill documents `send` / `inbox` / `ack` and a session's own membership (FR-3.4). It does not describe stopping the node, altering configuration, retention policy, creating or deleting a chat, or changing another session's membership. It documents no `wait` either: FR-4.7 forbids a blocking operation anywhere, and waiting is the waker adapter's job. **This is a surface boundary, not a sandbox** — and the honesty is now structural rather than a caveat: the boundary is a *skill that omits things*, and any session whose host lets it run shell commands can invoke the full CLI directly. It states what the product **offers** an agent and is explicit that it prevents nothing. Real containment would need a session-scoped credential, which this product does not have (there is no authentication anywhere — §4) and does not claim |
| FR-7.4 | **Every face invokes the CLI rather than reimplementing node behaviour**, and the node publishes no client library or SDK for one to bind to. The chat skill is instructions that call `aid chat`; the subscriber of FR-5.1 is a CLI invocation. Together these keep the HTTP transport internal to the node |
| FR-7.5 | The node has a **single responsibility: message exchange.** It ships no CLI and no operator surface of its own, and every human-facing operation against it is an `aid` subcommand. A change that would give the node its own operator-facing command is out of scope |
| FR-7.6 | **The node ships inside the `aid` payload, and carries no third-party dependency.** This requirement was previously the opposite — the node was a separate distributable *because* it needed third-party libraries — and **that premise is now false**, which is why the conclusion inverts rather than being defended. Both named libraries are gone: mDNS is replaced by a discovery design built on the standard library (FR-6.1), and the MCP server implementation left with the façade (§4 Out of Scope). A component with zero dependencies costs an uninterested user nothing but disk, so the separation bought nothing and cost a whole install-and-fetch surface. The node is therefore provisioned exactly as `dashboard/` already is: a runtime component at the repository root, listed in a manifest that every publication channel derives its file set from. **AID's zero-runtime-dependency decision is preserved literally, not amended** — no carve-out is required, because there is nothing to carve out |
| FR-7.7 | **A Node runtime is a prerequisite of the chat node, and this is stated rather than implied.** The `aid` CLI itself remains runtime-free — Bash and PowerShell only — so installing, updating and removing AID needs nothing but a shell. What this requirement governs is **the chat node**. Two other components need Node already, before and independently of this work, and are named for context rather than claimed as scope: the two on-demand skills that invoke Node scripts, and the dashboard server, which has offered a Node runtime alongside a Python one for as long as it has existed — **which of those two the dashboard keeps is adjacent work, not this requirement's** (see §10). The prerequisite is **checked before any side effect, with an explicit, actionable error** — never a stack trace, never a silent failure. It is honest about reach, and the distinction it draws is the load-bearing one: the audience installs its host tools through npm, so a runtime is **present**, but **no named host tool establishes which version** — several bundle their own or declare no minimum at all (§8 states this per host rather than as a count, deliberately). So Node may be assumed present; *a recent* Node may not. That argues for a **low** declared floor, and `/aid-specify` fixes two of them — one for components every adopter runs, one for the opt-in node — because they have different needs and need not be the same number |

### FR-8 — withdrawn

**FR-8 (repository Python floor) was deleted on 2026-08-10 and is not renumbered**, so that
every reference to FR-8.1–FR-8.7 elsewhere resolves to this note rather than to silence or,
worse, to a different requirement that inherited the number.

It required raising the declared Python floor to 3.12 across a declaration, eight CI pins,
fourteen documentation statements and eleven Knowledge Base places. **The runtime decision
removes its subject rather than deferring its work:** the adopter-facing runtime components
move to Node and the PyPI channel is dropped, so `packages/pypi/pyproject.toml` — the file
carrying the declaration — **is slated for deletion**, after which no shipped artifact declares a
Python floor.

> **A premise, not a deliverable — and the distinction is load-bearing, so it is stated once here
> and referenced from every other withdrawal note.** Dropping the PyPI channel is a **settled
> stakeholder decision that arrives as an input to this document.** Executing it — deleting
> `packages/pypi/`, retiring the publish job, choosing the dashboard's surviving implementation —
> is **adjacent work that is not in this document's scope and is verified by no criterion here**
> (§10). Both halves are needed to read the withdrawals correctly:
>
> - Because the decision is **settled**, FR-8 is withdrawn *now*: building a requirement whose
>   only subject is a file already slated for deletion would be waste, whichever work deletes it.
> - Because the execution is **adjacent**, this document must not claim credit for it, predict
>   its date, or describe it as done.
>
> **On disk today `packages/pypi/pyproject.toml` still exists and still reads `>=3.8`.** An
> earlier draft of this note said it "ceases to exist", which read as an accomplished fact and was
> false. It also means the `tech-debt.md` entry recording the untested floor (`M5`) is **still
> accurate today** and must not be closed until the deletion actually lands — at which point it
> closes as *Not Applicable*, its premise removed rather than its defect fixed.
The maintainer-only profile renderer remains on Python. It declares no floor of its own today,
and if it should, that is a separate maintainer-scoped change with no adopter-facing effect.

## 6. Non-Functional Requirements

### Delivery semantics

Treated as a conventional durable pub/sub problem — established solutions apply; no novel
mechanism required.

| Property | Requirement |
|---|---|
| Durability | Messages persist in the chat's log; survive subscriber disconnect and node restart |
| Delivery guarantee | **At-least-once**, with an idempotency key so a recipient can dedupe |
| Progress tracking | **Per-member position per chat**, with explicit acknowledgement — an unsubscribed interval delays delivery, it does not lose it |
| Ordering | FIFO **within a chat**: every member sees that chat's messages in the same order. **No** ordering guarantee *across* chats |
| Retention | A message is removed once it is **past its TTL *and* read by every live member** — never while an un-reaped member has still not read it. Plus a max **unread depth per member per chat** (the one bound defined in the limits table below), and **dead-session reaping** so a member that never reads cannot hold a chat's log from being trimmed indefinitely |

### Limits, retention, and policy

**Every parameter below is configurable.** The values are defaults, not constants — no
limit is hardcoded. All configuration is applied through the CLI (FR-7.2).

| Parameter | Default |
|---|---|
| Message TTL | **24 h** — the age at which a message becomes *eligible* for removal. It is removed only once every member has also read it; age alone never deletes an unread message |
| Max unread depth per member per chat | 1,000 messages |
| **Overflow policy** | **Reject the new send with an explicit error** (alternative: drop-oldest) |
| Max payload size | **None — messages are not size-limited** |
| Stale-session threshold | 30 min without heartbeat → marked stale in discovery. **Nothing is discarded** — the member keeps its place in every chat |
| **Reap threshold** | **24 h** without heartbeat → the node gives the member up for gone and **drops its claim on its chats**. What is released is its hold on the trim point, so messages it never read *do* then become removable — that is the point. Its **name is not destroyed**: re-registering it is accepted at any time |
| Long-poll timeout | **30 s**; the subscriber reconnects on timeout |

Overflow rejects rather than drops: a member that has fallen 1,000 messages behind is
broken, and the sender must learn that rather than have messages disappear silently.

**No message is destroyed unread by a member that is still there.** A chat's log is trimmed
only up to the point *every live* member has read, and a message is removed only when it is
**both** past its TTL **and** read by all of them. The TTL is an eligibility condition, not a
hard expiry — age alone never deletes a message a live member has not seen. This is
deliberate: a message that was sent, never delivered and never reported as undelivered is
exactly the failure the overflow policy above exists to prevent, and a hard expiry would
reintroduce it by another door.

**A reaped member stops counting.** Reaping is the one thing that can cause an unread message
to be removed, and that is its entire purpose: once a member is given up for gone, it is no
longer one of the members the trim point waits for, so a message only it never read becomes
removable. The guarantee is therefore bounded, not absolute — a message survives for as long
as some member that has not been reaped still has not read it.

**What bounds storage is therefore not time.** Two mechanisms carry it, and both are
required. The **unread-depth limit** stops a chat growing behind a member that has stopped
reading: once any member is 1,000 messages behind, further sends to that chat are rejected
with an explicit error. **Reaping** then clears the blockage: a member silent past the reap
threshold is given up for gone and its claim on the trim point is dropped, after which the
expired messages go. One consequence is accepted and stated plainly rather than left to be
discovered: a chat holding unread messages for a crashed session **keeps** them, and may stop
accepting new sends, until that session is reaped.

**Stale and reaped are two different states, and only the second releases anything.** Marking
a member **stale** (30 min without heartbeat) is a display state and changes nothing.
**Reaping** (24 h) is the node deciding a member is gone for good and releasing its claim, so
the trim point can move again — which does mean messages that member never read can now go.
Its **name survives**: re-registering it is accepted at any time, and the member simply starts
from the chat's current state.

The reap threshold and the message TTL share a 24 h default but are **separate settings**, so
message lifetime and dead-session patience can be tuned independently.

**There is no maximum payload size.** A message is never rejected or truncated for being
large. The consequence is that a chat's storage is bounded only by its message *count*, not
by its size on disk — the unread-depth limit caps how many messages may wait, not how many
bytes.

### Performance targets

**None for v1.** No latency, throughput, or wake-time target is set, and none is a
release condition. Speed is deliberately unconstrained until the design is proven.

## 7. Constraints

- The originating case is two sessions on **the same machine**; v1 additionally federates
  across a **trusted LAN**. The available hosting server is intentionally not part of the
  v1 topology.
- Sessions are launched by the operator's **own orchestrator**, not by a
  lead-spawns-teammates framework — the solution must not assume a shared codebase or a
  single lead.
- A session cannot be pushed to asynchronously; any design must respect the turn boundary.
- **A rendered skill is the agent-facing surface, and the reason is discoverability alone.**
  The `aid` CLI is on PATH globally and carries the whole message plane, so *capability* needs
  no second surface. What the CLI cannot do is **announce itself**: nothing advertises
  `aid chat` to a model, and a session that does not know the command exists will not guess it.
  A skill is exactly the artifact that fixes that, and this repository already renders one
  canonical skill into all five host dialects automatically.
  **This replaces an MCP façade, and the reversal is recorded rather than quietly dropped**,
  because the argument that was called decisive was wrong. That argument was that MCP "reaches
  a session not running AID at all", which a rendered skill cannot. It does not hold: AID must
  be present for a chat to exist at all, and the globally-installed CLI already reaches any
  session a skill could not. Set against that, MCP cost a third-party dependency, a
  per-host configuration snippet the **user** had to install by hand (the old FR-0.4), and a
  coverage claim established for only two of five named hosts — while the skill route covers
  all five by construction, costs no dependency, and needs no step from the user.
  **What this is deliberately *not* claimed on:** hosts that permit tool calls but forbid shell
  execution. Such a host would be reachable by MCP and not by a skill. All five named targets
  are terminal coding agents for which shell access is constitutive, so the category is
  believed empty here — but it is the one real thing given up, and it is named rather than
  argued away.
- **Host-agnostic (hard constraint).** Must work across Claude Code, Cursor, Antigravity,
  Copilot CLI, Codex, and future tools — no design may assume a single host's CLI or session
  model. This holds for the **pull** surface but **not** for waking an idle session.

## 8. Assumptions & Dependencies

**Cross-machine reach — resolved.** v1 assumes a flat, **trusted LAN**: peers find each other
(FR-6.1 — an outcome, no longer a named mechanism),
trust implicit in network membership, store-and-forward for offline peers. Because there is
no authentication anywhere in the product, the security boundary *is* the network — anything
that can reach the LAN can send, read, and register. NAT/firewall traversal and any
relay tier are out of scope for v1; the hosting server is held in reserve. Corporate
networks that block inbound peer connections would invalidate this and force the relay
tier forward.

**Wake heterogeneity persists independently of node locality.** Moving the service
on-machine removes the remote-trigger problem, but not the per-host wake problem: each
tool has its own (or no) headless entry point. A session running inside a **GUI IDE** may
have *no* external injection path at all — launching that tool's CLI creates a *new*
session rather than delivering into the one the user is watching.

**Inverted delivery (the chosen model).** Rather than an external process injecting a turn,
something **inside the tool** subscribes to the local node and the host's own machinery
turns an arriving message into a turn — same session, context preserved. Consequences:

- No external trigger, no remote-code-execution surface, no session-id capture, no
  `flock`, no risk of two processes mutating one working tree.
- The host requirement is *"can hold a wait open outside the model and surface an event to
  the agent"* — a materially lower bar than *"exposes a headless resume CLI"*.
- Only applies to a **live** session. A closed session is not woken.

**Host research — what is actually known.** The wake is the only unproven part of this
product; transport, storage, and sending are ordinary work.

**Read the sourcing column, not just the verdict.** Cursor, Copilot CLI and Antigravity were
checked against **published vendor documentation**, catalogued in the Knowledge Base's
external-source registry. **Claude Code was not** — its row rests on the capability
description exposed by the tool at runtime, which is first-hand but is not a citable
published document and is not in that registry. That asymmetry matters, because Claude Code
is the host whose mechanism is understood in the most detail — **not one that has been
demonstrated.** Nothing here is a proven wake; the table below rates confidence in the
*mechanism*, and its Claude Code row ends by deferring proof to the spike. If that row is
wrong, FR-5 has **no demonstrated instance** at all — the blocking-hook route on Cursor and
Copilot CLI would still be plausible, but every one of them would then be unproven together.
That is why P0 tests Claude Code first and Cursor second.

| Host | Wakes an idle agent? | Confidence |
|---|---|---|
| **Claude Code** | **Yes.** A long-lived monitor streams events into the session, including a WebSocket source that the server pushes to, and events arrive even while the session waits on the user | High on the mechanism, but **first-hand rather than cited** — taken from the tool's own runtime capability description, not from a published document, and therefore absent from the external-source registry. **Proof is deferred to the spike** |
| **Cursor** | **Not directly.** Its docs state plainly that no mechanism exists for a background process to initiate a turn. But its `stop` hook fires when the agent loop ends and can **inject the next user message**, so a hook that *blocks* until mail arrives is a viable waker | Medium — mechanism documented, blocking duration unmeasured |
| **Copilot CLI** | **Not directly.** Docs are explicit that no idle hook exists and no external process can inject into a session. Its `agentStop` hook can force a further turn, giving the same blocking-hook route as Cursor | High on the limit, unmeasured on the route |
| **Antigravity** | **Unknown.** Documentation is silent | Low |
| **Codex** | **Unknown — not researched.** The fifth profile AID renders into, and the one host nobody has looked at. Recorded so its absence is a stated gap rather than an oversight | None |

Two further findings bound the design. First, **MCP could never have been the waker**:
server-initiated messages (sampling, elicitation) are unsupported in Copilot CLI and
unimplemented in Cursor, so it could only ever have been a pull surface. This finding is
retained even though the façade is now out of scope (§4), and it earns its place twice over:
it is the constraint that would bind any future reconsideration of MCP, and it is evidence
that the façade was never load-bearing for the one hard part of this product. Second, the pull
floor is not a nicety — on any host whose blocking-hook route fails, it is the only mechanism
left.

**Assumption requiring validation (P0).** That a host can hold a token-free wait and turn
an arriving message into a turn **while the session is otherwise idle**. **Unproven on both
proving hosts** — for Claude Code the mechanism is understood first-hand but never
demonstrated end to end, and for Cursor the route is documented but its blocking limit is
unmeasured. That is why P0 tests Claude Code first (test 1) and Cursor second. The single
number that decides the design is **how long a Cursor `stop` hook may block before the host
kills it.**

**Toolchain — Node, with no third-party runtime dependency.** Replaced on 2026-08-10; the
previous entry read "Python 3.12, `mcp`/FastMCP for the MCP façade, `zeroconf` for mDNS."

| Concern | Choice | Third-party dependency |
|---|---|---|
| Runtime | Node | — |
| Durable store | the **built-in SQLite module**, `node:sqlite` | **none** |
| HTTP transport | the built-in HTTP server | **none** |
| Long-poll timeout / abort | the runtime's own cancellation primitive plus the request-closed event | **none** |
| LAN discovery | the built-in UDP socket module, plus a static peer list (FR-6.1) | **none** |
| Agent-facing surface | a rendered chat skill invoking the CLI (§4, FR-0.4) | **none** |

**The count is zero, and that is what inverted FR-7.6.** The previous toolchain needed two
libraries and the node was separated *because of them*; both are gone, so the node ships inside
the `aid` payload instead. AID's decision D10 — zero runtime dependencies, enforced by empty
dependency sets in both shipped manifests — is preserved **literally**, with no carve-out for an
opt-in component.

**The store contract was verified by execution, not by reading documentation.** Every clause
`/aid-specify` needs was run against the built-in module on **Node v24.19.0** and **v26.7.0**:
write-ahead logging engages and persists across reopen; full-synchronous durability sticks; a
partial unique index rejects a duplicate idempotency key while permitting many null ones;
cascading delete fires; a reader held a transaction open for three seconds while a writer
committed forty-nine sends with a slowest commit of three milliseconds; and a hard kill
mid-transaction left the committed rows intact, discarded the uncommitted one, and passed an
integrity check. **Two findings from that exercise are inputs to `/aid-specify`, not trivia:**
the default busy timeout is **zero**, so a non-zero value is *required* rather than advisable —
without it a second writer fails instantly instead of waiting — and there is **no
transaction-wrapper helper**, so the wrapper is hand-written.

**One dependency remains available and unused, and the reason is recorded.** The store is
`node:sqlite` at release-candidate stability rather than a pinned third-party binding. That
means it cannot be pinned or patched independently of the runtime, and the SQLite version it
carries follows whatever Node the user runs. The mitigation is a **seam, not a second
implementation**: all storage access sits behind one module, so substituting a pinned binding
later is a migration rather than a rewrite. **Building both was considered and rejected** — it
would double the test matrix permanently to insure against a failure that has not occurred, in
a product with no performance target. What is built instead is a startup assertion on the
runtime's reported SQLite version and the engine's own reported version, failing with an
actionable message rather than a stack trace.

**Closed by deletion: where `aid chat deploy` obtains the node.** This was recorded here as a
deliberate deferral to `/aid-specify`, turning on the offline air-gapped channel that has no
package index to reach. **The question no longer has a subject.** The node ships inside the
`aid` payload (FR-7.6), so there is nothing to fetch on any channel, air-gapped included, and
`deploy` itself is gone. It is recorded as closed rather than removed, so that the deferral is
seen to have been resolved rather than forgotten.

**Two floors, not one, and the number is `/aid-specify`'s to fix.** The components every adopter
runs and the opt-in node have different needs and need not agree. The research is explicit that
this argues for a **low** floor rather than a fashionable one. **Not one of the five named host
tools is established to require a recent system runtime**, and the evidence is stated per host
rather than as a count, because a count is what would be wrong here:

| Host | What was verified | Bearing on the floor |
|---|---|---|
| Claude Code | Its own documentation states the package downloads a native binary that does not use the system runtime, which is absent from its stated requirements | Says nothing about the user's PATH |
| Copilot CLI | Declares **no** engine minimum at all | Says nothing |
| Codex | **Lowered** its declared minimum to a version far below this repository's | Says nothing, and trends the wrong way |
| Cursor | Installs by script rather than through npm | Says nothing |
| Antigravity | **Not verified.** Its minimum was not opened against vendor documentation and must not be assumed | Unknown, and recorded as unknown |

The one tool the research did confirm as a genuine system-runtime consumer is **not one of the
five** this product targets, so it carries no weight here. Add that at least one current
long-term-support Linux distribution ships a runtime below the newest release line, and the
conclusion follows: a floor the system package manager cannot satisfy pushes users onto a
version manager, which is an adoption cost paid for nothing unless a capability actually
requires it. **The audience's runtime is present because npm was the install path, not because
any host tool guarantees a version.**

## 9. Acceptance Criteria

| # | Criterion |
|---|---|
| AC-1 | **The wake works, across tools.** A Cursor session and a Claude Code session **on the same machine**, in different repositories, share a chat and exchange a message, and the recipient **acts on it without any human action**. This is the stage-P2 form: it proves the wake and the cross-tool adapter contract without depending on federation |
| AC-1b | **The target case, end to end.** The same exchange with the two sessions on **different machines on the same network**. Identical to AC-1 except for the network hop, and deliberately separate because federation does not exist until stage P3 — AC-1 cannot pass at P2 while requiring a second machine |
| AC-2 | A member whose session restarts mid-flight receives its undelivered messages on reattaching to the same name, in every chat it belongs to, resuming each chat's own position |
| AC-3 | **Two machines on the LAN discover each other**, complete the handshake, and deliver a message across. Stated as an outcome: the criterion is silent on *how* they discover each other, because FR-6.1 is. It must be satisfiable by the guaranteed path alone — a criterion that can only pass when a particular network feature happens to work is a criterion that fails for reasons the product does not control |
| AC-4 | A message sent to a chat whose **home machine is offline** is delivered once that machine returns |
| AC-5 | With **no subscriber armed**, the message is still readable via `inbox()` at the session's next turn |
| AC-5b | **A two-member chat is a direct message.** Two sessions exchange private messages through an ordinary chat, using no mention and no whisper |
| AC-6 | A duplicate delivery is deduped by idempotency key; a reply correlates to its originating request |
| AC-7 | **The CLI stands the node up on a clean machine with no installation step**, and running the command again is safe. "Clean machine" now means only that `aid` is installed and the node has never run — there is nothing to fetch, resolve or verify, so the criterion no longer has an install path to exercise. Its remaining substance is that a first run works from nothing but the shipped payload, and that a second run does not fail. The precise form of the second half is the sub-decision named under FR-1.1 |
| AC-9 | **Node restart:** unacknowledged messages and every member's position survive a restart of the node itself — not merely of a session |
| AC-10 | **Retention holds, and nothing is lost to a live member.** A message past its TTL that every live member has read is removed; a message past its TTL that an un-reaped member has **not** read is **kept**. The max-unread-depth bound is enforced. A member silent past the **reap threshold** has its claim dropped and stops counting toward the trim point, after which that chat's log can be trimmed past where it had reached — **including messages that member never read**, which is the whole purpose of reaping |
| AC-11 | **Re-arm window:** messages arriving while the subscriber is between arms are all delivered, in order, on the next arm |
| AC-12 | **Chat delivery:** a message sent to a chat reaches every member of that chat, whether it has two members or many |
| AC-13 | **Operator visibility:** the CLI shows machines and sessions, this machine's chats and their members, per-member unread depth, and the audit log |
| AC-15 | **Surface boundary holds:** the agent-facing surface — the rendered chat skill — describes no operation that stops the node, changes configuration, creates or deletes a chat, or changes another session's chat membership, and *does* describe a session joining and leaving chats itself; joining a non-existent chat fails explicitly. **The verification changes shape with the surface, and honestly:** this is now a check on what the skill *offers*, not a check that an agent is *prevented*. FR-7.3 already said the boundary was never a sandbox, and with the surface being documentation rather than a protocol, that is plain instead of a caveat |
| AC-16 | **Only a major-version difference errors:** two nodes differing by minor or patch version interoperate normally; a major-version difference fails the handshake with a clear error — never silently half-work |
| AC-17 | **Whisper is private:** in a chat of three or more, a whispered message reaches only its target. Every other member sees it neither on delivery nor in history |
| AC-18 | **Mention is visible:** a mentioned message reaches every member, and the mentioned member can tell it was aimed at them |
| AC-19 | **Local-only resolution:** a chat name given without a machine address resolves on this machine only. When no such chat exists here the result is **not found** — even with a chat of that name on another machine on the network |
| ~~AC-20~~ | **Withdrawn 2026-08-10 with FR-8.** Verified the Python floor move. Its subject is going: no shipped artifact will declare a Python floor once the adopter-facing runtime is Node and the PyPI channel is dropped. Retained as a struck row, not renumbered, so references resolve |
| AC-21 | **The spike answers, and the answers are written down.** All four P0 questions have recorded outcomes: whether an idle Claude Code session acts on a message with no human action; whether an idle Cursor session does; **the measured limit on how long a Cursor `stop` hook may block before the host kills it**, as a number; and whether the exchange holds across two machines on the LAN. A "we could not determine it" is a valid answer only when it records what was tried. No P0 code survives into P1 |
| AC-22 | **Chat lifecycle is the operator's, and it works.** The operator creates a chat and deletes one through the CLI; a created chat is joinable and a deleted one is not. Nothing else in §9 exercised chat creation, though every other criterion depends on a chat existing |
| AC-23 | **A missing runtime fails clearly, and only for the component that needs it.** On a machine with `aid` installed and no usable Node present, starting the node fails with an explicit message naming Node as the prerequisite — not a stack trace — and every `aid` command that needs no runtime continues to work. **Restated, not withdrawn:** the criterion previously named Python and the `deploy` verb; the prerequisite is now Node and the verb is `start`, but the property being tested is unchanged and still worth testing, because the CLI itself remains runtime-free and that promise is exactly what this criterion protects |
| ~~AC-24~~ | **Withdrawn 2026-08-10 with FR-8.5.** Required a CI check failing when the declared Python floor and the tested version disagreed. No declared Python floor survives for it to guard |
| ~~AC-25~~ | **Withdrawn 2026-08-10 with FR-8.7.** Required the Knowledge Base to state the new Python floor. Nothing about a Python floor changes, so the Knowledge Base has nothing to move. The KB *does* change when this work ships — the dashboard's runtime, the publication channels, and decision D10's evidence — but that is ordinary ship-time KB work, not a criterion of this requirement set |

> **Every criterion above is settled; none is pending.** Most are stakeholder-ratified
> outright; the **six** whose current wording came from `/aid-define` are listed below with what
> that means for each. **The count was nine until 2026-08-10**, when the runtime decision
> withdrew AC-20, AC-24 and AC-25 — all three of them pipeline-authored, which is worth noticing:
> the criteria the pipeline added on its own initiative were exactly the ones a change of
> mechanism made moot. Nine others came from
> a quality check in the originating interview and arrived here unratified. They were
> reviewed one at a time and resolved: two were **deleted** — the negative-auth criterion,
> because all authentication was removed, and the oversized-payload criterion, because the
> size limit was removed; two were **rewritten** — chat delivery, and version mismatch, now
> bound to semantic versioning; the remainder were ratified as written. Nothing in this table
> is carried, assumed, or open.
>
> **Six criteria carry wording written after the interview, by `/aid-define` rather than by
> the stakeholder** — whether newly created or re-worded. All are named here so the
> distinction stays visible.
>
> **Three from decomposition:** AC-1b (new — AC-1 could not pass at its assigned stage, so it
> was split and the two-machine half became its own criterion), AC-21 (new — stage P0 had no
> acceptance criterion at all), and **AC-1 itself** (re-worded by that same split: the
> "on the same machine" qualifier and the stage-P2 explanation are both pipeline text).
>
> **Three from the cross-reference pass:** AC-22 (new — chat lifecycle was verified by nothing),
> AC-23 (new — from the stakeholder's runtime-prerequisite decision, and **restated on
> 2026-08-10** from Python to Node, which changed the named runtime and the verb but not the
> property), and the rewrite of **AC-10**, which now turns on the live-member bound and the reap
> threshold — neither of which existed at interview close, though both follow from decisions the
> stakeholder took (Q17, Q19).
>
> **Withdrawn from this list on 2026-08-10:** AC-24 and AC-25 (both new from the cross-reference
> pass) and the re-scoping of **AC-20**. All three served FR-8, which no longer exists.
>
> **Two of the six verify a requirement that the same pipeline pass also wrote**, and are
> flagged rather than buried:
>
> - **AC-23** verifies FR-7.7 (a runtime as the node's prerequisite) — but that requirement came
>   straight from a stakeholder decision, so only the wording is the pipeline's.
> - **AC-10** verifies FR-2.3's reaping clause and the reap threshold — again authored to
>   carry stakeholder decisions (Q17, Q19), so again only the wording.
>
> **The item flagged here as "most worth a second look" got one, and did not survive it.** That
> was AC-25, the criterion no stakeholder decision had asked for. It is now withdrawn — not
> because the second look judged it wrong, but because the requirement it verified was deleted
> from under it. The flag did its job either way: the criterion that was hardest to trace to a
> stakeholder decision was also the first to become moot when the design changed.
>
> The remaining four make an already-ratified requirement testable without adding scope. The
> rule throughout: **the stakeholder ratified the requirements these verify, not these
> wordings** — and where a requirement's own text was extended to make a criterion possible,
> that is said here rather than left to be discovered.

## 10. Priority

Ordered **risk-first**: the stage that could invalidate the architecture runs before anything
is built on top of it. From P1 onward each stage leaves something usable behind; **P0 is the
exception and is meant to be** — it produces answers, not product.

| Stage | Scope | Verifies |
|---|---|---|
| **P0 — POC** | Four tests against a throwaway stub node (one endpoint that waits, then returns a message), on **Claude Code and Cursor only**: (1) idle Claude Code session acts on a message with no human action; (2) idle Cursor session does the same via a blocking `stop` hook; (3) **how long a Cursor `stop` hook may block before the host kills it**; (4) the same exchange across two machines on the LAN | AC-21 — the single unvalidated assumption |
| ~~**P0b — Toolchain**~~ | **Withdrawn 2026-08-10 with FR-8.** Raised the repository's Python floor to 3.12. Removed rather than reordered: with the adopter-facing runtime moving to Node and the PyPI channel slated to be dropped, the declaration this stage moved is slated to go with it (premise, not deliverable — see the FR-8 withdrawal note; the file is still on disk today). Retained as a struck row so the stage sequence reads continuously | — |
| **P1 — Skeleton** | Node lifecycle + CLI + registration by stable name + chat create/delete/**join/leave**, **including the operator changing another session's membership** (FR-7.2, FR-3.4 — CLI-only, and the counterpart to AC-15's prohibition) + the local half of listing (FR-3.1) + durable `send`/`inbox`/`ack` with fan-out to every member, **pull only** (FR-5.3 — the pull floor ships here, not at P2). **Lifecycle is smaller than it was:** with the node shipping in the `aid` payload (FR-7.6) there is no install step to build | AC-2, AC-5, AC-5b, AC-6, AC-7, AC-9, AC-12, AC-22, AC-23 |
| **P2 — The wake** | Subscriber and re-arm (FR-5.1, FR-5.2, FR-5.4, FR-5.5 — FR-5.3's pull floor already shipped at P1), and the **rendered chat skill** (FR-0.2, FR-0.4 — FR-0.1 already shipped at P1), which replaces the withdrawn MCP façade. **FR-0.3 completes here, not at P1:** P1 delivered its administration and message-plane halves, but FR-0.3 also requires the CLI to carry the subscriber, which does not exist until this stage | **AC-1 (headline — same machine, cross-tool)**, AC-11, AC-15 |
| **P3 — Federation** | Discovery, handshake, store-and-forward, version negotiation (FR-6), machine-qualified chat ids and local-only resolution (FR-3.2), the network half of listing (FR-3.1). **Discovery is layered, and the layering has a sequencing consequence stated rather than discovered:** the guaranteed path (a static peer list plus heartbeat) satisfies AC-3 but *not* the zero-configuration expectation in §4; the best-effort layer above it is what does. Shipping only the floor leaves this stage's user-facing promise unmet even with its criterion green | **AC-1b (the target case)**, AC-3, AC-4, AC-16, AC-19 |
| **P4 — Completeness** | Mention and whisper, audit/operator visibility, retention enforcement. Chats of more than two need nothing new here — fan-out to every member is P1 (AC-12); what P4 adds is **addressing within** a larger chat | AC-10, AC-13, AC-17, AC-18 |

**Every stage is required. None is optional.** The stages are a delivery *order*, not a
priority scale — each is reached in turn, and from P1 onward each leaves working product
behind (P0 excepted, above). Every criterion
in §9 is a ratified release condition, including the four that land last (AC-10, AC-13,
AC-17, AC-18), and §4 In Scope names mention and whisper explicitly. A late stage is late,
not optional; nothing here may be dropped at planning time without reopening §9.

**The stage sequence is now P0 → P1 → P2 → P3 → P4, with no parallel stage.** P0b was the only
one, and its removal takes with it the only breaking change this work was going to ship to
existing users and the only deliverable whose value was independent of whether the wake
mechanism works at all. Everything remaining is on the critical path, and everything remaining
depends on P0's answer.

**This requirement set now ships no breaking change of its own**, and the distinction matters
enough to state rather than leave implied. P0b was the only stage that did.

The runtime decision that removed P0b **does** carry breaking changes — dropping the PyPI
publication channel, and which implementation of the dashboard is the shipped one — but **those
are not in this document's scope and are not verified by any criterion here.** This is the
Agent Chat Channel; §4 In Scope names the chat, the node, federation, delivery and the chat
skill, and it names no publication channel and no dashboard work. They are adjacent changes that
share a cause with this reset, released and announced on their own terms.

Stating it this way is deliberate, because the alternative was the error this note replaces: an
earlier draft asserted that "retiring the dashboard's Python implementation" ships as part of
this work, which nothing in §4, §5 or §9 supports. The reason P0b was kept separate applies to
those changes too — a breaking change buried inside a feature is how breaking changes ship by
accident — but the way to honour that here is to disclaim them, not to adopt them.

**Rationale.** P0 is near-free — a stub endpoint that waits, then answers — and is the only
stage capable of invalidating the architecture. If a host cannot hold a token-free wait and
turn an arriving message into a turn, the wake degrades to pull-only on that host. That
answer is needed before P1, not after P3.

**P0 expectations, stated so they are not mistaken later.**

| P0 is | P0 is not |
|---|---|
| Disposable. Every line is thrown away | The first slice of the node |
| Answering four questions, one of them a measured number | Producing anything shippable |
| Two hosts — Claude Code and Cursor | All five hosts |
| Done when the four answers exist | Done when something works nicely |

**Its only deliverable is the answers**, including the measured Cursor `stop`-hook blocking
limit. No P0 code is carried into P1.

**The other three hosts are named targets, not gates.** Copilot CLI, Antigravity and Codex
are expected to reuse the same adapter contract (FR-5.2), and none of them gates v1. Codex
is the weakest-known of the three — the fifth profile AID renders into, and the only host
whose harness has not been researched at all. That is stated rather than left silent, since
an unexamined host reads as an oversight otherwise.

**Why these two hosts.** Claude Code and Cursor are the v1 proving pair. The target case is
a developer in Cursor on one machine exchanging messages with a developer in Claude Code on
another machine on the same network — **every other case is a subset of it**: same machine,
same tool, or one-way. Copilot CLI, Antigravity and Codex remain named targets in §3 and are
expected to reuse the same adapter contract (FR-5.2), but none of the three gates v1.

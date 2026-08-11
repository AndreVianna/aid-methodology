# Chat Skill

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-0.2, FR-0.4, FR-7.3, §9 AC-15, §10 stage P2 | /aid-define |
| 2026-08-09 | Criterion added for AC-15's untested clause — joining a non-existent chat over MCP fails explicitly and creates nothing | /aid-define (cross-reference) |
| 2026-08-09 | "The one protocol every target tool already speaks" retracted — the sentence contradicted this feature's own CLI-fallback paragraph twelve lines below it | /aid-define (cross-reference) |
| 2026-08-09 | Rationale restructured to lead with the two reasons that hold — a tool call is the natural shape inside a turn, and MCP reaches a session not running AID at all — with coverage stated at the strength the source registry supports (confirmed for two of five hosts, three catalogued) rather than as an absolute in either direction; the Source parenthetical citing §7 for a claim §7 does not make was replaced | /aid-define (cross-reference) |
| 2026-08-09 | Criterion added for FR-0.4's "automates nothing" clause — a standing repository rule that no criterion verified: no host tool's MCP configuration is written or modified | /aid-define (cross-reference) |
| 2026-08-10 | **Feature replaced: MCP Message Facade → Chat Skill.** The slot, the stage (P2) and the requirement mapping are kept; the mechanism is not. **The reason is that this feature's own load-bearing claim was false.** Its Description said MCP "reaches a session that is **not running AID at all**, which a rendered skill cannot" — the argument §7 called decisive. The stakeholder identified that AID must be present for a chat to exist at all, and the `aid` CLI is installed globally on PATH, so the CLI already reaches every session a rendered skill could not. With that reason gone, what remained was **discoverability**, and this feature's own honesty about MCP's costs then decided against it: coverage "confirmed for two of five hosts", a third-party dependency, and a per-host snippet **the user** had to install by hand. A rendered skill covers all five host dialects through machinery the repository already has, carries no dependency, and asks nothing of the user. **Four criteria survive verbatim in substance** (own-membership only, no administrative operation, no logic of its own, and the plainly-stated boundary limits); **three are deleted with the protocol** (the registration snippet, the unregistered-host fallback, and the never-write-the-host-config rule — the last because a skill has no host configuration to leave alone, so the rule it verified is satisfied by construction rather than by test); **two are restated** onto the skill surface | /aid-specify (stakeholder) |

## Source

- REQUIREMENTS.md §5 FR-0.2, FR-0.4, FR-7.3, FR-7.4, §4 In Scope (the rendered chat skill) and
  §4 Out of Scope (the withdrawn MCP façade), §7 Constraints (the agent-facing-surface bullet —
  discoverability as the sole reason, and what is deliberately given up), §9 AC-15, §10 stage P2

## Description

The thing that tells a session the chat exists.

**The CLI is not the problem; being found is.** `aid chat` is on PATH globally and carries the
whole message plane, so a session that knows the command can already do everything. Nothing,
however, advertises that command to a model — and a session that does not know it exists will
not guess it. A skill is precisely the artifact that closes that gap, and this repository
already renders one canonical skill into all five host dialects automatically.

So this feature ships **documentation the model can find**, not a second surface. It carries no
logic and holds no state: every operation it describes is an `aid chat` invocation (FR-7.4).
Through it a session can send, read, acknowledge, and manage **its own** chat membership. That
is the entire described surface. Creating or deleting a chat, changing somebody else's
membership, altering configuration, stopping the node — none of it is described here.

**This is a surface boundary, not a cage, and the change of mechanism makes that plainer rather
than weaker.** The full administrative surface lives in the same `aid` CLI, and any session
whose host lets it run shell commands can invoke it directly. When the surface was a protocol,
that honesty read as a caveat about a boundary that looked enforced. Now the boundary simply
*is* a document that omits things, and the limit is visible in its nature rather than needing a
disclaimer. Real containment would need a per-session credential, and this product has no
authentication at all. Claiming otherwise would assert a safety property that does not exist.

**Nothing is asked of the user, and that is a change.** The retired façade required a
copy-pasteable configuration snippet per host, installed by hand — the product published it and
automated nothing, under this repository's standing rule that it manages no host tool's
configuration. A rendered skill needs none of that: it arrives with AID through the same
pipeline as every other skill. The standing rule is now satisfied **by construction** — there is
no host configuration for this feature to leave alone.

**What is given up, stated rather than argued away.** A host that permits tool calls but forbids
shell execution would have been reachable by MCP and is not reachable by a skill. All five named
targets are terminal coding agents for which shell access is constitutive, so the category is
believed empty here — but it is the one real loss, and it is named.

## User Stories

- As a session, I want to discover that the chat exists without being told by a human, so that
  I use it at all.
- As a session, I want to send and read messages as part of my work, so that messaging is not a
  detour I have to invent.
- As a session, I want to join and leave chats myself, so that I am not waiting on a human for
  something about only me.
- As the operator, I want the agent-facing surface to describe no administrative operation, so
  that the ordinary path does not invite reconfiguring my fleet.
- As the operator, I want the boundary's real limits stated plainly, so that I do not mistake a
  design contract for a sandbox.
- As a user, I want the chat to work on my tool with **no setup step of my own**, so that
  installing AID is the whole of it.

## Priority

Must

## Acceptance Criteria

- [ ] Given a session following the chat skill, when it sends, reads, acknowledges, joins and
      leaves, then all succeed.
- [ ] Given a session following the chat skill, when it tries to join a chat that does not
      exist, then the attempt **fails explicitly** and no chat is created — the surface that
      lets a session manage its own membership does not let it create one by implication.
- [ ] Given the chat skill, when it is read, then it **describes no operation** that stops the
      node, changes configuration, creates or deletes a chat, or changes another session's
      membership. This is a check on what the surface *offers*, and is deliberately not phrased
      as "the attempt is unavailable" — the operations remain reachable through the same CLI, as
      FR-7.3 states outright.
- [ ] Given an operation performed by following the skill and the same operation invoked
      directly on the CLI, when both complete, then they produce the same result against the
      same store — because the skill's instructions *are* CLI invocations.
- [ ] Given the chat skill, when it is inspected, then it holds no state and no logic of its
      own, and reimplements no node behaviour (FR-7.4).
- [ ] Given the five supported host dialects, when AID is installed, then the chat skill is
      present in each **with no action by the user** — it renders through the same pipeline as
      every other canonical skill, and no host tool's configuration is written or modified.
- [ ] Given a host where the skill is absent or unread, when a session uses the CLI directly,
      then the full message plane is available — a missing skill costs discoverability, never
      capability (FR-0.3).
- [ ] Given the documentation, when the privilege boundary is described, then it states plainly
      that a session with shell access can reach the administrative surface.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

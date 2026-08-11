# Host Waker Adapters

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-5.2, FR-5.4, FR-5.5, §3 (proving pair), §8 (host research), §9 AC-1, §10 stage P2 | /aid-define |
| 2026-08-09 | Off-schema `Depends on:` block removed; sequencing moved into Description prose | /aid-define (cross-reference) |
| 2026-08-09 | Claude Code's mechanism restated as first-hand rather than documented, matching the corrected §8; host count corrected from four to five | /aid-define (cross-reference) |
| 2026-08-09 | FR-5.4 split by clause with `feature-006` — this feature owns the host-side hand-over at the turn boundary, `feature-006` the node-side accumulation | /aid-define (cross-reference) |
| 2026-08-09 | "The only host rated as a proven wake" retracted — no host is proven, which is the spike's entire premise; Claude Code is simply the one whose mechanism is understood in most detail | /aid-define (cross-reference) |

## Source

- REQUIREMENTS.md §5 FR-5.2, FR-5.4 (the host-side clause — handing accumulated messages over at the next turn boundary; the node-side accumulation that makes them available belongs to `feature-006`), FR-5.5, §3 Users (v1 proving pair, the target case), §8 Assumptions (host research), §9 AC-1, §10 stage P2

## Description

The piece that turns an arriving message into a turn — the only part of this product that
differs per tool, and the only part nobody has built before.

**This feature cannot be specified before the spike answers.** Its Cursor half is shaped by
a number the spike measures: how long a `stop` hook may block before the host kills it. That
sequencing is carried by the stage order (P0 before P2) and belongs in the delivery plan;
it is stated here so the dependency is visible to anyone reading this feature alone.

Everything underneath is identical everywhere: the node, the chats, the wire. What differs
is how each tool can be made to notice something. That difference is confined to one small
adapter per tool, behind a single contract: **wait without spending anything, and when a
message arrives, produce a turn.**

The waiting must be free. A shell process sitting on a connection costs nothing; a model
asked to check repeatedly costs money forever. Any adapter that keeps the model in a loop
fails the contract regardless of whether it works.

Two adapters ship. **Claude Code** can hold a long-lived subscription that streams events
into a session, including while it waits on the user. That mechanism is **first-hand, not
cited** — taken from the tool's own runtime capability description rather than from any
published document, so it is absent from the source registry and its **proof is deferred to
the spike** (§8). No host is a proven wake; this is simply the one whose mechanism is
understood in the most detail, which is exactly why
the spike tests it first. **Cursor** cannot be pushed to at all; its only way in is a hook that fires when a
turn ends and can submit the next message. Making that a waker means letting the hook block
until mail arrives, which is why the spike's measured number decides the shape here.

Two paths must both work. **Idle** — a turn is produced on arrival. **Busy** — messages
accumulate and are handed over at the next turn boundary. Neither loses anything; the busy
path only delays.

A host with no viable adapter is not a failure. It falls back to reading its own mail, which
works everywhere. Five hosts are named (§3) and only two get an adapter here; the contract is
what lets the remaining three — and any tool named later — be added without touching anything
else.

## User Stories

- As a developer in Claude Code, I want a message from a colleague's session to reach me
  while I am idle, so that I do not have to check.
- As a developer in Cursor, I want the same, so that the tool I use does not decide whether
  I can be reached.
- As a developer mid-task, I want messages that arrived while I was working handed to me
  when I finish, so that being busy delays them rather than losing them.
- As the operator, I want an idle session to cost nothing while it waits, so that leaving
  sessions open all day is free.
- As a maintainer, I want a new tool to need only a new adapter, so that support does not
  mean redesign.

## Priority

Must

## Acceptance Criteria

- [ ] Given an idle Claude Code session in one repository and an idle Cursor session in
      another **on the same machine**, when one sends a message to their shared chat, then
      the recipient acts on it with no human action.
- [ ] Given an idle session with an adapter armed, when a message arrives, then a turn
      begins without human input.
- [ ] Given a session mid-turn, when a message arrives, then it is delivered at that
      session's next turn boundary.
- [ ] Given several messages arriving while a session is busy, when its turn ends, then all
      are delivered, in order.
- [ ] Given an armed adapter and no traffic, when it waits for an extended period, then no
      model tokens are consumed.
- [ ] Given a host with no adapter, when a message arrives, then the session can still read
      it at its next turn — degraded, not broken.
- [ ] Given both shipped adapters, when their implementations are compared, then they share
      the same node, store and wire protocol, differing only in the adapter.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

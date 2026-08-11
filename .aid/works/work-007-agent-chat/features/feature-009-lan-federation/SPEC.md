# LAN Federation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-3.1 (network half), FR-3.2, FR-3.3, FR-6, §4 Scope, §9 AC-1b, AC-3, AC-4, AC-16, AC-19, §10 stage P3 | /aid-define |
| 2026-08-09 | Cross-machine name uniqueness (FR-2.2) tested here, where two nodes can first see each other; `feature-004` keeps the single-machine half at P1 | /aid-define (cross-reference) |
| 2026-08-09 | That criterion reworded off "addressed" — names were retired as addresses by FR-2.1, and the phrasing reintroduced the retired model | /aid-define (cross-reference) |

## Source

- REQUIREMENTS.md §5 FR-2.2 (the cross-machine half of name uniqueness — the single-machine half is `feature-004` at stage P1), FR-3.1 (network half), FR-3.2, FR-3.3, FR-6.1–6.4, §4 Scope, §8 Assumptions (cross-machine reach), §9 AC-1b, AC-3, AC-4, AC-16, AC-19, §10 stage P3

## Description

Machines finding each other, and messages crossing between them. This is the stage that
delivers the target case.

Nodes announce themselves on the local network and discover their neighbours. There is
**no password, key, or login anywhere** — being reachable on the network is the entire
condition for taking part. That is a deliberate choice, and its consequence is stated
plainly: the network *is* the security boundary, so it has to be one you trust.

Every chat has a **home machine**, and its full name is machine plus chat name. Leave the
machine off and the lookup is local only: if there is no such chat here, the answer is *not
found* — even when a chat by that name exists next door. **No silent hop to another
machine.** Guessing on the user's behalf is how you send a message to the wrong room.

When a chat's home machine is off, the sending node holds the message and delivers it when
that machine returns. Being offline delays; it does not lose.

Machines will run different versions, because each is updated whenever its owner updates it.
Patch and minor differences work together by contract. Only a **major** difference — which
by definition means something breaking changed — refuses the connection, and it refuses
loudly. The failure mode this prevents is the quiet one: two nodes that appear to work while
silently dropping a field, so that duplicate detection or reply matching stops working and
nothing reports an error.

## User Stories

- As a developer in Cursor on my laptop, I want to exchange messages with a colleague's
  Claude Code session on another machine, so that the whole point of the product works.
- As the operator, I want machines to find each other without configuration, so that adding
  a machine is not a setup task.
- As a session, I want a bare chat name to mean *here*, so that I never reach a same-named
  room on another machine by accident.
- As a sender, I want messages to a machine that is currently off to be delivered when it
  returns, so that I do not have to resend.
- As the operator, I want two mismatched nodes to refuse each other clearly, so that I never
  debug a half-working connection.

## Priority

Must

## Acceptance Criteria

- [ ] Given a Cursor session on one machine and a Claude Code session on another on the same
      network, when one sends to their shared chat, then the recipient **acts on it with no
      human action** — the target case.
- [ ] Given two machines on the same network, when both nodes are running, then each
      discovers the other without configuration.
- [ ] Given two discovered nodes, when they connect, then no key, password or login is
      required of either.
- [ ] Given the same short session name registered on both machines, when the two nodes have
      discovered each other and each session's full identity is read, then both registrations
      are valid and can be told apart by machine — names are unique per machine, not globally, and
      this is the stage where that first becomes observable. (A name is still never a
      destination; nothing here sends *to* one.)
- [ ] Given a chat whose home machine is off, when a message is sent to it, then it is
      delivered once that machine returns.
- [ ] Given a chat name with no machine and no such chat on this machine, when it is
      resolved, then the result is **not found** — even with a chat of that name elsewhere
      on the network.
- [ ] Given two nodes differing only by patch or minor version, when they connect, then they
      interoperate normally.
- [ ] Given two nodes differing by major version, when they connect, then the handshake fails
      with an explicit error and no partial connection is established.
- [ ] Given a machine on the network, when a session lists its chats, then it sees the chats
      that machine hosts and their members.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

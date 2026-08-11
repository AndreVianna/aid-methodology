# Durable Chat Messaging

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-3.1 (local half), FR-3.4, FR-4, FR-5.3, §6 (delivery semantics), §9 AC-5, AC-5b, AC-6, AC-9, §10 stage P1 | /aid-define |
| 2026-08-09 | Chat lifecycle claimed and tested here — FR-7.2's chat-lifecycle clause and the new AC-22 added to Source; AC-12 (plain fan-out) moved in from `feature-010` and stage P4 to stage P1, where it is actually built | /aid-define (cross-reference) |
| 2026-08-09 | Two untested clauses of claimed requirements given criteria: reply correlation (AC-6's second half, FR-4.6) and leaving a chat (FR-3.4); §10's P1 scope updated to name leave and the pull floor | /aid-define (cross-reference) |
| 2026-08-09 | The no-loss guarantee bounded to the pre-reap window, matching §6 and `feature-011` — this was the one place the correction had not reached | /aid-define (cross-reference) |
| 2026-08-09 | Criteria added for the operator placing and removing **another** session's chat membership — granted by FR-3.4 and FR-7.2, assumed by a user story here, and tested nowhere; FR-4.1/FR-4.3 qualified in Source against `feature-010`'s directedness clauses | /aid-define (cross-reference) |
| 2026-08-09 | FR-7.2's other-session-membership clause claimed here explicitly — it had been owned by no feature at all, though the criteria above test it; §10's P1 scope now names the capability | /aid-define (cross-reference) |
| 2026-08-09 | §6 Delivery semantics narrowed in Source to the four rows this feature owns — the Retention row belongs to `feature-011` | /aid-define (cross-reference) |
| 2026-08-10 | **Runtime reset sweep — one edit.** The Source line's carve-out to `feature-003` read "the deploy/start/stop/status/configuration clauses"; `deploy` is deleted, since the node now ships inside the `aid` payload and has no install step to administer (FR-7.6). The clause list is otherwise unchanged. **Nothing else in this feature moves, and that is the substantive finding rather than the edit:** the store schema this feature owns — the per-chat monotonic sequence, the partial unique index enforcing idempotency dedupe, and `ON DELETE CASCADE` — was verified by execution to work verbatim on `node:sqlite` (Node v24.19.0 and v26.7.0), so the change of runtime costs this feature no redesign | /aid-specify (runtime reset) |

## Source

- REQUIREMENTS.md §5 FR-3.1 (local half), FR-3.4 (whole — a session's own join/leave/list, **and** the operator-only clause that changes another session's membership), FR-4.1–4.7 (the plain-delivery envelope; FR-4.1's `mention?`/`whisper_to?` fields and FR-4.3's whisper filtering are exercised by `feature-010` at stage P4), FR-5.3, FR-7.2 (chat-lifecycle clause **and the clause covering any change to another session's chat membership** — the start/stop/status/configuration clauses belong to `feature-003`, the retention-policy clause to `feature-011`), §6 Delivery semantics (durability, delivery guarantee, progress tracking and ordering — the Retention row belongs to `feature-011`), §9 AC-5, AC-5b, AC-6, AC-9, AC-12, AC-22, §10 stage P1

## Description

The chat, and everything you do with one.

**A chat is the only thing a message is addressed to.** There is no send-to-a-person. The
smallest chat has two members, and that *is* a private conversation — the same mechanism,
not a special case. One idea instead of two.

You create and delete chats through the CLI; a session only joins and leaves for itself, and
joining one that does not exist fails rather than quietly creating it. Chat lifecycle lives
here rather than with node administration because it is the thing every other criterion in
this feature depends on — there is nothing to send to until a chat exists.

A chat may have any number of members. Two is the minimum and the proving case, but a
message fans out to **every** member from the start; larger chats need nothing new here.
What they add later is a way to address *within* them. A session can also list the
chats on this machine and the ones it belongs to — without that, there would be no way to
learn a chat's name in order to join it.

Each chat keeps a **durable log**, and each member keeps **their own place** in it. Being
away delays messages; it does not lose them — right up until the node gives that member up
for gone and reaps it, which is retention's job and is covered in `feature-011`. Within that
window, being away costs nothing. A message may arrive twice, so each carries an
identifier that lets a recipient spot the repeat. Within one chat everyone sees the same
order.

Nothing here blocks. A reply is just another message sent back, matched to what it answers
by a shared identifier. No session ever waits on another — two turn-based agents cannot
safely be put on the same clock.

This stage is **pull only**: a session reads its own mail when it takes a turn. That path
must work on its own, because it is the floor every host falls back to.

## User Stories

- As the operator, I want to create a chat and add sessions to it, so that they have
  somewhere to talk.
- As the operator, I want to delete a chat I no longer need, so that the list stays
  meaningful.
- As a session, I want to list the chats here and join one by name, so that I can take part
  without being told an address out of band.
- As a session, I want to read messages that arrived while I was away, so that being busy
  costs me nothing.
- As a session, I want to mark how far I have read, so that I do not re-read the same
  messages.
- As a session, I want to spot a repeated message, so that acting twice on one instruction
  cannot happen.
- As a session, I want to send a reply that is recognisably an answer, so that a request
  and its response can be matched without either side waiting.

## Priority

Must

## Acceptance Criteria

- [ ] Given the operator, when a chat is created through the CLI, then a session can join it.
- [ ] Given a chat, when the operator deletes it through the CLI, then it can no longer be
      joined.
- [ ] Given a chat with two members, when one sends a message, then the other can read it.
- [ ] Given a chat with more than two members, when one sends a message, then **every**
      member can read it — fan-out is not limited to the two-member case.
- [ ] Given no subscriber armed, when a message arrives, then it is readable at the
      session's next turn — the pull path works alone.
- [ ] Given two sessions in a two-member chat, when they exchange messages, then it behaves
      as a private conversation, with no mention or whisper involved.
- [ ] Given a message read and acknowledged, when the session reads again, then it is not
      returned a second time.
- [ ] Given the same message delivered twice, when the recipient inspects it, then the
      repeat is identifiable by its identifier.
- [ ] Given a message sent as a reply to an earlier one, when the recipient reads it, then it
      can tell which message it answers — a reply correlates to its originating request.
- [ ] Given a member of a chat, when it leaves through the CLI, then it stops receiving that
      chat's messages and the chat no longer lists it as a member.
- [ ] Given the operator and a chat, when they add **another** session to it through the CLI,
      then that session is a member and receives the chat's messages — the operator can place
      a session, which no session can do for another (AC-15).
- [ ] Given the operator and a chat, when they remove **another** session from it through the
      CLI, then that session stops receiving its messages.
- [ ] Given unacknowledged messages, when the node is restarted, then those messages and
      every member's position survive.
- [ ] Given several messages sent into one chat, when members read them, then all members
      see them in the same order.
- [ ] Given a session, when it tries to join a chat that does not exist, then the attempt
      fails explicitly and no chat is created.
- [ ] Given a session, when it lists chats, then it sees the chats on this machine and the
      ones it belongs to.
- [ ] Given any operation in the message plane, when it is called, then it returns without
      waiting on another session.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

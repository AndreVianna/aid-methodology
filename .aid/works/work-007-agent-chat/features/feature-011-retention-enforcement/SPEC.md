# Retention Enforcement

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §6 (limits, retention and policy), §5 FR-7.2 (retention-policy clause), §9 AC-10, §10 stage P4 | /aid-define |
| 2026-08-09 | Reap threshold (24 h) added as a setting distinct from the 30-minute stale threshold; stale and reaped separated into their own criteria | /aid-define (cross-reference Q17) |
| 2026-08-09 | Priority raised Should → Must — AC-10 is a ratified release condition | /aid-define (cross-reference Q16) |
| 2026-08-09 | Lifetime and trim-point criteria reconciled — a message is removed only when past its lifetime **and** read by every member, so no message is destroyed unread; FR-2.3 added to Source, since this is the feature that builds reaping (Q19) | /aid-define (cross-reference) |
| 2026-08-09 | The unread guarantee bounded to **live** members — reaping is the deliberate exception that lets an unread message go, and a third criterion now tests it, replacing a worked example that contradicted the 24 h reap default | /aid-define (cross-reference) |
| 2026-08-09 | "Nothing belonging to the member is deleted" corrected — reaping *does* make its unread messages removable, which is the entire point; what survives reaping is the name | /aid-define (cross-reference) |
| 2026-08-09 | §6's two subsections split by clause with `feature-004`, `feature-005` and `feature-006` — this feature had claimed both whole while two others claimed named parameters, leaving the stale threshold, the long-poll timeout and the Retention row each reading as claimed twice | /aid-define (cross-reference) |

## Source

- REQUIREMENTS.md §6 Limits, retention and policy (the TTL, unread-depth, overflow-policy, payload-size and **reap-threshold** parameters — the stale-session threshold belongs to `feature-004` and the long-poll timeout to `feature-006`), §6 Delivery semantics (the Retention row only — the rest of that table belongs to `feature-005`), §5 FR-2.3 (reaping clause), §5 FR-7.2 (retention-policy clause), §9 AC-10, §10 stage P4

## Description

The part that stops a chat growing forever — without ever losing a message to do it.

**No message is destroyed unread by a member that is still there.** A message is removed only
when it is **both** older than its lifetime **and** read by every live member. Age alone is
not enough: the lifetime says when a message becomes *eligible* to go, and the trim point —
the place every live member has read up to — says when it actually goes. A message waiting on
a colleague who is simply slow, or away for the afternoon, is still there.

**Reaping is the one exception, and it is the point of reaping.** A member given up for gone
stops counting toward the trim point, so a message only that member never read becomes
removable. The guarantee is bounded, not absolute: a message survives as long as some
un-reaped member still has not read it — which by default means about a day past the last
sign of life, not forever.

That guarantee is the point. A message that was sent, never delivered and never reported as
undelivered is precisely the failure the overflow rule below exists to prevent; a hard expiry
would let it back in through another door.

**So time is not what bounds storage here. Two other things are, and both are required.**

The first is the **unread limit**. A member may fall behind by a thousand messages; past
that, new sends to that chat are **rejected with an explicit error** rather than quietly
dropping the oldest. A member that far behind is broken and the sender needs to learn it.
This limit carries more weight than it looks: **there is no maximum message size**, so
nothing bounds a chat in bytes.

The second is **reaping**. A member gone quiet long enough is given up for gone and its claim
on the trim point is dropped, after which the expired messages finally go. Without it, one
abandoned session would pin its chat's log indefinitely.

**Reaped is not the same as stale.** Stale (30 min) is a display state and releases nothing.
Reaped (24 h) is what actually unblocks cleanup: what is released is the member's hold on the
trim point, so messages only it never read do then become removable. Its **name** is not
destroyed — re-registering it is accepted at any time.

One consequence is accepted rather than hidden: a chat holding unread messages for a crashed
session **keeps** them, and may stop accepting new sends once the unread limit is reached,
until that session is reaped.

Every limit is a **default, not a constant** — how long messages are kept, how far behind a
member may fall, what happens on overflow, how long silence means gone. All of it is
changeable through the CLI without touching code.

## User Stories

- As the operator, I want old messages removed automatically once everyone has read them, so
  that a long-running node does not fill the disk.
- As a recipient who was away, I want a message addressed to me to still be there when I come
  back, so that being offline delays my mail rather than destroying it.
- As a sender, I want an explicit error when a member is too far behind, so that I learn the
  consumer is broken instead of losing messages silently.
- As the operator, I want an abandoned session's place released, so that one dead window does
  not stop cleanup for everyone in that chat.
- As the operator, I want to change any of these numbers without a code change, so that I can
  tune them to how I actually work.

## Priority

Must

## Acceptance Criteria

- [ ] Given a message older than the configured lifetime **that every live member has read**,
      when retention runs, then it is removed.
- [ ] Given a message older than the configured lifetime that **an un-reaped member has not
      read**, when retention runs, then it is **kept** — age alone never destroys a message a
      live member has not seen.
- [ ] Given a message older than the configured lifetime that **only a reaped member never
      read**, when retention runs, then it **is** removed — a reaped member stops counting
      toward the trim point, which is what reaping is for.
- [ ] Given a member at the configured unread limit, when another message is sent to that
      chat, then the send is rejected with an explicit error.
- [ ] Given a rejected send, when the chat is inspected, then no existing message was
      discarded to make room.
- [ ] Given a member silent past the **reap threshold** (default 24 h, distinct from the
      30-minute stale threshold), when it is reaped, then its claim is dropped and its chat's
      log can be trimmed past the point it had reached.
- [ ] Given a member marked stale but not yet past the reap threshold, when retention runs,
      then its claim is **still held** — stale alone releases nothing.
- [ ] Given a reaped member, when it re-registers under the same name, then it is accepted
      and starts from the chat's current state.
- [ ] Given a chat whose live members have all read up to a point, when retention runs, then
      the log is trimmed no further than that point.
- [ ] Given any retention limit, when it is changed through the CLI, then the new value takes
      effect without a code change.
- [ ] Given a very large message, when it is sent, then it is accepted — size is not limited,
      and the unread count is what bounds storage.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

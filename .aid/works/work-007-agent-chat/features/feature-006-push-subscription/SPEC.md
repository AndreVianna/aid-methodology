# Push Subscription

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-5.1, FR-7.4, §6 (long-poll timeout), §9 AC-11, §10 stage P2 | /aid-define |
| 2026-08-09 | FR-7.4 split by clause with `feature-003`, and FR-0.3's subscriber half claimed here — both were owned by two features at two stages and tested by neither; a criterion added for the subscriber-is-a-CLI-invocation clause | /aid-define (cross-reference) |
| 2026-08-09 | §6 Limits narrowed in Source to the long-poll timeout, the one parameter this feature owns | /aid-define (cross-reference) |

## Source

- REQUIREMENTS.md §5 FR-5.1, FR-5.4 (node-side accumulation), FR-0.3 (the subscriber half, completing what `feature-003` began at P1), FR-7.4 (the subscriber-is-a-CLI-invocation clause only — the in-tool-skills clause belongs to `feature-003`), §6 Limits (the **long-poll timeout** only — every other parameter in that table belongs to `feature-011`, except the stale-session threshold, which belongs to `feature-004`), §9 AC-11, §10 stage P2

## Description

The node side of waking someone: a connection held open, and a message pushed down it the
moment it arrives.

A subscriber opens the connection and leaves it open. Nothing is polled. When a message
lands the node pushes it immediately. Crucially, **the subscriber does not have to hang up
to deliver** — an earlier design assumed it did, which forced a reconnect after every
single message.

Where a host cannot hold a socket open, the same thing is done with a long wait that
reconnects on timeout, by default every 30 seconds. That number is not a delivery delay: a
message arriving two seconds in is delivered two seconds in. It only decides how often an
idle connection recycles.

There is a gap, however small, between one connection closing and the next opening. **The
gap must not lose anything.** Because the chat log is durable and every member keeps their
own place, a message arriving mid-gap is simply read on reconnection, in order, along with
anything else missed. This is the entire reason the durable log exists.

This half is host-independent. It is the node, the connection, and the wire — the same
everywhere. The per-tool half lives in the waker adapters.

## User Stories

- As a subscriber, I want the node to push a message as soon as it arrives, so that nothing
  has to poll.
- As a subscriber, I want to stay connected after receiving a message, so that a busy chat
  does not mean constant reconnection.
- As a subscriber on a host that cannot hold a socket, I want a long wait that reconnects,
  so that the same behaviour is available with a simpler transport.
- As a session, I want messages that arrived while I was reconnecting to be delivered next
  time, in order, so that the gap costs latency and not correctness.

## Priority

Must

## Acceptance Criteria

- [ ] Given an armed subscriber, when a message is sent to its chat, then the node pushes
      it without being polled.
- [ ] Given a subscriber that has just received a message, when another arrives, then it is
      delivered over the same connection with no reconnection in between.
- [ ] Given messages arriving while a subscriber is between connections, when it
      reconnects, then **all** of them are delivered, in order.
- [ ] Given an idle subscriber and no traffic, when the configured timeout elapses, then it
      reconnects and remains able to receive.
- [ ] Given a host that cannot hold a socket open, when it subscribes by long wait, then it
      receives the same messages as a socket subscriber.
- [ ] Given the timeout is reconfigured, when a subscriber reconnects, then the new value
      is in effect — the limit is a default, not a constant.
- [ ] Given the subscriber, when it is inspected, then it is **a CLI invocation** rather than
      a separate program speaking HTTP — the transport stays internal to the node, and the
      CLI is what carries the subscriber, completing FR-0.3.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

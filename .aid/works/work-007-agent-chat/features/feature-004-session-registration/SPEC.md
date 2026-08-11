# Session Registration

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-2, §6 (stale threshold), §9 AC-2, §10 stage P1 | /aid-define |
| 2026-08-09 | Stale and reaped separated — reaping handed to `feature-011`, and FR-2.3 narrowed in Source to the liveness-tracking clause this feature actually builds | /aid-define (cross-reference) |
| 2026-08-09 | FR-2.3's own text rewritten upstream to state both states and both thresholds; it had still read "stale registrations are reaped", conflating the two and contradicting §6 | /aid-define (cross-reference) |
| 2026-08-09 | The two-machine name-uniqueness criterion restated as a single-machine property of the id — it was unobservable at stage P1, where no node can see another; its cross-machine half moved to `feature-009` at P3 | /aid-define (cross-reference) |
| 2026-08-09 | §6 Limits narrowed in Source to the stale-session threshold, the one parameter this feature owns | /aid-define (cross-reference) |

## Source

- REQUIREMENTS.md §5 FR-2.1, FR-2.2 (the single-machine half — the id's shape; the cross-machine half is `feature-009` at stage P3), FR-2.3 (liveness-tracking and stale-marking clauses only — the reaping clause belongs to `feature-011`), §6 Limits (the **stale-session threshold** only — every other parameter in that table belongs to `feature-011`, except the long-poll timeout, which belongs to `feature-006`), §9 AC-2, §10 stage P1

## Description

How a session says who it is, and how it gets its place back.

A session registers a **name** — plus which tool it is, where it is working, and what it can
do. The name is an identity, not an address: it is how the session is recognised inside a
chat, mentioned, and whispered to. Nobody sends *to* a name.

Names matter because sessions do not last. They crash, hit their limits, get cleared and
restarted, constantly. If a session's place in its conversations were tied to the window,
every restart would lose it. Tying it to the name instead means restarting and re-claiming
the name puts you back exactly where you were — in every chat you belong to, at the point
you had read up to in each.

A session's full identity is its machine plus its name, matching how chats are addressed.
Names are unique per machine.

The node also tracks whether a session is still alive. One quiet for 30 minutes is marked
**stale** — probably gone — so the operator's view distinguishes "reading slowly" from
"never coming back". Being marked stale changes nothing about what is kept.

Giving a session up **for good** is a later, separate state (reaping, at 24 hours) and
belongs to retention, not registration. This feature observes and reports liveness; it
never releases anything.

## User Stories

- As a session, I want to claim a stable name, so that others can recognise me across
  restarts.
- As a session that just restarted, I want to re-claim my name and find my unread messages
  waiting, so that a crash costs me nothing.
- As a session in several chats, I want each chat to remember separately how far I have
  read, so that catching up in one does not skip messages in another.
- As the operator, I want sessions that have gone quiet to be marked as such, so that I can
  tell a slow reader from a dead one.

## Priority

Must

## Acceptance Criteria

- [ ] Given a new session, when it registers a name with its tool, working directory and
      capabilities, then it is recognised by that name.
- [ ] Given a name already held, when the same session restarts and re-registers it, then
      it is reattached to every chat it belonged to, at its previous position in each.
- [ ] Given a session that restarted mid-flight, when it reattaches, then messages that
      arrived while it was gone are still waiting.
- [ ] Given a registered session, when its full identity is read, then it is **this machine's
      address plus the name** — so a name is unique per machine, not globally, and the same
      short name registered elsewhere would be a different session. Verified locally: two
      nodes cannot see each other until federation arrives at stage P3, so this is a property
      of the id's shape, not a cross-machine test.
- [ ] Given a session that has sent no heartbeat for the configured interval, when the
      operator lists sessions, then it is shown as stale.
- [ ] Given a session marked stale, when its chats are inspected, then its position is
      still held — being marked stale discards nothing.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

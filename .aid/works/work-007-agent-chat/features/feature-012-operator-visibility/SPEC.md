# Operator Visibility

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-7.1, §3 (operator), §9 AC-13, §10 stage P4 | /aid-define |
| 2026-08-09 | Priority raised Should → Must — AC-13 is a ratified release condition, and §10 is a delivery order rather than a priority scale | /aid-define (cross-reference Q16) |

## Source

- REQUIREMENTS.md §5 FR-7.1, §3 Users and Stakeholders (the operator), §9 AC-13, §10 stage P4

## Description

Your window into what the sessions have been saying to each other.

The operator launches the fleet and is accountable for it, but sees none of the traffic —
the messages go between sessions, not through a person. This gives you the view: which
machines and sessions exist, which chats are on this machine and who is in them, how far
behind each member is, and a record of what was sent.

The unread counts are the diagnostic that matters. A member sitting at zero is keeping up.
One climbing toward the limit is a session that has stopped reading — a stuck agent, a
closed window, an adapter that quietly failed. That number is usually the first visible
symptom.

**This feature only reads.** It changes nothing, sends nothing, and deletes nothing. That
separation is deliberate: cleanup runs on a timer and modifies state, whereas this prints
what is there. They shared a name in an earlier draft, which hid the fact that they have
nothing in common.

## User Stories

- As the operator, I want to see which sessions are registered and which are marked stale, so
  that I know what is actually alive.
- As the operator, I want to see the chats on this machine and their members, so that I know
  who can hear whom.
- As the operator, I want each member's unread count, so that I can spot a session that has
  stopped reading before anyone complains.
- As the operator, I want a record of what was sent, so that I can audit what the sessions
  told each other.

## Priority

Must

## Acceptance Criteria

- [ ] Given registered sessions, when the operator lists them, then each is shown with its
      machine, tool and liveness.
- [ ] Given chats on this machine, when the operator lists them, then each is shown with its
      members.
- [ ] Given a member behind on its reading, when the operator lists chats, then that
      member's unread count is shown.
- [ ] Given messages that have been sent, when the operator reads the audit log, then it
      records what was sent, by whom, and to which chat.
- [ ] Given any command in this feature, when it runs, then no message, chat, membership or
      configuration is modified.
- [ ] Given a machine on the network, when the operator lists machines, then it appears with
      its liveness.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

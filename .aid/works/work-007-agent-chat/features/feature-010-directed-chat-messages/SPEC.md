# Directed Chat Messages

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-3.5, FR-3.6, FR-3.7, FR-4.1, FR-4.3, §9 AC-12, AC-17, AC-18, §10 stage P4 | /aid-define |
| 2026-08-09 | Un-stapled — AC-12 (plain fan-out to every member) moved to stage P1 and `feature-005`, leaving this feature purely about addressing *within* a chat; the exclusion note moved from Source into Description | /aid-define (cross-reference) |
| 2026-08-09 | Priority raised Should → Must — AC-17 and AC-18 are ratified release conditions, and §4 In Scope names mention and whisper explicitly | /aid-define (cross-reference Q16) |

## Source

- REQUIREMENTS.md §5 FR-3.5, FR-3.6, FR-3.7, FR-4.1 (`mention?` / `whisper_to?`), FR-4.3 (whisper filtering), §9 AC-17, AC-18, §10 stage P4

## Description

What happens once a chat has more than two members: aiming a message at someone, and saying
something only one of them can see.

**Not in this feature:** plain delivery to every member of a larger chat. That is ordinary
fan-out, built and tested at stage P1 (AC-12, `feature-005`). This feature adds only
**addressing within** a chat that already delivers to everyone.

With exactly two members, every message already has exactly one recipient — there is nobody
to aim at and nowhere to hide. Add a third and both become meaningful.

**Mention** aims a message. Everyone still sees it; the named members can tell it was meant
for them. It changes attention, not visibility.

**Whisper** does the opposite. It goes to exactly one member and only that member — and the
sender — can see it. Not on delivery, and **not in the history afterwards**. This is the
part that has to be right: a private aside that shows up when somebody scrolls back is worse
than no privacy at all, because it was believed to be private.

The two cannot be combined on one message. Mention broadens attention within full
visibility; whisper narrows visibility. A message that does both would have to answer who
can see a mention of someone who cannot see the message.

Everything else already works: a chat message reaches every member through the existing
durable log, and each member keeps their own place. Whisper is a visibility rule on top of
that, not a second delivery mechanism.

## User Stories

- As a session in a busy chat, I want to aim a message at a particular member, so that they
  know it needs them while everyone keeps the context.
- As a session, I want to say something to one member only, so that a side conversation does
  not interrupt everyone.
- As a whisper recipient, I want to be sure nobody else can read it, so that private means
  private.
- As a member who was not whispered to, I want no trace of it in the history, so that the
  record matches what I was shown at the time.

## Priority

Must

## Acceptance Criteria

- [ ] Given a message that mentions a member, when it is delivered, then every member
      receives it and the mentioned member can tell it was aimed at them.
- [ ] Given a message whispered to one member, when it is delivered, then only that member
      and the sender receive it.
- [ ] Given a whispered message, when another member reads the chat's history, then it does
      not appear — **not on delivery and not afterwards**.
- [ ] Given a message, when it carries both a mention and a whisper, then it is rejected.
- [ ] Given a two-member chat, when a message is sent with neither mention nor whisper, then
      it behaves exactly as before — larger chats add these, they do not change the small
      case.
- [ ] Given a whisper, when it is stored, then it uses the same durable log and per-member
      position as every other message.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

# Feedback Routing

Feedback reaches the work as an artifact: a question in a work's `STATE.yml`, a question in the
project Knowledge Base, an `IMPEDIMENT.md`, or a finding from monitoring. Route each one by the
table below. Every step that needs an answer from the user runs in the main conversation, under
the question rule.

| Feedback | Routes to |
|----------|-----------|
| A question in a work's `STATE.yml` `qa:` | Main conversation: ask the user the question, one topic at a time, with its reason and a recommendation. |
| A question in `.aid/knowledge/STATE.md` under `## Q&A (Pending)` | KB update: apply the confirmed answer through `/aid-update-kb`. |
| `IMPEDIMENT.md` | Building: the impediment is handled in the Building phase of its work. The task it blocks waits until it is resolved. |
| A monitor finding: a bug, or a change request | A new work through this same intake: a bug becomes a fix work; a change request becomes a new work. Start at `check-intent.md`. |

A finding is handed over as a plain request. It is never routed to an agent by name.

When two feedback items conflict, put both to the user, with a recommendation on which to take
first, under the question rule. Do not decide between them alone.

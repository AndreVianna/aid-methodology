# PROJ-42: Retry policy for the sync job

Status: updated 2026-10-16 by the product owner.

The sync job retries a failed upload. The first draft of this ticket said three attempts;
the decision changed.

- Attempts: give up after 5 attempts in total.
- Timeout: one attempt that runs longer than 30 seconds counts as failed.
- Backoff: wait 2 seconds before the second attempt, then double the wait each time.

Attachments: not accepted on this ticket. It holds comments only, up to 4 KB of text.

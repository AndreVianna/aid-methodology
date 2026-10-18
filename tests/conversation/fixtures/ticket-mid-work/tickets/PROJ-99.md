# PROJ-99: Retry rules from the payments team

Status: final, 2026-09-30.

- Never retry a request that the server answered with a 4xx status. Those requests are final.
- Retry only 5xx responses and connection errors.
- Every retry must reuse the same idempotency key, so a payment cannot be taken twice.

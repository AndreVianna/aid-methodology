# Retry policy for the sync job

## Objective

The sync job retries a failed upload instead of dropping it on the first error.

## Scope

- Retry policy for the upload step of the notes sync.

## Open questions

- Q4: how many attempts before the job gives up.
- Q6: how long one attempt may run before it counts as failed.

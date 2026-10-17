# External Sources

Information from outside the work reaches it in one of two ways:

- **Project sources** -- `.aid/connectors/INDEX.md` and `.aid/knowledge/external-sources.md`.
  Any work uses them when it needs them. They are never attached to a work.
- **Work sources** -- the work's own `sources:` list in its `STATE.yml`. They reach that work
  only.

Work sources follow four procedures: pull in, apply, write back, and handle tool limits.

## 1. Pull in (any phase)

- A tracker item is read through `/aid-read-ticket`. Its connector resolution and its fetch
  through the host tool's own connection stay as `.aid/runtime/templates/connectors/consumption-protocol.md`
  states them.
- A file or a link is read directly.
- Append one `sources:` entry for the item. Write it at once, with `added` set to the time it
  entered and `phase` set to the phase the work was in.

## 2. Apply

- Compare the new material with the work's open `qa:` entries. An answered question is closed,
  and the close names the source in the answer.
- A new question the material raises follows the question rule: one topic, its reason, a
  recommendation, valid options, and a free-text answer.
- When the material meets the conditions of the current phase, the phase moves on.
- Record the outcome in the entry's `effect`, for example `answered Q4, Q6; raised Q9`.

## 3. Write back

Write back only on the user's request. Use `/aid-update-ticket` with the `attachment` part, as
`/aid-update-ticket attachment [<connector>:]<ticket-id> <files>`. It previews and confirms the
write, as it does for any ticket. The files are the ones the user picks, usually `REQUIREMENTS.md`.

After a write lands, append one `write_backs:` entry at the top level of the `STATE.yml`.

## 4. Tool limits

A tracker may not be able to hold what is written: it may have no attachment call, cap the file
size, deny the permission, or stop partway. When that happens:

- Stop, and tell the user what the tracker could not hold.
- Offer the workable options with a recommendation, under the question rule.
- The user always decides how the work is persisted. Never pick a workaround alone.

## 5. Credentials

AID stores no credential for any source. The host tool's own connection does every read and
write. The aid-managed connection types (`api`, `ssh`, `url`, `cli`) stay deferred; their
descriptors exist for discovery and audit only.

## Entry shapes

A `sources:` entry, one per source:

```yaml
sources:
  - ref: 'jira:PROJ-123'   # connector-stem:id, a URL, or a repo-relative path
    kind: ticket           # ticket | issue | document | link | file
    added: '2026-10-14T10:00:00Z'
    phase: Planning        # phase when it entered
    effect: 'answered Q4, Q6; raised Q9'
```

A `write_backs:` entry, one per write-back, at the top level beside `sources:`:

```yaml
write_backs:
  - at: '2026-10-15T09:00:00Z'
    source: 'jira:PROJ-123'            # the sources[].ref written to
    part: attachment                   # the /aid-update-ticket part written
    files: 'REQUIREMENTS.md, PLAN.md'  # one comma-separated string
```

Both lists are block style. Each key stays within three levels.

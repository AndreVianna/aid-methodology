# Secret reconcile — set-skill logic

> Called by `SKILL.md` Step 5b, after Step 2 has resolved this run's `connection_type` (`$TYPE`)
> and `auth_method` (`$NEW_AUTH`, per [`question-sets.md`](question-sets.md)), and after Step 3 has
> read `$OLD_TYPE`/`$OLD_AUTH` off disk (empty on ADD). This is `aid-set-connector`'s **own**
> decision — it is **not** part of [`reconcile.md`](../../../aid/templates/connectors/reconcile.md)'s shared
> single-stem mode. `reconcile.md` § "Single-stem mode" Step S2 says so explicitly: *"a
> `connection_type` transition on UPDATE is the one point where single-stem mode's secret handling
> diverges from bulk mode... that decision is set-skill logic, owned by the calling skill
> (`aid-set-connector/SKILL.md`), not by this shared reconcile helper."*
>
> Two axes distinguish this from the OTHER two secret-touching flows in the connectors family:
> - **Bulk mode (ELICIT)** purges a secret **only** on REMOVE (`persisted ∖ declared`); an in-place
>   field UPDATE never purges, even when `auth_method` drops to `none` (that orphan is left for
>   feature-003's secret lifecycle, per `reconcile.md` § "Bulk mode" Step R3).
> - **`aid-unset-connector`** purges unconditionally as part of a REMOVE — there is no "is this
>   field-only" question, because the whole connector is going away.
>
> `aid-set-connector` sits between these: it is a **set**, not a remove, so it must decide — for
> the ONE stem it targets — whether the *new* state still needs the *old* secret, needs a fresh
> one, needs the old one purged, or never had one at all.

## The decision procedure

```
if [ "$CLASS" = ADD ]; then
    if [ "$TYPE" = mcp ] || [ "$NEW_AUTH" = none ]; then
        SECRET_ACTION=none      # nothing to capture -- mcp has no credential; auth none has none either
    else
        SECRET_ACTION=write     # first-ever capture for this stem
    fi
else  # CLASS == UPDATE
    if [ "$TYPE" = mcp ] || [ "$NEW_AUTH" = none ]; then
        if [ "$OLD_AUTH" != none ]; then
            SECRET_ACTION=purge   # had a stored secret; the new state has none -- orphaned
        else
            SECRET_ACTION=none    # never had one, still doesn't
        fi
    else  # new state IS a credentialed aid-managed result
        if [ "$OLD_TYPE" != "$TYPE" ]; then
            SECRET_ACTION=write   # transitioned INTO this type -- always a fresh capture, never a
                                  # reuse of whatever the old type's secret held
        elif [ "$OLD_AUTH" != "$NEW_AUTH" ]; then
            SECRET_ACTION=write   # auth_method itself changed (e.g. token -> pat) -- the old
                                  # credential's shape no longer applies
        elif [ "$ROTATE_SECRET_FLAG" = 1 ]; then
            SECRET_ACTION=write   # explicit --rotate-secret request
        else
            SECRET_ACTION=none    # pure field-only edit (e.g. endpoint changed, name changed) --
                                  # leave the stored secret exactly as-is, no re-prompt (AC4)
        fi
    fi
fi
```

Evaluate in this order; the branches are mutually exclusive by construction. `$TYPE`/`$NEW_AUTH`
are what Step 2 resolved this run; `$OLD_TYPE`/`$OLD_AUTH` are what Step 3 read off disk (both
empty when `$CLASS = ADD`). `$ROTATE_SECRET_FLAG` is `1` iff `--rotate-secret` was passed (Step 0),
else `0`.

## Applying `SECRET_ACTION`

- **`write`** — invoke, only when `secret_reference` resolves to the `file:` form (the default):
  ```bash
  bash .claude/aid/scripts/connectors/connector-secret.sh write "$STEM" --root .aid/connectors
  ```
  (PowerShell twin: `connector-secret.ps1`.) Never construct this with the literal secret text
  inlined anywhere (a bash command, `STATE.md`, the KB, the conversation transcript) — the script's
  own no-echo stdin capture is the only sanctioned path. For `env:<VAR>` / `keychain:<key>` forms,
  do **not** invoke this script at all — no local value is stored by AID for those forms; only the
  reference literal is written into the descriptor (Step 5a).
- **`purge`** — invoke unconditionally (idempotent even if the file happens to already be absent):
  ```bash
  bash .claude/aid/scripts/connectors/connector-secret.sh purge "$STEM" --root .aid/connectors
  ```
  (PowerShell twin: `connector-secret.ps1`.) This disposes exactly the ONE orphaned secret for
  `$STEM` — never any other stem's.
- **`none`** — no script call at all. This is what makes a repeat `set` at the same type, same
  `auth_method`, no `--rotate-secret`, byte-stable on the secret store (AC4).

## Ordering (binds SKILL.md Step 4 → Step 5)

`connector-secret write` fails closed (exit 4) unless `.aid/connectors/.gitignore` already ignores
`.secrets/`. Step 4 establishes that precondition **before** Step 5 ever runs, on every ADD and
every UPDATE — including one whose `SECRET_ACTION` turns out to be `none` or `purge` (neither of
which is gated by the precondition, but the ordering is unconditional regardless, so no code path
can ever reach a `write` call before the precondition holds). This is what lets AC2 upsert `jira`
`mcp → api` — and thus its first-ever `connector-secret write` — succeed on a fresh, off-pipeline
repo that has never run `/aid-discover`.

## Worked mapping to acceptance criteria

| AC | Scenario | `$CLASS` | `$OLD_TYPE`/`$OLD_AUTH` | `$TYPE`/`$NEW_AUTH` | `$SECRET_ACTION` |
|---|---|---|---|---|---|
| AC1 | `Jira mcp`, stem absent | ADD | — / — | `mcp` / `none` | none |
| AC2 | `Jira api`, stem was `mcp` | UPDATE | `mcp` / `none` | `api` / e.g. `token` | write |
| AC3 | `Jira mcp`, stem was `api`+`token` | UPDATE | `api` / `token` | `mcp` / `none` | purge |
| AC4 | `Jira api` re-run, no field change, no flag | UPDATE | `api` / `token` | `api` / `token` | none |
| AC4 | same, with `--rotate-secret` | UPDATE | `api` / `token` | `api` / `token` | write |
| AC4 | same, but `auth_method` edited to `pat` | UPDATE | `api` / `token` | `api` / `pat` | write |

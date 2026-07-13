# Per-type config question-sets

> Called by `SKILL.md` Step 2, after Step 1 has resolved `<tool>` → `$STEM` and looked up a
> matching row in
> [`preset-catalog.md`](../../../aid/templates/connectors/preset-catalog.md). This reference
> documents WHAT to ask per `<type>`, and the prefill precedence that decides whether a field
> starts pre-populated or blank. It does not cover the secret-capture DECISION (that is
> [`secret-reconcile.md`](secret-reconcile.md)) — only which fields are asked and their defaults.

## Prefill precedence (applies to every field below)

For each field the question-set below asks for, resolve its starting value in this order — the
first source that applies wins; none applying means the field starts blank and the user is asked
outright:

1. **On-disk value** — only when `$CLASS = UPDATE` **and** the type is unchanged from what is on
   disk (`$OLD_TYPE = $TYPE`). A type change invalidates the on-disk value for any field whose
   meaning is type-specific (`endpoint`, `auth_method`, `secret_reference` FORM) — those fields
   fall through to source 2 or 3 instead. `name` is the one field that may still carry over
   sensibly across a type change (SKILL.md's Step 5a still lets the user re-confirm it).
2. **The preset row** (Step 1) — only when the preset row's own `connection_type` **matches**
   `<type>`. A mismatched preset (e.g. Jira's `api`-typed row used under `aid-set-connector Jira
   mcp`) contributes `name`/`tags`/`notes` only (Step 1) — never its `endpoint-template` /
   `auth_method` / `secret_reference-form`, since those describe the *other* type's shape.
3. **Blank** — ask outright, no suggested default beyond the type's own forced value (below).

## Preset vs. custom, and the type-mismatch case

- **Preset, type matches** (e.g. `aid-set-connector Jira api` against Jira's `api` preset row):
  every applicable column prefills — `endpoint` from `endpoint-template`, `auth_method` from the
  row, `secret_reference` FORM from `secret_reference-form`. The user confirms or supplies instance
  specifics (their own org/host/domain, the env-var name when the form is `env:`).
- **Preset, type mismatches** (e.g. `aid-set-connector Jira mcp` against Jira's `api` preset row):
  `name` prefills from the row; `endpoint`/`auth_method`/`secret_reference` FORM do **not** —
  `<type>`'s own forced/default rules below apply instead, exactly as if this were a custom
  declaration for those fields. `preset: <preset-id>` is still recorded (the tool is a known
  preset — it is only being declared under a different transport this run).
- **Custom** (no preset-id match for `$STEM`): capture `name` (`<tool>` as given), `connection_type`
  (`<type>`, already validated against the closed enum in Step 0 — refused, not coerced), and the
  type's own fields below. `preset: custom`.

`tags`/`audience` are never prompted in either case — see SKILL.md Step 2's closing paragraph.

## The four question-sets

### `mcp` — tool-managed

| Field | Ask? | Default / rule |
|---|---|---|
| `name` | yes | Prefill precedence above |
| `endpoint` | optional | Informational only — **never** a launch/wire command (AID does not launch or wire an `mcp` target). Prefill from `endpoint-template` only when the preset's own type is `mcp` too; otherwise blank/skippable |
| `auth_method` | no | **Forced** `none` — the host tool authenticates the target; AID registers no credential |
| `secret_reference` | no | **No such field is written** — there is nothing to capture (see `secret-reconcile.md`) |

Body note: record that the connection is available via the **host tool's own MCP/plugin** and that
the agent must request it from the tool (the tool handles auth) — mirroring feature-001's worked
`github.md` example.

### `api` / `url` — aid-managed

| Field | Ask? | Default / rule |
|---|---|---|
| `name` | yes | Prefill precedence above |
| `endpoint` | yes | Prefill precedence above; this is the concrete connect target (URL) the agent uses directly |
| `auth_method` | yes | Choose from `none \| token \| pat \| oauth`. Default suggestion: prefill precedence above, else `token` |
| `secret_reference` FORM | only if `auth_method != none` | Default `file:.aid/connectors/.secrets/$STEM`; `env:<VAR>` / `keychain:<key>` offered as alternatives — ask for the VAR/key name when chosen |

### `ssh` — aid-managed

| Field | Ask? | Default / rule |
|---|---|---|
| `name` | yes | Prefill precedence above |
| `endpoint` | yes | Host/target — this type's connect target is a host, not a URL |
| `auth_method` | no | **Forced** `ssh-key` — an `ssh` connector is always credentialed by design; there is no `none` option for this type |
| `secret_reference` FORM | always | Same default/alternatives as `api`/`url` above; the captured value is the key material itself |

### `cli` — aid-managed

| Field | Ask? | Default / rule |
|---|---|---|
| `name` | yes | Prefill precedence above |
| `endpoint` | yes | Command/target (e.g. `docker`) |
| `auth_method` | yes | Choose from `none \| token \| pat \| oauth`. Default suggestion: `none` — most CLI targets need no stored credential (per feature-001, "usually none"), but the question is still asked so a credentialed CLI (e.g. one wrapping an authenticated API) is representable |
| `secret_reference` FORM | only if `auth_method != none` | Same mechanics as `api`/`url` above |

## Asking, per project convention

Use `AskUserQuestion` for every field the table above marks "yes"/"only if…" — never silently
assume a suggested value. For each:

- Include a **"Keep prefilled value"** option whose description shows the resolved prefill (or
  states "no default — type your own" when precedence resolved to blank).
- Include 1–2 topical suggestion options drawn from the table above (e.g. `auth_method`:
  `none`, `token`, `pat`, `oauth` as separate suggestion options, trimmed to what's relevant).
- **Never set the `preview` field** — it switches `AskUserQuestion` to a side-by-side layout that
  suppresses the auto-injected `Other` free-text input, which this flow needs (instance specifics
  — org/host/domain, VAR names — are never fully enumerable as fixed options).

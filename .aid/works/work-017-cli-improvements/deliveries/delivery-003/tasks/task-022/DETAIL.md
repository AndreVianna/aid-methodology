# task-022: Shared list-CRUD UI (Connectors + External Sources)

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** feature-007-connectors-list, feature-010-external-sources-list -> delivery-003

**Depends on:** task-019, task-021

**Scope:**
- Add both list-CRUD sections to the project page `dashboard/home.html`, rendered as siblings of the
  existing Knowledge Base band (`#knowledge-tool-section` line 877, rendered via
  `_renderKbCard(model.repo.kb_state)` in `renderMainPage`, call line 1350). Both `kb_state`,
  `connectors`, and `external_sources` are project-level `.aid/`-derived references on
  `model.repo`, so the new sections sit naturally beside the KB card (before the Pipelines section,
  line 879). Reuse one shared list-CRUD scaffold across both sections (view table/list +
  `write_enabled`-gated Add + per-row Remove + inline error surface).
- **Connectors section** -- a `<h2 class="main-section-head">Connectors</h2>` + container div
  populated by `_renderConnectorsCard(model.repo.connectors, writeEnabled)` in `renderModel`.
  Read view (always shown): a table with columns **Connector (name) · Type · Endpoint · Auth ·
  Secret Ref · Summary** matching `build-connectors-index.sh`'s column contract (lines 17-18) so the
  dashboard and the on-disk `INDEX.md` present the same shape; empty registry -> "No connectors
  registered." Add form (only when `write_enabled === true`): inputs for `name`, a `type` `<select>`
  (`mcp|api|ssh|url|cli`), `endpoint`, an `auth_method` `<select>`
  (`none|token|pat|oauth|ssh-key`), and a `secret_reference` field; MAY progressively show/hide
  fields by type (mirroring question-sets.md: `mcp` hides auth/secret, `ssh` forces `ssh-key`) --
  a client-side convenience, not required for AC. Submit -> `POST /r/<id>/api/op`
  `{op:"connector.set", target:{}, args:{name,type,endpoint?,auth?,secret_ref?}}`. Secret hint: for
  an aid-managed connector (`auth_method != none`) whose `secret_reference` uses the `file:` form,
  the row shows a passive "secret not yet stored -- run `connector-secret.sh write <stem>`" hint (the
  value is out-of-band per feature-007 §Security); NO secret input is posted. Remove: each row gets a
  Remove button with a `confirm()` guard -> `POST /r/<id>/api/op` `{op:"connector.remove", target:{},
  args:{stem}}`.
- **External Sources section** -- a `<h2 class="main-section-head">External Sources</h2>` +
  `<div id="external-sources-section">` immediately after the KB band, rendered by
  `_renderExternalSourcesCard(model.repo, model.write_enabled)` in `renderMainPage`. Read view
  (always shown): list each `model.repo.external_sources` entry, URL rendered as an
  `<a href rel="noopener noreferrer">`, else plain text, decided by a **browser-side URL regex twin**
  of the reader predicate: `/^[a-z][a-z0-9+.\-]*:\/\//` -- byte-identical to Python `_RE_URL`
  (`parsers.py` line 510, backing `is_url_source` line 623) and Node `RE_URL_SOURCE`
  (`reader.mjs` line 1066, backing `isUrlSource` line 1068); empty -> "No external sources
  registered." Write controls (only when `write_enabled === true`): a per-entry Remove button, and
  below the list an Add row = one text input (placeholder "https://… or path/to/doc") + Add button.
  Add -> `POST /r/<id>/api/op` `{op:"external-source.add", target:{}, args:{value:<input>}}`; Remove
  -> `{op:"external-source.remove", target:{}, args:{value:<entry>}}`. Client-side validation mirrors
  the server (trim; block empty and any-whitespace values before POST) -- fast feedback only, server +
  writer remain the authority.
- `write_enabled` gating -- read the `write_enabled` envelope signal feature-001 adds, alongside the
  other envelope-level fields `home.html` already consumes in `onSuccess` (`schema_version` line
  1069, `details` line 1081, `generated_by` lines 1085-1086), and pass it to both card renders. When
  false (read-only `--remote`), each section renders the view ONLY -- no Add form, no Remove buttons
  (defense-in-depth: the server 403s them anyway). The read-only lists render regardless.
- Actions & re-render -- issue each op as a direct same-origin `fetch` to `POST /r/<id>/api/op` (the
  same client call feature-002 introduces for `settings.set` and no shared op-helper abstraction is
  introduced here; CSP `connect-src 'self'` already permits it). On `ok`, perform the immediate
  targeted re-fetch of `./api/model` (the page's existing fetch, line 1042) and re-render both cards
  from the fresh model so the lists reflect the exact on-disk registry (drift window = one
  round-trip). On failure, surface the `error`/`detail` inline (e.g. 422 invalid-value -> "Enter a
  URL or a path with no spaces"; 404 -> the entry was already gone) and re-render from the fresh
  model regardless.

**Acceptance Criteria:**
- [ ] `home.html` renders a Connectors section and an External Sources section as siblings of the KB
  band via `_renderConnectorsCard` / `_renderExternalSourcesCard` in `renderMainPage`, both driven
  off `model.repo` (`connectors`, `external_sources`); both read views render regardless of
  `write_enabled`. (feature-007 AC2, feature-010 AC2)
- [ ] The Connectors table shows Connector · Type · Endpoint · Auth · Secret Ref · Summary (matching
  `build-connectors-index.sh`'s columns) with an empty-state line; the External Sources list renders
  each entry as an `<a href rel="noopener noreferrer">` iff it matches the browser URL regex twin
  `/^[a-z][a-z0-9+.\-]*:\/\//` (else plain text), with an empty-state line.
- [ ] Add/Remove controls render only when `envelope.write_enabled === true` (both sections); when
  false, no Add form and no Remove buttons render, but the read views remain visible.
- [ ] Connector Add submits `connector.set` with `target: {}` and the type-aware args; Remove submits
  `connector.remove` with `{stem}` behind a `confirm()` guard; the secret hint appears for an
  aid-managed `file:`-form connector and no secret value is ever posted. (feature-007 AC1)
- [ ] External-source Add submits `external-source.add` and Remove submits `external-source.remove`,
  both with `target: {}` and `{value}`; client-side trim/whitespace/empty validation runs before
  POST. (feature-010 AC1)
- [ ] On any op `ok`, the client re-fetches `./api/model` and re-renders both cards from the
  post-write model (no drift); on failure it surfaces `error`/`detail` inline and re-renders from the
  fresh model. (feature-007 AC2, feature-010 AC2)
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass

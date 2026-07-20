# task-014: index.html Add/Remove Project UI + card-actions scaffold

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

**Source:** feature-003-project-registry -> delivery-002

**Depends on:** task-013

**Scope:**
- **Objective:** add the Add Project and per-card Remove Project controls to `dashboard/index.html`, driving the `project.add` / `project.remove` ops task-013 registered, and introduce the **shared `card-actions` sibling-row scaffold** (KI-004) that feature-004 will reuse. `dashboard/index.html` is the only file changed; no server edit.
- **`write_enabled` read + gating (single signal).** In `onSuccess(envelope)` (which already calls `renderMachinePanel` L700 and `renderRepoGrid` L770 at L632-633), read `envelope.machine.write_enabled` once per load and thread it into the render. **Missing => false** (fail-safe). Every write control below renders **only when `write_enabled === true`**; the read-only presentation is otherwise unchanged.
- **UI-P1 Add Project.** A right-aligned "Add project" `.btn-ghost` in the `#repo-section` header row beside the "Projects" `<h2>` (L527), mirrored inside `#empty-registry` (L532) so the first project can be registered when the grid is empty. Clicking reveals an inline row: a labelled text `<input placeholder="/absolute/path/to/aid/project">` (note "must already be an AID project -- Add only registers it, it installs nothing"), a "Register" submit `.btn-ghost`, and "Cancel". Submit is a JS `fetch` POST of `{op:"project.add", args:{path:<trimmed input>}}` (empty input -> inline validation, **no** request); on 200 call the existing `doFetch()` (L590) to re-render. **No native `<form>` submit** (CSP `form-action 'none'`, `_CSP_HEADER` L290). On 422/500 show the writer's `detail` inline via `textContent` (input stays populated so the user can correct it). No OS folder picker (OQ-P1: typed path only).
- **UI-P2 Remove Project.** A small "Remove" `.btn-ghost` per card, added in `_renderRepoCard` (available cards, L815) and `_renderUnavailableCard` (stale cards, L902). Interaction: **lightweight inline confirm** -- clicking flips the button **in place** to "Confirm untrack" + "Cancel" with copy "Untracks this project from the dashboard. No files are removed." This is a decided **inline button-flip, NOT a `window.confirm`** (keyboard-reachable, `.btn-ghost`-stylable, `aria-live`-announceable). On confirm, JS `fetch` POST of `{op:"project.remove", target:{id: repo.id}}`, then `doFetch()`. On error, a transient inline message on the card via `textContent`. **Stale-card behaviour (feature-003 SPEC §UI-P2):** on an unavailable/stale card the Remove button **replaces** (does **not** supplement) the static manual prune-guidance steps when `write_enabled === true`; those steps remain only as the read-only fallback (when `write_enabled` is false/missing).
- **Shared `card-actions` sibling-row scaffold (KI-004).** Introduce a single reusable `<div class="card-actions">` sibling row: because a repo card is/becomes an `<a class="card card-link">` navigation link, action `<button>`s must **not** be nested inside the anchor -- the card grid item becomes a container holding the existing card link **plus** the sibling `card-actions` row. Remove Project lives in this row. This scaffold MUST be the single shape feature-004 (task-016) reuses for its "Update Tools" button -- not a second independently-invented action row.
- **OQ-P2 command-text reconciliation.** Fix the one stale command string in the read-only unavailable-card guidance: `aid remove --target <path>` (L936, a tool-uninstall command) -> the untrack-only `aid projects remove <path>`. Text-only, no behaviour change. **Leave the empty-registry hint `aid add <tool>` (L533) unchanged** -- it is the brand-new-user bootstrap command that scaffolds `.aid/` and auto-registers, which `aid projects add` (register-only, requires a pre-existing `.aid/`) cannot replace.
- **Safety / accessibility.** All new controls are real `<button type="button">` with discernible labels; all dynamic text (the user-typed path, the writer's `detail`) is inserted via `textContent` / `escHtml` (L689) -- never `innerHTML`. Error text uses `aria-live="polite"` consistent with the existing `#freshness-badge` (L501). No layout/theme change beyond the added controls. When read-only, the static prune guidance remains (text reconciled per OQ-P2).

**Acceptance Criteria:**
- [ ] The "Add project" control renders in the `#repo-section` header and inside `#empty-registry` **only when `envelope.machine.write_enabled === true`** (missing => hidden); clicking reveals the inline typed-path form; submit `fetch`-POSTs `project.add` with the trimmed path then re-renders via `doFetch()`; an empty input triggers inline validation with no request.
- [ ] On a 422/500 response the Add form surfaces the writer's `detail` inline via `textContent` and leaves the input populated; no native `<form>` submit is used (CSP `form-action 'none'` satisfied).
- [ ] A per-card "Remove" control renders in both `_renderRepoCard` and `_renderUnavailableCard` only when `write_enabled === true`; clicking flips the button in place to "Confirm untrack" + "Cancel" (an inline button-flip, not `window.confirm`) with the "No files are removed" copy; confirming `fetch`-POSTs `project.remove` with `{target:{id: repo.id}}` then re-renders via `doFetch()`.
- [ ] On an unavailable/stale card (`_renderUnavailableCard`) the Remove control **replaces** (does not supplement) the static manual prune-guidance steps when `write_enabled === true`; the static prune steps render only as the read-only fallback when `write_enabled` is false/missing (feature-003 SPEC §UI-P2).
- [ ] A single shared `<div class="card-actions">` sibling-row scaffold is introduced as a sibling to (never nested inside) the `<a class="card card-link">`, carries the Remove button, and is structured for feature-004 (task-016) to add its "Update Tools" button to the same row (KI-004).
- [ ] The stale unavailable-card guidance `aid remove --target <path>` (L936) is reconciled to `aid projects remove <path>`, and the empty-registry hint `aid add <tool>` (L533) is left unchanged (OQ-P2).
- [ ] All dynamic text (typed path, writer `detail`) is rendered via `textContent`/`escHtml` (no `innerHTML`); error text uses `aria-live="polite"`; controls are real `<button type="button">`.
- [ ] Under read-only (`write_enabled` false/missing) no Add or Remove control renders and the static prune guidance remains (feature-003 AC8 / AC2 truthful re-render on 200).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass

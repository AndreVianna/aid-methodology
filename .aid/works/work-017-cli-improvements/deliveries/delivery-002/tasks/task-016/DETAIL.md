# task-016: Update-tools UI on index.html

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

**Source:** feature-004-update-tools -> delivery-002

**Depends on:** task-014, task-015

**Scope:**
- **Objective:** add the two update controls to `dashboard/index.html` -- a global "Update CLI" in the machine panel (`tools.update-self`) and a per-repo-card "Update Tools" (`tools.update`) -- **reusing the shared `card-actions` sibling-row scaffold task-014 introduced** (KI-004), with a mandatory busy-state and the restart advisory on an observed `machine.aid_version` change (KI-002/KI-006). `dashboard/index.html` is the only file changed; `home.html` is **not** modified.
- Neither control renders unless `machine.write_enabled === true` (feature-001's DM-2 gate; **missing => false**, fail-safe).
- **Global "Update CLI" -- machine panel** (`renderMachinePanel`, L700-765). Append an action row to the `card.plugin` (after the `dl`, before `container.appendChild(card)`): a `<button class="btn-ghost">Update CLI</button>` shown only when `machine.write_enabled === true`. Click: disable the button and swap its label to "Updating..." (busy-state), then `fetch('/api/op', {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({op:'tools.update-self'})})`. On `ok`: re-fetch `/api/home`, re-render (the `machine.aid_version` pill L712-717 reflects the new version), and show a dismissible notice "AID CLI updated -- restart `aid dashboard` to load the new dashboard code." On failure: re-enable the button and surface `error`/`detail` inline (no silent failure).
- **Per-project "Update Tools" -- repo card** (`_renderRepoCard`, L815-888). The card is an `<a class="card card-link" href="/r/<id>/home.html">` (L826-828), so the `<button>` **must not** be nested inside it -- add it to the **shared `card-actions` sibling row scaffold task-014 introduced** (KI-004), alongside the existing Remove Project button (not a second independently-invented action row). Control: `<button class="btn-ghost">Update Tools</button>` shown only when `machine.write_enabled === true` **and** `repo.available === true` (an unavailable repo -- `_renderUnavailableCard`, L820 path -- has no `.aid/`/manifest to update and gets no button). `_renderRepoCard` currently receives only `repo` (L815); thread the envelope-level `machine.write_enabled` (read in `renderMachinePanel` L632) through `renderRepoGrid` -> `_renderRepoCard` so the card gates its button on the same global flag. Click: busy-state, then `fetch('/r/' + repo.id + '/api/op', ... body {op:'tools.update'})`.
- **Restart advisory on `machine.aid_version` change (KI-002 / KI-006).** After `tools.update-self` `ok`, always show the restart notice. After `tools.update` `ok`, capture the pre-op `machine.aid_version` and, if the re-fetched `machine.aid_version` **differs** (the observable signal that `aid update`'s stale-CLI self-update preamble ran, mutating the running server's own code, `bin/aid` L3097-3099), show the **same** dismissible "AID CLI updated -- restart `aid dashboard` to load the new dashboard code" notice. Reuse the existing "Assets out of date ... restart `aid dashboard`" copy (L516-521). On `tools.update` `ok` the card's installed-tool version chips (`repo.aid_version`, L850-864) reflect the persisted change (AC2/NFR3).
- **Busy-state (mandatory -- KI-003).** Because a real update takes seconds-to-minutes and the Node runtime blocks the whole server for the duration, the triggering button MUST be disabled and labelled "Updating..." until the op resolves; on the Node runtime the page is unresponsive during that window (documented limitation) -- the busy label sets the expectation.
- **Safety.** Real `<button type="button">`; error text via `textContent` (no `innerHTML` with `detail`), following the same safety rules as task-014. Under read-only (`write_enabled` false/missing) neither control renders.

**Acceptance Criteria:**
- [ ] A global "Update CLI" `<button class="btn-ghost">` is appended to the machine-panel `card.plugin` (`renderMachinePanel`) and renders **only when `machine.write_enabled === true`**; clicking sets the busy-state (disabled + "Updating...") and `fetch`-POSTs `{op:'tools.update-self'}` to `/api/op`.
- [ ] On `tools.update-self` `ok`, the client re-fetches `/api/home` (the `machine.aid_version` pill refreshes) and shows a dismissible "restart `aid dashboard`" notice; on failure the button re-enables and `error`/`detail` is surfaced inline (feature-004 AC1b).
- [ ] A per-repo "Update Tools" `<button class="btn-ghost">` is added to the **shared `card-actions` sibling-row scaffold from task-014** (not nested in the `<a class="card card-link">`, not a second action row) and renders only when `machine.write_enabled === true` **and** `repo.available === true`; `machine.write_enabled` is threaded through `renderRepoGrid` -> `_renderRepoCard`.
- [ ] Clicking "Update Tools" sets the busy-state and `fetch`-POSTs `{op:'tools.update'}` to `/r/<repo.id>/api/op`; on `ok` the client re-fetches `/api/home` so the card's version chips (`repo.aid_version`) refresh (feature-004 AC1 / AC2).
- [ ] The restart advisory is shown after `tools.update-self` unconditionally, and after `tools.update` whenever the re-fetched `machine.aid_version` differs from the captured pre-op value (KI-002/KI-006), reusing the existing restart copy (L516-521).
- [ ] The busy-state (button disabled + "Updating..." label until the op resolves) is present on both controls (KI-003); error text uses `textContent` (no `innerHTML`); under read-only neither control renders.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass

# task-012: Reader (Node twin reader.mjs) — mirror hierarchy + worktree + reconcile

**Type:** IMPLEMENT

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-009, task-010, task-011

**Scope:**
- Mirror tasks 009/010/011 in the Node twin `dashboard/server/reader.mjs` for byte-identical model output:
  - hierarchical per-unit STATE derivation + legacy monolithic fallback (presence-based per-work);
  - worktree enumeration via `git worktree list --porcelain` using the EXISTING `runGitCommand` fixed-argv / `execFileSync` no-shell pattern (`reader.mjs:525-544`), verb hard-coded in argv; same 2 s timeout + degrade-to-main behavior as the Python runner. NOTE: `reader.mjs` has NO git-verb allow-list today (`runGitCommand` runs `execFileSync("git", args)` with no verb check) — safety rests on the fixed-argv call, not an allow-list. IF the optional hardening guard is adopted (mirroring task-010), introduce a guarded runner in `reader.mjs` that permits `worktree` (+ the existing rev-parse/symbolic-ref/log) and route the calls through it; otherwise no allow-list is added. Do NOT assume an allow-list already exists;
  - same-work reconcile with an identical SD-2 rank map and newest-`Updated:` rule.
- Honor "state" naming and legacy "Status" fallback identically to Python.
- Keep the existing read-only construction (fs read + bounded git only).
- **Update `dashboard/home.html` for the state-naming rename:** home.html is install-wired/vendored and references the old section names in two places — the help string at `:3204` ("see Quick Check Findings, Delivery Gates above") is a pure user-facing label, but the `_anchorRawState` deep-anchor at `:3138` searches the raw STATE text for the LITERAL string `## Tasks Status` to scroll to a task's block. Renaming the section to `## Tasks State` would break that anchor unless it matches the new name (tolerate BOTH for legacy/hierarchical coexistence, consistent with the reader's legacy "Status" fallback). Update both; ASCII-only.

**Acceptance Criteria:**
- [ ] reader.mjs derives hierarchical works, falls back to legacy monolithic, enumerates worktrees, and reconciles same-work — matching the Python reader's behavior.
- [ ] The Node worktree call uses the fixed-argv / no-shell `runGitCommand` pattern (verb hard-coded); the subprocess is read-only, 2 s-bounded, degrades to main root. IF hardening adopted: a guarded runner is introduced and permits `worktree`; otherwise no allow-list claim is made (none exists in `reader.mjs` today).
- [ ] Node↔Python parity holds (identical model output) on the task-014 fixtures.
- [ ] `dashboard/home.html` user-facing labels and the `_anchorRawState` deep-anchor lookup match the renamed sections (tolerating both legacy "Status" and new "State"); ASCII-only.
- [ ] Read-only; ASCII-clean where shipped.
- [ ] All §6 quality gates pass.

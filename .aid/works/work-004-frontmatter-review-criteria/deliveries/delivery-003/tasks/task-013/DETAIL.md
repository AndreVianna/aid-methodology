# task-013: Derive the removal set and apply the check-skill-counts.mjs disposition

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-003

**Depends on:** -- (none within delivery-003; delivery-002 must be complete)

**Scope:**
- **Derive** the removal set from this branch's disk (AC-3) — assert no inherited inventory. Enumerate
  every script whose job is checking a fact stated in prose; for each, name the declaration that now
  covers it or state the coverage-drop and why.
- Confirm the two named non-candidates survive: `canonical/aid/scripts/kb/kb-citation-lint.sh` (checks
  citation form, not a prose fact) and `tests/canonical/test-dogfood-byte-identity.sh` (a build question).
- Apply the `check-skill-counts.mjs` disposition per feature-003 SPEC §2. **Owner decision point
  (flagged):** default is **full delete** (keeps the 379 guard-line floor), with each corpus part the
  cascade cannot absorb given a named replacement or a stated coverage-drop; the **narrow** alternative
  (keep it for `docs/` + root `README.md` only) is the fallback if the owner prefers the ongoing count
  gate there. Record which was chosen and why.
- **Handle the checker's companions when it is deleted** (else deleting it breaks the suite / leaves
  dangling citations — the count-guard analogue of task-008's README-pointer prep):
  - **`tests/canonical/test-skill-counts.sh`** — the wrapper that runs `node
    tests/canonical/check-skill-counts.mjs` (line 49) and is auto-discovered by `tests/run-all.sh`'s
    `tests/canonical/test-*.sh` glob (line 112). On full delete, remove it with the checker; on narrow,
    keep it pointed at the narrowed checker.
  - **KB docs that make a *current* claim about the checker** — update `module-map.md` and
    `test-landscape.md` (inventory rows) and `tech-debt.md` (W1-11's closure evidence cites the checker
    as the live count-guard). Leave genuinely **dated/historical** records as-is per FIX-contract F3
    (e.g. a dated row in `.aid/knowledge/STATE.md`). `relationships.md` is `source: generated` and drops
    the rows on regeneration in task-015 — do not hand-edit it.

**Acceptance Criteria:**
- [ ] The removal set is derived from disk; no file removed on an inherited inventory (AC-3).
- [ ] Each removed check names its replacing declaration or a stated coverage-drop-and-why.
- [ ] `kb-citation-lint.sh` and `test-dogfood-byte-identity.sh` survive.
- [ ] The `check-skill-counts.mjs` disposition (delete or narrow) is applied and the choice recorded.
- [ ] On full delete, `tests/canonical/test-skill-counts.sh` is removed too, so `tests/run-all.sh` has
      no orphaned suite; on narrow, the wrapper still points at a working checker.
- [ ] No KB doc makes a false *current* claim about the removed checker: `module-map.md`,
      `test-landscape.md`, `tech-debt.md` (W1-11) are updated; dated historical rows (`STATE.md`) are
      left per F3; `relationships.md` is left for task-015's regeneration.
- [ ] No new guard/mechanism added (C-1). All §6 quality gates pass.

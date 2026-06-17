# task-005: bash — reconcile auto-registration to the deterministic tier rule

**Type:** IMPLEMENT

**Source:** feature-001-projects-command → delivery-001

**Depends on:** task-003

**Scope:** Make the existing auto-registration call sites use `_aid_resolve_tier` (FR7), per SPEC §Layers A. **There are TWO interactive tier prompts in `bin/aid` — both must be removed:**
- **Prompt #1** — `_aid_cwd_classify` tier block (`~2145-2163`, "Register this repo…" `~2152`): **replace** the y/N prompt with `_aid_resolve_tier` (no prompt; it already gated on scope+location).
- **Prompt #2** — the `aid add` B-table tier prompt (`~2754`, "Add this repo to the shared machine registry?"): **also replace** with `_aid_resolve_tier`, so `aid add <tool>` on a global/outside-home install no longer prompts.
- `aid dashboard` auto-register (`~1212`/`~1221`): adopt `_aid_resolve_tier` BUT **preserve never-elevate** — a `shared` result that would require elevation degrades silently to the user tier (never prompt during a render).
- migrate side-effect register (`~1776`): pass the `_aid_resolve_tier` result and **never-elevate** (degrade silently — must not newly prompt under a TTY).
- This task OWNS both prompt regions (task-001 deliberately leaves them untouched). ASCII-only; re-anchor by symbol name. Do not alter `registry_register`/`registry_unregister` internals.

**Acceptance Criteria:**
- [ ] Neither prompt remains: `grep -nE "Register this|Add this repo" bin/aid` returns **zero**; both sites resolve tier via `_aid_resolve_tier`.
- [ ] `aid add <tool>` on a global, outside-`$HOME` target registers without any interactive prompt.
- [ ] `aid dashboard` auto-register and the migrate side-effect never prompt/elevate — they degrade silently to the user tier when a shared write would need elevation.
- [ ] Tier selection is consistent across `aid add` / cwd-classify / dashboard / migrate (all via `_aid_resolve_tier`).
- [ ] ASCII-only; `bin/aid` parses/runs.
- [ ] All §6 quality gates pass.

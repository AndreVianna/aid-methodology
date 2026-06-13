# task-061: aid-discover FR34 auto-trigger of aid-summarize + FR35 kb_baseline record at DONE

**Type:** IMPLEMENT

**Source:** feature-007-kb-dashboard → delivery-009

**Depends on:** task-059

**Scope:**
- Land the **one deliberate NEW closing behavior** of the KB tier (FR34, FF-A1, LC-A5, PR-A, R11) in `canonical/skills/aid-discover/references/state-done.md` (the DONE close). This is **NOT** a C4 behavior-preserving change — it is an intended new observable behavior; it **composes** (does not replace) the two existing approval gates (discovery's KB approval + summarize's V1).
- **AUTO-TRIGGER (FR34):** replace today's "💡 Optional: run /aid-summarize" *suggestion* (`state-done.md:19-27`) with an **auto-invocation** of `/aid-summarize` as discovery's closing step — invoking its FULL state machine (PREFLIGHT → STALE-CHECK → … → APPROVAL(V1) → WRITEBACK → DONE), which runs its own V1 visual-approval gate and produces `kb.html`. **Async by design:** discovery is "DONE" at KB approval and does not block on the summary; if the user defers/fails summarize's V1 the KB card sits at `preparing` (FF-A3), never `generating`.
- **RECORD BASELINE (FR35):** before HALT, resolve the default branch (DD-A2 detection: prefer existing, else `origin/HEAD` basename, else first of `{main, master}`) + read its tip via `git log -1 --format=%cI <branch>`, and **write** `.aid/settings.yml kb_baseline: {branch, tip_date}` (DD-A4) using `/aid-config`'s **"append a new block"** path (the not-yet-present-section idiom @ `aid-config SKILL.md:126-132`, NOT the single-line "Save in place" replace @ `SKILL.md:124`; same temp-file + `mv -f` crash-safe rename) — the schema task-059 owns. This is the **first** write of the multi-line `kb_baseline` block (R13).
- The auto-trigger **must not** regress either approval gate (R11): discovery's KB approval and summarize's V1 both still fire; the change adds an auto-invocation + the baseline write, nothing else.
- Edits are **canonical/-authored** (rendered by task-063's FULL `run_generator.py` — NOT per-script, NOT vendor-refresh). **ASCII-only.** Edits `canonical/**` only; do NOT edit `.claude/**` here.

**Acceptance Criteria:**
- [ ] `state-done.md` replaces the "💡 Optional: run /aid-summarize" suggestion (`:19-27`) with an **auto-invocation** of `/aid-summarize` (its full state machine incl. V1) as discovery's closing step; the two existing approval gates (discovery KB approval + summarize V1) both still fire — neither is replaced (R11).
- [ ] Before HALT, `aid-discover` resolves the default branch (DD-A2 detection) + reads its tip (`git log -1 --format=%cI`) and writes `.aid/settings.yml kb_baseline: {branch, tip_date}` via the **append-a-new-block** path (`aid-config SKILL.md:126-132`), NOT the single-line replace (R13); this matches the task-059 schema.
- [ ] The auto-trigger is documented as **async** (discovery is DONE at KB approval, does not block on the summary; a deferred/failed V1 → card `preparing`, never `generating` — FF-A3); it is recorded as the one **deliberate new behavior** (not C4-preserving, FR34/C7).
- [ ] All touched canonical files are ASCII-only; no discovery phase/gate beyond the documented FR34 close is altered.
- [ ] All §6 quality gates pass; the canonical edit is left to be dogfood-rendered by task-063 (this task does not run `run_generator.py` and does not modify `.claude/**`).

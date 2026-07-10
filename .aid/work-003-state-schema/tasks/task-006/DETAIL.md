# task-006: Normalize genuinely-dangling quality-gate references in AID templates

**Type:** REFACTOR

**Source:** work-003-state-schema -> delivery-001

**Depends on:** -- (none)

**Scope:**
- **Validate first — the reference is NOT uniformly dangling.** Two forms of a
  "`§6` / `section-6` quality gates" reference exist across the repo. Some are **dangling** (a
  standing line such as `All §6 quality gates pass` copied into an artifact that has no numbered
  §6 — e.g. a lite SPEC / DETAIL / BLUEPRINT). Others are **legitimate** references to a real
  defined concept and MUST NOT be touched — e.g. `canonical/aid/templates/knowledge-summary/authored-visual-catalog.md`
  ("The section-6 quality gates validate every authored visual for:"), the `shortcut-engine.md`
  meta-doc lines that describe the standing line, `aid-plan/references/first-run-loop.md`, and the
  `migrate-work-hierarchy.sh`/`.ps1` writer scripts. Enumerate every occurrence and classify each
  as dangling vs legitimate, with evidence.
- **Normalize ONLY the genuinely-dangling standing lines** to a non-dangling form
  (`All applicable quality gates pass (per .aid/settings.yml)`). Leave every legitimate reference
  byte-unchanged. Edit the **canonical** sources (`canonical/aid/templates/...`,
  `canonical/skills/...`) — NOT the generated `.claude/aid/...` mirror.
- If validation shows every remaining occurrence is legitimate (nothing genuinely dangling),
  close the fix as **Not Applicable** with the classification evidence.
- Render: run `python .claude/skills/generate-profile/scripts/run_generator.py`, resync the
  dogfood `.claude/`, and confirm `tests/canonical/test-dogfood-byte-identity.sh` passes.

**Acceptance Criteria:**
- [ ] Every `§6`/`section-6` quality-gate occurrence is enumerated and classified dangling-vs-legitimate with evidence (traces to BLUEPRINT gate criteria #10).
- [ ] Only genuinely-dangling standing lines are normalized; legitimate references (authored-visual-catalog's real section-6, meta-doc descriptions, writer scripts) are left byte-unchanged — no blanket grep-replace (traces to BLUEPRINT gate criteria #10).
- [ ] `run_generator.py` re-rendered; `tests/canonical/test-dogfood-byte-identity.sh` passes.
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).

# Deploy & Monitor Re-purpose (G9/G10)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.1 (G9/G10), C-6, NFR-7, A-4 | /aid-define |

## Source

- REQUIREMENTS.md §5.1 (G9 — Deploy, G10 — Monitor)
- REQUIREMENTS.md C-6, NFR-7, A-4

## Description

Add a Lite-path direct-entry shortcut to the two existing Deliver-group pipeline skills:
`aid-deploy` (ship an artifact to its target environment/audience — promote, verify, rollback)
and `aid-monitor` (run, observe, and sustain a live asset — SLOs, observability, toil, capacity).
These are deliberate re-purposes, not new skills or renames: the shortcut entry must be added
without breaking either skill's current pipeline role.

## User Stories

- As an AID adopter who wants to ship or observe an asset directly, I want to invoke `aid-deploy`
  or `aid-monitor` as a shortcut so I get a scaffolded Lite work, while their existing pipeline
  role keeps working unchanged.

## Priority

Could

## Acceptance Criteria

- [ ] Given `aid-deploy` and `aid-monitor`, when the catalog is checked, then their shortcut
  entry exists with a valid `SKILL.md` state machine and the `aid-` prefix (re-purposed, not
  renamed). (AC-1 — G9/G10 subset)
- [ ] Given each re-purposed skill, when `aid-reviewer` reviews it, then it scores >= the resolved `minimum_grade` (A+)
  before shipping. (AC-7 — G9/G10 subset)
- [ ] Given the re-purpose, when `aid-deploy`/`aid-monitor` are used, then they keep their
  current Deliver-group pipeline role (shortcut entry added without breaking it) and
  `tests/run-all.sh` is green. (AC-9 — deploy/monitor role half)
- [ ] Given `/aid-describe`'s lite path is removed (feature-013), when `aid-monitor` classifies a
  finding, then it routes **BUG → `/aid-fix`** and **change-request → `/aid-triage`**, with no
  remaining reference to the removed `aid-describe`-lite — the **required A-9 re-point** (Must).
  (NFR-7 / C-6 / A-9 / AC-9)

---

## Technical Specification

> Grounded in `research/spec-grounding.md § Q-A9` (the dual-role hosting decision **and** the
> hidden `aid-monitor` → `aid-describe`-lite coupling). This feature has **two parts**: (b) the
> **REQUIRED cutover re-point** of `aid-monitor`'s routing (Must — not optional, per § Q-A9),
> and (a) the **Could** shortcut invocation-context mode-branch on the two existing skills.
> Both preserve the current Deliver-group pipeline role (NFR-7 / C-6).

> **Scope note:** part (a) is the **Could** shortcut invocation entry; part (b) — the
> `aid-monitor` re-point — is a **Must** required cutover step (§ Q-A9; authority NFR-7 / C-6 /
> AC-9 / the L9/L10 KB contract). A dedicated AC for the re-point has been **back-filled** into the
> `## Acceptance Criteria` list above (the BUG→`/aid-fix`, CR→`/aid-triage` routing criterion).

### Part (b) — REQUIRED cutover: re-point `aid-monitor` routing (Must)

Today `aid-monitor` routes findings **directly at `aid-describe`'s lite/triage**, which
feature-013 removes. Once `aid-describe` is full-only, that target is gone, so the routing must
re-point: **BUG → `/aid-fix`** (feature-008's bare G6 shortcut) and **Change Request →
`/aid-triage`** (feature-014's router). The classification vocabulary (`BUG` / `CHANGE REQUEST`
/ `INFRASTRUCTURE` / `NO ACTION`) in `references/state-classify.md` is **unchanged** — only the
routing *targets* change.

**Exact edits (canonical):**

| File (durable anchor) | Edit |
|---|---|
| `canonical/skills/aid-monitor/SKILL.md` `description:` (frontmatter) | "route findings to aid-describe (bugs via its lite bug-fix triage; change requests as new/changed requirements)" → "route findings — bugs to `/aid-fix`, change requests to `/aid-triage`" |
| `canonical/skills/aid-monitor/SKILL.md` `## Agents Involved` → **Routing targets** | "BUG classification → re-enters at `aid-describe` (lite bug-fix triage)…" → "BUG → `/aid-fix` (creates + implements the fix work)"; "Change Request → re-enters at `aid-describe` as new/changed requirements" → "Change Request → `/aid-triage` (routes to the right entry)" |
| `canonical/skills/aid-monitor/references/state-route.md` `§ Step 4` proposal lines | `→ Proposed: Route to aid-describe (LITE-BUG-FIX triage)…` → `→ Proposed: Route to /aid-fix`; `→ Proposed: Route to aid-describe → new/changed requirements` → `→ Proposed: Route to /aid-triage` |
| `canonical/skills/aid-monitor/references/state-route.md` `§ Step 5 Act` blocks | rewrite the **BUG → aid-describe (LITE-BUG-FIX short path)** block to **BUG → `/aid-fix`** (hand the diagnosis — root cause, patch scope, test requirements — to `/aid-fix`, which scaffolds + implements the fix); rewrite the **CHANGE REQUEST → aid-describe** block to **CHANGE REQUEST → `/aid-triage`** (hand the desired change + evidence to `/aid-triage`, which suggests the right entry) |
| `canonical/skills/aid-monitor/README.md` | classification→route table + the "Act" bullet: `BUG | aid-describe` → `BUG | /aid-fix`; `Change Request | aid-describe` → `Change Request | /aid-triage`; drop "lite bug-fix triage" prose |

**KB lockstep (in-scope, per § Q-A9 — a behavioral contract the routing implements, not mere
prose):** `.aid/knowledge/pipeline-contracts.md § Feedback Loop Contracts`, rows **L9** and
**L10** — `L9 Monitor -> Describe (bug) | finding classified BUG -> LITE-BUG-FIX` becomes
`L9 Monitor -> Fix (bug) | finding classified BUG`; `L10 Monitor -> Describe (CR)` becomes
`L10 Monitor -> Triage (CR)`. Update in lockstep with `state-route.md` so the KB and the skill
agree. (Descriptive KB lines that name the removed `TRIAGE` state — `architecture.md § Phase
Boundaries` "Triage | aid-describe TRIAGE state; aid-monitor classify", the `artifact-schemas.md`
Triage STATE row — are **flagged KB follow-up**, coordinated with the feature-002/013 KB churn.)

**Dependencies for part (b):** feature-013 (removes the old target), feature-014 (provides
`/aid-triage`), feature-008 (provides `/aid-fix`). This is the § Q-A9 cutover coupling — the
re-point can only land after all three exist, i.e. in the cutover wave.

### Part (a) — Could: shortcut invocation-context mode-branch

Add a thin **mode-branch at the top** of each existing skill (per § Q-A9 recommendation) so one
skill directory hosts two opposite-lifecycle roles without breaking either:

- **`work-NNN` argument present** ⇒ the **existing pipeline path** runs unchanged
  (`aid-deploy`: `IDLE -> SELECTING -> VERIFYING -> PACKAGING -> DONE`, post-Execute; `aid-monitor`:
  `OBSERVE -> CLASSIFY -> ROUTE -> DONE`, post-deployment). NFR-7 / C-6 — byte-preserved role.
- **no `work-NNN` argument + a free-form description** ⇒ the **shortcut-scaffold path**: bind
  `VERB=deploy` (G9) / `VERB=monitor` (G10), delegate to the shared **shortcut-engine**
  (`canonical/aid/templates/shortcut-engine.md`, feature-003), scaffold a flattened lite work
  (feature-001 structure), run the grading gates (feature-004), and halt at the FR-10 approval
  gate. Never executes.

**Files (part a):**

| File | Change |
|---|---|
| `canonical/skills/aid-deploy/SKILL.md` | add the invocation-context detection to `## Arguments` / `## Pre-flight` (branch to shortcut-engine vs the existing pipeline states); the five pipeline states + their reference docs are untouched |
| `canonical/skills/aid-monitor/SKILL.md` | same mode-branch (shortcut-scaffold vs the OBSERVE/CLASSIFY/ROUTE pipeline); pipeline states untouched (and carry the part-(b) routing edits above) |
| `canonical/aid/templates/shortcut-catalog.yml` (feature-003) | the `aid-deploy` / `aid-monitor` rows need a `repurpose: true` marker — see the code contradiction below |

### Code contradiction to reconcile (feature-003 ↔ feature-012)

feature-003's `shortcut-catalog.yml` lists **45 canonical shortcuts including `aid-deploy` and
`aid-monitor`**, and its `build-shortcut-skills.py` emits **thin doorway** dirs plus a
**catalog↔dirs parity test** asserting each row's `SKILL.md` body "binds the row's `{verb,
artifact}`" (thin shape). But `aid-deploy`/`aid-monitor` are **pre-existing FAT skills** with
full pipeline state machines that this feature hand-edits — they are *not* generated thin
doorways. Reconcile by:

1. adding `repurpose: true` (or `generated: false`) to the `aid-deploy` / `aid-monitor` catalog
   rows;
2. making `build-shortcut-skills.py` **skip** repurpose rows (never generate/overwrite those two
   dirs — doing so would clobber the pipeline role, violating C-6);
3. relaxing feature-003's parity test to assert only *dir-exists + name-match + `aid-` prefix*
   for repurpose rows (not the thin-doorway body).

This must be agreed with feature-003; flag it in that feature's spec too.

### Testing strategy

- **Re-point (part b, canonical test):** `aid-monitor` `state-route.md` routes `BUG` → `/aid-fix`
  and `CHANGE REQUEST` → `/aid-triage` (fixture findings); no `aid-monitor` file (SKILL.md,
  state-route.md, README.md) references `aid-describe`, "lite bug-fix triage", or `LITE-BUG-FIX`
  (grep); `pipeline-contracts.md` L9/L10 targets updated in lockstep.
- **Pipeline-role no-regression (AC-9, part b + a):** with `work-NNN` present both skills run
  their existing pipeline states unchanged; `tests/run-all.sh` green.
- **Shortcut mode (part a, fixture):** no `work-NNN` + description scaffolds a flattened lite
  work and halts at approval (never executes); the catalog parity-test exemption for the two
  repurpose rows holds.
- **Grade:** `run_generator.py` renders both re-purposed skills to all 5 profiles; `render-drift`
  + dogfood byte-identity green (AC-6); `aid-reviewer` grades each ≥ A+ (AC-7 subset).

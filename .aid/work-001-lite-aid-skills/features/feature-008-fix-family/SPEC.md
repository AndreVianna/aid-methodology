# Fix Skill Family (G6)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.1 (G6), §5.4 | /aid-define |

## Source

- REQUIREMENTS.md §5.1 (G6 — Fix)
- REQUIREMENTS.md §5.4 (Naming scheme)

## Description

The G6 shortcut skill `aid-fix` (bare) for diagnosing and correcting a defect, regression,
incident, or vulnerability. It is invoked directly, enters the Lite path via the shared
direct-entry engine, and stays bare — with no artifact-suffixed variants.

## User Stories

- As an AID adopter with a known defect, I want to invoke `aid-fix` directly so I get a
  scaffolded Lite work for the diagnosis and correction without the interview.

## Priority

Must

## Acceptance Criteria

- [ ] Given `aid-fix`, when the catalog is checked, then it exists in `canonical/skills/` with a
  valid `SKILL.md` state machine and the `aid-` prefix. (AC-1 — G6 subset)
- [ ] Given `aid-fix`, when invoked, then it stays bare with no artifact-suffixed variants.
  (AC-4 — fix-bare)
- [ ] Given `aid-fix`, when `aid-reviewer` reviews it, then it scores >= the resolved `minimum_grade` (A+) before shipping.
  (AC-7 — G6 subset)

---

## Technical Specification

> Family-specific content on top of the settled shortcut engine (feature-003). `aid-fix` is a thin
> doorway binding `{verb=fix, artifact=""}` and delegating to
> `canonical/aid/templates/shortcut-engine.md` (writes feature-001's flattened work, runs
> feature-004's gates). This feature contributes one catalog row + the fix scaffolding reference.

### Catalog rows owned (AC-1 — G6 subset)

**One canonical skill, bare, no aliases, no artifact suffixes ⇒ 1 `canonical/skills/aid-fix/SKILL.md`
directory.** `aid-fix` stays bare per §5.4 (the fix-kind is a captured slot, not a separate skill):

| `name` | verb | artifact | alias_of | group |
|---|---|---|---|---|
| `aid-fix` | fix | `""` (bare) | null | G6 |

### Per-skill binding & default-type (feature-003 A-6 mapping)

There is **no `FIX` value in the closed 8-type enum**, so a fix's patch task is typed
`IMPLEMENT` (**fix-as-IMPLEMENT** per feature-003; enum unchanged — extending it is a lockstep
break, `artifact-schemas.md § Contracts`):

| Skill | `default_type` | Multi-type task set |
|---|---|---|
| `aid-fix` | `IMPLEMENT` | `IMPLEMENT` (reproduce + root-cause + patch) + `TEST` (regression test) |

### Scaffolding knowledge (`canonical/aid/templates/shortcut-scaffolding/fix.md`)

Grounded in the `fix-*` recipes (`fix-application`, `fix-security`, …) and
`digital-project-activities.md § 6` (corrective maintenance; incident response; respond-to-
vulnerability RV). Because `aid-fix` is bare, a **`fix-kind` slot** tunes the breakdown rather than a
suffix.

**CAPTURE slots (min):** symptom / bug title; reproduction steps; expected vs. actual behavior;
`fix-kind` (`defect` \| `regression` \| `incident` \| `vulnerability`); affected area (inferred from
repro where possible).

**Default task-breakdown** (a richer, correctly-typed split of the legacy single-task `fix-*`
recipe, which folded the test into the `IMPLEMENT` task — the regression test is now its own `TEST`
task):

- `task-001` IMPLEMENT — "Reproduce, root-cause, and patch {bug}".
- `task-002` TEST — "Regression test that **fails on pre-fix code and passes on post-fix code**"
  (the `fix-application` AC), depends on `task-001`.

**`fix-kind` adaptations** (SPEC-section activation + task tuning):

| fix-kind | SPEC section | Task adaptation |
|---|---|---|
| `defect` (default) | base `Feature Flow` | as above |
| `regression` | base + note the regressing change | repro pinned to the regressing commit/change |
| `vulnerability` | `### Security Specs` | `task-002` TEST proves the **exploit path is closed** (`fix-security` shape); deep SAST/DAST or dependency audit → route to `aid-test-security` |
| `incident` | base | the mitigation code stays in `aid-fix`; the **postmortem / runbook doc routes to `aid-document-runbook`** |

### Ownership boundary

`aid-fix` owns **corrective** work (a defect/regression/incident/vulnerability). It emits its own
regression `TEST` task (coverage scoped to proving *this* defect closed) — a broad test-authoring
request is `aid-test`. A change that is **not** a defect (new behavior / intent) is `aid-change`; a
behavior-preserving cleanup is `aid-refactor`. The security **remediation** is `aid-fix`, but
security **verification** (SAST/DAST/fuzz/audit) is `aid-test-security`; the **postmortem/runbook**
is `aid-document-runbook`; infra provisioning to close an incident is `aid-change-infra`.

### Layers & Components (canonical files)

| File | Change |
|---|---|
| `canonical/aid/templates/shortcut-catalog.yml` | **add 1 row** (`aid-fix`) |
| `canonical/aid/templates/shortcut-scaffolding/fix.md` | **new** — the fix scaffolding reference (fix-kind slot + adaptations above) |
| `canonical/skills/aid-fix/SKILL.md` | **generated** by feature-003's `build-shortcut-skills.py` — not hand-written |

No family-specific engine branch. Renders via the full `run_generator.py` to all five profiles
(NFR-1, AC-6). `aid-fix` is in the Phase-2 pilot cohort (REQUIREMENTS § 10).

### Testing strategy

- **Family scaffold proof** (canonical fixture): `aid-fix` on a `vulnerability` description produces
  a flattened work with `### Security Specs` activated and `tasks/` `001` IMPLEMENT →
  `002` TEST (exploit-closed), halting pre-Execute (FR-10). A `defect`-kind fixture asserts the
  base 2-task shape and that `aid-fix` stays bare (AC-4 — fix-bare).
- **Catalog↔dirs parity** + `render-drift` cover the row/dir (feature-003's tests; AC-1/AC-6).

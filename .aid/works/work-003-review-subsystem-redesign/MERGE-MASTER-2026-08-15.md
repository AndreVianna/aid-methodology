# Merge master into work-003 — completed

**Date:** 2026-08-15  
**Branch:** `work-003`  
**Merge:** `origin/master` into `work-003` — **complete**.

**Owner decision:** master is the base. Fold work-003 into it; do not rebuild around the old branch.

---

## 1. Conflict count (re-measured)

| Metric | Value | Command |
|---|---|---|
| work-003 unique commits | 124 | `git log --oneline origin/master..HEAD \| wc -l` (pre-merge) |
| master ahead | 302 | `git log --oneline HEAD..origin/master \| wc -l` (pre-merge; brief said 251) |
| Conflicts at merge start | **204** | `git diff --name-only --diff-filter=U \| wc -l` |

### By category → resolution

| Category | Count | Resolution |
|---|---|---|
| `profiles/` / `.claude/` / `.cursor/` | 143 | Took master; regenerate from canonical |
| `site/` / `docs/` / `README.md` | ~31 | Took master |
| `.aid/knowledge` inventory (not cascade doc) | 7 | Took master |
| Skill-count tests | 2 | Accepted master’s deletion |
| State templates `.md` | 2 | Accepted master’s rename → `.yml` |
| **Review design (11 files)** | **11** | **Took master** (owner decision) |

Design files taken from master:

```
.aid/knowledge/authoring-conventions.md
canonical/agents/aid-reviewer/AGENT.md
canonical/aid/templates/kb-authoring/review-rubric.md
canonical/aid/templates/reviewer-dispatch.md
canonical/aid/templates/reviewer-ledger-schema.md
canonical/skills/aid-{define,detail,discover,execute,plan,specify}/references/reviewer-brief.md
```

---

## 2. Decisions (owner-confirmed)

| # | Choice | Meaning |
|---|---|---|
| **1** | Cascade wins | `review-criteria:` is SoT. Rubric catalog content may be folded in later as criteria rows — catalog is not a second loader. |
| **2** | Master dispatch wins | Keep VERIFY/HUNT + cost meter in `reviewer-dispatch.md`. Do not gut it for `reviewer-brief-template.md`. |

---

## 3. Still on the branch from work-003 (not deleted yet)

These auto-merged as additions. They are **not** the active review path after this merge. Next work retires or folds them:

- `canonical/aid/templates/review-rubrics/` (10 files)
- `canonical/skills/aid-deep-review/`, `aid-light-review/`
- `canonical/aid/templates/reviewer-brief-template.md`
- review scripts: `check-gaps`, `gap-register`, `plan-resume`, `writeback-ledger`, plus `lint-modality`, `lint-settings`, `emit-summary-findings`

---

## 4. delivery-028 re-measure

| Metric | On branch after merge | origin/master (pre) |
|---|---|---|
| `review-rubrics/*.md` | 10 (present but demoted) | 0 |
| `Step 2` lines | 48 | 0 |
| `Severity` still in all 10 rubrics | yes — headline change still unimplemented | n/a |

---

## 5. Unexecuted deliveries (re-baseline)

| Class | IDs |
|---|---|
| STILL VALID | 014–016, 018, 020–021, 023–027 |
| CONFLICTS → re-scope | 013, 017, 019, 028 |
| OBSOLETE | 022 (master already has `/aid-review`) |
| Gated, finish after replan | 013–015 |

---

## 6. Next (in order)

1. Regenerate install trees (`generate-profile`).
2. Re-plan CONFLICTS/OBSOLETE deliveries against cascade + VERIFY/HUNT.
3. Fold useful rubric-catalog checks into `review-criteria:` (or drop).
4. Retire deep/light + brief-template + unjustified scripts (NFR-2 + cost meter).
5. Still do: severity-as-judgment; clean-context measurement.

# Implementation Sequencing — work-005

> How the 8 locked specs become `canonical/` changes. One branch
> (`work-005-lite-skills-refactor`), **one family at a time**: edit → regenerate →
> verify rendered output → backward-compat check → commit.

---

## Hard rules

- **Backward-compat is non-negotiable.** Every shipped skill name must still resolve —
  as a canonical row or a hint-alias. We remove **nothing** (net +14 new, 0 removed). Verify
  per family (§Backward-compat).
- **Local test hazards (do NOT run locally):** the full bash suite, `test-dashboard-parity.sh`,
  and port-binding server tests hang on this Windows/MSYS box. Regenerate locally
  (`run_generator.py`) and **verify by reading the rendered output**; defer byte-identity /
  parity / full-suite to **CI** (shallow clone — no history-dependent tests).
- **Dogfood resync every time:** after `run_generator.py`, resync repo-root `.claude/` from
  `profiles/claude-code/` (`test-dogfood-byte-identity` enforces it).
- **Pre-existing uncommitted repo changes** (`CLAUDE.md`, `.aid-manifest.json`,
  `.aid-version`, deleted `knowledge-base/README.md`) stay **untouched** — not ours.

## Phase 0 — foundational decision (blocks the collapse families)

The six collapse skills (review, research, report, document, prototype, `aid-test`-run) share
one single-shot skeleton: `INTAKE → produce → clean-context VERIFY → PRESENT → [publish/place]
→ DONE`, plus the standalone-STATE convention (normal work-state template, `phase` not driven),
grounding enforcement, present-before-commit gate, printed handoffs, per-call tiering.

**Decision — RESOLVED 2026-07-15: per-skill hand-authored bodies** (the `aid-query-kb`
model). No shared collapse-engine. Each collapse `SKILL.md` is self-contained and follows a
common pattern — nothing delegates at runtime. The **`review` pilot's `SKILL.md` is the
template** the other five collapses (research, report, prototype, `aid-test`-run, and the
document/dashboard collapse bodies) are modeled on; keep them consistent by copying its
shape, not by referencing it.

## Order (one family at a time)

| # | Family | Why here | Risk |
|---|---|---|---|
| 1 | **review / audit** (pilot) | proves the whole loop once (collapse-engine + repurpose flip + hand-authored body + regen + dogfood resync + compat + triage); core present-findings first, live PR/ticket publish as a follow-up increment | med |
| 2 | research / investigate / spike | collapse; `aid-researcher` + authorized-spike | med |
| 3 | report | collapse; delta from research | low |
| 4 | prototype (+ `-ui` hint) + **new `aid-design`** | collapse; light vs full verify | med |
| 5 | **document** restructure | new `create`/`change-document` artifact + 8 genre hints + `create-diagram`; `aid-tech-writer`; KB boundary | high |
| 6 | **test** restructure | `create`/`change-test` (engine rows) + `aid-test` run (collapse) + `test-*` hints; scaffolding split | high |
| 7 | experiment | content-only scaffolding edit; no engine/topology change | low |
| 8 | dashboard reframe | `create`/`change-dashboard` + `show-dashboard` hint; keep-cycle, naming only | low |

Rationale: collapses first (build & prove the shared engine on the pilot, then repeat), simple
→ hard; the restructures (document, test) after the engine is proven; **experiment (7) and
dashboard (8) are low-risk and may be pulled earlier if a quick win is wanted** — experiment
touches only `test-experiment.md`, dashboard is pure rename + hint-alias.

## Per-family recipe

1. **Edit canonical** — `shortcut-catalog.yml` rows (`repurpose` / new / hint-alias); skill
   bodies (hand-authored collapse doorways, or new engine-driven create/change rows);
   scaffolding; `shortcut-engine.md` detach where the family leaves the engine.
2. **`build-shortcut-skills.py`** — confirm it skips the `repurpose` rows and (re)generates the
   engine-driven ones.
3. **`run_generator.py`** (full — never a partial render).
4. **Resync dogfood** `.claude/` from `profiles/claude-code/`.
5. **Verify RENDERED output** — read the generated `SKILL.md` in `profiles/claude-code/` *and*
   dogfood `.claude/`, not just canonical (the fix must survive the transform).
6. **Backward-compat** — every old name of this family resolves (canonical or hint-alias);
   `/aid-triage` still recognizes it.
7. **Commit** on `work-005`.

## CI checkpoints

Push per family (or per small batch) and let **CI** run the heavy suites (byte-identity,
canonical-parity, dashboard-parity). `test-dogfood-byte-identity` is the one most likely to
catch a missed resync.

## Backward-compat matrix (final gate)

All must still resolve after everything lands:
`aid-review`, `aid-audit`; `aid-research`, `aid-investigate`, `aid-spike`; `aid-report`;
`aid-experiment`; `aid-document` + the 7 kinds; `aid-prototype`, `aid-prototype-ui`;
`aid-test`, `aid-test-security`, `aid-test-performance`, `aid-test-data-quality`;
`aid-show-dashboard`; and every unchanged create/change/add/update/fix/refactor/remove/
deprecate/migrate name.

# Work State -- work-012-kb-review-surface

> **State:** Executing — review-surface fix applied + verified; on work-012 branch (v2.0.5)
> **Phase:** Execute
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-07-05
> **User Approved:** yes

Scoped, user-approved fix (v2.0.5): meta process/ledger files were contaminating the
/aid-discover REVIEW and poisoning grades. Verified true (by code inspection): the M3
(Essence) and M4 (Assertiveness) **keystone** gates — which force grade ≤ D — read a raw
`.aid/knowledge/*.md` glob with no `kb-category` filter, so they ingested `STATE.md`,
`README.md`, and `external-sources.md` (all `kb-category: meta`) as if they were project
knowledge. M1/M2 already route by `kb-category` (meta → Spot-Check only); the gap was at
M3/M4.

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none (direct-prompt fix)
- **Updated:** 2026-07-05

---

## Triage

- **Path:** lite
- **Work Type:** bug-fix
- **Sub-path:** LITE-BUG-FIX
- **Decision rationale:** Scoping defect in the discover review dispatch; deterministic fix, no schema change; v2.0.5.
- **Override:** no

---

## Root cause (verified)

- `reviewer-prompt-teachback.md` (M3) and `reviewer-prompt-actback.md` (M4) both instruct:
  *"use ONLY the KB documents (`.aid/knowledge/*.md`)"* — a glob with NO `kb-category` filter.
- On disk, `.aid/knowledge/` holds three `kb-category: meta` docs (`STATE.md`, `README.md`,
  `external-sources.md`) + one generated doc (`INDEX.md`, `source: generated`). The glob
  sweeps all of them into the keystone gates.
- M1/M2 are NOT affected (they route by `kb-category`: meta → Spot-Check Snapshot).
- NOT affected: `kb.html` (`.aid/dashboard/`), `knowledge-summary.html` (`.html`, glob is
  `*.md`), `CLAUDE.md`/`AGENTS.md` (repo root — not in the glob; M1 ranks them tier-2
  non-authoritative; M3 Stage-1 excludes "system knowledge outside the KB"), `project-index.md`
  / `candidate-concepts.md` (`.aid/generated/`; also name-excluded by M3/M4).

## Fix (deterministic, tag-driven)

1. **`list_reviewable` accessor** added to `doc-set-resolve.md`: globs `.aid/knowledge/*.md`,
   keeps `kb-category != meta` AND `source != generated` (the hand-authored knowledge
   surface). Excludes STATE/README/external-sources (meta) + INDEX (generated). One batched
   awk pass, portable (no `nextfile`/`ENDFILE`), `LC_ALL=C`, no-frontmatter → default
   reviewable (surface never shrinks below primary).
2. **`state-review.md`**: pre-dispatch computes `REVIEW_SURFACE=$(list_reviewable .aid/knowledge)`
   and passes that explicit list to M3/M4 instead of the raw glob; both M3/M4 clean-context
   rules reworded to the reviewed-knowledge surface.
3. **M3/M4 prompts** reworded off the glob → reviewed-knowledge surface; excluded meta/generated
   named explicitly.
4. **M2 authoring-check scope** clarified: apply to Full Primary docs only (not every `.md`).
5. **M3 Stage-1 hardening**: explicitly disregard ambient `CLAUDE.md`/`AGENTS.md` context
   (residual: harness may inject them into the reviewer sub-agent, softening blind reconstruction).
6. **`build-project-index.sh`** default output realigned `.aid/knowledge/` → `.aid/generated/`
   (stale default; pipeline already passes `--output .aid/generated/…`; byte-identical with
   `--output`). Belt-and-suspenders so a generated index can never sit in the review surface.

Observation (surfaced, not fixed here): `external-sources.md` is tagged `kb-category: meta`
on disk, but `doc-set-resolve.md` says that is a *mis-tag* (it should be `primary`). The
filter is tag-driven, so it excludes external-sources as-tagged; if the tag is later
corrected to `primary` it would be included. Correcting that tag is a separate, debatable
call (is a citations doc part of essence review?) — left as tech-debt.

## Verification

- New `tests/canonical/test-kb-review-surface.sh` 6/6: keeps primary+extension, excludes
  meta (STATE/README/external-sources) + generated (INDEX), no-frontmatter defaults reviewable,
  deterministic. Extracts the canonical `list_reviewable` from `doc-set-resolve.md` (drift guard).
- `build-project-index.sh` byte-identical to master when `--output` is passed (pipeline path).
- (pending) 5 profiles regenerated + dogfood resynced; full canonical suite + dogfood byte-identity.

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-05 | Work created | -- | Other agent observed meta files (STATE.md) poisoning /aid-discover review grades. Verified true by code inspection: M3/M4 keystone gates read `.aid/knowledge/*.md` glob with no kb-category filter → ingest STATE/README/external-sources (meta) + INDEX (generated). M1/M2 already route by kb-category. Investigated the full contaminator set incl. CLAUDE.md/AGENTS.md (ambient, already handled) + kb.html/knowledge-summary.html (HTML, not caught by *.md glob). |
| 2026-07-05 | Implemented + verified | -- | Added `list_reviewable` (kb-category!=meta AND source!=generated), wired M3/M4 in state-review to the computed surface, reworded M3/M4 prompts, clarified M2 authoring scope, added M3 CLAUDE.md/AGENTS.md Stage-1 hardening, realigned build-project-index default output to .aid/generated/. New test-kb-review-surface.sh 6/6; build-project-index byte-identical (--output). Pending: regen + dogfood + full suite + v2.0.5. |

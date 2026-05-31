# task-008: De-hardcode the 14/16 literals (D1–D16) + data-driven agent-to-file mapping

**Type:** IMPLEMENT

**Source:** feature-004-declared-doc-set → delivery-002 (CORE wave)

**Depends on:** task-007

**Scope:**
- Apply the D1–D16 replacements from the F4 SPEC: `SKILL.md` (~L144–151/322/269–274), `state-generate.md` (~L3/8/9/67–72/118–122/131/176), `state-review.md` (~L3/11), `build-kb-index.sh:169` label, `knowledge-base/README.md:73`. Every "14"/"16"/hardcoded-name-list is swapped for a declared-set reference (the resolve accessors from task-007).
- Implement mapping-honors-declared-set (FR-P1-6): `state-generate.md` Steps 2–5 dispatch is computed from `owns-<agent> ∩ missing-on-disk`; empty list ⇒ agent not dispatched (no-hang on omission); an added doc ⇒ appears in its owner's list (dispatch on addition); the Verify step confirms `count == size(list-filenames)` + a name cross-check.
- Confirm the F2 reviewer pointer (task-003) was not reintroduced as a count literal (cross-cutting risk #3).
- Re-render with `python run_generator.py`.
- **Sizing note:** this is the largest task. If it overruns one session, split at the documented seam — 008a = literal de-hardcoding in read-only docs (SKILL D1–D5, build-kb-index D15, README D16, state-review D13–D14); 008b = `state-generate.md` D6–D12 + the §2.5 dispatch rewrite. Keep whole otherwise.

**Acceptance Criteria:**
- [ ] No "14"/"16" doc-count literal remains in `SKILL.md`, `state-generate.md`, `state-review.md`, `build-kb-index.sh`, `README` (grep clean); each site is a declared-set reference per the D1–D16 table.
- [ ] `state-generate.md` dispatch is data-driven from the resolve accessor: an omitted doc ⇒ no dispatch + count drops; an added doc ⇒ dispatched to its owner + count rises.
- [ ] For the default seed, the resolved dispatch set equals today's behavior (backward compatible).
- [ ] All §6 quality gates pass (render-drift clean, 13 suites green, generator self-tests).

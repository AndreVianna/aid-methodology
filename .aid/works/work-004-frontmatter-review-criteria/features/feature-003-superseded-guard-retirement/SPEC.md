# Superseded Guard Retirement

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Feature identified from REQUIREMENTS.md §4 stream 3 + deferred front-face bucket | /aid-define |

## Source

- REQUIREMENTS.md §2 (what stands in its place), §4 (stream 3; Out of Scope — deferred front-face bucket)
- REQUIREMENTS.md §6 NFR-2, NFR-4; §9 AC-3, AC-4, AC-6; §8 C-7

## Description

The declarations now exist and are read. This feature removes what was standing in for them, and
closes the work by aligning the surfaces a user reads.

**It derives its own removal set before removing anything.** REQUIREMENTS.md deliberately asserts no
inventory: an earlier draft listed six scripts totalling 2,816 lines, four of which do not exist on
this branch at all. Asserting an underived number is the defect this work exists to remove, so the
first task here is to enumerate — from disk — every script whose job is to check a fact stated in
prose, and for each one name the declaration that now covers it.

The verified archetype is `tests/canonical/check-skill-counts.mjs`: **379 lines** whose entire
purpose is to find count claims written in prose and compare them against the corpus. That is a
`contracts:` line wearing a script costume — it encodes one fact-check in code and can be wrong
about the fact.

Two named non-candidates, so the sweep does not over-reach:

- **`canonical/aid/scripts/kb/kb-citation-lint.sh`** (70 lines) checks citation *form*, not a prose
  fact. No declaration replaces it, and CI invokes it. It stays.
- **`tests/canonical/test-dogfood-byte-identity.sh`** sha256s the two tracked dogfood trees against
  the render manifest. That answers *"was the generator re-run"* — a build question, not a review
  question. It stays, and REQUIREMENTS.md §4 puts it explicitly out of scope.

The feature then closes the work:

- **The front face**, deferred by owner decision to the very end because it describes trees that
  were still moving: `docs/*.md` (7 files), the repo-root `README.md` (257 lines), and
  `examples/**/README.md` (4 files, 1,237 lines — of which `brownfield-full-path` and `greenfield`
  have zero inbound references).
- **The single render**, per C-2 and NFR-4: `canonical/` → `profiles/` → the two tracked dogfood
  trees, run once, here, after the source has stopped moving.
- **The exit arithmetic**: removed guard lines minus added mechanism lines, stated as a number. The
  confirmed floor is 2,181 — 1,802 from the deleted READMEs plus 379 from `check-skill-counts.mjs`.
- **The C-7 audit**: `imports-from-work-003.md` is reviewed, confirming nothing crossed from
  `work-003` except through its six gates.

## User Stories

- As an AID user, I want a fact stated once where it lives rather than re-encoded in a script that
  can be wrong about it, so that there is one thing to keep true instead of two.
- As an AID user, I want to be told which check was removed and what replaced it, so that "we
  deleted the tests" is a claim I can audit rather than trust.
- As an AID user, I want the README and docs to describe what the project actually is now, so that
  the first thing I read is not the most out-of-date thing in the repo.
- As an AID user, I want the work to end with less enforcement machinery than it started, so that
  the fix for over-engineering is not itself over-engineering.

## Priority

Must

## Acceptance Criteria

- [ ] Given stream 3 begins, when the removal set is decided, then it was **derived from this
      branch's disk** and no file is removed on the strength of an inherited inventory (AC-3).
- [ ] Given each removed check, when it is removed, then the declaration now covering it is named —
      a removal with no named replacement is not permitted.
- [ ] Given `kb-citation-lint.sh` and `test-dogfood-byte-identity.sh`, when the sweep runs, then both
      survive it, for the reasons recorded above.
- [ ] Given the removals and additions across all three features, when the work closes, then removed
      guard lines **exceed** added mechanism lines, stated as a number (AC-4, NFR-2).
- [ ] Given the deferred front-face bucket, when this feature completes, then `docs/`, the root
      `README.md` and `examples/**/README.md` describe the trees as they now are.
- [ ] Given C-2 and NFR-4, when the work closes, then the render chain has been refreshed **exactly
      once**, here — and `tests/canonical/test-dogfood-byte-identity.sh` passes against it.
- [ ] Given `imports-from-work-003.md`, when the work closes, then every entry passes all six C-7
      gates, and no commit, cherry-pick or file copy from `work-003` appears anywhere in the branch
      (AC-6).
- [ ] **Proof (AC-2, method per NFR-1):** given a check removed in this feature, when a defect of the
      class it used to catch is planted in a disposable worktree, then a real review reports it via
      the declaration that replaced it. A removal whose replacement cannot catch the defect is a
      regression, not a retirement.

---

## Technical Specification

*(Added by /aid-specify — do not fill during interview.)*

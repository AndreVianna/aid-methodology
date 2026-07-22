# Delivery BLUEPRINT -- delivery-001: release-aid Maintainer Release Skill

> **Delivery:** delivery-001
> **Work:** work-021-release-aid-skill
> **Created:** 2026-07-22

---

## Objective

Formalize `release-aid`, a repo-local maintainer-only skill that executes the AID repo's
own release process end-to-end — `/release-aid <level>` (`major|minor|patch|beta`) — from
the command to artifacts published on every channel with all checks green, pausing only
at the three irreversible human-gated points (PR merge, tag push, publish confirmation).
This is a single coherent unit because the value is the whole procedure: version math,
preconditions, carrier bumps, the mandatory release-notes + documentation sweep, the PR,
the dry-run, the tag, and per-channel verification interlock into one release. The skill
closes the gap the static spec (`infrastructure.md`) and partial runbook (`docs/release.md`)
leave open — nothing previously enforced updating the notes or auditing the docs, so both
drifted.

## Scope

- The `.claude/skills/release-aid/SKILL.md` skill: the RESOLVE → PRECHECK → BUMP →
  DOCS+NOTES (3.1 ledger + 3.2 doc sweep) → PR → DRY-RUN → TAG → VERIFY → CONFIRM →
  close-out sequence (Steps 0–9), the version-math table (incl. patch-from-beta promote),
  the four version carriers + beta npm exemption, the beta-vs-stable channel matrix, the
  three human-gated pauses, and the gotchas — mirrored in SPEC.md.
- Validation of the skill via a real dry-run of `release.yml` (no publish).
- The one-time reconciliation of the pre-existing broken ledger + doc backlog
  (`v2.1.0`–`v2.2.3-beta.1` sections, the stale `## Unreleased` items, the frozen README,
  and `infrastructure.md`'s stale npm/PyPI-disabled claim) — the debt the skill's Step 3
  prevents going forward (OD-1 resolved: the separate one-time task-003, run now).

**Out of scope:** modifying the release CI (`release.yml`), `release.sh`,
`check-version-sync.sh`, or any release infrastructure (the skill *drives* it, does not
change it); shipping the skill to adopters (never in `canonical/` / `profiles/` / a
tarball); authoring adopter-project changelogs (that is `aid-document-changelog`);
automating any of the three human-gated steps.

## Gate Criteria

Each criterion maps a SPEC AC to a concrete, testable check. Because the skill is a
markdown procedure (not code), verification is primarily by reading `SKILL.md`
against the AC, plus the task-002 dry-run exercising the mechanical steps.

- [ ] **GC-1 (AC-1 / FR-1)** — `SKILL.md` requires `<level>` and STOPs+asks on a
  missing/invalid value without reading `VERSION` or proceeding — verified by reading the
  "Argument — REQUIRED" section.
- [ ] **GC-2 (AC-2 / FR-2)** — The Step 0 version-math table + worked examples yield, from
  `VERSION` = `2.2.3-beta.1`: `beta`→`2.2.3-beta.2`, `patch`→`2.2.3` (promote),
  `minor`→`2.3.0`, `major`→`3.0.0`; and from stable `2.2.3`: `patch`→`2.2.4`,
  `beta`→`2.2.4-beta.1` — verified by reading Step 0 and re-deriving each example.
- [ ] **GC-3 (AC-3 / FR-3, NFR-2)** — Step 1 STOPs on each precondition failure (branch,
  clean tree, tag collision, red `test.yml`, render drift) and auto-cleans only
  `.aid/.aid-manifest.json` — verified by reading Step 1; the dry-run (task-002) exercises
  the gate/render-drift/version-sync checks green.
- [ ] **GC-4 (AC-4 / FR-4, NFR-5)** — Step 2 sets all three files for stable and only
  `VERSION` + `pyproject.toml` for beta (npm exempt), always SemVer `X.Y.Z-beta.N` (never
  PEP-440 `bN`) — verified by reading Step 2 + the CRITICAL beta-format note.
- [ ] **GC-5 (AC-5 / FR-5)** — Step 3.1 renames `## Unreleased`→`## v<target> - <UTC>`,
  opens a fresh `## Unreleased`, adds a `## Change Log` row, and reconciles a behind ledger
  before stamping — verified by reading Step 3.1.
- [ ] **GC-6 (AC-6 / FR-6, NFR-4)** — Step 3.2 audits + updates README, the affected KB
  docs (`capability-inventory`, `module-map`, `infrastructure`, `technology-stack`, …),
  `docs/`, and `site/src/content/docs/` (leaving the release changelog page — a sibling tree
  at `site/src/pages/releases/changelog.astro`, not under `content/docs/` — which is
  auto-sourced from GitHub Releases), routes
  methodology changes through `canonical/` + `generate-profile` (never `profiles/`), and
  carries the truthfulness guard — verified by reading Step 3.2 and confirming every listed
  surface + the guard is present.
- [ ] **GC-7 (AC-7 / FR-7, NFR-3)** — Step 4 commits Steps 2–3 on `release-<target>`
  (never `.aid/.aid-manifest.json`), verifies each PR check, PAUSEs to hand `gh pr merge`
  to the human, and switches/restores the `gh` account — verified by reading Step 4.
- [ ] **GC-8 (AC-8 / FR-8)** — Step 5 dispatches `release.yml` with `-f ref=master
  -f dry_run=true` and verifies each job green before tagging — verified by reading Step 5;
  the actual dry-run is task-002's acceptance.
- [ ] **GC-9 (AC-9 / FR-9)** — Step 6 PAUSEs for explicit confirmation before pushing the
  `v<target>` tag — verified by reading Step 6's ⏸ note.
- [ ] **GC-10 (AC-10 / FR-10)** — Step 7 inspects each job individually and encodes the
  channel matrix (stable: gate/github-release-latest/pypi/npm pass; beta:
  gate/github-release-prerelease-with-tarballs/pypi pass, npm-publish skipped) — verified
  by reading Step 7 + its expected-jobs table.
- [ ] **GC-11 (AC-11 / FR-11, NFR-3)** — Steps 8–9 confirm artifacts (PyPI `/simple/`;
  GitHub Release beta=prerelease-not-latest / stable=latest, asset list; npm for stable),
  restore `AndreVianna-Ross`, and report version/channels/URL + the notes/README update —
  verified by reading Steps 8–9.
- [ ] **GC-12 (AC-12 / FR-12)** — The Autonomy section states Steps 0–9 run without
  per-step check-ins except exactly the three ⏸ points — verified by reading the Autonomy
  section.
- [ ] **GC-13 (AC-13 / NFR-1)** — The skill is present only at `.claude/skills/release-aid/`,
  has no `aid-` prefix, and is absent from `canonical/skills/` and every `profiles/*/`
  tree — verified by `ls`/`git ls-files` over those paths.
- [ ] **GC-STD-1** — All tasks in delivery-001 are Done or Canceled — verified from the
  Tasks lifecycle table.
- [ ] **GC-STD-2** — All section-6 quality gates pass — verified by `grade.sh` over the
  delivery gate ledger.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Author the `release-aid` skill (`.claude/skills/release-aid/SKILL.md`) — the Step 0–9 sequence, version-math table, four carriers + beta npm exemption, channel matrix, three human-gated pauses, and gotchas. **Already authored/settled with the user; this task formalizes the existing artifact.** |
| task-002 | TEST | Validate the skill via a real dry-run of `release.yml` (`-f ref=master -f dry_run=true`, no publish) — exercises the preconditions, version-sync, render-drift, and per-channel packaging without releasing. Acceptance = a fully green dry-run run (each job inspected). |
| task-003 | DOCUMENT | One-time reconciliation of the pre-existing backlog (OD-1 resolved: run standalone, now — release on hold): add the missing `v2.1.0`–`v2.2.3-beta.1` ledger sections + drain the stale `## Unreleased` items in `release-tracking.md`; unfreeze the README to a "recent releases → changelog / GitHub Releases" pointer (OD-2 resolved: pointer only); correct `infrastructure.md`'s npm/PyPI-disabled claim. |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)
- **External prerequisites (for task-002 / a live run, not for this planning delivery):**
  `release.yml`, `release.sh`, `check-version-sync.sh`, the `generate-profile` skill, and
  `gh` authenticated with both `AndreVianna` and `AndreVianna-Ross`.

## Notes

- **Repo-local, never shipped.** Like `generate-profile`, `release-aid` lives only at
  `.claude/skills/release-aid/`; it is NOT in `canonical/skills/`, is NOT rendered to any
  `profiles/*` tree, carries no `aid-` prefix, and is never in a release tarball. It is
  edited directly (no canonical source to render from). This is a deliberate exception to
  the canonical-source pattern, not an oversight (NFR-1 / AC-13 / GC-13).
- **OD-1 (RESOLVED 2026-07-22 — separate one-time cleanup).** The pre-existing broken
  ledger backlog (`v2.1.0`–`v2.2.3-beta.1` + the stale `## Unreleased` items) is handled
  as the separate one-time **task-003**, run standalone **now** (release on hold); the
  skill does not auto-reconcile it on first run and only maintains the ledger going
  forward. task-003 is confirmed (no longer conditional).
- **OD-2 (RESOLVED 2026-07-22 — pointer only).** The 3.2 sweep keeps the README as a
  "recent releases → changelog / GitHub Releases" pointer with **no** version-specific
  "What's New" block. `SKILL.md` Step 3.2 + FR-6 state it definitively.
- Direct-authored flattened Lite work (fast path, owner-driven). The authoritative design
  is `.claude/skills/release-aid/SKILL.md`; detailed design is mirrored in
  SPEC.md § Technical Specification. Per-task `DETAIL.md` files are authored later
  (`/aid-detail`), not now.

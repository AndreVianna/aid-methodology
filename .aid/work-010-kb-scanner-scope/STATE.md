# Work State -- work-010-kb-scanner-scope

> **State:** In Review — fix applied + verified; on work-010 branch (PR pending)
> **Phase:** Execute
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-07-05
> **User Approved:** yes

Scoped, user-approved lite bug-fix: the two KB scanners walk the AID tool-install
("dogfood") trees at the repo root (`.claude/`, `.cursor/`, `.codex/`), which are
out of KB scope. This pollutes the term universe / project index and breaks
byte-reproducibility across AID updates. Fix: add those three dir names to the
shared `SKIP_DIRS` prune set in both scripts (kept in lockstep), alongside the
`.aid` prune that already exists for the same reason.

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
- **Decision rationale:** Single scoping defect in two shipped KB helpers; no new surface, no schema change.
- **Override:** no
- **Recipe:** none

---

## Root cause (verified against code)

`harvest-coined-terms.sh` (`SKIP_DIRS` at :88, `build_prune_expr` at :99, scan at :316)
and `build-project-index.sh` (`SKIP_DIRS` at :43, `build_prune_expr` at :55, scans at
:167/:173) share a byte-identical `SKIP_DIRS` prune array. It prunes `.git`, `node_modules`,
`target`, `.aid`, etc. — but NOT the tool-install dirs `.claude`/`.cursor`/`.codex`. The
prune is `find . \( -name .git -o -name .svn ... -o -name .aid \) -prune -o -type f -print`;
`-name` matches a dir's basename at ANY depth.

On a project with AID installed, the repo root holds `.claude/`, `.cursor/`, `.codex/` — the
AID install itself, not the target project's source. The scanners walk those trees, so:
1. **Term-universe pollution** — candidate-concepts.md picks up AID-tooling terms (real run:
   rank 36 = `echo` sourced from `.claude/aid/scripts/config/read-setting.sh`; ~200+ terms and
   ~1,000 index lines came from `.claude`/`.cursor` shell scripts).
2. **Reproducibility break** — these trees change on every AID update/re-install, so the
   "byte-reproducible" harvest/index diverge across updates even when the target is unchanged
   → false /aid-housekeep KB-DELTA drift + non-deterministic closure inputs.

The /aid-discover rule already states `.claude/` at the repo root is the dogfood install and
the KB makes no claims about it; `.aid` is already pruned for exactly this reason.

---

## Fix

Add `.claude .cursor .codex` to `SKIP_DIRS` in BOTH scripts, keeping the two arrays identical
(lockstep). The existing `build_prune_expr` `-name` logic prunes them at any depth. No other
behavior change; `.aid` and all existing prunes still apply.

Edge case (NOT handled here, by design): if the target project literally IS an AID/tooling repo
where `.claude/` etc. are the subject, that is a special dogfood case → would need an explicit
opt-in flag, never removal of the default prune. Pruning by default is correct for all normal
user projects and matches the existing out-of-scope rule.

Open question raised to user: AID also installs to `.github` (copilot-cli) and `.agent`
(antigravity). `.github` deliberately NOT pruned (standard project dir with legitimate content).
`.agent` is an antigravity install tree like the other three but was not in the ticket's list —
pending user decision on whether to add it.

---

## Verification (to record on completion)

- byte-identity on a tree WITHOUT tool dirs (output unchanged); tool terms/files excluded on a
  tree WITH `.claude`/`.cursor`/`.codex`.
- fixture test asserting a repo-root `.claude/` contributes zero terms/files.
- SKIP_DIRS arrays confirmed identical; both scripts `bash -n` clean.
- 5 profiles regenerated + dogfood resynced; full canonical suite + dogfood byte-identity.

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-05 | Work created | -- | KB-scanner scope bug: harvest + build-project-index walk repo-root tool-install trees (.claude/.cursor/.codex); out of KB scope; pollutes universe + breaks reproducibility. Confirmed SKIP_DIRS byte-identical in both, both prune .aid but not the tool dirs. |
| 2026-07-05 | Fix applied + verified | -- | Added `.claude .cursor .codex` to SKIP_DIRS in both scanners (lockstep re-confirmed byte-identical). Verified old-vs-new: (a) exclusion — tool trees incl. deep-nested `.cursor/deep/nested/` contribute 0 terms/files in NEW; OLD had 6 index paths + 17 candidate lines; (b) no-regression — tree WITHOUT tool dirs → NEW byte-identical to OLD for both scripts; (c) reproducibility — build-index byte-identical after in-place tool-tree mutation at same root; target terms (WidgetEngine/Frobnication) still surface (no over-prune). New fixture test tests/canonical/test-kb-scanner-scope.sh 5/5 (S01-S05 incl. lockstep guard). Affected suites green: harvest 18/0, harvest-batching 5/0, recon-classify 37/0, housekeep-classify 24/0, housekeep-deletion-split 17/0. (housekeep-workfolder-safety U10 fails LOCALLY only — unrelated git-merge-ancestry gate, gh-absent fallback; my change doesn't touch that code; the same suite is green on ubuntu CI.) dogfood byte-identity 571/0. 5 profiles regenerated (VERIFY PASS) + 2 dogfood copies resynced. No existing fixture contains tool dirs (nothing else changes). Open: whether to also prune .agent (antigravity install tree); version/release (v2.0.4). |

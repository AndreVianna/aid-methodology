# Infra Tech-Debt Paydown

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-7, §9 AC-9, §10 P4 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-7, §9 AC-9, §10 P4

## Description

A bundle of opportunistic infrastructure tech-debt side-tasks (carried over from tech-debt.md)
paid down alongside the core work. These are debt, not features — kept separate so they do not
dilute the core interview threads, and each is individually deferrable with rationale. The items
are: H1 — add a CI/test check that the dashboard file set agrees across the five install
manifests (install.sh, install.ps1, vendor.js, vendor.py, release.sh), the highest-leverage and
only HIGH item; M3 — refresh docs/repository-structure.md (stale skill/recipe counts and a wrong
path), reconciled via aid-housekeep; M4 — add a multi-viewport visual gate so a visual cannot
pass at a wide viewport yet clip at the dashboard column or mobile width; and M1 — npm/PyPI
publish enablement, which is owner-gated and external (account + token setup), scheduled only
when publishing the next public version.

## User Stories

- As an AID maintainer, I want a CI check that the five install manifests agree on the dashboard
  file set so that a forgotten update cannot silently ship a broken dashboard on one channel.
- As an AID adopter reading the docs, I want repository-structure.md to reflect the real skill /
  recipe counts and paths so that the documentation is accurate.
- As an AID maintainer, I want the visual gate to check multiple viewport widths so that a visual
  that clips at the dashboard column or mobile width is caught before merge.
- As the project owner, I want npm/PyPI publish enablement tracked so that the external account /
  token setup is scheduled when the next public version ships, or explicitly deferred with
  rationale.

## Priority

Could

## Acceptance Criteria

- [ ] Given the debt bundle, when this feature completes, then H1, M3, M4, and M1 are each closed
  or explicitly deferred with rationale. *(AC-9)*
- [ ] Given H1, when the install manifests disagree on the dashboard file set, then the CI/test
  check fails. *(AC-9)*
- [ ] Given M4, when a visual clips at the dashboard-column or mobile target width, then the
  multi-viewport gate flags it. *(AC-9)*

---

## Technical Specification

### Overview & scope discipline

This feature is a **bundle of four independent debt items** carried over from
`.aid/knowledge/tech-debt.md` (H1, M3, M4, M1). It is **wholly independent of the other
features in this work** (no dependency on FR-1's RESEARCH spike or any elicitation feature —
P4 "rides along") and the four items are **mutually independent and independently deferrable**.

At the Detail phase this feature decomposes into **four separate tasks** (one per item); they
have **no inter-dependencies** and may be executed in parallel from the start. There is **no
shared data model, no service flow, and no UI** — the usual Data Model / Feature Flow /
Layers & Components core sections are **N/A** (this is infrastructure/test/docs debt, not an
application feature). Each item below is a self-contained sub-spec with its own closure
criteria.

**Definition of Done (operationalizes AC-9):** the feature is complete when **each** of H1,
M3, M4, M1 is **either closed** (its closure criteria below met, CI green) **or explicitly
deferred with a written rationale** recorded in the work `STATE.md` and the corresponding
`tech-debt.md` item updated. Closing or deferring one item does not block the others.

> Grounding note: every item was verified against the live tree on 2026-06-27. The five
> manifests, `validate-visuals.mjs`, `docs/repository-structure.md`, and `release.yml` all
> exist at the paths cited; the counts/lists below are observed, not quoted from the debt doc.

---

### Sub-spec H1 — Install-manifest lockstep check *(the only HIGH; highest leverage)*

**Problem (verified).** The dashboard server+reader unit is a **12-file set** hard-coded
independently in five manifests, with no shared source list. A silent omission breaks
provisioning on exactly one channel (the real `home.html` regression). The 12 files, observed
identical across all five:

```
home.html  index.html
reader/__init__.py  reader/reader.py  reader/models.py  reader/parsers.py
reader/derivation.py  reader/locator.py
server/server.py  server/server.mjs  server/reader.mjs  server/__init__.py
```

Where each manifest lists the set (verified line ranges):
- `install.sh` — **twice**: stage loop (~L743–755) and install loop (~L791–801).
- `install.ps1` — string array (~L761–771).
- `packages/npm/scripts/vendor.js` — `COPIES` array (~L49–60) + a doc-comment block (~L19–30).
- `packages/pypi/scripts/vendor.py` — tuple list (~L58–69) + a doc-comment block (~L23–34).
- `release.sh` — **twice**: `cp` block (~L324–335) and the tar file-list (~L350–361); its
  `home.html` copy already carries a comment naming the other four.

**Design.** Add a **static lockstep check** as a new canonical test:
`tests/canonical/test-install-manifests-lockstep.sh`. It is **pure-text/structural** (no
install, no network, no Playwright) so it runs everywhere cheaply.

1. **Extract** the dashboard file set from each of the five manifests by parsing the
   `dashboard/<path>` tokens out of each file (grep for the `dashboard/…` paths; normalize the
   `install.ps1` backslash form `reader\reader.py` → `reader/reader.py`).
2. **Normalize** each extraction to a **sorted unique set** of relative paths.
3. **Compare** all five sets for **exact equality**. Use the union as the reference; for each
   manifest, report any **missing** or **extra** path versus the union.
4. **Internal-consistency guard** for the two files that list the set twice (`install.sh`,
   `release.sh`): assert the two occurrences within the same file agree, so a partial edit is
   caught even before cross-file comparison.
5. **Self-canary:** assert the extracted union is non-empty and contains the sentinel
   `home.html` and `server/reader.mjs`, so a parser that silently extracts nothing fails loud
   rather than passing vacuously.

**Fail behavior.** On any mismatch the script prints a per-manifest diff (manifest → missing /
extra paths) and `exit 1`. On full agreement it prints the agreed N-file set and `exit 0`.

**Wiring.** `tests/run-all.sh` auto-discovers `tests/canonical/test-*.sh` by glob (verified
L33) — **no edit to run-all is needed**. The canonical suite runs in `test.yml`, which (per the
now-resolved M2) gates `pull_request` to `master`, so the check **blocks a PR before merge**.

**Decision deferred to Detail:** whether to additionally **extract a single shared file-list**
(the debt doc's "Consider…") and have all five manifests read it. Recommendation: **ship the
check first** (closes the risk, low blast radius); treat shared-list extraction as a *separate,
optional* follow-up — refactoring five shipped installers across Bash/PS/JS/Py is higher-risk
than the guard that makes drift impossible to merge. The check is the AC-9 closure artifact.

**Closure criteria.** New suite exists, passes on the current (in-lockstep) tree, and **fails**
when any one manifest's set is perturbed (demonstrate with a throwaway edit in review); CI green.

---

### Sub-spec M3 — Refresh `docs/repository-structure.md` (stale counts + wrong path)

**Problem (verified counts).** `docs/repository-structure.md` is stale:

| Claim in doc | Lines | Reality (verified) |
|---|---|---|
| "12 skill definitions" / "12 skill definitions, one dir per skill" | L22, L73 | **13** skill dirs under `canonical/skills/` |
| "51 lite-path recipes" / "51 pre-filled lite-path recipe files" | L25, L76 | **52** files under `canonical/aid/recipes/` |
| path `canonical/recipes/` | L25, L76, L117 | actual path is **`canonical/aid/recipes/`** (the `aid/` segment) — `canonical/recipes/` does not exist |
| path `canonical/templates/` | L75, L116 | actual path is **`canonical/aid/templates/`** — `canonical/templates/` does not exist |
| path `canonical/scripts/` | L77 | actual path is **`canonical/aid/scripts/`** — `canonical/scripts/` does not exist |
| ASCII directory tree (`canonical/` → {skills, agents, templates, recipes, scripts}) | L21–26 | omits the real `canonical/aid/` node and mis-parents templates/recipes/scripts under `canonical/` directly; on disk `canonical/` = {agents, aid, skills}, with templates/recipes/scripts under `canonical/aid/` |

(All three `canonical/<x>/` paths in `repository-structure.md` predate the `canonical/aid/` nesting
and are **required** closure targets — the doc FR-7 says to *refresh* must not be left with ANY
wrong in-doc path. The `tech-debt.md` M3 entry's *other-doc* siblings remain out of scope — see below.)

**Design / reconcile path.** Per the established **count-drift precedent**, reconcile via
**`/aid-housekeep`** rather than ad-hoc inline edits — the same skill/recipe count appears
across ~10 doc/KB surfaces, and aid-housekeep is the sanctioned sweep that keeps them coherent
in one pass (precedent Q26/Q27). The Detail-phase task is: run `/aid-housekeep` scoped to the
skill-/recipe-count + ALL THREE in-doc `canonical/<x>/`→`canonical/aid/<x>/` path drifts
(templates L75/L116, recipes L76/L117, scripts L77), with `docs/repository-structure.md` as the
named target; let it correct the counts (13 / 52), fix all three paths, and reconcile any sibling
surfaces it surfaces. The counts must be **derived from the live
tree at run time** (`ls -d canonical/skills/*/ | wc -l`, `ls canonical/aid/recipes/ | wc -l`),
not transcribed from this spec, since they may drift again before execution.

**Out of scope for M3 (noted, not required here).** The `tech-debt.md` M3 entry also bundles two
sibling **source-doc** drifts — `docs/aid-methodology.md` flat-task-layout text and
`canonical/EMISSION-MANIFEST.md`'s 3-profile (vs 5) enumeration. FR-7 scopes *this* feature to
`repository-structure.md`; the aid-housekeep pass **may** fold those in if cheap, but they are
**not** part of M3's closure DoD and may be left to a future housekeep.

**Closure criteria.** `docs/repository-structure.md` shows the live counts and the corrected
`canonical/aid/{templates,recipes,scripts}/` paths — the doc must nowhere, in **prose OR the
L21–26 ASCII directory tree**, depict templates/recipes/scripts outside `canonical/aid/` (the tree
must show the `aid/` node with templates/recipes/scripts nested under it); KB-hygiene / CI green;
the `tech-debt.md` M3 row updated (resolved or scoped-remainder noted).

---

### Sub-spec M4 — Multi-viewport check (T4) in the visual-fidelity gate

**Problem (verified).** `canonical/aid/scripts/summarize/validate-visuals.mjs` renders each
visual at the **single default Playwright viewport** — `browser.newPage()` is called with **no
`setViewport`** (verified L178; default 1280×720, the debt doc's "~1152px content"). It runs
three checks, documented in the header (L25–32) and evaluated at L368–414:

- **T1** readable text (font-size ≥ threshold, not zero-height/overflow-clipped),
- **T2** minimal child-element overlap (≤20% of smaller area),
- **T3** non-trivial layout (rendered, non-collapsed bbox).

A visual can pass at the wide viewport yet **horizontally clip** at the dashboard column
(~720–760px) or mobile (~390px) — the feature-015 lifecycle-timeline pill cut by ~24px at 732px.

**Design — add T4 "no horizontal overflow-clip at target widths".** For each resolved visual,
re-evaluate at the two **representative widths** and assert no horizontal overflow:

- **Target widths:** dashboard column **~732px** (use a single representative value in the
  720–760 band) **and** mobile **~390px**. Make these a named constant array
  (`OVERFLOW_VIEWPORTS = [732, 390]`) alongside the existing `MIN_FONT_SIZE_PX` /
  `OVERLAP_TOLERANCE` constants so Detail can tune them.
- **Mechanism:** for each width, `page.setViewport({ width, height })` (or a fresh page per
  width) and, for each visual, flag overflow when the visual's content is wider than its
  container — i.e. `el.scrollWidth > el.clientWidth + ε` **or** the visual's rendered
  `getBoundingClientRect().right` exceeds its nearest layout container's right edge by > ε
  (small px tolerance to avoid sub-pixel false positives). Detail picks the precise predicate;
  the contract is **"a horizontally clipped visual fails at a target width."**
- **Caveat to resolve at Detail:** `kb.html` visuals may be authored at a fixed pixel width
  (inline SVG with explicit `width`), in which case a naive narrow viewport always "overflows."
  T4 must measure overflow **relative to the visual's own responsive container**, not the raw
  viewport, OR scope T4 to visuals whose container is width-constrained. This is the one real
  design risk in M4 and must be settled before implementation so T4 does not become a
  false-positive generator.

**Plug-in points.**
- In `validate-visuals.mjs`: add T4 to the per-visual evaluation loop (alongside T1/T2/T3),
  emit a `T4 overflow-clip (widths 732/390): PASS|FAIL` line per visual (mirroring L412–414),
  fold T4 into the per-visual pass/fail and the final `passCount` gate (L438), and add a T4
  entry to the failure-explanation block (L447–449) and the `--check-only` summary (L156–158).
- In `tests/canonical/test-visual-fidelity.sh`: the suite already exercises `--check-only` and
  invocation-error paths without Playwright (L37/L52/L93). Add (a) a `--check-only` assertion
  that T4 appears in the documented check list, and (b) — guarded by Playwright availability,
  matching the existing graceful-skip — a positive case (a within-bounds visual passes T4) and
  a negative case (a deliberately over-wide fixture fails T4 at 732/390 while still passing T1–T3
  at the wide viewport, proving T4 catches what T1–T3 miss).

**Closure criteria.** T4 implemented and wired into the T1/T2/T3 gate and the suite; the gate
**fails** on a visual that clips at 732px or 390px and **passes** the current in-spec `kb.html`;
canonical-suite + visual-fidelity CI green. Per the global web-review rule, the demonstration
that T4 catches a real clip must be **Playwright-rendered**, not source-inspected.

---

### Sub-spec M1 — npm/PyPI publish enablement *(owner-gated / external — deferrable)*

**Nature (verified).** This is **not a code change**. `.github/workflows/release.yml` already
contains correct, OIDC/Trusted-Publishing `npm-publish` (gated `if: vars.NPM_ENABLED == 'true'`,
L217) and `pypi-publish` (gated `if: vars.PYPI_ENABLED == 'true'`, L284) jobs; the external
blockers are documented in the workflow header (L19–36). Until external accounts exist and the
repo variables flip, releases publish to **GitHub Releases only**.

**Owner steps (the closure work — external, not in this repo).**
1. **npm:** create and own the **`@aid` npm scope** (or confirm OIDC Trusted Publishing for the
   `aid-installer` package on that scope); then set repo variable **`NPM_ENABLED=true`**.
2. **PyPI:** create the **CasuloAI Labs PyPI org**, **reserve the `aid-installer` name**, and
   configure a **Trusted Publisher** pointing at this repo + the release workflow; then set repo
   variable **`PYPI_ENABLED=true`**.
3. (Optional hardening, per the workflow header) prefer Trusted Publishing over a long-lived
   `NPM_TOKEN`.

**How to verify (when enabled).** Cut a release tag; confirm both `npm-publish` and
`pypi-publish` jobs **run** (no longer skipped by the `vars.*` gate) and succeed, then confirm
the package resolves on each channel (`npm view aid-installer@<v> version`; `pip index` /
install of `aid-installer==<v>`). The release already idempotently skips an already-published
version (L243–245), so a re-run is safe.

**Deferral (explicit, per AC-9).** M1 is **owner-gated and externally blocked** — it cannot be
closed by an agent and is correctly **scheduled only when publishing the next public version**.
Recommended disposition for *this* feature: **defer M1 with rationale** — "publish workflow is
already correct and OIDC-ready; closure requires external account/scope/Trusted-Publisher setup
and a repo-variable flip that only the owner can perform; defer until the next public release."
Record the deferral in the work `STATE.md` and update the `tech-debt.md` M1 row. Per the DoD,
an explicitly-deferred-with-rationale M1 **satisfies AC-9** for this item.

---

### Cross-item notes for the Detail phase

- **Four tasks, zero inter-dependencies** → all parallelizable; assign types: H1 = TEST
  (new bash suite), M3 = a `/aid-housekeep` run (docs reconcile), M4 = TEST+IMPLEMENT (mjs gate
  + suite), M1 = a tracked owner action / deferral decision (no code task).
- **Independent deferral:** any item may be deferred-with-rationale without affecting the other
  three; the feature still completes per the DoD.
- **CI surfaces touched:** H1 and M4 add canonical suites that run in `test.yml` (PR-gated to
  master); M3 must keep KB-hygiene green; M1 touches no CI behavior until the owner flips the
  variables.

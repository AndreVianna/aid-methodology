# task-075: MIGRATE — home.html source-move to dashboard/home.html (single source + derived dogfood copy)

**Type:** MIGRATE

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** none (Wave-1 foundation; independent start; predecessor of the vendoring + core steps)

**Scope:**
- Establish `dashboard/home.html` as the **single committed source of truth** for the per-repo SPA shell
  (LC-HSRC, DD-5/RC-2): take the current d010 dogfood file `.aid/dashboard/home.html` (122 KB, the
  hand-committed SPA shell; KI-010 confirmed it is the only real copy) and **copy its content to a new
  committed source `dashboard/home.html`** (alongside the existing CLI-home `dashboard/index.html`).
  This is a **relocation** of the source of truth — the SPA shell **content/behavior is unchanged** (it is
  still the static shell that fetches `/r/<id>/api/model` at runtime).
- **Keep `.aid/dashboard/home.html` as a derived copy** — do **NOT** delete it (R18: the multi-repo server
  serves the per-repo `<repo>/.aid/dashboard/home.html` at `/r/<id>/home.html`; deleting the dogfood copy
  would 404 the dogfood dashboard mid-transition). After this task, `dashboard/home.html` and
  `.aid/dashboard/home.html` are **byte-identical** (the source and its derived dogfood copy); their
  equality is CI-enforced by task-076's gate (R20/OQ-5).
- Establish the sync direction as **`dashboard/home.html` (source) → `.aid/dashboard/home.html` (derived
  copy)**: future edits land in the source, the dogfood copy is regenerated/kept-equal. Document this
  one-way relationship in a short header comment / the design note so an editor does not edit the dogfood
  copy by mistake (DD-5 — drift caught by task-076's equality gate, not structurally prevented here).
- **No `bin/aid` / `bin/aid.ps1` edit** in this task (it is pure source-layout). It does **not** add the
  vendor-manifest entries (that is task-076) and does **not** wire the migration copy step (that is the
  Wave-2 ADD step in task-077, which copies `$AID_HOME/dashboard/home.html` per repo).
- The file is hand-maintained, **NOT** `canonical/`-rendered — it is **absent** from
  `canonical/EMISSION-MANIFEST.md` (confirmed: zero matches) and is **not** subject to render-drift /
  `run_generator.py` (C8). Do not introduce it into `canonical/`.

**Acceptance Criteria:**
- [ ] `dashboard/home.html` exists as a new committed source whose content equals the prior
      `.aid/dashboard/home.html` (byte-identical), positioned alongside `dashboard/index.html`.
- [ ] `.aid/dashboard/home.html` is **retained** (not deleted) as the derived dogfood copy so the
      multi-repo server keeps serving `/r/<id>/home.html` without a 404 during the transition (R18); the
      server contract is unchanged.
- [ ] The SPA shell behavior is unchanged (relocation only — no functional edit to the shell); the
      source→copy sync direction is documented so the source of truth is unambiguous (DD-5).
- [ ] `dashboard/home.html` is **not** added to `canonical/` and remains absent from
      `canonical/EMISSION-MANIFEST.md` (not render-drift, C8).

# Requirements

> **Status:** Approved (2026-06-04) — escalated from lite path (LITE-FEATURE), seeded from
> the lite SPEC + task-001 research, then completed and confirmed via the full-path interview.
> Inline `[seed]` / `[lite-carry]` markers are retained as provenance only; all sections are
> confirmed and approved.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Initial interview started | /aid-interview |
| 2026-06-04 | Interview restarted — escalated from lite path (LITE-FEATURE); seeded from lite SPEC + task-001 research | /aid-interview escalation |
| 2026-06-04 | §3 Users & Stakeholders completed; security postures mapped per channel; §6 + §9 updated (provenance/checksums, all-4-channels AC) | /aid-interview CONTINUE |
| 2026-06-04 | §7 Constraints + §8 Assumptions completed: replace setup.sh/ps1; npm @aid/installer; PyPI under CasuloAI Labs (unregistered); version bumped 0.1.0-dev → 0.7.0 (VERSION + README) | /aid-interview CONTINUE |
| 2026-06-04 | §10 Priority confirmed (M2 → M3a/M3b → M7); seeded §§1,2,4,5,6,9 confirmed Complete — all sections done | /aid-interview CONTINUE |
| 2026-06-04 | Interview complete — approved | /aid-interview |
| 2026-06-04 | Cross-reference (Grade D→A+): multi-tool AGENTS.md resolved — FR2 per-tool `--tool`, FR11 protect-on-diff, FR12 invariant AGENTS.md; §4/§7/§9 corrected; README badge → 0.7.0; feature-006 added | /aid-interview (cross-reference) |

## 1. Objective

`[seed]` Provide a **frictionless, one-command way to deploy the AID methodology into an
adopter's repository** — replacing today's "clone the whole repo + run `setup.sh`/`setup.ps1`"
flow. The installer fetches only the rendered profile tree the adopter needs (not the full
repo), auto-detects the host tool, supports install / update / uninstall, pins versions, and
works both online and offline. Distribution spans multiple channels so adopters can use
whichever fits their environment.

## 2. Problem Statement

`[seed]` Adopting AID currently requires `git clone` of the entire repository (~2 MB / ~257
files per profile, plus canonical sources, tests, and maintainer-only tooling the adopter does
not need) followed by an interactive `setup.sh`/`setup.ps1` run. Pain points: (1) full-repo
download of unneeded content; (2) interactive-only — no scriptable one-liner, no host-tool
auto-detection; (3) no update, version-pinning, or uninstall path. This raises adoption
friction and makes reproducible/automated installs and air-gapped installs hard.

## 3. Users & Stakeholders

- **Adopters (primary)** — developers adding AID to their repo, across host tools
  (Claude Code / Codex / Cursor / Copilot CLI / Antigravity) and OSes. **No single primary
  segment** — all four install experiences must work at delivery. Segments map to both
  environment and security posture:
  - *No-runtime / quick* → `curl` online (M2) — most convenient, weakest supply-chain story.
  - *Node developers* → `npx` (M3a) — registry integrity + provenance.
  - *Python / data / AI developers* → `pip` / `pipx` (M3b) — registry integrity + provenance.
  - *Enterprise / security-conscious / air-gapped* → **offline tar (M2 `--from-bundle`)**:
    download, verify against published `SHA256SUMS` (and optional signature), then install
    with no network. Recommended path for security review. The npm/PyPI channels are an
    acceptable middle ground (integrity + provenance, but not a full content audit).
- **Maintainer (you)** — cuts releases; wants one tag → all channels published (M7), with
  provenance/attestations and checksums emitted automatically.
- **CI / automation consumers (secondary)** — scripted, non-interactive installs in pipelines.

## 4. Scope

### In Scope

`[seed]` Deliver the deployment system as **four coordinated channels** (per task-001
research decision M2 + M3a + M3b + M7):

- **M2 — GitHub Release tarball + bootstrap (`install.sh` / `install.ps1`):** zero-dependency
  fallback installer; downloads one per-profile tarball; install/update/uninstall;
  host-tool auto-detect + `--tool` override; online and `--from-bundle` offline modes;
  records installed version.
- **M3a — npm/npx CLI:** `npx @aid/installer …` for the Node audience.
- **M3b — PyPI/pipx CLI:** `pipx run aid-installer …` for the Python audience (the package is
  `aid-installer`; the `aid` console-script also runs via `pipx run --spec aid-installer aid …`).
- **M7 — CI-automated release:** a GitHub Actions workflow (tag-triggered) that runs the
  generator + render-drift check, packages the five per-profile tarballs + checksums,
  creates the GitHub Release, and publishes the npm and PyPI packages — all from one tag.
- **Shared install core** so M2/M3a/M3b do not duplicate install logic; **version sync**
  across git tag / VERSION file / package.json / pyproject.toml.
- **Protect-on-diff for root agent files** (FR11) — never silently clobber a user's existing
  `CLAUDE.md` / `AGENTS.md`; per-tool, argument-driven (`--tool`) install replacing the
  interactive multi-select menu.
- **Invariant root `AGENTS.md`** (FR12) — a small canonical-content normalization so the four
  AGENTS.md-writing profiles render byte-identical files.
- Documentation for the new install / update / uninstall flow across all channels.

### Out of Scope

`[seed]`
- Changing the canonical → 5-profiles render pipeline itself (FR12 directly edits the four
  hand-maintained `profiles/<tool>/AGENTS.md` source files; the generator is used only to prove
  the install trees are untouched — no pipeline-mechanics change).
- M6 (Homebrew/Scoop/Chocolatey taps) — deferred as an optional future convenience layer on
  top of the GitHub Release.
- M4 (`gh` extension) and M5 (sparse-checkout/degit) — dominated; not adopted.
- **`profiles/*/README.md` are NOT installed** (they are repo-presentation only; `setup.sh`
  never copies them). The installer writes only each tool's dir + its root agent file
  (`CLAUDE.md` or `AGENTS.md`); it never touches files it did not create (FR11).

## 5. Functional Requirements

`[seed]` (to be refined into per-feature SPECs during decomposition)

- **FR1 — Zero-dep installer (M2):** install or update the correct rendered profile tree at a
  pinned version without cloning the full repo; bash + PowerShell.
- **FR2 — Host-tool selection (per-tool, argument-driven):** install targets **one tool per
  invocation**, chosen by a `--tool` argument (optional comma-list for several), with
  auto-detect from project markers as the default and a clear prompt/error when ambiguous.
  Replaces `setup.sh`'s interactive multi-select menu — friendlier and scriptable. Each tool's
  dir (`.claude/`, `.cursor/`, …) is installed independently/isolated; only the shared root
  agent files couple tools (see FR11).
- **FR3 — Update:** re-run to update to latest or a pinned version; record installed version
  for reproducibility.
- **FR4 — Uninstall:** cleanly remove all AID-installed files via an install-time manifest.
- **FR5 — Offline mode:** install from a pre-downloaded bundle with no network.
- **FR6 — npm CLI (M3a):** `npx`-runnable installer for the Node audience, delegating to the
  shared core / release tarball.
- **FR7 — PyPI CLI (M3b):** `pipx`-runnable installer for the Python audience, delegating to
  the shared core / release tarball.
- **FR8 — CI release automation (M7):** tag-triggered workflow that builds tarballs +
  checksums, creates the GitHub Release, and publishes npm + PyPI from one tag, gated on
  the generator render-drift + test suite.
- **FR9 — Shared install core:** single canonical install logic reused by all surfaces (no
  4× duplication).
- **FR10 — Version synchronization:** one authoritative version reconciled across git tag,
  VERSION, package.json, pyproject.toml.
- **FR11 — Protect pre-existing root agent files (protect-on-diff):** the installer must
  **never silently overwrite** an existing root agent file (`CLAUDE.md`, `AGENTS.md`) it did
  not write. On install, if the target exists and differs from what would be written (checksum
  vs. the install manifest), warn, write the incoming version beside it as `*.aid-new` for the
  user to merge, and require `--force` to overwrite. Uninstall removes a root agent file only
  if it still checksum-matches what this tool installed (else leaves it — another tool or the
  user owns it now). This protects the adopter's own files and handles two tools writing
  differing `AGENTS.md`.
- **FR12 — Invariant root `AGENTS.md` (content normalization):** normalize the four
  AGENTS.md-writing profiles (codex, cursor, copilot-cli, antigravity) so their root `AGENTS.md`
  is **byte-identical**, eliminating tool-vs-tool collisions (currently they differ on one line —
  the install-root prefix in a schema path). These root files are **hand-maintained source**
  (not generated — they are absent from `emission-manifest.jsonl` and untouched by
  `run_generator.py`), so the fix is a **direct edit of the four files**, guarded by a CI
  invariance assertion; the generator is run only to prove the install trees stay untouched. No
  pipeline-mechanics change. With FR12 done, FR11's warning only ever fires for the user's own
  file.

## 6. Non-Functional Requirements

`[seed]`
- **Minimal dependencies (best-effort, weighted preference — NOT a hard constraint):** the
  M2 fallback path must require no adopter-side runtime beyond the OS baseline (curl/tar or
  PowerShell stdlib); M3a/M3b intentionally accept Node/Python for their audiences.
- **Cross-platform:** native Bash (Linux/macOS) and native PowerShell 5.1+ (Windows) — no WSL
  requirement for the fallback path.
- **Offline / air-gapped capable** (at least via M2 `--from-bundle`).
- **Reproducibility:** pinned, immutable versions; recorded installed version.
- **Supply-chain integrity (per-channel security postures):** the four channels deliberately
  span a security spectrum — offline tar (verify-before-install, strongest) → npm/PyPI
  (integrity + provenance) → curl online (most convenient, weakest). Therefore: publish
  `SHA256SUMS` (and optional signature) with every GitHub Release so the offline tar can be
  verified before install; publish the npm package with `--provenance` and the PyPI package
  via Trusted Publishing (sigstore attestations) so the registry channels carry integrity +
  origin guarantees. Registries verify integrity/origin, not code safety — the offline tar is
  the recommended path for enterprise/air-gapped security review.
- **Low maintainer upkeep:** one tag → all channels released (the point of M7).

## 7. Constraints

- **Replace, not coexist:** the new installer **supersedes `setup.sh` / `setup.ps1`** — the old
  setup scripts are removed and all references (README, docs, `infrastructure.md`) updated.
- **npm package:** scoped name **`@aid/installer`** (requires the `aid` npm org/scope).
- **PyPI package:** published under a **CasuloAI Labs** org (casuloailabs.com) — **org not yet
  registered on PyPI** (registration is a prerequisite/dependency, see §8). Package name TBD
  (proposed `aid-installer`).
- **Version baseline:** repo version set to **`0.7.0`** now (was `0.1.0-dev`); versioned
  releases start from here.
- **Don't touch the render pipeline:** the canonical→5-profiles generator stays as-is; the
  installer only consumes its output. Releases are cut from a clean rendered state (reuse the
  existing render-drift check).
- **CI is gated:** `test.yml` is a required check with branch protection; the M7 release
  workflow must coexist without weakening it.
- **Honor existing copy semantics:** match the current copy behavior (skip-identical,
  prompt-on-diff / `--force`). The old multi-select "survivor = highest-numbered selected tool
  by fixed block order" rule for the shared `AGENTS.md` is **superseded** by the new per-tool
  model (FR2): each `--tool` install does per-invocation last-writer-wins guarded by
  protect-on-diff (FR11). Note: version-recording (FR3) and the uninstall manifest (FR4) are
  **net-new** — today's `setup.sh` only echoes the version and has no uninstall; there is no
  prior manifest to "honor."
- **Five host-tool tree layouts** must all be supported, including the **root agent files**:
  claude-code `.claude/` + root `CLAUDE.md`; codex `.agents/` + `.codex/` + root `AGENTS.md`;
  cursor `.cursor/` + root `AGENTS.md`; copilot-cli `.github/` + root `AGENTS.md`; antigravity
  `.agent/` + root `AGENTS.md`. **Four tools (codex, cursor, copilot-cli, antigravity) write a
  shared root `AGENTS.md`**; claude-code uses `CLAUDE.md` only. This shared-root-file reality
  drives the multi-tool install/uninstall policy (see §5 FR2/FR4 and the open decision in §8).
- **Cross-platform floor:** Bash 4+ and PowerShell 5.1+ (M2). Node and Python minimum versions
  for M3a/M3b still TBD (see §8).
- Note: absence of a release pipeline / package-registry presence today is the **status quo
  this work intentionally changes**, not a constraint.

## 8. Assumptions & Dependencies

- **npm `@aid` scope** — the `@aid` org/scope must exist and be owned by the maintainer to
  publish `@aid/installer`. *(Verify availability/ownership.)*
- **PyPI CasuloAI Labs org** — **not yet registered on PyPI**; registering the org/account and
  reserving the package name is a prerequisite for the M3b channel.
- **Publishing credentials** — npm token + PyPI token, or (preferred) **OIDC Trusted
  Publishing** from GitHub Actions to avoid long-lived secrets *(verify Trusted Publishing
  support for both registries)*.
- **GitHub Releases** as the artifact host for M2/M7 (public repo).
- **Node / Python minimum versions** for M3a/M3b — TBD (to settle in the per-feature SPECs).
- **Research caveats to verify before build** — GitHub API rate limits, `npx` offline
  behavior, `pipx` prerequisites, sigstore/provenance specifics (flagged in the research doc).

## 9. Acceptance Criteria

`[seed]` (carried from lite SPEC; will be distributed across per-feature SPECs)

- [ ] `[lite-carry]` Given a developer in a target repo with no prior AID setup, when they run the one-command installer (auto-detect or `--tool`), then the correct rendered profile tree is installed **or updated** at a pinned version without cloning the full repo.
- [ ] `[lite-carry]` Clean uninstall removes exactly the AID-installed files (manifest-based).
- [ ] `[lite-carry]` Host-tool auto-detect with explicit override flag; clear error when ambiguous.
- [ ] `[lite-carry]` Cross-platform: bash and PowerShell paths both work.
- [ ] `[lite-carry]` Online and offline (`--from-bundle`) modes both supported.
- [ ] `[lite-carry]` Installed version recorded for reproducible updates.
- [ ] **All four install experiences work at delivery** and install equivalent results from the same release: `curl` online (M2), offline tar `--from-bundle` (M2), `npx` (M3a), `pip`/`pipx` (M3b).
- [ ] The offline tar can be verified before install against a published `SHA256SUMS` (and optional signature).
- [ ] The npm package is published with provenance and the PyPI package via Trusted Publishing (sigstore attestations).
- [ ] One tagged release (M7) produces the GitHub Release tarballs + checksums + npm + PyPI artifacts, gated on render-drift + tests.
- [ ] **Protect-on-diff:** given an existing `CLAUDE.md`/`AGENTS.md` the installer didn't write, when install runs without `--force`, then the file is NOT overwritten — a warning is shown and the incoming version is written as `*.aid-new`; `--force` overwrites.
- [ ] **Uninstall safety:** a root agent file is removed only if it still checksum-matches what this tool installed; otherwise left in place.
- [ ] **Invariant AGENTS.md:** the four AGENTS.md-writing profiles render a byte-identical root `AGENTS.md` (single sha256 across codex/cursor/copilot-cli/antigravity).

## 10. Priority

All four install experiences are **required at delivery** (no scope cut). Priority is **build
order**, confirmed as:

1. **M2 — foundation + shared install core** (tarball packaging, `install.sh`/`install.ps1`,
   host-detect, install/update/uninstall, online + offline, manifest, version recording;
   removes `setup.sh`/`setup.ps1`). Load-bearing; delivers value alone.
2. **M3a (npm `@aid/installer`) + M3b (PyPI)** — thin wrappers over the shared core/tarball;
   parallelizable once the core is stable.
3. **M7 — CI release automation** (one tag → tarballs + checksums + npm + PyPI, with
   provenance). Until M7 lands, releases are cut manually via `gh release create`.

Likely delivery mapping: **delivery-001 = M2**, **delivery-002 = M3a + M3b**,
**delivery-003 = M7**.

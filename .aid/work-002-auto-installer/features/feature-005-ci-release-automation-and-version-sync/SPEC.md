# CI Release Automation & Version Sync (M7)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Feature identified from REQUIREMENTS.md §5 (FR8, FR10), §6, §7, §8 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR8, FR10), §6 (supply-chain), §7 (CI gate), §8 (OIDC/Trusted Publishing)

## Description

Automates everything features 002/003/004 do manually. A **tag-triggered GitHub Actions workflow**
runs the generator + render-drift check, builds the five per-profile tarballs + `SHA256SUMS`,
creates the GitHub Release, and publishes the npm package (with `--provenance`) and the PyPI package
(via Trusted Publishing) — all from **one tag**, gated on the existing `test.yml` without weakening
branch protection. It also owns **version synchronization (FR10)**: reconciling one authoritative
version across the git tag, `VERSION`, `package.json`, and `pyproject.toml`. Until this feature
ships, releases are cut manually via feature-002.

## User Stories

- As the maintainer, I want to push one version tag and have all channels (GitHub Release tarballs + checksums, npm, PyPI) published automatically so that releasing is a single low-effort action.
- As an adopter, I want npm provenance and PyPI attestations so that the registry artifacts carry verifiable origin guarantees.

## Priority

Should (P2 — automation layer; the product ships via manual release (feature-002) until this lands)

## Acceptance Criteria

- [ ] Given a pushed version tag, when the workflow runs, then it produces the GitHub Release tarballs + `SHA256SUMS` and publishes npm + PyPI artifacts — gated on render-drift + the `test.yml` suite.
- [ ] The npm package is published with `--provenance`; the PyPI package via Trusted Publishing (sigstore attestations).
- [ ] One authoritative version is reconciled across git tag, `VERSION`, `package.json`, and `pyproject.toml` (mismatch fails the release).
- [ ] The release workflow coexists with `test.yml` and does not weaken branch protection.

## Dependencies

- **feature-002** (packaging logic to wrap), **feature-003** + **feature-004** (publish targets + their manifest files it synchronizes). Last to land.

---

## Technical Specification

> **Authored by:** /aid-specify (Architect). Grounded against live repo state on 2026-06-04:
> `VERSION`=`0.7.0`; remote `github.com/AndreVianna/aid-methodology`; no `v*` tags yet (first
> release bootstraps); `package.json` / `pyproject.toml` do **not** exist yet (created by
> feature-003 / feature-004). The existing CI is `.github/workflows/test.yml` (`name: CI`, jobs
> `render-drift` / `canonical-tests` / `generator-selftests` / `kb-hygiene`), a REQUIRED check with
> branch protection on `master` since 2026-05-29. This feature **wraps** `release.sh` (feature-002 —
> tarballs + `SHA256SUMS` + `gh release create`); it does not re-implement packaging. It publishes
> the npm (feature-003) and PyPI (feature-004) packages and **owns FR10** version reconciliation.

### S0. Scope and boundaries

This feature owns exactly one new file — `.github/workflows/release.yml` — plus one small,
unit-testable version-sync check it can vendor as a script. It is the **automation layer**: it does
not define packaging (feature-002 `release.sh`), the installers (feature-001), or the package
manifests (`package.json` from feature-003, `pyproject.toml` from feature-004). It **invokes**
`release.sh` and **publishes** the two packages, and it is the single authority for **FR10**
(reconciling the version across the git tag, `VERSION`, `package.json`, `pyproject.toml`).

Hard rule (REQUIREMENTS §7, `infrastructure.md`): the new workflow **must not weaken `test.yml` or
branch protection**. It adds a *separate* workflow on a *separate* trigger; it never edits
`test.yml`, never relaxes a required check, and never publishes from an ungated state.

### S1. Trigger model and permissions

```yaml
name: Release
on:
  push:
    tags: ['v*']            # primary path: maintainer pushes v<VERSION>
  workflow_dispatch:
    inputs:
      ref:                  # tag (or commit) to release; required for the dispatch path
        description: 'Tag to release (e.g. v0.7.0)'
        required: true
      dry_run:
        description: 'Build + assert version-sync, but publish nothing'
        type: boolean
        default: false

permissions:
  contents: write           # gh release create / upload assets (built-in GITHUB_TOKEN)
  id-token: write           # OIDC: npm --provenance attestation + PyPI Trusted Publishing
# everything else stays at the default-deny; no packages:/pull-requests:/issues: scopes.
```

- **Tag push is the product path.** `git tag v0.7.0 && git push origin v0.7.0` is the only
  maintainer action (REQUIREMENTS §6 "one tag → all channels"). The tag `v<VERSION>` is the
  authoritative version carrier (S4).
- **`workflow_dispatch` is the operational escape hatch:** re-run a release for an existing tag, or
  exercise the pipeline with `dry_run: true` (S6). On the dispatch path the job checks out
  `inputs.ref`; on the tag path it checks out `github.ref` and derives the version from
  `github.ref_name`.
- **Least privilege.** `contents: write` is the minimum for `gh release create` against the same
  repo (the built-in `GITHUB_TOKEN`; no PAT). `id-token: write` is required for the OIDC token used
  by both npm provenance and PyPI Trusted Publishing. No other scope is granted. Because this is a
  *workflow-level* `permissions:` block on a release-only trigger, it does not touch the
  `contents: read` posture of `test.yml`.

### S2. Gating — re-run the gate inside the release job (does NOT weaken branch protection)

**Key fact this design rests on:** GitHub branch protection on `master` gates **pull requests into
`master`**. A **tag push does not inherit or re-trigger those required checks** — the required-check
contract is a PR-merge contract, not a tag-time contract. Therefore the only sound way to guarantee
"a release is gated on render-drift + the test suite" is for `release.yml` to **re-run the gate
itself on the tagged commit**, not to "ask" branch protection (which has no jurisdiction over tags).

This *strengthens* rather than weakens the posture: the released bytes are proven green at the exact
tagged commit, independent of whatever happened on PRs. `test.yml` is untouched; branch protection
is untouched.

Implementation — a `gate` job that runs the **exact same** invariants as `test.yml`, reusing the
same pinned actions, with publish jobs blocked behind it via `needs:`:

```yaml
jobs:
  gate:
    runs-on: ubuntu-24.04
    outputs:
      version: ${{ steps.ver.outputs.version }}        # bare semver, propagated to the publish jobs (S3/S4)
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2  (pin from test.yml)
        with: { ref: ${{ inputs.ref || github.ref }} }
      - uses: actions/setup-python@a309ff8b426b58ec0e2a45f0f869d46889d02405 # v6.2.0
        with: { python-version: '3.11' }
      - id: ver
        name: Derive authoritative version from the tag/ref (strip leading 'v')
        shell: bash
        # Tag path: github.ref_name is the tag (e.g. v0.7.0). Dispatch path: inputs.ref.
        # Export the bare semver as VERSION for this job (version-sync) AND as a job output
        # (steps.ver.outputs.version) so the separate publish jobs can re-import it (S3/S4).
        run: |
          RAW="${{ inputs.ref || github.ref_name }}"   # 'v0.7.0' (tag) or inputs.ref (dispatch)
          echo "VERSION=${RAW#v}" >> "$GITHUB_ENV"      # -> '0.7.0' (this job)
          echo "version=${RAW#v}" >> "$GITHUB_OUTPUT"   # -> '0.7.0' (gate job output, for publish jobs)
      - run: git config core.fileMode false                  # same as test.yml render-drift
      - name: render-drift (profiles in sync with canonical)
        run: |
          python run_generator.py
          if ! git diff --exit-code -- profiles/; then
            echo "::error::profiles/ is out of sync with canonical/. Run 'python run_generator.py' and commit the result."
            exit 1
          fi
      # canonical helper suites (mirror test.yml's canonical-tests preamble)
      - uses: actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6.4.0
        with: { node-version: '20' }
      - uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
        with: { path: .aid/knowledge/.cache/mermaid.min.js, key: mermaid-v11.15.0 }
      - run: bash canonical/scripts/summarize/fetch-mermaid.sh
      - run: find canonical/scripts tests/canonical -name '*.sh' -exec chmod +x {} +
      - name: Assert test runtimes present (node + pwsh)   # verbatim from test.yml canonical-tests
        shell: bash
        run: |
          command -v node >/dev/null || { echo "::error::node missing — .mjs suites would skip"; exit 1; }
          command -v pwsh >/dev/null || { echo "::error::pwsh missing — PowerShell suites would skip"; exit 1; }
          echo "node $(node --version) | $(pwsh --version)"
      - run: bash tests/run-all.sh
      # generator self-tests (mirror test.yml's generator-selftests)
      - run: |
          python .claude/skills/aid-generate/scripts/render_lib.py --self-test
          python .claude/skills/aid-generate/scripts/test_manifest_safety.py --self-test
          python .claude/skills/aid-generate/scripts/render_canonical_scripts.py --self-test --canonical-root .
          python .claude/skills/aid-generate/scripts/verify_deterministic.py --self-test --canonical-root .
          python .claude/skills/aid-generate/scripts/verify_advisory.py --self-test --canonical-root .
          python .claude/skills/aid-generate/scripts/test_copilot_emitter.py --self-test --canonical-root .
          python .claude/skills/aid-generate/scripts/test_antigravity_emitter.py --self-test --canonical-root .
```

Design choices:

- **Reuse the exact render-drift gate** — `python run_generator.py` then
  `git diff --exit-code -- profiles/`, with the identical `git config core.fileMode false` and the
  byte-identical `::error::` remediation string `test.yml` uses (`profiles/ is out of sync with
  canonical/. Run 'python run_generator.py' and commit the result.`) and the byte-identical
  runtime-presence loud-fail block (the two `command -v … || { echo "::error::…"; exit 1; }` lines
  plus the version echo). Same invariant, two triggers. The surrounding step *ordering* mirrors
  `test.yml`'s canonical-tests preamble (fetch-mermaid → chmod → runtime-assert → run-all), inlined
  into one job rather than split across jobs.
- **Reuse the exact pinned action SHAs** from `test.yml` (checkout `de0fac2…`, setup-python
  `a309ff8…`, setup-node `48b55a0…`, cache `27d5ce7…`) so the release path and CI path drift
  together when the pins are bumped.
- The publish jobs (`github-release`, `npm-publish`, `pypi-publish`) each declare `needs: [gate, …]`,
  so **no artifact is published unless the gate is green** on the tagged commit. `kb-hygiene` checks
  (CRLF / `.aid/.temp` untracked / INDEX freshness) are repo-hygiene, not release-correctness, so
  they are *not* re-run in `gate` — they have no bearing on the released bytes; we keep `gate` to the
  three jobs that prove the artifact is correct (render-drift, canonical suites, generator
  self-tests). (Flagged as a deliberate trade-off, not an omission.)

> **DRY note (refinement, not a blocker):** the gate duplicates ~30 lines of `test.yml`. This is
> intentional for a first cut (a tag-trigger workflow cannot `needs:` a job in a different workflow
> file, and a reusable-workflow extraction is a larger refactor of `test.yml` that would touch the
> protected required-check). A future hardening is to extract the three correctness jobs into a
> `workflow_call` reusable workflow consumed by both `test.yml` and `release.yml`; deferred so this
> feature does not modify the protected `test.yml`.

### S3. Version-sync assertion (FR10 — runs in the gate, before any publish)

A dedicated **`version-sync`** step (in the `gate` job, after checkout) is the FR10 enforcement
point. It is the **single pre-publish assertion that all four version carriers agree**, and it
**fails the release on any mismatch** (REQUIREMENTS FR10; AC "mismatch fails the release").

```bash
# EXPECT is the authoritative version derived once at the top of the gate job
# (the "Derive authoritative version" step exported VERSION=<bare semver> into $GITHUB_ENV; S1).
EXPECT="${VERSION}"                                     # e.g. '0.7.0' (from tag v0.7.0)
fail=0
check () { [ "$2" = "$EXPECT" ] || { echo "::error::$1 = '$2', expected '$EXPECT' (from tag v$EXPECT)"; fail=1; }; }
check VERSION              "$(cat VERSION)"
check package.json         "$(node -p 'require("./package.json").version')"
check pyproject.toml       "$(python -c 'import tomllib,sys; print(tomllib.load(open("pyproject.toml","rb"))["project"]["version"])')"
[ "$fail" = 0 ] || exit 1
```

**Cross-job propagation of `VERSION`.** `$GITHUB_ENV` is job-scoped, so the bare semver derived in
`gate` is re-exposed to the publish jobs (separate jobs) via a `gate` job **output**, which each
publish job re-imports into its own `$GITHUB_ENV`. Concretely, the derivation step writes both
`$GITHUB_ENV` (for the rest of the `gate` job, e.g. `version-sync`) and `$GITHUB_OUTPUT`, and the
`gate` job declares the output:

```yaml
jobs:
  gate:
    runs-on: ubuntu-24.04
    outputs:
      version: ${{ steps.ver.outputs.version }}    # bare semver, e.g. '0.7.0'
    steps:
      # … checkout + setup-python …
      - id: ver
        name: Derive authoritative version from the tag/ref (strip leading 'v')
        shell: bash
        run: |
          RAW="${{ inputs.ref || github.ref_name }}"
          echo "VERSION=${RAW#v}" >> "$GITHUB_ENV"     # for version-sync (this job)
          echo "version=${RAW#v}" >> "$GITHUB_OUTPUT"  # for the publish jobs (S4)
```

Each publish job then re-imports it (so every `${VERSION}` reference in S4 resolves):

```yaml
  npm-publish:
    needs: [gate, github-release]
    env:
      VERSION: ${{ needs.gate.outputs.version }}     # same bare semver the gate verified
```

(`github-release` and `pypi-publish` declare the identical `env: VERSION:` from `needs.gate.outputs.version`.)

Reconciliation rule (SETTLED HERE for FR10):

- **The git tag `v<VERSION>` is the single source of truth at release time.** The workflow **derives
  the version from the tag and verifies the four files match it** — it does **not** mutate any file
  during the release (no in-CI bump-and-commit; the release is built from the committed, tagged
  bytes). This keeps the released artifact byte-identical to a reviewed, merged commit and avoids a
  CI commit racing branch protection.
- **The four carriers and their relationship:**
  1. git tag `v<VERSION>` — authoritative, supplied by the maintainer.
  2. `VERSION` file — the in-repo source of truth feature-002 already keys tarball names + tag off
     of (`release.sh` FAILs on a `--version`/`VERSION` mismatch; S4 of feature-002).
  3. `package.json` `version` (feature-003) — must equal `VERSION`.
  4. `pyproject.toml` `[project].version` (feature-004) — must equal `VERSION`.
  All four must equal the bare semver `${TAG#v}` or the release fails **before** `release.sh` runs
  and before any publish — so a mismatch can never ship a partial release.
- **Bumping (pre-tag, maintainer-side, NOT in this workflow):** the maintainer (or a small
  `bump-version.sh` helper — proposed, owned here as a follow-up, not required for the first cut)
  edits `VERSION` + `package.json` + `pyproject.toml` in one commit, merges it through the normal
  gated PR, then tags that commit `v<VERSION>`. The workflow's job is to *verify*, not to *author*,
  the version. This makes the assertion a pure read-only check that is also runnable locally and as a
  unit test (S7).
- **First-release reality:** until feature-003/004 land, `package.json` / `pyproject.toml` do not
  exist. The `version-sync` step treats a *missing* manifest as a skip-with-notice **only when its
  corresponding publish job is not selected** (S8 bootstrapping); once a manifest exists it is
  always checked. (Concretely: the npm/PyPI checks are gated on the file existing AND that channel
  being enabled; a present-but-mismatched manifest always fails.)

### S4. Publish steps (order, idempotency, fail-fast)

All publish jobs `needs: [gate]` (gate includes `version-sync`), so they start only from a
green, version-consistent, tagged commit. They run in this dependency order to fail fast on the
cheapest irreversible action first and to avoid a partial publish where avoidable:

**Job `github-release` (`needs: gate`)** — the canonical artifacts, first because every other
channel references the GitHub Release. It re-imports the verified bare semver as
`env: VERSION: ${{ needs.gate.outputs.version }}` (S3) so `${VERSION}` resolves below:

```yaml
# job-level: env: { VERSION: "${{ needs.gate.outputs.version }}" }   # the gate-verified bare semver
- uses: actions/checkout@de0fac2… { ref: ${{ inputs.ref || github.ref }} }
- uses: actions/setup-python@a309ff8… { python-version: '3.11' }
- name: Build tarballs + SHA256SUMS + GitHub Release (feature-002)
  env: { GH_TOKEN: ${{ github.token }} }
  run: |
    if [ "${{ inputs.dry_run }}" = "true" ]; then
      bash release.sh --version "${VERSION}" --dry-run        # build + checksums, no gh, no tag
    else
      bash release.sh --version "${VERSION}"                  # builds + gh release create
    fi
```

- This **invokes `release.sh`** (feature-002) — it does not duplicate packaging. `release.sh` already
  re-runs the render-drift check internally (defence in depth: even though `gate` proved it,
  `release.sh` re-asserts), builds the five `aid-<tool>-v<VERSION>.tar.gz`, emits `SHA256SUMS`, and
  runs `gh release create v<VERSION> …`. `GH_TOKEN` is the built-in `GITHUB_TOKEN` (auth for `gh`).
- **Idempotency:** `release.sh` step 1 already pre-checks tag/release existence and aborts if the
  tag or a Release for it already exists (feature-002 S1). On a *re-run for an existing tag*, that is
  a no-op-or-fail by design — the recovery path is to delete the draft/Release and re-run, OR run the
  publish-only jobs against the existing Release (the npm/PyPI jobs do not need `release.sh` to have
  re-created the Release; they build from the checked-out source). See S5.

**Job `npm-publish` (`needs: [gate, github-release]`)** — feature-003's `@aid/installer`
(job-level `env: VERSION: ${{ needs.gate.outputs.version }}`, per S3):

```yaml
# job-level: env: { VERSION: "${{ needs.gate.outputs.version }}" }
- uses: actions/checkout@de0fac2… { ref: ${{ inputs.ref || github.ref }} }
- uses: actions/setup-node@48b55a0…
  with: { node-version: '20', registry-url: 'https://registry.npmjs.org' }
- run: npm ci      # deterministic install from the committed package-lock.json (see note)
- name: Publish with provenance
  if: ${{ inputs.dry_run != true }}
  env: { NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }} }
  run: npm publish --provenance --access public
```

- **Deterministic install — `npm ci` (not `npm ci || npm install`).** feature-003's package ships
  `"dependencies": {}`, so the install does no dependency resolution either way; the point of `npm ci`
  here is the *fail-closed determinism* it guarantees (it requires a committed `package-lock.json` and
  errors on any drift between it and `package.json`). The earlier `|| npm install` fallthrough was
  non-deterministic — with no lockfile it would *always* fall through to `npm install` (which can
  mutate the lockfile), defeating the purpose. **Requirement on feature-003:** commit a
  `package-lock.json` (even one with empty deps) and add it to the `files`/publish allowlist's git
  tracking. With that lockfile present, `npm ci` is the single deterministic command. (If feature-003
  ultimately ships with no lockfile by design, replace this step with `npm install --no-package-lock
  --ignore-scripts` — an explicitly deterministic no-op for empty deps — rather than the
  `ci || install` fallthrough.)
- `--provenance` emits a signed SLSA provenance attestation tied to this workflow's OIDC identity
  (needs `id-token: write`, already granted; npm CLI ≥ 9.5, satisfied by node 20). `--access public`
  is required for a first publish of a **scoped** package (`@aid/installer`).
- **Auth:** stable path is the classic **`NPM_TOKEN`** automation token in repo secrets +
  `--provenance` for the attestation. *(npm "Trusted Publishing" / OIDC-without-token went GA in
  2025; if confirmed available for the `@aid` scope at build time, prefer it and drop `NPM_TOKEN`.
  Flagged "verify npm Trusted Publishing support" — REQUIREMENTS §8. Provenance itself does not
  require dropping the token.)*
- **Prerequisite (feature-003 / REQUIREMENTS §8):** the **`@aid` npm scope must exist and be owned by
  the maintainer**. Until then this job cannot publish (S8).
- **Idempotency:** npm **rejects republishing an existing version** (`E403 cannot publish over
  previously published version`). Re-running on an already-published version fails this job but harms
  nothing already shipped. Guard: `npm view @aid/installer@${VERSION}` → skip-with-notice if present
  (so a re-run to fix only PyPI does not red-fail on npm).

**Job `pypi-publish` (`needs: [gate, github-release]`, parallel with `npm-publish`)** —
feature-004's package under the CasuloAI Labs org
(job-level `env: VERSION: ${{ needs.gate.outputs.version }}`, per S3):

```yaml
# job-level: env: { VERSION: "${{ needs.gate.outputs.version }}" }
- uses: actions/checkout@de0fac2… { ref: ${{ inputs.ref || github.ref }} }
- uses: actions/setup-python@a309ff8… { python-version: '3.11' }
- run: python -m pip install --upgrade build && python -m build      # sdist + wheel into dist/
- name: Publish via Trusted Publishing (OIDC, no token)
  if: ${{ inputs.dry_run != true }}
  # SHA-pin (NOT the moving `@release/v1` tag), matching test.yml's pin-by-SHA convention
  # and the resolved supply-chain posture (infrastructure.md C1). The implementer MUST pin
  # to the commit SHA of a specific published release:
  #   pin to the SHA of pypa/gh-action-pypi-publish vN.M.K (the Trusted Publishing action)
  uses: pypa/gh-action-pypi-publish@<commit-sha> # vN.M.K  (pin to the SHA of a published release)
  # no `password:` — OIDC id-token is exchanged for a short-lived PyPI token; attestations on by default
```

- **PyPI Trusted Publishing** uses the OIDC `id-token` (no long-lived `PYPI_TOKEN`), and the
  `pypa/gh-action-pypi-publish` action emits PEP 740 / sigstore attestations by default
  (REQUIREMENTS §6 "PyPI via Trusted Publishing (sigstore attestations)"). *(Flagged "verify Trusted
  Publishing support / current action tag" — REQUIREMENTS §8.)*
- **SHA-pinning is mandatory for every `uses:` in this workflow** (no moving tags such as
  `@release/v1`, `@v1`, or `@main`), matching `test.yml`'s convention and the resolved supply-chain
  posture (`infrastructure.md` C1, "unpinned fetch resolved 2026-05-29"). The four CI-shared actions
  reuse `test.yml`'s exact SHAs (S2); the PyPI publish action — the most security-sensitive step —
  MUST likewise be pinned to the commit SHA of a specific published release, with the human-readable
  version as a trailing comment (`@<sha> # vN.M.K`). This is verified by `actionlint` (S7), which
  flags unpinned third-party actions.
- **Hard prerequisite (feature-004 blocker):** the **CasuloAI Labs PyPI org must be registered, the
  package name reserved, AND a Trusted Publisher configured** on PyPI pointing at
  `AndreVianna/aid-methodology` + workflow `release.yml` (+ environment, if used). Until that exists
  this job cannot authenticate — it is the gating external dependency for the M3b/M7 channel (S8).
- **Idempotency:** PyPI **rejects re-uploading an existing version** (`400 File already exists`); the
  publish action supports `skip-existing: true` to make a re-run idempotent. Recommended on so a
  re-run to fix only npm does not red-fail on PyPI.

**Atomicity caveat:** GitHub Release, npm, and PyPI are three independent registries with no
distributed transaction. We minimise partial-publish exposure by (a) gating all three on `gate`, (b)
ordering the GitHub Release first, (c) per-channel `skip-existing`/`npm view` guards so a re-run
completes only the missing channels. A truly atomic 3-way publish is not achievable; the operational
contract is "re-run the workflow until all three report published/skipped."

### S5. Secrets / identity

| Identity | Used by | Mechanism | Notes |
|---|---|---|---|
| `GITHUB_TOKEN` (built-in) | `github-release` (`gh release create`, asset upload) | auto-injected; `contents: write` | No PAT; same-repo scope only. |
| OIDC `id-token` | `npm-publish` (provenance), `pypi-publish` (auth + attestation) | `permissions: id-token: write` | No long-lived signing key; the §8 OIDC-preferred posture. |
| `secrets.NPM_TOKEN` | `npm-publish` | classic automation token | Stable path. Drop if/when npm Trusted Publishing is confirmed for `@aid` (verify). |
| *(none for PyPI)* | `pypi-publish` | Trusted Publishing (OIDC) | **No** `PYPI_TOKEN` — preferred over a long-lived token per §8 (verify support). |

### S6. Idempotency, dry-run, and safety

- **`dry_run` (workflow_dispatch input):** runs `gate` + `version-sync` + `release.sh --dry-run`
  (tarballs + `SHA256SUMS` into staging, no `gh`, no tag) + `npm publish --dry-run`-equivalent
  (build only) + `python -m build` (no upload). Validates the whole pipeline with zero irreversible
  side-effects — the safe pre-flight before a real tag.
- **Re-run on an existing tag:** each publish job is independently guarded (release pre-check;
  `npm view …` skip; PyPI `skip-existing`), so re-running converges on "all channels published"
  without double-publishing. The registries' own republish-rejection is the backstop.
- **Fail-fast:** `set -euo pipefail` in every `run:` block; any non-zero step fails its job; publish
  jobs never start unless `gate` (render-drift + suites + self-tests + version-sync) is green.

### S7. Testing / validation

- **`version-sync` as a unit test (primary, CI-able):** factor the S3 assertion into a tiny script
  (e.g. `tests/canonical/test-version-sync.sh` or a vendored `scripts/check-version-sync.sh`
  driven by a test). Cases: (VS01) all four agree → pass; (VS02) `package.json` differs → fail with
  the offending carrier named; (VS03) `pyproject.toml` differs → fail; (VS04) missing manifest with
  that channel disabled → skip-with-notice; (VS05) tag `v1.2.3` → `EXPECT=1.2.3`. This is the
  FR10 acceptance check and is auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh`
  glob — so it *also* runs in the existing `test.yml`, catching version drift on every PR, not only
  at release time. (This is the single biggest test-leverage point: FR10 becomes a permanent CI
  invariant, not a release-only gate.)
- **Workflow validation:** lint with `actionlint`; exercise the non-publish portion locally with
  `act` (`act push -e <tag-event.json>` runs `gate` + `--dry-run`; publish steps are guarded by
  `if: dry_run != true` and the registry secrets, so `act` cannot accidentally publish).
- **Real-world smoke:** the first real run is itself the bootstrap test (S8) — start with a
  GitHub-Release-only tag (npm/PyPI jobs skipped via S8 enable flags) before the scopes/orgs exist.

### S8. First-release bootstrapping (channels don't exist yet)

The first tag will predate the `@aid` scope and the CasuloAI Labs PyPI org. The workflow must release
the GitHub-Release channel **without** failing on the not-yet-publishable channels:

- **Channel enable flags:** repo/workflow variables `vars.NPM_ENABLED` / `vars.PYPI_ENABLED`
  (default `false`). `npm-publish` / `pypi-publish` carry `if: vars.NPM_ENABLED == 'true'` /
  `if: vars.PYPI_ENABLED == 'true'`. `version-sync` only enforces a manifest when its channel is
  enabled (S3) — so the GitHub Release ships at v0.7.0 with no `package.json`/`pyproject.toml`
  present, and the npm/PyPI checks light up only once those features land and their flags flip.
- **Enable sequence:** (1) feature-005 ships GitHub-Release-only automation; (2) feature-003 lands
  `package.json` + `@aid` scope acquired → flip `NPM_ENABLED`; (3) feature-004 lands `pyproject.toml`
  + CasuloAI Labs org registered + Trusted Publisher configured → flip `PYPI_ENABLED`. Each flip is a
  one-line repo-variable change, not a workflow edit.

### S9. Optional hardening (deferred, not in this cut)

- **SHA256SUMS signing (cosign/SLSA).** feature-002 already emits `SHA256SUMS`; a `--sign` cosign
  keyless path (OIDC, aligns with the `id-token: write` posture already present) is the recommended
  automated-signing candidate (feature-002 S3.2 routed the decision here). Deferred to a follow-up:
  `SHA256SUMS` + npm provenance + PyPI attestations already satisfy the §6 supply-chain ACs.
- **SLSA build-provenance for the tarballs** (`slsa-framework/slsa-github-generator`) — future.
- **Reusable-workflow extraction** of the three correctness jobs shared with `test.yml` (S2 DRY
  note) — future, because it touches the protected `test.yml`.

### S10. Risks / open questions

- **R1 — npm Trusted Publishing maturity (VERIFY).** Stable path uses `NPM_TOKEN` + `--provenance`.
  npm OIDC Trusted Publishing (token-less) reached GA in 2025; confirm it supports the `@aid` scope
  before dropping `NPM_TOKEN`. Provenance does not depend on this. (REQUIREMENTS §8.)
- **R2 — PyPI Trusted Publishing config (VERIFY + external).** Requires the CasuloAI Labs org
  registered, the package name reserved, and a Trusted Publisher bound to
  `AndreVianna/aid-methodology` + `release.yml` *before* the first PyPI run. This is feature-004's
  hard external blocker; the `PYPI_ENABLED` flag (S8) keeps it from blocking the GitHub-Release path.
- **R3 — gating vs. branch protection coexistence (RESOLVED, stated to verify the assumption).** Tag
  pushes are not governed by `master` branch protection, so the release **re-runs the gate itself**
  (S2) rather than relying on a required-check it cannot inherit. `test.yml` and branch protection
  are untouched. *Verify the assumption that no org policy auto-applies required checks to tag refs.*
- **R4 — first-release bootstrapping (HANDLED, S8).** Channel enable flags let v0.7.0 ship the
  GitHub Release before the scope/org exist; npm/PyPI light up as their prerequisites land.
- **R5 — partial publish (MITIGATED, S4).** No cross-registry transaction exists; mitigated by gating
  + ordering + per-channel `skip-existing`/`npm view` guards + "re-run to converge." Surfaced, not
  eliminated.
- **R6 — OIDC `id-token` scope is workflow-wide.** `id-token: write` at the workflow level is
  available to all jobs; acceptable here (only the two publish jobs use it) but note for any future
  job added to this file. A tighter cut would move `id-token: write` to job-level on the two publish
  jobs only — recommended refinement.
- **R7 — release built from committed bytes, not a CI bump (DESIGN, S3).** The workflow verifies the
  version, it does not author it. A maintainer who tags before bumping all four carriers gets a
  fail-fast `version-sync` error (the intended behaviour), not a silent mismatch.

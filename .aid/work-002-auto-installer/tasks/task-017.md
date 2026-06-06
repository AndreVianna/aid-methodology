# task-017: Version-sync unit test + workflow validation

**Type:** TEST

**Source:** feature-005-ci-release-automation-and-version-sync → delivery-004

**Depends on:** task-016

**Scope:**
- Factor the FR10 assertion into a small script (e.g. `tests/canonical/test-version-sync.sh` or a vendored `scripts/check-version-sync.sh` driven by a test) auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob — so FR10 is a permanent CI invariant on every PR, not only at release time.
- Cover VS01–VS05: all four carriers agree → pass; `package.json` differs → fail naming the carrier; `pyproject.toml` differs → fail; missing manifest with that channel disabled → skip-with-notice; tag `v1.2.3` → `EXPECT=1.2.3`.
- Validate `release.yml` with `actionlint` (flagging any unpinned third-party action) and exercise the non-publish portion with `act` (`act push -e <tag-event.json>` running `gate` + `--dry-run`; publish steps guarded by `if: dry_run != true` + registry secrets so `act` cannot publish).
- **Tooling prerequisite:** `actionlint` and `act` are not assumed present in the §6 gate env — probe for each and **skip-with-notice** (do not hard-fail the suite) when a tool is absent; the static `actionlint` SHA-pin check is the load-bearing, env-independent assertion.
- **Coverage boundary (OIDC publish path):** `act` cannot exercise the live OIDC/Trusted-Publishing path (no real registry/sigstore in CI). The publish/auth path is validated by static lint (`actionlint` SHA-pin) + the `--dry-run` build, **not** by a live publish — a real first publish remains a manual, observed release step. This partial coverage is intentional, not a gap.

**Acceptance Criteria:**
- [ ] The version-sync check is auto-discovered by `tests/run-all.sh` (so it runs in `test.yml` on every PR) and passes VS01–VS05, naming the offending carrier on mismatch.
- [ ] `actionlint` passes on `release.yml` and flags zero unpinned third-party actions (every `uses:` is SHA-pinned).
- [ ] `act` exercises `gate` + `--dry-run` locally without publishing (publish steps gated off), confirming the gate + version-sync path runs end-to-end.
- [ ] **Tool prerequisite handled:** when `actionlint`/`act` are absent from the gate env, the suite skips-with-notice rather than hard-failing; the env-independent `actionlint` SHA-pin assertion is the load-bearing check.
- [ ] **OIDC publish-path boundary stated:** the OIDC/Trusted-Publishing publish path is validated only by static lint + `--dry-run` (not a live publish in CI); the live first publish is an explicit manual/observed step, and this partial coverage is documented as intentional.
- [ ] All §6 quality gates pass.

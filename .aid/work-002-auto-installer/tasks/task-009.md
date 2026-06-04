# task-009: Install / update / uninstall flow documentation (M2 channels)

**Type:** DOCUMENT

**Source:** feature-001-shared-install-core-and-bootstrap → delivery-001

**Depends on:** task-006, task-008

**Scope:**
- Document the new one-command install / update / uninstall flow for the M2 channels (`curl … | bash` online, `irm … | iex`, and `--from-bundle` offline tar) across both `install.sh` and `install.ps1`.
- Document the CLI surface: `--tool` (auto-detect default + comma-list), `--version` pinning, `--from-bundle`, `--force`, `--update`, `--uninstall`, `--target`; canonical tool ids; the host-tool detection rules and ambiguity errors.
- Document protect-on-diff behavior (FR11): what `*.aid-new` means, the default exit 5 on a blocked root agent file, and how `--force` overrides; set expectations for the pre-FR12 multi-tool `AGENTS.md` warning until feature-006 lands.
- Document the offline verify-before-install workflow against `SHA256SUMS`, version recording (`.aid/.aid-version` + manifest), and the GitHub-API rate-limit guidance (`--version`/`$GITHUB_TOKEN`/`--from-bundle`).
- Place docs in the appropriate hand-maintained surfaces (e.g. `README.md` install section, `docs/`); update wherever task-008 removed `setup.sh` walkthroughs so the new flow replaces them.
- Author a persistent maintainer release-cut runbook/checklist for the first manual `gh release create` (the pre-feature-005 path) in a hand-maintained docs surface: preconditions, `release.sh --dry-run` then `--draft` review, the **default tar.gz-only** asset set, the `SHA256SUMS` publish step, and the recovery/idempotency notes.

**Acceptance Criteria:**
- [ ] The install/update/uninstall flow is documented for online curl, `irm | iex`, and offline `--from-bundle` paths, covering every CLI flag and the canonical tool ids.
- [ ] Protect-on-diff is documented including the `*.aid-new` artifact and the **default exit 5** behavior, plus the pre-FR12 multi-tool `AGENTS.md` expectation.
- [ ] The offline verify-against-`SHA256SUMS` workflow and the GitHub-API rate-limit guidance are documented; version recording is explained.
- [ ] Docs reference the **default** manifest location `.aid/.aid-manifest.json` and do not reintroduce any `setup.sh`/`setup.ps1` walkthrough.
- [ ] A persistent maintainer first-release runbook/checklist (manual `gh release create`, `release.sh --dry-run`/`--draft` review, recovery path) is published in a hand-maintained docs surface and references the **default tar.gz-only** asset set.
- [ ] All §6 quality gates pass.

# task-015: PyPI org registration prerequisite + publish runbook

**Type:** DOCUMENT

**Source:** feature-004-pypi-installer-cli → delivery-003

**Depends on:** task-014

**Scope:**
- Document the hard external blocker (feature-004 §S8/§S10 R1) and the steps to clear it: register the CasuloAI Labs organization/account on PyPI, reserve the `aid-installer` project name under that org, and configure Trusted Publishing (the GitHub repo + `release.yml` workflow as a trusted publisher) — flagged as coordinated with feature-005.
- Document the manual build/publish runbook (`python -m build` → sdist + wheel with `_vendor/` package data) and the pipx/pip UX surface + offline caveats from §S6 (primary `pipx run aid-installer` / `pipx run --spec aid-installer aid`; secondary `pipx install`/`pip install --user`; the `pipx run` not-offline-by-default caveat pointing air-gapped users at M2 `--from-bundle`).
- Record the SPEC-flagged defaults so docs are testable against them: package name `aid-installer`, `requires-python >=3.8`.
- Surface the `license` field reconciliation (§S10 R7) as an **explicit pre-publish confirm item** in the runbook: `pyproject.toml` `license` must match the repo `LICENSE`, verified/confirmed by feature-005 before the first publish.

**Acceptance Criteria:**
- [ ] The PyPI registration prerequisite (CasuloAI Labs org + `aid-installer` name reservation + Trusted Publisher config) is documented as the gating step before any publish, coordinated with feature-005.
- [ ] The manual `python -m build` runbook and the pipx/pip UX surface (incl. the `pipx run` offline caveat and the M2 air-gap fallback) are documented.
- [ ] Docs reference the **default** package name `aid-installer` and the **default** `requires-python >=3.8` floor.
- [ ] The runbook lists the `license` reconciliation (§S10 R7 — `pyproject.toml` `license` == repo `LICENSE`) as an **explicit pre-publish confirm item** gated on feature-005, not just an implicit note.
- [ ] All §6 quality gates pass.

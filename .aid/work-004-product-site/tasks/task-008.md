# task-008: One-time DNS + GitHub Pages custom-domain setup runbook

**Type:** DOCUMENT

**Source:** feature-002-build-and-deploy → delivery-001

**Depends on:** task-007

**Scope:**
- Document the exact one-time, out-of-band manual steps that gate AC2 (live HTTPS at the custom domain) — these are NOT automatable by the workflow (Cross-Cutting Risk #2):
  1. Repo Settings → Pages → Source = GitHub Actions.
  2. Repo Settings → Pages → Custom domain = `aid.casuloailabs.com` (add the domain in GitHub BEFORE creating the DNS record, to avoid takeover risk).
  3. GoDaddy DNS: add the `aid` `CNAME` → `AndreVianna.github.io`.
  4. Wait for Let's Encrypt provisioning (~24h), then enable Enforce HTTPS.
- Note that the committed `public/CNAME` prevents the custom-domain setting being wiped on each Actions deploy.
- Record that AC1 (builds+deploys to Pages) is independently verifiable ahead of AC2 (custom domain) so the delivery is not fully blocked on cert timing.
- Place the runbook where the operator will find it (the work's STATE/PLAN or a `docs/`-adjacent ops note as the project convention dictates).

**Acceptance Criteria:**
- [ ] The four manual steps are documented in exact, ordered form (GitHub-before-DNS ordering called out).
- [ ] The committed-`CNAME` rationale and the ~24h HTTPS provisioning wait are recorded.
- [ ] AC1-before-AC2 verifiability note is present so progress is not gated on cert timing.
- [ ] Accuracy verified against feature-002's SPEC and the live repo Pages/DNS settings model.
- [ ] All §6 quality gates pass.

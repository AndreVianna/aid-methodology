# task-024: LC-2 _aid_remote_expose/_teardown in bin/aid (Bash) + FR18 ACL-grant guidance

**Type:** IMPLEMENT

**Source:** feature-005-secure-remote-exposure → delivery-003

**Depends on:** task-021

**Scope:**
- Implement `_aid_remote_expose` / `_aid_remote_teardown` in the hand-maintained root `bin/aid` (Bash, LC-EXP-B), making the feature-004 `--remote` stub real per the ratified LC-2 contract.
- `expose(port)` (Feature Flow): re-assert the loopback target (non-loopback → exit 11); availability detect (`tailscale` on PATH + `tailscale status` logged-in/Running, else exit 10); bring up `tailscale serve --bg <port>` (tailnet-only — NEVER funnel; serve failure → revert + exit 12); resolve the private URL from `tailscale serve status --json`/`status --json`; print the FR18 step-by-step ACL-grant guidance block (SEC-2 — exact policy-file URL, the literal deny-by-default grant to paste with `dst` = this host, the verify step; substitute detected identity/FQDN); emit the opaque handle `tailscale-serve:<port>` (line 1) + the URL (line 2) on stdout, exit 0.
- `teardown(handle)`: parse `tailscale-serve:<port>` (malformed/empty → idempotent exit 0); revert via `tailscale serve --bg --https=443 off` (single-frontend model; `serve reset` only as fallback when no other mappings); never funnel reset; revert failure → exit 13.
- ASCII-only (the FR18 reminder string is ASCII, LC-3); never bind a socket / widen a bind / edit the tailnet policy file. Refresh vendored copies via the vendor step.

**Acceptance Criteria:**
- [ ] `expose <port>` with Tailscale present+logged-in runs `tailscale serve --bg <port>` (never funnel), prints the handle line `tailscale-serve:<port>` + a `https://…` private URL, and prints the FR18 step-by-step grant guidance (exact URL + literal grant + verify), exit 0.
- [ ] Availability failures exit 10; a non-loopback target exits 11; a serve failure reverts and exits 12 — all leaving the dashboard local-only and nothing public (SEC-1/SEC-3/C1).
- [ ] `teardown` reverts the single 443 serve frontend (not a blind `reset` when other mappings exist), is idempotent (malformed/double teardown → exit 0), and exits 13 on a revert warning.
- [ ] No `funnel`/`--funnel` token appears in the exposure helpers (SEC-1, grep-asserted); no socket bind, no bind widening, no policy-file edit.
- [ ] `bin/aid` (incl. the SEC-2 reminder string) passes the ASCII-only gate.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit/CLI tests for the new helpers added (full suite + parity is task-026); existing tests pass; build passes.

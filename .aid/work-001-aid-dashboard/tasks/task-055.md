# task-055: `--remote` (DR-4) re-target — feature-005 expose now fronts the CLI home (all registered repos)

**Type:** IMPLEMENT

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-047, task-049, task-052

**Scope:**
- Land DR-4 (OQ5 RESOLVED): `aid dashboard start <runtime> --remote` now exposes the **CLI home (all registered repos)** instead of a single repo's page — a serving-scope adjustment over feature-005's **unchanged** mechanism. This is the small wiring/verification task the PLAN flags for `--remote`.
- **Mechanism unchanged (verify, don't rewrite):** the feature-005 expose helper (`_aid_remote_expose` / PS twin, `bin/aid:540-721`), its tailnet-only `tailscale serve` invocation, FR18 ACL-grant guidance, the `dashboard.pid` `remote_handle` record, and teardown are **all unchanged**. The helper exposes "the loopback port"; *what* lives behind it is decided by DR-2 (task-047 already relocated the spawn to the machine server). The net change is conceptual: the port now fronts `/` (CLI home) → a grantee lands on the registered-repo list and can navigate into any repo's `/r/<id>/{home.html,kb.html,api/model}`.
- **Verification this task owns:** with the machine server running (task-047 spawn relocation + task-050/051 routes), `--remote` brings up the multi-repo server on the loopback port then exposes that port; confirm the **never-public** structural guarantee (SEC-1: literal `127.0.0.1` bind; `tailscale serve` tailnet-only, never `funnel`/public — the feature-005 grep self-check still passes) and the host/user-ACL scoping (C3) hold unchanged over the new page.
- **SEC-6 trade-off note (the only new posture):** exposing the repo **list** (paths/names) to a *granted* tailnet identity is the accepted OQ5 trade-off; add/confirm the documentation/guidance reflects this. No new exposure code, no new bind, no new public path.
- If task-052 resolved `aid dashboard --target` to option (a) auto-register + deep-link, confirm `--remote --target <repo>` still lands the grantee on `/` (the home stays reachable) — a consistency check only.
- **Shared-writer serialization:** this task edits `bin/aid`/`bin/aid.ps1`, as do task-047 (spawn seam) and task-049 (registry side-effect). It therefore depends on task-049 (in addition to task-047) so the three `bin/aid` writers land serially (047 → 049 → 055), never racing the same file.
- ASCII-only; vendored-copy refresh if any `bin/aid`/`.ps1` text changes; NOT render-drift.

**Acceptance Criteria:**
- [ ] `aid dashboard start <runtime> --remote` exposes the loopback port fronting the **CLI home** (all registered repos) via feature-005's unchanged `tailscale serve` path; a grantee opening the private `.ts.net` URL lands on `/` and can navigate into any registered repo's `/r/<id>/...`.
- [ ] The never-public structural guarantee holds: literal `127.0.0.1` bind (SEC-1), `tailscale serve` tailnet-only (no `funnel`/public token — feature-005 self-check passes), host/user-ACL scoping (C3) unchanged; the expose helper, teardown, `remote_handle` record, and FR18 guidance are byte-unchanged.
- [ ] The SEC-6 repo-list-to-grantees accepted-trade-off is reflected in the guidance/docs; no new exposure code or bind is introduced.
- [ ] `bin/aid`/`bin/aid.ps1` (if touched) pass ASCII-only + parity; vendored copies refreshed; not render-drift.
- [ ] All §6 quality gates pass; the `--remote` clear-fail/idempotent-teardown behavior from delivery-003 stays green over the re-targeted page (full parity suite is task-057).

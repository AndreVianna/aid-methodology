# task-014: LC-1 spawn seam — server entry-point filenames + --root/--host/--port arg grammar

**Type:** DESIGN

**Source:** feature-003-pipeline-dashboard-app + feature-004-cli-dashboard-control → delivery-002

**Depends on:** task-010

**Scope:**
- Ratify the LC-1 spawn seam between feature-004 (the CLI that spawns) and feature-003 (the server it spawns) — feature-004 proposed entry-point names + arg grammar feature-003 names neither yet (PLAN R3).
- Decide + document, as the binding contract both later tasks implement: the server entry-point filenames `server.py` (python) / `server.mjs` (node) under the dashboard assets dir; the invocation arg grammar `--root <target> --host 127.0.0.1 --port <n>`; the readiness/exit semantics (non-zero on bind failure, nothing required on stdout — the CLI prints the URL); where the assets live in the install tree.
- Confirm the seam against feature-002's `read_repo(aid_root)` (the `--root` maps to the reader's `aid_root`) and feature-004 CLI-1 grammar / Feature Flow step 6-7.

**Acceptance Criteria:**
- [ ] The entry-point filenames (`server.py` / `server.mjs`), their install-tree location, and the `--root/--host/--port` arg grammar are documented as the LC-1 contract both task-016/017 (server) and task-021/022 (CLI) build against.
- [ ] The readiness + exit-code semantics (non-zero on bind fail; bind host is the literal `127.0.0.1`, never configurable to a wider bind) are specified, consistent with feature-003 LC-S bind invariant and feature-004 SEC-1.
- [ ] The `--root` argument is reconciled with feature-002 `read_repo(aid_root)` so the spawned server serves the correct repo.
- [ ] The design records ≥2 alternatives where a real choice exists (e.g. entry-point naming / arg style) and a justified recommendation, with sources being the feature-003/004 SPECs.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] DESIGN default: the contract reuses the project's conventions and is responsive to both consuming features (no unilateral decision that breaks either SPEC); design rationale + trade-offs documented.

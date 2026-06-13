# Known Issues

<!-- Scoped to this work. Only issues that affect features in this work. -->
<!-- Created/updated by aid-specify during codebase exploration. -->
<!-- Consumed by aid-plan for deliverable sequencing. -->

## KI-001: `## Calibration Log` + task `## Dispatches` sub-column are written but undefined in any state template

- **Status:** ✅ RESOLVED (delivery-001 / task-001 M0, commit babb4d9) — `## Calibration Log` + task `## Dispatches` now declared in `work-state-template.md`; reconciled with `pipeline-contracts.md`.
- **Type:** Breaking API Contract (document/schema contract)
- **Severity:** Medium
- **Affects:** feature-001-pipeline-state-architecture
- **Source:** Producers write these sections —
  `canonical/skills/aid-discover/SKILL.md:105`,
  `canonical/skills/aid-monitor/SKILL.md:162-164`,
  `canonical/skills/aid-housekeep/SKILL.md:89`,
  `canonical/skills/aid-execute/references/state-execute.md` (`## Calibration Log`) — but
  neither `canonical/templates/work-state-template.md` nor
  `canonical/templates/discovery-state-template.md` declares a `## Calibration Log` section
  or a task `## Dispatches` sub-column. `pipeline-contracts.md` lists `## Calibration Log` as
  a required work-STATE section ("Every dispatcher (always-on, work-003)") but the template it
  cites has no such heading.
- **Description:** The dispatch-protocol writers create `## Calibration Log` on demand
  ("create section if missing"), so the section's column shape is producer-defined, not
  schema-defined, and the `## Dispatches` "sub-column" has no template home at all. This is
  exactly the kind of schema-vs-producer drift the FR17 normalization must close: a
  deterministic reader (feature-002) cannot rely on a section that no template guarantees.
- **See also:** This work's SPEC.md `## Technical Specification` (current-state inventory,
  row "Calibration Log / Dispatches").

## KI-002: IMPEDIMENT file path is documented two different ways (schema vs producer)

- **Status:** ✅ RESOLVED (delivery-001 / task-001 M0, commit babb4d9) — `schemas.md §13` reconciled to the flat `.aid/{work}/IMPEDIMENT-task-NNN.md` producer path (agrees with `pipeline-contracts.md`).
- **Type:** Breaking API Contract (document/schema contract)
- **Severity:** Medium
- **Affects:** feature-001-pipeline-state-architecture
- **Source:** `.aid/knowledge/schemas.md:504` declares the IMPEDIMENT path as
  `.aid/{work}/task-NNN/IMPEDIMENT.md`, but the actual producer
  `canonical/skills/aid-execute/references/state-execute.md:322,368` and
  `canonical/skills/aid-execute/SKILL.md:240,256` write+read
  `.aid/{work}/IMPEDIMENT-task-NNN.md` (flat, hyphenated). `pipeline-contracts.md`
  (`### IMPEDIMENT-task-NNN.md Contract`) agrees with the producer, not with schemas.md §13.
- **Description:** A deterministic Blocked-state reader (FR16) that scans for IMPEDIMENT
  artifacts must know the single canonical path. Today the KB's own schema doc points at a
  per-task subdirectory that the pipeline never creates. The FR17 normalization should pick one
  canonical location and reconcile schemas.md §13 to match (behavior-preserving: the producer
  path is the de-facto truth, so the cheapest fix corrects the doc, not the code).
- **See also:** `.aid/knowledge/tech-debt.md` (not yet catalogued there); SPEC.md current-state
  inventory row "IMPEDIMENT".

## KI-003: reader's Blocked-state IMPEDIMENT scan hard-codes the flat path; must track KI-002 resolution

- **Status:** ✅ RESOLVED (delivery-001 / task-013 M6, commit 7761754) — KI-002 reconciled schemas.md §13 to the flat path the reader's `_find_impediment_file` already scans; the coupling is closed (reader scan path == canonical documented path).
- **Type:** Temporary coupling (consumer hard-codes a path the producer-side reconciles)
- **Severity:** Low
- **Affects:** feature-002-state-reader-foundation
- **Source:** feature-002 SPEC.md `### State Machines` SM-2 — the fallback Blocked derivation scans
  `.aid/{work}/IMPEDIMENT-task-NNN.md` (the producer's de-facto flat path,
  `canonical/skills/aid-execute/references/state-execute.md:322`), deliberately NOT the
  `task-NNN/IMPEDIMENT.md` subdir that `.aid/knowledge/schemas.md:504` wrongly documents.
- **Description:** The reader follows the de-facto producer path (correct today), but this is the
  same path-duplication KI-002 tracks on the producer side. When feature-001 M0 reconciles
  `schemas.md §13` to one canonical IMPEDIMENT location, this reader's hard-coded scan path must be
  updated in lockstep. It is a temporary coupling, not a bug: today's behavior is correct.
- **See also:** KI-002 (feature-001); feature-002 SPEC.md SM-2 IMPEDIMENT note.

## KI-005: a `tailscale serve` mapping survives an AID server-process crash (residual exposure until next lifecycle command)

- **Type:** Operational caveat (out-of-process state outlives the AID process)
- **Severity:** Low
- **Affects:** feature-005-secure-remote-exposure
- **Source:** feature-005 SPEC.md `### Security Specs` SEC-4 + Feature Flow. `tailscale serve --bg`
  installs the proxy mapping in the `tailscaled` daemon, not in the AID launcher process. Feature-004
  persists the teardown handle in `.aid/.temp/dashboard.pid` and tears down before killing the server,
  but if the AID server process crashes (or the machine reboots) between `expose` and a clean `stop`,
  the serve mapping remains up.
- **Description:** The residual mapping is **still tailnet-only + ACL-grant-scoped — never public**, so
  this is **not** a C1 breach. The next `aid dashboard stop`/`start` for that port reclaims the stale
  PID record (feature-004 DM-3) and reverts the mapping (`teardown` is callable on the recorded handle;
  `expose` is idempotent). Bounded, self-correcting at the next lifecycle command. No fix required now;
  if a stronger guarantee is wanted later, a `serve`-mapping sweep on `start` could be added.
- **See also:** feature-005 SPEC.md SEC-4; feature-004 SPEC.md DM-3 (stale-record reclaim).

## KI-006: the host/user ACL grant is an operator-installed tailnet policy fact AID cannot author or verify from the node

- **Type:** External dependency / verification gap (admin-plane policy outside AID's reach)
- **Severity:** Low
- **Affects:** feature-005-secure-remote-exposure
- **Source:** feature-005 SPEC.md `### Security Specs` SEC-2 + RM-4. The C3 host/user narrowing is
  enforced by a deny-by-default Tailscale **grant** (`src` = authorized identity/group, `dst` = this
  host:port) that lives in the tailnet **policy file** — an admin-plane artifact. The AID node cannot
  author it (would violate NFR7's spirit + read-only posture) and cannot authoritatively read it back to
  prove scoping.
- **Description:** AID detects Tailscale, brings up `serve` (tailnet-only — **C1 holds unconditionally,
  never public**), and prints a reminder of the grant requirement (ask-user-over-auto-proof: annotate the
  thing it cannot verify, do not fabricate a guarantee). The C3 **narrowing** therefore depends on the
  operator installing the grant once (RM-4): **without** it the channel is tailnet-wide (the plain-`serve`
  gap) but still never public; **with** it, it is host/user-scoped per C3. Documented dependency, not a
  code defect. The selected-mechanism AC of feature-005 is satisfied (Tailscale Serve + ACL grant chosen
  and justified, RM-3); this KI records the operator-side prerequisite.
- **See also:** feature-005 SPEC.md SEC-2 (literal grant), RM-3/RM-4 (decision + setup); REQUIREMENTS.md
  §7 C3.

## KI-007: KB-dashboard INDEX freshness is a reader-cheap proxy, not a per-poll `build-kb-index.sh` run

- **Type:** Advisory-signal fidelity (cheap proxy approximates the authoritative CI gate)
- **Severity:** Low
- **Affects:** feature-007-kb-dashboard (consumes feature-002 reader)
- **Source:** feature-007 SPEC.md `### Data Model` DM-1 `KbIndexFreshness` + DD-3. The authoritative
  "INDEX up-to-date" definition is the kb-hygiene CI job (`.github/workflows/test.yml` `kb-hygiene`,
  step "INDEX.md is fresh" — regenerate via `canonical/scripts/kb/build-kb-index.sh` and diff with
  timestamp lines filtered). The reader is polled every ~5s (feature-003 FR5) and must stay low-overhead
  (NFR4) and inside feature-002's no-subprocess, no-LLM read path (LC-R), so it does NOT shell out to
  `build-kb-index.sh` per poll.
- **Description:** The reader computes a deterministic proxy instead: compare the set of `### [name]`
  entries in `INDEX.md` against the non-dot `*.md` files under `.aid/knowledge/` (the CI script's own
  doc-selection rule, `build-kb-index.sh` `find -maxdepth 1 -type f -name '*.md' ! -name '.*'`), plus
  per-doc `intent:` lines when cheaply available; mismatch → `stale`, exact → `fresh`, skipped-frontmatter
  hot poll → `unknown`. It surfaces *likely* staleness so the operator runs the regen (FR18 remediation,
  feature-007 UI-4). The dashboard signal is advisory; the authoritative gate remains CI. No behavior
  change required now; revisit if a cheaper exact comparison becomes available.
- **See also:** feature-007 SPEC.md DM-1/DD-3/UI-4; `.github/workflows/test.yml` `kb-hygiene`;
  `canonical/scripts/kb/build-kb-index.sh`.

## KI-008: AID captures no per-task / per-agent execution log (FR13 "logs" is the persistent STATE.md forensics + an honest "none" + FR18 guidance)

- **Type:** Capability gap (a requirement-listed source does not exist on disk today)
- **Severity:** Low
- **Affects:** feature-008-skill-task-drilldown (consumes feature-002 reader; would need feature-001
  producer-side work for a real per-task log)
- **Source:** feature-008 SPEC.md `### Data Model` DM-5 + DD-4. FR13 lists "logs" among the full
  drill-down detail, but a disk audit (2026-06-10) confirms there is **no `*.log` anywhere under
  `.aid/`** for pipeline/task execution: a work folder holds only `STATE.md`, `REQUIREMENTS.md`,
  `known-issues.md`. The only log on disk is the dashboard **server's own** stdout/stderr at
  `.aid/.temp/dashboard.log` (feature-004 SPEC DM-1 `logfile`, created by `aid dashboard start`,
  removed by `stop`) — a tool-operational log, **not** a task log. The reviewer ledger
  (`.aid/.temp/review-pending/<scope>.md`, `.claude/templates/reviewer-ledger-schema.md`) is
  **transient — deleted at skill DONE**, so it is not a forensic source for a completed task.
- **Description:** The persistent per-task forensics AID actually keeps are the work `STATE.md`
  `## Quick Check Findings ### task-NNN` block (findings, no grade), the `## Delivery Gates
  ### delivery-NNN` block (the per-delivery grade), and `.aid/{work}/delivery-NNN-issues.md`
  (deferred-`[HIGH]` rows, `schemas.md §12`). The drill-down surfaces those (DM-1) and, for "logs",
  shows an honest "no per-task logs are captured" state + FR18 step-by-step guidance (UI-4), labeling
  the server log as a tool diagnostic — never fabricating a task-log viewer over files that do not
  exist (ask-user-over-auto-proof: annotate what we cannot prove). True per-task execution logging is a
  **producer-side** capability (feature-001 territory), out of scope for this read-only view. No
  behavior change required now; revisit if per-task log capture is added to the pipeline.
- **See also:** feature-008 SPEC.md DM-1/DM-5/DD-4/UI-4; feature-004 SPEC.md DM-1 (`dashboard.log`);
  `.claude/templates/reviewer-ledger-schema.md` (transient ledger); `.aid/knowledge/schemas.md §12`.

## KI-004: heartbeat files are not work-scoped — reader treats liveness as a repo-level hint only

- **Type:** Signal-granularity limitation (consumed contract lacks the key the consumer would want)
- **Severity:** Low
- **Affects:** feature-002-state-reader-foundation
- **Source:** `.aid/knowledge/pipeline-contracts.md ## Heartbeat File` — the filename schema is
  `.aid/.heartbeat/<agent>-<unix-ts>.txt`; it keys on agent + unix-ts, **not** on `work_id`. With
  multiple works running concurrently a heartbeat cannot be attributed to a specific work.
- **Description:** The reader therefore consumes heartbeat as a **repo-level corroborating liveness
  hint** (Telemetry section) and **never** lets it influence a work's FR16 lifecycle (which stays
  derived from STATE.md primitives + feature-001's typed block). This is correct-by-design for
  read-only freshness badges (feature-003), but if a future feature-001 increment adds a work-scoped
  liveness signal, the reader can tighten attribution. No behavior change required now.
- **See also:** feature-002 SPEC.md `### Telemetry & Tracking`; feature-001 SPEC.md §2.4 (heartbeat
  is transient liveness, does not travel on handoff).

## KI-009: the dashboard server log (`.aid/.temp/dashboard.log`) is NOT captured on Windows

- **Status:** ⚠️ OPEN (by-design platform limitation; documented). Introduced by the Windows PS detach fix (feature-004 / bin/aid.ps1 Step 7).
- **Type:** Cross-platform behavior divergence (diagnostics)
- **Severity:** Low
- **Affects:** feature-004-cli-dashboard-control (producer), feature-008-skill-task-drilldown (consumer — `server_log_present` / "dashboard server log" panel)
- **Detail:** The Bash launcher spawns the dashboard server with `setsid "$interp" ... >"$log_file" 2>&1` (fully detached **and** stdout/stderr merged into `dashboard.log`). The PowerShell launcher cannot do both: `Start-Process` **with** `-RedirectStandardOutput/-RedirectStandardError` uses full handle inheritance, so the long-lived server inherits and holds the caller's stdout/stderr pipe open — a caller that captures `aid dashboard start` output (e.g. the CI dashboard smoke, or any `$x = aid dashboard start 2>&1`) then **hangs forever** waiting for EOF. The fix omits redirection so `Start-Process` uses **ShellExecute** (no caller-handle inheritance → true detach, the Windows analog of `setsid`). Consequence: on Windows the server's own stdout/stderr are **not** written to `dashboard.log`.
- **Impact:** start/stop/status are **behaviour-identical** across platforms (readiness is verified by TCP poll, not the log; PID liveness via `Get-Process`; the pid record still carries the `logfile` field for schema parity). The only loss is server-boot/error diagnostics on Windows.
- **Consumer guidance:** feature-008's "dashboard server log" panel must treat `server_log_present=false` as the **expected** Windows state and show a "log not captured on this platform" message — never a fake-empty viewer. (feature-008 SPEC.md `### Log availability` row updated to qualify this per-platform.)
- **Possible future remedy:** capture the Windows log via a shell wrapper (`Start-Process cmd /c "... > log 2>&1"`, ShellExecute — needs process-tree kill on stop) or a server-side `--logfile` option (both runtimes). Deferred — not worth the added stop-path complexity for boot diagnostics.
- **See also:** `bin/aid.ps1` Step 7 spawn comment; task-022.md Scope (Windows spawn deviation); feature-008 SPEC.md `### Log availability`.

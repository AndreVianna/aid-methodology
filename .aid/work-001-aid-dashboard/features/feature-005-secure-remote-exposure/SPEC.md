# Secure Remote Exposure (Authorized-Only, Never Public)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-10 | Feature identified from REQUIREMENTS.md §6 NFR1; §7 C1, C3 | /aid-interview |

## Source

- REQUIREMENTS.md §6 NFR1 (local-only / never public)
- REQUIREMENTS.md §7 C1 (never public — hard), C3 (remote/VM exposure access-restricted to
  authorized users)
- REQUIREMENTS.md §5 FR18 (step-by-step guidance for the operator-installed ACL grant + any
  Tailscale-install user-intervention)

## Description

When a repo (and its dashboard) runs on a **VM or remote machine**, the operator must be able to
**reach it from their own laptop** for testing — over a **private, access-restricted** channel that
is **never public**. This feature provides that reachability (e.g. via Tailscale or a similar
private-network mechanism), restricting access to **only the people authorized on that VM/host**,
not "anyone on the tunnel." It sits atop the local serve layer (feature-003) and does not change the
reader or the views.

Carries **C3 research**: the exact authorized-user-restriction mechanism is an open item (the house
Tailscale mechanism — `tailscale serve` over the tailnet — is the leading candidate).

## User Stories

- As an **operator running AID on a VM/remote**, I want to view that repo's dashboard from my
  laptop, so I can test and monitor it without sitting on the remote machine.
- As a **security-conscious operator**, I want remote access limited to authorized users and never
  exposed publicly, so pipeline state isn't leaked.

## Priority

Must (MVP — per user instruction: laptop remote-testing is part of the first deliverable).

## Acceptance Criteria

- [ ] Given a dashboard served on a VM/remote, when exposed for remote access, then it is reachable
      from the operator's laptop over a private channel and **never** on the public internet (C1).
- [ ] Given remote exposure is active, then access is **restricted to authorized users** of that
      VM/host, not anyone who can reach the tunnel (C3).
- [ ] Given C3, when the SPEC is written, then the specific authorized-user-restriction mechanism is
      selected and justified.

---

## Technical Specification

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Research / Mechanism
> Evaluation** (C3 mandates this — the alternatives table + the chosen mechanism, justified against
> host/user-scoping; this is the feature's central open item), **Feature Flow** (`expose` /
> `teardown` algorithms: bring up the ACL-scoped private channel over the bound `127.0.0.1:<port>`,
> return a teardown handle + the reachable private URL; revert; idempotency; failure-closed never-public
> behavior), **Layers & Components** (the **LC-2 contract** feature-004 consumes — `expose`/`teardown`
> signatures, the opaque handle shape, exit/return semantics; where the launcher/helper code lives;
> cross-platform; ASCII-only), **Security Specs** (REQUIRED — the C1 never-public invariant enforced
> *structurally*; the host/user-scoped ACL model; what "authorized user of that VM/host" means in the
> chosen mechanism; failure-closed; no inbound public ports), **External Integrations** (the chosen
> overlay tool as an external dependency — version, availability detection, graceful absence → exit 10).
> **Skipped:** UI Specs (no rendered surface — this layers under feature-003's page), Data Model / DB
> & Migration (AID ships no DB — `schemas.md`; the only state is the opaque handle, persisted by
> feature-004's `dashboard.pid`, defined under LC-2), Telemetry (none generated; NFR7),
> State Machines (the expose/teardown transitions are trivial enough to live in Feature Flow), CLI
> spec (the command surface is feature-004's; this feature is invoked *by* it, not a command itself).

C3 is **RESOLVED in direction** (REQUIREMENTS §7 C3; STATE.md Q3; user 2026-06-10) and the **specific
mechanism is selected here** (the third AC of this feature): **Tailscale Serve, locked to host/user
ACL grants** — *not* plain `tailscale serve` (which is tailnet-wide), *not* `tailscale funnel` (which is
public and would violate C1). The selection is justified against evaluated alternatives in the Research
section below. The exposure is **deterministic shell + a declarative ACL fact** — no agent/LLM anywhere
in the path (NFR7), implemented as a helper invoked by feature-004's existing Bash/PowerShell launcher
twin (NFR5). This feature **ratifies the LC-2 contract** that feature-004 proposed (and consumes) so the
two features agree on `expose(port) -> handle` / `teardown(handle)`, exit codes, and the opaque handle
shape.

---

### Research / Mechanism Evaluation

#### RM-1. The C3 problem, stated precisely

C3 requires the remote channel be reachable by **only the people authorized on that specific VM/host**,
**never** "anyone on the tunnel/tailnet," and **never** public (C1, hard). The evaluation axes:

1. **Host/user-scoped authorization** — access decided by *which authenticated identity / which device*,
   scoped to this one host's dashboard port, not network-wide. (The discriminating axis — most tunnels
   fail here.)
2. **Never-public (C1, hard)** — no path that places the dashboard on the public internet.
3. **Works from a VM behind NAT/firewall with no inbound public port** — egress-only, the VM dials out;
   no port-forward, no public listener.
4. **Cross-platform (NFR5)** — Windows + macOS + Linux client and host.
5. **Low setup friction / no third-party-runtime-dep creep** — fits AID's zero-third-party-dep posture
   (`technology-stack.md`); ideally a tool already present, no daemon AID must ship.
6. **No agent/LLM at runtime (NFR7)** — deterministic shell/config.

#### RM-2. Alternatives compared (2026)

| Mechanism | (1) Host/user-scoped? | (2) Never-public? | (3) NAT-egress only? | (4) X-platform? | (5) Friction / dep creep | (6) Deterministic? | Verdict |
|-----------|----------------------|-------------------|----------------------|-----------------|--------------------------|--------------------|---------|
| **Tailscale Serve + ACL grants** | **Yes** — grants are deny-by-default; `src` selects specific users (`name@example.com`), groups, or devices (tags), `dst` is *this host:port* [S1][S2] | **Yes** — `serve` is tailnet-only; only `funnel` is public and we never invoke it [S3][S5] | **Yes** — WireGuard, both ends dial the coordination/DERP plane; no inbound public port [S3] | **Yes** — Win/macOS/Linux clients (live host probe [S4]; Tailscale ships clients for all three) | **Low** — already installed on the target host (`tailscale 1.98.4` on `srvrivind01`, tailnet `tail74e815.ts.net`, confirmed live); AID ships nothing | **Yes** — `tailscale serve` + a static policy fact | **CHOSEN** |
| Plain `tailscale serve` (no ACL) | **No** — reachable by *any* tailnet node ("anyone on the tunnel") | Yes (tailnet-only) | Yes | Yes | Lowest | Yes | **Rejected** — fails axis 1; this is exactly the C3 gap |
| `tailscale funnel` | n/a | **NO** — funnel is *public internet* by design [S3][S5] | Yes | Yes | Low | Yes | **Rejected (hard)** — violates C1 |
| Cloudflare Tunnel + Access | Yes — Access enforces per-app identity policy (email/SSO) | Yes — Access in front; tunnel egress-only | Yes — `cloudflared` dials out | Yes | **Higher** — requires a Cloudflare account, a named tunnel, an Access app + IdP config; introduces `cloudflared` as a runtime dep AID would have to detect/ship [S6] | Yes (after setup) | **Runner-up** — strongest non-incumbent; rejected on dep-creep (axis 5) + not already present |
| WireGuard + host firewall (allowlist peers) | Partial — scoping is by *peer public key + firewall rule*, i.e. device-scoped, not user-identity-scoped; no built-in IdP | Yes | Yes (with a reachable endpoint or a relay) | Yes (clients) but manual config | **High** — hand-managed keys, endpoints, firewall rules per peer; brittle on changing NAT | Yes | Rejected — high friction, device-not-user scoping, manual relay for double-NAT |
| Headscale (self-hosted control plane) | Yes (ACL policy like Tailscale) | Yes | Yes | Yes | **Highest** — operator must run+maintain a coordination server; net-new infra AID does not have (`infrastructure.md`: "no server, no daemon, no cloud") | Yes | Rejected — infra burden; only relevant if avoiding the Tailscale SaaS control plane is a hard requirement (it is not) |
| Nebula (Slack overlay) | Partial — cert-based host/group scoping (CA-signed certs), not user-IdP; needs lighthouse host | Yes | Yes | Yes | High — run a lighthouse, manage a CA + per-host certs | Yes | Rejected — CA/lighthouse operational burden; device/group not user scoping |
| ngrok (with auth) | Partial — paid tiers add OAuth/IP/basic-auth in front of a **public** edge URL | **NO by default** — ngrok edges are public hostnames; "private" requires the paid agent-ingress/IP-restriction tier and *still* fronts a public endpoint | Yes | Yes | Med — third-party SaaS, account, runtime dep | Yes | Rejected — public-edge model is at odds with C1; auth bolts onto a public surface |
| SSH reverse tunnel (`ssh -R`) | Yes — gated by SSH host auth (authorized_keys = users authorized on the host) | Yes (bind the forward to loopback on the jump host) | Needs a reachable SSH relay/jump host | Yes | Med — needs a relay host; **and `ssh -R` is KILLED in the AID Bash sandbox** (user memory / env: exit 144) so it cannot be driven by an AID-spawned process | Yes | Rejected — relay requirement + the sandbox kills `ssh`, so AID cannot establish it programmatically |

Sources:
- [S1] Tailscale — *Manage grants* / ACL grants reference (`https://tailscale.com/kb/1324/acl-grants`):
  "Grants are Tailscale's enhanced access control system... follow Tailscale's **deny-by-default**
  approach... Each grant consists of `src`, `dst`, and at least one type of permissions"; `src`/`dst`
  selectors include "Specific email addresses (`name@example.com`) for individual users... Groups...
  Tags..." (fetched 2026-06-10).
- [S2] Tailscale — *Manage ACLs* (`https://tailscale.com/kb/1018/acls`) — the tailnet policy file is the
  single source of access truth; grants migrate from/extend classic ACLs (fetched 2026-06-10).
- [S3] Tailscale — *Tailscale Serve* (`https://tailscale.com/kb/1242/tailscale-serve`) — "share a local
  server **securely within your tailnet**"; the serve target proxies `127.0.0.1:<port>` to a
  tailnet-only HTTPS endpoint (fetched 2026-06-10).
- [S5] Tailscale — *Tailscale Funnel* (`https://tailscale.com/kb/1223/funnel`) — "route traffic from the
  **broader internet**... for **anyone to access — even if they don't use Tailscale**" — i.e. funnel is
  public; the explicit "share only within your tailnet" alternative is `serve` (fetched 2026-06-10).
- [S4] Live host probe (this machine, 2026-06-10): `tailscale version` -> `1.98.4`; `tailscale status`
  shows node `srvrivind01` on tailnet `tail74e815.ts.net`, user `AndreVianna@github`; `tailscale serve
  --help` documents `--bg <port>` for a `127.0.0.1:<port>` backend; `tailscale funnel --help` confirms
  funnel = "on the internet." (Grounds availability-detection + the chosen verbs.)
- [S6] Cloudflare — *Cloudflare Tunnel* + *Access* (the runner-up): an Access application enforces
  identity (SSO/email) in front of a `cloudflared` egress tunnel — host/user-scoped and never-public,
  but adds a Cloudflare account + named tunnel + Access app + the `cloudflared` runtime dependency
  (`https://developers.cloudflare.com/cloudflare-one/`). Cited as the strongest non-incumbent.

#### RM-3. Decision — Tailscale Serve + ACL grants

**Chosen: Tailscale Serve fronting the loopback port, with a deny-by-default ACL grant that scopes the
host's dashboard to specific authorized identities.** Rationale against the alternatives:

- It is the **only** option that satisfies **all six** axes *and* is **already installed on the
  deployment host** (axis 5 — `infrastructure.md` says AID owns no server/daemon/cloud; Tailscale is
  pre-existing operator infrastructure, not something AID ships → zero dep-creep, honoring the
  zero-third-party-dep posture of `technology-stack.md`).
- It closes the C3 gap **structurally**: plain `serve` is tailnet-wide (rejected); the fix is the ACL
  grant — `src` = the operator's specific identity/group, `dst` = *this host*'s dashboard service — so
  only authorized users, not "anyone on the tunnel," can reach it (RM-2 row 1 vs row 2).
- It never goes public: we invoke **`tailscale serve`** (tailnet-only [S3]) and **never `tailscale
  funnel`** (public [S5]). The absence of any funnel call is a structural C1 guarantee (SEC-1).
- Cloudflare Tunnel + Access is the credible runner-up and the right fallback *if* the user ever wants
  exposure decoupled from Tailscale; it loses here purely on dep-creep + not-already-present. It is
  recorded so the LC-2 contract below is **mechanism-agnostic** — if the user switches, only the helper
  body changes, not the contract feature-004 consumes.

**Operator setup this requires (genuine, flag to user — RM-4).** The host-scoping is enforced by a
tailnet **policy fact** the operator (tailnet admin) must put in place once — it is *not* something AID
can write at runtime (the policy file is an admin-plane artifact, and writing it from an LLM-driven
pipeline would violate NFR7's spirit and the read-only posture). See SEC-2 for the exact grant shape and
RM-4 for the one-time setup.

#### RM-4. One-time operator setup (documented, not automated)

For `--remote` to be both *functional* and *correctly host/user-scoped*, the tailnet admin must, once:

1. Have Tailscale installed and logged in on the VM/host (already true on `srvrivind01`).
2. Add a **deny-by-default** grant to the tailnet policy file scoping this host's served port to the
   authorized identity/group (SEC-2 gives the literal JSON). Tailscale is deny-by-default once any
   restricting grant exists, so the absence of a permissive wildcard is what makes it user-scoped.

AID **detects** whether Tailscale is present and logged in (External Integrations) and **documents** the
grant requirement (the helper prints a pointer on first `--remote` use), but does **not** edit the policy
file — that is the operator's deliberate, audited action. This is the "setup the user must do" called out
for user attention.

---

### Feature Flow

Two deterministic shell flows, invoked **by feature-004** (never directly by a user). No agent/LLM
anywhere (NFR7); every step is plain Bash/PowerShell + `tailscale` CLI calls. Feature-004's `start`
step 10 calls `expose`; its `stop` step 4 calls `teardown`.

#### `expose(port)` — bring up the host/user-scoped private channel

Input: the loopback port feature-003's server already bound (`127.0.0.1:<port>`, guaranteed by
feature-003 LC-S + feature-004 SEC-1 *before* this is called). Output on success: an opaque
**teardown handle** (LC-2) printed to stdout and the **reachable private URL** printed to stdout;
exit 0. On any failure: a clear error to stderr, **no public bind ever**, exit per the table.

```
1.  Pre-bind invariant (caller-guaranteed, re-asserted): the target is exactly 127.0.0.1:<port>.
      If the caller passed any non-loopback host token -> ERROR "expose target must be 127.0.0.1",
      exit 11 (internal-contract violation). This is belt-and-suspenders for SEC-1; expose NEVER
      itself binds a socket and NEVER widens a bind.
2.  Availability detection (External Integrations EI-1):
      a. `tailscale` on PATH?            no  -> exit 10 (mechanism absent).
      b. `tailscale status` reports the node is logged in / Running?
                                         no  -> exit 10 (present but not usable; message names the cause).
      (Both checks are read-only `tailscale` queries; no state change yet.)
3.  Bring up Serve (tailnet-only, NEVER funnel):
      run, idempotently:  tailscale serve --bg <port>
      This proxies the tailnet HTTPS endpoint -> http://127.0.0.1:<port> [S3][S4]. We invoke the
      `serve` verb ONLY. There is NO code path that invokes `tailscale funnel` (SEC-1, grep-asserted).
      serve failure (nonzero exit) -> capture stderr, do NOT leave a half-up serve (run
        `tailscale serve --https=443 off` / `tailscale serve reset` to revert this port), exit 12.
4.  Resolve the private URL: from `tailscale serve status --json` (or `tailscale status --json`
      Self.DNSName), compose https://<this-node-fqdn>/  (e.g. https://srvrivind01.tail74e815.ts.net/).
      This URL is reachable ONLY by tailnet peers AND only those the ACL grant permits (SEC-2).
5.  Host/user-scope guidance (SEC-2; **step-by-step per FR18**):
      Because the node cannot authoritatively read the tailnet policy (`tailscale serve status` shows
      only the served target, not the admin-plane grant), expose CANNOT prove the grant is in place.
      Instead of a terse one-liner, it prints **step-by-step instructions** the operator can follow to
      make access host/user-scoped (FR18). The printed block (stdout, ASCII-only):

        Remote exposure is UP (tailnet-private). To restrict it to ONLY you (C3), add a
        deny-by-default tailnet ACL grant — without it, any tailnet device can reach this host.
        Step 1. Open the tailnet policy file:
                  https://login.tailscale.com/admin/acls/file
        Step 2. Add this grant (replace the identity with yours or a group):
                  {"grants":[{"src":["<you@example.com>"],"dst":["<this-host>"],"ip":["tcp:443"]}]}
                  (src = your identity/group; dst = THIS host only, never "*"; ip = the serve port.)
        Step 3. Save. Tailscale is deny-by-default once any grant exists, so every other device is
                now denied.
        Step 4. Verify from your laptop: open <private-URL> — it should load for you, and a
                non-authorized device should get connection-refused/forbidden.
        (AID cannot edit your tailnet policy for you — it is admin-plane, and the dashboard never
        runs an agent/LLM at runtime. See `aid dashboard` docs / feature-005 SEC-2.)

      `<you@example.com>`, `<this-host>`, and `<private-URL>` are substituted with the detected node
      identity/FQDN where available. This is informational output, not a gate — `serve` is already
      tailnet-only (never public), so C1 holds regardless; the guidance concerns the C3 narrowing.
      (Ask-user-over-auto-proof: annotate the requirement we cannot verify + tell the user exactly how
      to satisfy it; never fabricate a guarantee.)
6.  Emit the handle (LC-2) on stdout and exit 0:
      a single line:  tailscale-serve:<port>
      followed by the URL line:  https://<node-fqdn>/
      (Caller feature-004 captures the handle into dashboard.pid.remote_handle and prints the URL.)
```

#### `teardown(handle)` — revert the exposure

```
1.  Parse the handle (LC-2): must match "tailscale-serve:<port>".
      malformed/empty -> treat as nothing-to-tear-down, exit 0 (idempotent; mirrors feature-004 stop).
2.  Availability: if `tailscale` is gone now (uninstalled mid-run) -> WARN to stderr, exit 0
      (we cannot revert what is no longer there; the caller already logs a partial).
3.  Revert the serve mapping this feature created (the HTTPS:443 -> localhost:<port> proxy):
      tailscale serve --bg --https=443 off
      (`--https=443 off` targets the FRONTEND mapping `expose` created with `serve --bg <port>`;
      `<port>` is the loopback BACKEND, not a valid `off` target, so the `serve <port> off` form is
      NOT used.) A full `tailscale serve reset` is the fallback ONLY if the `--https=443 off` form is
      unavailable AND `serve status` shows no other mappings. Never funnel reset (we never set it).
      revert failure -> WARN to stderr, exit 13 (caller treats as a partial: server still gets killed).
4.  exit 0 on clean revert.
```

- **Scope: one exposure per host (MVP).** Consistent with feature-003/004's "one dashboard per repo"
  + fixed default port (8787), the MVP exposes **one** dashboard per host via the single HTTPS:443
  serve frontend. So `teardown`'s `--https=443 off` reverts exactly the mapping `expose` created — the
  earlier "ONLY this port's mapping" framing (which implied port-keyed multi-mapping) is replaced by
  this single-frontend model. **Concurrent remote exposure of multiple repos on one host is OUT of MVP
  scope** (it would need distinct frontends per repo — a post-MVP enhancement); attempting a second
  `expose` while a 443 mapping exists reuses/over-writes it rather than multiplexing.
- **OQ5 cross-reference — what `--remote` exposes (RESOLVED 2026-06-12, owned by feature-010).** With
  the two-level re-architecture (feature-010), `aid dashboard --remote` exposes the **machine-level CLI
  home — all registered repos**: a grantee sees the full registered-repo list and can open **any**
  registered repo's dashboard through feature-010's multi-repo server. This does **not** change anything
  on feature-005's side — exposure stays a **single HTTPS:443 frontend** over the one localhost port the
  multi-repo server binds; the difference is only *what that one server serves* (the CLI home, not a
  single repo). The C3 host/user-ACL scoping and C1 never-public guarantees are **unchanged** — only the
  *granted* tailnet identities reach it; exposing the repo list (paths/names) to those granted identities
  is the **accepted trade-off** of OQ5. (Concurrent exposure of *multiple frontends* remains out of MVP,
  per the bullet above; one frontend now fronts the whole CLI home.)
- **Idempotency (mirrors feature-004's idempotent `stop`).** A second `teardown` with the same handle,
  or after the serve mapping is already gone, is a clean no-op exit 0 — never an error. `expose` run
  twice for the same port is also safe (`tailscale serve --bg` is declarative/idempotent).
- **Failure → never public, server stays local.** Every `expose` failure path exits nonzero **without
  having placed anything on the public internet** (we only ever call `serve`, never `funnel`) and
  **without touching the loopback server** (which feature-004 bound before calling us and keeps running
  local-only). The worst case is "no remote, clear error, dashboard still at `http://127.0.0.1:<port>`"
  — exactly feature-004's SEC-2 contract.
- **No agent/LLM (NFR7).** Every step is a `tailscale` subprocess call + string handling. No model call,
  no network egress beyond what the `tailscale` daemon already does for the operator.

---

### Layers & Components

Per `coding-standards.md` (small, single-purpose, deterministic, documented exit codes, **ASCII-only
shipped scripts**) and `architecture.md` (the `aid` CLI dispatch pattern). This feature adds **one helper
implemented twice** — a Bash function in `bin/aid` and its PowerShell twin in `bin/aid.ps1` — invoked by
feature-004's `_cmd_dashboard_ctl` / `Invoke-AidDashboardCtl`. It ships **no new top-level command**
(feature-004 owns the command surface).

| Component | Side | Responsibility | MUST NOT |
|-----------|------|----------------|----------|
| **LC-EXP-B `_aid_remote_expose` / `_aid_remote_teardown` (Bash)** | `bin/aid` | run the `expose`/`teardown` flows above via the `tailscale` CLI; return the opaque handle + URL; revert cleanly | invoke `tailscale funnel`; bind any socket; widen a bind; edit the tailnet policy file; call any agent/LLM; emit non-ASCII bytes |
| **LC-EXP-P `Invoke-AidRemoteExpose` / `Invoke-AidRemoteTeardown` (PowerShell)** | `bin/aid.ps1` | byte-behavior twin of LC-EXP-B (same handle shape, exit codes, messages) | diverge from the Bash side (parity gate); any of the above |
| **LC-2 the exposure contract** | seam to feature-004 | the `expose`/`teardown` interface feature-004 calls and persists | (defined below — this is the ratification) |

#### LC-2. The exposure contract (RATIFIED — this is the agreement feature-004 records)

Feature-004 proposed LC-2 as `expose(port@127.0.0.1) -> handle` / `teardown(handle)`, persisting an
opaque `remote_handle` in `.aid/.temp/dashboard.pid` and consuming exit code **10** for "mechanism
absent." This feature **ratifies and concretizes** it. The contract is a **subprocess/return-value
contract** (not an in-language function call) because the two features are the same Bash/PowerShell
launcher — `expose` is a shell function feature-004 calls and whose stdout + exit code it consumes.

**Signatures (shell-function form, in `bin/aid` / `bin/aid.ps1`):**

```
expose:    _aid_remote_expose <port>
             # precondition: the server is already listening on 127.0.0.1:<port>
             # stdout (on exit 0), exactly two lines:
             #   tailscale-serve:<port>          <- the opaque HANDLE (line 1)
             #   https://<node-fqdn>/            <- the reachable private URL (line 2)
             # stderr: human messages (reminders, errors)
             # exit:   0 ok | 10 mechanism absent | 11 bad target | 12 serve-up failed | (caller maps)

teardown:  _aid_remote_teardown <handle>
             # input: the line-1 handle string captured from a prior expose
             # exit:  0 ok/idempotent | 13 revert warned (caller treats as partial, still kills server)
```

**The opaque handle shape.** `tailscale-serve:<port>` — a single ASCII line. It is **opaque to
feature-004**: feature-004 stores it verbatim in `dashboard.pid.remote_handle` and passes it back to
`teardown` without parsing. The `mechanism:<arg>` scheme is forward-compatible — if the mechanism ever
becomes Cloudflare (RM-2 runner-up), the handle becomes e.g. `cloudflare-tunnel:<tunnel-id>` and **only
the helper body changes**; feature-004's persist/replay logic is unchanged because it treats the handle
as an opaque token. This is precisely why feature-004 typed `remote_handle` as `string|null`.

**Exit-code reconciliation with feature-004 (CLI-2 table).** Feature-004 surfaces exactly **exit 10** to
the user for "`--remote` requested but the secure exposure mechanism is unavailable; local server still
runs." This feature's `expose` returns a *finer* set internally (10/11/12), which feature-004 **collapses
to its user-facing 10** (all three mean "remote did not come up; stay local, never public"):

| `expose` internal exit | Meaning | feature-004 user-facing mapping |
|------------------------|---------|---------------------------------|
| `0` | exposed; handle + URL on stdout | record `remote=true`, `remote_handle=<handle>`, print URL, exit 0 |
| `10` | `tailscale` absent OR not logged in | exit **10** (feature-004 CLI-2) — "mechanism not available", server stays local |
| `11` | internal: non-loopback target passed | exit **10** to user; this is a contract bug, logged at `--verbose`; never public |
| `12` | `tailscale serve` invocation failed | exit **10** to user; serve reverted; message names the serve error |

`teardown` returns `0` (clean/idempotent) or `13` (revert warned); feature-004's `stop` step 4 maps `13`
to its "remote teardown reported a warning" partial and **still proceeds to kill the server** — matching
feature-004's stated "do not abort the process kill on a teardown hiccup." This reconciliation is the
ratification feature-004's SPEC flagged as "proposed here, not yet ratified" (its LC-2 row + Security
"Out of scope" note); **with this spec the seam is agreed.**

#### LC-3. Where the code lives + the CI gates (cross-platform mechanics)

- **`bin/aid` / `bin/aid.ps1` are hand-maintained canonical source, NOT `canonical/`→render artifacts.**
  Verified in feature-004 LC-4 (they are not in `canonical/EMISSION-MANIFEST.md`): the
  render-drift / `run_generator.py` pipeline does **not** touch them. The helper functions are added
  **directly** to root `bin/aid` and `bin/aid.ps1`; vendored copies (`packages/npm/bin/aid`,
  `packages/pypi/aid_installer/_vendor/bin/aid`) are regenerated by the `prepack`/build vendor step,
  **not** hand-edited (`infrastructure.md` Install Pipeline; feature-004 LC-4).
- **ASCII-only gate (hard, `coding-standards.md` + memory; CI `test-ascii-only.sh`).** `bin/aid`,
  `bin/aid.ps1` are in `SHIPPED_SCRIPTS`. The new helpers MUST be ASCII-only — plain `->`, `|`, ASCII
  punctuation in every reminder/error string. (The reminder text in `expose` step 5 is ASCII.)
- **Parity gate (hard; CI `test-aid-cli-parity.sh`).** Bash and PowerShell must produce identical exit
  codes + messages. The `expose`/`teardown` helpers are added to **both** dispatchers with identical
  handle shape, exit codes (LC-2 table), and user-visible strings; the parity suite is extended to cover
  the `--remote` clear-fail path (T-3 below) — `tailscale` is stubbed so the suite runs without a live
  tailnet.
- **NFR5 cross-platform.** `tailscale` is a single cross-platform CLI with the same verbs on Win/macOS/
  Linux (live host probe [S4]; the `tailscale` CLI is identical across platforms); both launcher twins
  shell out to it identically. No platform-specific exposure logic.

---

### Security Specs

This is the security-critical feature of the work. The invariants are enforced **structurally**, not by
convention, and verified by tests (below).

- **SEC-1. Never public (C1, hard — structural).** The only exposure verb this feature ever invokes is
  **`tailscale serve`**, which is **tailnet-only** [S3]. The public verb **`tailscale funnel`** is
  **never called from any code path** — a grep-level self-check test asserts the strings `funnel` and
  `--funnel` do **not** appear in the `bin/aid`/`bin/aid.ps1` exposure helpers (mirrors feature-003's
  "server source contains no `0.0.0.0`" and feature-002's "reader contains no write primitive"
  self-check family, `pipeline-contracts.md`). There is **no inbound public port**: WireGuard is
  egress/relay-based, so the VM opens no public listener (RM-2 axis 3). C1 cannot be violated by a config
  typo because there is no funnel/public token in the source to mistype.
- **SEC-2. Host/user-scoped authorization (C3 — the ACL grant).** "Authorized user of that VM/host"
  means, concretely: **a tailnet identity (or group) named in the `src` of a deny-by-default grant whose
  `dst` is this host's served dashboard.** Tailscale grants are deny-by-default [S1]; once a restricting
  grant exists, only the named identities reach the `dst`. The literal grant the operator installs once
  (RM-4) looks like (tailnet policy file, `tailscale.com/kb/1324`):

  ```jsonc
  // Tailscale tailnet policy file — admin installs once; AID does NOT write this.
  {
    "grants": [
      {
        "src": ["andre.vianna.rj@hotmail.com"],     // or a group: ["group:dashboard-admins"]
        "dst": ["srvrivind01"],                       // THIS host only (tag/host name), not "*"
        "ip":  ["tcp:443"]                             // the serve HTTPS port on this host
      }
    ]
  }
  ```

  - **Why this is host/user-scoped, not tailnet-wide:** `dst` is *this host* (not `*`), and `src` is a
    *specific identity/group* (not `autogroup:members`/`*`). Any other tailnet node — "anyone on the
    tunnel" — is denied by default. This is the exact C3 narrowing that plain `tailscale serve` (RM-2
    row 2) lacks.
  - **What AID does vs. what the operator does:** AID brings up `serve` and **detects** Tailscale; the
    **grant is an admin-plane policy fact the operator installs** (RM-4). AID cannot author it at runtime
    (the policy file is admin-scoped, and an LLM-driven pipeline writing tailnet ACLs would break NFR7's
    spirit + the read-only posture). `expose` step 5 **prints step-by-step instructions** for
    installing the grant (FR18 — exact URL, the literal grant to paste, and how to verify) rather than
    asserting a guarantee it cannot verify from the node (ask-user-over-auto-proof).
- **SEC-3. Failure-closed (C1 preserved on every error).** Every `expose` failure exits nonzero with the
  dashboard **still local-only** and **nothing public** (SEC-1). There is **no fallback** that widens the
  bind, opens a public port, or calls funnel. Feature-004 layered this: the server is bound `127.0.0.1`
  *before* `expose` is attempted, so a remote failure degrades to local-only, never to public.
- **SEC-4. Clean teardown (no lingering exposure).** `teardown` reverts **only this port's** serve
  mapping (not the operator's unrelated serve config) so no private tunnel is left listening after `stop`.
  Because feature-004 persists the handle in `dashboard.pid` and tears down *before* killing the server,
  a crash that leaves a stale record is reclaimed by the next `start`/`stop` (feature-004 DM-3) — but
  note the **residual-exposure caveat**: a `serve` mapping survives a server *process* crash (it lives in
  the `tailscaled` daemon, not the AID process). The next `aid dashboard stop`/`start` for that port
  reverts it (feature-004 reclaims the stale record and this feature's `expose` is idempotent / `teardown`
  is callable on the recorded handle). Registered as KI-005 (a bounded operational caveat, not a C1
  breach — a surviving `serve` mapping is still tailnet-only + grant-scoped, never public).
- **SEC-5. No new secrets, no credentials handled.** AID stores no Tailscale auth token; authentication
  is the operator's existing `tailscaled` login (`tailscale status` shows it). The handle
  (`tailscale-serve:<port>`) is **not** a secret — it is a port reference; persisting it in
  `dashboard.pid` (gitignored `.aid/.temp/`) leaks nothing.

---

### External Integrations

- **EI-1. Tailscale CLI (`tailscale`) — the chosen mechanism's external dependency.**
  - **Version / availability:** any modern `tailscale` (confirmed `1.98.4` on the deployment host
    `srvrivind01` [S4]); the verbs used (`serve --bg <port>`, `serve status --json`, `serve … off` /
    `serve reset`, `status --json`) were verified present/working on the live `1.98.4` host probe [S4]
    (and are long-standing `serve` verbs per [S3]).
  - **Detection (graceful absence → feature-004 exit 10):** `expose` step 2 checks (a) `tailscale` on
    PATH and (b) `tailscale status` reports a logged-in/Running node. Either failing → internal exit 10,
    which feature-004 surfaces as its user-facing exit 10 ("mechanism not available; local server still
    running"). This is the **only** dependency, and its absence is handled, not crashed — honoring the
    zero-third-party-dep posture (AID ships nothing; it *uses* the operator's existing Tailscale if
    present, else cleanly declines `--remote`).
  - **No daemon AID owns.** AID does not start/stop `tailscaled`; it assumes the operator's Tailscale is
    running (the normal state on a tailnet-joined VM). This keeps `infrastructure.md`'s "no server, no
    daemon owned by this project" property intact.
- **EI-2. (Documented fallback, not implemented in MVP) Cloudflare Tunnel + Access** — recorded in RM-2/
  RM-3 as the runner-up so the LC-2 handle scheme stays mechanism-agnostic. **Not** an MVP dependency.

---

### Test scenarios (deliverables, not polish)

`tailscale` is **stubbed** (a PATH shim) in CI so these run without a live tailnet (mirrors feature-004's
runtime-stub approach T-8/T-11 and feature-003's "skip if runtime absent" PT-1 pattern).

| # | Scenario | Asserts |
|---|----------|---------|
| T-1 | `expose <port>` with stub `tailscale` present+logged-in | invokes `tailscale serve --bg <port>` (asserted on the stub's recorded argv), prints handle line `tailscale-serve:<port>` + a `https://...` URL, exit 0 |
| T-2 | `expose` then `teardown <handle>` | teardown reverts the same port's serve mapping (stub argv shows `serve ... off`/scoped reset, NOT `reset`-all when other mappings exist), exit 0 |
| T-3 | `--remote` with **no** `tailscale` on PATH (and the not-logged-in variant) | `expose` exit 10; feature-004 surfaces exit 10, server stays local, `dashboard.pid.remote=false` (this is feature-004 T-11 viewed from this side) |
| T-4 | **never-funnel guard** (SEC-1) | grep `bin/aid` + `bin/aid.ps1` exposure helpers contain **no** `funnel` token; the stub `tailscale` fails the test if ever called with `funnel` |
| T-5 | `teardown` with a malformed/empty handle, and a double `teardown` | exit 0 idempotent (no error), mirrors feature-004 idempotent stop |
| T-6 | `expose` with a non-loopback target token (internal-contract probe) | exit 11; feature-004 maps to user-facing 10; **never** widens a bind |
| T-7 | `tailscale serve` invocation fails (stub returns nonzero) | `expose` exit 12; the half-up serve is reverted (stub argv shows the off/reset); never public |
| T-8 | Bash vs PowerShell parity for T-1/T-3/T-5 | identical exit codes + handle shape + messages (extend `test-aid-cli-parity.sh`) |
| T-9 | ASCII-only guard | `bin/aid` + `bin/aid.ps1` (incl. the new helpers + the SEC-2 reminder string) still pass `test-ascii-only.sh` |

(The *real* host/user-scoping — that the ACL grant actually denies an unauthorized peer — is a tailnet
**policy** property, not a code property, and is verified by the operator against their tailnet, not by
AID's CI. T-4 + SEC-1 verify the code-side never-public invariant; SEC-2/RM-4 document the operator-side
scoping. KI-005 records the residual-mapping caveat.)

---

### Known issues registered by this feature

This feature adds an exposure helper to `bin/aid`/`bin/aid.ps1` and ratifies the LC-2 contract. The
never-public (SEC-1, grep-asserted), failure-closed (SEC-3), and clean-teardown (SEC-4) properties are
enforced invariants verified by tests, not carried as debt. Two genuine items are registered in
`known-issues.md`:

- **KI-005** — a `tailscale serve` mapping lives in the `tailscaled` daemon and **survives an AID server
  process crash**, so a crash between `expose` and a clean `stop` can leave a serve mapping up until the
  next `aid dashboard stop`/`start` reclaims it. Bounded operational caveat (the surviving mapping is
  still tailnet-only + grant-scoped — never public, no C1 breach); the next lifecycle command reverts it.
- **KI-006** — the host/user **ACL grant is an operator-installed tailnet policy fact AID cannot author
  or verify from the node** (admin-plane). AID detects Tailscale + brings up `serve` (tailnet-only,
  never public — C1 holds unconditionally) and prints a reminder, but the C3 *narrowing* depends on the
  operator's grant. Documented dependency, not a defect: without the grant the channel is tailnet-wide
  (the plain-`serve` gap), still never public; with it, it is host/user-scoped per C3.

(The existing KI-001..KI-004 are feature-001/002 concerns this feature does not touch.)

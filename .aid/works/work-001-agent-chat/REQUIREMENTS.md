# Requirements

- **Name:** Agent Chat Channel
- **Description:** Delivers a local, CLI-administered node that lets AI coding-assistant sessions message one another across repositories, tools, and LAN-connected machines.

> **Seeded from a predecessor rather than interviewed from zero.** §1–§3, §6 and §10 are
> carried verbatim; §5 carries FR-0–FR-7 with FR-8 withdrawn and deliberately not
> renumbered; §9 is renumbered to a gapless **AC-1–AC-22**, since a fresh work has no
> citation history to protect and the criteria deleted during the interview or withdrawn
> with FR-8 need no struck rows.
>
> **§4, §7 and §8 are carried as-is and left open** — `state: Pending` in `STATE.yml`, which is
> what makes `/aid-describe` resume on exactly those three. Each is correct in substance but
> still carries narrative about a scope reset that is this document's prehistory rather than its
> content, and cleaning that up is a conversation with the stakeholder, not a mechanical edit.
> (`Pending` rather than a more descriptive `Partial` because `Pending | Complete` is the enum
> the state template declares, and an out-of-enum value in a machine-read field is a defect
> however well it reads.)

## 1. Objective

Provide a communication channel that lets one AI coding-assistant session send messages or
notifications to another. The sessions work in **different repositories**, and are started
by the operator's own orchestrator rather than by a lead-spawns-teammates framework.

Sessions talk in **chats**. A chat is the only thing a message is addressed to, and the
smallest chat — two members — *is* a direct message. Larger chats add **mention** (aimed at
someone, visible to all) and **whisper** (visible only to one member).

The channel is delivered as a **local node** — a service started and administered by the
`aid` CLI, running on each machine and serving every session on it, regardless of tool. The
node itself has a single responsibility, message exchange, and ships no operator surface of
its own. Nodes federate to other machines over a trusted LAN. Sessions reach the node
**through the `aid` CLI**, which carries the whole message plane over one core; a **rendered
chat skill** makes that surface discoverable to a session without being a second surface of its
own (§4, FR-0).

A hosting server is available but is **deliberately unused in v1**; it is held in reserve
for a later delivery, should NAT traversal or relay ever be required.

## 2. Problem Statement

An AI coding-assistant session is **turn-based, not a server**. It has no event loop that
can be pushed to, and receives nothing asynchronously mid-turn; between turns it is idle,
waiting for input. Consequently the transport is not the hard part — **getting a message
into a turn is**.

Delivery splits by the recipient's lifecycle at the moment the message arrives:

| Recipient state | What "notify" actually means |
|---|---|
| Idle (finished its task, sitting there) | A turn must be **started** for it |
| Actively running its own loop | It can only be handed the message at its **next turn boundary** |
| Not yet started | The notification *is* the **launch** |

This is why named pipes, Unix sockets, and Redis pub/sub feel correct but do not by
themselves solve the problem: nothing inside the recipient is listening on the socket,
because these tools expose no listener loop. The pattern must be chosen by the recipient's
lifecycle, not by the IPC technology.

Today there is no shared mechanism for this coordination.

### Prior art considered (input, not a decision)

1. **Resume an idle instance** — `claude -p --resume <session-id> "<message>" --bare`,
   serialized with `flock`. Lands as a real user turn with context intact; no live process
   or relay daemon; survives reboot. Caveat: `--resume` spawns a *new* process continuing
   the session, so a still-live original on the same working tree causes conflicts. Saved
   mid-session hook output replays stale; only `SessionStart` hooks re-run
   (`source=resume`).
2. **File inbox + `Stop`-hook turn-guard** — sender appends to a JSONL inbox; the
   recipient's `Stop` hook blocks turn-end when mail is unread. Requires the
   `stop_hook_active` guard or it loops forever. Limitation: only fires while the recipient
   is still taking turns; a fully idle recipient never picks the mail up.
3. **Persistent bidirectional streaming** — `claude -p --input-format stream-json
   --output-format stream-json`. The only CLI mechanism for bidirectional programmatic
   comms in print mode, but underdocumented and subject to a block-buffering bug when
   piped. Amounts to building and babysitting a daemon.
4. **First-party Agent Teams** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) — mailbox +
   `SendMessage` + shared task list, but modeled as one lead spawning teammates on a
   *shared* codebase, experimental, and token-heavy. Its *mechanism* (file inbox,
   between-turn pickup) is applicable; its framing is not.

## 3. Users & Stakeholders

**Participants (the messaging endpoints).** AI coding-assistant sessions, explicitly not
one vendor:

| Participant | Status |
|---|---|
| Claude Code | **v1 proving pair.** Reference host; wake mechanism understood first-hand but **not yet proven — the P0 spike tests it first** (§8) |
| Cursor | **v1 proving pair.** Wake route identified, one measurement outstanding (P0) |
| Antigravity | Named target; not a v1 gate. Researched, but its documentation is **silent** on external wake — no route known |
| Copilot CLI | Named target; not a v1 gate. Wake route documented (`agentStop`), unmeasured. (GitHub Copilot CLI — named **Copilot CLI** throughout, matching the profile AID renders into) |
| Codex | Named target; not a v1 gate. **Not researched at all** — the only host nobody has looked at, which is a different gap from Antigravity's, where the looking was done and found nothing |
| Future/unknown tools | Must be supportable without redesign — via the FR-5.2 adapter contract |

**The target case:** a developer in Cursor on one machine exchanging messages with a
developer in Claude Code on another machine on the same network. Every other case — both
sessions on one machine, both in the same tool, one-way only — is a subset of it. Solving
the target case solves them all.

**Operator.** The human running the fleet, who launches sessions via their own
orchestrator and needs to see and audit what was sent between them.

## 4. Scope

### In Scope

- **Chat-based messaging between sessions**, regardless of which tool hosts each session.
  A chat is the only addressing unit; a two-member chat is a direct message. Within a chat
  of more than two, a message may **mention** members (visible to all) or **whisper** to one
  (visible only to them).
- A **local service (node)**, started by the CLI, that all local sessions connect to.
  There is no installation step: the node ships inside the `aid` payload (FR-7.6).
- **Cross-machine** connection between nodes on a **trusted LAN**: peers **find each other**,
  and store-and-forward at the sending node so a peer whose machine is offline still
  receives its messages. **The discovery mechanism is deliberately not named here** — it is
  stated as an outcome, because the research behind FR-6.1 found that no single mechanism
  works everywhere users actually are.
  **And the promise is deliberately bounded: discovery always works, by a path that depends
  on no network feature. Finding peers *without configuration* is a convenience layered
  above that, offered where the network permits and promised nowhere** — the environments
  that defeat it are ordinary ones (FR-6.1), and a promise the product cannot keep on a
  developer's own laptop is worse than one it does not make.
- **Delivery to a live session that is not currently taking a turn**, via an in-tool
  subscriber that holds a token-free wait open and turns an arriving message into a turn
  (FR-5.2). An idle session is woken on arrival; a busy one receives at its next turn
  boundary. **Pull remains the universal floor** — a session with no subscriber armed reads
  its inbox at its own turn boundaries using the same read tool.
- **No process spawning or session resumption anywhere in the product.** Launching a
  session that is closed or does not yet exist remains the responsibility of the
  operator's existing orchestrator.
- **A rendered chat skill**, in the repository's existing canonical-skill form, so that a
  session *discovers* the chat exists. The `aid` CLI is on PATH but is not advertised to a
  model; a skill is. It renders into all five host dialects through machinery this repository
  already has, invokes the CLI (FR-7.4), and reimplements nothing.

### Out of Scope

- **An MCP façade.** The rendered chat skill above is the agent-facing surface instead, and it
  serves the only thing a second surface was needed for — discoverability — on better terms:
  all five hosts by construction, no third-party dependency, and nothing for the user to
  install by hand. §7 carries the full reasoning.
- **Raising the repository's Python floor.** Nothing in this design depends on what the
  repository declares — the node states its own runtime requirement (FR-7.7) — so the raise is
  not this work's to make, whatever else changes around it. (A channel decision has been
  described to this document as settled; it is an input, not a fact this document asserts, and
  the exclusion holds either way — see the FR-8 note.) The maintainer-only profile renderer
  stays on Python and is a separate, maintainer-scoped concern.
- **A second implementation of the node.** One runtime, one implementation. The local
  dashboard server's Node/Python twin is a precedent this work declines to follow — roughly
  8,300 lines mirroring roughly 10,100, kept in step by a dedicated CI parity gate. A node
  carrying durable storage, federation and per-host adapters would be worse.

- **NAT/firewall traversal** and any internet-scale or cross-network reach. v1 assumes a
  flat, trusted LAN.
- **Relay / rendezvous infrastructure.** The available hosting server is deliberately
  unused in v1 and held in reserve for a later delivery.
- **Untrusted or public networks.** Trust is implicit in network membership: being on the
  LAN is the only condition for participating. There is no key, password, or login
  anywhere in this product — so the network itself must be a controlled one.
- **Launching or resuming sessions.**

## 5. Functional Requirements

**One surface, one core.** The **`aid` CLI** is the whole product surface — administration,
the subscriber, and the full message plane. HTTP is the node's internal transport, not a
second public surface: the subscriber reaches it through a CLI invocation (FR-7.4), so
nothing outside the product calls it directly.

A **rendered chat skill** sits above the CLI as *documentation the model can find*, not as a
second surface. It carries no logic and holds no state: every operation it describes is an
`aid chat` invocation.

### FR-0 — Surface

| # | Requirement |
|---|---|
| FR-0.1 | There is **one core implementation** of the message plane. No face may reimplement it, and a face that cannot be expressed as a call into that core is not added |
| FR-0.2 | **A session reaches the message plane through the CLI** — `send`, `inbox`, `ack`, plus its own chat membership (`join`, `leave`, list-my-chats; FR-3.4). Administrative operations exist on the same CLI and are **not** described by the chat skill (see FR-7.3) |
| FR-0.3 | The CLI covers administration, the subscriber, **and** the full message plane, so the product is fully functional on every host, with no per-host protocol support required of anyone |
| FR-0.4 | **The product writes no host tool's configuration.** It renders a skill into the host dialects it already supports, through the same pipeline as every other AID skill, and touches nothing else — no MCP registration, no settings file, no hook wiring. A host whose skill is absent loses discoverability, never capability: the full message plane stays reachable over the CLI per FR-0.3 |

### FR-1 — Node lifecycle

| # | Requirement |
|---|---|
| FR-1.1 | **The node needs no installation step.** It ships inside the `aid` payload (FR-7.6), so there is nothing to fetch, resolve, verify or install: the CLI **starts** it, and starting it is safe to run without checking whether it is already running |
| FR-1.2 | The node runs as a background service, independent of any session's lifetime |
| FR-1.3 | The CLI reports node status and can stop it |

> **One sub-decision is deliberately left to `/aid-specify`, and named rather than assumed.**
> FR-1.1's "safe to run without checking" was previously carried by `deploy`, which was
> idempotent; `start` was not, and returned a distinct code when the node was already running,
> matching `aid dashboard start`. With `deploy` deleted there is no longer a verb holding that
> property, so `start` must either **absorb it** (already-running becomes success) or **keep the
> distinct code** and leave FR-1.1 satisfied by the absence of an install step alone. The
> dashboard precedent points one way and this requirement's original wording points the other.
> Nothing else in this document depends on the answer.

### FR-2 — Session registration

| # | Requirement |
|---|---|
| FR-2.1 | A session registers with `register(name, tool, cwd, capabilities)`, binding itself to a **stable name**. The name is an **identity, not an address** — it is how a session is recognised inside a chat, mentioned, and whispered to; it is never a destination on its own |
| FR-2.2 | A session's full id is **machine address + session name**, mirroring the chat rule in FR-3.2. Names are unique per machine. Re-registering an existing name **reattaches** that session to its existing chat memberships and positions |
| FR-2.3 | **Liveness is tracked** (heartbeat or connection), and drives **two distinct states at two thresholds** (§6). **Stale** — quiet past the stale threshold — is a *display* state: the member is shown as probably gone and **nothing is released**. **Reaped** — quiet past the longer reap threshold — is the node giving the member up for good: its registration is released and it **stops counting toward its chats' trim points**, which is what lets those logs be trimmed again — **including messages it never read.** Its identity is not destroyed: the name is free and re-registering it is accepted at any time. Tracking and stale-marking belong to registration; reaping belongs to retention |

### FR-3 — Chats and addressing

**The chat is the only addressing unit.** There is no direct-to-session address. A message
is always sent *to a chat*, and a chat always has at least two members. A two-member chat
**is** a direct message — the same mechanism, not a special case. This is deliberate: one
concept instead of two, with private conversation as its smallest instance.

| # | Requirement |
|---|---|
| FR-3.1 | **Listing has a local half and a network half, and they ship at different stages.** *Local* — list the chats hosted on this machine, and the chats the calling session belongs to. Needs no network and is available from the first usable release, because a session cannot join a chat it has no way to name. *Network* — list machines on the network and, for a given machine, the chats it hosts and their members, with tool, liveness, and declared capabilities. Arrives with federation |
| FR-3.2 | A chat's full id is **machine address + chat name**. When the machine address is omitted, resolution is **local-machine-only**: if no chat of that name exists on this machine the result is **not found**, even when a chat of that name exists on another machine. There is no silent remote fallback |
| FR-3.3 | Every chat has a **home machine** — the machine in its id. Members on other machines take part remotely; the chat itself lives in one place |
| FR-3.4 | **Chat control is split.** Chat *existence* (create, delete) and any change to *another* session's membership are administrative and CLI-only (FR-7.2). A session may manage **only its own** membership: `join(chat)`, `leave(chat)`, and listing the chats it belongs to. Joining a chat that does not exist **fails with an explicit error** — a session never creates a chat implicitly |
| FR-3.5 | **Mention** — a message may flag one or more members by name. The message stays visible to the whole chat; the flag marks who it is aimed at |
| FR-3.6 | **Whisper** — a message may be directed to exactly one member, and is then visible **only** to that member and its sender. Other members never see it, in delivery or in history |
| FR-3.7 | Mention and whisper are meaningful only in a chat of **more than two** members. In a two-member chat every message already has exactly one recipient, so neither is required — and a whisper there is equivalent to an ordinary message |

### FR-4 — Messaging

| # | Requirement |
|---|---|
| FR-4.1 | `send(chat, body, kind?, idempotency_key?, mention?, whisper_to?)` delivers to a chat. `mention` flags members without restricting visibility; `whisper_to` restricts visibility to one member (FR-3.5, FR-3.6). The two are mutually exclusive on a single message |
| FR-4.2 | Each **chat** owns a **durable message log** that persists across session restarts and node restarts, and each **member holds its own position** in that log. A session in several chats holds one position per chat |
| FR-4.3 | `inbox(chat?, cursor?)` returns messages after the caller's position — for one chat, or across every chat the caller belongs to when `chat` is omitted. Whispers not addressed to the caller are never returned |
| FR-4.4 | `ack(chat, cursor)` advances the caller's committed position in that chat |
| FR-4.5 | Delivery is at-least-once; recipients dedupe on the idempotency key |
| FR-4.6 | Messages carry a `kind` and an optional `correlation_id` / `reply_to` |
| FR-4.7 | A reply is an **ordinary asynchronous message** that wakes the requester through the normal path. The API exposes **no blocking operation** — no session's turn ever stalls waiting on another session |

### FR-5 — Wake and subscription

| # | Requirement |
|---|---|
| FR-5.1 | The node offers a **push subscription** — a connection a subscriber holds open and the node pushes to on arrival (WebSocket, or a long-poll for hosts that cannot hold a socket). The subscriber is **not required to exit** to deliver |
| FR-5.2 | **Waker adapter, one per host tool.** Every adapter satisfies one contract: *wait without consuming model tokens, and turn an arriving message into a turn.* The node, the store, and the wire protocol are identical across hosts; only the adapter differs. A host with no viable adapter degrades to FR-5.3, it does not block the product |
| FR-5.3 | **Pull floor:** reading the inbox is fully usable with no subscriber armed |
| FR-5.4 | **Idle and busy are different paths, both required.** *Idle* — the adapter produces a turn as soon as a message arrives. *Busy* — messages accumulate and are delivered at the session's next turn boundary. Neither path loses a message; the busy path only delays it |
| FR-5.5 | **The wait must be free.** An adapter blocks in a process outside the model, never by keeping the model in a poll loop. Cost while idle is zero tokens |

### FR-6 — Cross-machine (trusted LAN)

| # | Requirement |
|---|---|
| FR-6.1 | **Nodes find each other on the LAN.** This is stated as an *outcome* rather than a mechanism, deliberately: research established that no single mechanism reaches every environment users are actually in — WSL2 host-to-distro multicast is an open upstream defect, access-point client isolation and VLAN splits defeat broadcast and multicast alike, and macOS 15+ gates both silently for a per-user agent. Of eleven comparable local-first tools surveyed, only two make mDNS their primary mechanism, and **every one of them ships a manual path as the backstop.** The requirement is therefore that discovery **works**, with a guaranteed path that depends on no network feature, and zero-configuration discovery layered above it as best-effort. `/aid-specify` fixes the layers; this requirement fixes only that the outcome is reached and that no layer is load-bearing alone |
| FR-6.2 | Node-to-node trust is **implicit in network membership** — a node reachable on the trusted LAN participates. No key, password, or login is required, of a peer node or of a session |
| FR-6.3 | The **sending** node stores and forwards a message whose destination chat's **home machine** is offline, delivering it once that machine returns |
| FR-6.4 | The handshake compares protocol versions by **semantic versioning**: nodes sharing a **major** version interoperate, and minor or patch differences are compatible by contract. Only a **major** difference — which by definition means a breaking change — fails the handshake, and it fails with an explicit error |

### FR-7 — Administration and the privilege boundary

The **`aid` CLI is the complete administrative interface** to the local node. All service
management goes through it; sessions reach only the message plane.

"The CLI" throughout this document means **the `aid` CLI**. The node itself ships no
operator-facing command — it is a service, administered from outside. This mirrors the
existing local dashboard server: a loopback-bound background service with no CLI of its
own, administered through `aid`, with state under `$AID_HOME`.

| # | Requirement |
|---|---|
| FR-7.1 | The CLI shows machines and registered sessions, the chats on this machine with their members, each member's unread depth per chat, and a message audit log |
| FR-7.2 | All service management — start, stop, status, configuration, retention policy, **chat lifecycle (create, delete) and any change to another session's chat membership** — is performed **through the CLI only**. The CLI holds the complete chat mechanism, including everything a session can do for itself. **`deploy` was the first item on this list and is deleted, not moved:** the node ships in the `aid` payload (FR-7.6), so there is no install operation to administer. There is no peer-pairing operation either: trust is implicit in network membership (FR-6.2), so there is nothing to exchange or approve |
| FR-7.3 | **The agent-facing surface describes the message plane and nothing else.** The chat skill documents `send` / `inbox` / `ack` and a session's own membership (FR-3.4). It does not describe stopping the node, altering configuration, retention policy, creating or deleting a chat, or changing another session's membership. It documents no `wait` either: FR-4.7 forbids a blocking operation anywhere, and waiting is the waker adapter's job. **This is a surface boundary, not a sandbox** — and the honesty is now structural rather than a caveat: the boundary is a *skill that omits things*, and any session whose host lets it run shell commands can invoke the full CLI directly. It states what the product **offers** an agent and is explicit that it prevents nothing. Real containment would need a session-scoped credential, which this product does not have (there is no authentication anywhere — §4) and does not claim |
| FR-7.4 | **Every face invokes the CLI rather than reimplementing node behaviour**, and the node publishes no client library or SDK for one to bind to. The chat skill is instructions that call `aid chat`; the subscriber of FR-5.1 is a CLI invocation. Together these keep the HTTP transport internal to the node |
| FR-7.5 | The node has a **single responsibility: message exchange.** It ships no CLI and no operator surface of its own, and every human-facing operation against it is an `aid` subcommand. A change that would give the node its own operator-facing command is out of scope |
| FR-7.6 | **The node ships inside the `aid` payload, and carries no third-party dependency.** The node needs no third-party library at all: mDNS is replaced by a discovery design built on the standard library (FR-6.1), and the MCP server implementation left with the façade (§4 Out of Scope). A component with zero dependencies costs an uninterested user nothing but disk, so the separation bought nothing and cost a whole install-and-fetch surface. The node is therefore provisioned exactly as `dashboard/` already is: a runtime component at the repository root, listed in a manifest that every publication channel derives its file set from. **AID's zero-runtime-dependency decision is preserved literally, not amended** — no carve-out is required, because there is nothing to carve out |
| FR-7.7 | **A Node runtime is a prerequisite of the chat node, and this is stated rather than implied.** The `aid` CLI itself remains runtime-free — Bash and PowerShell only — so installing, updating and removing AID needs nothing but a shell. What this requirement governs is **the chat node**. Two other components need Node already, before and independently of this work, and are named for context rather than claimed as scope: the two on-demand skills that invoke Node scripts, and the dashboard server, which has offered a Node runtime alongside a Python one for as long as it has existed — **which of those two the dashboard keeps is adjacent work, not this requirement's** (see §10). The prerequisite is **checked before any side effect, with an explicit, actionable error** — never a stack trace, never a silent failure. It is honest about reach, and the distinction it draws is the load-bearing one: the audience installs its host tools through npm, so a runtime is **present**, but **no named host tool establishes which version** — several bundle their own or declare no minimum at all (§8 states this per host rather than as a count, deliberately). So Node may be assumed present; *a recent* Node may not, which argues for a **low** declared floor. **The node's floor is therefore `>=22.13.0`** — low, and determined rather than chosen: the built-in SQLite module the store depends on does not exist before 22.5.0 and needs a flag the node cannot assume until 22.13.0 (§8). It is stated here rather than deferred precisely because it looks like a judgement call and is not; a reader weighing the adoption argument alone would reasonably inherit the repository's `>=22` and ship a node that cannot open its own store on five of that line's releases. **The floor for components every adopter runs is a separate number and is not this requirement's** — they have different needs and need not agree. **One consequence of that floor is a requirement in its own right: the node emits no runtime warning the operator cannot act on.** Below Node 24.15.0 the built-in SQLite module prints an `ExperimentalWarning` to stderr on every open, so on the declared floor every start would carry a line nobody can do anything about. The node suppresses **that** message on **that** runtime range and nothing else — never warnings wholesale, so a different experimental warning still reaches the operator. This is the same principle as the actionable-error rule above, applied to success rather than failure: the node's stderr is where AC-22's prerequisite error has to land, and a line on every start is what teaches an operator to stop reading it |

### FR-8 — withdrawn

**The number FR-8 is not reused**, so that any reference to FR-8.1–FR-8.7 resolves here rather
than to a different requirement that inherited it.

FR-8 would have raised the repository's declared Python floor. **It is withdrawn because that
raise was never a prerequisite for this work** — nothing in the messaging design depends on
what the repository declares, and the node states its own runtime requirement (FR-7.7). The
floor is due a raise on its own merit, and belongs to whichever work is due to do it.

> **What this withdrawal does *not* rest on.** A channel decision has been described to this
> document as settled — that PyPI is dropped, after which no shipped artifact would declare a
> Python floor at all. That is an **input this document was handed, not a fact it may assert
> about the repository**, and the withdrawal above is deliberately independent of it: if the
> channel stays, FR-8 is still withdrawn, for the reason given. Executing any of it — deleting
> `packages/pypi/`, retiring the publish job, choosing the dashboard's surviving implementation
> — is adjacent work, in scope for neither this document nor any criterion in §9.
>
> **On disk today `packages/pypi/pyproject.toml` still exists and still reads `>=3.8`**, so the
> Knowledge Base entry recording that untested floor (`M5`) is accurate and must not be closed
> until the deletion lands — at which point it closes as *Not Applicable*, its premise removed
> rather than its defect fixed.

The maintainer-only profile renderer remains on Python. It declares no floor of its own today,
and if it should, that is a separate maintainer-scoped change with no adopter-facing effect.

## 6. Non-Functional Requirements

### Delivery semantics

Treated as a conventional durable pub/sub problem — established solutions apply; no novel
mechanism required.

| Property | Requirement |
|---|---|
| Durability | Messages persist in the chat's log; survive subscriber disconnect and node restart |
| Delivery guarantee | **At-least-once**, with an idempotency key so a recipient can dedupe |
| Progress tracking | **Per-member position per chat**, with explicit acknowledgement — an unsubscribed interval delays delivery, it does not lose it |
| Ordering | FIFO **within a chat**: every member sees that chat's messages in the same order. **No** ordering guarantee *across* chats |
| Retention | A message is removed once it is **past its TTL *and* read by every live member** — never while an un-reaped member has still not read it. Plus a max **unread depth per member per chat** (the one bound defined in the limits table below), and **dead-session reaping** so a member that never reads cannot hold a chat's log from being trimmed indefinitely |

### Limits, retention, and policy

**Every parameter below is configurable.** The values are defaults, not constants — no
limit is hardcoded. All configuration is applied through the CLI (FR-7.2).

| Parameter | Default |
|---|---|
| Message TTL | **24 h** — the age at which a message becomes *eligible* for removal. It is removed only once every member has also read it; age alone never deletes an unread message |
| Max unread depth per member per chat | 1,000 messages |
| **Overflow policy** | **Reject the new send with an explicit error** (alternative: drop-oldest) |
| Max payload size | **None — messages are not size-limited** |
| Stale-session threshold | 30 min without heartbeat → marked stale in discovery. **Nothing is discarded** — the member keeps its place in every chat |
| **Reap threshold** | **24 h** without heartbeat → the node gives the member up for gone and **drops its claim on its chats**. What is released is its hold on the trim point, so messages it never read *do* then become removable — that is the point. Its **name is not destroyed**: re-registering it is accepted at any time |
| Long-poll timeout | **30 s**; the subscriber reconnects on timeout |

Overflow rejects rather than drops: a member that has fallen 1,000 messages behind is
broken, and the sender must learn that rather than have messages disappear silently.

**No message is destroyed unread by a member that is still there.** A chat's log is trimmed
only up to the point *every live* member has read, and a message is removed only when it is
**both** past its TTL **and** read by all of them. The TTL is an eligibility condition, not a
hard expiry — age alone never deletes a message a live member has not seen. This is
deliberate: a message that was sent, never delivered and never reported as undelivered is
exactly the failure the overflow policy above exists to prevent, and a hard expiry would
reintroduce it by another door.

**A reaped member stops counting.** Reaping is the one thing that can cause an unread message
to be removed, and that is its entire purpose: once a member is given up for gone, it is no
longer one of the members the trim point waits for, so a message only it never read becomes
removable. The guarantee is therefore bounded, not absolute — a message survives for as long
as some member that has not been reaped still has not read it.

**What bounds storage is therefore not time.** Two mechanisms carry it, and both are
required. The **unread-depth limit** stops a chat growing behind a member that has stopped
reading: once any member is 1,000 messages behind, further sends to that chat are rejected
with an explicit error. **Reaping** then clears the blockage: a member silent past the reap
threshold is given up for gone and its claim on the trim point is dropped, after which the
expired messages go. One consequence is accepted and stated plainly rather than left to be
discovered: a chat holding unread messages for a crashed session **keeps** them, and may stop
accepting new sends, until that session is reaped.

**Stale and reaped are two different states, and only the second releases anything.** Marking
a member **stale** (30 min without heartbeat) is a display state and changes nothing.
**Reaping** (24 h) is the node deciding a member is gone for good and releasing its claim, so
the trim point can move again — which does mean messages that member never read can now go.
Its **name survives**: re-registering it is accepted at any time, and the member simply starts
from the chat's current state.

The reap threshold and the message TTL share a 24 h default but are **separate settings**, so
message lifetime and dead-session patience can be tuned independently.

**There is no maximum payload size.** A message is never rejected or truncated for being
large. The consequence is that a chat's storage is bounded only by its message *count*, not
by its size on disk — the unread-depth limit caps how many messages may wait, not how many
bytes.

### Performance targets

**None for v1.** No latency, throughput, or wake-time target is set, and none is a
release condition. Speed is deliberately unconstrained until the design is proven.

## 7. Constraints

- The originating case is two sessions on **the same machine**; v1 additionally federates
  across a **trusted LAN**. The available hosting server is intentionally not part of the
  v1 topology.
- Sessions are launched by the operator's **own orchestrator**, not by a
  lead-spawns-teammates framework — the solution must not assume a shared codebase or a
  single lead.
- A session cannot be pushed to asynchronously; any design must respect the turn boundary.
- **A rendered skill is the agent-facing surface, and the reason is discoverability alone.**
  The `aid` CLI is on PATH globally and carries the whole message plane, so *capability* needs
  no second surface. What the CLI cannot do is **announce itself**: nothing advertises
  `aid chat` to a model, and a session that does not know the command exists will not guess it.
  A skill is exactly the artifact that fixes that, and this repository already renders one
  canonical skill into all five host dialects automatically.
  **An MCP façade is the alternative, and it loses on every axis that matters here.** The one
  thing it could do that a skill cannot — reach a session not running AID at all — is not a
  case that exists: AID must be present for a chat to exist, and the globally-installed CLI
  already reaches any session a skill could not. Against that it costs a third-party
  dependency, a per-host configuration snippet the **user** installs by hand, and coverage
  established for only two of the five named hosts — where the skill route covers all five by
  construction, costs no dependency, and needs no step from the user.
  **What this is deliberately *not* claimed on:** hosts that permit tool calls but forbid shell
  execution. Such a host would be reachable by MCP and not by a skill. All five named targets
  are terminal coding agents for which shell access is constitutive, so the category is
  believed empty here — but it is the one real thing given up, and it is named rather than
  argued away.
- **Host-agnostic (hard constraint).** Must work across Claude Code, Cursor, Antigravity,
  Copilot CLI, Codex, and future tools — no design may assume a single host's CLI or session
  model. This holds for the **pull** surface but **not** for waking an idle session.

### Decisions taken, and the alternatives rejected

Fourteen decisions that shaped this design, each with the alternative it rejected and why. The
rejected branch is the load-bearing half: the conclusions above and in §5 can be restated from
the design, but *what was tried and discarded* cannot, and without it a later reader re-proposes
a rejected option in good faith.

They were settled in an earlier `/aid-describe` run in another repository and carried here with
the requirements. **None has passed this work's approval gate, so any may be revisited** — they
are rationale, not ratified constraints. Three (ID-9, ID-12, ID-13) had an element overturned by a
later decision; each override is stated inside its own row, because a conclusion copied without
its override reinstates a design that was rejected.

> **Why these live here and not in `.aid/knowledge/decisions.md`.** That document requires each
> decision to be grounded in its evidence, and every entry in it cites a file that exists. This
> product does not exist yet, so the only evidence these could cite is this work folder — which
> the Knowledge Base may not reference, by rule, because the folder is pruned when the work
> ships. **Promotion to the Knowledge Base is ship-time work**, as `D30`+ with real evidence
> citations — ordinary ship-time KB work rather than a criterion of this requirement set.
>
> **On the ids.** These were `D1`–`D14` while they lived in `STATE.md`, and are `ID-1`–`ID-14`
> here — `ID` for *interview decision*, mapping exactly `Dn` → `ID-n`. Two live namespaces
> already claim the obvious spellings: `.aid/knowledge/decisions.md` uses `D1`–`D29` for AID's
> own decisions. A prefix that cannot be confused with that is worth more than continuity with
> a numbering that only ever existed in a file now retired. (An earlier draft also cited a
> per-feature Scope Ledger using `D-1`–`D-8`; that specification is not carried forward, so
> the collision it warned about no longer exists.)

| # | Decision | Rejected alternative, and why |
|---|---|---|
| ID-1 | **MCP cannot wake an idle session.** MCP is pull-only — invoked *by* an agent, *during* a turn. Server→client notifications and `sampling` exist in the protocol, but no host maps them to "start a turn" | A hosted MCP bus as the whole solution — architecturally cannot notify an idle session |
| ID-2 | **A local node per machine**, stood up by the CLI | A hosted central broker — cannot reach into a local process, and a hosted service that spawns local processes is remote code execution by design |
| ID-3 | **Wake = in-tool subscriber.** A skill arms a background process; the host's own background-completion notification produces the turn | An external waker (`claude -p --resume` plus `flock`) — per-host fragmentation, session-id capture, and two processes mutating one working tree. Also a `Stop`-hook mailbox — never fires once a session is fully idle |
| ID-4 | **The pull floor is retained** — a session with no subscriber reads its inbox at its own turn boundaries | Subscriber-only. Rejected because the floor is *free*: a woken session must read its mail anyway, so the read tool exists regardless |
| ID-5 | **No process spawning and no session resumption in the product** | Channel-owns-launching — the operator's orchestrator already launches sessions, so a dead session is a launch problem rather than a wake problem |
| ID-6 | **Address by stable name**, session id internal; the mailbox binds to the name | Session-id addressing — sessions restart constantly (context limits, crashes, `/clear`), which orphans undelivered mail and forces every sender to re-discover ids |
| ID-7 | **Async request/reply** via `correlation_id`, and **no blocking API** | A synchronous `ask(timeout)` — couples two turn-based agents' timelines; the asking agent stalls while the peer may not even be awake, and any timeout is a guess |
| ID-8 | **Durable log, at-least-once, per-member cursor, explicit ack** | Fire-and-forget. Under the durable model the re-arm gap becomes *latency* rather than loss — standard consumer-offset semantics |
| ID-9 | **Reject on overflow.** A full mailbox means a broken consumer, and the sender must learn that rather than have messages vanish. **The oversized-payload half of this decision is OVERRIDDEN:** it originally also hard-rejected large payloads, and there is now **no message size limit** at all — a message is never rejected or truncated for being large (§6). One consequence follows and is stated in §6: storage is bounded by message *count*, never by bytes | Drop-oldest, or truncation. Silent truncation had already been recorded as tech debt in the originating workspace |
| ID-10 | **Every limit is configurable through the CLI** | Hardcoded constants |
| ID-11 | **The CLI is the complete administrative interface, and the privilege boundary is absolute** — no administrative operation is reachable from the agent-facing surface | Exposing administration over MCP — an agent could then pair an unknown peer or stop the node |
| ID-12 | **One shared core, and no second implementation of the message plane.** **The MCP half of this decision is OVERRIDDEN ENTIRELY** (§4 Out of Scope): it originally put the message plane on *both* the CLI and an MCP façade over one core, and the façade is withdrawn — a rendered chat skill takes its place. **Note what the override does to the rejected alternative opposite:** the objection to CLI-only was that skills are the least portable layer and would need hand-authoring per host, and that is now known to be false for this repository, which renders one canonical skill into all five host dialects automatically. The surviving half — one core, no second implementation — is unchanged and is now FR-0.1 | CLI-only — skills are the least portable layer and would need hand-authoring per tool, forever, including future ones. MCP-only — leaves hosts with weak MCP configuration stranded |
| ID-13 | **v1 is same-machine plus a trusted LAN**, with no NAT traversal and no relay. **Two elements are OVERRIDDEN.** The pre-shared key is gone: there is **no authentication anywhere** in this product, and trust is implicit in network membership, which makes the network itself the security boundary (§4, §8). mDNS is gone as a *named mechanism*: FR-6.1 now states discovery as an **outcome**, because research found no single mechanism reaches every environment users are actually in — of eleven comparable local-first tools surveyed only two make mDNS primary, and **all eleven** ship a manual backstop. **The surviving core is unchanged** | Same-machine-only — loses the federation the stakeholder wanted. Full NAT traversal or a relay tier — all of the risk, none of the core value |
| ID-14 | **Risk-first priority:** the P0 spike runs before anything is built | Folding validation into P2 — would build federation on top of a wake mechanism that may not exist on three of the five target hosts |

## 8. Assumptions & Dependencies

**Cross-machine reach — resolved.** v1 assumes a flat, **trusted LAN**: peers find each other
(FR-6.1 — stated as an outcome),
trust implicit in network membership, store-and-forward for offline peers. Because there is
no authentication anywhere in the product, the security boundary *is* the network — anything
that can reach the LAN can send, read, and register. NAT/firewall traversal and any
relay tier are out of scope for v1; the hosting server is held in reserve. Corporate
networks that block inbound peer connections would invalidate this and force the relay
tier forward.

**Wake heterogeneity persists independently of node locality.** Moving the service
on-machine removes the remote-trigger problem, but not the per-host wake problem: each
tool has its own (or no) headless entry point. A session running inside a **GUI IDE** may
have *no* external injection path at all — launching that tool's CLI creates a *new*
session rather than delivering into the one the user is watching.

**Inverted delivery (the chosen model).** Rather than an external process injecting a turn,
something **inside the tool** subscribes to the local node and the host's own machinery
turns an arriving message into a turn — same session, context preserved. Consequences:

- No external trigger, no remote-code-execution surface, no session-id capture, no
  `flock`, no risk of two processes mutating one working tree.
- The host requirement is *"can hold a wait open outside the model and surface an event to
  the agent"* — a materially lower bar than *"exposes a headless resume CLI"*.
- Only applies to a **live** session. A closed session is not woken.

**Host research — what is actually known.** The wake is the only unproven part of this
product; transport, storage, and sending are ordinary work.

**Read the sourcing column, not just the verdict.** Cursor, Copilot CLI and Antigravity were
checked against **published vendor documentation**, catalogued in the Knowledge Base's
external-source registry. **Claude Code was not** — its row rests on the capability
description exposed by the tool at runtime, which is first-hand but is not a citable
published document and is not in that registry. That asymmetry matters, because Claude Code
is the host whose mechanism is understood in the most detail — **not one that has been
demonstrated.** Nothing here is a proven wake; the table below rates confidence in the
*mechanism*, and its Claude Code row ends by deferring proof to the spike. If that row is
wrong, FR-5 has **no demonstrated instance** at all — the blocking-hook route on Cursor and
Copilot CLI would still be plausible, but every one of them would then be unproven together.
That is why P0 tests Claude Code first and Cursor second.

| Host | Wakes an idle agent? | Confidence |
|---|---|---|
| **Claude Code** | **Yes.** A long-lived monitor streams events into the session, including a WebSocket source that the server pushes to, and events arrive even while the session waits on the user | High on the mechanism, but **first-hand rather than cited** — taken from the tool's own runtime capability description, not from a published document, and therefore absent from the external-source registry. **Proof is deferred to the spike** |
| **Cursor** | **Not directly.** Its docs state plainly that no mechanism exists for a background process to initiate a turn. But its `stop` hook fires when the agent loop ends and can **inject the next user message**, so a hook that *blocks* until mail arrives is a viable waker | Medium — mechanism documented, blocking duration unmeasured |
| **Copilot CLI** | **Not directly.** Docs are explicit that no idle hook exists and no external process can inject into a session. Its `agentStop` hook can force a further turn, giving the same blocking-hook route as Cursor | High on the limit, unmeasured on the route |
| **Antigravity** | **Unknown.** Documentation is silent | Low |
| **Codex** | **Unknown — not researched.** The fifth profile AID renders into, and the one host nobody has looked at. Recorded so its absence is a stated gap rather than an oversight | None |

Two further findings bound the design. First, **MCP could never have been the waker**:
server-initiated messages (sampling, elicitation) are unsupported in Copilot CLI and
unimplemented in Cursor, so it could only ever have been a pull surface. This finding is
retained even though the façade is now out of scope (§4), and it earns its place twice over:
it is the constraint that would bind any future reconsideration of MCP, and it is evidence
that the façade was never load-bearing for the one hard part of this product. Second, the pull
floor is not a nicety — on any host whose blocking-hook route fails, it is the only mechanism
left.

**Assumption requiring validation (P0).** That a host can hold a token-free wait and turn
an arriving message into a turn **while the session is otherwise idle**. **Unproven on both
proving hosts** — for Claude Code the mechanism is understood first-hand but never
demonstrated end to end, and for Cursor the route is documented but its blocking limit is
unmeasured. That is why P0 tests Claude Code first (test 1) and Cursor second. The single
number that decides the design is **how long a Cursor `stop` hook may block before the host
kills it.**

**Toolchain — Node, with no third-party runtime dependency.**

| Concern | Choice | Third-party dependency |
|---|---|---|
| Runtime | Node | — |
| Durable store | the **built-in SQLite module**, `node:sqlite` | **none** |
| HTTP transport | the built-in HTTP server | **none** |
| Long-poll timeout / abort | the runtime's own cancellation primitive plus the request-closed event | **none** |
| LAN discovery | the built-in UDP socket module, plus a static peer list (FR-6.1) | **none** |
| Agent-facing surface | a rendered chat skill invoking the CLI (§4, FR-0.4) | **none** |

**The count is zero, and that is what inverted FR-7.6.** The previous toolchain needed two
libraries and the node was separated *because of them*; both are gone, so the node ships inside
the `aid` payload instead. AID's decision D10 — zero runtime dependencies, enforced by empty
dependency sets in both shipped manifests — is preserved **literally**, with no carve-out for an
opt-in component.

**The store contract was verified by execution, not by reading documentation.** Every clause
`/aid-specify` needs was run against the built-in module on **Node v24.19.0** and **v26.7.0**:
write-ahead logging engages and persists across reopen; full-synchronous durability sticks; a
partial unique index rejects a duplicate idempotency key while permitting many null ones;
cascading delete fires; a reader held a transaction open for three seconds while a writer
committed forty-nine sends with a slowest commit of three milliseconds; and a hard kill
mid-transaction left the committed rows intact, discarded the uncommitted one, and passed an
integrity check. **Two findings from that exercise are inputs to `/aid-specify`, not trivia:**
the default busy timeout is **zero**, so a non-zero value is *required* rather than advisable —
without it a second writer fails instantly instead of waiting — and there is **no
transaction-wrapper helper**, so the wrapper is hand-written.

**Re-verified on the floor the repository actually declares (2026-09-01).** The run above used
v24.19.0 and v26.7.0; the adopter-facing floor is `>=22`, so the two were never the same claim.
Every clause was therefore re-executed on **v22.14.0** and every one holds — write-ahead logging,
full-synchronous durability, the partial unique index rejecting a duplicate while two null keys
coexist, cascading delete, a clean integrity check — **including both findings**, which reproduce
exactly. The store decision is sound on the declared floor and not only on the versions it was
first tried against.

> **But `>=22` is not the floor this store can actually run on, and the gap is precise.**
> `node:sqlite` was **added in v22.5.0** behind `--experimental-sqlite`, and the flag requirement
> was **removed in v22.13.0** (and v23.4.0); release-candidate stability arrives in v24.15.0
> (`nodejs.org/api/sqlite.html`, accessed 2026-09-01). So `>=22` admits **22.0–22.4, where the
> module does not exist at all**, and **22.5–22.12, where it exists only behind a flag**. The
> effective floor for the node is therefore **22.13.0**. On 22.x and 23.x the module additionally
> emits an `ExperimentalWarning` on stderr at every open.
>
> **This is the same shape of defect the Knowledge Base already records against the Python
> channel** — a declared floor that nothing demonstrates — arriving from the other direction, so
> inheriting `>=22` silently would be that error made twice. **So the node declares
> `>=22.13.0`** (FR-7.7), which is what these measurements determine rather than merely inform.
> **The coupled question is settled with it: the node suppresses that warning** (FR-7.7). On
> 22.x and 23.x the module prints an `ExperimentalWarning` to stderr at every open — observed
> first-hand on v22.14.0 while running the store contract above — and release-candidate status
> arrives only in 24.15.0, so on the declared floor it would appear on every start. The filter
> is deliberately narrow: that message, on that runtime range, so any other experimental
> warning still surfaces. It also expires by construction — once the declared floor reaches
> 24.15.0 there is nothing left for it to match and it can be deleted.

**One dependency remains available and unused, and the reason is recorded.** The store is
`node:sqlite` at release-candidate stability rather than a pinned third-party binding. That
means it cannot be pinned or patched independently of the runtime, and the SQLite version it
carries follows whatever Node the user runs. The mitigation is a **seam, not a second
implementation**: all storage access sits behind one module, so substituting a pinned binding
later is a migration rather than a rewrite. **Building both was considered and rejected** — it
would double the test matrix permanently to insure against a failure that has not occurred, in
a product with no performance target. What is built instead is a startup assertion on the
runtime's reported SQLite version and the engine's own reported version, failing with an
actionable message rather than a stack trace.

**Two floors, not one — and only one of them is still open.** The components every adopter runs
and the opt-in node have different needs and need not agree. The research below is explicit
that both argue for a **low** floor rather than a fashionable one. **The node's is settled at
`>=22.13.0`** (FR-7.7): the store fixes its lower bound, so that number is read off the
evidence rather than chosen, and it is the lowest one that actually works. What remains
`/aid-specify`'s to fix is the **other** floor — the one for components every adopter runs,
which no store constrains. **Not one of the five named host
tools is established to require a recent system runtime**, and the evidence is stated per host
rather than as a count, because a count is what would be wrong here:

| Host | What was verified | Bearing on the floor |
|---|---|---|
| Claude Code | Its own documentation states the package downloads a native binary that does not use the system runtime, which is absent from its stated requirements | Says nothing about the user's PATH |
| Copilot CLI | Declares **no** engine minimum at all | Says nothing |
| Codex | **Lowered** its declared minimum to a version far below this repository's | Says nothing, and trends the wrong way |
| Cursor | Installs by script rather than through npm | Says nothing |
| Antigravity | **Not verified.** Its minimum was not opened against vendor documentation and must not be assumed | Unknown, and recorded as unknown |

The one tool the research did confirm as a genuine system-runtime consumer is **not one of the
five** this product targets, so it carries no weight here. Add that at least one current
long-term-support Linux distribution ships a runtime below the newest release line, and the
conclusion follows: a floor the system package manager cannot satisfy pushes users onto a
version manager, which is an adoption cost paid for nothing unless a capability actually
requires it. **The audience's runtime is present because npm was the install path, not because
any host tool guarantees a version.**

## 9. Acceptance Criteria

| # | Criterion |
|---|---|
| AC-1 | **The wake works, across tools.** A Cursor session and a Claude Code session **on the same machine**, in different repositories, share a chat and exchange a message, and the recipient **acts on it without any human action**. This is the stage-P2 form: it proves the wake and the cross-tool adapter contract without depending on federation |
| AC-2 | **The target case, end to end.** The same exchange with the two sessions on **different machines on the same network**. Identical to AC-1 except for the network hop, and deliberately separate because federation does not exist until stage P3 — AC-1 cannot pass at P2 while requiring a second machine |
| AC-3 | A member whose session restarts mid-flight receives its undelivered messages on reattaching to the same name, in every chat it belongs to, resuming each chat's own position |
| AC-4 | **Two machines on the LAN discover each other**, complete the handshake, and deliver a message across. Stated as an outcome: the criterion is silent on *how* they discover each other, because FR-6.1 is. It must be satisfiable by the guaranteed path alone — a criterion that can only pass when a particular network feature happens to work is a criterion that fails for reasons the product does not control |
| AC-5 | A message sent to a chat whose **home machine is offline** is delivered once that machine returns |
| AC-6 | With **no subscriber armed**, the message is still readable via `inbox()` at the session's next turn |
| AC-7 | **A two-member chat is a direct message.** Two sessions exchange private messages through an ordinary chat, using no mention and no whisper |
| AC-8 | A duplicate delivery is deduped by idempotency key; a reply correlates to its originating request |
| AC-9 | **The CLI stands the node up on a clean machine with no installation step**, and running the command again is safe. "Clean machine" now means only that `aid` is installed and the node has never run — there is nothing to fetch, resolve or verify, so the criterion no longer has an install path to exercise. Its remaining substance is that a first run works from nothing but the shipped payload, and that a second run does not fail. The precise form of the second half is the sub-decision named under FR-1.1 |
| AC-10 | **Node restart:** unacknowledged messages and every member's position survive a restart of the node itself — not merely of a session |
| AC-11 | **Retention holds, and nothing is lost to a live member.** A message past its TTL that every live member has read is removed; a message past its TTL that an un-reaped member has **not** read is **kept**. The max-unread-depth bound is enforced. A member silent past the **reap threshold** has its claim dropped and stops counting toward the trim point, after which that chat's log can be trimmed past where it had reached — **including messages that member never read**, which is the whole purpose of reaping |
| AC-12 | **Re-arm window:** messages arriving while the subscriber is between arms are all delivered, in order, on the next arm |
| AC-13 | **Chat delivery:** a message sent to a chat reaches every member of that chat, whether it has two members or many |
| AC-14 | **Operator visibility:** the CLI shows machines and sessions, this machine's chats and their members, per-member unread depth, and the audit log |
| AC-15 | **Surface boundary holds:** the agent-facing surface — the rendered chat skill — describes no operation that stops the node, changes configuration, creates or deletes a chat, or changes another session's chat membership, and *does* describe a session joining and leaving chats itself; joining a non-existent chat fails explicitly. **The verification changes shape with the surface, and honestly:** this is now a check on what the skill *offers*, not a check that an agent is *prevented*. FR-7.3 already said the boundary was never a sandbox, and with the surface being documentation rather than a protocol, that is plain instead of a caveat |
| AC-16 | **Only a major-version difference errors:** two nodes differing by minor or patch version interoperate normally; a major-version difference fails the handshake with a clear error — never silently half-work |
| AC-17 | **Whisper is private:** in a chat of three or more, a whispered message reaches only its target. Every other member sees it neither on delivery nor in history |
| AC-18 | **Mention is visible:** a mentioned message reaches every member, and the mentioned member can tell it was aimed at them |
| AC-19 | **Local-only resolution:** a chat name given without a machine address resolves on this machine only. When no such chat exists here the result is **not found** — even with a chat of that name on another machine on the network |
| AC-20 | **The spike answers, and the answers are written down.** All four P0 questions have recorded outcomes: whether an idle Claude Code session acts on a message with no human action; whether an idle Cursor session does; **the measured limit on how long a Cursor `stop` hook may block before the host kills it**, as a number; and whether the exchange holds across two machines on the LAN. A "we could not determine it" is a valid answer only when it records what was tried. No P0 code survives into P1 |
| AC-21 | **Chat lifecycle is the operator's, and it works.** The operator creates a chat and deletes one through the CLI; a created chat is joinable and a deleted one is not. Nothing else in §9 exercised chat creation, though every other criterion depends on a chat existing |
| AC-22 | **A missing runtime fails clearly, and only for the component that needs it.** On a machine with `aid` installed and no usable Node present, starting the node fails with an explicit message naming Node as the prerequisite — not a stack trace — and every `aid` command that needs no runtime continues to work. **Restated, not withdrawn:** the criterion previously named Python and the `deploy` verb; the prerequisite is now Node and the verb is `start`, but the property being tested is unchanged and still worth testing, because the CLI itself remains runtime-free and that promise is exactly what this criterion protects |

> **Every criterion above is settled; none is pending.** Most are stakeholder-ratified
> outright. Nine arrived from a quality check in an earlier interview and were unratified on
> arrival; they were reviewed one at a time and resolved — two **deleted** (the negative-auth
> criterion, because all authentication was removed from the product, and the oversized-payload
> criterion, because the size limit was removed), two **rewritten** (chat delivery, and version
> mismatch, now bound to semantic versioning), and the rest ratified as written. Nothing in this
> table is carried, assumed, or open.
>
> **Six criteria carry wording written by `/aid-define` rather than by the stakeholder**, whether
> newly created or re-worded. They are named because the distinction matters: the stakeholder
> ratified the requirements these verify, not these wordings.
>
> **Three from feature decomposition:** **AC-2** (new — AC-1 could not pass at its assigned
> stage, so it was split and the two-machine half became its own criterion), **AC-20** (new —
> stage P0 had no acceptance criterion at all), and **AC-1 itself**, re-worded by that same
> split, since the "on the same machine" qualifier and the stage-P2 explanation are both
> pipeline text.
>
> **Three from the cross-reference pass:** **AC-21** (new — chat lifecycle was verified by
> nothing, though every other criterion depends on a chat existing), **AC-22** (new — carrying
> the stakeholder's decision that a runtime is a prerequisite of the node rather than of AID),
> and the rewrite of **AC-11**, which now turns on the live-member bound and the reap threshold.
>
> **Two of the six verify a requirement the same pass also wrote**, which is worth flagging
> rather than burying:
>
> - **AC-22** verifies FR-7.7, a runtime as the node's prerequisite — but that requirement came
>   straight from a stakeholder decision, so only the wording is the pipeline's.
> - **AC-11** verifies FR-2.3's reaping clause and §6's reap threshold. Neither existed at
>   interview close, but both follow from decisions the stakeholder took: that a reap threshold
>   is a setting distinct from the 30-minute stale threshold, and that removal requires a message
>   to be **both** past its lifetime **and** read by every live member, so age alone never
>   destroys an unread message.
>
> The remaining four make an already-ratified requirement testable without adding scope. Where a
> requirement's own text had to be extended to make a criterion possible, that is said here
> rather than left to be discovered.

## 10. Priority

Ordered **risk-first**: the stage that could invalidate the architecture runs before anything
is built on top of it. From P1 onward each stage leaves something usable behind; **P0 is the
exception and is meant to be** — it produces answers, not product.

| Stage | Scope | Verifies |
|---|---|---|
| **P0 — POC** | Four tests against a throwaway stub node (one endpoint that waits, then returns a message), on **Claude Code and Cursor only**: (1) idle Claude Code session acts on a message with no human action; (2) idle Cursor session does the same via a blocking `stop` hook; (3) **how long a Cursor `stop` hook may block before the host kills it**; (4) the same exchange across two machines on the LAN | AC-20 — the single unvalidated assumption |
| **P1 — Skeleton** | Node lifecycle + CLI + registration by stable name + chat create/delete/**join/leave**, **including the operator changing another session's membership** (FR-7.2, FR-3.4 — CLI-only, and the counterpart to AC-15's prohibition) + the local half of listing (FR-3.1) + durable `send`/`inbox`/`ack` with fan-out to every member, **pull only** (FR-5.3 — the pull floor ships here, not at P2). **Lifecycle is smaller than it was:** with the node shipping in the `aid` payload (FR-7.6) there is no install step to build | AC-3, AC-6, AC-7, AC-8, AC-9, AC-10, AC-13, AC-21, AC-22 |
| **P2 — The wake** | Subscriber and re-arm (FR-5.1, FR-5.2, FR-5.4, FR-5.5 — FR-5.3's pull floor already shipped at P1), and the **rendered chat skill** (FR-0.2, FR-0.4 — FR-0.1 already shipped at P1), which replaces the withdrawn MCP façade. **FR-0.3 completes here, not at P1:** P1 delivered its administration and message-plane halves, but FR-0.3 also requires the CLI to carry the subscriber, which does not exist until this stage | **AC-1 (headline — same machine, cross-tool)**, AC-12, AC-15 |
| **P3 — Federation** | Discovery, handshake, store-and-forward, version negotiation (FR-6), machine-qualified chat ids and local-only resolution (FR-3.2), the network half of listing (FR-3.1). **Discovery is layered, and the layering is now matched by what §4 promises:** the guaranteed path (a static peer list plus heartbeat) satisfies AC-4, and it is also the whole of the promise — §4 offers zero-configuration discovery as a convenience where the network permits and commits to it nowhere. So shipping the floor delivers this stage rather than leaving a promise unmet, and the best-effort layer above it improves the experience without carrying a criterion | **AC-2 (the target case)**, AC-4, AC-5, AC-16, AC-19 |
| **P4 — Completeness** | Mention and whisper, audit/operator visibility, retention enforcement. Chats of more than two need nothing new here — fan-out to every member is P1 (AC-13); what P4 adds is **addressing within** a larger chat | AC-11, AC-14, AC-17, AC-18 |

**Every stage is required. None is optional.** The stages are a delivery *order*, not a
priority scale — each is reached in turn, and from P1 onward each leaves working product
behind (P0 excepted, above). Every criterion
in §9 is a ratified release condition, including the four that land last (AC-11, AC-14,
AC-17, AC-18), and §4 In Scope names mention and whisper explicitly. A late stage is late,
not optional; nothing here may be dropped at planning time without reopening §9.

**The stage sequence is now P0 → P1 → P2 → P3 → P4, with no parallel stage.** P0b was the only
one, and its removal takes with it the only breaking change this work was going to ship to
existing users and the only deliverable whose value was independent of whether the wake
mechanism works at all. Everything remaining is on the critical path, and everything remaining
depends on P0's answer.

**This requirement set ships no breaking change of its own**, and the distinction matters
enough to state rather than leave implied.

Two breaking changes sit nearby and are **not** in this document's scope, nor verified by any
criterion in §9: dropping the PyPI publication channel, and which implementation of the
dashboard is the shipped one. This is the Agent Chat Channel — §4 In Scope names the chat, the
node, federation, delivery and the chat skill, and names no publication channel and no dashboard
work. Both are released and announced on their own terms.

They are disclaimed rather than adopted, and deliberately so: a breaking change buried inside a
feature is how breaking changes ship by accident.

**Rationale.** P0 is near-free — a stub endpoint that waits, then answers — and is the only
stage capable of invalidating the architecture. If a host cannot hold a token-free wait and
turn an arriving message into a turn, the wake degrades to pull-only on that host. That
answer is needed before P1, not after P3.

**P0 expectations, stated so they are not mistaken later.**

| P0 is | P0 is not |
|---|---|
| Disposable. Every line is thrown away | The first slice of the node |
| Answering four questions, one of them a measured number | Producing anything shippable |
| Two hosts — Claude Code and Cursor | All five hosts |
| Done when the four answers exist | Done when something works nicely |

**Its only deliverable is the answers**, including the measured Cursor `stop`-hook blocking
limit. No P0 code is carried into P1.

**The other three hosts are named targets, not gates.** Copilot CLI, Antigravity and Codex
are expected to reuse the same adapter contract (FR-5.2), and none of them gates v1. Codex
is the weakest-known of the three — the fifth profile AID renders into, and the only host
whose harness has not been researched at all. That is stated rather than left silent, since
an unexamined host reads as an oversight otherwise.

**Why these two hosts.** Claude Code and Cursor are the v1 proving pair. The target case is
a developer in Cursor on one machine exchanging messages with a developer in Claude Code on
another machine on the same network — **every other case is a subset of it**: same machine,
same tool, or one-way. Copilot CLI, Antigravity and Codex remain named targets in §3 and are
expected to reuse the same adapter contract (FR-5.2), but none of the three gates v1.

## 11. Features

One `###` subsection per feature — a decomposition of §5 into an independently implementable
unit, not a second place to state requirements. Every §5 functional requirement maps to at
least one feature, and **every §9 criterion is owned by exactly one feature**, so both are
checkable. §9 holds a gapless **AC-1–AC-22**, and the ownership below accounts for all
twenty-two, once each, matching §10 stage for stage.

**Five features, one per §10 stage, and the count is a floor rather than a preference.** Two
things set it. **The spike cannot merge into anything:** AC-20 requires that no code from it be
carried forward, which is a statement about a feature boundary — with no separate feature there
is nothing for the criterion to be true of. **And the product cannot be a single feature:**
`/aid-plan` sequences features into deliveries, so one product feature yields one delivery and
§10's requirement that each stage from P1 leaves working product behind would exist only as
prose. Below those two constraints, the stages are also where cohesion falls, because they were
drawn around what ships together.

> **Feature ids were reassigned when this set was re-decomposed, and that is a hazard worth
> naming rather than a fact worth burying.** Eleven features became five, and three of the new
> ids — 003, 004, 005 — now denote something different from what they denoted before. Prose
> carried across that change kept citing the old numbers and therefore silently named the
> wrong feature; a cross-reference pass caught five such citations, and they are corrected
> above. **The lesson for anything written from here on:** cite a feature by id *and* title on
> first mention in a passage, so a future reassignment is visible as a contradiction rather
> than resolving quietly to the wrong target. Criterion ids are safe to cite bare — §9's are
> stable and a script proves each is owned exactly once.

### Feature 001 — Wake Feasibility Spike

- **Priority:** Must
- **Requirements:** **No §5 requirement.** This feature produces evidence, not product — it
  verifies the §8 assumption that a host can hold a token-free wait and turn an arriving message
  into a turn. Traces to §10 stage P0 and §8 Assumptions (host research; the unvalidated
  assumption)
- **Criteria:** AC-20  ← ids from §9; never restated here

> **Runs first, and alone.** Everything else in §11 is built on the answer this produces, and
> AC-20 requires that none of its code survive into the next stage — which is why it stays its
> own feature no matter how far the others are merged.

#### Description

Answer the one question that can invalidate the whole design, before anything is built on
top of it: **can a message arriving from outside turn an idle AI session into a live turn,
with no human touching anything?**

**Neither host has actually been proven.** For Claude Code the mechanism is understood
first-hand — a long-lived monitor streams events into a session, and events arrive even while
the session sits waiting — but that is a runtime capability description, not a published
document and not a demonstration, so it is untested like everything else here. That is
precisely why it is **test 1**: if the one host rated most likely to work does not, FR-5 has
no demonstrated instance at all. Cursor is weaker still. Cursor's
documentation states plainly that no background process can start a turn; the only way in
is its `stop` hook, which fires when a turn ends and can submit the next message. So the
route exists, and everything depends on a number nobody has measured: **how long Cursor
lets that hook block before killing it.** Block long enough and Cursor behaves like Claude
Code. Die after a second and Cursor falls back to reading its own mail.

The work is a throwaway stub — one endpoint that waits, then answers — driven against two
real tools on two real machines. **Every line is discarded.** The deliverable is four
recorded answers, one of them a measured number, and nothing else.

#### User Stories

- As the operator, I want to know whether an idle Cursor session can be woken at all, so
  that I find out before P1 is built rather than after P3.
- As the operator, I want the Cursor hook's blocking limit as a number, so that the
  subscriber's timeout is chosen from evidence rather than guessed.
- As a developer, I want a recorded "we could not determine it, and here is what we tried",
  so that an unanswered question is visibly unanswered instead of silently assumed.

#### Technical Specification

This specifies an **experiment, not a component**. What follows is an apparatus, a procedure,
and a record format. It deliberately designs no part of the node — the node's shape is
Feature 003's subject, and anything decided here would be decided before the evidence
exists, which is the whole reason this stage runs first.

Two properties govern every choice below:

1. **Nothing is proven yet.** Both wake mechanisms are hypotheses. Claude Code's is
   understood first-hand and is not a citable document (REQUIREMENTS §8, and
   `.aid/knowledge/external-sources.md` § Host agent-tool documentation: "Treat any Claude
   Code harness claim as unsourced until a published reference exists"). Cursor's route is
   documented but its one load-bearing number is unmeasured. The apparatus therefore treats
   both hosts identically and lets neither pass on reputation.
2. **Every artifact is thrown away** (AC-20, §10 "P0 expectations"). The location, the
   naming, and the file count below are chosen so that promotion into P1 requires a
   deliberate act that a reviewer can see, rather than an omission nobody notices.

##### Data Model

**Deliberately excluded — no schema exists to specify.** The spike persists nothing that
outlives a run: no chat, no message log, no member position. It writes exactly two on-disk
shapes, both of them evidence rather than state — an append-only run log (§ Telemetry &
Tracking) and the answer record (§ Recording the Answers). Both are specified where they are
used. Introducing a durable store here would be the first step toward the node, which this
stage exists to *not* build.

##### Feature Flow

###### The stub node — one endpoint, and only one

| Property | Value |
|---|---|
| Method and path | `GET /wait` |
| Query parameters | `after` (integer seconds, default `0`), `text` (string, default `""`), `run` (opaque run id, echoed back) |
| Behaviour | Sleep `after` seconds on the request's own thread, then respond |
| Success response | `200 application/json` — `{"run": "<run>", "text": "<text>", "sent_at": <epoch_ms>, "seq": <n>}`. **`seq`** is a per-process counter incremented once per request served, starting at `1`, reset when the stub restarts. It exists so two responses within the same millisecond are still orderable in the log, and so a restarted stub is visible as a counter that went backwards rather than as a silent gap |
| Errors | `404` unknown path; `400` non-integer, negative, or above `--max-wait` (default `86400`) `after` |
| Concurrency | `http.server.ThreadingHTTPServer` — a single-threaded server would serialise the two waiters and fail test 4 for a reason that has nothing to do with the wake |
| Every request | Logged before the sleep begins and again after the response is written (§ Telemetry & Tracking) |

**`after` is the send.** The stub has no `send` operation and gains none: the arrival time is
chosen by the caller when it arms the wait, and the timer expiring *is* the message being
sent. A real send path is Feature 002, and building one here would produce exactly the
artifact most likely to be promoted. `after=0` therefore does double duty — it is how a woken
session reports that it woke (the request itself is the machine-readable witness), at the cost
of nothing, because an immediate return is the same code path.

###### What the words mean, operationally

These three definitions are load-bearing; without them test 1 can pass while proving nothing.

- **Idle** — *no model tokens are being consumed and no turn is in progress.* This is FR-5.5's
  bar ("an adapter blocks in a process outside the model"), not "the window is unfocused". A
  session holding a foreground shell call open is **busy**, not idle, and a run arranged that
  way is invalid. The evidence that a run was idle is that the block lived entirely inside a
  hook process (the hook log spans the interval) while the session transcript shows no
  assistant activity across it.
- **No human action** — between arming and the arrival, the operator issues no input, clicks
  nothing, and answers no prompt. A host permission prompt for the woken turn's command counts
  as human action and invalidates the run for the pass criterion (see § Test Method, "What
  invalidates a run").
- **Acts on it** — the woken turn performs one externally observable act: it runs
  `<python> <spike-dir>/spike_hook.py --act <run> --url <stub-url>`, which issues
  `GET /wait?after=0&text=ACT-<run>&run=<run>`. **`run` is mandatory on every request**, here
  as everywhere — it has no default (see the endpoint contract above), and every log line from
  every process carries it, which is what makes a run's lines separable from a neighbour's.
  The stub's request log records it with a timestamp, so "it acted" is a line in a file rather
  than an impression of a transcript. The transcript is kept as corroboration, not as the
  primary witness.

###### Arrangement CC — Claude Code

1. The operator registers a `Stop` hook whose command is an absolute interpreter path plus an
   absolute path to `spike_hook.py --host claude` (host configuration, never the repository's
   — see § Layers & Components).
2. The operator gives the session one trivial prompt and stops touching the machine. The turn
   ends; `Stop` fires; the hook process starts and the session is idle by the definition above.
3. The hook checks the `stop_hook_active` guard the host provides and exits `0` immediately,
   without blocking, when it is set — omitting this guard loops the session forever
   (REQUIREMENTS §2, prior art 2). **How that flag is carried to the hook is read from the
   host's own hook contract at execution time and copied into the record's apparatus block**,
   for the same reason Cursor's payload schema is (below): the Knowledge Base holds no citable
   Claude Code harness document, so a transport asserted here would be a guess. The hook also
   exits immediately when this run's `<run>.armed` sentinel is already consumed, so a run arms
   exactly once and a repeat cannot pollute the next measurement.
4. The hook issues `GET /wait?after=<N>&run=<run>` against the stub and blocks.
5. At `t0+N` the stub responds. The hook emits the continuation payload that makes the session
   take a further turn, carrying the instruction to perform the act.
6. The act reaches the stub. Test 1's answer is the presence or absence of that line, plus the
   idle and no-human-action evidence.

**Arrangement CC is the constructible one, not the one §8 describes.** §8's Claude Code row
rests on a long-lived monitor streaming events into the session; the spike has no such server,
and a stub that grew one would stop being a stub. The blocking `Stop` hook is the route this
work has already written down (§2, prior art 2) and is what CC tests. If it fails, the second
attempt is §8's streamed-event path, and if that proves unconstructible against a stub, *that
is the recorded answer* — AC-20 admits "could not determine" precisely here, provided the
record says what was tried. Which arrangement produced the answer is a required field of the
record.

###### Arrangement CU — Cursor

Identical in shape, with three differences that come from the host:

1. The hook is Cursor's **`stop`** hook, which fires when the agent loop ends and can submit
   the next user message (`https://cursor.com/docs/hooks`, catalogued in
   `.aid/knowledge/external-sources.md`).
2. The continuation payload is Cursor's, not Claude Code's. **The exact field names are read
   from that vendor page at execution time and copied verbatim into the record's apparatus
   block.** They are not stated here: the Knowledge Base registry records the hook's semantics
   and not its payload schema, and a schema guessed in a specification is a defect that
   surfaces as a mysterious test failure.
3. Cursor is the host under measurement in test 3, so the same hook binary carries the
   block-limit instrumentation.

##### Layers & Components

There are **three files**, and the count is itself a design decision — a spike with a module
layout is a spike someone will promote.

| Artifact | Role |
|---|---|
| `spike_stub_node.py` | The one endpoint above. `--port` (default `8811` — see § External Integrations for why not 8787 or 8799), `--bind` (default `127.0.0.1`), `--max-wait`, `--log` (default `throwaway/logs/stub-<port>.ndjson`; § Telemetry) |
| `spike_hook.py` | Both hooks and the act. `--host claude` or `--host cursor`, `--url`, `--after`, `--deadline`, `--run`, `--log` (default `throwaway/logs/<run>.ndjson`; § Telemetry); `--act <run>` performs the woken turn's single request. Arms once per run via a `<run>.armed` sentinel beside it |
| `spike_probe.py` | External observer. `--run` (required — which run to watch), `--log` (default `throwaway/logs/<run>.ndjson` — the same file the hook resolves for that run; see § Telemetry), `--interval-ms` (default `250`). Reads the run log until it sees that run's `proc: hook` / `event: start` line, takes the `pid` from it (the schema in § Telemetry names that line as where the probe learns it), then samples that pid's liveness every `--interval-ms` and appends `probe` events to the same log. Exits when the pid dies or the run ends. It exists only to tell *killed* from *abandoned* (§ Test Method) |

###### Where they live, and why that location is the disposability mechanism

All three live in **`.aid/works/work-001-agent-chat/throwaway/`** — a new directory, created by
this feature and deleted by it. (Re-homed on 2026-09-01: the path was under a per-feature folder,
and features are now sections of this document rather than folders, so there is no per-feature
directory to nest it in. Nothing about the disposability argument below depends on the depth.)

Three independent things make promotion hard, which is what "disposable by construction" has
to mean if it is to mean anything:

- **The repository rule.** `CLAUDE.md` states that work folders are transient and that **no
  permanent artifact may depend on the contents of a specific work folder.** A P1 task that
  imported from this path would break a standing rule, visibly, in review — not merely be in
  poor taste.
- **The disk.** The work folder is pruned when the work ships, so the code stops existing
  without anyone deciding to delete it.
- **Git.** Untracked-by-accident is not a guarantee, so this feature adds **one
  line** to `.gitignore` for the `throwaway/` directory, in the existing
  "Transient pipeline work folders -- kept LOCAL only, never committed" block that already
  carries `.aid/works/work-023-ticket-integration/` and
  `.aid/works/work-004-optimize-skill-library/`. That line is removed when the work ships. It
  is a rule *about* a work folder rather than a dependency *on* one, which is why it does not
  offend the transience rule — and the precedent for it is already in the file.

The `spike_` prefix on every filename is chosen so the no-carry-forward check is a search
rather than a judgement (§ Recording the Answers).

###### Where they must not live, and the concrete mechanism each would trip

| Location | What would happen |
|---|---|
| `tests/canonical/` | `tests/run-all.sh` discovers suites by the glob `tests/canonical/test-*.sh` and runs each under `timeout 300` (`tests/run-all.sh`:8,:93). A spike script there is auto-enrolled into CI merely by existing, and the block-limit run needs longer than 300 s — it would red master while measuring nothing |
| `canonical/` | Rendered into `profiles/` by `run_generator.py` and guarded by the render-drift gate; the spike would ship to every adopter |
| `dashboard/` | The file set is derived from `dashboard/MANIFEST` by five consumers and gated by `tests/canonical/test-dashboard-manifest.sh` |
| `packages/npm/`, `packages/pypi/` | Both declare empty dependency sets on purpose (decision D10, FR-7.6); anything here is distribution |

###### Language, runtime, and conformance

**Python, standard library only, `3.9+`**, and the actual interpreter version on each machine is
recorded. Stdlib-only
means nothing to install on the second machine. Not shell, because both hooks must run unchanged
on Windows and on the LAN peer, and because the measurement needs a monotonic clock and — on
POSIX, where one can be installed — a signal handler inside the process being timed.

> **The spike stays Python, and stays deliberately unaligned with the product's runtime.**
> This paragraph originally stated `3.9+` while taking **no** position on either the repository
> floor or the node's 3.12 — a spike that pinned either would be a spike with an opinion about
> P1. On 2026-08-10 both anchors disappeared: the repository-floor feature was withdrawn and the
> node moved to Node (REQUIREMENTS §8 Toolchain). **The `3.9+` here is unaffected, because it
> never derived from either.** It is a floor this spike sets for itself.
>
> **Why not follow the product to Node.** What the spike measures is a *host* property — whether
> a tool can hold a token-free wait and turn an arriving message into a turn, and how long a
> blocking hook survives before the host kills it. That is runtime-independent: no finding of
> this feature changes with the language. What the choice does affect is the assumption imposed
> on the two machines the spike runs across, and there Python is the **weaker** assumption, being
> present by default on more Linux and macOS installations than Node is — which is precisely why
> stdlib-only was chosen in the first place. Add that the code is deleted when the spike closes,
> and alignment with P1 buys nothing while a rewrite of three files risks a defect in the one
> stage whose output is a measurement.
>
> **This is recorded rather than left implicit** because a reader arriving after the runtime
> reset would otherwise reasonably expect Node here, and reasonably suspect the Python below of
> being an oversight. It is a decision.

The three files follow `.aid/knowledge/coding-standards.md` § Python Conventions —
`#!/usr/bin/env python3`, a header block stating Purpose / Usage / Exit codes (§ File Header
Convention), `from __future__ import annotations`, type hints, `argparse` inside
`main() -> int` with `sys.exit(main())`, results on stdout and diagnostics on stderr. Exit
codes reuse the documented scheme (§ Exit Codes): `0` success, `1` runtime failure, `2` usage
or argument error, `3` for a bind or connection failure, whose semantics match the existing
network/fetch code. Each header additionally opens with the line
`THROWAWAY - work-001 stage P0. Deleted when the spike closes. Do not import, copy, or
promote.`

###### Host configuration is the operator's, and never this repository's

Each host session for the spike runs in **a scratch project directory outside the AID
repository**, and its hook is registered in that scratch project's own host configuration or in
the operator's user-scope configuration. The repository's `.claude/settings.json` is **tracked**
(verified with `git ls-files`) and the repository's `.claude/` tree is written only by the
install path — a spike that edited it would both pollute the dogfood tree and put a hook into
every AID contributor's checkout. If a project-scope file is used at all it is the git-ignored
`.claude/settings.local.json` (`.gitignore`:55). This is **required by FR-0.4, not merely aligned with it** — and that changed on
2026-08-10. FR-0.4 previously said AID writes and manages no host tool's **MCP**
configuration, and this paragraph reasoned from that narrow wording: a hook is not MCP
configuration, so the requirement did not govern the spike, which then followed its spirit *by
choice*. **The restated FR-0.4 is broader** — "the product writes no host tool's configuration",
with MCP named only as one instance — so it now governs the spike's hook directly. **The
practice below is unchanged and already complies**; what changes is that compliance is no longer
optional, and a future spike edit that reached into a tracked host-config file would be a
requirement violation rather than a lapse of taste.

##### Test Method / Measurement Protocol

###### Common apparatus and run discipline

- **A run is identified** by `<test>-<parameter>-<repeat>`, e.g. `T3-060-b`, and that id
  appears on every log line the run produces, in both processes and on both machines.
- **Clocks.** Elapsed times come from `time.monotonic()`; wall-clock ISO-8601 UTC is logged
  alongside it only for correlating the two machines and the host's own logs. No elapsed figure
  is ever computed from wall clock.
- **Before each run:** the stub is restarted, machine sleep and display-sleep are disabled, no
  other hook is registered, and the woken turn's command is pre-approved in the host's
  permission settings.
- **During each run:** the operator does not touch either machine. The no-touch window is
  recorded with its start and end.
- **After each run:** the operator records the outcome and the log excerpt immediately. A run
  reconstructed from memory later is not evidence.

###### What invalidates a run

Any of the following voids the run, which is re-executed rather than interpreted: the operator
interacted with the session; the host raised a permission prompt; the machine slept; the stub
restarted or returned early; the hook's own log shows a gap larger than 2 s between heartbeats
without a matching probe observation. Void runs are logged with their reason — the count of
void runs and why is part of the record, because a test that can only be run four times in ten
attempts is itself a finding.

###### Test 1 — an idle Claude Code session (AC-20 question 1)

Arrangement CC with `--after 60`. **Pass** when all four hold: the act appears in the stub's
request log; it appears after the arrival; the transcript shows no assistant activity between
arming and arrival; and the no-touch window covers the whole interval. **Fail** when the
arrival is served and no act follows within 120 s. Three runs; the answer is the majority with
all three outcomes recorded, and a 2–1 split is reported as intermittent rather than smoothed
into a pass.

###### Test 2 — an idle Cursor session (AC-20 question 2)

Arrangement CU, `--after 60`, otherwise identical to test 1. Test 2 is only meaningful for a
block that Cursor tolerates, so it runs at `after=60` first and, if the hook is killed before
the arrival, is re-run at a duration test 3 has shown to survive. Ordering note: test 3 may
therefore have to run before test 2 completes, and the record states the order actually used.

###### Test 3 — the number (AC-20 question 3)

This is the deliverable that is a measurement, so its procedure is stated to the point of
tedium.

**What is being measured.** Not "how long the process lives" but **how long a `stop` hook may
block and still have its continuation honoured** — the usable blocking budget. A hook that
survives 300 s and whose submitted message Cursor then ignores is worth exactly as much as one
that was killed at 5 s, and a protocol that only watched the pid would score the first as a
success.

**Apparatus.** The hook blocks on a real socket read, not on `sleep`: it issues
`GET /wait?after=<D+30>&run=<run>` against the stub on **loopback** and applies its own client deadline
of `D`. So the stub can never return first, the block is a genuine network wait (some hosts
time out on silence rather than on runtime, and `sleep` would not exercise that), and a hook
that is left alone returns under its own power at exactly `D`. Loopback is deliberate: test 3
measures the host, not the network. The hook is invoked as an absolute interpreter path plus an
absolute script path, with **no shell wrapper**, so the process the host spawns is the process
being measured — a wrapper would leave the interpreter as an orphaned grandchild and make
"still alive" unreadable.

**Instrumentation.** The hook writes `start` (with its pid and `D`), then a `beat` every
250 ms, then one terminal line. On POSIX it installs handlers for SIGTERM, SIGINT and SIGHUP
that write `killed` with the elapsed time and the signal number, giving the kill instant
exactly. **On Windows there is no such signal** — a terminated process gets no chance to
write — so the last `beat` bounds the kill to within 250 ms, and the reported number carries
that resolution explicitly. `spike_probe.py` samples the pid on the same 250 ms cadence from
outside, which is what distinguishes a dead process from a live but ignored one. Each log line
is flushed to the OS on write; `fsync` is not used, because a process kill does not lose data
already handed to the kernel and 2,400 syncs would perturb the thing being timed.

**The three outcomes, defined before any data is collected.**

- **SURVIVED(D)** — the hook returned on its own at `D`, *and* the act reached the stub. Both
  halves are required.
- **KILLED(t)** — the heartbeat stopped at `t < D` and the probe confirms the pid gone. `t` is
  exact on POSIX and `±0.25 s` on Windows.
- **ABANDONED(D)** — the probe shows the process alive through `D` and the hook returned, but no
  act follows within 120 s: Cursor stopped waiting and moved on without honouring the
  continuation.

The usable budget is bounded by whichever of KILLED and ABANDONED appears first, and the record
names which mode was observed. Treating them as one number would hide the more interesting
failure.

**Phase 0 — the prior.** Re-read `https://cursor.com/docs/hooks` and record whatever timeout it
states, including "none stated", together with the Cursor version. A documented number is not a
measured one; the measurement is performed regardless, and a disagreement between the two is a
finding recorded in both directions.

**Phase 1 — ladder.** One run each at `D` = 5, 15, 30, 60, 120, 300, 600 s, ascending. Stop at
the first non-SURVIVED outcome. This yields `S` (largest survived) and `F` (smallest failed).
If 600 s survives, stop the ladder and go straight to phase 3, confirming at the 600 s ceiling,
for the answer **"≥ 600 s, no limit observed"** — that is a complete answer for the design's
purposes, since §6's long-poll default
is 30 s, and chasing an upper bound past 600 s spends hours to change no decision. Record the
ceiling that was probed, so "≥ 600 s" is never mistaken for "unbounded".

**The degenerate case has to be handled, because it is the one that changes the architecture.**
If the lowest rung fails, there is no `S` to bisect from, so the ladder continues *downward* at
2 s and 1 s. If 1 s also fails, the recorded answer is **"the `stop` hook may not block at
all"** — with the terminal mode and the observed `t` — and the consequence is stated rather than
softened: Cursor has no viable waker adapter and degrades to the FR-5.3 pull floor, which is
FR-5.2's stated fallback and is exactly the outcome §10's rationale says this stage exists to
discover before P1.

**Phase 2 — bisection.** Probe `D = round((S+F)/2)`, one run, and replace `S` or `F` by the
outcome. Repeat until `F - S ≤ max(5 s, 0.10 × F)`. From a `[300, 600]` bracket this is three
to four runs.

**Phase 3 — confirmation.** Three runs at `S` and three at `F`. (Where phase 1 reached the
ceiling, `S` is 600 s and there is no `F`; the three ceiling runs are the whole of phase 3.)
The result is accepted only
when `S` survives 3 of 3 and `F` fails 3 of 3. Any mixed endpoint means the limit is **not
deterministic**, which is reported as such — the bracket, plus the per-endpoint outcome counts
— rather than averaged into a number the design would then trust. Three repetitions and not
thirty because the number feeds a timeout choice with a safety margin, not a statistical claim:
what the design needs is a conservative floor and an order of magnitude.

**Stopping rule.** The measurement ends at the first of: phase 3 confirms — at a bisected `S`,
at the 600 s ceiling, or at the "may not block at all" floor; or the budget of **25 runs or
4 hours of wall clock** is exhausted. In the last case
the record states the bracket reached, every run performed, and why it stopped — which is
exactly the shape AC-20 requires of a "could not determine".

**Reported form.** Largest duration surviving 3 of 3; smallest failing 3 of 3; the bracket;
terminal mode (killed, abandoned, or both); signal or "none observable (Windows)"; resolution;
run count including void runs; Cursor version; OS and version; network (loopback).

**What the number is for, stated but not acted on here.** §6 defaults the long-poll timeout to
30 s. If `S` lands near or below 60 s, that default is challenged, and if it lands in the
hundreds of seconds it is comfortably safe. Recording the implication is in scope; changing
the requirement is not — **that belongs to Feature 003 (The Wake)**, which owns both the
subscription and the per-host adapters, and whose own note already says it is shaped by this
number.

###### Test 4 — two machines on the LAN (AC-20 question 4)

Machine **A** runs the stub bound to `0.0.0.0` — so the local waiter reaches it on loopback and
machine B reaches it on the LAN address, from one process — and hosts the **Claude Code**
session. Machine **B** hosts the **Cursor** session, whose hook holds its block across
the network. This is the shape of the target case in REQUIREMENTS §3 — Cursor on one machine,
Claude Code on another — and it puts the LAN hop under the host with the weaker route, where a
router, NIC or OS idle-connection timeout would bite first.

Procedure: arm both sessions; each calls `GET /wait?after=<N>&run=<run>` with an `N` chosen so
both are armed before the arrival; at `t0+N` both are released by the same stub. Each woken turn
performs its act, and machine B's act crosses the LAN back to the stub.

**Pass** when the stub's request log holds, in order, both waits, the single arrival, and both
acts, with machine B's act arriving from B's address. The log is one file on one machine, so the
ordering is unambiguous and no clock synchronisation between the machines is required — the
reason the stub, and not the sessions, holds the authoritative log.

Test 4 also carries **one confirmation run at `S`** over the LAN. If the block that survived on
loopback does not survive across the network, the usable budget over LAN is smaller than the
number test 3 produced, and both figures are recorded.

**What test 4 does not prove, stated plainly.** It proves that a message crossing the LAN wakes
a session on the far machine and that the woken turn can reach the other machine's service. It
does **not** prove node-to-node federation, peer discovery, or store-and-forward — those are
FR-6 and Feature 004 at stage P3, and no line of this spike touches them.

##### External Integrations

The only integration is the LAN hop in test 4, and it is deliberately as thin as it can be.

| Concern | Decision |
|---|---|
| Transport | Plain HTTP/1.1 over TCP. No TLS: REQUIREMENTS §4 has no authentication anywhere in the product and §8 makes the network the security boundary; adding TLS here would test a property the product does not have |
| Bind | `127.0.0.1` by default; `0.0.0.0` **only** for test 4, and only for as long as that test runs |
| Port | `--port`, **default `8811`**, recorded in the apparatus. **AID does have a fixed port to avoid: `8787`**, the dashboard default in `bin/aid` and `bin/aid.ps1`. `8799` is also excluded — `.aid/knowledge/infrastructure.md` documents the maintainer's own local command as `aid dashboard start node --port 8799`, on the very machine this spike runs on, and it is used by the UI test harness besides; a stub that silently squats it would surface as a mysterious dashboard outage rather than as a spike error. `8811` collides with neither, nor with any other port this repository names. The stub **fails loudly on a bound port** — **exit `3`**, the documented code for a bind or connection failure (§ Exit Codes), with the port in the message — rather than falling back to another, so a collision is a stopped run, not a run measured against somebody else's server. The operator confirms the port is free on both machines and records it |
| Firewall | An inbound rule on machine A for that port, added for the test and removed after. Whether one was required is recorded — on Windows it usually is, and a reader repeating this will otherwise lose an hour to a silent block |
| Discovery | None. Machine A's address is passed to machine B on the command line. Discovery is FR-6.1 and stage P3 — and FR-6.1 is stated as an **outcome**, not as mDNS, since 2026-08-10; the spike's hand-passed address is therefore not a stand-in for any particular mechanism |
| Precedent guarded | The shipped dashboard server binds `127.0.0.1` and its `--remote` flag is a clear-fail stub (`.aid/knowledge/tech-debt.md` § Security Observations). The stub's non-loopback bind sets **no** precedent for the node: Feature 003 decides the node's bind policy on its own evidence |

##### Telemetry & Tracking

The measurement is only as good as its log, so the log has a schema.

**One append-only NDJSON file per run**, written by both `spike_hook.py` and `spike_probe.py`,
plus one per stub process. One JSON object per line, flushed on write.

**Where it lives, and what it is called.** All three scripts resolve `--log` the same way, and
the convention is stated here once because three flags defaulting to "the same file" is
meaningless unless something computes it:

```
throwaway/logs/<run>.ndjson       # per-run log: spike_hook.py and spike_probe.py
throwaway/logs/stub-<port>.ndjson # per-stub-process log: spike_stub_node.py
```

relative to the `throwaway/` directory named under § Layers & Components, with `logs/` created
on first write. `<run>` is the run id already carried on every line. So `--log` on
`spike_hook.py` and `spike_probe.py` defaults to `throwaway/logs/<run>.ndjson` for the `--run`
they were given — which is what makes the probe and the hook meet in the same file without the
operator having to pass matching paths to both. `--log` remains available on all three to
override it; nothing in the protocol depends on the override.

| Field | Meaning |
|---|---|
| `ts_wall` | ISO-8601 UTC, for cross-machine and cross-tool correlation only |
| `t_mono` | Seconds since that process's start, from `time.monotonic()` — the only field elapsed figures are computed from |
| `run` | The run id, on every line from every process |
| `proc` | `stub`, `hook`, or `probe` |
| `machine` | `A` or `B` |
| `pid` | The writing process's pid; the hook's `start` line is where the probe learns it |
| `event` | `start`, `beat`, `request`, `respond`, `act`, `end`, `killed`, `abandoned`, `probe`, `void`, `error` |
| `d` | The run's target block duration, on hook lines |
| `seq` | The stub's per-process request counter, on `request` and `respond` lines only. It is what makes two events inside the same millisecond orderable, and what makes a restarted stub visible — the counter goes backwards instead of the log showing a silent gap |
| `alive` | Boolean, on `probe` lines only |
| `signal` | Signal number, on `killed` lines from POSIX only |
| `note` | Free text; carries the void reason on `void` lines |

**Nothing else is instrumented.** No metrics endpoint, no aggregation, no summary file — the
answer record is written by hand from these logs, and a tool that summarised them would be a
tool worth keeping, which is the failure mode this stage is guarding against.

##### Recording the Answers

**The record is the deliverable** (§10: "Its only deliverable is the answers"). It is written
to
**`.aid/works/work-001-agent-chat/FINDINGS.md`** — at the work root, outside `throwaway/`, so
that deleting the code does not delete the result. (Re-homed on 2026-09-01 with the `throwaway/`
directory above, for the same reason: features are sections of this document now, not folders.)

Its shape:

1. **Apparatus block** — for each host: tool and version, OS and version, machine role, Python
   version, the hook configuration file actually used, the continuation payload schema copied
   verbatim from the vendor page, the stub's port and bind, and whether a firewall rule was
   needed. This block is why a later reader can tell whether the answer still applies after a
   host update.
2. **The four answers, one row each:** question, verdict (`Pass`, `Fail`, or `Inconclusive`),
   the answer itself, runs performed (including void runs), the log excerpt that evidences it,
   and the date. Question 3's answer is the reported form specified in test 3 — a number with a
   bracket, a terminal mode, and a resolution, never a bare figure.
3. **A "what was tried" paragraph, mandatory for every `Inconclusive` row** — the arrangements
   attempted, the outcome of each, and why the question could not be closed. AC-20 admits
   "we could not determine it" **only** in this form, so a row is not complete without it. An
   empty paragraph is a failed criterion, not a formatting lapse.
4. **Order of execution**, since test 2 may depend on test 3's result (see test 2).
5. **The implication for the design**, recorded and not acted upon: what the measured budget
   means for the §6 long-poll default, addressed to Feature 003 (The Wake).

###### Disposal and the no-carry-forward check

When the four answers are transcribed and the record is complete, `throwaway/` is deleted and
the `.gitignore` line goes with it. The feature's last acceptance criterion — no code carried
forward — is then checked three ways, because the obvious check is vacuous:

- **`git ls-files` proves nothing here** and must not be cited as if it did: the work folder is
  untracked, so a path-based search over tracked files returns empty whether or not the spike
  ever existed. Stating this is part of the check.
- **The directory is absent from disk** at the moment P1's first task starts.
- **The names are absent from the repository.** A search of tracked files for `spike_stub_node`,
  `spike_hook`, and `spike_probe` returns nothing. This one is not vacuous — it is what catches
  a file copy-pasted into `canonical/`, `dashboard/` or `tests/`, which is the realistic way P0
  code survives.
- **No P1 task cites the path.** No task DETAIL under this work references `throwaway/`. This
  catches promotion by reference, which the name search would miss.

###### Promotion to the Knowledge Base (stakeholder decision Q22)

AC-20 requires the answers to be written down and does not say where they live **after** this
work ships. `FINDINGS.md` satisfies the criterion and serves every consumer inside this work,
but the work folder is prunable by rule — and the measured Cursor number is a durable fact
about a third-party harness, not pipeline state. Feature 003's adapter design turns on it,
and re-measuring costs hours.

**Decided: the results are promoted to `.aid/knowledge/external-sources.md` when the spike
completes.** That document already draws the first-hand-versus-cited distinction for these
exact hosts, so the entries land beside the claims they settle:

| Promoted | Recorded as |
|---|---|
| The Cursor `stop`-hook blocking limit | First-hand measurement: the number, its confidence bound, the method in one sentence, the host version, the OS, and the date |
| Whether an idle Claude Code session acts with no human action | First-hand result. That document has **no Claude Code row** — deliberately: its § Host agent-tool documentation preamble explains that Claude Code's harness is exposed at runtime rather than published, and instructs the reader to "treat any Claude Code harness claim as unsourced until a published reference exists". The spike produces the project's first **measured** claim about it, so the promotion amends that preamble rather than filling a table row, and the distinction it draws — first-hand versus citable — is preserved, not erased |
| Whether the exchange held across the LAN | One line, with the arrangement tested |

The **full run record stays in `FINDINGS.md`** and is pruned with the folder. What is promoted
is the conclusion and enough method to trust or re-derive it — not the raw ladder.

**One hard constraint on the KB entry.** It states the measurement and its method **only**:
no work id and no work-folder path — in prose, table or frontmatter. "Measured by the P0
spike of work-NNN" is exactly the shape to avoid; "measured 2026-09-01 against Cursor
x.y, method as below" is the shape to use.
The project's context file forbids naming a work in the Knowledge Base, for the exact reason
that applies here: the folder this measurement came from will not exist, so a citation to it
is a dangling pointer by design. Cite the host, the version and the date instead.

The promotion happens at execute time, when the numbers exist. This specification records the
obligation; it does not pre-write the entry.

##### BDD Scenarios

> **Provenance.** The scenarios below are not `/aid-specify` output. They were authored
> during requirements work under a retired schema that held feature-level acceptance
> criteria; §9 is now the only place a criterion is stated, so these are verification
> detail and an input to `/aid-specify`. Several cover a claimed FR clause that no §9
> criterion reaches on its own, which is why they were kept rather than deleted.

- [ ] Given an idle Claude Code session with the stub armed, when a message is sent, then
      the session acts on it with no human action — recorded as pass or fail.
- [ ] Given an idle Cursor session with a blocking `stop` hook, when a message is sent,
      then the session acts on it with no human action — recorded as pass or fail.
- [ ] Given a Cursor `stop` hook that blocks indefinitely, when the host terminates it,
      then **the elapsed time is recorded as a number**.
- [ ] Given the two sessions on different machines on the same network, when a message is
      sent, then the exchange is recorded as pass or fail.
- [ ] Given any test that could not be completed, when the spike closes, then the record
      states what was attempted and why it was inconclusive — silence is not an outcome.
- [ ] Given the spike is complete, when P1 begins, then **no code from this feature has
      been carried forward**.

### Feature 002 — Node and Message Plane

- **Priority:** Must
- **Requirements:** §5 FR-0.1, FR-0.3 *(the administration and message-plane halves — the
  subscriber half completes in Feature 003)*, FR-1.1–1.3, FR-2.1, FR-2.2 *(the single-machine
  half: the id's shape)*, FR-2.3 *(liveness tracking and stale-marking — reaping belongs to
  Feature 005)*, FR-3.1 *(local half)*, FR-3.4, FR-4.1–4.7 *(the plain-delivery envelope —
  FR-4.1's `mention?` / `whisper_to?` fields and FR-4.3's whisper filtering belong to Feature
  005)*, FR-5.3, FR-7.2 *(start / stop / status / configuration, chat lifecycle, and any change
  to another session's membership — retention policy belongs to Feature 005)*, FR-7.4 *(the
  **no-client-library** clause — see the ownership note below)*, FR-7.5, FR-7.6, FR-7.7;
  §6 Delivery semantics *(durability, delivery guarantee, progress tracking, ordering)*;
  §6 Limits *(the **stale-session threshold**)*; §7 Constraints; §10 stage P1
- **Criteria:** AC-3, AC-6, AC-7, AC-8, AC-9, AC-10, AC-13, AC-21, AC-22  ← ids from §9; never restated here

> **Specify this feature first.** It is the keystone: the process model, the CLI surface, the
> store schema and the one core all live here, and every later feature builds on them.
>
> **Why this is one feature and not three.** An earlier decomposition split it into node
> lifecycle, session registration and durable messaging, and the split failed on its own terms:
> the lifecycle feature owned the store schema the messaging feature needed, so a schema defect
> in the first blocked the second outright, and the plan had to record one feature as NO-GO until
> the other was fixed. Lifecycle, registration, chats and messaging all touch **one** store
> schema and **one** core API. They change together, so they are specified together — which
> removes that coupling instead of managing it.
>
> **It is the largest feature here, and that is stated rather than hidden.** Nine of the
> twenty-two criteria. Every candidate split line runs through the store schema, which is what
> went wrong before; if it proves too large to build in one pass, the place to slice it is
> `/aid-plan`, which can stage one feature across deliveries without re-drawing a boundary.
>
> **FR-7.4 ownership — two features, and this is where it is settled.** FR-7.4 has three
> separable clauses. **This feature** owns *the node publishes no client library or SDK*.
> **Feature 003** owns the other two — *the chat skill's instructions are CLI invocations* and
> *the subscriber is a CLI invocation*. Together they keep the HTTP transport internal to the
> node, which is what FR-7.4 asks for.

#### Description

The background service that holds the messages, and the commands that run it.

The node does **one job** — move messages between sessions. It ships no commands of its
own, no installer, and no operator screen. Everything a human does to it is an `aid`
subcommand: start it, ask how it is, stop it. There is nothing to *put there* — the node
ships inside the `aid` payload, so the CLI starts what it already carries.

Once running it is independent of every session. Sessions come and go; the node stays — it
outlives the window that started it. (Whether it also restarts itself after a machine
reboot is **not** specified: no requirement asks for it, and nothing here tests it.)

The node **ships inside the `aid` payload and carries no third-party dependency** (FR-7.6),
so `aid` does contain it: there is nothing to fetch on any channel, air-gapped included, and
a user who never enables chat pays only disk. One consequence follows and is deliberate:
**the node needs a Node runtime, and no host tool guarantees which version is on PATH**
(FR-7.7, §8). So chat states Node as a prerequisite, checks it before any side effect, and
says so with a clear error rather than a crash. The `aid` CLI itself stays runtime-free —
installing, updating and removing AID needs nothing but a shell.

Beneath the surface there is **one implementation**. The CLI is not a second version of the
node's logic, and the rendered chat skill is not a third — the skill holds no logic at all,
since every operation it describes is an `aid chat` invocation. This matters more than it
sounds: two implementations drift, and the drift shows up as messages that behave
differently depending on which door they came through.

How a session says who it is, and how it gets its place back.

A session registers a **name** — plus which tool it is, where it is working, and what it can
do. The name is an identity, not an address: it is how the session is recognised inside a
chat, mentioned, and whispered to. Nobody sends *to* a name.

Names matter because sessions do not last. They crash, hit their limits, get cleared and
restarted, constantly. If a session's place in its conversations were tied to the window,
every restart would lose it. Tying it to the name instead means restarting and re-claiming
the name puts you back exactly where you were — in every chat you belong to, at the point
you had read up to in each.

A session's full identity is its machine plus its name, matching how chats are addressed.
Names are unique per machine.

The node also tracks whether a session is still alive. One quiet for 30 minutes is marked
**stale** — probably gone — so the operator's view distinguishes "reading slowly" from
"never coming back". Being marked stale changes nothing about what is kept.

Giving a session up **for good** is a later, separate state (reaping, at 24 hours) and
belongs to retention, not registration. This feature observes and reports liveness; it
never releases anything.

The chat, and everything you do with one.

**A chat is the only thing a message is addressed to.** There is no send-to-a-person. The
smallest chat has two members, and that *is* a private conversation — the same mechanism,
not a special case. One idea instead of two.

You create and delete chats through the CLI; a session only joins and leaves for itself, and
joining one that does not exist fails rather than quietly creating it. Chat lifecycle lives
here rather than with node administration because it is the thing every other criterion in
this feature depends on — there is nothing to send to until a chat exists.

A chat may have any number of members. Two is the minimum and the proving case, but a
message fans out to **every** member from the start; larger chats need nothing new here.
What they add later is a way to address *within* them. A session can also list the
chats on this machine and the ones it belongs to — without that, there would be no way to
learn a chat's name in order to join it.

Each chat keeps a **durable log**, and each member keeps **their own place** in it. Being
away delays messages; it does not lose them — right up until the node gives that member up
for gone and reaps it, which is retention's job and is covered in Feature 005. Within that
window, being away costs nothing. A message may arrive twice, so each carries an
identifier that lets a recipient spot the repeat. Within one chat everyone sees the same
order.

Nothing here blocks. A reply is just another message sent back, matched to what it answers
by a shared identifier. No session ever waits on another — two turn-based agents cannot
safely be put on the same clock.

This stage is **pull only**: a session reads its own mail when it takes a turn. That path
must work on its own, because it is the floor every host falls back to.

#### User Stories

- As the operator, I want one command to stand the node up on a clean machine, so that
  setting up a new machine is not a procedure.
- As the operator, I want to run that command again without fear, so that I never have to
  remember whether I already did.
- As the operator, I want to see whether the node is running and stop it, so that I am not
  guessing at a background process.
- As a session, I want the node to already be there, so that my ability to send a message
  does not depend on which window opened first.
- As a session, I want to claim a stable name, so that others can recognise me across
  restarts.
- As a session that just restarted, I want to re-claim my name and find my unread messages
  waiting, so that a crash costs me nothing.
- As a session in several chats, I want each chat to remember separately how far I have
  read, so that catching up in one does not skip messages in another.
- As the operator, I want sessions that have gone quiet to be marked as such, so that I can
  tell a slow reader from a dead one.
- As the operator, I want to create a chat and add sessions to it, so that they have
  somewhere to talk.
- As the operator, I want to delete a chat I no longer need, so that the list stays
  meaningful.
- As a session, I want to list the chats here and join one by name, so that I can take part
  without being told an address out of band.
- As a session, I want to read messages that arrived while I was away, so that being busy
  costs me nothing.
- As a session, I want to mark how far I have read, so that I do not re-read the same
  messages.
- As a session, I want to spot a repeated message, so that acting twice on one instruction
  cannot happen.
- As a session, I want to send a reply that is recognisably an answer, so that a request
  and its response can be matched without either side waiting.

#### Technical Specification

> **Not yet specified.** `/aid-specify` has not run on this feature.
>
> A specification for part of it existed and is **deliberately not carried forward** — it was
> written before the runtime decision and rested on premises that decision contradicts (a
> separate distributable, a Python prerequisite, an install step), and it never passed review.
> `git log --follow` on this document recovers it if ever needed.
>
> **Two findings from that specification's review are carried forward as constraints, because
> they are defects a re-specification would otherwise walk straight back into:**
>
> 1. **Exit code `5` is already taken.** The earlier specification allocated it while dismissing
>    the table that records the existing use as non-authoritative — the second time that same
>    reasoning produced a collision. Whatever codes this feature allocates must be checked
>    against every existing use, not against a list believed to be complete.
> 2. **`id INTEGER PRIMARY KEY` without `AUTOINCREMENT` is a rowid alias**, so SQLite **reuses a
>    reaped member's id**. A later member then silently inherits every message its predecessor
>    sent — a correctness defect with no error and no symptom until someone reads the wrong mail.
>    Verified to behave this way on the built-in SQLite module. Reaping is Feature 005's, but the
>    schema that makes it safe is this feature's.

##### BDD Scenarios

> **Provenance.** The scenarios below are not `/aid-specify` output. They were authored
> during requirements work under a retired schema that held feature-level acceptance
> criteria; §9 is now the only place a criterion is stated, so these are verification
> detail and an input to `/aid-specify`. Several cover a claimed FR clause that no §9
> criterion reaches on its own, which is why they were kept rather than deleted.

*From Node Service Lifecycle:*

- [ ] Given a machine where `aid` is installed and the node has never run, when the operator
      starts it, then it runs — with nothing fetched, resolved, verified or installed first.
- [ ] Given a machine with `aid` installed and no usable Node runtime on PATH, when the
      operator starts the node, then it fails with an explicit message naming Node as the
      prerequisite — not a stack trace — and every `aid` command that needs no runtime
      still works.
- [ ] Given a Node runtime below 24.15.0, where the built-in SQLite module warns on every
      open, when the operator starts the node, then stderr carries **no**
      `ExperimentalWarning` — and, when an unrelated experimental warning is raised, that one
      still reaches the operator. Suppression is scoped to the one known message, not to
      warnings as a class.
- [ ] Given a node already running, when start runs again, then it does not fail with an
      unhandled error. **Whether it reports plain success or a distinct already-running
      code is FR-1.1's open sub-decision**, so this scenario deliberately fixes only the
      part that holds whichever way that is settled.
- [ ] Given a running node, when the operator asks for status, then its state is reported.
- [ ] Given a running node, when the operator stops it, then it stops.
- [ ] Given a running node, when the session that started it exits, then the node keeps
      running.
- [ ] Given the node's shipped files, when they are inspected, then they carry no
      operator-facing command of their own.
- [ ] Given `aid`'s own package manifests, when their dependency lists are read after this
      work ships, then they are **still empty** — and this time because the node has no
      third-party dependency at all, not because its dependencies were kept in a separate
      distributable. FR-7.6 is satisfied literally rather than by a carve-out.
- [ ] Given the node's distribution, when it is inspected, then it offers **no client library
      or SDK** for a caller to bind to. So an in-tool skill written later has nothing to
      reimplement against and invokes the CLI by construction, which is what FR-7.4's first
      clause asks for. (The rendered chat skill Feature 003 adds at stage P2 is instructions
      that call `aid chat`, not a client library — and the separate question of the HTTP
      transport staying internal to the subscriber belongs to Feature 003.)
- [ ] Given the node's implementation, when it is inspected, then message-plane logic lives
      in one core that the CLI calls rather than reimplements — so every face added later,
      the chat skill included, has a single core behind it.

*From Session Registration:*

- [ ] Given a new session, when it registers a name with its tool, working directory and
      capabilities, then it is recognised by that name.
- [ ] Given a name already held, when the same session restarts and re-registers it, then
      it is reattached to every chat it belonged to, at its previous position in each.
- [ ] Given a session that restarted mid-flight, when it reattaches, then messages that
      arrived while it was gone are still waiting.
- [ ] Given a registered session, when its full identity is read, then it is **this machine's
      address plus the name** — so a name is unique per machine, not globally, and the same
      short name registered elsewhere would be a different session. Verified locally: two
      nodes cannot see each other until federation arrives at stage P3, so this is a property
      of the id's shape, not a cross-machine test.
- [ ] Given a session that has sent no heartbeat for the configured interval, when the
      operator lists sessions, then it is shown as stale.
- [ ] Given a session marked stale, when its chats are inspected, then its position is
      still held — being marked stale discards nothing.

*From Durable Chat Messaging:*

- [ ] Given the operator, when a chat is created through the CLI, then a session can join it.
- [ ] Given a chat, when the operator deletes it through the CLI, then it can no longer be
      joined.
- [ ] Given a chat with two members, when one sends a message, then the other can read it.
- [ ] Given a chat with more than two members, when one sends a message, then **every**
      member can read it — fan-out is not limited to the two-member case.
- [ ] Given no subscriber armed, when a message arrives, then it is readable at the
      session's next turn — the pull path works alone.
- [ ] Given two sessions in a two-member chat, when they exchange messages, then it behaves
      as a private conversation, with no mention or whisper involved.
- [ ] Given a message read and acknowledged, when the session reads again, then it is not
      returned a second time.
- [ ] Given the same message delivered twice, when the recipient inspects it, then the
      repeat is identifiable by its identifier.
- [ ] Given a message sent as a reply to an earlier one, when the recipient reads it, then it
      can tell which message it answers — a reply correlates to its originating request.
- [ ] Given a member of a chat, when it leaves through the CLI, then it stops receiving that
      chat's messages and the chat no longer lists it as a member.
- [ ] Given the operator and a chat, when they add **another** session to it through the CLI,
      then that session is a member and receives the chat's messages — the operator can place
      a session, which no session can do for another (AC-15).
- [ ] Given the operator and a chat, when they remove **another** session from it through the
      CLI, then that session stops receiving its messages.
- [ ] Given unacknowledged messages, when the node is restarted, then those messages and
      every member's position survive.
- [ ] Given several messages sent into one chat, when members read them, then all members
      see them in the same order.
- [ ] Given a session, when it tries to join a chat that does not exist, then the attempt
      fails explicitly and no chat is created.
- [ ] Given a session, when it lists chats, then it sees the chats on this machine and the
      ones it belongs to.
- [ ] Given any operation in the message plane, when it is called, then it returns without
      waiting on another session.

### Feature 003 — The Wake

- **Priority:** Must
- **Requirements:** §5 FR-0.2, FR-0.3 *(the subscriber half, completing what Feature 002
  begins)*, FR-0.4, FR-5.1, FR-5.2, FR-5.4, FR-5.5, FR-7.3, FR-7.4 *(the
  **skill-invokes-the-CLI** and **subscriber-is-a-CLI-invocation** clauses — see the ownership
  note under Feature 002)*; §6 Limits *(the **long-poll timeout**)*; §4 In Scope *(the rendered
  chat skill)* and §4 Out of Scope *(the withdrawn MCP façade)*; §7 Constraints *(the
  agent-facing-surface bullet)*; §10 stage P2
- **Criteria:** AC-1, AC-12, AC-15  ← ids from §9; never restated here

> **This is the feature the spike exists for.** Its per-host half is shaped by the number
> Feature 001 measures — how long a Cursor `stop` hook may block before the host kills it — so
> it cannot be specified before that answer exists.
>
> **Three parts, one job: turn an arriving message into a turn.** The node side holds a
> connection open and pushes. The host side is one small adapter per tool, behind a single
> contract — wait without spending anything, and when a message arrives, produce a turn. The
> rendered chat skill is what makes any of it discoverable to a session that would otherwise
> never learn the commands exist. They are one feature because none of them delivers the wake
> alone: a subscriber with no adapter wakes nothing, an adapter with no subscriber has nothing
> to wait on, and either without the skill is a capability no session knows to use.

#### Description

The node side of waking someone: a connection held open, and a message pushed down it the
moment it arrives.

A subscriber opens the connection and leaves it open. Nothing is polled. When a message
lands the node pushes it immediately. Crucially, **the subscriber does not have to hang up
to deliver** — an earlier design assumed it did, which forced a reconnect after every
single message.

Where a host cannot hold a socket open, the same thing is done with a long wait that
reconnects on timeout, by default every 30 seconds. That number is not a delivery delay: a
message arriving two seconds in is delivered two seconds in. It only decides how often an
idle connection recycles.

There is a gap, however small, between one connection closing and the next opening. **The
gap must not lose anything.** Because the chat log is durable and every member keeps their
own place, a message arriving mid-gap is simply read on reconnection, in order, along with
anything else missed. This is the entire reason the durable log exists.

This half is host-independent. It is the node, the connection, and the wire — the same
everywhere. The per-tool half lives in the waker adapters.

The piece that turns an arriving message into a turn — the only part of this product that
differs per tool, and the only part nobody has built before.

**This feature cannot be specified before the spike answers.** Its Cursor half is shaped by
a number the spike measures: how long a `stop` hook may block before the host kills it. That
sequencing is carried by the stage order (P0 before P2) and belongs in the delivery plan;
it is stated here so the dependency is visible to anyone reading this feature alone.

Everything underneath is identical everywhere: the node, the chats, the wire. What differs
is how each tool can be made to notice something. That difference is confined to one small
adapter per tool, behind a single contract: **wait without spending anything, and when a
message arrives, produce a turn.**

The waiting must be free. A shell process sitting on a connection costs nothing; a model
asked to check repeatedly costs money forever. Any adapter that keeps the model in a loop
fails the contract regardless of whether it works.

Two adapters ship. **Claude Code** can hold a long-lived subscription that streams events
into a session, including while it waits on the user. That mechanism is **first-hand, not
cited** — taken from the tool's own runtime capability description rather than from any
published document, so it is absent from the source registry and its **proof is deferred to
the spike** (§8). No host is a proven wake; this is simply the one whose mechanism is
understood in the most detail, which is exactly why
the spike tests it first. **Cursor** cannot be pushed to at all; its only way in is a hook that fires when a
turn ends and can submit the next message. Making that a waker means letting the hook block
until mail arrives, which is why the spike's measured number decides the shape here.

Two paths must both work. **Idle** — a turn is produced on arrival. **Busy** — messages
accumulate and are handed over at the next turn boundary. Neither loses anything; the busy
path only delays.

A host with no viable adapter is not a failure. It falls back to reading its own mail, which
works everywhere. Five hosts are named (§3) and only two get an adapter here; the contract is
what lets the remaining three — and any tool named later — be added without touching anything
else.

The thing that tells a session the chat exists.

**The CLI is not the problem; being found is.** `aid chat` is on PATH globally and carries the
whole message plane, so a session that knows the command can already do everything. Nothing,
however, advertises that command to a model — and a session that does not know it exists will
not guess it. A skill is precisely the artifact that closes that gap, and this repository
already renders one canonical skill into all five host dialects automatically.

So this feature ships **documentation the model can find**, not a second surface. It carries no
logic and holds no state: every operation it describes is an `aid chat` invocation (FR-7.4).
Through it a session can send, read, acknowledge, and manage **its own** chat membership. That
is the entire described surface. Creating or deleting a chat, changing somebody else's
membership, altering configuration, stopping the node — none of it is described here.

**This is a surface boundary, not a cage, and the change of mechanism makes that plainer rather
than weaker.** The full administrative surface lives in the same `aid` CLI, and any session
whose host lets it run shell commands can invoke it directly. When the surface was a protocol,
that honesty read as a caveat about a boundary that looked enforced. Now the boundary simply
*is* a document that omits things, and the limit is visible in its nature rather than needing a
disclaimer. Real containment would need a per-session credential, and this product has no
authentication at all. Claiming otherwise would assert a safety property that does not exist.

**Nothing is asked of the user, and that is a change.** The retired façade required a
copy-pasteable configuration snippet per host, installed by hand — the product published it and
automated nothing, under this repository's standing rule that it manages no host tool's
configuration. A rendered skill needs none of that: it arrives with AID through the same
pipeline as every other skill. The standing rule is now satisfied **by construction** — there is
no host configuration for this feature to leave alone.

**What is given up, stated rather than argued away.** A host that permits tool calls but forbids
shell execution would have been reachable by MCP and is not reachable by a skill. All five named
targets are terminal coding agents for which shell access is constitutive, so the category is
believed empty here — but it is the one real loss, and it is named.

#### User Stories

- As a subscriber, I want the node to push a message as soon as it arrives, so that nothing
  has to poll.
- As a subscriber, I want to stay connected after receiving a message, so that a busy chat
  does not mean constant reconnection.
- As a subscriber on a host that cannot hold a socket, I want a long wait that reconnects,
  so that the same behaviour is available with a simpler transport.
- As a session, I want messages that arrived while I was reconnecting to be delivered next
  time, in order, so that the gap costs latency and not correctness.
- As a developer in Claude Code, I want a message from a colleague's session to reach me
  while I am idle, so that I do not have to check.
- As a developer in Cursor, I want the same, so that the tool I use does not decide whether
  I can be reached.
- As a developer mid-task, I want messages that arrived while I was working handed to me
  when I finish, so that being busy delays them rather than losing them.
- As the operator, I want an idle session to cost nothing while it waits, so that leaving
  sessions open all day is free.
- As a maintainer, I want a new tool to need only a new adapter, so that support does not
  mean redesign.
- As a session, I want to discover that the chat exists without being told by a human, so that
  I use it at all.
- As a session, I want to send and read messages as part of my work, so that messaging is not a
  detour I have to invent.
- As a session, I want to join and leave chats myself, so that I am not waiting on a human for
  something about only me.
- As the operator, I want the agent-facing surface to describe no administrative operation, so
  that the ordinary path does not invite reconfiguring my fleet.
- As the operator, I want the boundary's real limits stated plainly, so that I do not mistake a
  design contract for a sandbox.
- As a user, I want the chat to work on my tool with **no setup step of my own**, so that
  installing AID is the whole of it.

#### Technical Specification

{Added by /aid-specify — do not fill during interview.}

##### BDD Scenarios

> **Provenance.** The scenarios below are not `/aid-specify` output. They were authored
> during requirements work under a retired schema that held feature-level acceptance
> criteria; §9 is now the only place a criterion is stated, so these are verification
> detail and an input to `/aid-specify`. Several cover a claimed FR clause that no §9
> criterion reaches on its own, which is why they were kept rather than deleted.

*From Push Subscription:*

- [ ] Given an armed subscriber, when a message is sent to its chat, then the node pushes
      it without being polled.
- [ ] Given a subscriber that has just received a message, when another arrives, then it is
      delivered over the same connection with no reconnection in between.
- [ ] Given messages arriving while a subscriber is between connections, when it
      reconnects, then **all** of them are delivered, in order.
- [ ] Given an idle subscriber and no traffic, when the configured timeout elapses, then it
      reconnects and remains able to receive.
- [ ] Given a host that cannot hold a socket open, when it subscribes by long wait, then it
      receives the same messages as a socket subscriber.
- [ ] Given the timeout is reconfigured, when a subscriber reconnects, then the new value
      is in effect — the limit is a default, not a constant.
- [ ] Given the subscriber, when it is inspected, then it is **a CLI invocation** rather than
      a separate program speaking HTTP — the transport stays internal to the node, and the
      CLI is what carries the subscriber, completing FR-0.3.

*From Host Waker Adapters:*

- [ ] Given an idle Claude Code session in one repository and an idle Cursor session in
      another **on the same machine**, when one sends a message to their shared chat, then
      the recipient acts on it with no human action.
- [ ] Given an idle session with an adapter armed, when a message arrives, then a turn
      begins without human input.
- [ ] Given a session mid-turn, when a message arrives, then it is delivered at that
      session's next turn boundary.
- [ ] Given several messages arriving while a session is busy, when its turn ends, then all
      are delivered, in order.
- [ ] Given an armed adapter and no traffic, when it waits for an extended period, then no
      model tokens are consumed.
- [ ] Given a host with no adapter, when a message arrives, then the session can still read
      it at its next turn — degraded, not broken.
- [ ] Given both shipped adapters, when their implementations are compared, then they share
      the same node, store and wire protocol, differing only in the adapter.

*From Chat Skill:*

- [ ] Given a session following the chat skill, when it sends, reads, acknowledges, joins and
      leaves, then all succeed.
- [ ] Given a session following the chat skill, when it tries to join a chat that does not
      exist, then the attempt **fails explicitly** and no chat is created — the surface that
      lets a session manage its own membership does not let it create one by implication.
- [ ] Given the chat skill, when it is read, then it **describes no operation** that stops the
      node, changes configuration, creates or deletes a chat, or changes another session's
      membership. This is a check on what the surface *offers*, and is deliberately not phrased
      as "the attempt is unavailable" — the operations remain reachable through the same CLI, as
      FR-7.3 states outright.
- [ ] Given an operation performed by following the skill and the same operation invoked
      directly on the CLI, when both complete, then they produce the same result against the
      same store — because the skill's instructions *are* CLI invocations.
- [ ] Given the chat skill, when it is inspected, then it holds no state and no logic of its
      own, and reimplements no node behaviour (FR-7.4).
- [ ] Given the five supported host dialects, when AID is installed, then the chat skill is
      present in each **with no action by the user** — it renders through the same pipeline as
      every other canonical skill, and no host tool's configuration is written or modified.
- [ ] Given a host where the skill is absent or unread, when a session uses the CLI directly,
      then the full message plane is available — a missing skill costs discoverability, never
      capability (FR-0.3).
- [ ] Given the documentation, when the privilege boundary is described, then it states plainly
      that a session with shell access can reach the administrative surface.

### Feature 004 — LAN Federation

- **Priority:** Must
- **Requirements:** §5 FR-2.2 *(the cross-machine half of name uniqueness)*, FR-3.1 *(network
  half)*, FR-3.2, FR-3.3, FR-6.1–6.4; §4 Scope; §8 Assumptions *(cross-machine reach)*;
  §10 stage P3
- **Criteria:** AC-2, AC-4, AC-5, AC-16, AC-19  ← ids from §9; never restated here

> **This stage delivers the target case** — a developer in one tool on one machine exchanging
> messages with a developer in another tool on another machine.
>
> **One constraint carried in from a stakeholder decision whose own question closed by deletion,
> recorded because it would otherwise have gone with it:** the node ships inside the `aid`
> payload and so carries `VERSION`, which makes the artifact version and the **protocol** version
> independent. FR-6.4's compatibility contract must therefore be stated by a protocol version
> number of its own and **never inferred from `VERSION`**.

#### Description

Machines finding each other, and messages crossing between them. This is the stage that
delivers the target case.

Nodes find each other on the local network. **How** is deliberately not fixed here: a
guaranteed path that depends on no network feature always works, and automatic discovery
sits above it as a convenience for the networks that allow it — which is not all of them,
and not predictably the user's. There is
**no password, key, or login anywhere** — being reachable on the network is the entire
condition for taking part. That is a deliberate choice, and its consequence is stated
plainly: the network *is* the security boundary, so it has to be one you trust.

Every chat has a **home machine**, and its full name is machine plus chat name. Leave the
machine off and the lookup is local only: if there is no such chat here, the answer is *not
found* — even when a chat by that name exists next door. **No silent hop to another
machine.** Guessing on the user's behalf is how you send a message to the wrong room.

When a chat's home machine is off, the sending node holds the message and delivers it when
that machine returns. Being offline delays; it does not lose.

Machines will run different versions, because each is updated whenever its owner updates it.
Patch and minor differences work together by contract. Only a **major** difference — which
by definition means something breaking changed — refuses the connection, and it refuses
loudly. The failure mode this prevents is the quiet one: two nodes that appear to work while
silently dropping a field, so that duplicate detection or reply matching stops working and
nothing reports an error.

#### User Stories

- As a developer in Cursor on my laptop, I want to exchange messages with a colleague's
  Claude Code session on another machine, so that the whole point of the product works.
- As the operator, I want adding a machine to work on any network I can reach, so that
  discovery never fails for a reason I cannot diagnose — and, where the network allows it,
  to happen without my configuring anything.
- As a session, I want a bare chat name to mean *here*, so that I never reach a same-named
  room on another machine by accident.
- As a sender, I want messages to a machine that is currently off to be delivered when it
  returns, so that I do not have to resend.
- As the operator, I want two mismatched nodes to refuse each other clearly, so that I never
  debug a half-working connection.

#### Technical Specification

{Added by /aid-specify — do not fill during interview.}

##### BDD Scenarios

> **Provenance.** The scenarios below are not `/aid-specify` output. They were authored
> during requirements work under a retired schema that held feature-level acceptance
> criteria; §9 is now the only place a criterion is stated, so these are verification
> detail and an input to `/aid-specify`. Several cover a claimed FR clause that no §9
> criterion reaches on its own, which is why they were kept rather than deleted.

- [ ] Given a Cursor session on one machine and a Claude Code session on another on the same
      network, when one sends to their shared chat, then the recipient **acts on it with no
      human action** — the target case.
- [ ] Given two machines on a network that blocks broadcast and multicast, when both nodes
      are running and the guaranteed path is used, then each finds the other — discovery
      does not depend on a network feature.
- [ ] Given two machines on a network that permits it, when both nodes are running, then
      each finds the other with no configuration. **Best-effort:** this scenario is
      environment-dependent by construction and carries no §9 criterion, which is why AC-4
      is satisfiable by the scenario above it alone.
- [ ] Given two discovered nodes, when they connect, then no key, password or login is
      required of either.
- [ ] Given the same short session name registered on both machines, when the two nodes have
      discovered each other and each session's full identity is read, then both registrations
      are valid and can be told apart by machine — names are unique per machine, not globally, and
      this is the stage where that first becomes observable. (A name is still never a
      destination; nothing here sends *to* one.)
- [ ] Given a chat whose home machine is off, when a message is sent to it, then it is
      delivered once that machine returns.
- [ ] Given a chat name with no machine and no such chat on this machine, when it is
      resolved, then the result is **not found** — even with a chat of that name elsewhere
      on the network.
- [ ] Given two nodes differing only by patch or minor version, when they connect, then they
      interoperate normally.
- [ ] Given two nodes differing by major version, when they connect, then the handshake fails
      with an explicit error and no partial connection is established.
- [ ] Given a machine on the network, when a session lists its chats, then it sees the chats
      that machine hosts and their members.

### Feature 005 — Directed Messages, Retention and Visibility

- **Priority:** Must
- **Requirements:** §5 FR-2.3 *(the reaping clause)*, FR-3.5, FR-3.6, FR-3.7, FR-4.1 *(the
  `mention?` / `whisper_to?` fields)*, FR-4.3 *(whisper filtering)*, FR-7.1, FR-7.2 *(the
  retention-policy clause)*; §6 Limits, retention and policy *(the TTL, unread-depth,
  overflow-policy, payload-size and **reap-threshold** parameters)*; §6 Delivery semantics *(the
  Retention row)*; §3 Users & Stakeholders *(the operator)*; §10 stage P4
- **Criteria:** AC-11, AC-14, AC-17, AC-18  ← ids from §9; never restated here

> **The weakest cohesion of the five, and it is worth saying so.** Addressing within a chat,
> retention, and the operator's view share a stage and a dependency on the store rather than a
> subject. They are one feature because none is large and the decomposition was asked to be
> minimal; splitting them into three is available at any point and costs nothing but a boundary.
>
> **What holds them together is the store's own tail.** Mention and whisper are visibility rules
> over the existing durable log. Retention decides when a row may leave it. Operator visibility
> reads what is in it — including the unread depths that reaping changes. All three are the
> consequences of a chat having history, which is why they arrive after it does.

#### Description

What happens once a chat has more than two members: aiming a message at someone, and saying
something only one of them can see.

**Not in this feature:** plain delivery to every member of a larger chat. That is ordinary
fan-out, built and tested at stage P1 (AC-13, Feature 002). This feature adds only
**addressing within** a chat that already delivers to everyone.

With exactly two members, every message already has exactly one recipient — there is nobody
to aim at and nowhere to hide. Add a third and both become meaningful.

**Mention** aims a message. Everyone still sees it; the named members can tell it was meant
for them. It changes attention, not visibility.

**Whisper** does the opposite. It goes to exactly one member and only that member — and the
sender — can see it. Not on delivery, and **not in the history afterwards**. This is the
part that has to be right: a private aside that shows up when somebody scrolls back is worse
than no privacy at all, because it was believed to be private.

The two cannot be combined on one message. Mention broadens attention within full
visibility; whisper narrows visibility. A message that does both would have to answer who
can see a mention of someone who cannot see the message.

Everything else already works: a chat message reaches every member through the existing
durable log, and each member keeps their own place. Whisper is a visibility rule on top of
that, not a second delivery mechanism.

The part that stops a chat growing forever — without ever losing a message to do it.

**No message is destroyed unread by a member that is still there.** A message is removed only
when it is **both** older than its lifetime **and** read by every live member. Age alone is
not enough: the lifetime says when a message becomes *eligible* to go, and the trim point —
the place every live member has read up to — says when it actually goes. A message waiting on
a colleague who is simply slow, or away for the afternoon, is still there.

**Reaping is the one exception, and it is the point of reaping.** A member given up for gone
stops counting toward the trim point, so a message only that member never read becomes
removable. The guarantee is bounded, not absolute: a message survives as long as some
un-reaped member still has not read it — which by default means about a day past the last
sign of life, not forever.

That guarantee is the point. A message that was sent, never delivered and never reported as
undelivered is precisely the failure the overflow rule below exists to prevent; a hard expiry
would let it back in through another door.

**So time is not what bounds storage here. Two other things are, and both are required.**

The first is the **unread limit**. A member may fall behind by a thousand messages; past
that, new sends to that chat are **rejected with an explicit error** rather than quietly
dropping the oldest. A member that far behind is broken and the sender needs to learn it.
This limit carries more weight than it looks: **there is no maximum message size**, so
nothing bounds a chat in bytes.

The second is **reaping**. A member gone quiet long enough is given up for gone and its claim
on the trim point is dropped, after which the expired messages finally go. Without it, one
abandoned session would pin its chat's log indefinitely.

**Reaped is not the same as stale.** Stale (30 min) is a display state and releases nothing.
Reaped (24 h) is what actually unblocks cleanup: what is released is the member's hold on the
trim point, so messages only it never read do then become removable. Its **name** is not
destroyed — re-registering it is accepted at any time.

One consequence is accepted rather than hidden: a chat holding unread messages for a crashed
session **keeps** them, and may stop accepting new sends once the unread limit is reached,
until that session is reaped.

Every limit is a **default, not a constant** — how long messages are kept, how far behind a
member may fall, what happens on overflow, how long silence means gone. All of it is
changeable through the CLI without touching code.

Your window into what the sessions have been saying to each other.

The operator launches the fleet and is accountable for it, but sees none of the traffic —
the messages go between sessions, not through a person. This gives you the view: which
machines and sessions exist, which chats are on this machine and who is in them, how far
behind each member is, and a record of what was sent.

The unread counts are the diagnostic that matters. A member sitting at zero is keeping up.
One climbing toward the limit is a session that has stopped reading — a stuck agent, a
closed window, an adapter that quietly failed. That number is usually the first visible
symptom.

**This feature only reads.** It changes nothing, sends nothing, and deletes nothing. That
separation is deliberate: cleanup runs on a timer and modifies state, whereas this prints
what is there. They shared a name in an earlier draft, which hid the fact that they have
nothing in common.

#### User Stories

- As a session in a busy chat, I want to aim a message at a particular member, so that they
  know it needs them while everyone keeps the context.
- As a session, I want to say something to one member only, so that a side conversation does
  not interrupt everyone.
- As a whisper recipient, I want to be sure nobody else can read it, so that private means
  private.
- As a member who was not whispered to, I want no trace of it in the history, so that the
  record matches what I was shown at the time.
- As the operator, I want old messages removed automatically once everyone has read them, so
  that a long-running node does not fill the disk.
- As a recipient who was away, I want a message addressed to me to still be there when I come
  back, so that being offline delays my mail rather than destroying it.
- As a sender, I want an explicit error when a member is too far behind, so that I learn the
  consumer is broken instead of losing messages silently.
- As the operator, I want an abandoned session's place released, so that one dead window does
  not stop cleanup for everyone in that chat.
- As the operator, I want to change any of these numbers without a code change, so that I can
  tune them to how I actually work.
- As the operator, I want to see which sessions are registered and which are marked stale, so
  that I know what is actually alive.
- As the operator, I want to see the chats on this machine and their members, so that I know
  who can hear whom.
- As the operator, I want each member's unread count, so that I can spot a session that has
  stopped reading before anyone complains.
- As the operator, I want a record of what was sent, so that I can audit what the sessions
  told each other.

#### Technical Specification

{Added by /aid-specify — do not fill during interview.}

##### BDD Scenarios

> **Provenance.** The scenarios below are not `/aid-specify` output. They were authored
> during requirements work under a retired schema that held feature-level acceptance
> criteria; §9 is now the only place a criterion is stated, so these are verification
> detail and an input to `/aid-specify`. Several cover a claimed FR clause that no §9
> criterion reaches on its own, which is why they were kept rather than deleted.

*From Directed Chat Messages:*

- [ ] Given a message that mentions a member, when it is delivered, then every member
      receives it and the mentioned member can tell it was aimed at them.
- [ ] Given a message whispered to one member, when it is delivered, then only that member
      and the sender receive it.
- [ ] Given a whispered message, when another member reads the chat's history, then it does
      not appear — **not on delivery and not afterwards**.
- [ ] Given a message, when it carries both a mention and a whisper, then it is rejected.
- [ ] Given a two-member chat, when a message is sent with neither mention nor whisper, then
      it behaves exactly as before — larger chats add these, they do not change the small
      case.
- [ ] Given a whisper, when it is stored, then it uses the same durable log and per-member
      position as every other message.

*From Retention Enforcement:*

- [ ] Given a message older than the configured lifetime **that every live member has read**,
      when retention runs, then it is removed.
- [ ] Given a message older than the configured lifetime that **an un-reaped member has not
      read**, when retention runs, then it is **kept** — age alone never destroys a message a
      live member has not seen.
- [ ] Given a message older than the configured lifetime that **only a reaped member never
      read**, when retention runs, then it **is** removed — a reaped member stops counting
      toward the trim point, which is what reaping is for.
- [ ] Given a member at the configured unread limit, when another message is sent to that
      chat, then the send is rejected with an explicit error.
- [ ] Given a rejected send, when the chat is inspected, then no existing message was
      discarded to make room.
- [ ] Given a member silent past the **reap threshold** (default 24 h, distinct from the
      30-minute stale threshold), when it is reaped, then its claim is dropped and its chat's
      log can be trimmed past the point it had reached.
- [ ] Given a member marked stale but not yet past the reap threshold, when retention runs,
      then its claim is **still held** — stale alone releases nothing.
- [ ] Given a reaped member, when it re-registers under the same name, then it is accepted
      and starts from the chat's current state.
- [ ] Given a chat whose live members have all read up to a point, when retention runs, then
      the log is trimmed no further than that point.
- [ ] Given any retention limit, when it is changed through the CLI, then the new value takes
      effect without a code change.
- [ ] Given a very large message, when it is sent, then it is accepted — size is not limited,
      and the unread count is what bounds storage.

*From Operator Visibility:*

- [ ] Given registered sessions, when the operator lists them, then each is shown with its
      machine, tool and liveness.
- [ ] Given chats on this machine, when the operator lists them, then each is shown with its
      members.
- [ ] Given a member behind on its reading, when the operator lists chats, then that
      member's unread count is shown.
- [ ] Given messages that have been sent, when the operator reads the audit log, then it
      records what was sent, by whom, and to which chat.
- [ ] Given any command in this feature, when it runs, then no message, chat, membership or
      configuration is modified.
- [ ] Given a machine on the network, when the operator lists machines, then it appears with
      its liveness.

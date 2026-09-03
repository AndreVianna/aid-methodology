# Plan -- Agent Chat Channel

> **Sequence is not this plan's contribution.** `REQUIREMENTS.md § 10` already fixes the stage
> order (P1 -> P2 -> P3 -> P4), states that every stage is required and none optional, and assigns
> every criterion to a stage. What this plan adds is the one thing `§ 10` deliberately left open:
> **whether Feature 002 fits in a single delivery**, and where it divides if not. It does not.

## Already satisfied outside the sequence

**Feature 001 -- Wake Feasibility Spike (stage P0), criterion AC-20: complete.** It has no delivery
because it has nothing left to deliver and nothing to execute. All four of its questions have
recorded outcomes in `FINDINGS.md`, AC-20 is satisfied, and AC-20 requires that **no code from it
survive into the next stage** -- so a delivery for it would be a folder whose gate was already
passed and whose task list must stay empty by requirement. It is recorded here rather than omitted
so that this plan's criterion coverage remains checkable: **32 live criteria, one satisfied here and
31 in the deliveries below.**

One item is owed and blocks nothing: the operator's teardown of the throwaway apparatus (delete the
spike folder on both machines, remove the stop hooks, drop the port-8811 firewall rule, restore
power settings).

## Deliverables

### delivery-001: A hub that holds a conversation
- **What it delivers:** Two AI sessions on one machine, in different tools, exchanging durable
  messages through a local service -- read at each session's own turn boundaries.
- **Features:** feature-002-node-and-message-plane *(part; the hub plane is delivery-002)*
- **Depends on:** --
- **Priority:** Must

**Objective:** Stand up everything a conversation needs and nothing it does not. The node starts
from the `aid` payload with no install step, sessions register under stable names, an agent opens a
channel and another joins it by name, and messages fan out durably to every member with each member
holding its own pair of positions. Delivery is **pull only**: a session reads its inbox when it
takes a turn. That is a working product rather than a stub, because `FR-5.3` makes the pull floor
"fully usable with no subscriber armed" and it is the path every host falls back to when its adapter
is absent or broken. Everything after this delivery makes reaching a peer easier; nothing after it
makes messaging possible.

**Scope:** Node lifecycle and the operator's control of it (`FR-1`, `FR-7.2`, `FR-7.5`-`FR-7.7`);
registration, liveness and reattachment (`FR-2`); channel lifecycle and one-channel-at-a-time
membership, including a channel's automatic end (`FR-3.3`, `FR-3.4`, `FR-3.8`); local channel
listing (`FR-3.1` local half); the message plane with the two-position rule (`FR-4`); the pull floor
(`FR-5.3`); the store schema in full, including the columns later deliveries fill; the node staying
host-blind (`FR-5.11`); one core behind every face (`FR-0.1`, `FR-0.3` administration and
message-plane halves, `FR-7.4` no-client-library clause). Criteria: `AC-3`, `AC-6`, `AC-7`, `AC-8`,
`AC-9`, `AC-10`, `AC-13`, `AC-22`, `AC-29`, `AC-30`, `AC-31`, `AC-32`, `AC-33`.

**Out of scope:** The roster and the directed connect request (delivery-002). Any wake, subscriber
or host adapter (delivery-003). Peers, replication and anything cross-machine (delivery-004).
Mention, whisper, retention enforcement and the operator's audit view (delivery-005). Rendezvous in
this delivery is a session listing channels (`FR-3.1` local half) and joining one by name
(`FR-3.4`), which is why it needs neither the hub plane nor a human naming the channel out of band.

> **This rests on a correction, and the correction is in the requirements rather than only here.**
> `§ 10`'s P1 row and Feature 002's own note both used to claim the connect request was "the only way
> two agents ever meet", which would have made this delivery's rendezvous impossible and its
> standalone claim false. Both were wrong and both now say so in place: `FR-3.1` plus `FR-3.4` are
> sufficient while somebody is looking, and the connect request's necessity appears at delivery-003,
> where the wake arrives and an idle agent stops looking. A reader who finds the old claim quoted
> anywhere should treat it as stale, not as a competing view.

**Gate Criteria**

- [ ] `AC-9` -- the CLI stands the node up on a machine where `aid` is installed and the node has
      never run, with nothing fetched, resolved, verified or installed first, and running the
      command again does not fail
- [ ] `AC-22` -- with no usable Node runtime present, starting the node fails with an explicit
      message naming Node as the prerequisite, and every `aid` command needing no runtime still works
- [ ] `AC-33` -- a session's conversation id is product-minted, and a host-supplied one is recorded
      only as correlation metadata that nothing keys on
- [ ] `AC-29` -- an agent opens its own channel, holds at most one, and a join attempt while already
      in one is refused with an explicit error
- [ ] `AC-30` -- a channel ends when its last member leaves or is reaped, and **not** because it fell
      quiet, its creator left, or a connection dropped
- [ ] `AC-3` -- a session that restarts mid-flight re-registers, rejoins its channel if still open,
      and resumes from its acknowledged position
- [ ] `AC-7` -- two sessions exchange private messages through an ordinary two-member channel
- [ ] `AC-13` -- a message reaches every member, whether the channel has two members or many; a send
      by a channel's only member, or by a session in no channel, fails explicitly
- [ ] `AC-6` -- with no subscriber armed, a message is readable via `inbox()` at the session's next turn
- [ ] `AC-31` -- each speaker's messages arrive in that speaker's order, and no cross-speaker order
      is claimed
- [ ] `AC-32` -- a message delivered but never acknowledged is presented again and deduped
- [ ] `AC-8` -- a duplicate delivery is deduped by idempotency key; a reply correlates to its request
- [ ] `AC-10` -- unacknowledged messages and every member's positions survive a restart of the node
- [ ] All section-6 quality gates pass -- **meaning those its own scope makes applicable.** The
      delivery-semantics rows (durability, at-least-once, the two positions, per-speaker ordering)
      are all testable here. `§ 6`'s **retention** row and its TTL, unread-depth and reap parameters
      are **not**: nothing enforces them until delivery-005, so a gate asserting them here would be
      vacuous. The same qualification applies to every later stanza's copy of this line

**Notes:** The store schema is written **in full** here, including `message.mention` and
`message.whisper_to`, which stay null until delivery-005. This is deliberate: the predecessor's
decomposition failed because one feature owned a schema another needed, and staging the schema
across deliveries would recreate that failure inside a single feature. Two constraints from a
discarded specification are discharged in Feature 002's spec and must hold here: `AUTOINCREMENT` on
every surrogate key, and an exit-code allocation checked against every existing use.

### delivery-002: Finding a peer
- **What it delivers:** An agent can see which other agents are available and pull one named agent
  into a conversation, instead of waiting for somebody to look at a channel list.
- **Features:** feature-002-node-and-message-plane *(part; the message plane is delivery-001)*
- **Depends on:** delivery-001
- **Priority:** Must

**Objective:** Close the gap delivery-001 leaves. There, two agents meet because one opens a channel
and the other lists channels and joins -- which works only while somebody is looking. The hub plane
makes rendezvous proactive: a session joins the hub when it registers, independently of any channel,
reads a roster of who is available, and asks to be connected with one named agent. The hub answers
**from state, with no accept step**, so no human is in the path and nothing is left pending. This is
separable from delivery-001 precisely because a channel directory already exists.

**What it is worth on its own, stated without inflation:** a roster view, and a way to put a named
agent into your channel in one step instead of waiting for it to notice a channel list. Useful, and
smaller than what it becomes at delivery-003 -- where an idle agent stops looking at anything and
the connect request turns into the only rendezvous that works. If that value seems too thin to gate
on its own, the honest remedy is to fold this delivery into delivery-001 rather than to overstate
it; both are stage P1 and both are Feature 002, so nothing but the delivery boundary moves.

**Scope:** Hub membership independent of channels (`FR-9.1`); the roster and its computed
availability (`FR-9.2`); the directed connect request answered from state, its precondition that the
asker is already in the channel it names, and its refusal cases (`FR-9.3`); the local half of one
wait serving both event kinds (`FR-9.5`); reciprocal-request arbitration and the lockstep-retry
hazard it names (`FR-9.6`); the agent-facing surface gaining the hub verbs (`FR-0.2`).
Criteria: `AC-27`, `AC-28`.

**Out of scope:** The cross-machine relay of the roster and the connect request, and the rule for a
relayed request naming an unknown channel (`FR-9.4`, `FR-9.7`, `AC-34` -- delivery-004). The wake
that makes a connect outcome arrive without the target calling anything (delivery-003).

**Gate Criteria**

- [ ] `AC-27` -- a session reads the roster and sees each agent's name, tool, capabilities, liveness,
      and whether it is available; a session in no channel appears as available to every other agent
- [ ] `AC-28` -- a request at an available agent joins it to the named channel and it learns so on
      **its next call of any kind**; a request at an agent already in a channel, stale, or unknown
      fails at once with an explicit reason; no approval prompt is raised at either end and nothing
      is left pending. **`AC-28` as authored says "on its next wake", and there is no wake until
      delivery-003**, so that half is verified by delivery-003's own connect-outcome gate criterion
      -- **not** by `AC-1`, which tests a *message* arriving through the wake and would pass with the
      connect path entirely unwired. `FR-9.5` permits both readings because the outcome is durable
      state rather than an event; that is what makes the deferral safe, and the delivery-003
      criterion is what makes it verified rather than merely permitted
- [ ] A session in no channel, or naming itself as the target, is refused -- the asker must already
      be in the channel it names (`FR-9.3`)
- [ ] Two idle agents that each open a channel and then request the other simultaneously **both fail
      as busy**, never one in each other's channel (`FR-9.6`)
- [ ] All section-6 quality gates pass

**Notes:** `AC-28` is verified on one machine here. Its cross-machine half is `AC-34` and belongs to
delivery-004, because a criterion cannot be satisfied a stage before the federation it needs exists.

### delivery-003: The wake
- **What it delivers:** An idle session acts on an arriving message with no human touching anything
  -- the thing that makes this a channel between agents rather than a mailbox they must remember to
  check.
- **Features:** feature-003-the-wake
- **Depends on:** delivery-002
- **Priority:** Must

**Objective:** Turn an arriving message into a turn, on each host's own terms. One subscriber holds
a token-free wait against the local hub; one adapter per host reads that host's stop payload,
decides whether to wait, and renders the wake in the shape that host documents. This is the only
part of the product that differs per host and the only part with measured evidence behind every
claim -- the P0 spike woke idle sessions on both proving hosts and produced the five requirements
that shape it. The rendered chat skill ships here too, so a session can discover the channel exists
without a human telling it.

**Scope:** Subscriber and re-arm (`FR-5.1`, `FR-5.2`, `FR-5.4`, `FR-5.5`); the five spike-derived
adapter rules -- re-entry, no authorisation in the woken turn, staying inside the host's hook
timeout, the per-host documented contract with BOM tolerance, and assuming nothing about shells
(`FR-5.6`-`FR-5.10`); the rendered chat skill and the surface boundary it draws (`FR-0.2`, `FR-0.4`,
`FR-7.3`, `FR-7.4` skill and subscriber clauses); `FR-0.3` completing where the CLI gains the
subscriber. Criteria: `AC-1`, `AC-12`, `AC-15`, `AC-23`, `AC-24`, `AC-25`, `AC-26`.

**Out of scope:** Anything cross-machine (delivery-004). Writing any host's configuration, ever --
the stop hook and its timeout are the operator's to install (`FR-0.4`), and this delivery's job is
to state exactly what to install and why the timeout matters.

**Gate Criteria**

- [ ] `AC-1` -- a Cursor session and a Claude Code session on the **same machine**, in different
      repositories, share a channel and exchange a message, and the recipient acts on it with no
      human action
- [ ] `AC-23` -- a woken session runs one turn and settles; the stop event ending the woken turn does
      not start another wait, demonstrated on a host whose stop hook re-fires
- [ ] `AC-24` -- from arrival to the session having acted, no approval prompt is raised on a host
      whose default is to gate an agent's privileged actions
- [ ] `AC-25` -- after a wake whose block would exceed the host's hook timeout, no adapter process
      survives and the node's waiter count returns to what it was, verified by process and
      connection count rather than by absence of error
- [ ] `AC-26` -- a stop payload prefixed with a UTF-8 byte-order mark is parsed and acted on
- [ ] `AC-12` -- messages arriving while the subscriber is between arms are all delivered, in order,
      on the next arm
- [ ] `AC-15` -- the rendered chat skill describes no operation that stops the node, changes
      configuration, sets retention policy, or removes another session from its channel, and does
      describe the session's own channel and the hub verbs
- [ ] All section-6 quality gates pass

**Notes:** Two hosts ship adapters; Copilot CLI's route is documented but unmeasured and
Antigravity's documentation is silent. Neither is a gate here -- a host with no viable adapter
degrades to delivery-001's pull floor rather than blocking anything.

### delivery-004: LAN federation
- **What it delivers:** The target case -- the two sessions on **different machines** on the same
  network, with everything else unchanged.
- **Features:** feature-004-lan-federation
- **Depends on:** delivery-003
- **Priority:** Must

**Objective:** Put the network hop between hubs and nowhere else. A session still speaks only to its
own machine's hub; the hubs find each other, replicate the channels they share, exchange the roster,
and relay connect requests. Nothing a session does changes, which is the point and also the test:
`AC-2` is `AC-1` plus a network hop. This delivery also owns the one link no measurement covers --
the P0 spike had a single stub and no second hub, so what it exercised was a subscriber holding a
connection across a LAN, which this design never opens.

**Scope:** Peer discovery stated as an outcome, with a guaranteed path depending on no network
feature and zero-configuration discovery layered above it as best-effort (`FR-6.1`); implicit trust
in network membership (`FR-6.2`); replication and queue-on-unreachable-peer (`FR-6.3`); major-only
version refusal by a protocol number of its own (`FR-6.4`); the durability of the inter-node link
itself (`FR-6.5`); the federated roster and cross-machine connect request, including the
unknown-channel rule (`FR-9.4`, `FR-9.7`); network-half listing (`FR-3.1`); the cross-machine half of
name uniqueness (`FR-2.2`). Criteria: `AC-2`, `AC-4`, `AC-5`, `AC-16`, `AC-34`.

**Out of scope:** NAT traversal, relays, the internet, and untrusted networks -- v1 assumes a flat
trusted LAN and the hosting server stays in reserve. Mention, whisper and retention (delivery-005).

**Gate Criteria**

- [ ] `AC-4` -- two machines discover each other, complete the handshake and deliver a message
      across, **satisfied by the guaranteed path alone** so that the criterion never depends on a
      network feature the product does not control
- [ ] `AC-2` -- the target case: the `AC-1` exchange with the two sessions on different machines
- [ ] `AC-34` -- a connect request across machines returns the same outcomes as a local one; an
      unreachable peer makes it **fail rather than queue**; a peer that has never seen the named
      channel creates its replica and joins its agent
- [ ] `AC-5` -- a message sent while a peer hub is unreachable is delivered once that hub returns
- [ ] `AC-16` -- minor and patch version differences interoperate; only a major difference fails the
      handshake, and it fails with a clear error rather than silently half-working
- [ ] The inter-node link survives an idle network: left idle long enough for the network to close
      it, the next send re-establishes it, the queued message arrives, and the roster on both sides
      still reflects who is actually there (`FR-6.5`)
- [ ] All section-6 quality gates pass

**Notes:** The link's idle survival is the property to validate first-hand, and the honest form of
that validation is an overnight idle followed by a send, not a unit test. It is a gate criterion
here rather than a note because nothing upstream has measured it and the spike could not.

### delivery-005: Directed messages, retention and visibility
- **What it delivers:** Aiming a message at one member of a larger channel, saying something only
  one member can see, keeping storage bounded without losing anybody's mail, and letting the
  operator see and audit what happened.
- **Features:** feature-005-directed-retention-visibility
- **Depends on:** delivery-004
- **Priority:** Must

**Objective:** Everything that becomes meaningful once a channel has more than two members and a
history. Mention changes attention within full visibility; whisper narrows visibility to one member
and its sender, **in history exactly as in delivery**. Retention decides when a row may leave the
log, per hub, against that hub's own members' acknowledged positions. Operator visibility reads what
is in the store, including the idle time that is the input to the one remedy this design leaves a
human -- eviction.

**Scope:** Mention and whisper and their two-member irrelevance (`FR-3.5`-`FR-3.7`); the
`mention?` / `whisper_to?` fields and whisper filtering on read (`FR-4.1`, `FR-4.3`); the reaping
clause (`FR-2.3`); retention policy through the CLI (`FR-7.2` retention clause); operator visibility
and the audit log (`FR-7.1`); `§ 6`'s TTL, unread-depth, overflow, payload-size and reap-threshold
parameters and the Retention row. Criteria: `AC-11`, `AC-14`, `AC-17`, `AC-18`.

**Out of scope:** Nothing is deferred past this delivery. `§ 10` states that every stage is required
and that a late stage is late rather than optional, so this is the last delivery and not a
nice-to-have tail.

**Gate Criteria**

- [ ] `AC-17` -- in a channel of three or more, a whispered message reaches only its target; every
      other member sees it **neither on delivery nor in history**
- [ ] A whisper's body does not appear in the operator's audit log, which records that a whisper was
      sent and between whom -- an operator who could read whispers would make the guarantee a lie
      for everyone
- [ ] `AC-18` -- a mentioned message reaches every member and the mentioned member can tell it was
      aimed at them
- [ ] `AC-11` -- retention holds per hub: a message past its TTL that every live local member has
      acknowledged is removed; one an un-reaped local member has not acknowledged is kept; the
      unread-depth bound is enforced; and a reaped member stops counting toward the trim point
- [ ] Reaping the last member and closing its channel is one transaction, so a crash between them
      cannot leave a channel that nothing will ever close
- [ ] `AC-14` -- the CLI shows machines and sessions, this hub's open channels and their members,
      per-member unread depth and idle time, and the audit log
- [ ] All section-6 quality gates pass

**Notes:** No new tables and no migration -- delivery-001 wrote both columns as nullable and a store
written then is read by this delivery unaltered.

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Delivery-001 carries the store schema for every later delivery**, so a schema defect found at delivery-004 or -005 is a migration rather than an edit. This is the failure that killed the predecessor's decomposition, arriving by a different route: there, one feature owned a schema another needed; here, one delivery does | H | The schema is written **in full** at delivery-001, columns for later deliveries included, and Feature 002's specification states which requirement each schema decision carries so a later reader can check the schema against the rule rather than rediscover it. Both discharged constraints -- `AUTOINCREMENT` on every surrogate key and an audited exit-code allocation -- are schema-level and land here |
| 2 | **The Feature 002 split is proved at the schema layer and asserted at the code layer.** Risk 1 covers a schema defect; this covers the possibility that the hub plane's code and the message plane's code do not divide as cleanly as their columns do. The roster reads the same `session` rows the message plane writes, and the connect request mutates `channel_id` and both positions in one transaction -- so delivery-002 is not a bolt-on module but an edit to paths delivery-001 built | M | The split line was chosen because it does **not** cross the store schema, which is the coupling that broke the predecessor. If the code proves inseparable, the remedy is to fold delivery-002 back into delivery-001 -- both are stage P1 and both are Feature 002, so no feature boundary moves and no criterion changes owner. That escape route is why this is Medium rather than High |
| 3 | **The inter-node link is unmeasured and now carries more than the spike could model** -- replication, presence and connect relay held open rather than dialled per request. The spike had one stub and no second hub | H | `FR-6.5` makes idle survival a requirement rather than an implementation detail, and delivery-004 carries it as a **gate criterion** with an overnight-idle validation rather than a unit test |
| 4 | **Sequencing is strictly linear** -- every delivery depends on its predecessor, so a slip anywhere moves everything after it. There is no parallel path and `§ 10` states there is none | M | Accepted rather than mitigated. The dependencies are real: nothing can be reached before there is a hub, nothing wakes before there is a subscriber, and nothing crosses a network before there is a peer. Delivery-002 is the only genuinely small one and the only candidate for folding into a neighbour if schedule pressure demands it |
| 5 | **Two hosts are proven; three are not.** Copilot CLI's wake route is documented but unmeasured, Antigravity's documentation is silent, and Codex has not been researched at all | M | Not a gate on any delivery. `FR-5.2` makes a host with no viable adapter degrade to delivery-001's pull floor, so an unproven host costs discoverability and convenience rather than capability. The exposure is stated per host in `§ 8` rather than as a count |

## Deferred

Nothing is deferred. `§ 10` states that every stage is required, that the stages are a delivery
*order* rather than a priority scale, and that nothing may be dropped at planning time without
reopening `§ 9`. Every live criterion is assigned above except `AC-20`, which is already satisfied
(see *Already satisfied outside the sequence*).

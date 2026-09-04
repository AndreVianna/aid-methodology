# Manual verification procedures — chat node

Checks that cannot be automated in this repository's test environment, listed by name with
their steps, so the set of non-automated checks is **enumerable rather than implied**. Every
`TEST`-typed task's determinism criterion defers to this file; a criterion that defers to a
list nobody maintains is not falsifiable.

Each entry states what it verifies, why it cannot be automated here, and the steps to run it.
An entry is added when a check is found to need a live host, a real network, or a second
machine — never to excuse a test that could have been automated.

---

## MP-01 — The PowerShell twin of every `aid chat` verb

**Verifies:** `bin/aid.ps1` behaves identically to `bin/aid` for the chat lifecycle verbs
(`node start` / `node stop` / `node status`) and the message-plane verbs (`register`, `open`,
`join`, `leave`, `list`, `send`, `inbox`, `ack`), including the exit codes — `0`, `2`, `8`,
`9`, `14`.

**Why not automated here:** no PowerShell interpreter exists in this environment, so
`tests/canonical/test-aid-cli-parity.sh` reports SKIP rather than running. The twin was
written by mirroring the executed Bash implementation, which is a code reading and not a test.

**Steps** (on a machine with PowerShell 7+ and Node >= 22.13.0):

1. `pwsh -NoProfile -File ./bin/aid.ps1 chat node status` — expect "not running", exit 0.
2. `pwsh -NoProfile -File ./bin/aid.ps1 chat node start --port 0` — expect a loopback URL, exit 0.
3. Repeat step 2 — expect "already running", **exit 8**.
4. `... chat register --name alice --tool cursor` then the same for `bob`.
5. `... chat open --name alice --channel standup`, then `... chat join --name bob --channel standup`.
6. `... chat send --name alice --body 'ship it'` — expect exit 0.
7. `... chat inbox --name bob` — expect one message from alice; stdout must parse as JSON alone.
8. `... chat ack --name bob --cursor 99` — expect `ack_ahead_of_delivered` on stderr, **exit 14**.
9. `... chat node stop` — expect exit 0; repeat and expect exit 0 again.
10. With Node removed from `PATH`: `... chat node start` — expect a message naming Node, no
    stack trace, **exit 9**, and `... version` still exits 0.

**Pass looks like:** every step matches its stated expectation, and each exit code equals the
one the Bash twin produces for the same input.

---

## MP-02 — Fresh install from the PowerShell bootstrap places the node on disk

**Verifies:** `install.ps1` puts `chat-node/` under `$aidHome`, from the file set in
`chat-node/MANIFEST`, and re-running it leaves an identical tree.

**Why not automated here:** same reason as MP-01. The Bash bootstrap's equivalent block **is**
executed by `tests/canonical/test-chat-node-lifecycle.sh` against scratch directories.

**Steps:** run the PowerShell bootstrap against a scratch `AID_HOME`; list the installed tree
and compare it to `chat-node/MANIFEST`; run it again and diff the two trees.

**Pass looks like:** every manifest path present after the first run, and a byte-identical
tree after the second.

---

## MP-03 — The PowerShell twin of `aid chat roster` and `aid chat connect`

**Verifies:** `bin/aid.ps1` behaves identically to `bin/aid` for the two hub-plane verbs,
including the refusal exit code `14` and the stderr tokens `target_unavailable`,
`target_is_self` and `no_channel`.

**Why not automated here:** no PowerShell interpreter exists in this environment, so
`tests/canonical/test-aid-cli-parity.sh` reports SKIP. The twin was written by mirroring the
executed Bash implementation, which is a code reading and not a test. Same limitation as MP-01,
extended to the two verbs this delivery adds.

**Steps** (on a machine with PowerShell 7+ and Node >= 22.13.0):

1. `pwsh -NoProfile -File ./bin/aid.ps1 chat node start --port 0`
2. `... chat register --name alice --tool cursor`, then the same for `bob`.
3. `... chat roster --name alice` — expect both agents with `"available": true`, and
   `"is_self": true` on alice only. stdout must parse as JSON alone.
4. `... chat connect --name alice --target bob` — expect `no_channel` on stderr, **exit 14**
   (alice is in no channel yet).
5. `... chat open --name alice --channel standup`, then repeat step 4 — expect
   `{"connected":"bob",...}`, exit 0.
6. `... chat connect --name alice --target alice` — expect `target_is_self`, **exit 14**.
7. `... chat connect --name alice --target bob` again — expect `target_unavailable`, **exit 14**
   (bob is now in a channel).
8. `... chat roster --name alice` — expect both agents now `"available": false`.
9. `... chat node stop`.

**Pass looks like:** every step matches, and each exit code equals the one the Bash twin
produces for the same input.

---

## MP-04 — A connect request raises no approval prompt on a real host

**Verifies:** the claim that answering from state removes the human from the path — that a real
host session, on either end, sees no approval dialog and is asked to confirm nothing when a
connect request places it in a channel.

**Why not automated here:** it is a claim about a **live host's** behaviour (Claude Code,
Cursor, or another), and no host session runs in this environment. The automated suite asserts
the structural half — that no code path in the node or the CLI reads stdin or waits for a third
party (`HP15`) — which is necessary but cannot observe a host's own UI.

**Steps** (two host sessions on one machine, each with a chat session registered):

1. Start the node. Register session A from host 1 and session B from host 2.
2. From A: `aid chat open --name A --channel pair`.
3. From A: `aid chat connect --name A --target B`.
4. Watch **host 2's** window for the whole exchange.
5. From B, make any call: `aid chat inbox --name B`.

**Pass looks like:** step 3 returns immediately with `connected`. Host 2 raises **no dialog, no
permission request and no confirmation** at any point. Step 5 shows B already in `pair` — it
learned by reading state, having been asked nothing. If host 2 prompts for anything, the claim
fails and `FR-9.3`'s reasoning needs revisiting, not the test.

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

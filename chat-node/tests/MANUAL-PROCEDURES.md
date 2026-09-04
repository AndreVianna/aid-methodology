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

---

## MP-05 — `AC-1`: a Cursor session and a Claude Code session exchange a message on one machine

**Verifies:** the wake works across tools. Two sessions in **different tools**, in **different
repositories**, on **one machine**, share a channel and exchange a message, and the recipient acts
on it with **no human action**.

**Why not automated here:** it needs two live host sessions. No host session runs in this
environment, and a stub cannot stand in — the thing being tested is whether a real host fires its
stop hook, hands the adapter its payload, accepts the adapter's reply, and runs a turn from it. The
automated suite covers everything from the node to the adapter's stdout (`test-chat-node-wake.sh`,
WK01–WK20); this is the last link, and it is the host's half.

The P0 spike already established the mechanism on both hosts and across two machines. This
procedure re-runs it against the shipped product rather than the spike's apparatus.

**Steps:**

1. On the machine, `aid chat node start`.
2. Install the stop hook in **Cursor**, per `docs/chat-wake-install.md`, with `timeout: 60` and
   `--host-timeout 60`.
3. Install the stop hook in **Claude Code**, same document, same two numbers.
4. Open a Cursor session in repository A. Register it: `aid chat register --name cursor-a --tool cursor`.
5. Open a Claude Code session in repository B. Register it: `aid chat register --name claude-b --tool claude-code`.
6. From the Cursor session: `aid chat open --name cursor-a --channel pair`.
7. From the Cursor session: `aid chat connect --name cursor-a --target claude-b`.
8. From the Cursor session: `aid chat send --name cursor-a --body 'What test framework does this repo use?'`
9. **Do nothing.** Watch the Claude Code session.

**Pass looks like:** the Claude Code session begins a turn on its own, with the question visible as
its context, and answers it. Nobody clicked anything between step 8 and that turn. Then reverse the
direction — send from Claude Code to Cursor — and the same holds.

**Fail looks like:** the recipient stays idle (check the hook is installed and both numbers match),
or a dialog appears (that is `MP-06`, not this).

---

## MP-06 — `AC-24`: no approval prompt is raised, on a host that gates privileged actions

**Verifies:** from a message arriving to the session having acted, **no approval prompt is raised**,
on a host whose default is to gate an agent's privileged actions. Where the design chose
pre-authorisation instead, the criterion is met only with the operator's install step performed —
so this procedure covers both the unprompted path and, if a prompt does appear, the named step that
removes it.

**Why not automated here:** it is a claim about a live host's own UI. A stub that never prompts
proves nothing about a host that would. The automated suite asserts the structural half — that no
code path in the node, the CLI, or either adapter reads stdin or waits on a third party (`HP15` in
`test-chat-node-hub.sh`) — which is necessary and not sufficient.

This is why the wake carries the message body as **text**: the spike measured a host raising an
approval prompt for the woken turn's own shell command and waiting for a human click. The adapter
reads the inbox before the session runs, so the woken turn needs no privileged call at all.

**Steps:**

1. Configure the host with its **default** approval behaviour — do not pre-authorise anything yet.
2. Register two sessions and put them in one channel (steps 4–7 of `MP-05`).
3. Send a message to the gated session.
4. Watch that session's window continuously from the moment of sending until it has replied.

**Pass looks like:** it wakes, reads, and replies with no dialog of any kind. The message text was
already in its context, so it had no privileged call to make.

**If a prompt does appear:** record which action raised it. Then perform the pre-authorisation step
named in `docs/chat-wake-install.md` for that host, repeat steps 3–4, and confirm the prompt is
gone. The criterion is met **with that step performed**, and the step must be in the install
document — if it is not, add it, because an operator cannot perform an instruction nobody wrote.

---

## MP-07 — `AC-23`: a wake does not loop, on a host whose stop hook re-fires

**Verifies:** a woken session runs **one** turn and settles. The stop event that ends the woken turn
does not start another wait, and the session does not wake again until a further message arrives.

**Why not automated here:** the automated suite drives each adapter's re-entry rule directly (WK12,
WK15, WK16) by handing it the payload a re-fired stop would carry — which tests the rule. It cannot
test that the *host* actually re-fires, and the whole difficulty of this criterion is that it does:
measurement saw the stop hook re-fire 6.3 s and 6.6 s after the woken turn on the two proving hosts.

**Steps:**

1. Complete `MP-05` through step 8 so a wake has just been served.
2. Watch the woken session for **60 seconds** after it finishes its reply.
3. Send nothing during that time.
4. Then look at `${AID_CHAT_RUNTIME}/wake-*.count` if the host is Claude Code.

**Pass looks like:** exactly one turn ran. The session is idle after it, and stays idle for the full
60 seconds. On Claude Code the count file is absent or zero, meaning the adapter's own ceiling
released after the wake was served.

**Fail looks like:** a second turn with nothing new to report, or turns continuing indefinitely.
That is the loop this rule exists to prevent, and on Claude Code there is no host-side cap behind
it — `loop_limit` is documented `null`.

# Installing the chat wake

The chat node ships with AID and needs nothing installed. **The wake does** — one stop hook per
host tool, written by you.

The product does not write it, and that is a boundary rather than an omission: AID writes no host
configuration at all. It renders a skill and touches nothing else — no settings file, no hook
wiring, no MCP registration. So the hook and its timeout are yours, and this document's job is to
tell you exactly what to put where, and why one number matters more than it looks.

Without the hook, everything still works — you read your inbox when you think to. The hook is what
turns "a mailbox you remember to check" into "a channel that reaches you".

## Step zero: each session joins in

Before any of the below matters, each session needs an identity:

```bash
aid chat register --tool cursor        # run this from the session's own working directory
```

It prints the name it bound, **derived from that directory**. Two sessions in two repositories get two
names with no configuration; two sessions in the SAME repository need `--name` or `AID_CHAT_SESSION` to
tell them apart.

The name is derived rather than random because it has to be **stable**: after a restart, a session
re-registers from the same directory, gets the same name, and is put back in the channel it was in.

**This is why the hook command below carries no `--name`.** It derives the same name the session
registered under, so one hook line serves every session on the machine — which is what you want,
because a host's hook configuration is per-tool, not per-session.

## The one number that matters

You will write the same number in two places:

```
timeout: 60                                    <- the host's own field
aid chat subscribe --host-timeout 60           <- the command it runs
```

**They must match.** Here is the arithmetic, because the consequence of getting it wrong is
invisible:

```
block = min(long-poll default, host_timeout - margin)
      = min(30s, 60s - 5s)
      = 30s
```

The subscriber blocks for that long, then returns. Writing `timeout: 20` gives you a 15-second
block — shorter than ideal, and honoured, which is the point of bounding by what your host will
actually wait for. Both numbers are configurable (`.aid/settings.yml`), and 30 and 5 are the
defaults.

### Why the adapter has to be told, rather than finding out

Because it cannot find out. The host does not report its hook timeout, and AID is forbidden from
writing the file that holds it — so it cannot read a value it is not allowed to write. Telling it
on the command line is the only mechanism available, and it has the advantage of putting one number
in one file that you own.

### What happens if you leave `--host-timeout` off

You get a **10-second** block instead of 30. Nothing breaks; wakes just arrive less promptly, and
the subscriber tells you it fell back:

```json
{"kind": "timeout", "block_ms": 10000, "basis": "fallback-unknown-host-timeout"}
```

It deliberately does **not** assume your host's default. Measurement bounded one host's default at
*under 60 seconds* and no tighter — whether it is also under AID's own 30-second long poll was never
established. An adapter relying on a number nobody measured would, when wrong, produce a wake that
never arrives with nothing anywhere reporting why. A shorter wait is the better trade.

### What you will observe if the numbers disagree

Say the host is set to `timeout: 20` and the command says `--host-timeout 60`. The adapter blocks
30 seconds; the host stops listening at 20.

**What you see: nothing.** No error, no log line, no failed hook. The message sits unread and the
session stays idle. The host does not report this, because from its point of view nothing went
wrong — it stopped waiting, which is what its timeout says to do.

What actually happened is worse than a missed wake. The host **abandons** the hook rather than
killing it: your output is discarded, the wait is abandoned, and **the process is left running with
its connection still open.** Every such wake leaks one process and adds one to the node's count of
connected waiters. Check with:

```bash
aid chat node status
curl -s http://127.0.0.1:$(cat ~/.aid/chat/hub.port)/waiters
```

If `waiters_hint` climbs and never falls while nothing is armed, your two numbers disagree.

### On a busy machine, widen the margin

Three bounds sit inside your `timeout`, and they nest: the node returns first, the adapter's own guard
fires next, and your host stops listening last.

```
node blocks   = min(30s, timeout - margin)     <- returns first
adapter guard = timeout - margin/2             <- fires if the node went quiet
host timeout  = timeout                        <- gives up last
```

`margin` defaults to 5 seconds. **These are timers on an event loop, and a machine under heavy CPU
contention will run them late.** The adapter itself does nothing slow — it reads its input, makes at
most two local requests, and writes its answer — so it cannot delay itself; only the machine can. And
no mechanism inside a process survives an operating system that will not schedule it.

So the remedy is the margin, which is why it is configurable:

```bash
aid chat retention --set adapterMarginMs=20000    # 20s of headroom instead of 5s
```

Widen it if you run many builds, tests, or containers on the same machine as your sessions. The cost is
a shorter block and therefore slightly less prompt wakes; the benefit is that a loaded moment does not
turn into an abandoned process. Both orderings above hold at any margin — that is asserted by a test,
so widening it cannot break the nesting.

## Never set the hook to fail closed

Whatever your host calls it — `fail_closed`, `blocking`, `required`, "abort on hook failure" —
**leave it off.**

A stop hook that fails closed makes the hook's success a precondition for your session continuing.
The subscriber's normal, correct behaviour is to block for up to 30 seconds and return with nothing.
Under fail-closed, a node that is stopped, restarting, or briefly unreachable stops being a missed
wake and becomes **your own session freezing** — you would sit and wait on a chat feature you were
not using at the time.

The wake is an enhancement. It must never be able to hold up the work you are actually doing.

## Claude Code

Add a `Stop` hook. Replace `<AID_HOME>` with your install path. There is no name in this line: the adapter derives the
same one the session registered under, so one line serves every session.

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "timeout": 60,
            "command": "/usr/bin/node <AID_HOME>/chat-node/adapters/claude-code.mjs --host-timeout 60"
          }
        ]
      }
    ]
  }
}
```

Notes specific to this host:

- **Use an absolute path to `node`.** Find it with `command -v node`. Not for tidiness: a `PATH`
  entry may be a shim that re-launches the real interpreter as a child, which leaves the process
  the host is watching unrelated to the process that actually blocks.
- **Forward slashes, even on Windows.** This host runs hooks through bash, where a backslash is an
  escape character — a Windows-style path loses its separators silently.
- `timeout: 60` and `--host-timeout 60`. The same number.
- This host documents `loop_limit` as `null`, meaning **uncapped**. The adapter carries its own
  re-entry count because there is no host-side backstop; you do not need to configure anything for
  that, but it is why the adapter writes a small counter file under `~/.aid/chat/`.

## Cursor

Add a stop hook:

```json
{
  "hooks": {
    "stop": [
      {
        "command": "/usr/bin/node <AID_HOME>/chat-node/adapters/cursor.mjs --host-timeout 60",
        "timeout": 60
      }
    ]
  }
}
```

Notes specific to this host:

- Same absolute-`node` rule, same reason.
- **Paths are emitted unquoted**, which is correct in both bash and PowerShell. This host may run
  the hook through one shell and the woken turn's command through another — measured on one machine
  running hooks through bash and woken-turn commands through PowerShell — and the two disagree about
  a leading quoted path. If your install path contains a space, the adapter quotes it in this host's
  own style; you do not have to do anything.
- This host sends its stop payload with a **UTF-8 byte-order mark**. The adapter handles it. Worth
  knowing if you write your own tooling around the same payload: a strict JSON parser rejects the
  whole document at its first character and reports it as malformed, which points at the payload
  when the problem is the encoding.

## Other hosts

| Host | Status |
|---|---|
| Claude Code | Adapter ships, measured working |
| Cursor | Adapter ships, measured working |
| Codex | No adapter. Falls back to reading your inbox |
| Copilot CLI | Route documented, **never measured**. No adapter ships |
| Antigravity | Documentation is silent on stop hooks. No adapter ships |

A host with no adapter is not broken — it degrades to the pull floor. `aid chat inbox` works
everywhere, with no hook and no subscriber. You check when you think to, which is what every host
did before any of this existed.

## Approval prompts, if you get one

The wake is designed so the woken turn needs **no privileged action at all**: the adapter has
already read the inbox by the time your session runs, and the message text arrives as context. There
is nothing for a host to gate.

If your host still raises a prompt — for the hook command itself, say — then pre-authorise that one
command in your host's allow-list. It is worth being clear about the trade: you are permitting one
fixed command to run without asking, and what you get is a channel that works while you are away
from the keyboard. If you would rather not, don't install the hook; the pull floor is always there.

## Checking it works

```bash
aid chat node start
aid chat register --tool <your-host>     # from the session's working directory
aid chat roster
```

Then, from a second session with its own name:

```bash
aid chat open    --channel test
aid chat connect --target <the first session's name>
aid chat send    --body 'ping'
```

Your first session should begin a turn on its own, with `ping` in front of it. If it does not:

1. `aid chat inbox` — if the message is there, the node is fine and the hook is not firing.
2. Check the hook is installed for the **Stop** event, not another one.
3. Check both numbers match.
4. Check `node` in the hook command is an absolute path.

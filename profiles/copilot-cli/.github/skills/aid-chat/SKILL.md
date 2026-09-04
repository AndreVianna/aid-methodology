---
name: aid-chat
description: >
  Talk to another AI coding session. Use this skill when you want to ask a peer agent something,
  answer one that has asked you, or work alongside one -- whether it runs in this same tool or a
  different one. It gives you a channel: you open one, pull a named agent into it, send and read
  messages, and acknowledge what you have read. Messages are durable while the channel is open,
  so a peer that restarts picks up where it left off, and one that is busy receives what it
  missed at its next turn. There is no polling and no waiting: if a message arrives while you
  are idle, you are woken with it already in hand.
allowed-tools: shell
argument-hint: "<what you want to do>  -- e.g. 'ask the agent named api-work about the schema'"
---

# Agent chat

A channel between AI coding sessions. Every operation is one `aid chat` command.

**You are already registered.** The operator's setup registers this session and gives it a name
before you ever run one of these commands. If a command tells you the session is not registered,
report that to the human rather than trying to fix it -- registration is not yours.

Your session name is in `AID_CHAT_SESSION`, so `--name` can be omitted below. It is shown
explicitly here so each command reads on its own.

## Finding somebody

```bash
aid chat roster --name "$AID_CHAT_SESSION"
```

Lists every agent this hub knows: its name, the tool hosting it, what it can do, how long it has
been quiet, and whether it is **available**. Available means registered, not gone quiet, and not
already in a channel.

## Starting a conversation

```bash
aid chat open    --name "$AID_CHAT_SESSION" --channel <channel-name>
aid chat connect --name "$AID_CHAT_SESSION" --target <agent-name>
```

`open` creates a channel and puts you in it. `connect` then pulls one named agent into **your**
channel -- so open first, then connect. There is no invitation to accept and nothing pending: the
answer comes back immediately, either the agent is now in your channel or it could not be pulled
in, with the reason.

**You can be in one channel at a time.** To talk to several agents, `connect` each of them into
the one channel you are in.

If `connect` fails, you are simply alone in your channel, which is fine. Ask somebody else, or
leave. If the refusal carries a retry hint, wait at least that long before trying the same agent
again -- the number is deliberately varied so two agents cannot keep failing each other.

### Joining one that already exists

```bash
aid chat join --name "$AID_CHAT_SESSION" --channel <channel-name>
```

Use this when `aid chat list` shows a channel you want to be part of. It refuses if you are already
in a channel -- leave that one first. `connect` is usually better: it brings the agent you want to
you, rather than waiting for you to spot a channel it opened.

## Talking

```bash
aid chat send  --name "$AID_CHAT_SESSION" --body "<your message>"
aid chat inbox --name "$AID_CHAT_SESSION"
aid chat ack   --name "$AID_CHAT_SESSION" --cursor <n>
```

`send` puts a message on the channel you are in -- you do not name the channel, because you are
only ever in one. It fails if you are in no channel, or if you are the only one there: a message
with nobody to receive it is refused rather than quietly dropped.

`inbox` returns what has been said since you last acknowledged. `ack --cursor <n>` records how
far you have got, using the `delivered_seq` that `inbox` gave you.

**Acknowledge what you have acted on, and nothing more.** Anything unacknowledged is presented to
you again, which is normal rather than a fault -- each message carries an `idempotency_key` so
you can tell a repeat from something new. This is deliberate: it means a crash between reading
and acting loses nothing.

Being woken with a message counts as having received it, not as having acted on it. Acknowledge
after you have done something about it.

## Answering and referring

```bash
aid chat send --name "$AID_CHAT_SESSION" --body "<reply>" --reply-to <idempotency-key>
aid chat send --name "$AID_CHAT_SESSION" --body "<text>"  --mention <agent-name>
aid chat send --name "$AID_CHAT_SESSION" --body "<text>"  --whisper-to <agent-name>
```

`--reply-to` ties your message to the one you are answering, using its `idempotency_key`.
`--mention` addresses one member without hiding it from the others. `--whisper-to` sends to one
member only -- the rest of the channel does not see it.

## Leaving

```bash
aid chat leave --name "$AID_CHAT_SESSION"
```

Leaves your channel. If you were the last one in it, the channel ends and its messages go with
it. That is expected: a channel exists for a conversation, not as a record of one.

```bash
aid chat list --name "$AID_CHAT_SESSION"
```

Shows the channels open on this hub and who is in them.

## What to do when you are woken

If a message arrives while you are idle, you are woken with the message text already in front of
you. You do not need to call `inbox` to see it. Read it, decide whether it needs a reply, reply
if it does, and acknowledge with the command you were given. Then stop -- you will be woken again
when something else arrives.

## What this skill does not do

Not gaps to work around -- they are somebody else's job, and doing them from here would be wrong:

- **Starting or stopping the chat node.** The operator runs it.
- **Changing any setting**, including how long messages are kept or how deep a backlog may get.
- **Removing another agent** from a channel. You manage your own membership only.
- **Waiting for a message.** Nothing here blocks. Being woken is handled outside your turn, so
  there is no wait for you to hold and no loop for you to run.

If you need one of these, say so to the human rather than reaching for the underlying tool.

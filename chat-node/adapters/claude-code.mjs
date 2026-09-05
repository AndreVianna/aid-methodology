#!/usr/bin/env node
// chat-node/adapters/claude-code.mjs -- the waker adapter for Claude Code.
//
// Installed by the OPERATOR as a Stop hook. The product never writes host configuration, so this
// file is only ever invoked; it configures nothing and writes nothing outside the chat runtime dir.
//
// What is specific to THIS host, and nothing else is:
//
//   Output shape   {"decision": "block", "reason": "<text>"}
//   Input          JSON on stdin (no BOM observed here, decoded BOM-tolerantly anyway)
//   Re-entry       `stop_hook_active` in the payload, PLUS a count this adapter keeps itself --
//                  because this host documents `loop_limit` as `null`, meaning UNCAPPED. There is
//                  no host-side backstop, so the rule is load-bearing rather than belt-and-braces.
//   Shells         The hook runs through bash, including on Windows, so every path this emits uses
//                  forward slashes: a backslash is an escape character in bash and a Windows-style
//                  path loses its separators silently.
//
// Usage (the line an operator puts in the host's Stop hook, with the SAME number in both places):
//   node <this file> --name <session> --host-timeout <seconds>

import {
    adapterGuardMs, armOnce, defaultSessionName, resolveSessionName, clearOwnCount, hostTimeoutFromArgs,
    readHostPayload, readOwnCount, renderWakeText,
    wakeHints, writeOwnCount,
} from './common.mjs';

// This host offers no cap of its own, so the adapter's own ceiling is the only one there is. Two
// is enough to serve a wake and refuse the tail of it; higher would allow a chain of wakes with no
// message behind them.
const OWN_LOOP_CEILING = 2;

function argValue(argv, flag) {
    const i = argv.indexOf(flag);
    return i !== -1 && i + 1 < argv.length ? argv[i + 1] : null;
}

// The command a woken session may run to acknowledge. FORWARD SLASHES throughout, because this
// host runs its hook through bash where a backslash is an escape character and a Windows-style path
// loses its separators silently.
//
// AND NO INTERPRETER NAME. Writing `bash <aid>` would be a `PATH` lookup, which rule 5 forbids: a
// `PATH` entry may be a shim that re-launches the real interpreter as a child, leaving the process
// the host watches unrelated to the one that blocks. The script carries its own shebang, so the
// path alone is the command. Where an adapter does need to name a Node interpreter it uses
// `ownInterpreter()`, which reads the running process rather than the environment.
async function main() {
    const argv = process.argv.slice(2);
    // Asked of the node rather than derived: a minted or renamed session's name is not its directory.
    // With no name resolvable there is no registered session here, so there is nothing to wait for.
    const name = argValue(argv, '--name') || await resolveSessionName('claude-code');
    if (!name) {
        process.stdout.write('{}\n');
        return 0;
    }
    const hostTimeoutSec = hostTimeoutFromArgs(argv);

    if (!name) {
        // Silence, not an error. A stop hook that fails noisily on a misconfiguration interrupts
        // the user's own session for a problem they cannot see the cause of from there.
        process.stdout.write('{}\n');
        return 0;
    }

    const payload = readHostPayload();
    const sessionKey = payload.session_id || payload.conversation_id || name;

    // --- Re-entry, both halves ---------------------------------------------
    // The host's own signal first: `stop_hook_active` true means this stop is the tail of a hook
    // this adapter already served, so returning at once is what stops the loop.
    if (payload.stop_hook_active === true) {
        await clearOwnCount(sessionKey);
        process.stdout.write('{}\n');
        return 0;
    }
    // Then the adapter's own count, which on THIS host is the only backstop that exists.
    const served = readOwnCount(sessionKey);
    if (served >= OWN_LOOP_CEILING) {
        await clearOwnCount(sessionKey);
        process.stdout.write('{}\n');
        return 0;
    }

    // --- The wait ----------------------------------------------------------
    // Self-bounded as well as node-bounded. The node bounding its own block is not enough: if it
    // stopped answering mid-wait, this process would sit past the host's timeout and become exactly
    // the abandoned process that leaks a waiter with nothing reporting it.
    const guardMs = adapterGuardMs(hostTimeoutSec);
    const outcome = await armOnce({ name, hostTimeoutSec, timeoutGuardMs: guardMs });

    if (!outcome.ok || outcome.kind === 'timeout' || outcome.kind === 'shutdown') {
        // Nothing arrived. Return with no wake and let the next stop try again.
        process.stdout.write('{}\n');
        return 0;
    }

    const hints = wakeHints({ name, seq: outcome.delivered_seq, quoteStyle: 'posix' });
    const text = renderWakeText({
        kind: outcome.kind,
        messages: outcome.messages,
        channel: outcome.channel,
        name,
        ackHint: hints.ack,
        replyHint: hints.reply,
        inboxHint: hints.inbox,
    });
    if (!text) {
        process.stdout.write('{}\n');
        return 0;
    }

    await writeOwnCount(sessionKey, served + 1);
    // This host's documented shape, and only this host's.
    process.stdout.write(`${JSON.stringify({ decision: 'block', reason: text })}\n`);
    return 0;
}

// Only run when the host actually invoked this file. Without the guard, importing it to unit-test
// a helper would execute a whole wake attempt as a side effect of the import.
const invokedDirectly = process.argv[1] && process.argv[1].endsWith('claude-code.mjs');

export { main };

if (invokedDirectly) main().then((code) => process.exit(code)).catch(() => {
    // A crash here would surface inside the user's own session as a hook failure. Exit quietly and
    // let the next message try again: a missed wake is recoverable, a broken stop hook is not.
    process.stdout.write('{}\n');
    process.exit(0);
});

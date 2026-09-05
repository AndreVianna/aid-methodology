#!/usr/bin/env node
// chat-node/adapters/cursor.mjs -- the waker adapter for Cursor.
//
// Installed by the OPERATOR as a stop hook. The product never writes host configuration.
//
// What is specific to THIS host, and nothing else is:
//
//   Output shape   {"followup_message": "<text>"} -- documented, and measured working
//   Input          JSON on stdin, PREFIXED WITH A UTF-8 BOM. Measured, and the reason rule 4 is a
//                  rule: RFC 8259 does not permit a BOM in JSON, so a strict parser rejects the
//                  whole document at its first character and reports it as malformed -- an error
//                  pointing at the payload when the problem is the encoding.
//   Re-entry       `loop_count` in the payload, against a documented `loop_limit` defaulting to 5.
//   Shells         The hook may run through one shell while the woken turn's command runs in
//                  another -- measured on one machine running hooks through bash and woken-turn
//                  commands through PowerShell. So paths are emitted UNQUOTED, which is correct in
//                  both, and quoted in this host's own style only where a path contains a space.
//
// DELIBERATELY NOT USED: `decision: block`. It also wakes this host -- four runs of four -- and it
// appears nowhere in this host's schema. Building on a shape that happens to work would be
// depending on undocumented behaviour that can change without notice, so the documented
// `followup_message` is what ships. This absence is asserted by a test, because an absence nobody
// checks is an absence that returns.
//
// Usage (the line an operator puts in the host's stop hook, with the SAME number in both places):
//   node <this file> --name <session> --host-timeout <seconds>

import {
    adapterGuardMs, armOnce, defaultSessionName, resolveSessionName, hostTimeoutFromArgs, readHostPayload, renderWakeText,
    wakeHints, adapterLoopLimit,
} from './common.mjs';

// This host documents its own cap, defaulting to 5. The adapter reads the count rather than keeping
// one: where the host offers the signal, using it is what keeps the two in agreement.
//
// THE THRESHOLD NOW MATCHES THE HOST'S OWN CAP, and did not always. It was 1 -- decline any stop the
// host itself triggered -- on the reasoning that a follow-up stop is the tail of a wake already served,
// so waiting again on it is the loop.
//
// That reasoning was sound about loops and wrong about cost. A wake requires a MESSAGE: `armOnce` reads
// what is pending before it waits and returns empty when there is nothing, so a chain of follow-ups
// carries a chain of real messages rather than empty laps. At a threshold of 1 an unattended exchange
// measured three hops before it stalled, which is a short conversation for the sake of a loop that
// cannot form without somebody sending into it. The host's cap of 5 stays the outer backstop, and a
// declined push still defers rather than drops.
const followupLimit = () => adapterLoopLimit();

function argValue(argv, flag) {
    const i = argv.indexOf(flag);
    return i !== -1 && i + 1 < argv.length ? argv[i + 1] : null;
}

// The command a woken session may run to acknowledge. UNQUOTED unless it has to be quoted, and
// with the interpreter taken from the running process rather than from `PATH` -- a `PATH` entry may
// be a shim that re-launches the real interpreter as a child, leaving the process the host watches
// unrelated to the process that blocks.
// NO INTERPRETER NAME IS EMITTED. Writing `bash <aid>` would be a `PATH` lookup, which is the very
// thing rule 5 forbids: a `PATH` entry may be a shim, and which `bash` answers on a Windows machine
// with several installed is not something this adapter can know. The script carries its own shebang,
// so the path alone is the command.
async function main() {
    const argv = process.argv.slice(2);
    // Asked of the node rather than derived: a minted or renamed session's name is not its directory.
    // With no name resolvable there is no registered session here, so there is nothing to wait for.
    const name = argValue(argv, '--name') || await resolveSessionName('cursor');
    if (!name) {
        process.stdout.write('{}\n');
        return 0;
    }
    const hostTimeoutSec = hostTimeoutFromArgs(argv);

    if (!name) {
        process.stdout.write('{}\n');
        return 0;
    }

    // Decoded BOM-tolerantly, which on THIS host is not defensive: it is required.
    const payload = readHostPayload();

    // --- Re-entry -----------------------------------------------------------
    const loopCount = Number(payload.loop_count ?? 0);
    if (Number.isFinite(loopCount) && loopCount >= followupLimit()) {
        process.stdout.write('{}\n');
        return 0;
    }

    // --- The wait -----------------------------------------------------------
    // Self-bounded as well as node-bounded, so a node that stops answering mid-wait cannot make
    // this process outlive the host's willingness to listen.
    const guardMs = adapterGuardMs(hostTimeoutSec);
    const outcome = await armOnce({ name, hostTimeoutSec, timeoutGuardMs: guardMs });

    if (!outcome.ok || outcome.kind === 'timeout' || outcome.kind === 'shutdown') {
        process.stdout.write('{}\n');
        return 0;
    }

    const hints = wakeHints({ name, seq: outcome.delivered_seq, quoteStyle: 'powershell' });
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

    // This host's documented shape, and only this host's.
    process.stdout.write(`${JSON.stringify({ followup_message: text })}\n`);
    return 0;
}

// Only run when the host actually invoked this file. Without the guard, importing it to unit-test
// a helper would execute a whole wake attempt as a side effect of the import.
const invokedDirectly = process.argv[1] && process.argv[1].endsWith('cursor.mjs');

export { main };

if (invokedDirectly) main().then((code) => process.exit(code)).catch(() => {
    process.stdout.write('{}\n');
    process.exit(0);
});

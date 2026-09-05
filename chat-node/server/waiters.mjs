// chat-node/server/waiters.mjs -- the registry of who is currently listening.
//
// A LONG POLL, not a WebSocket. The requirement permits either, and long-poll is what a hook can
// hold: the adapter is a short-lived process the host starts and watches, so it needs a wait it
// can hold with an ordinary HTTP request and abandon by dying. A WebSocket would add a protocol
// and a heartbeat to solve a problem the hook lifetime does not have.
//
// THE REGISTRY IS A HINT, NEVER A FACT, and this is the load-bearing property rather than a
// caveat. A host may ABANDON an over-running hook instead of killing it: output discarded, wait
// abandoned, and the process left running with its socket still open. So a registered waiter means
// "somebody was listening when this was registered", never "somebody is listening now" and never
// "this session exists". Everything here is written to that standard:
//
//   - Nothing in the store depends on the registry. It is memory only, rebuilt from nothing on
//     restart, and losing it costs a waiting client one timeout and no message.
//   - A resolved wait carries no message body, only the news that something arrived. The client
//     reads the store. One source of truth for what a message says.
//   - Every registration is removed on close, on timeout, and on resolve, by the same path.

import { limits } from './settings.mjs';

export function createRegistry() {
    // channel id -> Set of waiters listening to that channel.
    const byChannel = new Map();
    // session name -> Set of waiters listening for that session's own situation to change.
    const bySession = new Map();

    function _add(map, key, waiter) {
        if (!map.has(key)) map.set(key, new Set());
        map.get(key).add(waiter);
    }
    function _remove(map, key, waiter) {
        const set = map.get(key);
        if (!set) return;
        set.delete(waiter);
        if (set.size === 0) map.delete(key);   // no empty buckets: `count()` must mean something
    }

    // One removal path for every way a wait can end -- resolved, timed out, or the client vanished.
    // Three separate teardowns would be three chances to leak a registration that no longer has a
    // reader, and the leaked-registration case is exactly what the host's abandon behaviour causes.
    function _release(waiter) {
        if (waiter.released) return false;
        waiter.released = true;
        clearTimeout(waiter.timer);
        if (waiter.channelId !== null) _remove(byChannel, waiter.channelId, waiter);
        _remove(bySession, waiter.sessionName, waiter);
        return true;
    }

    return {
        // `settle` is called with the outcome. It is the caller's job to write the response; this
        // module owns only who is listening and when they stop.
        register({ sessionName, channelId, timeoutMs, settle, onAbandon = null }) {
            const waiter = {
                sessionName,
                channelId: channelId ?? null,
                released: false,
                timer: null,
                settle,
            };
            _add(bySession, sessionName, waiter);
            if (waiter.channelId !== null) _add(byChannel, waiter.channelId, waiter);

            waiter.timer = setTimeout(() => {
                if (_release(waiter)) settle({ kind: 'timeout' });
            }, timeoutMs);
            // Do not hold the process open for a wait. A node with an armed waiter and nothing
            // else to do should still be able to exit.
            if (waiter.timer.unref) waiter.timer.unref();

            // The abandoned-client case, which is the normal one rather than the exceptional one:
            // a host that abandons its hook leaves this connection open with nobody reading it,
            // and the socket closing is the only signal that ever arrives.
            waiter.abandon = () => {
                if (_release(waiter) && onAbandon) onAbandon();
            };
            return waiter;
        },

        release: _release,

        // Wake everyone listening to a channel. Returns how many were woken, which is what makes
        // "the waiter count returned to what it was" checkable from outside.
        announceMessage({ channel_id, arrival_seq, from }) {
            const set = byChannel.get(channel_id);
            if (!set) return 0;
            let woken = 0;
            for (const waiter of [...set]) {
                // A sender is not woken by its own message. It knows: it just sent it, and the
                // send call already told it the arrival position.
                if (waiter.sessionName === from) continue;
                if (_release(waiter)) {
                    waiter.settle({ kind: 'message', arrival_seq });
                    woken += 1;
                }
            }
            return woken;
        },

        // Wake one session because its own situation changed.
        announceConnect({ session_name, channel }) {
            const set = bySession.get(session_name);
            if (!set) return 0;
            let woken = 0;
            for (const waiter of [...set]) {
                if (_release(waiter)) {
                    waiter.settle({ kind: 'connect', channel });
                    woken += 1;
                }
            }
            return woken;
        },

        // The operator-visible number, and the one AC-25 is checked against. It counts
        // REGISTRATIONS, which is the honest thing to count: whether a reader is still on the far
        // end of each one is precisely what this process cannot know.
        count() {
            let n = 0;
            for (const set of bySession.values()) n += set.size;
            return n;
        },

        countForChannel(channelId) {
            const set = byChannel.get(channelId);
            return set ? set.size : 0;
        },

        // Used only when the server shuts down: settle everything so no client is left holding a
        // response that will never be written.
        drain() {
            const all = [];
            for (const set of bySession.values()) for (const w of set) all.push(w);
            for (const waiter of all) {
                if (_release(waiter)) waiter.settle({ kind: 'shutdown' });
            }
            return all.length;
        },
    };
}

// The block a wait should use, given what the host will actually wait for.
//
// The arithmetic is the whole point of the flag and is stated here once so no caller re-derives it:
// block = min(long_poll_default, host_timeout - margin). An operator writing `timeout: 60` gets
// this product's 30 s long poll; one writing `timeout: 20` gets 15 s -- shorter than preferred and
// honoured, which is the point of bounding by what the host will wait for rather than by what the
// product would like.
//
// Where the host timeout is UNKNOWN it does NOT inherit the platform default. Measurement bounded
// one host's default at under 60 s and no tighter; whether it is also under this product's 30 s
// long poll was never established, and an adapter cannot rely on a bound nobody measured, in
// either direction. So the fallback is short enough to be safe under the shortest default known,
// accepting a shorter wait over a wake that never arrives with nothing reporting why.
export const UNKNOWN_TIMEOUT_BLOCK_MS = 10_000;

export function blockMsFor({ hostTimeoutSec = null } = {}) {
    const { longPollMs, adapterMarginMs } = limits();
    if (hostTimeoutSec === null || hostTimeoutSec === undefined || !Number.isFinite(Number(hostTimeoutSec))) {
        return { blockMs: Math.min(UNKNOWN_TIMEOUT_BLOCK_MS, longPollMs), basis: 'fallback-unknown-host-timeout' };
    }
    const budgetMs = (Number(hostTimeoutSec) * 1000) - adapterMarginMs;
    if (budgetMs <= 0) {
        // A timeout at or under the margin leaves no room to both wait and return. Refusing to
        // wait at all is right: a block that cannot finish before the host stops listening is the
        // leak this margin exists to prevent.
        return { blockMs: 0, basis: 'host-timeout-below-margin' };
    }
    return {
        blockMs: Math.min(longPollMs, budgetMs),
        basis: budgetMs < longPollMs ? 'bounded-by-host-timeout' : 'long-poll-default',
    };
}

// chat-node/server/settings.mjs -- every limit, read rather than hardcoded.
//
// Section 6 of the requirements opens by declaring itself the registry of every configurable
// parameter and states that no limit is hardcoded. This module is how that stays true: the
// defaults live here in one table, and each is overridable. A literal appearing at a call site
// somewhere in the core is the failure this file exists to prevent.
//
// The source of truth for project configuration is `.aid/settings.yml`, read through
// `read-setting.sh` -- the repository's rule is never to hand-parse that YAML in another
// script. The node is not a shell script, so rather than shelling out on every read it takes
// each value from the environment, which is where the CLI puts it after resolving it through
// the sanctioned reader. That keeps one parser for the YAML and one place for the defaults.

const DEFAULTS = {
    // Message TTL: the age at which a message becomes ELIGIBLE for removal. Age alone never
    // deletes an unacknowledged message -- the trim point decides that.
    ttlMs: 24 * 60 * 60 * 1000,
    // Max unread depth per member. A member this far behind is broken and the sender must
    // learn it, which is why overflow rejects rather than dropping the oldest.
    maxUnread: 1000,
    // Quiet past this: unavailable to a connect request, and nothing released.
    staleMs: 30 * 60 * 1000,
    // Quiet past this: given up for gone, its claim on the trim point dropped, and its
    // channel closed if it was the last member.
    reapMs: 24 * 60 * 60 * 1000,
    // How long a subscriber holds a wait before returning empty and re-arming.
    longPollMs: 30 * 1000,
    // How long a message waits for its immediate per-speaker predecessor before the hub
    // declares the gap permanent, releases the successor and records the skip. Without a
    // bound the hold-back rule does not terminate: a predecessor that never arrives holds
    // every later message from that sender forever, and silently.
    gapGraceMs: 60 * 1000,
    // How often the periodic jobs run. Not a policy value -- the policy is `ttlMs` and `reapMs` -- but
    // the granularity at which they are applied, and it is configurable for the same reason as the
    // rest: a test needs it small and an operator may want it large.
    jobIntervalMs: 60 * 1000,
    // The headroom an adapter leaves between its own block and the host's configured hook
    // timeout. Sized from measurement rather than taste: the observed wake-to-refire maximum
    // was 4.303 s and still rising as samples accumulated.
    adapterMarginMs: 5 * 1000,
};

const ENV = {
    ttlMs:           'AID_CHAT_TTL_MS',
    maxUnread:       'AID_CHAT_MAX_UNREAD',
    staleMs:         'AID_CHAT_STALE_MS',
    reapMs:          'AID_CHAT_REAP_MS',
    longPollMs:      'AID_CHAT_LONG_POLL_MS',
    gapGraceMs:      'AID_CHAT_GAP_GRACE_MS',
    adapterMarginMs: 'AID_CHAT_ADAPTER_MARGIN_MS',
    jobIntervalMs:   'AID_CHAT_JOB_INTERVAL_MS',
};

// Read on every call rather than cached, so a test or an operator changing a value takes
// effect without restarting the process. The cost is a handful of env reads.
export function limits() {
    const out = {};
    for (const [key, def] of Object.entries(DEFAULTS)) {
        const raw = process.env[ENV[key]];
        const n = raw === undefined || raw === '' ? NaN : Number(raw);
        out[key] = Number.isFinite(n) && n >= 0 ? n : def;
    }
    return out;
}

export { DEFAULTS as LIMIT_DEFAULTS, ENV as LIMIT_ENV };

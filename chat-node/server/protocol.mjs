// chat-node/server/protocol.mjs -- the inter-node protocol version, and the handshake rule.
//
// THE PROTOCOL VERSION IS ITS OWN NUMBER AND IS NEVER INFERRED FROM `VERSION`. The node ships inside
// the `aid` payload, so the artifact's version moves for reasons that have nothing to do with the
// wire: a documentation fix, a skill rename, an unrelated bug. Deriving the protocol from it would
// mean two hubs refusing each other because somebody corrected a typo, or -- far worse -- accepting
// each other after a genuine wire change that happened to ship in a patch release.
//
// So it moves only when the wire changes, and the rule for comparing it is stated once, here.

export const PROTOCOL_VERSION = '1.0.0';

export function protocolParts(v = PROTOCOL_VERSION) {
    const m = /^(\d+)\.(\d+)\.(\d+)/.exec(String(v || ''));
    if (!m) return null;
    return { major: Number(m[1]), minor: Number(m[2]), patch: Number(m[3]) };
}

// MAJOR-ONLY REFUSAL, by contract rather than by hope. A minor or patch difference is compatible
// because this rule says so, which puts the obligation on whoever changes the wire: an addition that
// an older peer cannot ignore is a MAJOR change, and calling it minor to avoid a refusal is the bug
// this rule exists to make impossible to hide.
//
// The refusal is explicit and carries both versions, because the alternative -- refusing silently,
// or half-working -- is the failure mode that costs an operator a day. A hub that accepted an
// incompatible peer and then mis-parsed its messages would look like message loss, and the cause
// would be nowhere near the symptom.
export function checkCompatibility(theirs, ours = PROTOCOL_VERSION) {
    const a = protocolParts(ours);
    const b = protocolParts(theirs);
    if (!b) {
        return {
            compatible: false,
            reason: 'protocol_unparseable',
            detail: `peer announced an unreadable protocol version: ${JSON.stringify(theirs)}`,
        };
    }
    if (a.major !== b.major) {
        return {
            compatible: false,
            reason: 'protocol_major_mismatch',
            detail: `peer speaks protocol ${theirs}, this hub speaks ${ours}; major versions must match`,
            ours, theirs,
        };
    }
    return { compatible: true, ours, theirs, major: b.major };
}

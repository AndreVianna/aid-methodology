// chat-node/server/node.mjs -- entry point for the agent chat node (the "hub").
//
// One hub runs per machine and serves every session on it, regardless of which tool
// hosts each session. It has a single responsibility -- message exchange -- and ships no
// operator surface of its own: every human-facing operation against it is an `aid`
// subcommand (FR-7.5).
//
// This file is the provisioning target: it exists so the component is real, listed in
// chat-node/MANIFEST, and provisioned by all five channels. Its routes, its store and its
// waiter registry are added by the tasks that own them -- the schema, the lifecycle, the
// message plane and the hub plane -- each of which extends this module rather than
// replacing it.
//
// Third-party dependencies: NONE, and that is a requirement rather than a coincidence
// (FR-7.6). The store is the built-in SQLite module, the transport is the built-in HTTP
// server, and discovery uses the built-in UDP socket module. `aid` itself declares zero
// third-party dependencies and this component must not be the thing that changes that.

// The PROTOCOL version, deliberately independent of the repository's VERSION file. The node
// ships inside the `aid` payload, so the artifact version moves for reasons the wire format
// does not; inferring one from the other is the defect FR-6.4 exists to prevent.
export const PROTOCOL_VERSION = '1.0.0';

function usage() {
    process.stderr.write('usage: node node.mjs --protocol-version\n');
    process.stderr.write('  The node is administered through the `aid` CLI, not directly.\n');
    return 2;
}

export function main(argv) {
    if (argv.includes('--protocol-version')) {
        process.stdout.write(`${PROTOCOL_VERSION}\n`);
        return 0;
    }
    return usage();
}

// `import.meta.main` is not available on the declared floor, so compare argv[1] instead.
if (process.argv[1] && process.argv[1].endsWith('node.mjs')) {
    process.exit(main(process.argv.slice(2)));
}

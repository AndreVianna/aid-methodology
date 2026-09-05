// chat-node/server/node.mjs -- entry point for the agent chat node (the "hub").
//
// One hub runs per machine and serves every session on it, regardless of which tool
// hosts each session. It has a single responsibility -- message exchange -- and ships no
// operator surface of its own: every human-facing operation against it is an `aid`
// subcommand (FR-7.5). Running this file directly is therefore not a supported path.
//
// This file is the provisioning target and deliberately nothing more: it exists so the
// component is real, listed in chat-node/MANIFEST, and delivered by all five channels. Its
// store, its HTTP routes and its waiter registry are added by the tasks that own them, each
// of which extends this module rather than replacing it.
//
// NOT here, deliberately: the protocol version. It is real and it matters -- the node ships
// inside the `aid` payload, so the artifact version moves for reasons the wire format does
// not, and inferring one from the other is the defect FR-6.4 exists to prevent -- but it is
// the version-handshake task's to introduce, at the stage where a second hub exists to
// negotiate with. Declaring it here would be that task's work done early and unreviewed.
//
// Third-party dependencies: NONE, and that is a requirement rather than a coincidence
// (FR-7.6). The store is the built-in SQLite module, the transport is the built-in HTTP
// server, and discovery uses the built-in UDP socket module. `aid` itself declares zero
// third-party dependencies and this component must not be the thing that changes that.

export function main() {
    process.stderr.write('chat-node: this component is administered through the `aid` CLI.\n');
    process.stderr.write('chat-node: see `aid chat --help`; it is not run directly.\n');
    return 2;
}

// `import.meta.main` is not available on the declared floor, so compare argv[1] instead.
if (process.argv[1] && process.argv[1].endsWith('node.mjs')) {
    process.exit(main());
}

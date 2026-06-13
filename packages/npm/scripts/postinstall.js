#!/usr/bin/env node
// postinstall.js - FF-4 eager notice on npm i -g aid-installer.
//
// Purpose:
//   Runs automatically as the `postinstall` npm script immediately after
//   `npm install -g aid-installer` completes.
//
//   A postinstall runs NON-INTERACTIVELY (RC-3 / SEC-1): it NEVER silently
//   mutates the machine.  Two behaviours:
//     AID_MIGRATE_YES=1  ->  spawn `aid update self --yes` which calls the
//                            FF-2 scan in non-interactive opt-in mode.
//     (default)          ->  print a one-line notice directing the user to
//                            run `aid update self` when ready (annotate + defer).
//
//   The version-sentinel in bin/aid (task-080) is the universal guarantee for
//   ALL install channels (pypi, curl, --ignore-scripts); this postinstall is the
//   npm-channel eager path only.  Failure here (any error) is non-fatal: we
//   catch all exceptions so the npm install never fails because of postinstall.
//
// Reference: feature-011-upgrade-migration SPEC FF-4 / RC-3 / OQ-3 / R16.

'use strict';

var spawnSync = require('child_process').spawnSync;
var path      = require('path');
var process   = require('process');

// packages/npm/scripts/postinstall.js is two levels below the package root.
var pkgRoot = path.join(__dirname, '..');

try {
    var env = Object.assign({}, process.env, { AID_INSTALL_CHANNEL: 'npm' });

    if (process.env.AID_MIGRATE_YES === '1') {
        // Non-interactive opt-in: spawn `aid update self --yes` which triggers
        // the FF-2 scan with AID_MIGRATE_YES=1 already set (or passed via --yes).
        // The scan runs in non-interactive mode and writes the DM-3 marker on
        // completion so the sentinel does not re-fire on the next aid invocation.
        var aidArgs;
        var aidCmd;
        var aidCmdArgs;
        if (process.platform === 'win32') {
            var ps1 = path.join(pkgRoot, 'bin', 'aid.ps1');
            aidCmd     = 'pwsh';
            aidCmdArgs = ['-NoLogo', '-NonInteractive', '-File', ps1, 'update', 'self', '--yes'];
        } else {
            var aidSh = path.join(pkgRoot, 'bin', 'aid');
            aidCmd     = 'bash';
            aidCmdArgs = [aidSh, 'update', 'self', '--yes'];
        }
        var res = spawnSync(aidCmd, aidCmdArgs, { stdio: 'inherit', env: env });
        // Non-fatal: ignore exit code / errors from the spawn.
    } else {
        // Default (non-interactive, no opt-in): annotate + defer (RC-3 / SEC-1).
        // Print a one-line notice; the version-sentinel fires on the next
        // interactive `aid` invocation (universal guarantee, R16).
        process.stdout.write(
            'AID installed. Run `aid update self` to migrate your repos to the latest format.\n'
        );
    }
} catch (e) {
    // Postinstall failure must NOT break `npm i -g` (NFR12 / RC-3).
    // Print a soft warning and exit 0.
    try {
        process.stderr.write('WARN: aid postinstall: ' + e.message + '\n');
    } catch (_) {}
}

process.exit(0);

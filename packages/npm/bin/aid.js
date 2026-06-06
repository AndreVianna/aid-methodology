#!/usr/bin/env node
// aid.js - npm channel shim for the AID CLI.
//
// Purpose:
//   Installed as the `aid` bin entry when the user runs `npm i -g aid-installer`.
//   Spawns the vendored bin/aid (bash) or bin/aid.ps1 (pwsh/powershell) with
//   AID_INSTALL_CHANNEL=npm injected into the child environment so that
//   `aid update self` prints the npm upgrade hint instead of re-bootstrapping.
//
// Runtime selection:
//   Windows  -> try pwsh first, then powershell (with -NoLogo -NonInteractive -File)
//   All else -> bash bin/aid
//
// argv forwarding: process.argv.slice(2) is spread as an array into spawnSync args
//   (no shell:true) so spaces and shell metacharacters in arguments are safe.

'use strict';

var spawnSync = require('child_process').spawnSync;
var path      = require('path');
var os        = require('os');
var process   = require('process');
var fs        = require('fs');

// packages/npm/bin/aid.js lives one level below the package root.
var pkgRoot = path.join(__dirname, '..');

var env = Object.assign({}, process.env, { AID_INSTALL_CHANNEL: 'npm' });

var userArgs = process.argv.slice(2);
var res;

if (process.platform === 'win32') {
    var ps1 = path.join(pkgRoot, 'bin', 'aid.ps1');
    var fixedFlagsPwsh = ['-NoLogo', '-NonInteractive', '-File', ps1];

    // Try pwsh (PowerShell 7+) first.
    res = spawnSync('pwsh', fixedFlagsPwsh.concat(userArgs), { stdio: 'inherit', env: env });

    if (res.error && res.error.code === 'ENOENT') {
        // Fallback to Windows PowerShell 5.1.
        res = spawnSync('powershell', fixedFlagsPwsh.concat(userArgs), { stdio: 'inherit', env: env });

        if (res.error && res.error.code === 'ENOENT') {
            process.stderr.write(
                'ERROR: aid: neither pwsh nor powershell found on PATH.' +
                ' Install PowerShell to use the aid CLI.\n'
            );
            process.exit(1);
        }
    }
} else {
    var aidSh = path.join(pkgRoot, 'bin', 'aid');
    res = spawnSync('bash', [aidSh].concat(userArgs), { stdio: 'inherit', env: env });

    if (res.error && res.error.code === 'ENOENT') {
        process.stderr.write(
            'ERROR: aid: bash not found on PATH.' +
            ' Install bash to use the aid CLI.\n'
        );
        process.exit(1);
    }
}

// Relay exit code (null when killed by signal).
if (res.status == null) {
    process.exit(res.signal ? 1 : 0);
} else {
    process.exit(res.status);
}

#!/usr/bin/env node
// vendor.js - Copy the 6 aid-cli source files from the repo root into the npm package.
//
// Run automatically as the `prepack` npm script so `npm pack` and
// `npm publish` always ship the current source.
//
// Source of truth is the repo root (two levels above packages/npm/).
// Destination is packages/npm/{bin,lib,VERSION} (gitignored; generated at pack time).
//
// Files copied (mirrors release.sh Step-5 aid-cli bundle):
//   bin/aid              -> packages/npm/bin/aid
//   bin/aid.ps1          -> packages/npm/bin/aid.ps1
//   bin/aid.cmd          -> packages/npm/bin/aid.cmd
//   lib/aid-install-core.sh  -> packages/npm/lib/aid-install-core.sh
//   lib/AidInstallCore.psm1  -> packages/npm/lib/AidInstallCore.psm1
//   VERSION              -> packages/npm/VERSION

'use strict';

var fs   = require('fs');
var path = require('path');

// packages/npm/scripts/vendor.js is three levels below repo root.
var repoRoot = path.join(__dirname, '..', '..', '..');
var pkgRoot  = path.join(__dirname, '..');

var copies = [
    ['bin/aid',                  'bin/aid'],
    ['bin/aid.ps1',              'bin/aid.ps1'],
    ['bin/aid.cmd',              'bin/aid.cmd'],
    ['lib/aid-install-core.sh',  'lib/aid-install-core.sh'],
    ['lib/AidInstallCore.psm1',  'lib/AidInstallCore.psm1'],
    ['VERSION',                  'VERSION'],
];

// Ensure destination directories exist.
var dirs = ['bin', 'lib'];
for (var i = 0; i < dirs.length; i++) {
    var d = path.join(pkgRoot, dirs[i]);
    if (!fs.existsSync(d)) {
        fs.mkdirSync(d, { recursive: true });
    }
}

var ok = true;
for (var j = 0; j < copies.length; j++) {
    var src  = path.join(repoRoot, copies[j][0]);
    var dest = path.join(pkgRoot,  copies[j][1]);
    try {
        fs.copyFileSync(src, dest);
        console.log('vendor: copied ' + copies[j][0] + ' -> packages/npm/' + copies[j][1]);
    } catch (e) {
        console.error('vendor: ERROR copying ' + src + ': ' + e.message);
        ok = false;
    }
}

if (!ok) {
    process.exit(1);
}

console.log('vendor: done. 6 files vendored into packages/npm/.');

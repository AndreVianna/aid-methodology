#!/usr/bin/env node
// vendor.js - Copy the aid-cli source files from the repo root into the npm package.
//
// Run automatically as the `prepack` npm script so `npm pack` and
// `npm publish` always ship the current source.
//
// Source of truth is the repo root (two levels above packages/npm/).
// Destination is packages/npm/{bin,lib,dashboard/,VERSION} (gitignored; generated at pack time).
//
// Files copied (mirrors release.sh Step-5 aid-cli bundle):
//   bin/aid              -> packages/npm/bin/aid
//   bin/aid.ps1          -> packages/npm/bin/aid.ps1
//   bin/aid.cmd          -> packages/npm/bin/aid.cmd
//   lib/aid-install-core.sh  -> packages/npm/lib/aid-install-core.sh
//   lib/AidInstallCore.psm1  -> packages/npm/lib/AidInstallCore.psm1
//   VERSION              -> packages/npm/VERSION
//
// Dashboard server+reader unit: the curated file set is NOT listed here -- it is read
// from the single-source manifest dashboard/MANIFEST (shared with install.sh, install.ps1,
// packages/pypi/scripts/vendor.py and release.sh; guarded by
// tests/canonical/test-dashboard-manifest.sh). This prevents a new dashboard source file
// from being silently omitted from the npm channel (the H1 lockstep failure mode).

'use strict';

var fs   = require('fs');
var path = require('path');

// packages/npm/scripts/vendor.js is three levels below repo root.
var repoRoot = path.join(__dirname, '..', '..', '..');
var pkgRoot  = path.join(__dirname, '..');

// Read the curated dashboard file set from the single-source manifest (dashboard/MANIFEST).
// One path per line, relative to dashboard/; #-comments and blank lines ignored.
function readDashboardManifest(root) {
    var text = fs.readFileSync(path.join(root, 'dashboard', 'MANIFEST'), 'utf8');
    // Split on CRLF or LF (a Windows checkout may carry \r\n); strip #-comments and
    // surrounding whitespace. Using /#.*/ (no $) + \r?\n split avoids the JS-regex gotcha
    // where '.' and '$' do not span a trailing '\r', which would leak comment lines.
    return text.split(/\r?\n/)
        .map(function (line) { return line.replace(/#.*/, '').trim(); })
        .filter(function (line) { return line.length > 0; });
}

var copies = [
    ['bin/aid',                          'bin/aid'],
    ['bin/aid.ps1',                      'bin/aid.ps1'],
    ['bin/aid.cmd',                      'bin/aid.cmd'],
    ['lib/aid-install-core.sh',          'lib/aid-install-core.sh'],
    ['lib/AidInstallCore.psm1',          'lib/AidInstallCore.psm1'],
    ['VERSION',                          'VERSION'],
];
// Append the dashboard server+reader unit from the shared manifest. MANIFEST itself is
// vendored too, so the npm payload is self-describing (in lockstep with vendor.py and
// release.sh, which also ship it).
copies.push(['dashboard/MANIFEST', 'dashboard/MANIFEST']);
readDashboardManifest(repoRoot).forEach(function (rel) {
    copies.push(['dashboard/' + rel, 'dashboard/' + rel]);
});

// Clean slate: remove any prior vendored payload (lib/ dir, dashboard/ dir, the vendored
// bin scripts, VERSION) so stray runtime artifacts or files from an older version never
// ship. Keep the committed shim bin/aid.js.
try { fs.rmSync(path.join(pkgRoot, 'lib'),       { recursive: true, force: true }); } catch (e) {}
try { fs.rmSync(path.join(pkgRoot, 'dashboard'), { recursive: true, force: true }); } catch (e) {}
['bin/aid', 'bin/aid.ps1', 'bin/aid.cmd', 'VERSION'].forEach(function (f) {
    try { fs.rmSync(path.join(pkgRoot, f), { force: true }); } catch (e) {}
});

// Ensure destination directories exist.
var dirs = ['bin', 'lib', 'dashboard/reader', 'dashboard/server'];
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
        fs.mkdirSync(path.dirname(dest), { recursive: true });
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

console.log('vendor: done. ' + copies.length + ' files vendored into packages/npm/.');

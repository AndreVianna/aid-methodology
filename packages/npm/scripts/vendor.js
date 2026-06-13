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
// Dashboard server+reader unit (12 files, curated -- excludes tests/ __pycache__ *.pyc README):
//   dashboard/home.html                   -> packages/npm/dashboard/home.html
//   dashboard/index.html                  -> packages/npm/dashboard/index.html
//   dashboard/reader/__init__.py          -> packages/npm/dashboard/reader/__init__.py
//   dashboard/reader/reader.py            -> packages/npm/dashboard/reader/reader.py
//   dashboard/reader/models.py            -> packages/npm/dashboard/reader/models.py
//   dashboard/reader/parsers.py           -> packages/npm/dashboard/reader/parsers.py
//   dashboard/reader/derivation.py        -> packages/npm/dashboard/reader/derivation.py
//   dashboard/reader/locator.py           -> packages/npm/dashboard/reader/locator.py
//   dashboard/server/server.py            -> packages/npm/dashboard/server/server.py
//   dashboard/server/server.mjs           -> packages/npm/dashboard/server/server.mjs
//   dashboard/server/reader.mjs           -> packages/npm/dashboard/server/reader.mjs
//   dashboard/server/__init__.py          -> packages/npm/dashboard/server/__init__.py

'use strict';

var fs   = require('fs');
var path = require('path');

// packages/npm/scripts/vendor.js is three levels below repo root.
var repoRoot = path.join(__dirname, '..', '..', '..');
var pkgRoot  = path.join(__dirname, '..');

var copies = [
    ['bin/aid',                          'bin/aid'],
    ['bin/aid.ps1',                      'bin/aid.ps1'],
    ['bin/aid.cmd',                      'bin/aid.cmd'],
    ['lib/aid-install-core.sh',          'lib/aid-install-core.sh'],
    ['lib/AidInstallCore.psm1',          'lib/AidInstallCore.psm1'],
    ['VERSION',                          'VERSION'],
    // Dashboard server+reader unit (12 files, curated).
    ['dashboard/home.html',              'dashboard/home.html'],
    ['dashboard/index.html',             'dashboard/index.html'],
    ['dashboard/reader/__init__.py',     'dashboard/reader/__init__.py'],
    ['dashboard/reader/reader.py',       'dashboard/reader/reader.py'],
    ['dashboard/reader/models.py',       'dashboard/reader/models.py'],
    ['dashboard/reader/parsers.py',      'dashboard/reader/parsers.py'],
    ['dashboard/reader/derivation.py',   'dashboard/reader/derivation.py'],
    ['dashboard/reader/locator.py',      'dashboard/reader/locator.py'],
    ['dashboard/server/server.py',       'dashboard/server/server.py'],
    ['dashboard/server/server.mjs',      'dashboard/server/server.mjs'],
    ['dashboard/server/reader.mjs',      'dashboard/server/reader.mjs'],
    ['dashboard/server/__init__.py',     'dashboard/server/__init__.py'],
];

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

console.log('vendor: done. 18 files vendored into packages/npm/.');

# task-063 EVIDENCE -- the coverage baseline re-bootstrapped

Closes BLUEPRINT criterion **7**.

## 1. A correction: the blocker was unfixed, not unfixable

This task was recorded **Blocked** on the grounds that `pwsh` had "no route" here -- `apt` has no
candidate, there is no root, no static binary was on the box and `dotnet` was absent. Every one of
those observations was true, and the conclusion drawn from them was **wrong**: the upstream
PowerShell tarball installs cleanly to `~/.local`, and `gawk` installs the same way from a `.deb`
extracted with `dpkg-deb -x` (plus `libsigsegv2`, its one missing shared library).

```
pwsh    7.4.6            (tarball -> ~/.local/pwsh)
gawk    5.2.1            (.deb -> ~/.local/gawk, awk symlinked to it)
node    v22.14.0
python3 3.12.3
```

**That also retired the long-standing "environment" findings.** With `gawk` present and
`LC_ALL=C`, the three suites written off across two gates as environment-blocked all pass:

```
test-domain-doc-matrix      PASS      (was: gawk 3-arg match())
test-dogfood-byte-identity  PASS      (was: same)
test-doc-set-mapping        PASS      (was: locale collation)
```

The honest reading is that "unfixable in this environment" had been asserted from a failed `apt`
rather than established, and it stood unchallenged through two gates.

## 2. The capture

```
$ bash tests/coverage-parity.sh collect --out tests/coverage-baseline.tsv
collect -> tests/coverage-baseline.tsv (7376 rows); provenance -> tests/coverage-baseline.meta
real 10m8s
```

`.meta` records the provenance the contract asks for, and the capture commit resolves to this
branch:

```
captured_utc:    2026-08-15T07:22:17Z
commit_sha:      54e2fc025342e0e6c72e1cf903082273eafe8d56   (= HEAD at capture)
runner_os:       Linux 6.12.94+ x86_64 GNU/Linux
pwsh_version:    7.4.6
node_version:    v22.14.0
python3_version: Python 3.12.3
```

It was **not** hand-edited: the `.tsv` is the collector's own output, so `.meta` cannot
desynchronise from it -- the failure mode the runbook warns about, and the one the previous
baseline's header records happening.

## 3. The shape matches §4c exactly

| key | before | after | §4c predicts |
|---|---|---|---|
| `CDP{i}a` | 59 | **95** | 95 |
| `CDP{i}b` | 59 | **95** | 95 |
| `CDP{i}c` | 59 | **95** | 95 |
| `CDP{i}d` | 58 | **94** | 94 |
| `CDP{i}e` | 34 | **34** | 34 |
| `CDP{i}f` | 34 | **34** | 34 |
| `CDP{i}g` | 34 | **34** | 34 |
| **CDP rows** | **337** | **481** | **+144** |

**+144, to the digit** -- the figure predicted before any run, and independently confirmed by the
PR's own CI run beforehand (180 added, 36 removed on that suite).

**One predicted figure was wrong, and the measurement wins.** §4c expects a `DMR` key count of
**46**; the baseline holds **43**. That is not a shortfall: the suite emits exactly 43 unique `DMR`
ids (`--verbose`, `sort -u`), the previous baseline also held 43, and the count did not move. 46
was an estimate in the DETAIL; 43 is what the corpus does.

Total data rows: 7241 -> **7376** (+135). The CDP delta is +144; the remainder nets down through
other suites, chiefly the five `test-downstream-worktree-entry.sh` `G2` labels that embed line
numbers and shifted when five descriptions were rewritten.

## 4. Committed as the criterion requires

Both files in **one** commit and nothing else:

```
$ git show --name-only HEAD
tests/coverage-baseline.meta
tests/coverage-baseline.tsv
```

136 test scripts showed as modified after the collect -- **mode-only**, zero content changes, from
the collector marking them executable exactly as CI's own step does. `core.fileMode` was set to
`false`, which is how the repository is maintained and what CI sets explicitly, so those never
entered the commit.

## 5. No secrets touched

`.aid/connectors/.secrets/` unchanged; `.meta` carries no credential -- only OS, runtime versions,
a timestamp and a commit sha.

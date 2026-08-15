# task-063 EVIDENCE -- the coverage baseline re-bootstrapped in CI

Closes BLUEPRINT criterion **7**. §§1-4 record a local attempt that failed and why; §5 records the run that worked.

## 1. Two of my earlier claims were wrong, and one was right for the wrong reason

**Wrong: "`pwsh` has no route here."** True that `apt` has no candidate and there is no root --
but the upstream PowerShell tarball installs cleanly to `~/.local`, and `gawk` installs the same
way from a `.deb` via `dpkg-deb -x` (plus `libsigsegv2`). Both worked first try.

```
pwsh 7.4.6   gawk 5.2.1   node v22.14.0   python3 3.12.3
```

**Wrong: three suites are "environment-blocked".** With `gawk` present and `LC_ALL=C`, all three
pass -- `test-domain-doc-matrix`, `test-dogfood-byte-identity`, `test-doc-set-mapping`. That
finding stood through two gates on the strength of a failed `apt`, and it should not have.

**Right, but not for the stated reason: the capture belongs in CI.** The runbook's rationale is
runtime completeness. That is not the binding constraint, as §3 shows.

## 2. The capture succeeded and the artifact was still invalid

```
$ bash tests/coverage-parity.sh collect --out tests/coverage-baseline.tsv
collect -> 7376 rows; provenance -> tests/coverage-baseline.meta        (10m8s)
```

The shape matched feature-006 §4c **exactly** -- `CDP a/b/c` 59 -> 95, `d` 58 -> 94, `e/f/g`
unchanged at 34, **+144 CDP rows**, the figure predicted before any run and independently
confirmed by the PR's earlier CI run (180 added, 36 removed).

CI then rejected it: **`RESULT: FAIL -- 229 un-excused reduction(s)`**.

## 3. Why -- and it is the real reason the capture belongs in CI

`collect` records **both** `PASS:` and `FAIL:` lines, because either proves the assertion ran. But
a `FAIL` label carries its failure detail -- `E2E01b ... expected '6' got '0'` -- so it is a
*different key* from the `PASS` label for the same assertion.

Two suites fail on this box for reasons unrelated to any runtime:

```
test-release-install-e2e.sh       FAIL   (needs a real release staging)
test-delivery-gate-aggregate.sh   FAIL
```

So the capture embedded their failure text as expected keys:

| | FAIL-labelled rows |
|---|---|
| previous baseline | **22** |
| my capture | **144** |

CI, where those suites pass, produces the PASS labels instead -- so all 122 extra keys read as
removals. **A baseline captured where some suites fail is worse than a stale one**: it silently
encodes those failures as the expected corpus, and every future run diffs against them.

That is the binding constraint the runbook is really protecting, and it is stronger than the
runtime-completeness reason it gives: the baseline must describe **the environment the gate runs
in**. No amount of local tooling satisfies that.

## 4. Reverted

The two files are restored to their previous state (7248 rows, 22 FAIL-labelled). Nothing else was
touched; the 136 mode-only churn from the collect run was kept out via `core.fileMode=false`, which
is how the repository is maintained.

## 5. The capture that worked -- in CI, as required

The owner dispatched the `coverage-parity` workflow with **`bootstrap: true`** on this branch
(run **31890557325**, `workflow_dispatch`, conclusion **success**). The `coverage-baseline`
artifact could not be fetched from here -- artifact downloads redirect to
`*.blob.core.windows.net`, which this environment's egress policy rejects (`gh run download` and
the API `zip` endpoint both fail there, and the allowed-domain list carries only
`cursor.blob.core.windows.net`) -- so the owner supplied the artifact directly.

**Provenance confirms it is CI's environment, not this one:**

```
runner_os:       Linux 6.17.0-1022-azure x86_64 GNU/Linux
pwsh_version:    7.6.4          node_version: v24.19.0     python3_version: 3.11.15
commit_sha:      544f2cff...    (on this branch)
captured_utc:    2026-08-15T14:49:05Z
```

Every runtime version differs from this box, which is precisely the point §3 makes.

**Every predicted figure holds:**

| | committed (stale) | CI capture | expected |
|---|---|---|---|
| `CDP{i}a` / `b` / `c` | 59 | **95** | 95 |
| `CDP{i}d` | 58 | **94** | 94 |
| `CDP{i}e` / `f` / `g` | 34 | **34** | 34 |
| CDP rows | 337 | **481** | **+144** |
| data rows | 7241 | **7385** | **+144** |
| unique `DMR` ids | 43 | **43** | 43 (the DETAIL's 46 was an estimate) |

**And the check the local attempt failed:**

```
FAIL-labelled rows:   previous baseline 22  |  CI capture 22  |  local attempt 144
```

22, matching the previous baseline -- so no failure text from any environment is baked in. That is
the single measurement that distinguishes a valid baseline from the invalid one §3 describes.

Committed as the criterion requires: both files, one commit, nothing else.

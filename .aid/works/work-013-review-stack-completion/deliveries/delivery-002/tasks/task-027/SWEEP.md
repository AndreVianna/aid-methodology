# task-027 — the COVERS sweep, and its residue of one

## The defect class

A suite that declares **no** `# COVERS:` line is treated by `select-suites.sh` as covering
everything, so it always runs. That is the fail-safe, and forgetting the header costs only time.

The dangerous case is the opposite one: a suite that **does** declare coverage but omits a file it
actually asserts against. It then looks covered, runs on unrelated changes, and is skipped by
precisely the change that would break it. The selector's own header says as much — "the one thing
that could lose coverage is a WRONG COVERS line".

## The two fixed here

| Suite | Omitted | Why it matters |
|---|---|---|
| `test-criterion-oracles.sh` | `canonical/agents/aid-reviewer/AGENT.md` | it asserts the agent file still says `7-column`; editing that file skipped the assertion |
| `test-scoped-review-cycles.sh` | `canonical/aid/scripts/grade.sh` | `SC15` runs the grader to prove the 7-column contract holds; editing the grader skipped the proof |

Measured before and after:

```
$ bash tests/canonical/select-suites.sh canonical/agents/aid-reviewer/AGENT.md | grep -c test-criterion-oracles
1     # 0 before
$ bash tests/canonical/select-suites.sh canonical/aid/scripts/grade.sh | grep -c test-scoped-review-cycles
1     # 0 before
```

The control, so the fix is not a selector widened into always-true:

```
$ bash tests/canonical/select-suites.sh README.md | grep -c 'test-criterion-oracles\|test-scoped-review-cycles'
0
```

And each suite's already-declared files still select it — `g07-selector-partition.sh` selects the
oracle suite, `reviewer-ledger-schema.md` selects the scoped suite. Both suites pass with their
assertion counts unchanged at 21 and 15.

## The residue: one, not zero

The class was swept across every suite that declares a `COVERS` line, comparing each declared glob
against the `canonical/` and `scripts/` paths the suite actually names. Raw output flagged three
suites; two are false positives and one is real.

| Suite | Flagged path | Verdict |
|---|---|---|
| `test-criterion-oracles.sh` | `canonical/agents/__g07probe__/NOTANAGENT.md` | **false positive** — a fixture the test creates and deletes; not on disk |
| `test-review-path-audit.sh` | five paths including `aid-screener/AGENT.md` | **false positive** — written into a temp root at lines 84-85 (`"${dir}/canonical/..."`), so they are fixture paths, not dependencies |
| `test-validator-behavior.sh` | `canonical/aid/scripts/summarize/grade-summary.sh` | **REAL** |

The discriminator is whether the path exists on disk: a fixture the suite creates under a temp root
is not a dependency, however much it looks like one in a grep.

### The real one

`test-validator-behavior.sh` extracts grep patterns **from `grade-summary.sh` at runtime**, and says
so in its own comment:

> Patterns are EXTRACTED from `grade-summary.sh` at runtime so this section cannot drift from the
> real patterns `grade-summary.sh` uses (a prior version hand-copied patterns with mis-escapes that
> could never fail for the reason claimed).

It declares three `COVERS` files and `grade-summary.sh` is not among them:

```
$ bash tests/canonical/select-suites.sh canonical/aid/scripts/summarize/grade-summary.sh \
    | grep -c test-validator-behavior
0
```

So a change to `grade-summary.sh` skips the one suite written to catch exactly that change — and
the comment records that hand-copied patterns had already failed silently once before.

**Route: task-042**, whose scope names a residue of one. It is recorded here rather than fixed
because task-027's scope is two header lines and no assertion logic, and because a residue reported
is the point — a sweep that narrows its own class to whatever it happened to fix proves nothing.

## Why the residue is not zero on purpose

A class sweep that returns zero residue is indistinguishable from a sweep that was never run
against a wide enough corpus. This one names its corpus (every suite declaring a `COVERS` line),
its discriminator (does the path exist on disk), and the single instance it leaves behind with the
task that owns it.

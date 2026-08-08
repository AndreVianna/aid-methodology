# Review Rubric — Executable family

**Members:** `CODE`, `TEST`, `CONFIG`, `INFRA`, `JOB`, `PIPELINE`, `MIGRATION`
**Kind:** A (adversarial content grade)
**Universal tier:** [`INDEX.md`](INDEX.md) — the defect taxonomy, the two authority ladders,
severity derivation and evidence admissibility all apply and are not restated here.

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

---

## What this family is for

An executable artifact **runs**. So unlike a definition artifact, most of its correctness is
mechanically checkable — and the rules below are weighted heavily towards `mechanical` mode for
exactly that reason. Where a check can be a command, it is one.

**Portability note.** Each `Criterion` cites a KB spine document and a section by name. Document
names are standard across AID installations; a given adopter's KB may not carry the cited *section*.
When the declaring section is absent the rule **cannot fire**, and the concern is a criteria gap
rather than a finding.

**The most common failure in this family is a rule that has no criterion.** "Write clean code",
"prefer composition", "keep functions short" — none of these is admissible unless the project's own
KB declares it. See `INDEX.md`'s admission rule: no `Criterion`, no row.

---

## Rules

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `EXE-01` | The project builds | `technology-stack.md § Build Commands` | MUST | mechanical | Run the declared build command; non-zero exit is the finding | `Step 2` |
| `EXE-02` | The declared linters pass | `technology-stack.md § Lint Commands` | MUST | mechanical | Run each declared lint command | `Step 2` |
| `EXE-03` | The declared test suites pass | `technology-stack.md § Test Commands`, `test-landscape.md § Test Commands` | MUST | mechanical | Run the declared suites; a failing assertion is the finding | `Step 2` |
| `EXE-04` | New behaviour is covered by a test at the level the project's strategy declares | `test-landscape.md § Test Data Strategy`, `§ Coverage Assessment` | MUST | judgment | Name the test that would fail if the new behaviour regressed. If none exists, that is the finding | `Step 2` |
| `EXE-05` | A script's exit codes follow the project's declared alphabet | `coding-standards.md § Exit Codes` | MUST | mechanical | Compare each `exit N` against the declared meaning for N | `Step 2` |
| `EXE-06` | Output goes to the declared stream — results to stdout, diagnostics to stderr | `coding-standards.md § Logging and Output` | MUST | mechanical | `grep` for diagnostics written to stdout, or results written to stderr | `Step 2` |
| `EXE-07` | Errors are handled as the project declares, not swallowed | `coding-standards.md § Error Handling` | MUST | judgment | Name each failure path and what it does. A silently-ignored failure is the finding | `Step 2` |
| `EXE-08` | Names follow the declared conventions | `coding-standards.md § Naming Conventions` | SHOULD | judgment | Compare each new identifier against the declared convention for its kind | `[LOW]; escaped (>1 file) → [MEDIUM]` |
| `EXE-09` | A script carries the declared file header | `coding-standards.md § File Header Convention` | MUST | mechanical | Check the first lines of each new script against the declared header shape | `Step 2` — one script header is confined → `[MEDIUM]`; widespread → escaped → `[HIGH]` |
| `EXE-10` | Language-specific conventions are followed for the language in question | `coding-standards.md § Shell (Bash) Conventions`, `§ PowerShell Conventions`, `§ Python Conventions`, `§ JavaScript / Node Conventions` | SHOULD | judgment | Apply the section matching the file's language. A file in a language the KB does not cover is a criteria gap, not a finding | `[LOW]; escaped (>1 file) → [MEDIUM]` |
| `EXE-11` | Configuration is read through the declared access path, not re-implemented | `coding-standards.md § Configuration Access` | MUST | mechanical | `grep` for direct reads of a config file where the declared accessor exists | `Step 2` |
| `EXE-12` | Security conventions are honoured — no secret in source, no unsafe execution of untrusted input | `coding-standards.md § Security Conventions` | MUST | judgment | Name each place untrusted input reaches an interpreter, a path, or a credential | `Step 2` |
| `EXE-13` | A load-bearing architectural boundary is not crossed | `architecture.md § Load-Bearing Boundaries`, `§ Invariants` | MUST | judgment | Name the boundary and the crossing. A boundary the KB does not declare is not a finding | `Step 2` |

---

## Notes for reviewers of this family

**Run `EXE-01` through `EXE-03` before reading anything.** They are three commands, they are the
project's own declared gates, and a red one usually explains whatever you were about to find by
inspection.

**`EXE-04` is the one that needs judgment and gets skipped.** "Is it tested?" is easy to answer
loosely. The disciplined form is: *name the test that would fail if this regressed*. If you cannot
name it, the behaviour is untested regardless of the coverage number.

**`EXE-10` and `EXE-13` both have an explicit no-criterion escape.** A language the KB does not
cover, or a boundary it does not declare, produces a **criteria gap** — not a finding at a softened
severity. That is the whole point of the admission rule.

---

## See also

- [`INDEX.md`](INDEX.md) — universal tier and routing
- [`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale) — severity derivation

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Thirteen rules, every `Criterion` verified against a heading that exists in the KB spine. |

# task-002: Build kb-language-lint.sh and add the additive --defined-extra flag to closure-check.sh

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-008-kb-plain-language -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Create `canonical/aid/scripts/kb/kb-language-lint.sh` per SPEC.md `#### Layer 2 -- the enforcement
  script`: flags `--root <repo>`, `--kb-dir <path>`, `--check glossary|frontmatter|all` (default
  `all`), `--verbose`, `-h/--help`; exit codes 0 clean, 1 findings, 2 usage.
- Glossary path (SPEC.md `#### Flow A`): run `harvest-coined-terms.sh` twice (`--root <repo>` and
  `--root <kb-dir>`) with a non-truncating `--top`, concatenate and deduplicate the two
  `## Ranked Candidates` tables into `.aid/.temp/kb-language/candidates.md`, extract the glossary's
  table-defined terms into a `--defined-extra` file, then call `closure-check.sh` with `--concepts`,
  `--spine`, `--kb-dir`, `--dismissed .aid/knowledge/.glossary-dismissed.txt`, `--defined-extra`,
  and `--output-a`, and convert each output-(a) row into
  `  [GLOSSARY-GAP] <doc>: coined term "<term>" has no domain-glossary.md definition`.
- Frontmatter path (SPEC.md `#### Flow B`): own the counting inside this script -- `objective:` is
  one physical line of at most 25 whitespace-delimited words; `summary:` is at most 2 sentences
  (split on `.`, `?`, `!` followed by whitespace or end-of-line) of at most 30 words each with at
  most 1 em-dash. Select docs with the same single-pass awk contract `lint-frontmatter.sh` uses
  (`kb-category:` in {primary, extension}, `source:` not `generated`; meta and generated docs
  skipped). Emit `  [LANG-FRONTMATTER] <doc>: <description>`.
- Add exactly one optional flag, `--defined-extra <file>`, to
  `canonical/aid/scripts/kb/closure-check.sh`: its lines are unioned into the defined-identifier set
  before normalization. Absent by default, and the default invocation must stay byte-identical to
  today's (AC-17). No other change to that script.
- Follow the family's conventions: bash only (no PowerShell twin -- `canonical/aid/scripts/kb/` is a
  bash-only family), ASCII-only, `set -euo pipefail` (relaxed to `set -uo pipefail` only where a
  non-zero `grep` must be tolerated, as `kb-citation-lint.sh` does), and a header block with
  Purpose/Usage/Exit codes per `coding-standards.md`.
- Out of scope here: the durable fixture pair and suite (task-003), the CI and oracle wiring
  (task-005), the canonical rule prose (task-004), and the `profiles/` render (task-014).

**Acceptance Criteria:**
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --help` prints usage and exits 0; an unknown
      flag exits 2; a clean run exits 0 and a run with findings exits 1.
- [ ] `--check glossary` builds `.aid/.temp/kb-language/candidates.md` from both harvests, and the
      merged table contains at least one term that the `--root <repo>` harvest alone does not produce
      (proving the second, KB-rooted harvest is actually contributing).
- [ ] On a scratch KB under `mktemp -d` containing a doc that introduces a coined term with no
      glossary entry and no dismissal row, the lint exits 1 and prints a `[GLOSSARY-GAP]` line naming
      that term; with a `### ` entry added for the same term it exits 0 -- the mechanism AC-7 is proven
      against. (Smoke check only; the durable fixture pair is task-003's.)
- [ ] `--check frontmatter` emits `[LANG-FRONTMATTER]` for a 38-word `objective:` and for a
      `summary:` exceeding 2 sentences / 30 words / 1 em-dash, and emits nothing for their in-bounds
      twins; the finding line shape matches `  [TAG] <doc>: <description>` (AC-4).
- [ ] `closure-check.sh --defined-extra <file>` unions the file's terms into the defined set, and
      `bash tests/canonical/test-closure-check.sh` still passes with the flag absent -- the default
      path is unchanged (AC-17).
- [ ] Reading the script's invocation set shows no tool outside bash, coreutils, awk, git, and
      optional ripgrep, and `AID_HARVEST_NO_RG=1 bash canonical/aid/scripts/kb/kb-language-lint.sh
      --root .` produces findings identical to the default run (AC-13).
- [ ] `bash tests/canonical/test-ascii-only.sh` passes over both scripts, and no `.ps1` twin is added
      to `canonical/aid/scripts/kb/`.
- [ ] All section-6 quality gates pass.

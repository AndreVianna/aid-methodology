# Test Landscape

> **Source:** aid-discover (discovery-quality)
> **Status:** Populated (initial dogfood pass)
> **Last Updated:** 2026-05-21
> **Cross-references:** `project-index.md` (file inventory), `project-structure.md:222-232` (Build/Test/CI absence)

## TL;DR

**There is no traditional test suite in this repository, and no CI/CD.** This is a methodology + multi-tool install-bundle repo (353 files, 49,226 lines; 70.6% Markdown, 11.1% Shell, 7.0% JavaScript). The closest analogues to "tests" are:

1. **Runtime quality scripts** that ship to user projects via the `aid-summarize` skill (validate generated HTML, links, Mermaid diagrams, contrast).
2. **Skill pre-flight scripts** that gate AID skills on a user's project (verify-kb, check-preflight).
3. **Manual contributor discipline** documented in `CONTRIBUTING.md`.
4. **The AID methodology's own quality gates** (REVIEW mode in Discover, review loop in Execute, deterministic grading via `grade.sh`).

None of these exercise this repo's own artifacts. The repo ships untested.

## Search Results — Conventional Test Indicators

| Pattern | Found | Notes |
|---------|-------|-------|
| `tests/`, `test/`, `spec/` | None at repo level | `templates/reports/test-report-template.md` is a template, not a test file |
| `*.test.{js,ts,py,go,java}` | None | — |
| `*_test.go`, `*Test.java`, `test_*.py` | None | — |
| `pytest.ini`, `jest.config.*`, `vitest.config.*`, `mocha.opts`, `karma.conf.*` | None | — |
| `package.json` (which could declare a test runner) | None | No JS/TS project metadata at root or in any tree |
| `.github/workflows/*` | None | Confirmed by `project-index.md` Notable Files (which would list CI configs) |
| `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`, `.circleci/` | None | — |

Search method: `Glob` patterns for the above + `Grep` over `project-index.md`'s Full File Inventory. The only files matching `*test*` are `templates/knowledge-base/test-landscape.md` (the KB template) and `templates/reports/test-report-template.md` — both are templates *for downstream user projects*, not tests of this repo.

## Validation / Quality Scripts (Runtime, Ship to User Projects)

### 1. `aid-summarize` Validation Suite

These run inside the `aid-summarize` skill (state machine PREFLIGHT -> STALE-CHECK -> PROFILE -> GENERATE -> VALIDATE -> FIX -> APPROVAL -> WRITEBACK -> DONE) against the HTML it just generated. They live under `templates/knowledge-summary/scripts/` and are copied into each install tree (4 copies each).

| Script | Lines | Language | Purpose | Invoked at |
|--------|-------|----------|---------|------------|
| `validate-html.sh` | 94 | Bash | Structural + accessibility checks on generated `knowledge-summary.html` — verifies semantic landmarks (`html lang`, `header role=banner`, `main`, `nav`, `footer`, `title`), ARIA on lightbox dialog, `prefers-reduced-motion` media query, `:focus-visible`, skip-link, noscript fallback, color-scheme declaration, inlined Mermaid library, and at least one `pre class="mermaid"` block. | VALIDATE state of `aid-summarize` |
| `validate-links.sh` | 78 | Bash | Verifies in-page anchor `href="#..."` links resolve to in-page `id="..."` attributes, and relative markdown links `href="./*.md"` resolve to existing files. | VALIDATE state of `aid-summarize` |
| `validate-diagrams.mjs` | 294 | Node.js | Extracts every `pre class="mermaid"` block; calls `mmdc` (Mermaid CLI) to parse and render each. Falls back to regex sanity check if `mmdc` is unavailable. Exit 0 on success, 1 on failure, 2 on invocation error. Has `--fast` flag (skip `mmdc`). | VALIDATE state of `aid-summarize` |
| `contrast-check.mjs` | 151 | Node.js | Extracts CSS variables from inlined `style` block, verifies WCAG AA contrast ratios for known token pairs in both light and dark themes. | VALIDATE state of `aid-summarize` |
| `check-preflight.sh` | 100 | Bash | Pre-flight gate for `aid-summarize`. Verifies (1) `DISCOVERY-STATE.md` exists, (2) `**User Approved:** yes` is set, (3) at least one KB doc is populated (more than 30 non-blank lines, not just "Pending"), (4) Plan Mode not active, (5) npm registry reachable (skippable with `--cdn-mermaid`), (6) Node.js >= 18. | PREFLIGHT state of `aid-summarize` |
| `stale-check.sh` | 93 | Bash | Compares latest dates in DISCOVERY-STATE.md's "Review History" vs. "Summarization History" tables. Emits `STALE` / `CURRENT_APPROVED` / `CURRENT_UNAPPROVED` / `FIRST_RUN`. Lexical date comparison (works for `YYYY-MM-DD`). | STALE-CHECK state of `aid-summarize` |
| `fetch-mermaid.sh` | 77 | Bash | Downloads Mermaid library from npm for inlining. | GENERATE state of `aid-summarize` |
| `concatenate.sh` / `concatenate.ps1` | 23 / 36 | Bash / PS | Concatenates section markdown files into a single working document. | GENERATE state of `aid-summarize` |
| `writeback-discovery-state.sh` | 138 | Bash | Appends a new entry to DISCOVERY-STATE.md's "Summarization History" after VALIDATE passes and the user approves. | WRITEBACK state of `aid-summarize` |
| `grade.sh` (knowledge-summary variant) | 194 | Bash | Deterministic A+/A/B/C/D/F grading for the HTML, based on weighted check results from validate-html.sh, validate-links.sh, validate-diagrams.mjs, contrast-check.mjs. **Any unparseable Mermaid diagram = automatic F.** Distinct from the top-level `templates/scripts/grade.sh` (141 lines), which grades general issue lists. | VALIDATE state of `aid-summarize` |

**Scope:** *User runtime, not this repo.* These scripts run when a user invokes `/aid-summarize` against their own KB to produce `.aid/knowledge/knowledge-summary.html`. They do not exercise any file in this repository.

### 2. `aid-discover` Pre-Flight Scripts

| Script | Lines | Language | Purpose | Invoked at |
|--------|-------|----------|---------|------------|
| `claude-code/.claude/skills/aid-discover/scripts/check-preflight.sh` | 45 | Bash | Verifies (1) `DISCOVERY-STATE.md` exists and is non-empty (init has run), (2) Plan Mode not active (env-var heuristic). Exits 1 if init not run, 2 if Plan Mode. | Step 0a of `aid-discover` |
| `claude-code/.claude/skills/aid-discover/scripts/verify-kb.sh` | 60 | Bash | After discovery, verifies all 16 expected KB files exist in the target directory. Used to detect which sub-agents need re-dispatch. Note: hardcoded list of 16 files (does not include `additional-info.md`). | Post-generation step of `aid-discover` |

**Scope:** *User runtime.* These ship only in the Claude Code tree (`claude-code/.claude/skills/aid-discover/scripts/`); the Codex and Cursor trees inline equivalent logic into their longer SKILL.md bodies.

### 3. Build / Index Scripts (Runtime)

| Script | Lines | Language | Purpose |
|--------|-------|----------|---------|
| `templates/scripts/build-project-index.sh` | 368 | Bash | Step 0c pre-pass for `aid-discover`. Emits `.aid/knowledge/project-index.md` so the 5 discovery sub-agents share a common file inventory. Duplicated 4x across `templates/` + 3 install trees (identical content). |
| `templates/scripts/grade.sh` | 141 | Bash | Deterministic grade calculation from a Reviewer's structured issue list. **Same input -> same grade.** Duplicated 4x across `templates/` + 3 install trees (verified identical to `claude-code/.claude/templates/scripts/grade.sh` by `diff`). |

## Test Commands

There is no test runner in this repository. The closest "test commands" are:

```bash
# Validate a generated knowledge-summary HTML (user-side, after running /aid-summarize)
bash templates/knowledge-summary/scripts/validate-html.sh path/to/knowledge-summary.html
bash templates/knowledge-summary/scripts/validate-links.sh path/to/knowledge-summary.html
node templates/knowledge-summary/scripts/validate-diagrams.mjs path/to/knowledge-summary.html
node templates/knowledge-summary/scripts/contrast-check.mjs path/to/knowledge-summary.html

# Verify a user-project KB has all 16 expected docs (user-side, after /aid-discover)
bash claude-code/.claude/skills/aid-discover/scripts/verify-kb.sh .aid/knowledge/

# Compute a deterministic grade from a Reviewer's issue list
bash templates/scripts/grade.sh < reviewer-output.json
```

**No command runs against this repo's own source artifacts.**

## CI/CD Integration

**None.** No `.github/workflows/`, no `.gitlab-ci.yml`, no Jenkinsfile, no Azure Pipelines, no CircleCI config, no Travis. Confirmed by:

- `project-index.md` Notable Files lists only `CONTRIBUTING.md`, `LICENSE`, `README.md` — CI configs are detected by name and would appear here.
- `project-structure.md:225` explicitly states "No CI configuration found."
- No `node_modules`, `package.json`, or other artifacts that would imply a JS-based CI runner.

This means there is **no automated check** that:
- The 3 install trees stay in sync (`triplication drift`).
- The installer scripts (`setup.sh` / `setup.ps1`) actually copy what they say they copy.
- Skill or agent frontmatter is well-formed.
- The shell scripts pass `shellcheck`.
- Mermaid examples in `methodology/aid-methodology.md` render.
- Cross-document references (e.g., `templates/README.md -> templates/reports/track-report-template.md`) actually resolve.

## Testing Patterns

### Manual Quality Discipline (CONTRIBUTING.md)

`CONTRIBUTING.md:21-26` is the de-facto QA process:

> When updating a skill or agent, update ALL locations:
> 1. `skills/aid-{phase}/README.md` — human docs
> 2. `claude-code/skills/aid-{phase}/SKILL.md` — LLM version
> 3. `codex/skills/aid-{phase}/SKILL.md` — LLM version (shared body, Codex-specific frontmatter)
>
> Same for agents: update the human README, Claude Code .md, and Codex .toml.

Cursor is documented separately in `cursor/README.md`. The CONTRIBUTING guide does NOT explicitly mention the cursor tree in the triplication rule even though Cursor is a fully-shipped 4th target — this is an inconsistency between docs and reality.

Additional CONTRIBUTING constraints:
- `CONTRIBUTING.md:75` — "For examples: Add to `examples/` with a `README.md` explaining context. **Anonymize everything.**"
- `CONTRIBUTING.md:97` — "Under 500 lines per skill (AgentSkills best practice)" — currently violated for Codex/Cursor `aid-discover` (1,078 / 1,090) and `aid-interview` (694 / 698) SKILL.md files.

### The Methodology's Inherited Quality Posture

AID itself defines runtime quality gates. While none enforce quality of *this repo*, they apply to user projects:

| Phase | Gate | Mechanism | Owner |
|-------|------|-----------|-------|
| Init | Plan-mode check | `check-preflight.sh` | aid-init skill |
| Discover | REVIEW state — DISCOVERY-STATE.md must reach grade >= Minimum (default A) | discovery-reviewer agent + `grade.sh` | aid-discover skill |
| Specify | GAP.md when KB insufficient or requirements ambiguous | Architect agent (manual emission) | architect agent |
| Execute | Per-task review loop — reviewer issues -> `grade.sh` -> fix-or-pass | reviewer agent + `grade.sh` | aid-execute skill |
| Deploy | Full build + test verification before PR creation | operator agent (calls user's existing build/test) | aid-deploy skill |
| Monitor | Production findings classified and routed | monitor skill + monitor agent | aid-monitor skill |
| Summarize | HTML quality gates (validate-html, validate-links, validate-diagrams, contrast-check, grade.sh) — must pass before WRITEBACK | scripts above + Reviewer | aid-summarize skill |

These are *the methodology's QA story for user projects*. They demonstrably work (`examples/data-pipeline/README.md:43-50` — Grade A validation caught an LLM hallucination of $8,524 vs. $44,018). But none of them protect this repository itself from drift, typos, broken links, or incompatible vendor format changes.

## Gaps — Test/QA Coverage of This Repository

Each gap below is real, not hypothetical, and each carries a measurable risk for adopters.

### [HIGH] No CI runs on PRs
**Evidence:** No `.github/workflows/` anywhere in the tree.
**Impact:** A PR can introduce broken shell syntax, malformed frontmatter, missing files, or triplication drift without any automated signal. The Reviewer is the human maintainer; nothing else.
**Remediation (suggested):** Add a `.github/workflows/validate.yml` that runs `shellcheck` over `**/*.sh`, `yamllint` over agent frontmatter, and a custom diff script that fails when SKILL.md bodies drift across trees beyond an expected delta.

### [HIGH] No triplication-drift checker
**Evidence:** `CONTRIBUTING.md:21-26` requires manual propagation; no automated equivalent exists. `aid-discover/SKILL.md` is 453 / 1,078 / 1,090 lines (Claude Code / Codex / Cursor) — 2.4x variance — undetected by tooling.
**Impact:** A bug fix applied only to `claude-code/.claude/skills/aid-discover/SKILL.md` silently leaves the Codex and Cursor versions stale. Users of those tools get an outdated experience.
**Remediation (suggested):** Script that for each `aid-*/SKILL.md`, diffs the bodies and asserts a maximum allowed delta — or, better, normalizes via a transform that strips Codex/Cursor-specific inlining and compares the resulting canonical body.

### [HIGH] No smoke test of any AID skill end-to-end
**Evidence:** No script invokes a full skill against a sample project. The `examples/` directory contains anonymized *outputs*, not test fixtures with expected-output diffs.
**Impact:** A subtle frontmatter break, a script regression, or a permission allow-list mistake can ship without anyone noticing until a user opens an issue.
**Remediation (suggested):** A scripted run of `setup.sh` against `examples/brownfield-enterprise/` followed by `bash claude-code/.claude/skills/aid-discover/scripts/check-preflight.sh` and `verify-kb.sh` would catch the most basic regressions.

### [MEDIUM] No schema validation of SKILL.md or agent frontmatter
**Evidence:** No JSON Schema / Ajv config / `actionlint`-style validator in the repo.
**Impact:** A typo in `allowed-tools:` or a missing `model:` field passes review silently; the host AI tool may then ignore the file or behave unexpectedly.
**Remediation (suggested):** A simple Python or Node validator that parses every `**/SKILL.md`'s YAML frontmatter and every `codex/.codex/agents/*.toml`, asserts required fields, and checks values against an allow-list (e.g., `model` in `{opus, sonnet, haiku}`).

### [MEDIUM] No verification that installer scripts produce a working tree
**Evidence:** `setup.sh` and `setup.ps1` exist but have no test coverage.
**Impact:** A `cp -r` rule mistake, a missing path translation between Bash and PowerShell, or a Windows-specific quoting bug can break installs without anyone noticing.
**Remediation (suggested):** A `test-install.sh` that creates a temp directory, runs `setup.sh tmp/` for all three tools, then asserts expected paths exist and `diff -r` shows zero diff against the source tree (modulo the `--force` interactive behavior).

### [MEDIUM] No spell-check / link-check on this repo's markdown
**Evidence:** The `aid-summarize` validation scripts check links in generated *user* HTML, but no equivalent runs on this repo's own README.md, CONTRIBUTING.md, methodology/aid-methodology.md, or the 249 markdown files.
**Impact:** Broken anchors and dead URLs in the methodology document degrade adopter experience. `templates/README.md` already references two files that do not exist (`track-report-template.md` and `MONITOR-STATE.md`) — see `tech-debt.md`.
**Remediation (suggested):** `lychee` or `markdown-link-check` in a GitHub Action.

### [LOW] No unit coverage of `build-project-index.sh` or `grade.sh`
**Evidence:** Both are 100+ line Bash programs with no tests. `build-project-index.sh` (368 lines) is the file every discovery sub-agent consumes — a regression here cascades into 5 sub-agents reading wrong data. `grade.sh` (141 lines) determines whether work advances or returns for revision.
**Impact:** A grading bug silently lets bad work through the gate or blocks good work indefinitely.
**Remediation (suggested):** A `bats` test suite with golden inputs/outputs for each — at minimum, "empty input -> A+", "1 critical -> F", "5 minor -> A", etc.

## Cross-References

- `tech-debt.md` — Triplication drift (HIGH), missing CI (HIGH), placeholder templates (MEDIUM), file-size guideline violations (LOW)
- `security-model.md` — Permission allow-list shape (LOW); the lack of CI also affects security regression detection
- `infrastructure.md` — Distribution mechanism details

WARNING: All "no X found" claims above are based on the file inventory in `project-index.md` and targeted `Glob`/`Grep` searches. They are accurate for the tracked file set as of 2026-05-21.

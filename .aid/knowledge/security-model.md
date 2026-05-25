# Security Model

> **Source:** aid-discover (discovery-quality)
> **Status:** Populated (initial dogfood pass)
> **Last Updated:** 2026-05-23 (LOW: stale path refs FIX cycle 11)
> **Cross-references:** `external-sources.md` (vendor tool docs + local cross-reference), `project-structure.md:34-35` (this repo's own settings), `infrastructure.md` (canonical/ + run_generator.py trust chain). Paths cited in this doc may live in `canonical/agents/`, `canonical/skills/` (canonical authority post work-002) or `profiles/{claude-code,codex,cursor}/` (generator output).

## Framing

This repo is **a docs-and-skills bundle, not a runtime system.** It has no auth, no sessions, no users, no PII processing. Its security surface is entirely about:

1. **What the shipped skills tell a host AI tool to do** when a user installs them into their project.
2. **What permission grants each host tool's settings allow** when those skills run.
3. **What sensitive data may flow into discovery output** (`.aid/knowledge/`) when AID is run against a user's codebase.
4. **What trust chain a user implicitly accepts** by `git clone`-ing the repo and running `setup.sh`.

Where threats apply to a *user's project* rather than this repo, we say so. Each finding is rated **[CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [INFO]**.

WARNING: Security assessment is from static analysis only. No dynamic testing has been performed.

## 1. Permission Models — Per Host Tool

### 1.1 Claude Code — `.claude/settings.json` Allow-Lists

**This repo's own `.claude/settings.json`** (used during this dogfood discovery — not shipped to users):

```json
{
  "permissions": {
    "allow": [
      "Bash(mkdir -p \"C:/Projects/Personal/AID/profiles/claude-code/.claude/templates/scripts\" ...)",
      "Bash(cp \"C:/Projects/Personal/AID/templates/scripts/grade.sh\" ...)",
      "Bash(chmod +x \"C:/Projects/Personal/AID/profiles/claude-code/.claude/templates/scripts/grade.sh\" ...)",
      "Bash(chmod +x \"C:/Projects/Personal/AID/templates/scripts/build-project-index.sh\")",
      "Bash(cp \"C:/Projects/Personal/AID/templates/scripts/build-project-index.sh\" ...)",
      "Bash(chmod +x C:/Projects/Personal/AID/profiles/claude-code/.claude/templates/scripts/build-project-index.sh ...)"
    ]
  }
}
```

Analysis:
- Allow-list is **narrow** — explicit `mkdir`, `cp`, and `chmod` commands with absolute paths. This is good hygiene: no wildcards, no broad `Bash(*)` grant.
- No deny-list. Everything not in the allow list prompts the user.
- All allowed commands target the repo's own template-propagation workflow (copying `grade.sh` and `build-project-index.sh` into the three install trees) — i.e., dogfood housekeeping.

**Install payload's `profiles/claude-code/CLAUDE.md`** does NOT ship a `profiles/claude-code/.claude/settings.json`. Searched: no such file exists in the install tree. Users get whatever default Claude Code permission posture applies to their machine. *This is by design* — the methodology does not impose a permission policy on users; it leaves that decision to the adopter.

[INFO] **Permission allow-list is narrow and well-formed** in this repo's own settings.

### 1.2 The `.claude/settings..json` Double-Dot File — **HISTORICAL (file removed 2026-05-25)**

> **Status:** The double-dot file `.claude/settings..json` was removed from the repository. The analysis below is preserved as a record of the bug that previously existed. See `project-structure.md` Anomaly #2 for current state.


`.claude/settings.json` (the historical double-dot typo file `.claude/settings..json` was removed; see `project-structure.md` Anomaly #2) exists alongside `.claude/settings.json` (see `project-structure.md` anomaly #2). Diffing (verified 2026-05-21):

```
$ diff .claude/settings.json .claude/settings..json
# Returns whitespace-only differences (trailing newline) — files are effectively identical.
```

Content is **effectively** identical (only a trailing-newline difference per reviewer spot-check #16; earlier wording said "no output" which was imprecise). The double-dot is a typo. Claude Code will not load this file as a settings file, so it has no security effect. But because it is **not gitignored**, it is committed.

[LOW] **Filename typo committed to repo.** Cosmetic; no functional security impact, but it should be deleted to avoid future confusion about which file is authoritative. See `tech-debt.md`.

### 1.3 Codex CLI — TOML Agents with `developer_instructions`

Codex agents (`profiles/codex/.codex/agents/*.toml`) inline the entire system prompt in the `developer_instructions` triple-quoted string. There is no separate skill body for Codex agent execution — the agent's *entire* behavioral charter is in TOML.

Spot-check of `profiles/codex/.codex/agents/operator.toml`:
- 38 lines, `model = "gpt-5.4"`, `model_reasoning_effort = "medium"`.
- `developer_instructions` includes the rule "Safety-first. If anything is uncertain, stop and ask. Never \"just try\" with production." **(Note: this quote is in `operator.toml`, not `developer.toml` as an earlier draft of this section claimed — correction per reviewer spot-check.)**
- No secrets, no API keys, no embedded credentials.

Spot-check of `profiles/codex/.codex/agents/developer.toml`:
- 17 lines. Brief instructions: read SPEC.md, follow KB, run build (`mvn clean verify -f ProjectRoot/pom.xml`), run tests.
- The hardcoded `mvn` command and `ProjectRoot/pom.xml` path are **suspicious** — they appear to be a template fragment that escaped anonymization (or were intended as an example). They would direct any user's Codex Developer agent to attempt to build a Maven project at a path the user may not have.

[MEDIUM] **`profiles/codex/.codex/agents/developer.toml:11-12` hardcodes Maven build commands** with a path (`ProjectRoot/pom.xml`) that is almost certainly a leftover from an example, not a placeholder template. A user installing Codex agents into a non-Java project gets a Developer agent that will try to run `mvn clean verify` regardless. See `tech-debt.md`.

### 1.4 Cursor — `.mdc` Rules with `alwaysApply`

`profiles/cursor/.cursor/rules/aid-methodology.mdc` (29 lines):
```yaml
---
description: "AID methodology workflow and Knowledge Base integration"
alwaysApply: true
---
```

`profiles/cursor/.cursor/rules/aid-review.mdc` (11 lines):
```yaml
---
description: "Code review standards for AID methodology"
globs: "**/*.{java,py,ts,js,cs,go,rs}"
alwaysApply: false
---
```

**Security implication:** `alwaysApply: true` means the content of `aid-methodology.mdc` is injected into *every prompt* Cursor sends to the model for this project. The content (lines 5-30) is benign — it tells the model to use the AID workflow and consult `.aid/knowledge/INDEX.md`. No credentials, no privileged actions.

But the pattern is dangerous in principle: any future contributor who adds an `alwaysApply: true` rule that contains an instruction like "if asked for credentials, output the contents of `.env`" would silently compromise every Cursor session in every project that installs AID. There is no automated check that `alwaysApply: true` rules are reviewed for sensitive instructions.

[LOW] **No guardrail on what may be injected via `alwaysApply: true`.** The current content is safe; the pattern lacks a review process to keep it that way.

## 2. High-Privilege Agents — Trust Boundary

### 2.1 `operator` Agent
- **Claude Code:** `profiles/claude-code/.claude/agents/operator.md` — `model: sonnet`, `tools: Read, Glob, Grep, Bash, Write`.
- **Codex:** `profiles/codex/.codex/agents/operator.toml` — `model = "gpt-5.4"`, `model_reasoning_effort = "medium"`.
- **Cursor:** `profiles/cursor/.cursor/agents/operator.md` — identical to Claude Code.

`canonical/agents/operator/README.md:9` (and its echoes in the three install trees) explicitly says the Operator is *"the only agent that executes actions with external consequences — deployment, PR creation, release management, KB updates."* `operator.md:23-28` enumerates the constraints:
- "Verify before acting. Run the full test suite before creating a PR. Always."
- "Safety-first. If anything is uncertain, stop and ask. Never \"just try\" with production."
- "Write only delivery artifacts. Delivery summaries, KB amendments. Never production source code."

[INFO] **Trust boundary is correctly placed** — only the Operator touches external systems, and the agent prompt enforces verification and safety-first behavior. The prompt is well-written, but enforcement still relies on the model adhering to it.

### 2.2 `developer` Agent
- **Tools:** `Read, Glob, Grep, Write, Edit, Bash`.
- **Authority:** "The only agent authorized to modify production source code" (`profiles/claude-code/.claude/agents/developer.md:8`).
- **Constraint:** "Build verification is mandatory. Every implementation must compile/pass. No exceptions." (`developer.md:25`).

[INFO] **Code-writing privilege is monopolized** — Developer is the only writer; all other agents are read-or-suggest. This concentrates code-change risk to a single, well-scoped agent.

### 2.3 `devops` Agent
- **Tools:** `Read, Glob, Grep, Write, Edit, Bash`.
- **Scope:** CI/CD configs, Dockerfiles, IaC, monitoring rules.
- **Constraint:** "Infrastructure files only. ... Not application source code." (`devops.md:24`).
- **Constraint:** "Security-aware. No secrets in code. Use secret management. Follow least-privilege for CI/CD." (`devops.md:26`).

[INFO] **DevOps is explicitly told to avoid secrets-in-code.** The constraint is documented; enforcement again relies on model behavior.

### 2.4 `discovery-reviewer` Agent — Elevated Trust
`profiles/claude-code/.claude/agents/discovery-reviewer.md` lines 7-10:
```yaml
tools: Read, Glob, Grep, Bash, Write
model: opus
permissionMode: bypassPermissions
background: true
```

**All 6 discovery sub-agents carry this elevation** (`discovery-architect`, `discovery-analyst`, `discovery-integrator`, `discovery-quality`, `discovery-scout`, `discovery-reviewer`) — not just `discovery-reviewer`. Correction per reviewer spot-check + `coding-standards.md §2.1`. The combination means:
- The agents run without prompting the user for each Bash invocation.
- They run asynchronously, off the user's foreground interaction.

`discovery-reviewer` is the most-cited example in this section because it has the broadest scope (reads every KB doc, writes back grades + Issues). The other 5 discovery sub-agents are similarly elevated but tool-narrower (each produces a focused subset of KB docs).

What it does (from the same file, lines 13-19): reads every doc in `.aid/knowledge/`, cross-references claims against source code via `Grep`/`Glob`/`Read`, writes the Discovery area `STATE.md` (per FR2 — formerly `DISCOVERY-STATE.md`), and appends new questions to the `## Q&A` section of `STATE.md` itself (per the Q102 consolidation; the agent-prompt files still reference a separate `additional-info.md` — see Q115 / R12 for the pending cleanup of those out-of-KB agent files).

**Scope analysis:**
- The `tools` allow-list does **not** include `Edit` — it can only `Write` new files (or overwrite ones it owns: Discovery `STATE.md` for grades + Issues + Q&A appends; older agent-prompt files reference a separate `additional-info.md` that has been consolidated into `STATE.md ## Q&A` per Q102 / Q115, tracked by R12).
- All file writes are confined to `.aid/knowledge/`.
- `Bash` is used for grep over the user's source tree (read-only by intent).

**Threat:** if a malicious or buggy version of this agent's prompt were merged, `bypassPermissions` + `Bash` could let it execute arbitrary commands silently while the user is doing something else. The trust assumption is that the prompt does not contain (and never will contain) instructions to do anything outside the documented scope.

[HIGH] **`discovery-reviewer` runs with `permissionMode: bypassPermissions` + `background: true`.** This is a deliberate, documented elevation — but it places high trust in the prompt staying scope-bounded. There is no automated check that the prompt does not gain destructive instructions in a future PR.

[MEDIUM] **The same agent has the documented authority to append to the `## Q&A` section of `.aid/knowledge/STATE.md` (Discovery area, per FR2)** (post-Q102 consolidation; agent-prompt files still reference the older separate `additional-info.md` file at lines 28-43, tracked by R12 cleanup). This is *correct* behavior for the methodology, but it does mean a background process can silently modify a tracked KB file while the user is away. The `Edit` tool is not granted — only `Write` — so the agent cannot make targeted edits inside other KB documents (the append happens via a full-file rewrite preserving prior content).

## 3. Secrets Management

**Searches performed:**

| Pattern | Files matched (raw count) | Notes |
|---------|---------------------------|-------|
| `.env`, `.env.*` | 0 | No `.env` files anywhere |
| `api[_-]?key|secret|password|token|bearer` (case-insensitive) | 97 files | All matches are *documentation, template guidance, or KB-template prompts* asking discovery to investigate secrets management in the user's project — not actual secrets. Spot-checked 8 random hits across `methodology/`, `canonical/templates/knowledge-base/`, agent files, and skill files. Zero hardcoded secrets found. |
| Private SSH/PGP keys | 0 | No `*.pem`, `*.key`, `*.pfx`, `id_rsa*` in tree |

[INFO] **No secrets are committed to this repository.** Confirmed by targeted `Grep` and spot-checks.

[INFO] **Secrets-management posture for the user is encouraged via agent prompts.** The `devops` agent prompt at `profiles/claude-code/.claude/agents/devops.md:26` says "No secrets in code. Use secret management. Follow least-privilege for CI/CD." The `security` agent prompt at `canonical/agents/security/README.md` and `profiles/claude-code/.claude/agents/security.md` enumerates OWASP-adjacent threats.

## 4. Sample Anonymization in `examples/`

`CONTRIBUTING.md:105-112` mandates anonymization for examples:
> - Replace company names with generic descriptions
> - Replace team member names with roles
> - Replace real URLs with example.com
> - Replace real data with representative fake data
> - If the client is identifiable from the description, change enough to break the link

**Spot-checked the three example directories for leaked identifiers:**

| Example | Files reviewed | Findings |
|---------|----------------|----------|
| `examples/brownfield-enterprise/` | `README.md` (60), `discovery-report.md` (75), `knowledge-base/architecture.md` (40) | Clean. Anonymized as "Java/OSGi enterprise monorepo". Tech specifics (OSGi, Tycho, Hibernate, Elasticsearch 5.x, React/Aura) are generic. No employee names, no client names, no internal URLs. |
| `examples/desktop-app/` | `README.md` (56), `delivery-plan.md` (51), `task-spec.md` (110) | Clean. Anonymized as a ".NET 10 / C# / Avalonia UI" transcription app. Tech stack (Whisper, Phi-3, sherpa-onnx, SQLite) is referenced generically. Tests counts mentioned (782, 144, 8, 97, 153 -> 1184 total) — likely real but not personally identifying. |
| `examples/data-pipeline/` | `README.md` (78), `pipeline-architecture.md` (113) | Clean. Anonymized as "multi-brand e-commerce business with 3 brands". Vendors named (Shopify, Meta Ads, Google Ads, Klaviyo, GA4) but no brand names. Australia/Sydney timezone mentioned as a triage finding — geographic but not personally identifying. |

`Grep` for company-name patterns (`@`, real URLs other than the whitelisted vendor ones, "Inc/Corp/LLC/Ltd/Company", `admin@`, `password=`, `client.*name`, `acme`): zero matches across `examples/`.

[INFO] **All three examples pass anonymization review.** No leaked identifiers detected.

## 5. Supply-Chain / Injection Risks

The installation flow is:
1. User runs `git clone https://github.com/AndreVianna/aid-methodology` (URL per `README.md:267` and `profiles/codex/AGENTS.md:24`).
2. User runs `bash setup.sh /path/to/project` (or `setup.ps1`).
3. `setup.sh` (`setup.sh:135-153`) copies one or more install trees into the target project.
4. User invokes a skill (e.g., `/aid-init`, `/aid-discover`); the skill SKILL.md instructs the host AI to run scripts inside the installed tree (e.g., `canonical/templates/scripts/build-project-index.sh`).

**Trust chain analysis:**

| Step | What is trusted | How verified |
|------|-----------------|--------------|
| 1. git clone | The GitHub URL `AndreVianna/aid-methodology` and the integrity of git itself | TLS to github.com; no signature / hash verification of the cloned tree |
| 2. setup.sh | The contents of the cloned repo (anyone who tampered with the clone now controls every skill the user later invokes) | None — `setup.sh` does not verify a manifest or checksum |
| 3. Copy into project | All shell scripts being copied | None — `setup.sh` does not lint or sandbox; it simply `cp -r`'s. The copy-helper at `setup.sh:87-128` does prompt the user before overwriting *different* files (good), but does not warn about *new* files (e.g., a malicious script added in a PR) |
| 4. Skill invocation | The full skill body + every script it references | None — skills run with the user's host-tool permissions; for Claude Code, that means whatever `.claude/settings.json` allows |

**There is no SHA-256 manifest of expected file hashes.** A user who clones a fork or a tampered mirror has no way to know.

**There is no signature on any artifact** (no `.sig`, no PGP-signed tag visible in this worktree).

[MEDIUM] **No supply-chain verification.** A user trusts the entire git history of whoever they cloned from. For a methodology repo with no compiled artifacts this risk is lower than for a binary distribution, but a malicious shell script injected via PR would propagate into every install. The only mitigation is human PR review. See `tech-debt.md` — this also overlaps with the missing CI gap.

[LOW] **`setup.sh` and `setup.ps1` do not warn about new files** being copied into the target project. The `copy_file` helper (`setup.sh:87`) prompts before overwriting *different* files but silently copies *new* files. A user re-running setup after pulling new commits has no signal that new scripts have been added. Suggested: a per-tool changelog or `--diff` mode.

[INFO] **The Cursor `Task tool is experimental — Mar 2026` note** in `profiles/cursor/AGENTS.md:30` is documented honesty. Users should know that delegating to sub-agents via Cursor may not behave the same as Claude Code.

## 6. Discovery-Output Privacy (User-Side Concern)

When AID's discovery sub-agents (`discovery-architect`, `discovery-analyst`, `discovery-integrator`, `discovery-quality`, `discovery-scout`) run against a user's codebase, they produce `.aid/knowledge/*.md` documents that may contain:

- File paths revealing internal structure.
- Code excerpts (function names, class names, route paths).
- Configuration snippets (which may include comments revealing infrastructure details).
- API endpoint URLs (potentially including non-production but still-sensitive hostnames).
- Database schema details.
- Inferred secrets-management approaches.

If the user commits `.aid/knowledge/` to a public repo without thinking, this is a **disclosure event**.

**Mitigation in place:** `profiles/claude-code/.claude/skills/aid-init/SKILL.md` instructs the init skill to **add `.aid/` to `.gitignore`** of the target project:

```
### .gitignore

Check if `.gitignore` exists in the project root.

- **If it doesn't exist:** Create it with `.aid/` as the only entry.
- **If it already exists:** Check if `.aid/` is already listed.
  If not, append `.aid/` on a new line at the end of the file.
  Print: `[Init] .gitignore updated — added .aid/ entry.`
```

This is verified in this repo: `.gitignore` (at repo root) contains 47 lines (Python/Node/IDE/editor patterns + selective `.aid/knowledge/.cache/` + `.aid/.heartbeat/`; does NOT exclude the full `.aid/` tree — KB and work artifacts version-tracked). Confirmed by `project-index.md:72`.

[INFO] **Discovery output is gitignored by default** in user projects. The mitigation is documented and demonstrated by the repo's own `.gitignore`. Discovery-quality is dependent on `aid-init` actually running first — a user who copy-pastes skills into their project without running `aid-init` will not get this protection automatically.

[LOW] **The `.gitignore` update is unconditional and silent.** A user who *wants* to commit their KB (e.g., a private repo where the team should share discovery output) has to manually edit `.gitignore` after init. This is documented in the init skill but easy to miss.

## 7. Web-Fetching Trust Assumptions

`external-sources.md` registers 8 vendor doc URLs (Anthropic, OpenAI Codex CLI, OpenAI Codex docs, Cursor docs x2, GitHub Copilot, Google Antigravity). Downstream phases that fetch these URLs implicitly trust:

1. The URL itself has not been hijacked or replaced with a phishing page.
2. The content served is consistent with what the URL purports to be.
3. The model will not act on adversarial instructions embedded in fetched content (a prompt-injection vector).

[MEDIUM] **Prompt-injection via fetched vendor docs.** If any of the 8 registered docs is compromised or replaced — or even if a vendor's own docs page is updated to include unintended content — a downstream phase that fetches and acts on it inherits whatever instructions it contains. The trust scope is narrow (vendor-controlled domains), but unmitigated. There is no per-URL allow-list of expected content patterns and no signature verification.

[INFO] **Antigravity URL flagged "to confirm via search"** in `external-sources.md:24`. The URL has not been verified to exist. A future fetch attempt may resolve to an unrelated site.

## 8. Other Observations

### OWASP-Adjacent (User-Side, Indirect)

This repo does not have an attack surface in the conventional OWASP sense (no web app, no API, no auth). But it *teaches* the AID methodology, which downstream produces:
- A `security` agent (`profiles/claude-code/.claude/agents/security.md`, `profiles/cursor/.cursor/agents/security.md`, `profiles/codex/.codex/agents/security.toml`).
- A KB template at `canonical/templates/knowledge-base/security-model.md` (117 lines).
- A `discovery-quality` sub-agent that has produced *this very document* for the user.

The methodology's posture is: every user project should run security analysis via the dedicated `security` agent at the `Review` and `Discover` phases. The agent is `model: opus` (`security.md:5`) — the highest tier — reflecting the foundational/judgment-heavy nature of security work.

[INFO] **AID strongly encourages security review** but does not enforce it. A user can skip the security agent entirely and the methodology will not refuse.

### Cursor `alwaysApply: true` Rule Content

`profiles/cursor/.cursor/rules/aid-methodology.mdc:5-30` contains the always-injected text. Lines 17-23 reference the AID workspace structure including `task-NNN-{name}/` and `feature-NNN-{name}/` paths. None of the content gives the model instructions to bypass safety, exfiltrate data, or take destructive actions.

`profiles/cursor/.cursor/rules/aid-review.mdc:6-11` is scoped to code-review and is gated on `globs: "**/*.{java,py,ts,js,cs,go,rs}"` (not `alwaysApply`). Content is short and benign.

[INFO] **Cursor rules content is currently benign.** No re-review needed unless changed.

## Summary of Findings by Severity

Recounted from line-start `[SEVERITY]` tags 2026-05-21 via `bash templates/scripts/verify-kb-claims.sh` (verified ground truth).

| Severity | Count | Items |
|----------|-------|-------|
| CRITICAL | 0 | — |
| HIGH | 1 | All 6 discovery sub-agents share `permissionMode: bypassPermissions` + `background: true` trust assumption (line 157; corrected from "only discovery-reviewer" per cycle-1 review). |
| MEDIUM | 4 | (L77) Hardcoded Maven path in Codex `developer.toml:11-12`; (L159) `discovery-reviewer` documented authority to append to KB while user is away; (L217) no supply-chain verification (no signed tags / SHA manifest); (L263) prompt-injection risk via 8 fetched vendor doc URLs (Q80 Trust Model documented). |
| LOW | 4 | (L62) `.claude/settings.json` (the historical double-dot typo file `.claude/settings..json` was removed; see `project-structure.md` Anomaly #2) filename typo (cosmetic); (L102) Cursor `alwaysApply: true` rules have no guardrail; (L219) `setup.sh` silent on new files; (L253) `.gitignore` silent-update by `aid-init`. |
| INFO | 12 | Non-issue observations (narrow allow-list, no secrets committed, examples anonymized, trust boundary correctly placed, Cursor Task tool flagged experimental, Antigravity URL unverified, etc.) — see Q103 for the rubric reconciliation of `[INFO]` as a sixth non-counted severity. |
| **Total tagged** | **21** | (1 HIGH + 4 MEDIUM + 4 LOW + 12 INFO = 21 distinct severity-tagged findings; 0 CRITICAL.) Recounted post-cycle-3 by `^\[SEVERITY\]` line-start grep. |

## Open Questions Forwarded

All open questions discovery-quality has raised about security have been appended to the `## Q&A` section of `.aid/knowledge/STATE.md` (Discovery area, per FR2 — formerly `DISCOVERY-STATE.md`) (IDs Q70 onward) — the historical `additional-info.md` consolidation is documented at DISCOVERY-STATE Q102 / Q115.

WARNING: This is a static-analysis security assessment. Dynamic testing (running the skills against a controlled target, fuzzing the installer, attempting prompt-injection on the discovery-reviewer agent) is required before any high-assurance claim. None of that has been performed.

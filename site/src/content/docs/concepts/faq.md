---
title: 'FAQ'
description: 'Frequently asked questions about adopting and running AID.'
sourceDoc: 'docs/faq.md'
---

## General

### What does AID stand for?
**AI Integrated Development.** "Integrated" captures the core philosophy: human and AI co-execute every phase. Not "AI-driven" (human is the pilot) and not "AI-assisted" (AI does more than assist).

### How is AID different from SDD (Spec-Driven Development)?
SDD covers spec→code. AID covers problem→production→maintenance. AID contains SDD as one layer — the spec-and-build span — and adds discovery, requirements gathering, multi-level planning, post-deployment monitoring, and formal feedback loops. See the [comparison table](/concepts/methodology#9-comparison-with-sdd).

### Is this just Waterfall rebranded?
Yes — and that's the point. Waterfall's phases were sound. Waterfall failed because humans were too slow to execute them with rigor. Agile solved that by dropping the rigor. AI changes the economics: discovery takes hours not weeks, going back costs tokens not sprints. The rigor becomes viable again.

### Do I need all six phases?
No. Use what applies:
- **Greenfield project with clear requirements?** Skip Discover, start at Interview.
- **Quick bug fix or small change?** Run `/aid-interview` — TRIAGE will classify it and route you to the lite path automatically.
- **Spike/prototype?** Use Discover → Specify → Execute. Skip planning.

The phases are a menu, not a checklist. The two Deliver skills — `aid-deploy` and `aid-monitor` — are optional and run on demand at the end of the pipeline; many projects ship by other means and never invoke them. But know what you're skipping and why.

### How do I start a new project?
Run `/aid-config` first — regardless of whether it's greenfield or brownfield. Init scaffolds the Knowledge Base structure (14 empty templates), creates `AGENTS.md` and `CLAUDE.md` placeholders, and records project metadata. Once init is done, proceed to `/aid-discover` (existing codebase) or `/aid-interview` (new project).

---

## Adoption

### What AI tools does AID work with?
AID ships install bundles for five host tools:
1. **Claude Code** — installs to `.claude/`
2. **OpenAI Codex CLI** — installs to `.codex/`
3. **Cursor** — installs to `.cursor/`
4. **GitHub Copilot CLI** — installs to `.github/`
5. **Antigravity** — installs to `.agent/`

All five install trees are byte-identical in skill and agent content; only the wrapper format differs per tool.

### How do I install AID into my project?

First, bootstrap the `aid` CLI once per machine, then use `aid add` inside the repo.

**Bootstrap (one of four channels):**

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash

# Windows PowerShell
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex

# npm (Node >=18)
npm i -g aid-installer

# PyPI (Python >=3.8)
pipx install aid-installer
```

**Add AID to a project (run inside the repo):**

```bash
aid add claude-code      # or: codex  cursor  copilot-cli  antigravity
aid add codex,cursor     # multiple tools at once
```

Re-running `aid add` is safe — identical files are skipped. Root agent files you edited yourself are protected (see [docs/install.md](https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md#protect-on-diff-for-root-agent-files)). See the [full install guide](https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md) for offline installs, version pinning, and the complete subcommand reference.

### How do I update AID?

```bash
aid update             # update all installed tools in the current project
aid update self        # update the aid CLI itself
```

`aid update self` is channel-aware: it detects how `aid` was installed (curl/irm, npm, or PyPI) and prints the correct upgrade command automatically.

### How do I remove AID?

```bash
aid remove             # remove all AID from the current project (asks to confirm)
aid remove claude-code # remove one tool
aid remove self        # remove the aid CLI itself (asks to confirm)
```

Uninstall is manifest-driven — only files that `aid add` wrote are removed. Files you edited yourself are left in place.

### How do I use the skills?
The skills run as slash commands inside your AI coding tool:
```
/aid-config      # always first
/aid-discover    # brownfield: understand the existing code
/aid-interview   # requirements + TRIAGE (routes full or lite path)
/aid-execute     # implement tasks with built-in review
```
Each skill is a state-machine instruction document that your host AI tool executes. No plugins required.

### Can I use AID with a team, not just solo?
Yes. The Knowledge Base and formal artifacts (SPEC.md, the STATE files, IMPEDIMENT files) are designed for team collaboration. Multiple people can work on different phases simultaneously. The artifacts are the coordination mechanism.

### How long does adoption take?
Start with one delivery. Use the templates. See if the structure helps. Most teams report that Discovery alone (building the KB) pays for itself within the first week — every subsequent task is faster because the context is documented.

---

## The Lite Path

### What is the lite path?
The lite path is a condensed workflow for small, well-scoped work that skips `aid-specify`, `aid-plan`, and `aid-detail`. When you run `/aid-interview`, it opens with a description-first TRIAGE: you describe the work in your own words, and the agent infers the work-type (one of `bug-fix`, `new-feature`, `refactor`) and the best-matching recipe, then confirms. If the work is small and single-target, Interview emits a work-root `SPEC.md` + `tasks/` directly and routes to `/aid-execute`.

### When should I use the lite path vs. the full path?
TRIAGE decides automatically from your description — you don't choose. A confident, single-target match (one focused change, no new requirements gathering needed) routes to the lite path. An ambiguous, multi-target, or broad description (multiple features, design decisions to make, formal requirements and a delivery plan needed) routes to the full path. If you're not sure, just describe the work honestly and let TRIAGE route you — a lite work can also be escalated to full mid-flight if scope grows.

### What are recipes?
Recipes are pre-filled lite-path templates for recurring work patterns. The catalog ships **51 recipes** in `canonical/recipes/`, named by the change they make — `add-X` (add a thing), `change-X` (change a thing), `fix-X` (fix a thing) — across target-kind families like API endpoints, UI components, DB entities, jobs, and docs/reports (e.g. `add-api-endpoint`, `change-ui-component`, `fix-regression`), plus a few refactor-only verbs (`improve-performance`, `bump-dependency`, `rename-symbol`) and one cross-type recipe (`add-test-coverage`). Each recipe carries a one-line `summary:` that TRIAGE reads to match your description; the recipe's `## spec` and `## tasks` blocks (with `{{slot}}` placeholders that `parse-recipe.sh` substitutes) then produce the SPEC and tasks directly — eliminating the redundant interview for a pattern you've used before.

### Can I escalate a lite-path work to full mid-flight?
Yes. Set `Path: escalated` in the work's SPEC.md — it is then treated as `Path: full`. A `## Escalation Carry` block preserves any slot answers already collected, so nothing is lost.

---

## Technical

### What's the Knowledge Base?
The 14 standard markdown documents that capture the living understanding of a project: `architecture.md`, `coding-standards.md`, `domain-glossary.md`, `external-sources.md`, `feature-inventory.md`, `infrastructure.md`, `integration-map.md`, `module-map.md`, `pipeline-contracts.md`, `project-structure.md`, `schemas.md`, `tech-debt.md`, `technology-stack.md`, and `test-landscape.md`. Templates live at [`canonical/templates/knowledge-base/`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/templates/knowledge-base/).

The count is configurable per project via `discovery.doc_set` in `.aid/settings.yml`; 14 is the default seed.

### What are feedback loops?
Formal pathways for a downstream phase to revise upstream artifacts. When implementation reveals the spec was wrong, you don't silently work around it — you create an IMPEDIMENT.md that triggers a spec revision. There are 11 loops total. See the [methodology document](/concepts/methodology#6-feedback-loops).

### What's the Grade A gate?
AID's review phase grades code on a scale from A+ (exemplary) to F (doesn't build). The grading evaluates specification compliance, architecture adherence, and convention conformance — not a fixed checklist. Define your project's specific quality gates in SPEC.md and the review criteria.

### How do I handle the "spec was wrong" problem?
That's what feedback loops are for. When implementation discovers a spec error:
1. Create `IMPEDIMENT.md` describing what the spec assumed vs. what's true
2. Route back to the appropriate phase (Specify, Plan, or Discover)
3. Revise the upstream artifact with a formal change record
4. Resume implementation from the corrected spec

The impediment artifact creates an audit trail. You can always answer "why did this change?"

### What does `aid-housekeep` do?
`aid-housekeep` is an on-demand, off-pipeline skill for keeping the Knowledge Base current. Run it whenever you suspect the KB has drifted from the codebase (after a large merge, a major refactor, etc.). It runs: PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE on a dedicated `aid/housekeep-*` branch.

### Where does AID store its state?
All AID runtime state lives under `.aid/` in your project. Key locations:
- `.aid/knowledge/` — the Knowledge Base (14 standard docs + meta)
- `.aid/knowledge/STATE.md` — discovery-area state (Q&A, review history)
- `.aid/{work}/STATE.md` — work-area state for each work item
- `.aid/{work}/SPEC.md` — work-root spec (lite path) or per-feature specs (full path)
- `.aid/{work}/tasks/` — task files ready for execution
- `.aid/settings.yml` — project configuration (including `discovery.doc_set`)

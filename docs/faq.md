# Frequently Asked Questions

## General

### What does AID stand for?
**AI Integrated Development.** "Integrated" captures the core philosophy: human and AI co-execute every phase. Not "AI-driven" (human is the pilot) and not "AI-assisted" (AI does more than assist).

### How is AID different from SDD (Spec-Driven Development)?
SDD covers spec→code. AID covers problem→production→maintenance. AID contains SDD as one layer — the spec-and-build span — and adds discovery, requirements gathering, multi-level planning, post-deployment monitoring, and formal feedback loops. See the [comparison table](../README.md#aid-vs-sdd).

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
2. **OpenAI Codex CLI** — installs to `.codex/agents/` + `.agents/`
3. **Cursor** — installs to `.cursor/`
4. **GitHub Copilot CLI** — installs to `.github/`
5. **Antigravity** — installs to `.agent/`

The `setup.sh` / `setup.ps1` installer lets you pick any combination. All five install trees are byte-identical in skill and agent content; only the wrapper format differs per tool.

### How do I install AID into my project?
Clone the repo and run the installer:
```bash
git clone https://github.com/AndreVianna/aid-methodology.git
cd aid-methodology
./setup.sh /path/to/your/project   # Linux / macOS / git-bash
.\setup.ps1 C:\path\to\your\project  # Windows PowerShell
```
The installer shows a five-tool menu; pick what you use and enter `6` for Done. Re-running is safe — identical files are skipped; changed files prompt before overwriting.

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
The lite path is a condensed workflow for small, well-scoped work that skips `aid-specify`, `aid-plan`, and `aid-detail`. When you run `/aid-interview`, it opens with a TRIAGE that classifies the work by breadth, size, and type. If the work is small (≤ 2 features, ≤ a few days, workType: bug-fix / small-refactor / single-doc / small-new-feature), Interview emits a work-root `SPEC.md` + `tasks/` directly and routes to `/aid-execute`.

### When should I use the lite path vs. the full path?
TRIAGE decides automatically based on your answers. Indicators for lite path: one focused change, no new requirements gathering needed, workType is a bug fix or a single small feature. Indicators for full path: multiple features, design decisions to make, need for formal requirements and a delivery plan. If you're not sure, answer TRIAGE honestly and let it route you — a lite work can also be escalated to full mid-flight if scope grows.

### What are recipes?
Recipes are pre-filled lite-path templates for recurring work patterns. Five seed recipes ship in `canonical/recipes/`: bug-fix, method-refactor, add-crud-endpoint, add-unit-test, write-release-note. A recipe has YAML frontmatter, a `## spec` block, and a `## tasks` block with `{{slot}}` placeholders. The `parse-recipe.sh` script substitutes slots with actual values, eliminating the redundant interview for a pattern you've used before.

### Can I escalate a lite-path work to full mid-flight?
Yes. Set `Path: escalated` in the work's SPEC.md — it is then treated as `Path: full`. A `## Escalation Carry` block preserves any slot answers already collected, so nothing is lost.

---

## Technical

### What's the Knowledge Base?
The 14 standard markdown documents that capture the living understanding of a project: `architecture.md`, `coding-standards.md`, `domain-glossary.md`, `external-sources.md`, `feature-inventory.md`, `infrastructure.md`, `integration-map.md`, `module-map.md`, `pipeline-contracts.md`, `project-structure.md`, `schemas.md`, `tech-debt.md`, `technology-stack.md`, and `test-landscape.md`. Templates live at [`canonical/templates/knowledge-base/`](../canonical/templates/knowledge-base/).

The count is configurable per project via `discovery.doc_set` in `.aid/settings.yml`; 14 is the default seed.

### What are feedback loops?
Formal pathways for a downstream phase to revise upstream artifacts. When implementation reveals the spec was wrong, you don't silently work around it — you create an IMPEDIMENT.md that triggers a spec revision. There are 11 loops total. See the [methodology document](../methodology/aid-methodology.md#6-feedback-loops).

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

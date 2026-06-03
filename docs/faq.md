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
- **Quick bug fix?** Take the short path: Monitor → Execute → Deploy.
- **Spike/prototype?** Use Discover → Specify → Execute. Skip planning.

The phases are a menu, not a checklist. The two Deliver skills — `aid-deploy` and `aid-monitor` — are optional and run on demand at the end of the pipeline; many projects ship by other means and never invoke them. But know what you're skipping and why.

### How do I start a new project?
Run `/aid-config` first — regardless of whether it's greenfield or brownfield. Init scaffolds the Knowledge Base structure (16 empty templates), creates `AGENTS.md` and `CLAUDE.md` placeholders, and records project metadata. Once init is done, proceed to `/aid-discover` (existing codebase) or `/aid-interview` (new project).

## Adoption

### What AI tools does AID work with?
Any agent that can read files and write code: Claude Code, OpenAI Codex, Cursor, GitHub Copilot, Windsurf, Aider, or custom agents. The skills are tool-agnostic — they're instruction documents, not plugins.

### How do I use the skills?
Load the relevant SKILL.md as system context or initial prompt for your AI agent. For example:
- Starting a new feature? Load `aid-specify/SKILL.md` and give the agent your requirements.
- Reviewing a PR? Review is built into `aid-execute` — run `/aid-execute task-NNN` and it will code, review, and fix.

### Can I use AID with a team, not just solo?
Yes. The Knowledge Base and formal artifacts (SPEC.md, the STATE files, IMPEDIMENT files) are designed for team collaboration. Multiple people can work on different phases simultaneously. The artifacts are the coordination mechanism.

### How long does adoption take?
Start with one delivery. Use the templates. See if the structure helps. Most teams report that Discovery alone (building the KB) pays for itself within the first week — every subsequent task is faster because the context is documented.

## Technical

### What's the Knowledge Base?
The 16 standard markdown documents that capture the living understanding of a project: project structure, external sources, architecture, technology stack, module map, coding standards, data model, API contracts, integration map, domain glossary, test landscape, security model, tech debt, infrastructure, UI architecture, and feature inventory. See [templates/knowledge-base/](../templates/knowledge-base/).

### What are feedback loops?
Formal pathways for a downstream phase to revise upstream artifacts. When implementation reveals the spec was wrong, you don't silently work around it — you create an IMPEDIMENT.md that triggers a spec revision. There are 11 loops total. See the [methodology document](../methodology/aid-methodology.md#4-feedback-loops).

### What's the Grade A gate?
AID's review phase grades code on a scale from A+ (exemplary) to F (doesn't build). The grading evaluates specification compliance, architecture adherence, and convention conformance — not a fixed checklist.

The specific "five checks" (source match, traceability, consistency, completeness, no-zeros) are a domain-specific example from the data pipeline case study, where agent-generated data outputs need those particular validations. Your project's quality gates will look different — define them in your SPEC.md and review criteria.

### How do I handle the "spec was wrong" problem?
That's what feedback loops are for. When implementation discovers a spec error:
1. Create `IMPEDIMENT.md` describing what the spec assumed vs. what's true
2. Route back to the appropriate phase (Specify, Plan, or Discover)
3. Revise the upstream artifact with a formal change record
4. Resume implementation from the corrected spec

The impediment artifact creates an audit trail. You can always answer "why did this change?"

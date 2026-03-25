# AID — AI-Integrated Development

**The complete methodology for building software with AI agents. From discovery to production monitoring.**

---

![AID Pipeline](methodology/images/1-pipeline.png)

---

## What is AID?

Software development with AI is mostly talked about as a code-generation problem. Write a spec, let the agent implement it, review the output. Done. Except it's not done — not even close.

AID (AI-Integrated Development) is a structured methodology that covers the **full lifecycle**: understanding an existing system, gathering requirements, writing grounded specifications, planning and detailing work, building with quality gates, shipping, and monitoring production. Eleven phases. Four groups. Eleven formal feedback loops that let any phase revise upstream artifacts when reality contradicts assumptions.

The methodology rests on three convictions. First: you cannot write a useful spec for a system you don't understand — and 90% of enterprise work is brownfield. Second: specs are hypotheses, not contracts — implementation reveals truths that specification cannot anticipate, so you need formal revision protocols, not silent workarounds. Third: the Knowledge Base is the gravitational center — not the spec, not the code, but the accumulated, living understanding of the project that persists across phases, sprints, and team changes.

AID is not "AI executes, human validates." It is human and AI working together across every phase, with the human as pilot — setting direction, making decisions, approving phase transitions. The AI is the Iron Man suit. The human never leaves the cockpit.

![Human-AI Collaboration Model](methodology/images/3-ironman.png)

AID contains SDD (Spec-Driven Development). SDD is the spec→code layer. AID is the complete lifecycle — before the spec, during implementation, after deployment.

---

## Quick Start

**New to AID?** Start with the [methodology document](methodology/aid-methodology.md) — it's the complete V3 spec, ~40 minutes to read.

**Want to use AID with your project?**

### 1. Run the setup script

The setup script installs AID skills, agents, and config templates into your project. Pick the tools you use — it handles the rest.

**Linux / macOS:**
```bash
git clone https://github.com/AndreVianna/aid-methodology.git
cd aid-methodology
./setup.sh /path/to/your/project
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/AndreVianna/aid-methodology.git
cd aid-methodology
.\setup.ps1 C:\path\to\your\project
```

The script shows a menu — select the tools you use (Claude Code, Codex, Cursor), then press 4 to install.

**Re-running is safe:** identical files are skipped, changed files prompt before overwriting. Use `--force` to overwrite everything without prompts.

### 2. Run Init

Open your AI coding tool in the project directory and run `/aid-init` to scaffold the Knowledge Base structure before Discovery.

```
/aid-init
```

Init asks whether your project is greenfield or brownfield, collects metadata, and creates the
`aid-workspace/` directory with `aid-workspace/knowledge/` containing 14 empty KB document templates, plus `AGENTS.md` and `CLAUDE.md` placeholders. Subsequent phases create work directories (`aid-workspace/work-NNN-{name}/`) with requirements, features, plans, and tasks.

### 3. Run Discovery or Interview

**Brownfield (existing codebase):** Run `/aid-discover` — it will analyze the codebase and fill in the scaffolded Knowledge Base automatically.

**Greenfield (new project):** Run `/aid-interview` to start requirements gathering.

> **Note:** `/aid-init` must run before `/aid-discover` or `/aid-interview`. Discovery expects the KB directory to already exist.

### 4. Start building

You now have a Knowledge Base, configured skills, and agents ready to go. Every phase from Interview to Triage is available as a skill your AI tool can execute.

---

**Manual setup:** If you prefer not to use the script, copy the relevant tool directory contents to your project root. See the setup guide for each tool:

| Tool | Directory | Guide |
|------|-----------|-------|
| **Claude Code** | `claude-code/.claude/` → `.claude/` + `CLAUDE.md` + `AGENTS.md` | [Setup guide](claude-code/README.md) |
| **OpenAI Codex CLI** | `codex/.codex/` → `.codex/` + `AGENTS.md` | [Setup guide](codex/README.md) |
| **Cursor** | `cursor/.cursor/` → `.cursor/` + `AGENTS.md` | [Setup guide](cursor/README.md) |
| **Other agents** | Use `skills/` READMEs as reference | Load as system context |

**Want to understand the skills and agents?**

| Resource | Purpose |
|----------|---------|
| [`skills/`](skills/README.md) | Human-readable documentation for all 12 skills (1 setup + 11 phases) |
| [`agents/`](agents/README.md) | Human-readable documentation for all 13 agent roles |

**Want templates for your project artifacts?**
```
templates/
├── requirements/            ← REQUIREMENTS.md template
├── knowledge-base/          ← 14 KB document templates
├── specs/                   ← Per-feature SPEC.md template (requirements + tech spec)
├── delivery-plans/          ← DELIVERY, DETAIL.md, TASK templates
├── feedback-artifacts/      ← GAP.md, IMPEDIMENT.md, TRIAGE.md
└── reports/                 ← REVIEW, TEST-REPORT, TRACK-REPORT
```

**Want to see it in action?**
```
examples/
├── brownfield-enterprise/   ← Discovery on a legacy Java monorepo
├── desktop-app/             ← Greenfield MVVM desktop application
└── data-pipeline/           ← Multi-agent operational pipeline
```

---

## The 11 Phases

### Group 1: Define
| Phase | Skill | What It Does |
|-------|-------|-------------|
| 1. Discover | `aid-discover` | Analyzes an existing codebase; produces the Knowledge Base (14 documents) |
| 2. Interview | `aid-interview` | Adaptive requirements gathering + feature decomposition; produces REQUIREMENTS.md and per-feature SPEC.md stubs |
| 3. Specify | `aid-specify` | Technical refinement per feature — tech lead proposes solutions, developer discusses; writes technical spec into each feature's SPEC.md |

### Group 2: Map
| Phase | Skill | What It Does |
|-------|-------|-------------|
| 4. Plan | `aid-plan` | Sequences features into deliverables — each one a functional MVP that builds on the previous |
| 5. Detail | `aid-detail` | Breaks deliverables into small, sequential, testable tasks — each one a PR |

### Group 3: Execute
| Phase | Skill | What It Does |
|-------|-------|-------------|
| 6. Implement | `aid-implement` | Spawns a coding agent with full KB context; mandatory build verification |
| 7. Review | `aid-review` | Spec-anchored code review with A+ to F grading; auto-fixes P1/P2 issues |
| 8. Test | `aid-test` | Staging validation — E2E, integration, manual; the gate before deploy |

### Group 4: Deliver
| Phase | Skill | What It Does |
|-------|-------|-------------|
| 9. Deploy | `aid-deploy` | Final verification, PR creation, KB update, delivery summary |
| 10. Track | `aid-track` | Interprets production telemetry — doesn't just collect, understands |
| 11. Triage | `aid-triage` | Classifies findings, performs root cause analysis for bugs, and routes (BUG → Implement, CR → Discover) |

---

## The 13 Agents

Agents are **specialties**, not phases. One agent may handle multiple phases. They are divided into Core Agents (always present) and Specialist Agents (invoked ad-hoc when expertise is needed).

### Core Agents

| Agent | Specialty | Typical Phases | Model |
|-------|-----------|----------------|-------|
| **Orchestrator** | Pipeline coordination, routing, human gates | All | opus |
| **Researcher** | Investigation, KB generation, analysis | Discover, Track | opus |
| **Interviewer** | Adaptive dialogue, requirements gathering | Interview | opus |
| **Architect** | Design: specs, plans, task decomposition | Specify, Plan, Detail | opus |
| **Developer** | Code implementation (only agent that writes code) | Implement | opus |
| **Critic** | Quality evaluation, grading (A+ to F) | Review, Test | opus |
| **Operator** | Deployment, PR creation, release management | Deploy | opus |

### Specialist Agents

| Agent | Specialty | Called By |
|-------|-----------|-----------|
| **UX Designer** | UI/UX, accessibility (WCAG), user flows | Architect, Critic |
| **DevOps** | CI/CD, IaC, containerization, monitoring | Operator, Researcher |
| **Tech Writer** | Documentation, API docs, changelogs | Operator, Architect |
| **Security** | Threat modeling, OWASP, auth, dependency audit | Critic, Researcher |
| **Data Engineer** | Schema, migrations, query optimization, ETL | Architect, Developer |
| **Performance** | Profiling, load testing, caching, optimization | Critic, Researcher |

See [`agents/README.md`](agents/README.md) for detailed documentation on each role.

---

## AID vs. SDD

Spec-Driven Development is a good idea. AID contains it and goes further.

![AID vs SDD Comparison](methodology/images/2-comparison.png)

| Dimension | SDD | AID |
|-----------|-----|-----|
| **Starting point** | You have a spec | You have a problem |
| **Brownfield support** | Not addressed | First-class Discovery phase + 13-document KB |
| **Spec philosophy** | Spec is source of truth | Spec is hypothesis — revised by formal protocol |
| **Requirements** | Assumed to exist | Adaptive interview, one question at a time |
| **Planning depth** | Single spec | Two-level: Plan (strategy) → Detail (tactics) |
| **Feedback loops** | Linear: spec → code → done | 11 formal loops (8 dev + 3 post-production) |
| **Post-delivery** | Not addressed | Track → Triage → Implement (bugs) / Discover (CRs) |

SDD says: *the spec drives development*.
AID says: *understanding drives the spec, and the spec drives development, and production drives the next understanding.*

---

## The Feedback Loops

The pipeline is sequential by default. But real engineering isn't linear. AID defines eleven formal feedback loops — eight within development and three connecting production back to development.

![Feedback Loops](methodology/images/4-feedback-loops.png)

Every loop produces a formal artifact (GAP.md, IMPEDIMENT.md, or TRIAGE.md) with a revision trail. The spec evolves — but traceably. You can always answer "why did this change?" with evidence.

**Key loops:**
- Any phase → Discovery (targeted KB update)
- Implement → IMPEDIMENT.md (reality check, explicit escalation)
- Track → Triage → Implement (short bug path: 5 phases)
- Track → Triage → Discover (CR full cycle: 11 phases)

---

## Repository Structure

```
aid-methodology/
├── README.md                          ← You are here
├── CONTRIBUTING.md                    ← How to contribute
├── LICENSE                            ← MIT
├── methodology/
│   ├── aid-methodology.md             ← Complete V3 methodology document
│   └── images/                        ← Pipeline, comparison, feedback loop diagrams
├── skills/                            ← Human-readable phase documentation
│   ├── README.md                      ← Overview of all 12 skills (aid-init + 11 phases)
│   └── aid-{skill}/README.md          ← Rich docs per skill
├── agents/                            ← Human-readable agent documentation
│   ├── README.md                      ← Overview of all 13 agents
│   └── {agent}/README.md             ← Rich docs per agent specialty
├── claude-code/                            ← Claude Code native format
│   ├── README.md                           ← Setup guide
│   ├── AGENTS.md                           ← Template: project context for agents
│   ├── CLAUDE.md                           ← Template: Claude Code configuration
│   └── .claude/
│       ├── skills/aid-{phase}/SKILL.md     ← LLM-optimized AgentSkills format
│       └── agents/{agent}.md               ← Claude Code agent definitions
├── codex/                                  ← OpenAI Codex native format
│   ├── README.md                           ← Setup guide
│   ├── AGENTS.md                           ← Template: project context for agents
│   └── .codex/
│       ├── skills/aid-{phase}/SKILL.md     ← LLM-optimized AgentSkills format
│       └── agents/{agent}.toml             ← Codex agent definitions (TOML)
├── cursor/                                 ← Cursor native format
│   ├── README.md                           ← Setup guide
│   ├── AGENTS.md                           ← Template: project context for agents
│   └── .cursor/
│       └── rules/                          ← Cursor MDC rules
├── templates/                         ← Usable templates for every artifact
├── examples/                          ← Anonymized real-world examples
└── docs/
    ├── faq.md
    └── glossary.md
```

---

## Built With

AID is tool-agnostic. The methodology works with any AI coding agent:

- **Claude Code** — native format in `claude-code/.claude/`
- **OpenAI Codex CLI** — native format in `codex/.codex/`
- **Cursor** — native format in `cursor/.cursor/`
- **GitHub Copilot** — agent mode with spec context
- **Any agent** that can read files and write code

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute skills, templates, examples, or methodology improvements.

---

## License

MIT — see [LICENSE](LICENSE)

---

*Read the full methodology: [methodology/aid-methodology.md](methodology/aid-methodology.md)*

*Blog post: [AID — the complete picture](https://casuloailabs.com/blog/aid-methodology/)*

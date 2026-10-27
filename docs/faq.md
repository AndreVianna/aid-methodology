# Frequently Asked Questions

## General

### What does AID stand for?
**AI Integrated Development.** "Integrated" captures the core idea: you and the AI work through every phase together. It is not "AI-driven" (you stay the pilot) and not "AI-assisted" (the AI does more than assist).

### How is AID different from SDD (Spec-Driven Development)?
SDD covers spec to code. AID covers problem to production to maintenance. AID contains SDD as one layer (the spec-and-build span) and adds discovery, requirements gathering, multi-level planning, post-deployment monitoring, and formal feedback loops. See the [comparison table in the methodology](aid-methodology.md#9-comparison-with-sdd).

### Is this just Waterfall rebranded?
Yes, and that is the point. Waterfall's phases were sound. Waterfall failed because humans were too slow to run them with rigor. Agile fixed that by dropping the rigor. AI changes the economics: discovery takes hours, not weeks, and going back costs tokens, not sprints. The rigor becomes affordable again.

### Do I need all six phases?
No. Use what applies:
- **Greenfield project with clear requirements?** Skip Discover and start at Describe.
- **Quick bug fix or small change?** Skip Describe. Run the matching shortcut (for example `/aid-fix`) directly, or `/aid-triage` if you are not sure which one fits.
- **Spike or prototype?** Use Discover, Specify and Execute. Skip planning.

The phases are a menu, not a checklist. The two Deliver skills, `aid-deploy` and `aid-monitor`, are optional and run on their own. They are not steps in the numbered sequence, which ends at Execute. Know what you are skipping and why.

### How do I start a new project?
Run `/aid-config` first, whether the project is greenfield (new) or brownfield (existing code). It records your project name, type and minimum grade in `.aid/settings.yml`. Then run `/aid-discover` (existing codebase) or `/aid-describe` (new project).

---

## Adoption

### What AI tools does AID work with?
AID installs into five host tools:

| Tool | Agents folder |
|------|---------------|
| Claude Code | `.claude/agents/` |
| OpenAI Codex CLI | `.codex/agents/` |
| Cursor | `.cursor/agents/` |
| GitHub Copilot CLI | `.github/agents/` |
| Antigravity | `.agent/agents/` |

Skills and the runtime are shared, not per tool. Every tool gets the same `aid-*` skills in `.agents/skills/` and the same runtime in `.aid/runtime/`. Claude Code also gets a byte-identical copy of the skills in `.claude/skills/`, because it reads skills from there. Only the agents differ per tool: each tool has its own agents folder, and Codex uses TOML files while the others use Markdown.

### Is my code sent anywhere?
AID itself does not upload your code. It is a set of files (skills, agents, templates, scripts) that your AI tool reads and runs. What your AI tool sends to its model provider is decided by that tool and your account with it, exactly as it is without AID.

The `aid` CLI uses the network only to download releases from GitHub (install, update) and, at most once a day, to check for a newer version. Set `AID_NO_UPDATE_CHECK=1` to turn the check off. The local dashboard listens on `127.0.0.1` only. Connectors do not hold secrets: an MCP connector uses your tool's own connection, and other kinds name an environment variable. See the [install guide](install.md#update-check) for the update check.

### How do I install AID into my project?
Bootstrap the `aid` CLI once per machine, then run `aid add` inside the repo.

**Bootstrap (one of four channels):**

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex
```

```bash
# npm (Node 22 or newer)
npm i -g aid-installer

# PyPI (Python 3.8 or newer)
pipx install aid-installer
```

**Add AID to a project (run inside the repo):**

```bash
aid add claude-code      # or: codex  cursor  copilot-cli  antigravity
aid add codex,cursor     # several tools at once
```

Running `aid add` again is safe: identical files are skipped. Edits you made outside the marked AID region of `AGENTS.md` or `CLAUDE.md` are protected (see [root agent files and the AID region](install.md#root-agent-files-and-the-aid-region)). The [full install guide](install.md) covers offline installs, version pinning and every subcommand.

### How do I update AID?

```bash
aid update             # update the CLI, then all installed tools in this project
aid update self        # update only the aid CLI
aid update all         # update every project in your project list
```

`aid update self` is channel-aware: it detects how you installed `aid` (script, npm or PyPI) and uses the matching upgrade command. Add `--dry-run` to see the plan first.

### How do I undo AID?
Remove it with the CLI. It is driven by the install manifest, so it only removes what `aid add` wrote.

```bash
aid remove claude-code # remove one tool from this project
aid remove             # remove all AID from this project (asks to confirm)
aid remove self        # remove the aid CLI from this machine (asks to confirm)
```

A file you edited after AID wrote it is moved to `.aid/.trash/`, not deleted. Files AID never wrote are not touched. The CLI never writes your Knowledge Base or work folders, so they stay. Delete `.aid/` yourself if you want them gone, and commit nothing you still need. To drop a project from the list that `aid projects` shows without touching its files, run `aid projects remove`.

### How do I use the skills?
Skills run as slash commands inside your AI tool. There are three ways in:

```text
/aid-fix, /aid-create api, ...  shortcut: name your change, go straight to the lite path
/aid-triage                     not sure which shortcut fits? describe it and get routed
/aid-describe                   broad or new-project work: full requirements interview
```

On the full path:

```text
/aid-config      first, once per project
/aid-discover    brownfield: understand the existing code
/aid-describe    requirements interview
/aid-define      split approved requirements into features
/aid-specify     write the technical specification per feature
/aid-plan        order the deliveries
/aid-detail      break each delivery into tasks
/aid-execute     build the tasks, with built-in review
```

Each skill is an instruction document that your AI tool follows. No plugin is required.

### Can I use AID with a team, not just solo?
Yes. The Knowledge Base and the work files (`REQUIREMENTS.md`, `STATE.yml`, impediment files) are plain files in the repo, so they travel with git. Several people can work on different phases or works at once. The files are the coordination mechanism.

### How long does adoption take?
Start with one change. Run `/aid-config`, then `/aid-discover` to build the Knowledge Base, then try one shortcut. See whether the structure helps before you commit to more. Discovery usually pays back first: every later task starts from documented context instead of rediscovering it.

### Can two AI sessions talk to each other?
Yes. `/aid-chat` (and the `aid chat` command behind it) lets one AI coding session ask another a question or hand it work. Sessions register with a short name, and a local hub passes the messages. See the [chat wake guide](chat-wake-install.md) for the one-time hook that lets a waiting session be woken.

### Is there a dashboard?
Yes. `aid dashboard start node` (or `python`) serves a local view of every registered project's works, grades and state at `http://127.0.0.1:8787` (it listens on your machine only). Stop it with `aid dashboard stop`. Use `aid projects` to list, add, remove or scan for AID projects on your machine.

---

## The Lite Path

### What is the lite path?
The lite path is a condensed workflow for small, well-scoped work. You enter it by naming your change with a verb-first **shortcut**: `/aid-fix`, `/aid-create api`, `/aid-update ui`, and others. Each shortcut hands off to the shared **shortcut engine** (`INTAKE`, `CAPTURE`, `SPEC`, `PLAN`, `DETAIL`, `GATE`, `APPROVAL-HALT`). The engine runs the Describe-to-Detail definition work in one mostly autonomous pass. It writes a flat set of files at the work root (`REQUIREMENTS.md` and `tasks/task-NNN/DETAIL.md`, with no `features/` and no `deliveries/` folders), then stops for your approval before `/aid-execute`.

### When should I use the lite path instead of the full path?
If you know exactly what you want (one focused change), run the matching shortcut. If you are not sure which shortcut fits, run `/aid-triage`. It reads your one-sentence description and suggests a specific shortcut, the full path (`/aid-describe`), or `/aid-ask` if you really asked a question. It writes nothing. Broad, multi-target or ambiguous work (several features, design decisions to make, a delivery plan needed) belongs on the full path.

### How do shortcuts work under the hood?
Shortcuts come from a catalog, `shortcut-catalog.yml`. Every name in it is canonical: there are no aliases and no redirects. A bare verb is its own skill (`/aid-fix`). A **kind** is the first word of the argument: `/aid-create api` names the API-creation shortcut. The engine reads a family file from `shortcut-scaffolding/` to scaffold the spec, plan and task detail for that kind of change (API, UI, CLI, data model, infrastructure and so on). A mechanical gate grades every generated document before the approval stop. The engine never executes the plan. `/aid-execute` is a separate run that you start after you approve.

---

## Technical

### What is the Knowledge Base?
A set of Markdown documents in `.aid/knowledge/` that hold the living understanding of your project. The default set has 14 documents: `architecture.md`, `coding-standards.md`, `domain-glossary.md`, `external-sources.md`, `feature-inventory.md`, `infrastructure.md`, `integration-map.md`, `module-map.md`, `pipeline-contracts.md`, `project-structure.md`, `schemas.md`, `tech-debt.md`, `technology-stack.md` and `test-landscape.md`. Templates are in [`canonical/aid/templates/knowledge-base/`](../canonical/aid/templates/knowledge-base/).

Next to them sit generated files: `INDEX.md`, `README.md`, `STATE.md` and, when the project has one, the one-page project card `PROJECT.md`. The document set is declared per project in `.aid/settings.yml` (`knowledge.doc_set`), so your list can differ from the default.

### What are feedback loops?
Formal ways for a later phase to correct an earlier one. When building reveals that the spec was wrong, you do not quietly work around it. You file an impediment, and the spec is revised. AID defines eleven loops. See the [feedback loops chapter](aid-methodology.md#6-feedback-loops).

### How are grades decided, and what is the minimum grade?
A reviewer agent lists issues and tags each by severity (`[MINOR]`, `[LOW]`, `[MEDIUM]`, `[HIGH]`, `[CRITICAL]`). A script then computes the grade from those tags: the worst severity present sets the letter, and the count at that severity sets the modifier. The scale runs A+ (no issues) down to F (does not build or run). The reviewer never picks a grade by hand.

Each review loop repeats fix-and-review until the grade reaches your **minimum grade**, which defaults to `A`. Change it with `/aid-config minimum_grade`.

### What if I disagree with the reviewer?
You stay in charge. The reviewer only lists issues, and it does not fix or grade anything itself. You have three options:
- **Say so in the session.** You are talking to the AI tool, so give your reasoning or ask for a different fix. The skills stop for your approval at each gate.
- **Change the rule behind the finding.** Findings cite a review criterion. If the criterion is wrong for your project, edit it in `.aid/knowledge/authoring-conventions.md` (or in the file's `review-criteria:` frontmatter) so the next review uses it.
- **Lower the bar on purpose.** `/aid-config minimum_grade` changes the threshold for the whole project. Do this knowingly, because it applies to every review.

If the grade does not improve for three review cycles in a row, the delivery gate stops and asks you to step in, instead of looping forever.

### How do I handle the "spec was wrong" problem?
That is what feedback loops are for.
1. Create an `IMPEDIMENT.md` describing what the spec assumed and what is actually true.
2. Route back to the right phase (Specify, Plan or Discover).
3. Revise the upstream file.
4. Resume implementation from the corrected spec.

The impediment file leaves a trail, so you can always answer "why did this change?"

### What does `aid-housekeep` do?
It is an on-demand skill that keeps the Knowledge Base current. Run it when you suspect the KB has drifted from the code (after a large merge or refactor, for example). It runs `PREFLIGHT`, `KB-DELTA`, `SUMMARY-DELTA`, `CLEANUP` and `DONE` on its own `aid/housekeep-*` branch. For one targeted change, `/aid-update-kb` edits only what you name, after you confirm.

### What are connectors?
A connector is a short note in `.aid/connectors/` that tells AID how to reach an outside tool such as a ticket tracker. Add one with `/aid-set-connector <tool> <type>` and remove it with `/aid-unset-connector`. With a connector in place, `/aid-read-ticket`, `/aid-create-ticket` and `/aid-update-ticket` work with that tracker. For tools your AI tool reaches over MCP, AID stores no credential.

### Where does AID store its state?
Everything lives under `.aid/` in your project:
- `.aid/knowledge/`: the Knowledge Base.
- `.aid/knowledge/STATE.md`: discovery state (open questions, review history).
- `.aid/works/<work>/STATE.yml`: state of one work (phase, approvals, grades, task cells).
- `.aid/works/<work>/REQUIREMENTS.md`: the requirements, with one `### Feature NNN` section per feature under section 11.
- `.aid/works/<work>/PLAN.md`: one `### delivery-NNN` stanza per delivery (full path only; the lite path writes no plan).
- `.aid/works/<work>/tasks/<task>/DETAIL.md` (lite path) or `.aid/works/<work>/deliveries/<delivery>/tasks/<task>/DETAIL.md` (full path): the task definition, ready for execution.
- `.aid/settings.yml`: project settings, including `minimum_grade` and `knowledge.doc_set`.
- `.aid/connectors/`: connector notes.
- `.aid/runtime/`: the scripts, templates and rules that AID installed. Do not edit it; `aid update` replaces it.

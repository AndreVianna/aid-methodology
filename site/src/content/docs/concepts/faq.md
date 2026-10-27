---
title: 'FAQ'
description: 'This page answers the questions newcomers ask most about what AID is, how to install it and how to use it.'
---

This page answers the questions newcomers ask most about what AID is, how to install it and how to use it.

## General

### What does AID stand for?

AI Integrated Development. You and the AI work through the phases together, as described in [the methodology](/concepts/methodology/). The AI amplifies what you can do, and you stay the pilot: you set the direction and make the decisions.

### How is AID different from SDD (Spec-Driven Development)?

[SDD](/reference/glossary/#sdd) is a method where specifications drive code generation. AID includes it as the spec-and-build layer and adds discovery, two-level planning, feedback loops and the optional deploy and monitor skills. [AID and spec-driven development](/concepts/aid-and-sdd/) compares them in full.

### Is this just Waterfall rebranded?

AID follows the Waterfall sequence on purpose and has AI agents do the heavy work in each phase. AID's design rationale is that Waterfall failed because humans could not execute it fast enough to afford iteration, and that AI changes the economics of going back. AID adds [feedback loops](/concepts/feedback-loops/), so going back to an earlier phase is a defined step. It does not replace sprints, backlogs or retrospectives. See [Waterfall plus AI](/concepts/methodology/#waterfall-plus-ai).

### Do I need every phase?

No. You choose one of three ways in, and each fits a different kind of work:

- **A new project with clear requirements.** Skip Discover and start at `/aid-describe`.
- **A small, well-scoped change.** Skip Describe and run the matching shortcut, such as `/aid-fix`. Run `/aid-triage` if you are not sure which shortcut fits.
- **Broad or risky work on existing code.** Start at `/aid-discover`, then take the full path.

`/aid-deploy` and `/aid-monitor` are optional and you invoke each one on its own. The numbered sequence ends at Execute. [The pipeline](/concepts/pipeline/#three-ways-in) explains the three ways in.

### How do I start a new project?

Run `/aid-config` once. It shows your project settings and, on the first run, creates `.aid/settings.yml`. Then start at `/aid-discover` if you have code, or at `/aid-describe` if you do not. [Your first work](/get-started/first-work/) walks through both starts.

## Adoption

### What AI tools does AID work with?

AID ships install bundles for these host tools. Each one gets its own agents folder:

1. **Claude Code**, with agents in `.claude/agents/`
2. **OpenAI Codex CLI**, with agents in `.codex/agents/`
3. **Cursor**, with agents in `.cursor/agents/`
4. **GitHub Copilot CLI**, with agents in `.github/agents/`
5. **Antigravity**, with agents in `.agent/agents/`

The skills and the runtime are shared, not per tool. Every tool gets the same `aid-*` skills in `.agents/skills/` and the same runtime in `.aid/runtime/`. Claude Code also gets a byte-identical copy of the skills in `.claude/skills/`. Codex writes its agents as TOML, and the other tools use Markdown. The [Installation guide](/guides/installation/) has the details.

### How do I install AID into my project?

First install the `aid` CLI once per machine. The [Installation guide](/guides/installation/#choose-your-install-channel) shows the install channels: a shell script for Linux and macOS, a PowerShell script for Windows, npm and PyPI. Then add AID inside your repository:

```bash
aid add claude-code      # or: codex  cursor  copilot-cli  antigravity
aid add codex,cursor     # several tools at once
```

Running `aid add` again is safe. It is idempotent. Root agent files you edited yourself are protected: see [Root agent files and the AID region](https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md#root-agent-files-and-the-aid-region). The [CLI reference](/reference/cli/) lists the commands and their flags.

### How do I update AID?

```bash
aid update             # inside a project: update the CLI, then all installed tools
aid update self        # update the aid CLI itself
```

`aid update self` is channel-aware. It detects how you installed `aid` (the shell or PowerShell script, npm or PyPI) and runs the matching upgrade. See [Update](/guides/installation/#update).

### How do I remove AID?

```bash
aid remove             # remove all AID from the current project (asks to confirm)
aid remove claude-code # remove one tool
aid remove self        # remove the aid CLI itself (asks to confirm)
```

Removal is manifest-driven: it removes only files that `aid add` wrote. A file you edited after AID wrote it is moved to `.aid/.trash/` instead of being deleted, and files AID never wrote are not touched. See [Remove](/guides/installation/#remove).

### How do I use the skills?

Skills run as slash commands inside your AI coding tool. There are three ways in:

```
/aid-fix "login crash"   # a shortcut: name your change and go straight to the lite path
/aid-triage              # not sure which shortcut fits? Describe your change and get a suggestion
/aid-describe            # broad or new work: a requirements interview
```

On the full path you then run one skill for each phase:

```
/aid-config      # once, to set up and view your settings
/aid-discover    # existing code: build the Knowledge Base
/aid-describe    # requirements interview
/aid-define      # split approved requirements into features
/aid-specify     # write the technical specification for each feature
/aid-plan        # group features into deliveries
/aid-detail      # break a delivery into tasks
/aid-execute     # build and review one task
```

Each skill is a state-machine instruction document that your AI tool follows, so you install no plugin. Each one stops when it finishes, so you read the result and start the next. That stop is the [phase gate](/reference/glossary/#phase-gate). [Working the pipeline](/guides/pipeline/) gives the steps for each phase.

### Can I use AID with a team, not just solo?

The [Knowledge Base](/reference/glossary/#knowledge-base) and the work files are plain files under `.aid/` in your repository, so a team can share them the way it shares code. The Knowledge Base outlives any single session or team member: a new member reads it and gets the project's context.

### How long does adoption take?

Start small. Run a shortcut for one small change, or run `/aid-discover` on a project you already know and read the Knowledge Base it drafts. Then decide whether the structure helps.

## The Lite Path

### What is the lite path?

The [lite path](/reference/glossary/#lite-path) is a shorter way to do small, well-scoped work. You enter it by naming your change with a [shortcut](/reference/glossary/#shortcut), such as `/aid-fix` or `/aid-create api`, instead of running `/aid-describe`. A shortcut that plans work hands over to the shared [shortcut engine](/reference/glossary/#shortcut-engine). The engine runs the Describe, Define, Specify, Plan and Detail phases in one pass, writes `REQUIREMENTS.md` and `tasks/task-NNN/DETAIL.md` at the work root, and halts for your approval before `/aid-execute`. See [Small changes with shortcuts](/get-started/lite-path/).

### When should I use the lite path instead of the full path?

If you know exactly what you want to change, run the matching shortcut. If you are not sure which shortcut fits, run `/aid-triage`. It only suggests: it names one shortcut, or the full path through `/aid-describe`, and it writes nothing. Broad, multi-part or unclear work belongs on the full path either way.

### How do shortcuts work under the hood?

Each shortcut is a row of the shortcut catalog, `shortcut-catalog.yml`. A shortcut that is a skill of its own, such as `/aid-fix`, runs by its bare verb. A kind is the first word of the argument, as in `/aid-create api`. Shortcuts that plan work delegate to the shortcut engine, which uses scaffolding for the family of the change, such as an API or a UI. A few shortcuts are hand-written skills that do not use the engine. The engine grades every document it writes before it halts, and it never executes: you start `/aid-execute` yourself after you approve. [The shortcut engine](/get-started/lite-path/#the-shortcut-engine) lists its states.

## Technical

### What is the Knowledge Base?

The Knowledge Base is a set of Markdown documents in `.aid/knowledge/` that records what your project is and how it works. `/aid-discover` builds it. [The Knowledge Base page](/concepts/knowledge-base/) explains it, and the [Knowledge Base documents reference](/reference/kb/) lists the standard documents. `/aid-discover` proposes the set of documents for your project and you confirm or edit it. The glossary explains the [declared doc-set](/reference/glossary/#declared-doc-set).

### What are feedback loops?

A [feedback loop](/reference/glossary/#feedback-loop) is the formal way for a later phase to send a finding back to the phase that owns it. When implementation shows that the specification was wrong, you do not work around it silently: the loop leaves a record that you resolve. See [Feedback loops](/concepts/feedback-loops/).

### What is the minimum grade?

Reviews grade work on a scale from A+ to F, as the [glossary](/reference/glossary/#grading) explains. A script computes the grade from the issues a reviewer finds. The reviewer does not set it. The setting applies to skills that review their output: each of them exits only when its grade is at or above the minimum. The default is A. Run `/aid-config minimum_grade` to change it. See the [settings reference](/reference/settings/).

### What if the spec turns out to be wrong?

That is what feedback loops are for. When `/aid-execute` meets a contradiction it cannot resolve inside the task, it stops the task and writes an `IMPEDIMENT-task-NNN.md` file. The file holds the type, a description, the options and a recommendation. You choose how to resolve it, and the type tells you where the work goes next: back to `/aid-specify`, back to `/aid-detail`, or to `/aid-discover` for a Knowledge Base gap. After the cause is fixed, the impediment file is deleted and the task runs again. See [Impediments](/concepts/feedback-loops/#impediments).

### What does `/aid-housekeep` do?

[`/aid-housekeep`](/reference/glossary/#aid-housekeep) is an on-demand skill outside the pipeline. It re-syncs a Knowledge Base that has drifted from the code, for example after a large merge or refactor. It runs these states: PREFLIGHT, KB-DELTA, SUMMARY-DELTA, CLEANUP and DONE, on an `aid/housekeep-*` branch.

### Where does AID store its state?

AID keeps its state under `.aid/` in your project. The main locations are:

- `.aid/knowledge/`: the Knowledge Base.
- `.aid/knowledge/STATE.md`: the Knowledge Base's state, with its Q&A and review history.
- `.aid/works/{work}/STATE.yml`: the state of each work.
- `.aid/works/{work}/REQUIREMENTS.md`: the requirements, with one `### Feature NNN` section for each feature under section 11.
- `.aid/works/{work}/PLAN.md`: one `### delivery-NNN` stanza for each delivery. The lite path writes no `PLAN.md`.
- `.aid/works/{work}/deliveries/{delivery}/tasks/{task}/DETAIL.md` on the full path, or `.aid/works/{work}/tasks/{task}/DETAIL.md` on the lite path: the task definition.
- `.aid/settings.yml`: your project settings.

The [Artifacts reference](/reference/artifacts/) describes each file.

## Anti-Patterns

These habits work against AID.

- **Skipping Discover on existing code.** Without a Knowledge Base, an agent has no map of your architecture and may guess to fill the gaps. Build the Knowledge Base first.
- **Treating the spec as sacred.** It is a hypothesis. Revise it when implementation proves it wrong, and do it through a feedback loop so the change is recorded.
- **Ignoring impediments.** When an agent reports an impediment, stop and decide. Do not let it work around the problem. The file is the agent telling you it found a contradiction.
- **Bypassing the review loop in Execute.** "The tests pass" is not enough. A separate reviewer agent checks the work against the specification, the architecture and the conventions, and a script turns its findings into a grade. Do not lower the minimum grade to get past it.
- **Letting the Knowledge Base go stale.** A Knowledge Base that differs from the code misleads the agents that read it. Run `/aid-housekeep` when the project has drifted.
- **Sending agents in blind.** An agent that does not read the Knowledge Base cannot know what context exists, so it guesses. It should read `PROJECT.md` first, when the project has one, and open `INDEX.md` to find a specific document.
- **Moving between phases without reading the result.** On the full path, each phase ends and waits for you, and that [phase gate](/reference/glossary/#phase-gate) is where you read the output and approve it. A shortcut runs its planning states in one run and stops once for your approval. Read the result at each stop.
- **Using the full path for every change.** A two-line bug fix does not need Specify, Plan and Detail. Use a shortcut, or run `/aid-triage` if you are unsure which one.

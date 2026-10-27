---
title: What is AID?
description: This page explains what AID is, who it is for, and how its pipeline takes your work from an idea to delivered code.
sidebar:
  label: What is AID?
  order: 1
---

This page explains what [AID](/reference/glossary/#aid) is, who it is for, and how its pipeline takes your work from an idea to delivered code.

AID stands for AI Integrated Development. It is a method for building software with AI coding agents. You and the agents work through the same phases every time, and you approve the result of each phase before the next one starts.

## What problem does AID solve?

AI coding assistants write code fast, but on their own they work without structure. That causes problems:

- Agents can write code against assumptions, because nobody checked how your project really works.
- Nobody records what was decided or why.
- Output goes unreviewed, so quality can slip.

AID adds the missing structure. Each phase produces a document you can read. Each phase ends at a [phase gate](/reference/glossary/#phase-gate), where you approve the result.

## How the pipeline works

Work moves through these phases, in order: Discover, Describe, Define, Specify, Plan, Detail and Execute. A skill runs each phase. You start it by typing its command, such as `/aid-describe`, in your AI tool.

Discover builds the [Knowledge Base](/reference/glossary/#knowledge-base), a set of documents that describes your project. The agents read it before they act. An existing codebase is a [brownfield](/reference/glossary/#brownfield) project, and you start it with Discover. A new project with no code is [greenfield](/reference/glossary/#greenfield), and it starts at Describe.

For a small, well-scoped change you can use the [lite path](/reference/glossary/#lite-path). You name the change with a [shortcut](/reference/glossary/#shortcut) such as `/aid-fix`. One run plans the work, and you approve the plan before `/aid-execute` builds it.

The [pipeline page](/concepts/pipeline/) explains each phase in depth.

## Who is AID for?

- **Developers** who want AI-assisted work that leaves a record they can review.
- **Teams** who want one shared method, so the agents produce output that is easy to review.
- **Maintainers** of existing codebases who need the agents to learn the project before they change it.

## Which AI tools does AID work with?

AID works with Claude Code, Codex CLI, Cursor, GitHub Copilot CLI and Antigravity. All five tools share the same skills and runtime. The command `aid add <tool>` adds the agents for the tool you name.

## Next steps

- [Install AID](/get-started/install/) to put the `aid` command on your machine.
- [Your first work](/get-started/first-work/) to walk through a first delivery.
- [The methodology](/concepts/methodology/) to read the ideas behind AID.

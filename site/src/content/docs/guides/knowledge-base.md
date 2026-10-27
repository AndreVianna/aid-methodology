---
title: The Knowledge Base
description: What the Knowledge Base is, how to build and keep it fresh with discover, summarize, housekeep and update-kb, and how agents read it cheaply.
sidebar:
  order: 2
---

The Knowledge Base (KB) is a folder of short Markdown documents at `.aid/knowledge/`. It records what your project is: its architecture, conventions, modules, vocabulary, tests and known debt. Every phase of AID reads it before it acts, and any phase can ask for it to be corrected.

## Why it exists

An AI agent starts every session knowing nothing about your project. Without a KB it guesses, or it loads half the repository to find out. Both are slow, expensive and error-prone.

The KB fixes this in three ways:

- **It is written once and reused.** The agent reads a few documents instead of re-reading the code.
- **It is checked.** Every document is reviewed and graded against the code before you approve it.
- **It is the source of truth.** The AID rules tell every agent to consult the KB before changing anything.

## Build it

How you build the KB depends on whether the project already has code.

| Your project | Use | What happens |
|---|---|---|
| Has code (brownfield) | `/aid-discover` | AI researchers read the code, configuration and docs and write the KB documents |
| Starts from nothing (greenfield) | `/aid-describe` | The requirements interview also writes a small starting KB from your intent |

Set the project type once with `/aid-config`. It is stored as `type: brownfield` or `type: greenfield` in `.aid/settings.yml`.

### Brownfield: `/aid-discover`

`/aid-discover` runs a short state machine. Each run does one step and tells you what comes next.

1. **Elicit.** It asks which external sources (vendor docs, reference URLs) and which tools (a tracker, for example) the project depends on. Tools are catalogued as connectors. See [Connectors and tickets](/guides/connectors-and-tickets/).
2. **Generate.** It confirms the project's domain and the list of documents with you, then several research sub-agents write the documents.
3. **Review.** A separate reviewer grades the documents. See [Review and grades](/guides/review-and-grades/).
4. **Q and A.** Anything the researchers could not settle becomes a question for you.
5. **Fix.** Findings are fixed until the grade meets the minimum.
6. **Approval.** You approve the KB.

Discovery has one strict rule. It must not assume. If two sources disagree, or a term is unclear, it records a question and waits for you instead of guessing. You should see those questions in the discovery state file, `.aid/knowledge/STATE.md`.

To restart from scratch, run `/aid-discover --reset`. To change the grade it must reach, run `/aid-discover --grade A-`.

### Greenfield: forward-authored KB

A new project has no code to read, so there is nothing to discover. Instead, `/aid-describe` adds a step after the interview. It asks about five things and writes them as KB documents marked `source: forward-authored`:

1. The project's vocabulary (`domain-glossary.md`). Required.
2. The intended architecture, at sketch level (`architecture.md`). Required.
3. Conventions and standards (`coding-standards.md`).
4. The technology stack (`technology-stack.md`).
5. Decisions and their reasons (`decisions.md`), only when you confirm real decisions.

A reviewer then checks these documents for consistency with each other.

## Which documents are in the KB

The KB does not have a fixed size. The set is chosen for your project at discovery, confirmed by you, and recorded as `knowledge.doc_set` in `.aid/settings.yml`. The shipped templates give a default set. See [KB documents](/reference/kb-documents/) for the full list and what each holds.

Besides those documents, the folder holds:

- **`PROJECT.md`**, the project card: one page with what the project is, its stack, its build and test commands, where things live and the rules that never bend. Start from the `project-card.md` template.
- **`INDEX.md`**, a table that lists every document with a one-line objective and summary. It is generated; do not edit it by hand.
- **`README.md`**, a completeness tracker for the confirmed document set.
- **`STATE.md`**, the discovery run state: grades, approval, open questions and review history.
- **`kb.html`**, the optional visual tour described below.

## How agents read it

Agents read the KB in tiers, cheapest first. Each step is used only when the one before is not enough.

1. **The project card.** `PROJECT.md` is read first in every session, when the project has one. Claude Code loads it automatically through `CLAUDE.md`.
2. **The index.** `INDEX.md` is opened only to find which document answers a question.
3. **One document.** The agent opens the single document the index points to, never the whole folder.
4. **The exact place in the source.** From that document, the agent goes to the precise file and symbol it cites.

This is retrieval by convention. There are no embeddings and no vector database. The KB is small, so a good index and fixed file names are enough.

## The citation rule

A KB document states a fact only when it can point to where the fact comes from. The `sources:` list in each document's frontmatter names the files it was built from.

When a document cites code in the text, it cites a durable anchor: the file path plus a symbol, heading or unique string you can search for, such as `auth.ts` and `verifyToken`. It does not cite a bare line number, because line numbers move with every edit. A lint script, `kb-citation-lint.sh`, flags bare `file:LINE` citations.

Two more rules keep the KB honest:

- It describes the current state only. History belongs in git.
- It never names a work (`work-NNN`) or a work folder, because works are deleted once they ship.

## Keep it fresh

Code changes faster than documents. AID gives you three tools, from smallest to largest.

| Tool | Use it when | Scope |
|---|---|---|
| `/aid-update-kb` | One fact changed and you want that edit and nothing more | One targeted change |
| `/aid-housekeep` | The project has drifted over time | The whole KB, the summary and stale files |
| `/aid-discover` | You need to rebuild or extend the KB | Full or targeted discovery |

### `/aid-update-kb`

Run it with a sentence: `/aid-update-kb "the API now requires version headers"`. It works in its own git worktree, analyzes how your instruction lands in the KB, and shows you the exact scope. You confirm before any edit. After the edit and a review, you approve a second time. Nothing is applied without both confirmations.

### `/aid-housekeep`

`/aid-housekeep` runs three jobs in a fixed order on a dedicated `aid/housekeep-*` branch, with one commit per stage:

1. **KB delta.** It compares the KB with the repository and finds what drifted, then re-approves the affected documents.
2. **Summary delta.** It rebuilds `kb.html` through `/aid-summarize`.
3. **Cleanup.** It lists stale `.aid/` artifacts and deletes only the ones you confirm.

Use `/aid-housekeep --cleanup-only` to run just the cleanup. If a stage stalls, running it again resumes at that stage.

### How freshness is tracked

Two things make drift visible:

- **The baseline.** `knowledge.source` in `.aid/settings.yml` is the branch the KB is compared against. `knowledge.last_update` records when the KB was last built.
- **Per-document checks.** Each document lists its `sources:` and the commit it was approved at. The freshness check asks git whether any source changed since. The verdict for each document is current, suspect or unknown. Housekeeping examines the suspect ones first, but it does not skip the others.

## Read it as a page: `/aid-summarize`

`/aid-summarize` builds `.aid/knowledge/kb.html`, a single self-contained web page that tours the KB for newcomers. It is written for people who need to understand the project quickly, not for agents.

To run it you need:

- An approved KB. It checks `User Approved: yes` in `.aid/knowledge/STATE.md`.
- Node.js 22 or later, used to validate the page.

Options include `--grade X` to set the grade the page must reach, `--theme` to choose a palette, and `--reset` to force a rebuild. Running it again on an unchanged KB does nothing.

Open `kb.html` in any browser. You should see one section per KB document.

## Related pages

- [KB documents](/reference/kb-documents/) lists each document and who writes it.
- [Review and grades](/guides/review-and-grades/) explains how the KB is graded.
- [Settings reference](/reference/settings/) covers `knowledge.*` and `minimum_grade`.

---
name: aid-ask
description: >
  Optional on-demand read-only Q&A skill. Takes a free-form question and answers
  it in one pass, grounded in three context sources: the Knowledge Base
  (.aid/knowledge/), the live codebase, and in-flight AID works
  (.aid/work-*/STATE.md + progress). Returns an answer with source citations
  (KB doc names, file paths, or work-NNN STATE references). Modifies no files.
  Trivial questions are answered inline (Read/Glob/Grep only); broad or
  expensive investigations dispatch aid-researcher in strictly read-only mode.
  When the available context cannot answer the question, states the gap
  explicitly rather than fabricating an answer.
allowed-tools: Read, Glob, Grep, Agent
argument-hint: "<question>  — a free-form question about the project"
---

# Project Q&A

Answers a free-form question about the project in one pass. Reads context from
the Knowledge Base, the live codebase, and in-flight AID work state, then
replies with source citations. Modifies no files.

**Read-only.** `/aid-ask` never creates, edits, or deletes any file.
The `allowed-tools` grant confirms this: `Read, Glob, Grep, Agent` — no
`Write`, `Edit`, or `Bash`.

**Not a numbered pipeline phase.** `/aid-ask` is an optional, on-demand skill
outside the Discover→Execute flow. No work folder, no STATE.md, no artifacts
written.

**Single-shot, no state machine.** One pass: read context → answer → exit.

---

## Pre-flight

- Confirm a question was supplied. If `/aid-ask` is invoked with no argument,
  print:
  ```
  Usage: /aid-ask <question>
  Example: /aid-ask "Which agent tier handles code review?"
  ```
  Then exit without answering.

---

## Execution: answer the question

### Step 1 — Classify the question

Decide whether the question is **trivial** or **broad/expensive**:

- **Trivial:** answerable by reading a small number of known KB docs or a
  specific file path. Examples: "What does aid-housekeep do?", "Where does the
  generator output go?", "What is the allowed-tools list for aid-researcher?"
- **Broad/expensive:** requires deep codebase traversal, cross-file pattern
  matching, or analysis of many files. Examples: "What are all the places where
  STATE.md is written?", "Summarize every Q&A in the current discovery cycle",
  "How does the render pipeline handle tool-name remapping across all profiles?"

### Step 2a — Trivial question: answer inline

Read only the files needed to answer:

1. Load `.aid/knowledge/INDEX.md` to identify which KB docs are relevant.
2. Read the relevant KB docs (e.g., `architecture.md`, `coding-standards.md`,
   `module-map.md`, `pipeline-contracts.md`, `schemas.md`, etc.) using `Read`.
3. Glob or Grep specific files as needed (e.g., locate a SKILL.md or AGENT.md,
   check a script header, read a work STATE.md).
4. Compose the answer with inline citations:
   - KB doc: cite as "`architecture.md` §Section" or `coding-standards.md §7b`.
   - File path: cite as `.cursor/skills/aid-ask/SKILL.md`.
   - Work state: cite as `work-001-aid-ask STATE.md` or `work-NNN STATE.md §Section`.

### Step 2b — Broad/expensive question: dispatch aid-researcher

Dispatch `aid-researcher` with this prompt structure:

```
TASK: Answer the following question about the project. Operate strictly
read-only — return your analysis as your message; do NOT write, create, edit,
or delete any file.

QUESTION: <the user's question verbatim>

INSTRUCTIONS:
1. Load .aid/knowledge/INDEX.md to navigate the KB.
2. Read the KB docs relevant to the question.
3. Glob or Grep the codebase as needed to gather evidence.
4. Read .aid/work-*/STATE.md files if the question concerns in-flight works.
5. Return a structured answer with source citations (KB doc names, file paths,
   work-NNN STATE references). Do not fabricate facts; if the context cannot
   answer the question, state the gap explicitly.
6. Write nothing. Return everything as your message.
```

Wait for `aid-researcher` to complete. Use its returned message as the answer
body for Step 3.

### Step 3 — Compose and emit the reply

Format the answer as:

```
## Answer

<answer text, grounded in the evidence gathered>

## Sources

- <citation 1>  (e.g., `architecture.md §Thin-Router state machine`)
- <citation 2>  (e.g., `.cursor/skills/aid-housekeep/SKILL.md`)
- <citation 3>  (e.g., `work-001-aid-ask STATE.md §Goal`)
```

If context is insufficient to answer:

```
## Answer

The available context does not contain enough information to answer this
question: <restate the question briefly>.

## Gap

<Describe specifically what is missing — which KB doc lacks the data, which
codebase subtree was not reachable, or which work STATE.md did not exist.>

## Sources

- <doc or path checked>
- <doc or path checked>
```

Do NOT fabricate an answer. Stating the gap is the correct response when
context is insufficient.

---

## Dispatch table

| Condition | Worker | Output |
|-----------|--------|--------|
| Trivial question | inline (Read / Glob / Grep) | Answer in conversation |
| Broad/expensive question | `aid-researcher` (read-only) | Answer in conversation |

The dispatched `aid-researcher` MUST be instructed to operate strictly
read-only (return analysis as its message; write nothing). See Step 2b for the
required prompt.

---

## Constraints

- **No writes.** This skill never creates, modifies, or deletes any file —
  enforced by the `allowed-tools` frontmatter (`Read, Glob, Grep, Agent`).
- **No work folder.** `/aid-ask` does not create `.aid/work-*/` directories or
  STATE.md files for its own use.
- **Cite sources.** Every factual claim in the answer must be traceable to a KB
  doc, a file path, or a work STATE.md reference.
- **State gaps explicitly.** When the context cannot answer, say so clearly.
  Never invent data.
- **Read-only dispatch.** When `aid-researcher` is dispatched, its prompt MUST
  instruct it to return analysis as its message and write nothing.

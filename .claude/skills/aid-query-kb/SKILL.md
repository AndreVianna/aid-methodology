---
name: aid-query-kb
description: >
  Optional on-demand Q&A skill. Takes a free-form question and answers it in
  one pass, grounded in three context sources: the Knowledge Base
  (.aid/knowledge/), the live codebase, and in-flight AID works
  (.aid/work-*/STATE.md + progress). Returns an answer with source citations
  (KB doc names, file paths, or work-NNN STATE references). When the available
  context cannot answer the question, states the gap explicitly rather than
  fabricating an answer AND captures the gap as a Query-Gap entry in the
  STATE.md Q&A (Pending) backlog so it feeds the KB-improvement loop.
  Trivial questions are answered inline (Read/Glob/Grep only); broad or
  expensive investigations dispatch aid-researcher in strictly read-only mode.
  Writes are restricted to appending a Query-Gap entry to a STATE.md Q&A
  (Pending) section; no KB doc, settings, or code file is ever written.
allowed-tools: Read, Glob, Grep, Agent, Write, Edit
argument-hint: "<question>  — a free-form question about the project"
---

# Project Q&A

Answers a free-form question about the project in one pass. Reads context from
the Knowledge Base, the live codebase, and in-flight AID work state, then
replies with source citations.

**Write scope (gap-capture only).** `/aid-query-kb` writes to exactly one place
and only when the context is insufficient to answer: it appends a `### Q{N}`
Query-Gap entry to a `## Q&A (Pending)` section of a `STATE.md` backlog file.
No KB doc, settings file, or code file is ever written. The answer path stays
fully read-only; only the gap-append branch writes (NFR-6/C4: capture-and-flag,
never auto-apply).

**Not a numbered pipeline phase.** `/aid-query-kb` is an optional, on-demand skill
outside the Discover-Execute flow. No work folder, no STATE.md of its own.

**Single-shot, no state machine.** One pass: read context -> answer -> exit.

---

## Pre-flight

- Confirm a question was supplied. If `/aid-query-kb` is invoked with no argument,
  print:
  ```
  Usage: /aid-query-kb <question>
  Example: /aid-query-kb "Which agent tier handles code review?"
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
   - File path: cite as `.claude/skills/aid-query-kb/SKILL.md`.
   - Work state: cite as `work-001-kb-skills STATE.md` or `work-NNN STATE.md §Section`.

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

### Step 2c — Connector enrichment (optional)

When the question concerns a specific item tracked in a catalogued connector (e.g. "what's the
status of PROJ-45?"), consult it per
`.claude/aid/templates/connectors/consumption-protocol.md` (scan `.aid/connectors/INDEX.md`;
for a `connection_type: mcp` match, request the connection from the host tool's own MCP — AID
resolves nothing and stores no credential) and fold what it returns into the answer, cited the
same way as any other source (Step 3). Skip silently when no matching connector is catalogued —
this never blocks or replaces the KB/codebase/in-flight-work answer path above.

### Step 3 — Compose and emit the reply

Format the answer as:

```
## Answer

<answer text, grounded in the evidence gathered>

## Sources

- <citation 1>  (e.g., `architecture.md §Thin-Router state machine`)
- <citation 2>  (e.g., `.claude/skills/aid-housekeep/SKILL.md`)
- <citation 3>  (e.g., `work-NNN STATE.md §Goal`)
```

If context is insufficient to answer, emit the reply AND then capture the gap:

**Reply (always emit first):**

```
## Answer

The available context does not contain enough information to answer this
question: <restate the question briefly>.

## Gap

<Describe specifically what is missing -- which KB doc lacks the data, which
codebase subtree was not reachable, or which work STATE.md did not exist.>

## Sources

- <doc or path checked>
- <doc or path checked>
```

**Gap capture (Step 4) -- append after emitting the reply:**

Resolve the target backlog file using the rule in Step 4 below, determine the
next free `Q{N}` in that backlog (never renumber), then append the entry.

Do NOT fabricate an answer. Stating the gap and capturing it is the correct
response when context is insufficient.

---

### Step 4 -- Gap capture

When Step 3 emits a gap reply, immediately capture the gap into the Q&A backlog.

**Target-file resolution:**

- If the query was about an **in-flight work** (the question concerns a specific
  `.aid/work-NNN-*/` effort whose STATE.md exists), write to that work's
  `.aid/work-NNN-*/STATE.md` `## Q&A (Pending)` section.
- Otherwise write to the **knowledge backlog** at
  `.aid/knowledge/STATE.md` `## Q&A (Pending)`.
- **When ambiguous** (the query touches both a work and the KB), default to
  `.aid/knowledge/STATE.md` and name the alternative work in the entry's
  Context field. (A Q&A append is non-destructive, so default-and-name is the
  proportionate choice over asking the user.)

**Determine `N`:** read the target backlog file, grep for all `### Q[0-9]+`
headers, find the highest number, and set `N = highest + 1`. If no Q entries
exist yet, set `N = 1`. Never renumber existing entries.

**Classify the gap flavor:**

- `KB-contradicts-code`: the KB asserts a fact that directly contradicts what
  the live code says. Impact = `High`.
- `KB-cannot-answer`: the KB simply lacks coverage for the question. Impact = `Medium`.

**Append the following entry** (no trailing blank lines needed beyond the
standard one-blank-line separator between entries):

```
### Q{N}
- **Category:** Query-Gap / <KB-cannot-answer | KB-contradicts-code>
- **Impact:** <High | Medium>
- **Status:** Pending
- **Context:** /aid-query-kb was asked "<question verbatim>". The available
  context could not answer it: <the specific gap -- which KB doc lacks the
  data, OR the exact KB claim that contradicts the code with both citations>.
  Sources checked: <docs/paths>.
- **Suggested:** Run /aid-update-kb "<the gap as an update prompt>" (or fold
  into the next /aid-housekeep KB-DELTA) to close the gap, then
  REVIEW -> APPROVAL.
```

Write-scope constraint (hard): **writes are restricted to appending a
Query-Gap entry to a `STATE.md ## Q&A (Pending)` section; no KB doc,
settings, or code file is ever written.** If the resolved target file does not
have a `## Q&A (Pending)` section, append the section heading before the
entry. Do not modify any other part of the file.

---

## Dispatch table

| Condition | Worker | Output |
|-----------|--------|--------|
| Trivial question | inline (Read / Glob / Grep) | Answer in conversation |
| Broad/expensive question | `aid-researcher` (read-only) | Answer in conversation |
| Insufficient context | inline + gap-capture write | Gap reply + Q{N} entry appended to STATE.md |

The dispatched `aid-researcher` MUST be instructed to operate strictly
read-only (return analysis as its message; write nothing). See Step 2b for the
required prompt.

---

## Constraints

- **Write scope (gap-capture only).** Writes are restricted to appending a
  Query-Gap `### Q{N}` entry to a `STATE.md ## Q&A (Pending)` section. No KB
  doc, settings, or code file is ever written. The answer path stays read-only;
  only the gap-append branch writes.
- **No work folder.** `/aid-query-kb` does not create `.aid/work-*/` directories or
  STATE.md files for its own use.
- **Cite sources.** Every factual claim in the answer must be traceable to a KB
  doc, a file path, or a work STATE.md reference.
- **State gaps explicitly.** When the context cannot answer, say so clearly.
  Never invent data.
- **Read-only dispatch.** When `aid-researcher` is dispatched, its prompt MUST
  instruct it to return analysis as its message and write nothing.

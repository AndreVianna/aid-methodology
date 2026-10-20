---
name: aid-ask
description: >
  Answer a question about this project, with citations. Use this skill when you want to know
  something -- how a part of the system works, what a document says, where a piece of work
  stands -- and you want a grounded answer rather than a guess. It reads three sources: the
  Knowledge Base, the live codebase, and any AID work currently in flight, and cites
  whichever it used, by document name, file path, or work reference. When those sources
  genuinely cannot answer, it says so instead of inventing an answer, and records the gap so
  it feeds back into improving the Knowledge Base. Trivial questions are answered inline;
  broad investigations are dispatched read-only. The only thing it ever writes is that
  recorded gap.
allowed-tools: Read Glob Grep Agent Write Edit Bash Shell Terminal
argument-hint: "<question>  — a free-form question about the project"
---

# Project Q&A

Answers a free-form question about the project in one pass. Reads context from
the Knowledge Base, the live codebase, and in-flight AID work state, then
replies with source citations.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

**Write scope (gap-capture only).** `/aid-ask` writes to exactly one place
and only when the context is insufficient to answer: it records a Query-Gap entry,
through the writer in an in-flight work's `qa`, or as a `### Q{N}` entry in the
`## Q&A (Pending)` section of the knowledge backlog (`.aid/knowledge/STATE.md`).
No KB doc, settings file, or code file is ever written. The answer path stays
fully read-only; only the gap-append branch writes (NFR-6/C4: capture-and-flag,
never auto-apply).

**Not a numbered pipeline phase.** `/aid-ask` is an optional, on-demand skill
outside the pipeline phases. No work folder, no state file of its own.

**Single-shot, no state machine.** One pass: read context -> answer -> exit.

**Step rules:** the advance words, the step procedure and the work record are
`.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

**State Detection** (`.aid/runtime/templates/skill-steps.md`): there is no saved step to
resume, so detection has nothing to validate; it never routes.

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
  STATE.yml is written?", "Summarize every Q&A in the current discovery cycle",
  "How does the render pipeline handle tool-name remapping across all profiles?"

### Step 2a — Trivial question: answer inline

Read only the files needed to answer:

1. Load `.aid/knowledge/INDEX.md` to identify which KB docs are relevant.
2. Read the relevant KB docs (e.g., `architecture.md`, `coding-standards.md`,
   `module-map.md`, `pipeline-contracts.md`, `schemas.md`, etc.) using `Read`.
3. Glob or Grep specific files as needed (e.g., locate a SKILL.md or AGENT.md,
   check a script header, read a work's STATE.yml).
4. Compose the answer with inline citations:
   - KB doc: cite as "`architecture.md` §Section" or `coding-standards.md §7b`.
   - File path: cite as `.agents/skills/aid-ask/SKILL.md`.
   - Work state: cite as `work-001-kb-skills STATE.yml` or `work-NNN STATE.yml §Section`.

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
4. Read .aid/works/work-*/STATE.yml files if the question concerns in-flight works.
5. Return a structured answer with source citations (KB doc names, file paths,
   work-NNN STATE.yml references). Do not fabricate facts; if the context cannot
   answer the question, state the gap explicitly.
6. Write nothing. Return everything as your message.
```

Wait for `aid-researcher` to complete. Use its returned message as the answer
body for Step 3.

### Step 2c — Connector enrichment (optional)

When the question concerns a specific item tracked in a catalogued connector (e.g. "what's the
status of PROJ-45?"), fetch it by invoking `/aid-read-ticket [<connector>:]<ticket-id>` — the
connector resolution and host-MCP fetch live there (feature-001); no direct-fetch recipe is
re-implemented here — and fold what it returns into the answer, cited the same way as any other
source (Step 3). Skip silently when no matching connector is catalogued — this never blocks or
replaces the KB/codebase/in-flight-work answer path above; the delegated read is non-destructive,
so no extra confirm is added.

### Step 3 — Compose and emit the reply

Format the answer as:

```
## Answer

<answer text, grounded in the evidence gathered>

## Sources

- <citation 1>  (e.g., `architecture.md §Thin-Router state machine`)
- <citation 2>  (e.g., `.agents/skills/aid-housekeep/SKILL.md`)
- <citation 3>  (e.g., `work-NNN STATE.yml`, the `intent` key)
```

If context is insufficient to answer, emit the reply AND then capture the gap:

**Reply (always emit first):**

```
## Answer

The available context does not contain enough information to answer this
question: <restate the question briefly>.

## Gap

<Describe specifically what is missing -- which KB doc lacks the data, which
codebase subtree was not reachable, or which work STATE.yml did not exist.>

## Sources

- <doc or path checked>
- <doc or path checked>
```

**Gap capture (Step 4) -- append after emitting the reply:**

Resolve the target backlog file using the rule in Step 4 below, determine the
next free `Q{N}` in that backlog (never renumber), then record the entry (Step 4).

Do NOT fabricate an answer. Stating the gap and capturing it is the correct
response when context is insufficient.

---

### Step 4 -- Gap capture

When Step 3 emits a gap reply, immediately capture the gap into the Q&A backlog.

**Target-file resolution:**

- If the query was about an **in-flight work** (the question concerns a specific
  `.aid/works/work-NNN-*/` effort whose STATE.yml exists), record the gap in that
  work's own `.aid/works/work-NNN-*/STATE.yml` `qa` sequence. Every work keeps its
  `qa` in its work-root STATE.yml, whatever its layout; a delivery's own file is
  never written.
- Otherwise write to the **knowledge backlog** at
  `.aid/knowledge/STATE.md` `## Q&A (Pending)`.
- **When ambiguous** (the query touches both a work and the KB), default to
  `.aid/knowledge/STATE.md` and name the alternative work in the entry's
  Context field. (A Q&A append is non-destructive, so default-and-name is the
  proportionate choice over asking the user.)

**Determine `N`:** for a work, the writer assigns the next free id (`Q<n>`) and
prints it; never renumber existing entries. For the knowledge backlog, read its
`## Q&A (Pending)` section, find the highest `### Q[0-9]+`, and set `N = highest + 1`
(or `N = 1` when it is empty). (The knowledge backlog keeps its markdown scheme until
the KB moves to its own state file.)

**Classify the gap flavor:**

- `KB-contradicts-code`: the KB asserts a fact that directly contradicts what
  the live code says. Impact = `High`.
- `KB-cannot-answer`: the KB simply lacks coverage for the question. Impact = `Medium`.

**Record the entry.** For a work, write it through the writer, which appends a `Pending`
entry to the work's `qa` and prints its id. This skill runs from the project root, not from
the work's worktree, so always point the writer at that work's record with `AID_STATE_FILE`:

```
AID_STATE_FILE=.aid/works/work-NNN-<slug>/STATE.yml bash .aid/runtime/scripts/execute/writeback-state.sh \
  --ask --category 'Query-Gap / <KB-cannot-answer | KB-contradicts-code>' --impact <High | Medium> \
  --asked-by aid-ask \
  --context '/aid-ask was asked "<question verbatim>". The available context could not answer it: <the specific gap -- which KB doc lacks the data, OR the exact KB claim that contradicts the code with both citations>. Sources checked: <docs/paths>.' \
  --suggested 'Run /aid-update-kb "<the gap as an update prompt>" (or fold into the next /aid-housekeep KB-DELTA) to close the gap, then REVIEW -> APPROVAL.'
```

For the knowledge backlog, append the `### Q{N}` entry to `.aid/knowledge/STATE.md`
`## Q&A (Pending)`, in its markdown shape, as today.

Write-scope constraint (hard): **writes are restricted to recording a Query-Gap entry
through the writer in a work's `qa`, or appending to the knowledge backlog's
`## Q&A (Pending)` section; no KB doc, settings, or code file is ever written.** Do not
modify any other part of the file.

---

## Dispatch table

| Condition | Worker | Output |
|-----------|--------|--------|
| Trivial question | inline (Read / Glob / Grep) | Answer in conversation |
| Broad/expensive question | `aid-researcher` (read-only) | Answer in conversation |
| Insufficient context | inline + gap-capture write | Gap reply + Q{N} entry appended to the `qa` sequence (STATE.yml) |

The dispatched `aid-researcher` MUST be instructed to operate strictly
read-only (return analysis as its message; write nothing). See Step 2b for the
required prompt.

---

## Constraints

- **Write scope (gap-capture only).** Writes are restricted to recording a
  Query-Gap entry (id/category/impact/state/context/suggested) through the writer in a
  work's `qa` sequence, or appending to the knowledge backlog's `## Q&A (Pending)`
  section. No KB doc, settings, or code file is ever written. The answer path
  stays read-only; only the gap-append branch writes.
- **No work folder.** `/aid-ask` does not create `.aid/works/work-*/` directories or
  STATE.yml files for its own use.
- **Cite sources.** Every factual claim in the answer must be traceable to a KB
  doc, a file path, or a work STATE.yml reference.
- **State gaps explicitly.** When the context cannot answer, say so clearly.
  Never invent data.
- **Read-only dispatch.** When `aid-researcher` is dispatched, its prompt MUST
  instruct it to return analysis as its message and write nothing.

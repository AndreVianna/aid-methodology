---
name: aid-ask
description: >
  Friendly-named alias of /aid-query-kb -- the optional on-demand Q&A skill.
  Takes a free-form question and answers it in one pass, grounded in three
  context sources: the Knowledge Base (.aid/knowledge/), the live codebase,
  and in-flight AID works (.aid/works/work-*/STATE.md + progress). Returns an
  answer with source citations. When the available context cannot answer the
  question, states the gap explicitly and captures it as a Query-Gap entry so
  it feeds the KB-improvement loop. This file carries no logic of its own --
  its full behavior is defined entirely by
  canonical/skills/aid-query-kb/SKILL.md, which this skill delegates to.
allowed-tools: Read, Glob, Grep, Agent, Write, Edit
argument-hint: "<question>  — a free-form question about the project"
---

# Project Q&A (alias of /aid-query-kb)

`/aid-ask` is the friendly-named alias of **`/aid-query-kb`**
(`canonical/skills/aid-query-kb/SKILL.md`) -- `aid-query-kb` was renamed FROM
`aid-ask` in commit `cf6cb1af`; this file restores the shorter, friendlier
invocation name as a thin alias, per the same alias-is-a-full-directory
convention the generated shortcut catalog uses
(`canonical/aid/templates/shortcut-catalog.yml`'s Topology note: an alias is a
full, separate `canonical/skills/<name>/SKILL.md` directory -- not a redirect
the generator resolves). It is registered in the catalog as
`alias_of: aid-query-kb`, `repurpose: true` (never generated or overwritten by
`build-shortcut-skills.py`, which skips every `repurpose: true` row -- this
file is hand-authored, like `aid-query-kb` itself).

**This file has no logic of its own.** Its entire behavior -- question
classification (trivial vs. broad/expensive), the inline-vs-`aid-researcher`
dispatch, the answer format, the write-scope constraint (gap-capture only, no
KB/settings/code file ever written), and every other rule -- is defined
exclusively by `canonical/skills/aid-query-kb/SKILL.md`. Read that file and
execute it exactly as written, substituting nothing except the invocation
name in any printed usage example (`/aid-ask` instead of `/aid-query-kb`):
single-shot, read-only except for the one gap-capture write, grounded in the
Knowledge Base + the live codebase + in-flight `.aid/works/work-*/STATE.md` works,
cited, no work folder, no state machine of its own. Duplicating that logic
here would let the two skills drift out of sync (`feedback` precedent: KB
docs never re-derive what another document already owns); this file exists
only so a user who reaches for the shorter, friendlier name still gets the
exact same skill.

## Pre-flight

Same as `aid-query-kb`'s own Pre-flight (`canonical/skills/aid-query-kb/SKILL.md
§ Pre-flight`): confirm a question was supplied. If `/aid-ask` is invoked with
no argument, print:

```
Usage: /aid-ask <question>
Example: /aid-ask "Which agent tier handles code review?"
```

Then exit without answering.

## Execution

Delegate to `canonical/skills/aid-query-kb/SKILL.md § Execution: answer the
question` in full -- Step 1 (classify trivial vs. broad/expensive), Step 2a
(trivial: answer inline from KB/codebase reads), Step 2b (broad/expensive:
dispatch `aid-researcher` read-only), Step 3 (compose the reply, with the
gap-reply shape when context is insufficient), and Step 4 (gap capture: append
a `### Q{N}` Query-Gap entry to the resolved backlog's `## Q&A (Pending)`
section). Every constraint that file states (`§ Constraints`) applies here
unchanged: cite sources, never fabricate, write nothing beyond the one
gap-capture append, no `.aid/works/work-*/` folder or `STATE.md` of `/aid-ask`'s own.

---
name: aid-document-decision
description: >
  Write an ADR NOW -- an architecture decision record (Context -> Decision ->
  Alternatives -> Consequences) -- in one pass. A thin kind-sibling of
  /aid-create-document with the document genre bound to ADR. Grounded in and
  accuracy-checked against the Knowledge Base (.aid/knowledge/) and the project source;
  produced by aid-tech-writer, verified by aid-reviewer. It RESOLVES NOTHING -- drafts,
  you approve, then it is placed. NEVER writes into .aid/knowledge/. This file carries no
  logic of its own -- its full behavior is defined by
  .claude/skills/aid-create-document/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<decision> -- the decision to record"
---

# Document Decision (ADR kind-sibling of /aid-create-document)

`/aid-document-decision` is a thin **kind-sibling** of **`/aid-create-document`**
(`.claude/skills/aid-create-document/SKILL.md`) -- not an alias: it is its own catalog
row (`alias_of: null`, its own `{verb: document, artifact: decision}`), `repurpose: true`
(skipped by `build-shortcut-skills.py`; hand-authored). It carries **no logic of its own.**

Execute `.claude/skills/aid-create-document/SKILL.md` exactly as written, with the
document **genre bound to ADR** (structure: Context -> Decision -> Alternatives ->
Consequences) and the **format = markdown**. Substitute only the invocation name in any
printed usage example (`/aid-document-decision` instead of `/aid-create-document`).
Deeper genre structures: `.claude/aid/templates/shortcut-scaffolding/document.md`.

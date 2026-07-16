---
name: aid-spike
description: >
  Alias of /aid-research -- investigate an open technical question NOW and return
  a curated, verified answer that RESOLVES NOTHING (presents conclusions +/-,
  conflicts with their reasons, and gaps for you to resolve). "Spike" emphasizes
  the feasibility-question flavor; aid-research handles that via its
  human-authorized, isolated, throwaway spike escalation (it never spikes code
  without your approval). This file carries no logic of its own -- its full
  behavior is defined by .cursor/skills/aid-research/SKILL.md.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "<question> -- a feasibility question to investigate"
---

# Research (alias of /aid-research)

`/aid-spike` is the alias of **`/aid-research`** (`.cursor/skills/aid-research/SKILL.md`),
per the alias-is-a-full-directory convention the shortcut catalog uses (an alias is a full,
separate `.cursor/skills/<name>/SKILL.md` directory, not a redirect the generator
resolves). Registered `alias_of: aid-research`, `repurpose: true` (skipped by
`build-shortcut-skills.py`; hand-authored, like `aid-research`).

**This file has no logic of its own.** Its entire behavior is defined exclusively by
`.cursor/skills/aid-research/SKILL.md` -- including the **feasibility-spike escalation**
that the name "spike" evokes: research stays analytical by default and only writes a
**throwaway, isolated spike (never touching production) after your explicit
authorization**, folding the finding back into the answer. Read that file and execute it
exactly as written, substituting nothing except the invocation name in any printed usage
example (`/aid-spike` instead of `/aid-research`). Duplicating the logic here would let the
two drift out of sync.

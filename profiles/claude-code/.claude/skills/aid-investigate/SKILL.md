---
name: aid-investigate
description: >
  Alias of /aid-research -- investigate an open technical question NOW and return
  a curated, verified answer that RESOLVES NOTHING (presents conclusions +/-,
  conflicts with their reasons, and gaps for you to resolve). Grounded in the
  Knowledge Base + project source (authoritative) with supplementary cited web
  sources; produced by aid-researcher, verified by aid-reviewer. This file carries
  no logic of its own -- its full behavior is defined by
  .claude/skills/aid-research/SKILL.md.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<question> -- an open technical question to investigate"
---

# Research (alias of /aid-research)

`/aid-investigate` is the alias of **`/aid-research`** (`.claude/skills/aid-research/SKILL.md`),
per the alias-is-a-full-directory convention the shortcut catalog uses (an alias is a full,
separate `.claude/skills/<name>/SKILL.md` directory, not a redirect the generator
resolves). Registered `alias_of: aid-research`, `repurpose: true` (skipped by
`build-shortcut-skills.py`; hand-authored, like `aid-research`).

**This file has no logic of its own.** Its entire behavior -- the fast/guided question
intake, the work-folder allocation, two-tier grounding (KB+source authoritative, web
supplementary+cited, KB<->web conflicts surfaced with reasons), the clean-context
`aid-researcher` INVESTIGATE, the human-authorized isolated spike escalation, the
`aid-reviewer` VERIFY + grade loop, the resolves-nothing PRESENT, and every constraint --
is defined exclusively by `.claude/skills/aid-research/SKILL.md`. Read that file and
execute it exactly as written, substituting nothing except the invocation name in any
printed usage example (`/aid-investigate` instead of `/aid-research`). Duplicating the
logic here would let the two drift out of sync.

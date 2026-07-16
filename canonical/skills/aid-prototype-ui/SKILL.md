---
name: aid-prototype-ui
description: >
  Alias of /aid-prototype (ui hint) -- build a THROWAWAY low-fidelity UI
  wireframe/mock + interaction flow NOW to validate a UX direction, then present
  what it shows and hand the real build off. Resolves nothing; isolated and
  throwaway. This file carries no logic of its own -- its full behavior is defined
  by canonical/skills/aid-prototype/SKILL.md, with "ui" as the prototype target.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<screen/flow> -- the UI screen(s)/flow whose direction to validate"
---

# Prototype UI (alias of /aid-prototype)

`/aid-prototype-ui` is the backward-compatible **ui hint-alias** of `/aid-prototype`
(`canonical/skills/aid-prototype/SKILL.md`), per the alias-is-a-full-directory convention
the shortcut catalog uses. Registered `alias_of: aid-prototype`, `repurpose: true`
(hand-authored; skipped by `build-shortcut-skills.py`). Historically its own skill; folded
into generic `aid-prototype` in work-005 because a UI is just one prototype target.

**This file has no logic of its own.** Execute `canonical/skills/aid-prototype/SKILL.md`
exactly as written, with the prototype **target bound to `ui`** -- so INTAKE captures the
target screen(s)/flow, key interactions and states (loading/empty/error/success), and
navigation context, and the model is a UI wireframe/mock + interaction flow with
accessibility notes. Everything else (throwaway + isolated, `aid-architect` producer, LIGHT
verify, resolves-nothing PRESENT, handoff to `/aid-create-ui`) is `aid-prototype`'s.
Substitute only the invocation name (`/aid-prototype-ui`) in any printed usage example. For
a KEPT UI design meant to be built, use `/aid-design`.

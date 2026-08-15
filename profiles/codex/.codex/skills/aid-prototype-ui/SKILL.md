---
name: aid-prototype-ui
description: >
  Build a throwaway, low-fidelity UI wireframe and interaction flow to test whether a UX
  direction actually works. Use this skill when you want to see a screen before committing
  to building it. Isolated and disposable: it never touches production, and it reports what
  the mock shows rather than deciding anything for you. For a kept UI design meant to inform
  the real build rather than a throwaway that validates a direction, use /aid-design-ui
  instead. A thin kind-sibling of /aid-prototype, which defines its full behavior.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<screen/flow> -- the UI screen(s)/flow whose direction to validate"
---

# Prototype UI (ui kind-sibling of /aid-prototype)

`/aid-prototype-ui` is a thin **ui kind-sibling** of `/aid-prototype`
(`.codex/skills/aid-prototype/SKILL.md`) -- not an alias: it is its own catalog row
(`alias_of: null`, its own `{verb: prototype, artifact: ui}`), `repurpose: true`
(hand-authored; skipped by `build-shortcut-skills.py`). Historically its own generated
skill; its behavior folded into generic `aid-prototype` in work-005 because a UI is just
one prototype target.

**This file has no logic of its own.** Execute `.codex/skills/aid-prototype/SKILL.md`
exactly as written, with the prototype **target bound to `ui`** -- so INTAKE captures the
target screen(s)/flow, key interactions and states (loading/empty/error/success), and
navigation context, and the model is a UI wireframe/mock + interaction flow with
accessibility notes. Everything else (throwaway + isolated, `aid-architect` producer, LIGHT
verify, resolves-nothing PRESENT, handoff to `/aid-create-ui`) is `aid-prototype`'s.
Substitute only the invocation name (`/aid-prototype-ui`) in any printed usage example. For
a KEPT UI design meant to be built, use `/aid-design`.

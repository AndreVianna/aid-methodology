# Design seed — Intent → skill routing table in `rules.md`

**Status:** not started · **Seeded:** 2026-10-11 · **Depends on:** AID v4.0.0 (shared skills
folder), which introduces `.aid/runtime/rules.md` and the `AGENTS.md` pointer region.

> Entry A (hand-written) seed. When the work ships, delete it: the design then lives in
> `canonical/aid/rules.md` and its generator/test.

## Problem

The maintainer wants to ask for AID work in plain words ("execute the tasks", "update the docs")
and have the agent pick the right skill, without typing `/aid-<skill>`. Every host that follows the
Agent Skills standard (Claude Code, Codex, Cursor, Antigravity, Copilot CLI) already routes this
way: the agent sees each skill's `name` and `description` and loads the skill whose description
matches the request. A slash command only forces one skill and skips that matching.

For AID the matching is unreliable:

- **Too many skills.** AID ships 112 skills. Claude Code gives the skill listing about 1% of the
  context; on overflow it drops descriptions, least-used first. In a live Claude Code session on
  this repo, `aid-execute`, `aid-plan`, `aid-detail` and many others appeared as bare names with no
  description, so a plain request has only a name to match against.
- **Overlapping skills.** Several skills fit one request (e.g. "update the docs" →
  `aid-update-kb`, `aid-update-document` or `aid-document`).
- **Per-host behaviour differs.** Each host has its own listing budget and matching; nothing in the
  repo steers them the same way.

## Options considered

1. **Intent → skill table in the always-loaded rules** (`canonical/aid/rules.md`, installed as
   `.aid/runtime/rules.md` and reached through the `AGENTS.md` pointer). A short table maps common
   request phrasings to the one skill that handles them, with tie-breakers for overlapping skills.
   Works in every host, because every host reads the rules. *Proposed.*
2. **Description hygiene.** Make every skill `description` lead with its trigger ("Use when …"),
   keep it short, and name what distinguishes it from its neighbours. Helps every host, but does
   not survive a host dropping descriptions. *Proposed as a complement to 1.*
3. **Bigger skill-listing budget.** Claude Code's `skillListingBudgetFraction` (e.g. `0.02`) or
   `skillOverrides` (`"name-only"` for rarely used skills). Claude Code only, user-level setting;
   cannot be shipped per project. *Document as an optional user tip, not the fix.*
4. **Fewer visible skills.** Mark internal or rarely-invoked skills with
   `disable-model-invocation: true` so they do not compete for matching (they stay slash-invocable).
   Shrinks the listing, but hides skills a plain request should reach. *Evaluate per skill; not a
   default.*
5. **Keep slash commands only.** Always precise, but defeats the goal. *Rejected as the sole
   approach; remains the guaranteed path.*

## Current direction

Options 1 + 2, with 3 documented as a user tip:

- Add a section to `canonical/aid/rules.md` (for example `## Skill routing`) holding a compact
  table: `When the user asks to … | Use skill | Not to be confused with`. Cover the pipeline phases
  (discover, describe, define, specify, plan, detail, execute), the common shortcuts (create /
  update / fix / refactor / test / document families), and the on-demand skills (ask, research,
  brainstorm, review, report, housekeep, config, connectors, chat).
- State the routing rules in two lines above the table: prefer the most specific skill (an
  artifact-suffixed shortcut over the bare verb); when two still fit, ask one short question
  instead of guessing; an explicit `/aid-<skill>` always wins.
- **Generate, do not hand-maintain** the table: derive rows from the shortcut catalog
  (`canonical/aid/templates/shortcut-catalog.yml`) plus a small hand-curated list for the pipeline
  and on-demand skills, so the table cannot drift from the shipped skill set. A test fails when a
  shipped skill is missing from the table or a row names a skill that does not exist.
- Run a description-hygiene pass over `canonical/skills/*/SKILL.md` (lead with the trigger, short,
  distinguishing clause), with a lint for description length and the "Use when" lead.
- Mention the Claude Code `skillListingBudgetFraction` / `skillOverrides` tip in the install docs.

## Constraints

- `rules.md` is loaded every session in every host: the table must stay small (target: one
  screen; group families into single rows rather than one row per skill).
- One source of truth: rows are generated from the catalog; descriptions remain the per-skill
  truth; the table only routes.
- Must not change any skill's behaviour, name or invocation; slash commands keep working.
- Must stay byte-identical across hosts (it ships inside the shared runtime).

## Open questions

- Grouping granularity: one row per family (e.g. "create a <thing>" → `aid-create-<artifact>`) or
  one row per skill?
- Should the routing table also list the agents (`aid-architect`, `aid-reviewer`, …) for hosts that
  dispatch sub-agents by name?
- Is a probe needed to confirm each host honours the table over its own description matching
  (same method as the v4 `AGENTS.md` pointer probe)?

## Destination

`canonical/aid/rules.md` (new `## Skill routing` section), its generator and test under
`.claude/skills/generate-profile/scripts/` and `tests/canonical/`, and a description-hygiene pass
over `canonical/skills/*/SKILL.md` — scoped as a follow-up `/aid-update` work after AID v4.0.0
ships.

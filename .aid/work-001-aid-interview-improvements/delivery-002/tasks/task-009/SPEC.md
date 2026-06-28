# task-009: grant aid-researcher web capabilities (WebSearch + WebFetch)

**Type:** CONFIGURE

**Source:** work-001-aid-interview-improvements -> delivery-002 (debt discovered during delivery-001 execution; folded in per owner direction 2026-06-27)

**Depends on:** -- (none; independent of the other delivery-002 tasks)

**Scope:**
- **Rationale (traceability):** delivery-001's RESEARCH spike required a genuine WEB survey (the 7
  elicitation/domain-discovery families + the "web-trending" grill-me approach). The canonical
  RESEARCH executor `aid-researcher` has `tools: Read, Glob, Grep, Bash, Write` -- **no web tools** --
  so the spike had to be dispatched on `general-purpose` agents instead of the type-appropriate
  executor. This is an agent-capability gap: RESEARCH is exactly the task type that may need the web.
- **The fix:** in `canonical/agents/aid-researcher/AGENT.md`, add **`WebSearch`** and **`WebFetch`**
  to the frontmatter `tools:` line (new value: `Read, Glob, Grep, Bash, Write, WebSearch, WebFetch`).
  No other canonical agent is changed (web access is scoped to the researcher, the one agent whose
  job is information-gathering).
- Update the agent's prose so the capability is coherent: extend the `description:` and the
  `## What You Do` list to state it may research **external / web sources** (current documentation,
  standards, prior art) with cited URLs + access dates, consistent with the dual-audience evidence
  standard. Keep `## What You Don't Do` honest (e.g. no unsourced claims).
- **Propagate:** run the FULL `python .claude/skills/generate-profile/scripts/run_generator.py` so
  the 5 profile copies (`profiles/*/.../agents/aid-researcher/AGENT.md`) + the `.claude/` dogfood
  mirror are regenerated and the emission manifests updated; render-drift CI must stay green and DBI
  byte-identity must hold.
- Register the gap as a resolved item in `.aid/knowledge/tech-debt.md` (one new row; surgical) so it
  is traceable.

**Acceptance Criteria:**
- [ ] `canonical/agents/aid-researcher/AGENT.md` frontmatter `tools:` includes `WebSearch` and `WebFetch`; no other agent's tools changed (verify via grep across `canonical/agents/`).
- [ ] The agent description + `## What You Do` coherently state the web-research capability (with the cited-source expectation); `## What You Don't Do` not contradicted.
- [ ] FULL `run_generator.py` run: the 5 `profiles/*/.../agents/aid-researcher/AGENT.md` copies + the `.claude/` mirror reflect the new tools line; DBI byte-identity holds; emission manifests updated; render-drift clean.
- [ ] `.aid/knowledge/tech-debt.md` carries a new resolved row for this gap (surgical edit; other rows untouched).
- [ ] `tests/run-all.sh` (HOME-pinned) stays green; ASCII-only; no scope creep beyond the researcher agent + its propagation + the tech-debt row.
- [ ] All REQUIREMENTS.md §6 quality gates pass.

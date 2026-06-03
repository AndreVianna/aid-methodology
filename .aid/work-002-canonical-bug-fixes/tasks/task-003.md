# task-003: D1 — heartbeat/Bash mismatch: grant Bash where needed, exempt the shell-less agent

**Type:** CONFIGURE

**Source:** work-002-canonical-bug-fixes → delivery-001

**Depends on:** — (none)

**Scope:**
- All 22 canonical agents carry the `## Heartbeat protocol` block, which mandates a
  shell-generated timestamp (`echo "[$(date -u …)]" > "$HEARTBEAT_FILE"`). Three agents lack the
  `Bash` tool needed to honor it. Resolve each per its design:
  - `canonical/agents/interviewer/AGENT.md` (tools: `Read, Glob, Grep`) → add `Bash`.
  - `canonical/agents/tech-writer/AGENT.md` (tools: `Read, Glob, Grep, Write, Edit`) → add `Bash`.
  - `canonical/agents/simple-formatter/AGENT.md` (tools: `Read, Write, Edit`) → it is intentionally
    shell-less; do **not** add Bash. Instead rewrite its Heartbeat section to mark it exempt and
    instruct dispatchers not to pass `HEARTBEAT_FILE`/`HEARTBEAT_INTERVAL` to it.
- Audit the remaining heartbeat-enabled agents to confirm every non-exempt one already grants
  `Bash` (the analysis found only these three mismatched; verify nothing else regressed).
- Edit canonical `AGENT.md` frontmatter only — the generator renders `tools:` into each install
  tree (regeneration is task-007).

**Acceptance Criteria:**
- [ ] `interviewer` and `tech-writer` frontmatter `tools:` include `Bash`.
- [ ] `simple-formatter` keeps `Read, Write, Edit` (no Bash) and its Heartbeat section explicitly
      marks it exempt + tells dispatchers not to pass `HEARTBEAT_FILE`.
- [ ] Every agent that still carries the active (non-exempt) heartbeat block grants `Bash`.
- [ ] All §6 quality gates pass.

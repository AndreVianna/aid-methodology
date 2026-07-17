# State: FIRST-RUN

This state runs only when STATE.md `## Interview State` does not exist in the work folder; it creates the scaffolding before the conversational interview begins.

### 1a. Read KB (if it exists)

Check for `.aid/knowledge/INDEX.md`. If it exists, read it to understand what's
already known about the project. This context prevents asking questions the KB already answers.

If no KB exists, that's fine — this is a greenfield project.

### 1b. Create or update STATE.md

Ensure `.aid/works/{work}/STATE.md` exists and has an `## Interview State` section and a
`## Cross-phase Q&A` section. Copy from `../../templates/work-state-template.md` if
the file does not yet exist.

### 1b-ii. Seed the frontmatter block

After the STATE.md file exists (created from the template above or already present), write
the opening scalar values directly into `.aid/works/{work}/STATE.md`'s leading YAML frontmatter
block (the top of the file, before the `# Work State` title), replacing every placeholder
line the template ships with the actual opening values. Resolve this work's own minimum
grade first:

```bash
bash .claude/aid/scripts/config/read-setting.sh --skill describe --key minimum_grade --default A
```

then write the whole block:

```yaml
pipeline:
  path: full
  initiator: aid-describe
started: "{today, YYYY-MM-DD}"
minimum_grade: "{resolved value from the read-setting.sh call above}"
user_approved: no
lifecycle: Running
phase: Describe
active_skill: aid-describe
updated: "{YYYY-MM-DDTHH:MM:SSZ}"         ← today's UTC timestamp, e.g. 2026-06-10T14:32:00Z
pause_reason: --
block_reason: --
block_artifact: --
```

(`pipeline.path` is always `full` here -- `aid-describe` is the FULL-pipeline starting
skill, never a flattened Lite shortcut; the flattened-only `delivery_state`/`gate_tier`/
`gate_grade`/`gate_timestamp` group is left untouched, since a full-path work's delivery
lifecycle/gate lives in its own `delivery-NNN/STATE.md` instead.)

This side-effect is a state-write only (no user-visible output, no gate, no prompt). It does
not change any observable interview behavior — CONTINUE begins immediately after scaffolding.
The `pause_reason`, `block_reason`, and `block_artifact` keys are included with the sentinel
value `--` so every conditional key is structurally present from the start. All values are
valid opening members of the closed enums declared in the template. The body's
`## Pipeline State` section is a static enum-reference blockquote and is never rewritten here
or by any later `writeback-state.sh --pipeline` call.

**Idempotency:** if the frontmatter already has `lifecycle: Running` (the work was
previously scaffolded), skip this step — do not overwrite values that may have been advanced
by a later phase.

### 1c. Create REQUIREMENTS.md scaffold

Copy the template from `../../templates/requirements.md` to
`.aid/works/{work}/REQUIREMENTS.md`.
Add the first Change Log entry: `| {today} | Initial interview started | /aid-describe |`

**Identity header seeding:** the template already carries the identity block between
`# Requirements` and `## Change Log`:

```
- **Name:** *(pending)*
- **Description:** *(pending)*
```

These placeholder lines are written as part of the template copy. Do not remove or
overwrite them here — they are replaced with confirmed values at COMPLETION (see
`state-completion.md` Step 3). No additional write is required in this step.

### 1d. Monitor-routed finding seed (optional)

If this work was opened following a `CHANGE REQUEST` finding that `/aid-triage` suggested
routing here — originating in `aid-monitor/references/state-route.md` Step 5 — seed
REQUIREMENTS.md with the desired new/changed behavior and its evidence; the full-path
interview then continues over the remaining gaps as usual.

If there is no Monitor-originated finding (the normal case — a human-initiated interview),
skip this step. The seed only pre-fills answers; it never overrides the deterministic
interview flow. (A `BUG` finding no longer routes here at all — `aid-monitor` hands bugs
directly to `/aid-fix`; see `aid-monitor/references/state-route.md` Step 5.)

**Note:** Sections are empty — no placeholder markers. The STATE.md `## Interview State` tracks
which sections have been filled.

### 1e. Connector awareness — record a source ticket's `ticket_ref` (optional)

If this interview's originating context names, or clearly traces to, an already-filed ticket in a
catalogued issue-tracker connector (e.g. the Monitor-routed finding in Step 1d cites one, or the
requester names one directly), read it via that connector per
`.claude/aid/templates/connectors/consumption-protocol.md` (scan `.aid/connectors/INDEX.md`; for
a `connection_type: mcp` match, request the connection from the host tool's own MCP — AID resolves
nothing and stores no credential) and record `ticket_ref: <stem>:<external-id>` in this work's
`STATE.md` frontmatter (the same block seeded at Step 1b-ii). Skip silently when no such ticket is
named or no matching connector is catalogued — purely additive; never blocks or alters the
interview flow.

---

**Advance:** **CHAIN** → [State: CONTINUE] after scaffolding is complete (continue inline). CONTINUE emits the D1 opener and runs the full-path interview.

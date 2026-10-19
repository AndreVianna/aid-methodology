# State: FIRST-RUN

This state runs only when STATE.yml (with its `interview` key) does not exist in the work folder; it creates the scaffolding before the conversational interview begins.

### 1a. Read KB (if it exists)

Check for `.aid/knowledge/INDEX.md`. If it exists, read it to understand what's
already known about the project. This context prevents asking questions the KB already answers.

If no KB exists, that's fine — this is a greenfield project.

### 1b. Work record (created by the gate)

The gate's `§ 3a` (`.aid/runtime/templates/work-initiation-gate.md`) creates `.aid/works/{work}/STATE.yml`
before this state runs. Do not copy the template and do not write the record's keys by hand; set any
other key through the writer.

### 1b-ii. Seed the record through the writer

The gate's `§ 3a` writes the opening record in one locked write, with the writer's create mode and
this skill as the caller, its first step and the Definition phase:

```bash
bash .aid/runtime/scripts/execute/writeback-state.sh --create \
  --work-dir .aid/works/{work} --reading {type} --request '{the user's words}' \
  --skill aid-describe --step FIRST-RUN --phase Definition --depth full \
  --minimum-grade "{resolved value of: bash .aid/runtime/scripts/config/read-setting.sh --skill describe --key minimum_grade --default A}"
```

The record then holds this skill as the caller and as the saved skill, the step `FIRST-RUN`, the phase
`Definition`, `lifecycle: Running`, `started` and `updated`. Its pause and block keys hold `--`.
`pipeline.path` is `full`: `aid-describe` is the FULL-pipeline starting skill, never a flattened Lite
shortcut. This write is silent (no user-visible output, no gate, no prompt). CONTINUE begins
immediately after it.

**Idempotency:** `--create` refuses a work that already has a `STATE.yml` (exit 8), so this write
happens once. On a resume, the record decides the step; do not write it again.

### 1c. Create REQUIREMENTS.md scaffold

Copy the template from `../../../aid/templates/requirements.md` to
`.aid/works/{work}/REQUIREMENTS.md`.

**Identity header seeding:** the template already carries the identity block between
`# Requirements` and `## 1. Objective`:

```
- **Name:** *(pending)*
- **Description:** *(pending)*
```

These placeholder lines are written as part of the template copy. Do not remove or
overwrite them here — they are replaced with confirmed values at COMPLETION (see
`state-completion.md` Step 3). No additional write is required in this step.

### 1d. Monitor-routed finding seed (optional)

If this work was opened from a plain request that the skill guide routed here after a
`CHANGE REQUEST` finding — originating in `aid-monitor/references/state-route.md` Step 5 — seed
REQUIREMENTS.md with the desired new/changed behavior and its evidence; the full-path
interview then continues over the remaining gaps as usual.

If there is no Monitor-originated finding (the normal case — a human-initiated interview),
skip this step. The seed only pre-fills answers; it never overrides the deterministic
interview flow. (A `BUG` finding no longer routes here at all — `aid-monitor` hands bugs
directly to `/aid-fix`; see `aid-monitor/references/state-route.md` Step 5.)

**Note:** Sections are empty — no placeholder markers. `interview.sections[].state`
(STATE.yml) tracks which sections have been filled.

### 1e. Connector awareness — add a source ticket to the work's `sources:` (optional)

If this interview's originating context names, or clearly traces to, an already-filed ticket in a
catalogued issue-tracker connector (e.g. the Monitor-routed finding in Step 1d cites one, or the
requester names one directly), fetch it by invoking `/aid-read-ticket [<connector>:]<ticket-id>`
— the connector resolution and host-MCP fetch live there (feature-001); no direct-fetch recipe is
re-implemented here — and add a `sources:` entry (`ref: <stem>:<external-id>`, `kind: ticket`, `added` the current UTC time, `phase` the phase it is in now, `effect: ''` until it is applied) to this work's `STATE.yml`, on the list seeded at Step 1b-ii. Skip silently when no such ticket
is named or no matching connector is catalogued — purely additive; never blocks or alters the interview flow;
the delegated read is non-destructive, so no extra confirm is added.

---

**Advance:** **CHAIN** → [State: CONTINUE] after scaffolding is complete (continue inline). CONTINUE emits the D1 opener and runs the full-path interview.

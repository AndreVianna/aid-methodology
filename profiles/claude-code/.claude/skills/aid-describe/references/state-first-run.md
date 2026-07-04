# State: FIRST-RUN

This state runs only when STATE.md `## Interview State` does not exist in the work folder; it creates the scaffolding so that TRIAGE can ask the 3 path-determination questions before the conversational interview begins.

### 1a. Read KB (if it exists)

Check for `.aid/knowledge/INDEX.md`. If it exists, read it to understand what's
already known about the project. This context prevents asking questions the KB already answers.

If no KB exists, that's fine — this is a greenfield project.

### 1b. Create or update STATE.md

Ensure `.aid/{work}/STATE.md` exists and has an `## Interview State` section and a
`## Cross-phase Q&A` section. Copy from `../../templates/work-state-template.md` if
the file does not yet exist.

### 1b-ii. Seed the `## Pipeline State` block

After the STATE.md file exists (created from the template above or already present), write
the opening `## Pipeline State` field values directly into `.aid/{work}/STATE.md`, replacing
the template placeholder lines under `## Pipeline State` with the actual opening values:

```
- **Lifecycle:** Running
- **Phase:** Interview
- **Active Skill:** aid-describe
- **Updated:** {YYYY-MM-DDTHH:MM:SSZ}         ← today's UTC timestamp, e.g. 2026-06-10T14:32:00Z
- **Pause Reason:** —
- **Block Reason:** —
- **Block Artifact:** —
```

This side-effect is a state-write only (no user-visible output, no gate, no prompt). It does
not change any observable interview behavior — TRIAGE continues immediately after scaffolding.
The `Pause Reason`, `Block Reason`, and `Block Artifact` lines are included with the sentinel
value `—` so the grep-recoverable `**Field:** value` format is structurally complete from the
start. All values are valid opening members of the closed enums declared in the template.

**Idempotency:** if `## Pipeline State` already has `Lifecycle: Running` (the work was
previously scaffolded), skip this step — do not overwrite values that may have been advanced
by a later phase.

### 1c. Create REQUIREMENTS.md scaffold

Copy the template from `../../templates/requirements.md` to
`.aid/{work}/REQUIREMENTS.md`.
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

If this work was opened from an `aid-monitor` finding — routed here per
`aid-monitor/references/state-route.md` Step 5 — read that finding and
use it to seed the intake:

- **BUG finding** → it carries the lite path: TRIAGE settles on `LITE-BUG-FIX`, and the
  recorded root cause, patch scope, and test requirements pre-fill the reproduction /
  intended-behavior so the condensed interview is near-complete.
- **CHANGE REQUEST finding** → seed REQUIREMENTS.md with the desired new/changed behavior
  and its evidence; TRIAGE then routes by scope as usual.

If there is no Monitor finding (the normal case — a human-initiated interview), skip this
step. TRIAGE still asks its questions; the seed only pre-fills answers, it never overrides
the deterministic routing rule.

**Note:** Sections are empty — no placeholder markers. The STATE.md `## Interview State` tracks
which sections have been filled.

---

**Advance:** **CHAIN** → [State: TRIAGE] after scaffolding is complete (continue inline). Triage then determines the path (lite or full).

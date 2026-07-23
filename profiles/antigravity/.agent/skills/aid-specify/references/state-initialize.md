# State: INITIALIZE

First run for this feature; load context, determine sections, and begin The Loop.

### Step 1: Load Full Context

Read ALL before making any proposal:

1. **SPEC.md** — the feature's requirements (description, user stories, acceptance criteria)
2. **REQUIREMENTS.md** — full requirements for cross-reference
3. **KB via INDEX.md** — Read `.aid/knowledge/INDEX.md` first. Use the summaries
   to decide which KB docs are relevant to this feature, then load them.
   At minimum you'll need architecture, coding-standards, and schemas for
   most features, but let the INDEX guide you — don't guess.
   - Check `feature-inventory.md` to understand existing features and how the
     new feature relates to them.
   - **Greenfield:** If KB docs are init placeholders (`❌ Pending`), treat as empty.
     Propose from scratch; decisions will seed KB during Write step.
4. **Codebase** — `Grep`/`Glob` to explore relevant source code. Skip for greenfield.
5. **Known Issues** — Read `.aid/works/{work}/known-issues.md` if it exists. Check `tech-debt.md` in KB.

**During codebase exploration, register known issues** in `.aid/works/{work}/known-issues.md`
(create from `../../templates/known-issues.md` if missing). Only register issues in code
that this feature touches. See [Known Issues Scope](#known-issues-scope) for criteria.

### Step 2: Determine Applicable Sections

**Core sections (always present unless truly N/A):**

| Section | Content |
|---------|---------|
| Data Model | Tables, columns, types, constraints, FKs, indices — or "no schema changes" |
| Feature Flow | Technical flowchart: request → service → repo → response |
| Layers & Components | What goes in each layer, dependencies, DI registrations |

**Conditional sections — activation rules:**

Each has two paths: **Auto-activate** (obvious from context) or **Ask** (use default question).

| Section | Auto-activate when... | Default question |
|---------|----------------------|------------------|
| API Contracts | KB/Requirements mention endpoints/API | Does this feature expose or modify any APIs? |
| UI Specs | Requirements mention screens/UI or architecture.md documents frontend patterns | Does this feature include UI changes? |
| Events & Messaging | KB has queues/events or async | Does this feature involve async processing or events? |
| DDD Analysis | KB/Requirements indicate DDD | Does the project follow DDD? Define bounded contexts? |
| BDD Scenarios | Requirements indicate BDD/Gherkin | Does the project use BDD? Write Gherkin scenarios? |
| CQRS Specs | KB shows CQRS pattern | Does this feature use Command/Query separation? |
| State Machines | Requirements describe stateful workflows | Any stateful workflows with defined transitions? |
| Security Specs | Requirements mention auth/roles | Specific auth/permission requirements beyond basic? |
| Migration Plan | Brownfield + schema changes | Does this change existing schemas or require migration? |
| Cache Strategy | Requirements mention performance | Performance requirements that may need caching? |
| External Integrations | Requirements mention 3rd party | Does this integrate with external services? |
| Batch/Jobs | Requirements mention scheduled work | Any scheduled jobs or background tasks? |
| Mobile Specs | Requirements target mobile or architecture.md shows mobile targets | Mobile platforms? Offline-first? Platform-specific? |
| Search/Indexing | Requirements mention search | Full-text search or complex filtering needed? |
| AI Enhancements | Requirements mention AI/ML | AI or ML involved? (prompts, RAG, agents, fine-tuning) |
| Telemetry & Tracking | Not obvious | Specific logging, auditing, or alerting requirements? |
| Recovery Management | Not obvious | Disaster recovery or backup requirements? |
| Cloud Support | Requirements mention deploy/cloud | Specific cloud provider requirements? |
| Hardware Requirements | Not obvious | Particular hardware considerations? |

**Conditional section content guide (when activated):**

**UI Specs** — Reference `architecture.md` (and any project-specific repo-presentation docs) for existing UI patterns:
- Component Breakdown: new/modified components, props, state, composition within existing tree
- State Management: local vs global state changes, stores affected, server state sync
- Navigation Changes: new routes, guard changes, deep link additions
- Responsive Behavior: breakpoint-specific layouts, mobile-first decisions
- Design Integration: tokens used, theme changes, design system components extended
- Accessibility: ARIA patterns for new components, keyboard nav, screen reader support

**Mobile Specs** — Reference `architecture.md` for platform context:
- Platform Differences: iOS vs Android behavior for this feature
- Offline Behavior: what works offline, sync strategy, conflict resolution
- Push Notifications: if this feature triggers or handles notifications
- Native APIs: camera, GPS, biometrics, storage, permissions required
- App Store Impact: new permissions, review guideline considerations

### Step 3: Register in work STATE.md

In the work's `.aid/works/{work}/STATE.md`, update the `## Features State` table:
- Find or add a row for this feature
- Set State to `In Discussion`, Started date to today
- Columns: Feature | State | Sections | Started | Last Updated | Notes

Emit pipeline phase (silent state-write only — no output, no gate):
```
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specify
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value aid-specify
bash .agent/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

### Step 3b: Connector awareness — record this feature's `ticket_ref` (optional)

If this feature's requirements trace to, or the user names, an already-filed ticket in a
catalogued issue-tracker connector, fetch it by invoking `/aid-read-ticket
[<connector>:]<ticket-id>` — the connector resolution and host-MCP fetch live there (feature-001);
no direct-fetch recipe is re-implemented here — and record a `**Ticket:** <stem>:<external-id>`
line in this feature's `SPEC.md` (per `specs/spec-template.md`). Skip silently when no such ticket
applies or no matching connector is catalogued; the delegated read is non-destructive, so no extra
confirm is added.

### Step 4: Present and Start

Present activated sections + ambiguous questions:

```
I've analyzed {feature} against the KB and codebase.

**Core sections:**
- Data Model — {brief rationale}
- Feature Flow — {brief rationale}
- Layers & Components — {brief rationale}

**Also activated:**
- {Section} — {why}

**Questions:**
1. {default question for ambiguous section}
2. ...

Does this look right? Answer the questions, and tell me if I'm missing anything.
```

Process response → update work STATE.md `## Features State` → begin **The Loop** for first Pending section.

**Advance:** **CHAIN** → [State: CONTINUE] (continue inline).

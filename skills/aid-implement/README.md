
# Execute Task with Agent

Read a TASK spec, load relevant context from SPEC.md and the Knowledge Base, spawn a coding agent, and verify the output builds and passes tests.

## Core Principle

**Agents don't improvise.** They receive a task spec, a project spec, and KB context. They implement what's specified. When they encounter something that contradicts their instructions, they report an impediment — they don't silently work around it.

## Inputs

- `TASK-{id}.md` — the primary prompt. What to build.
- `SPEC.md` — the project specification. Architectural constraints.
- `knowledge/` documents (context-dependent):
  - Always: `coding-standards.md`, `architecture.md`.
  - If DB work: `data-model.md`.
  - If API work: `api-contracts.md`.
  - If integration work: `integration-map.md`.
  - If test-heavy: `test-landscape.md`.

## Process

### Step 1: Prepare Context

Assemble the agent's context:

1. **Primary prompt:** The full TASK-{id}.md content.
2. **System context:** SPEC.md (constraints, architecture, non-functional requirements).
3. **KB context:** Relevant documents based on task type. Don't load all 16 — select the 2-4 most relevant.
4. **Workspace:** The codebase directory where the agent will work.

### Step 2: Spawn Agent

Use the coding-agent skill to spawn an implementation agent. The agent prompt should include:

```
## Task
{Full TASK-{id}.md content}

## Project Specification
{Relevant sections of SPEC.md}

## Coding Standards
{From knowledge/coding-standards.md}

## Architecture Context
{From knowledge/architecture.md — relevant sections}

## Additional Context
{Other KB documents as needed}

## Rules
- Follow the coding standards exactly.
- Match the interface contracts in the task spec.
- Write tests as specified in Test Requirements.
- If you encounter something that contradicts the task spec or KB, STOP and report it.
  Do NOT work around it silently.
- Run build and tests before reporting completion.
```

### Step 3: Verify Output

After the agent completes:

1. **Build check:** Run the project's build command. Must pass with zero errors and zero warnings.
2. **Test check:** Run the full test suite. All tests must pass — both new and existing.
3. **Scope check:** Review the files changed. Do they match the "Files to Touch" guidance in the task spec? Unexpected file changes need justification.

If verification fails:
- Build errors → agent must fix before reporting done.
- Test failures → distinguish between new test failures (agent's bug) and regression (agent broke existing code).
- Scope creep → if the agent touched files outside the task scope, evaluate whether the change was necessary.

### Step 4: Handle Impediments

If the agent reports that assumptions don't hold:

1. Agent generates `IMPEDIMENT.md`:
   ```markdown
   # IMPEDIMENT: IMP-{id}
   **Source:** aid-implement, TASK-{task-id}
   **Type:** wrong-assumption | missing-dependency | architecture-conflict | kb-gap
   **Description:** {What's wrong}
   **KB Impact:** {Which KB document needs revision, if any}
   **Options:**
     A) {Option with effort, risk, trade-offs}
     B) {Option with effort, risk, trade-offs}
     C) {Option with effort, risk, trade-offs}
   **Recommendation:** {Which option and why}
   **Blocking:** TASK-{task-id}
   ```
2. If `kb-gap` → trigger targeted aid-discover, update KB.
3. If resolvable within task scope → resolve, document in commit message.
4. If requires plan/spec change → pause, escalate to human.

**Key rule:** The agent NEVER silently works around an impediment. Silent workarounds create tech debt.

## Multi-Agent Parallel Execution

When the plan (aid-plan) identifies independent tasks, execute them in parallel:

### Prerequisites for Parallel Execution

- Tasks have no shared dependencies (confirmed in DELIVERY-{id}.md dependency graph).
- Tasks touch different files/modules (no merge conflicts).
- Each agent gets its own feature branch.

### Parallel Protocol

1. Create a feature branch per task: `feature/TASK-{id}`.
2. Spawn one agent per task with `streamTo: "parent"`.
3. **Yield and wait.** Do not start other work in the same turn.
4. As each agent completes, verify its output independently.
5. Merge branches in dependency order.
6. Run full test suite after merge to catch integration issues.

### When NOT to Parallelize

- Tasks share database migrations (merge conflicts in migration files).
- Tasks modify the same interfaces (conflicting signatures).
- One task's output is another's input (dependency exists despite plan saying otherwise).

## Output

- Code changes on a feature branch.
- Tests added per task spec requirements.
- Build: green. Tests: green.
- IMPEDIMENT.md if assumptions were violated.
- Task status updated to "Complete" (or "Blocked" if impediment unresolved).

## Feedback Loops

### → Discovery / Plan / Spec (Loop 5)

**Trigger:** Implementation reveals assumptions don't hold.

**Protocol:**
- `kb-gap` → targeted aid-discover → KB updated → resume or re-plan.
- `wrong-assumption` about the spec → GAP.md → aid-specify revision → resume.
- `architecture-conflict` → escalate to human with options.
- Resolvable locally → resolve, document, continue.

### ← Review (Loop 6)

If review identifies issues:
- `CODE` issues → fix in the same branch.
- `TASK` issues → update task spec, re-implement affected portions.
- `SPEC`/`KB`/`ARCHITECTURE` issues → escalate upstream.

## Quality Checklist

- [ ] Agent received TASK spec + SPEC.md + relevant KB documents.
- [ ] Build passes with zero errors, zero warnings.
- [ ] All tests pass (new and existing).
- [ ] Files changed match expected scope.
- [ ] No silent workarounds — impediments are documented.
- [ ] Task status updated.
- [ ] Commit messages reference the TASK-{id}.

## See Also

- [coding-agent skill](/usr/lib/node_modules/openclaw/skills/coding-agent/SKILL.md) — For spawning coding agents.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.

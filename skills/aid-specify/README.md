
# Generate Specification

Transform REQUIREMENTS.md into a formal SPEC.md grounded in the Knowledge Base. The spec describes what to build in the context of what already exists.

## Core Principle

**Specs are grounded, not generic.** Don't say "use repository pattern" — say "register in `ServiceCollectionExtensions.cs` following the pattern in `knowledge/coding-standards.md` §3.2." Don't say "add a database table" — say "extend the existing schema using EF Core migrations, following the naming convention in `knowledge/data-model.md`."

## Inputs

- `REQUIREMENTS.md` — what to build.
- `knowledge/` directory — how the system currently works. Read at minimum:
  - `architecture.md` — to align with existing patterns.
  - `technology-stack.md` — to specify within the actual stack.
  - `coding-standards.md` — to mandate existing conventions.
  - `data-model.md` — to extend the existing schema.
  - `integration-map.md` — to understand current integrations.

## Process

### Step 1: Read and Internalize

1. Read REQUIREMENTS.md completely. Understand the problem, users, features, and constraints.
2. Read relevant KB documents. Map each requirement to existing system components.
3. Identify where new functionality touches existing code vs. where it's entirely new.

### Step 2: Resolve Conflicts

Check for conflicts between requirements and existing architecture:

- Does a requirement contradict an architectural pattern? Document the conflict.
- Does a requirement assume a capability the system doesn't have? Note the gap.
- Do two requirements contradict each other? Flag for stakeholder decision.

If conflicts require more information:
- **KB gap** → generate GAP.md with `discovery-needed`, trigger aid-discover.
- **Requirements gap** → generate GAP.md with `needs-interview`, trigger aid-interview.
- **Architectural tension** → document in the spec as a decision point.

### Step 3: Write SPEC.md

Generate using the template in [references/spec-template.md](references/spec-template.md).

#### Vision

One paragraph. What this is, why it exists, what problem it solves. Derived from REQUIREMENTS.md Problem Statement.

#### Constraints

Drawn from KB + requirements:

```markdown
## Constraints
- Stack: .NET 10, Avalonia 11, EF Core 10 (from KB technology-stack.md)
- Platform: Windows, Linux (from REQUIREMENTS.md)
- Performance: < 200ms UI response (from REQUIREMENTS.md)
- Security: Local-only, no auth required (from REQUIREMENTS.md)
```

Every constraint references its source.

#### Architecture

Extend the existing architecture, don't reinvent it:

```markdown
## Architecture
- Pattern: MVVM with ReactiveUI (extending existing pattern per KB architecture.md)
- Data: SQLite via EF Core (extending existing schema per KB data-model.md)
- External: Whisper API for transcription (new integration)
```

For greenfield: define the architecture from scratch, referencing coding-standards.md for conventions.

#### Domain Model

Key entities and relationships. Reference `knowledge/domain-glossary.md` for term definitions. Introduce new entities with clear definitions.

#### Feature Specifications

For each feature from REQUIREMENTS.md (priority-ordered):

```markdown
### Feature: {Name}
**Priority:** Must | Should | Could
**Requirement:** REQ-{n} from REQUIREMENTS.md

**Behavior:**
- {What the feature does, step by step}
- {User-visible behavior}
- {System behavior}

**Interfaces:**
- {Public APIs, UI components, data contracts}

**Edge Cases:**
- {What happens when X}
- {What happens when Y}

**Error Handling:**
- {How errors are surfaced to the user}
- {How errors are logged}

**Dependencies:**
- {Other features this depends on}
- {Existing system components affected}
```

#### Non-Functional Requirements

Grounded in KB:

```markdown
## Non-Functional Requirements

### Testing
- Follow existing test patterns (KB test-landscape.md): xUnit for unit, Playwright for E2E.
- Minimum coverage: unit tests for all new public methods.

### Logging
- Use Serilog structured logging (KB coding-standards.md §4).

### Accessibility
- {From requirements}

### Performance
- {From requirements, validated against KB infrastructure.md}
```

### Step 4: Cross-Reference Check

Before finalizing:

- [ ] Every requirement from REQUIREMENTS.md is addressed in the spec.
- [ ] Every architectural decision references the KB.
- [ ] No spec section contradicts KB documents.
- [ ] Feature dependencies form a valid DAG (no circular dependencies).
- [ ] Non-functional requirements are measurable.

### Step 5: Initialize Revision History

```markdown
## Revision History
| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-specify | Initial specification |
```

## Output

`SPEC.md` — formal specification with Vision, Constraints, Architecture, Domain Model, Feature Specifications, Non-Functional Requirements, and Revision History.

## Spec Revision (Re-entry)

When triggered by a GAP.md from aid-plan, aid-detail, or aid-review:

1. Read the GAP.md to understand the ambiguity or contradiction.
2. If `needs-interview` → trigger targeted aid-interview first, get the answer.
3. Revise the specific section of SPEC.md.
4. Add revision history entry referencing the GAP.
5. Report completion to the calling phase.

## Feedback Loops

### → Discovery (Loop 2)

**Trigger:** Writing the spec exposes insufficient understanding of a subsystem.

**Example:** Specifying a feature that touches the auth module, but `knowledge/security-model.md` is marked Partial.

**Protocol:** Pause → GAP.md with `discovery-needed` → trigger aid-discover → KB updated → resume specification.

### ← Plan / Review (Loops 4, 6)

**Trigger:** Planning reveals the spec is ambiguous, or review finds a fundamental spec issue.

**Protocol:** Receive GAP.md → understand the issue → revise SPEC.md → update revision history → report completion.

## Quality Checklist

- [ ] Every feature spec has Behavior, Interfaces, Edge Cases, Error Handling, Dependencies.
- [ ] Architectural decisions reference KB documents, not generic patterns.
- [ ] Constraints are sourced (KB or REQUIREMENTS.md).
- [ ] No requirement from REQUIREMENTS.md is missing from the spec.
- [ ] Conflicts between requirements and architecture are documented.
- [ ] Revision history is initialized.

## See Also

- [Spec Template](references/spec-template.md) — Full SPEC.md template.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.

---
name: aid-specify
description: >
  Transform REQUIREMENTS.md into a formal SPEC.md grounded in the Knowledge Base.
  Use when requirements are complete and need formalization, or when a GAP.md
  triggers spec revision.
metadata:
  short-description: Specification generation from requirements and KB
---

# Generate Specification

Transform REQUIREMENTS.md into SPEC.md grounded in the Knowledge Base.

## Core Principle

Specs are grounded, not generic. Don't say "use repository pattern" — say "register in `ServiceCollectionExtensions.cs` following the pattern in `aid-workspace/knowledge/coding-standards.md` §3.2."

## Inputs

- `REQUIREMENTS.md`
- `aid-workspace/knowledge/`: architecture.md, technology-stack.md, coding-standards.md, data-model.md, integration-map.md

## Process

### 1. Read and Internalize
Read REQUIREMENTS.md completely. Map each requirement to existing system components via KB.

### 2. Resolve Conflicts
- Requirement contradicts architecture? Document the conflict.
- Requirement assumes missing capability? Note the gap.
- Two requirements contradict? Flag for stakeholder decision.
- KB gap → GAP.md with `discovery-needed` → trigger aid-discover.
- Requirements gap → GAP.md with `needs-interview` → trigger aid-interview.

### 3. Write SPEC.md

**Vision:** One paragraph — what, why, what problem.

**Constraints:** Each references its source (KB or REQUIREMENTS.md).

**Architecture:** Extend existing patterns. Reference KB documents.

**Domain Model:** Entities, relationships. Reference domain-glossary.md.

**Feature Specifications:** For each feature (priority-ordered):
- Priority, Requirement reference
- Behavior (step by step)
- Interfaces (APIs, UI, data contracts)
- Edge Cases
- Error Handling
- Dependencies

**Non-Functional Requirements:** Testing, logging, accessibility, performance — grounded in KB.

### 4. Cross-Reference Check
- [ ] Every requirement addressed
- [ ] Architectural decisions reference KB
- [ ] No spec section contradicts KB
- [ ] Feature dependencies form valid DAG
- [ ] NFRs are measurable

### 5. Initialize Revision History

## Spec Revision (Re-entry)

1. Read GAP.md for the ambiguity/contradiction
2. If `needs-interview` → trigger targeted aid-interview first
3. Revise specific section
4. Add revision history entry
5. Report completion

## Output

`SPEC.md` with Vision, Constraints, Architecture, Domain Model, Feature Specifications, NFRs, Revision History.

## Quality Checklist

- [ ] Every feature has Behavior, Interfaces, Edge Cases, Error Handling, Dependencies
- [ ] Architectural decisions reference KB, not generic patterns
- [ ] Constraints are sourced
- [ ] No requirement missing from spec
- [ ] Conflicts documented
- [ ] Revision history initialized

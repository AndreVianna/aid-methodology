---
name: aid-plan
description: >
  Define the high-level roadmap from SPEC.md — MVP scope, module identification,
  deliverable scoping, test scenarios, risk assessment. Strategy, not tactics.
  Use when SPEC.md is complete and you need a roadmap, or when a GAP.md triggers re-planning.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
context: fork
agent: architect
---

# High-Level Roadmap

Produce PLAN.md: MVP definition, modules, deliverables, test scenarios, risks.

## Core Principle

Plan is strategy. Detail is tactics. Plan answers "what do we build and in what order?" Detail answers "how do we build it?"

## Inputs

- `SPEC.md`
- `aid-workspace/knowledge/`: architecture.md, module-map.md, tech-debt.md, test-landscape.md

## Process

### 1. Define MVP
Smallest set of features that delivers value. List included features with justification. List deferred features with reasoning.

### 2. Identify Modules
Map features to system modules. For each: features contained, existing vs. new code, risk level (from tech debt + test coverage + complexity).

### 3. Scope Deliverables
Group modules into shippable increments. Good boundaries: independent features, natural progression, testable independently. Each deliverable: modules, features, dependencies, what it validates.

### 4. Define Test Scenarios
Per deliverable: high-level scenarios that prove it works. Describe what to prove, not how to test. Format: `TS-{id}: {scenario description}`.

### 5. Risk Assessment
Table: Risk | Impact | Likelihood | Mitigation.

### 6. Identify Spikes
Time-boxed research tasks for uncertain areas. Generate when: new technology, risk needs investigation, KB has blocking open question.

## Feedback Loops

- **→ Discovery:** KB incomplete → GAP.md with `discovery-needed`
- **→ Specify:** Spec ambiguous → GAP.md with `ambiguity` or `contradiction`
- **← Detail:** Plan too vague → receive feedback, revise

## Output

`PLAN.md` with: MVP definition, Module map, Deliverables (ordered with dependencies), Test scenarios per deliverable, Risk assessment, Spikes.

## Quality Checklist

- [ ] MVP clearly defined with justification
- [ ] Every SPEC feature assigned to a deliverable or explicitly deferred
- [ ] Module boundaries match KB architecture
- [ ] Deliverable dependencies are meaningful
- [ ] Test scenarios defined per deliverable
- [ ] Risks assessed with mitigations
- [ ] Spikes identified for uncertain areas

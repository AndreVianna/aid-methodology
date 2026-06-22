# Essence-Capture Research

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-12, FR-13, FR-14, FR-15, FR-16, FR-31, FR-32) | /aid-interview |

## Source

- REQUIREMENTS.md §5.D (FR-12, FR-13, FR-14, FR-15, FR-16), §5.I (FR-31, FR-32)
- REQUIREMENTS.md §1.2 (the essence gap, the 'Relative bus' miss), §1.4 (research side), §1.5 (the method), §2.1/§2.3 (P1, P3)
- §4 S4

## Description

This feature is the heart of the overhaul: it makes discovery **capture a
project's essence** — its ubiquitous language and native concepts — instead of
cataloging generic structure. It adds a **mechanical coined-term / salient-concept
harvest** that scans all source types and emits a candidate-concept list
(project-coined × recurring × cross-source) — the deterministic anchor that turns
"did we miss a concept?" into a checklist (the 'Relative bus' concept lights up
here). From that list it builds a **concept spine** — the grounded native concepts,
constructed *before* the per-concern docs and shared with every researcher so
cross-cutting concepts are nobody-falls-between-lanes.

It introduces the **comprehension / closure loop**: stop cataloging and explain
how the system works in the project's own language, iterating until the
explanation closes (no undefined project-specific term remains). A
**can't-explain-it tripwire** makes any ungrounded project-specific term a
mandatory investigation rather than ignorable noise, and research must read **all
source types** — code, docs/ADRs, reports, data bundles, commit/issue history —
because the *why-here* (the essence) lives in prose, not just code. The concept
spine is **persisted as a first-class KB doc** (the upgraded ubiquitous-language /
glossary) that other docs reference and the INDEX routes to. When a concept
**cannot be grounded from the artifacts**, discovery **escalates it as a human
Q&A** rather than silently dropping it.

## User Stories

- As an **AI agent** consuming the KB, I want discovery to capture the project's
  native concepts so that I get the delta from what I already know, not the generic
  skeleton.
- As a **senior architect**, I want a persisted concept spine that other docs
  reference so that the project's conceptual model is a durable backbone, not lost
  scratch.
- As an **AID adopter**, I want discovery to read the *why* sources and ground every
  coined term so that the KB explains *my* domain ('Relative bus'-type concepts) and
  passes teach-back.
- As an **AID maintainer**, I want ungroundable concepts escalated as explicit human
  Q&A so that silent misses become caught questions.

## Priority

Must

## Acceptance Criteria

- [ ] Given any project, when the mechanical harvest runs, then it scans all source
  types and emits a candidate-concept list (project-coined × recurring ×
  cross-source). *(FR-12; supports AC2)*
- [ ] Given the candidate list, when discovery proceeds, then a grounded concept
  spine is built before the per-concern docs and shared with every researcher.
  *(FR-13)*
- [ ] Given a fresh agent and only the KB, when asked, then it can explain how the
  project works in its own language and answer "what is X?" for the native concepts
  (teach-back closure / closure loop). *(FR-14, AC1 keystone, AC3)*
- [ ] Given any ungrounded project-specific term, when discovery encounters it, then
  it is treated as a mandatory investigation, never ignorable noise. *(FR-15,
  tripwire)*
- [ ] Given a project, when research runs, then it reads all source types — code,
  docs/ADRs, reports, data, commit/issue history. *(FR-16)*
- [ ] Given a fixture with a planted 'Relative bus'-style concept, when discovery
  runs, then it captures and defines it. *(FR-12; AC2 — validated in f012)*
- [ ] Given a project, when discovery completes, then the concept spine exists as a
  first-class KB doc that other docs reference and the INDEX routes to. *(FR-31, AC14)*
- [ ] Given a concept that cannot be grounded from the artifacts, when discovery
  detects it, then it escalates a human Q&A entry (surfaced, not silently dropped).
  *(FR-32, AC15)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 budget — the harvest,
> the closure self-containment check, and salience ranking are mechanical/scripted
> (cheap, deterministic, CI-able); the closure loop must be bounded; LLM judgment
> (synthesis, "did it understand") is minimized and evidence-anchored. AC3 (closure
> self-containment) is verified jointly with f012.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

# UX Designer

**Specialist Agent — invoked ad-hoc**

The UX Designer provides expertise in UI/UX patterns, accessibility (WCAG), user flows, wireframes, and component design. It is called when the pipeline encounters interface-related decisions or needs to evaluate usability.

## What It Does

The UX Designer reviews designs, proposes user flows, evaluates accessibility compliance, suggests component patterns, and critiques interfaces. It brings a user-centered perspective that other agents lack — thinking about how humans interact with the software, not just how the software works internally.

## When It's Invoked

| Called By | Context |
|-----------|---------|
| **Architect** | During Specify/Plan — when designing user-facing features |
| **Critic** | During Review — when evaluating UI implementation quality |
| **Orchestrator** | When any phase needs UX expertise |

This agent is not part of the standard pipeline flow. It is called on demand when the work involves user interfaces.

## What It Produces

- **UX recommendations** — component suggestions, layout patterns, interaction flows
- **Accessibility audit results** — WCAG compliance findings with specific violations
- **User flow diagrams** — described in text/markdown (step-by-step flows)
- **Component specifications** — detailed UI component behavior descriptions

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Architect** | Architect designs *systems*. UX Designer designs *interactions*. |
| **Critic** | Critic evaluates code quality. UX Designer evaluates *usability* quality. |
| **Tech Writer** | Tech Writer documents for *readers*. UX Designer designs for *users*. |

## Tools

- **Read, Glob, Grep** — reviewing existing UI code and patterns
- **Bash** — running accessibility audit tools, inspecting component libraries

## Model

**Sonnet** — UX evaluation is pattern-matching and standard-referencing rather than deep novel reasoning.

## Examples

- *"We're adding a settings page. What should the UX look like?"* → Proposes user flow and component layout
- *"Review the new form implementation for accessibility."* → WCAG audit with specific findings
- *"The navigation is confusing. What's wrong?"* → Usability analysis with improvement suggestions

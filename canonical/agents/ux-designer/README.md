> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`AGENT.md`](AGENT.md) in this folder.

# UX Designer

**Specialist Agent — invoked ad-hoc**

The UX Designer provides expertise in UI/UX patterns, accessibility (WCAG), user flows, wireframes, and component design. It is called when the pipeline encounters interface-related decisions or needs to evaluate usability.

## What It Does

The UX Designer reviews designs, proposes user flows, evaluates accessibility compliance, suggests component patterns, and critiques interfaces. It brings a user-centered perspective that other agents lack — thinking about how humans interact with the software, not just how the software works internally.

## When It's Invoked

| Called By | Context |
|-----------|---------|
| **Architect** | During Specify/Plan — when designing user-facing features |
| **Reviewer** | During Review — when evaluating UI implementation quality |
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
| **Reviewer** | Reviewer evaluates code quality. UX Designer evaluates *usability* quality. |
| **Tech Writer** | Tech Writer documents for *readers*. UX Designer designs for *users*. |

## Tools

- **Read, Glob, Grep** — reviewing existing UI code and patterns
- **Bash** — running accessibility audit tools, inspecting component libraries

## Tier

**Medium tier** — UX recommendations and accessibility audits are knowledge-heavy synthesis against established standards (WCAG 2.1, design system patterns, platform HIG). The Medium tier handles structured pattern application; the Large tier would add little for typical UX critique.

## Examples

- *"We're adding a settings page. What should the UX look like?"* → Proposes user flow and component layout
- *"Review the new form implementation for accessibility."* → WCAG audit with specific findings
- *"The navigation is confusing. What's wrong?"* → Usability analysis with improvement suggestions

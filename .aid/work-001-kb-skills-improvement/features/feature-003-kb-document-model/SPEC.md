# KB Document Model

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-8, FR-9, FR-11, FR-29) | /aid-interview |

## Source

- REQUIREMENTS.md §5.C (FR-8, FR-9, FR-11), §5.H (FR-29)
- REQUIREMENTS.md §1.3 (the KB model: summary+pointer, concerns-driven, audience/ownership), §2.1/§2.3/§2.7 (P1, P3, P7)
- §4 S3, S9

## Description

This feature defines *what a KB document is* under the new model, and aligns the
visual rendering to match. Documents are derived from a small, universal, stable
set of **concerns** (how is it built? what are the parts? what conventions? what
vocabulary? how is it tested? what's risky? how does it ship? what does it do for
users?) rather than from an enumeration of project types. The concrete doc set is
**proposed → confirmed** with the user: a concern may split into several docs, or
a project-specific doc may be added.

Each doc follows the **summary + pointer** model: it synthesizes the durable,
cross-cutting understanding (the *why*, the *how parts interact*, the gotchas) and
points to its `sources:` for volatile detail — neither a fat transcription nor a
hollow link-farm. Document boundaries fall where coverage, fit, and
audience/ownership agree, so audience and ownership become first-class dimensions.
Per-doc research expectations are phrased as **open questions** ("describe how this
is structured and why") rather than fill-in templates that invite generic bending.
Finally, `aid-summarize` is updated to render this new model (concept spine,
summary+pointer, audience) in the visual summary.

## User Stories

- As a **senior architect**, I want each doc to synthesize the conceptual model and
  point me to source for detail so that I get the *why* without a stale transcription.
- As a **junior developer**, I want docs sized to a coherent concern with a clear
  audience so that I get orientation at my level and know where to go deeper.
- As an **AID adopter**, I want the doc set derived from my project's concerns and
  confirmed with me so that I get the right documents, not a fixed one-size seed.
- As a **researcher (AI agent)**, I want expectations phrased as open questions so
  that I report what is actually in the source instead of bending it to a template.

## Priority

Should

## Acceptance Criteria

- [ ] Given a project, when the doc set is determined, then it is derived from the
  universal concern set (not a project-type enumeration) and proposed → confirmed
  with the user, allowing concern splits and project-specific docs. *(FR-8)*
- [ ] Given a KB doc, when it is authored, then it follows the summary + pointer
  model — durable synthesis in the doc, volatile detail left in `sources:`. *(FR-9)*
- [ ] Given a doc with `owner:`/`audience:`, when boundaries are drawn, then the
  audience/ownership dimension informs the boundary and the INDEX audience filter.
  *(FR-10 consumed here; primary in f001)*
- [ ] Given per-doc research, when expectations are issued, then they are phrased
  as open questions, not fill-in templates. *(FR-11)*
- [ ] Given the new KB model, when `aid-summarize` runs, then the visual summary
  renders the concept spine, summary+pointer, and audience. *(FR-29)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}

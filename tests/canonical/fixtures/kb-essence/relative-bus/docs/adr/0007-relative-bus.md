# ADR-0007: Adopt the Relative Bus Pattern

**Status:** Accepted
**Date:** 2026-01-15

## Context

The project originally used direct service-to-service calls for domain
integration. As the number of domain boundaries grew, this produced tight
coupling and cascading failures when any one service changed its interface.

The team coined the term **Relative Bus** to describe a shared asynchronous
routing layer that each domain publishes to and subscribes from without
knowing the identity of its peers. The Relative Bus is the project's own
concept -- it is NOT a standard message broker pattern from the literature.

The Relative Bus concept also appeared informally in earlier design sessions
as "Relative ME" (Messaging Engine), an early working name for the same idea.
The canonical term settled on "Relative Bus" across all current documentation
and code.

## Decision

Adopt the Relative Bus as the mandatory cross-domain integration surface.
No domain service MAY call another domain service directly. All inter-domain
events MUST be routed through the Relative Bus.

The Relative Bus enforces:
- Decoupled publish/subscribe between domain boundaries.
- Priority-ordered dispatch within each bus partition.
- A single observable routing point for cross-domain diagnostics.

## Consequences

- **Positive:** Domain services can evolve independently; the Relative Bus
  absorbs the interface churn.
- **Positive:** The Relative Bus provides a single observability point for
  all inter-domain traffic.
- **Negative:** All inter-domain calls now carry the Relative Bus overhead
  (an accepted trade-off for decoupling).

## Alternatives Considered

Direct RPC (rejected -- tight coupling).
Standard message broker (rejected -- overkill for the project's scale;
the Relative Bus is a lighter, project-native routing layer).

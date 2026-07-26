---
kb-category: primary
source: hand-authored
objective: Project-specific vocabulary with definitions for all domain and AID-specific terms.
summary: Canonical reference for naming -- disambiguates terms that mean different things in different contexts.
sources: []
tags: [C4, glossary, vocabulary, terminology]
see_also: [coding-standards.md]
owner: architect
audience: [developer, architect, pm]
intent: |
  Project-specific vocabulary with definitions. Disambiguates terms that mean different things in different contexts; canonical reference for naming.
contracts: []
changelog:
  - 2026-06-23: Upgraded to concept-spine structure (concept entries + retained lexicon tables; f004)
  - 2026-06-23: Added f001 frontmatter fields (objective/summary/sources/tags/see_also/owner/audience)
  - 2026-05-26: KB Authoring v2 template seed
---

# Domain Glossary

> **Source:** aid-describe (Phase 2) -- captured from stakeholder language
> **Status:** {Complete | Partial | Missing}
> **Last Updated:** {date}

This glossary documents the **team's actual language** -- not industry standard terms, but what *this* team means when they use these words. When building with AI agents, this is critical: an agent that uses "transaction" when the team means "order" will write specs and code that technically work but conceptually misalign.

This doc has two parts: the **Concept Spine** (load-bearing native concepts, each grounded with definition-as-used-here / relates-to / sources) and the **Lexicon** (vocabulary tables for terms that are important but not load-bearing spine concepts). The spine is the backbone; the lexicon is the reference. No term is lost between the two.

## Contents

- [Concept Spine](#concept-spine)
- [Core Domain Terms](#core-domain-terms)
- [Abbreviations and Acronyms](#abbreviations--acronyms)
- [Terms with Specific Domain Meanings](#terms-with-specific-domain-meanings)
- [Terms to Avoid](#terms-to-avoid)
- [Business Process Vocabulary](#business-process-vocabulary)
- [Invariants](#invariants)
- [Change Log](#change-log)

---

## Concept Spine

> The spine holds the project's **native load-bearing concepts** -- the terms that carry the
> project's essence and that other KB docs reference. Each entry is grounded from source artifacts
> (NOT a generic definition -- only what it means in this project). The `sources:` field on each
> entry is the grep-recoverable anchor that grounds it; the doc-level frontmatter `sources:` above
> is the union of all concept-level sources.
>
> Populated by the closure loop (aid-discover Step 5b). Seeded from candidate-concepts.md.
> New native terms discovered during grounding are appended and re-grounded in turn.

### {ConceptName}

**Definition-as-used-here:** {What this concept means in THIS project, NOT in general. The project-specific delta is the value -- a generic definition is negative value; omit it.}

**Relates-to:** {How this concept connects to other spine concepts. The cross-cutting linkage no single researcher lane owns. List: ConceptA (how it relates), ConceptB (how it relates).}

**sources:**
- `{path/to/file}:{AnchorOrDistinctString}` -- {brief note on what this source grounds}
- `{path/to/another/file}:{AnchorOrDistinctString}` -- {brief note}

---

> Add one entry per grounded native concept. Use the block above as the pattern.
> Below is an illustrative example with the template filled in:

### Relative Bus

**Definition-as-used-here:** An architectural coordination idea unique to this project: components share state by emitting position-relative deltas to a shared bus, rather than owning absolute state. Not a module or a service -- an idea spread across multiple files and ADRs.

**Relates-to:** EventBus (the shared bus the Relative Bus pattern writes to), SyncReconciler (the consumer that re-assembles absolute state from relative deltas), PeerSync (the protocol that carries deltas cross-node).

**sources:**
- `src/bus/relative.ts:RelativeBusEmitter` -- core emitter class that defines the delta contract
- `docs/adr/0007.md:we never block on the peer` -- ADR that explains the why-here rationale

---

## Core Domain Terms

> Terms that are important domain vocabulary but are not load-bearing spine concepts.
> Each sub-section groups related terms.

### {Term}

**Definition:** {Plain English definition -- what does this mean in this domain?}

**Code reference:** {Where this entity appears: model class, database table, API endpoint, etc.}

**Usage notes:** {How the team uses this term. Edge cases. Common misunderstandings.}

**Related terms:** {other terms that relate to this one}

**Example:** {A concrete example that illustrates the definition}

---

> Repeat the above block for each term. Below are some examples with the template filled in:

### Order

**Definition:** A customer's confirmed intent to purchase. An Order exists once payment method is captured, regardless of fulfillment status.

**Code reference:** `Domain.Orders.Order` entity, `orders` database table, `/api/v1/orders` endpoints

**Usage notes:** The team distinguishes "Order" (confirmed) from "Cart" (pre-confirmation). Never use "Order" to mean a pending cart. An Order can be in states: Pending, Processing, Shipped, Delivered, Cancelled, Refunded.

**Related terms:** Cart, Fulfillment, Invoice

**Example:** "When a customer clicks Checkout and payment succeeds, a Cart becomes an Order."

---

### {AnotherTerm}

**Definition:** {definition}

**Code reference:** {where in code}

**Usage notes:** {team-specific notes}

---

## Abbreviations & Acronyms

| Abbreviation | Full Form | Context |
|-------------|-----------|---------|
| {e.g., SKU} | Stock Keeping Unit | {inventory management — unique product identifier} |
| {e.g., PO} | Purchase Order | {procurement — not to be confused with Customer Order} |
| {e.g., SLA} | Service Level Agreement | {ops — response/resolution time commitments} |

---

## Terms with Specific Domain Meanings

> Standard industry terms that mean something different in this codebase or domain.

| Term | Industry Meaning | Domain Meaning Here |
|------|-----------------|---------------------|
| {e.g., "Customer"} | {person who buys} | {in this system: an Organization account, not an individual} |
| {e.g., "Product"} | {thing for sale} | {the top-level catalog item; a Variant is the actual purchasable SKU} |

---

## Terms to Avoid

> Words that cause confusion and should not appear in new code, specs, or documentation.

| Avoid | Use Instead | Reason |
|-------|-------------|--------|
| {e.g., "User"} | {e.g., "Customer" or "Admin"} | {ambiguous — means different things in different contexts} |
| {e.g., "Record"} | {e.g., specific entity name} | {too generic — use the actual entity name} |

---

## Business Process Vocabulary

> Key business processes and their names. Knowing these helps AI agents write code that aligns with domain language.

| Process | Description | Trigger | Outcome |
|---------|-------------|---------|---------|
| {e.g., "Fulfillment"} | {picking, packing, shipping an order} | {Order status → Processing} | {Order status → Shipped} |
| {e.g., "Reconciliation"} | {matching financial records against bank statements} | {end of business day} | {exceptions report generated} |

---

## Invariants

> **Conceptual invariants** that MUST always hold about the spine concepts above -- the
> relationships and rules the vocabulary depends on that an agent would otherwise violate
> while "technically" using the right words. These are not code invariants (those live in
> `architecture.md` / `module-map.md`); these are about meaning. State each as a hard rule.

- **{Concept relationship}:** {e.g. "an Order MUST have captured payment -- a Cart is never an
  Order; the two terms are never interchangeable"}.
- **{State rule}:** {e.g. "an Order's state MUST progress forward through the lifecycle; it
  never returns to Pending once Processing"}.
- **{Identity rule}:** {e.g. "a Customer is an Organization account, never an individual user
  -- code that conflates them violates the domain model"}.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-describe | Initial glossary from stakeholder interview |

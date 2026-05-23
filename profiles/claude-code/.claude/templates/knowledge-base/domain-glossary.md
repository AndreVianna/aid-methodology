# Domain Glossary

> **Source:** aid-interview (Phase 2) — captured from stakeholder language
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

> This glossary documents the **team's actual language** — not industry standard terms, but what *this* team means when they use these words. When building with AI agents, this is critical: an agent that uses "transaction" when the team means "order" will write specs and code that technically work but conceptually misalign.

---

## Core Domain Terms

### {Term}

**Definition:** {Plain English definition — what does this mean in this domain?}

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

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-interview | Initial glossary from stakeholder interview |

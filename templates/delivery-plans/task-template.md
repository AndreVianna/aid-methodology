# task-{id}: {Name}

> **Delivery:** DELIVERY-{id}
> **User Story:** US-{id}
> **Status:** Not Started | In Progress | In Review | Complete
> **Complexity:** S | M | L | XL
> **Assigned to:** {agent instance or human}

---

## Objective

{What this task accomplishes in 1-2 sentences. Be specific — this is what the agent reads first and uses to calibrate everything that follows.}

**Example:** "Implement the `IOrderRepository` interface with PostgreSQL-backed CRUD operations using Entity Framework Core, following the repository pattern established in `aid-workspace/knowledge/architecture.md`."

---

## Context

> Critical context the agent needs before starting. Don't assume the agent has read everything — tell it what matters.
> **Always include `aid-workspace/knowledge/INDEX.md`** — the agent's map of the full Knowledge Base. If you need context not listed below, consult the INDEX and read the relevant document before making assumptions.

**Architecture reference:** {KB architecture.md section this task extends}
**Coding standards:** {KB coding-standards.md section most relevant}
**Data model:** {KB data-model.md tables this task touches}
**Related existing code:** {path/to/similar/existing/code — "follow this pattern"}
**KB Index:** `aid-workspace/knowledge/INDEX.md` — consult for additional context on demand

---

## Interface Contracts

> The public API this task introduces or changes. Defined before implementation — the test is written against this.

```csharp
// C# example:
public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<Order>> GetByCustomerAsync(Guid customerId, CancellationToken ct = default);
    Task<Order> SaveAsync(Order order, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
}
```

```typescript
// TypeScript example:
export interface OrderRepository {
  findById(id: string): Promise<Order | null>;
  findByCustomer(customerId: string): Promise<Order[]>;
  save(order: Order): Promise<Order>;
  delete(id: string): Promise<void>;
}
```

---

## Acceptance Criteria

> Concrete, testable. An agent should be able to read this list and write tests against each criterion before writing the implementation.

- [ ] `GetByIdAsync` returns the Order when it exists
- [ ] `GetByIdAsync` returns `null` when the ID doesn't exist
- [ ] `SaveAsync` persists a new Order and returns it with the generated ID
- [ ] `SaveAsync` updates an existing Order and returns the updated version
- [ ] `DeleteAsync` removes the Order — subsequent `GetByIdAsync` returns `null`
- [ ] All methods correctly propagate the CancellationToken
- [ ] Zero warnings on build
- [ ] Unit tests pass
- [ ] Integration test passes against real database (Testcontainers)

---

## Test Requirements

**Unit tests:** {n-m expected}
- {what to mock, what to assert}
- {edge cases to cover: null inputs, empty results, exception propagation}

**Integration tests:** {n expected — if applicable}
- {what real dependency to test against}
- {what scenarios: CRUD round-trip, concurrent writes, etc.}

**Edge cases to cover explicitly:**
- {edge case 1}
- {edge case 2}
- {concurrent access / race condition if relevant}

---

## Files to Touch

> Guidance for the agent. Not a mandate — the agent may need to touch other files, but this gives direction.

**Create:**
- `{path/to/new/Implementation.cs}` — the main implementation
- `{path/to/tests/ImplementationTests.cs}` — unit tests
- `{path/to/tests/integration/ImplementationIntegrationTests.cs}` — integration tests (if applicable)

**Modify:**
- `{path/to/DependencyInjection.cs}` — register the new service (line ~{n}, follows existing pattern)
- `{path/to/DbContext.cs}` — add DbSet if new entity (line ~{n})

**Do NOT modify:**
- `{path/to/sensitive/file}` — {reason: owned by another task / not in scope / risk of regression}

---

## Notes & Gotchas

> Things the agent needs to know that aren't obvious from the task or KB.

- {e.g., "The `Order` entity uses soft deletes — always filter `WHERE deleted_at IS NULL`. See KB data-model.md."}
- {e.g., "Don't use `SaveChanges()` directly — this service uses Unit of Work, call `_unitOfWork.CommitAsync()` instead."}
- {e.g., "The test database is reset between tests via Testcontainers — don't use shared IDs."}

---

## Impediment Protocol

If you discover that the KB is wrong, the spec contradicts the actual code, or an assumption in this task doesn't hold:

1. **Stop** — don't silently work around it
2. **Create** `IMPEDIMENT-{n}.md` using the template in `templates/feedback-artifacts/IMPEDIMENT.md`
3. **Document** what you found, what you assumed, and what the options are
4. **Wait** for resolution before proceeding

Silent workarounds are how tech debt is born.

---

## Completion Record

> Filled in when task is complete.

**Completed:** {date}
**Branch:** {branch}
**Files changed:** {n}
**Tests added:** {n unit / n integration}
**Build status:** ✅ Green | ❌ Failed
**Review grade:** {when reviewed}

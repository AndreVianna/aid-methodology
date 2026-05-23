# Architecture

> **Source:** aid-discover (Phase 1)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

---

## Pattern

> Identify the primary architectural pattern(s). Be specific — not just "MVC" but how MVC is applied.

**Primary Pattern:** {MVVM | Clean Architecture | CQRS | Layered | Microservices | Hexagonal | Monolith | other}

{2-3 sentences explaining how this pattern is actually implemented in this codebase. Reference specific folders, namespaces, or files where the pattern is visible.}

**Secondary Patterns:** {any additional patterns in specific subsystems}

---

## Layers

> Map the logical layers. Focus on what actually exists in the code, not what the documentation claims.

| Layer | Purpose | Key Namespaces / Packages / Folders |
|-------|---------|-------------------------------------|
| {Presentation / UI / API} | {Handles incoming requests, renders output} | {path/to/ui} |
| {Application / Service} | {Orchestrates use cases, no business rules} | {path/to/services} |
| {Domain / Business} | {Core entities, business rules, domain logic} | {path/to/domain} |
| {Infrastructure / Data} | {Database access, external services, I/O} | {path/to/infra} |

---

## Module Boundaries

> What talks to what. Dependency direction is critical — document it.

```
{ModuleA} → {ModuleB}     (ModuleA depends on ModuleB)
{ModuleB} → {ModuleC}
{ModuleA} ✗ {ModuleC}     (direct dependency NOT present — goes through B)
```

**Boundary rules observed in code:**
- {e.g., "Domain layer has no dependencies on Infrastructure — enforced via project references"}
- {e.g., "Services access repositories via interfaces, never concrete implementations"}
- {e.g., "UI layer does not import domain entities directly — uses DTOs"}

---

## Data Flow

> Trace the main path through the system: entry point → processing → storage → response.

**Primary request flow:**
```
{Entry: e.g., HTTP request → Controller}
  → {Validation: e.g., FluentValidation}
  → {Application layer: e.g., CommandHandler}
  → {Domain: e.g., AggregateRoot.Handle()}
  → {Persistence: e.g., Repository.Save()}
  → {Response: e.g., DTO mapped and returned}
```

**Background job flow (if applicable):**
```
{Trigger: e.g., scheduled / message queue}
  → {Worker / Consumer}
  → {Processing}
  → {Output}
```

---

## Dependency Injection

| Property | Value |
|----------|-------|
| **Framework** | {Microsoft.Extensions.DI | Autofac | Spring | Guice | manual | none} |
| **Registration location** | {path/to/startup/file} |
| **Lifetime conventions** | {Singleton for: X; Scoped for: Y; Transient for: Z} |

---

## Key Architectural Decisions

> Significant decisions visible in the code. Include rationale if evident from comments or structure.

| Decision | What | Why (if evident) |
|----------|------|-----------------|
| {e.g., Event sourcing in Orders} | {All order state changes are stored as events} | {Comment in EventStore.cs references audit requirements} |
| {e.g., Synchronous HTTP for all integrations} | {No async client libraries used} | {Unknown — possible legacy constraint} |
| {e.g., CQRS split in Search module only} | {SearchQuery vs. SearchCommand separate paths} | {Performance — read model is denormalized} |

---

## Known Architectural Issues

> Things that exist but shouldn't, or are missing but should exist.

- {e.g., "Circular dependency between OrderService and CustomerService — both import each other"}
- {e.g., "Domain entities directly reference EF Core — infrastructure concern leaked into domain"}
- {e.g., "No clear boundary between Application and Domain layers — business logic in service methods"}

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial discovery |

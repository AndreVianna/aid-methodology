# Coding Standards

> **Source:** aid-discover (Phase 1) — inferred from code analysis
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

> ⚠️ **Important:** These conventions are **inferred from code analysis**. They reflect what the code actually does, not what documentation claims. Confirm ambiguous or inconsistent patterns with the team before enforcing them in new code.

---

## Naming Conventions

| Element | Convention | Example | Exceptions |
|---------|-----------|---------|------------|
| Classes | {PascalCase} | `OrderProcessor` | |
| Interfaces | {IPascalCase / PascalCase} | `IOrderRepository` | |
| Methods | {PascalCase / camelCase} | `ProcessOrder()` | |
| Variables (local) | {camelCase} | `orderCount` | |
| Constants | {UPPER_SNAKE / PascalCase} | `MAX_RETRY_COUNT` | |
| Files | {convention} | {example} | |
| Namespaces/Packages | {convention} | {example} | |
| Database columns | {snake_case / PascalCase} | `created_at` | |

**Observed inconsistencies:** {list any places where naming deviates from the norm}

---

## Error Handling

| Property | Pattern |
|----------|---------|
| **Primary pattern** | {Exceptions / Result\<T\> / Either monad / error codes} |
| **Exception hierarchy** | {Base exception class, if any — e.g., `AppException : Exception`} |
| **Where caught** | {e.g., only at service boundary; middleware handles HTTP errors} |
| **Logging on error** | {always / on unhandled / never — and with what context} |

**Example pattern:**
```csharp
// Example showing the actual error handling pattern observed
```

---

## Logging

| Property | Value |
|----------|-------|
| **Framework** | {e.g., Serilog, NLog, log4j, structlog, winston} |
| **Format** | {Structured (JSON) / Unstructured text} |
| **Log levels used** | {Verbose, Debug, Info, Warning, Error, Fatal} |
| **Contextual data** | {What's always included: correlation ID, user ID, etc.} |

**Observed logging pattern:**
```csharp
// Example of how logging is done in this codebase
```

---

## Configuration Management

| Property | Value |
|----------|-------|
| **Pattern** | {appsettings.json + env overrides / pure env vars / config server / other} |
| **Secrets** | {user secrets / env vars / vault / AWS SSM / other} |
| **Environment naming** | {Development, Staging, Production / dev, test, prod / other} |
| **Feature flags** | {if any — tool and pattern} |

---

## File & Project Organization

| Property | Convention |
|----------|-----------|
| **Files per class** | {One class per file / grouped by feature / other} |
| **Folder structure** | {By layer / by feature / by type / mixed} |
| **Test file location** | {Co-located with source / separate test project / test folder} |
| **Test file naming** | {e.g., `{Class}Tests.cs` / `test_{class}.py` / `{class}.spec.ts`} |

---

## Code Organization Patterns

> Higher-level patterns observed consistently across the codebase.

- **{Pattern name}:** {description of where and how it's used}
- **{Pattern name}:** {description}

**Example:** "Repository pattern is used for all database access. Repositories are always injected as interfaces. No direct DbContext usage outside repository implementations."

---

## Comments & Documentation

| Property | Convention |
|----------|-----------|
| **API documentation** | {XML docs / JSDoc / docstrings / none} |
| **When to comment** | {Public APIs only / complex logic / always / rarely} |
| **Observed style** | {Describe what you see in the code} |

---

## Observed Inconsistencies

> Document places where the codebase doesn't follow its own conventions. These are tech debt items for awareness.

| Area | Inconsistency | Files Affected | Recommendation |
|------|--------------|----------------|----------------|
| {e.g., Naming} | {Some services use `Manager` suffix, some use `Service`} | {list} | {Standardize on Service in new code} |
| {e.g., Error handling} | {Legacy controllers return 200 with error body; newer ones use ProblemDetails} | {list} | {New code uses ProblemDetails} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial conventions inferred from code |

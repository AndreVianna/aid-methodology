# Known Issues Scope & Feature-Specific Quality Gates

Reference material for the specify skill — what to register as known issues
during codebase exploration, and how to handle feature-specific quality requirements.

## Known Issues Scope

**File:** `.aid/{work}/known-issues.md` — one per work, shared across all features.
Created from `../../../templates/known-issues.md` on first issue found.

**Only register issues found in code this feature touches.** The filter:

> *"Can I implement this feature without resolving this?"*
> - **No** → register (blocks or compromises the feature)
> - **Yes, but it gets worse** → register with Severity: Medium

**Four types only:**

| Type | Example |
|------|---------|
| **Bug** | NullPointerException in OrderService.processAsync when basket is empty |
| **Security** | SQL injection in UserRepository.findByEmail — string concatenation |
| **Deprecated Dependency** | Jackson 2.13 (EOL) used by the serialization layer this feature extends |
| **Breaking API Contract** | GET /api/orders returns 200 with empty body instead of 404 when not found |

**Excluded** (scope creep):
- Coding standard violations → already in `coding-standards.md` (KB)
- Code smells / long methods → general tech debt, not actionable per-feature
- Tech debt not touching this feature → stays in `tech-debt.md` (KB)

## Feature-Specific Quality Gates

REQUIREMENTS.md §6 defines the **project baseline** for unit tests and linting.
Specify may add **feature-specific requirements** on top of that baseline.

During the Discussion Loop, when proposing sections that involve complex logic,
edge cases, or critical paths, explicitly discuss:

- **Test requirements beyond baseline** — "This auth flow has 5 edge cases
  (expired token, revoked user, concurrent refresh, etc.) — each needs an
  explicit test beyond the coverage minimum."
- **Feature-specific lint rules** — "This module handles user input — stricter
  lint rules for input validation apply (e.g., no raw string concatenation
  in SQL queries)."

Write these in the relevant SPEC.md section (e.g., within Security Specs, Feature Flow,
or a dedicated "Quality Requirements" subsection if multiple apply).

These flow down to `/aid-detail` where they become concrete acceptance criteria on tasks.

**Cross-reference with KB:** Before registering, check `tech-debt.md`. If already
catalogued, add a reference (`See tech-debt.md #TD-NNN`) instead of duplicating.

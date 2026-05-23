# Tech Debt

> **Source:** aid-discover (Phase 1)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

> This document is a diagnosis, not a sprint plan. It identifies what exists so that agents don't create more of it, and so the team can make informed decisions about what to address and when.

---

## Debt Inventory

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| TD-001 | {Complexity / Test Gap / Outdated Dep / Architecture / Other} | {description} | {file/module} | {High/Med/Low} | {S/M/L/XL} | {P1/P2/P3} |

**Risk definitions:**
- **High** — Active production risk. Affects reliability, security, or maintainability of core features.
- **Medium** — Growing cost. Will become high-risk if not addressed within 1-2 cycles.
- **Low** — Known issue, not urgent. Track but don't block on it.

---

## Detailed Debt Items

### TD-001: {Title}

**Type:** {Complexity / Test Gap / Outdated Dependency / Architecture Violation / Duplication / Dead Code / Security / Performance}

**Description:** {What the problem is. Be concrete — reference specific files, patterns, and behaviors.}

**Location:**
- `{path/to/file.ext}` — {what's wrong here}
- `{path/to/other.ext}` — {what's wrong here}

**Symptoms:**
- {observable problem this causes today}
- {problem it will cause if left unaddressed}

**Root Cause:** {why this debt exists — time pressure, legacy migration, unclear requirements, etc.}

**Remediation:**
- {specific steps to fix}
- {estimated effort: S/M/L/XL}
- {risks of fixing — what might break}

**Dependencies:** {Does fixing this unblock or require other changes?}

---

## Complexity Hotspots

> Files/classes with cyclomatic complexity above threshold. These are where bugs hide.

| File | Complexity | Size (lines) | Last Modified | Notes |
|------|-----------|-------------|---------------|-------|
| {path/to/file} | {n} | {n} | {date} | {why it's complex} |

**Threshold used:** {e.g., cyclomatic complexity > 15 flagged}

---

## Missing Test Coverage

> Modules and functions that lack meaningful tests — concentrated risk.

| Module / Function | Current Coverage | Type Missing | Business Risk |
|------------------|-----------------|--------------|---------------|
| {module} | {%} | {unit / integration / E2E} | {what breaks if this fails} |

---

## Outdated Dependencies

> Dependencies flagged as outdated, end-of-life, or with known CVEs.

| Package | Current | Latest | EOL | CVE | Migration Effort |
|---------|---------|--------|-----|-----|-----------------|
| {package} | {version} | {version} | {date / N/A} | {CVE-XXXX / none} | {S/M/L} |

---

## Architecture Violations

> Places where the current code violates the intended architecture.

| Violation | Location | Should Be | Impact |
|-----------|----------|-----------|--------|
| {e.g., Domain entity imports EF Core} | `Domain/Order.cs` | {No infrastructure deps in Domain} | {Prevents testing without DB} |
| {e.g., Business logic in controller} | `Controllers/OrderController.cs` | {In Application layer} | {Can't reuse logic, hard to test} |

---

## Duplication

> Significant duplicated logic that should be consolidated.

| Area | Copies | Location | Risk if Not Consolidated |
|------|--------|----------|--------------------------|
| {e.g., Email validation logic} | 4 | {list files} | {Inconsistent validation behavior} |

---

## Dead Code

> Code that exists but is no longer used. Removal reduces cognitive load and maintenance surface.

| Item | Location | Evidence of Disuse | Safe to Remove? |
|------|----------|--------------------|-----------------|
| {class/method/file} | {path} | {no references / commented out / feature flag off} | {Yes / Verify first} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial debt audit |

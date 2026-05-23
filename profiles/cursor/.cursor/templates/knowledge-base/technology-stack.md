# Technology Stack

> **Source:** aid-discover (Phase 1)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

---

## Runtime

| Property | Value |
|----------|-------|
| **Primary Language** | {e.g., C# 12, TypeScript 5.3, Java 21, Python 3.12} |
| **Runtime** | {e.g., .NET 10, Node.js 22, JVM 21, CPython 3.12} |
| **Target OS** | {e.g., Linux/Windows (any), Windows only, macOS} |
| **Architecture** | {e.g., x64, ARM64, cross-platform} |

---

## Frameworks

| Framework | Version | Purpose | Notes |
|-----------|---------|---------|-------|
| {e.g., ASP.NET Core} | {8.0.x} | {HTTP server, routing, middleware} | |
| {e.g., Entity Framework Core} | {8.0.x} | {ORM, migrations} | {Using code-first migrations} |
| {e.g., React} | {18.x} | {UI rendering} | |
| {e.g., FastAPI} | {0.110.x} | {REST API framework} | |

---

## Build System

| Property | Value |
|----------|-------|
| **Build Tool** | {e.g., MSBuild, Maven, Gradle, npm scripts, cargo, make} |
| **Package Manager** | {e.g., NuGet, npm, pip + uv, Maven, cargo} |
| **Lock File** | {e.g., packages.lock.json, package-lock.json, Pipfile.lock — path} |
| **CI System** | {e.g., GitHub Actions, Azure DevOps, Jenkins — pipeline file path} |

**Build commands:**
```bash
# Build
{command to build the project}

# Run tests
{command to run all tests}

# Run locally
{command to start the app}

# Package/publish
{command to create deployable artifact}
```

---

## Key Dependencies

> Focus on non-obvious or version-sensitive dependencies. Skip standard library equivalents.

| Package | Version | Purpose | Concerns |
|---------|---------|---------|----------|
| {package-name} | {version} | {what it does} | {end-of-life? known vulnerabilities? heavily customized?} |
| {e.g., Newtonsoft.Json} | {13.0.3} | {JSON serialization} | {Consider migrating to System.Text.Json} |
| {e.g., log4j-core} | {2.17.1} | {logging} | {Post-Log4Shell patched version — verify} |

---

## Test Frameworks

| Framework | Version | Scope | Notes |
|-----------|---------|-------|-------|
| {e.g., xUnit} | {2.x} | {Unit + Integration} | |
| {e.g., Playwright} | {1.x} | {E2E} | |
| {e.g., Testcontainers} | {3.x} | {Integration (DB, MQ)} | {Used in integration tests — requires Docker} |

---

## Version Concerns

> Flag anything out of date, end-of-life, or with known vulnerabilities.

| Package / Runtime | Current | Latest | Status | Priority |
|-------------------|---------|--------|--------|----------|
| {item} | {version} | {latest} | {⚠️ EOL / 🔴 CVE / ✅ OK} | {High / Medium / Low} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial stack inventory |

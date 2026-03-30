# Document Expectations

These define what the reviewer (and FIX mode) should look for in each document.

---

### project-structure.md
Must have: directory tree (top 3-4 levels with annotations), file counts per major directory,
key files and their purpose (entry points, build files, configs, tests), detected languages
and frameworks, documentation files found in the repository. This is an inventory/map — not
deep analysis. Other agents use this to know WHERE to look.
**Red flags**: Too shallow (just a tree dump without annotations). Missing file counts.
Too deep (analyzing patterns instead of mapping structure). Missing key build/config files.

### architecture.md
Must have: project type, folder structure (annotated), architectural patterns with evidence,
module boundaries, data flow (entry→processing→persistence), DI registration, entry points.
**Red flags**: Generic descriptions without file paths. Missing data flow.

### technology-stack.md
Must have: languages with versions, frameworks with versions (from actual config files),
databases, package managers, build tools, runtime, dev tooling.
Must have: **Build Commands** section with exact build command(s), **Lint Commands** section
with exact lint command(s). These are critical for aid-execute — agents need runnable
commands, not just tool names.
**Red flags**: "⚠️ Version TBD" on things extractable from pom.xml/package.json/manifests.
Missing or vague Build/Lint Commands (e.g., just "Maven" without `mvn clean package`).

### module-map.md
Must have: every module listed with purpose, key classes, dependencies between modules.
**Red flags**: Module listed without purpose explanation. Missing dependency relationships.

### coding-standards.md
Must have: naming conventions (with examples from code), file layout, DI patterns, error
handling, logging patterns, test patterns.
**Red flags**: Generic advice instead of project-specific conventions.

### data-model.md
Must have: entity hierarchy, relationships (1:N, M:N), base classes, key entities with
purpose, database config, migration strategy.
**Red flags**: Entity list without relationships. Missing how entities connect to each other.

### api-contracts.md
Must have: API style, actual endpoint paths/URLs (not just class names), auth mechanism,
request/response formats, error patterns.
**Red flags**: Lists action classes without URLs. Missing how to actually call the API.

### integration-map.md
Must have: external systems with connection details, protocols, config locations, error
handling, retry patterns. NOT just a module list.
**Red flags**: Same content as module-map.md. Missing connection details.

### domain-glossary.md
Must have: business-specific terms, technical terms unique to this project, abbreviations,
product names with explanations.
**Red flags**: Generic programming terms. Missing project-specific vocabulary.

### test-landscape.md
Must have: frameworks, test types, coverage metrics/goals, CI integration, which modules
have real tests vs placeholders, test gaps with severity.
Must have: **Test Commands** section with exact commands to run all unit tests, per-module
tests, and coverage reports. These are critical for aid-execute — agents need runnable
commands, not just framework names.
**Red flags**: Too short. Missing per-module coverage assessment. Missing or vague Test
Commands (e.g., just "JUnit" without `mvn test`).

### security-model.md
Must have: auth mechanisms, authorization model, secrets management, transport security,
OWASP assessment, access logging.
**Red flags**: Generic OWASP checklist without project-specific assessment.

### tech-debt.md
Must have: categorized by severity (Critical/High/Medium/Low), each with location, risk,
and notes. Observations about overall health.
**Red flags**: Missing severity classification. No actionable locations.

### infrastructure.md
Must have: Source Control section (VCS type, hosting, branch/commit commands), CI/CD pipeline
details, container config, Deployment section (build output type, packaging, publishing target,
versioning scheme, release process), Project Management section (tool or "none", access method,
entity mapping if applicable), artifact repos, runtime config, monitoring, environments.
**Red flags**: Lists tools without explaining how they're configured or connected. Missing Source
Control section or assuming Git without verifying. Missing Deployment section. Project Management
section absent (should explicitly say "none" if no tool is used).

### ui-architecture.md
Must have (if frontend exists): component architecture (tree, composition patterns),
state management (framework, data flow), design system (tokens, library),
routing (router, guards), responsive strategy (breakpoints, device targets),
accessibility (WCAG level, ARIA patterns), styling approach (method, conventions),
build & bundle (bundler, code splitting, lazy loading).
If backend-only: explicitly states "No frontend detected."
**Red flags**: Lists frameworks without explaining patterns. Missing component tree.
Missing state management data flow. No accessibility section.

### feature-inventory.md
Must list ALL features identified by the user. Each feature has description, status, modules,
endpoints, data entities. Red flag: features without module mapping, features with placeholder
descriptions, features obviously missing from user's original list.

### external-sources.md
Must have: list of all external documentation sources provided by the user (if any), with
path, type (file/directory), date provided, accessibility status, and summary of key content.
If no external sources were provided, must explicitly state that all knowledge was derived
from repository content only.
**Red flags**: Missing when external paths were registered in aid-init. No summary of what
was found in external sources. Not reflecting which KB documents reference external content.

### INDEX.md
Must have: accurate 2-3 line summary per document. Summaries must reflect actual content.
**Red flags**: Generic summaries. Summaries that don't match document content.

### README.md
Must have: completeness table, revision history.
**Red flags**: Missing gap acknowledgment.

### CLAUDE.md
Must have: accurate project description, project overview, real build/test commands,
conventions from code, architecture summary, KB reference. No remaining `(pending discovery)` placeholders.

**Red flags**: Placeholder text still present. Commands that wouldn't actually work. Missing key gotchas for agents.

# Security

**Specialist Agent — invoked ad-hoc**

The Security specialist provides expertise in threat modeling, OWASP compliance, authentication/authorization patterns, secrets management, vulnerability assessment (SSRF, injection, XSS), and dependency auditing. It is called when the pipeline needs security expertise.

## What It Does

The Security agent evaluates code and architecture for security vulnerabilities, reviews authentication and authorization implementations, audits dependencies for known CVEs, and performs threat modeling for new features. It thinks like an attacker — looking for what could go wrong, not just what works correctly.

## When It's Invoked

| Called By | Context |
|-----------|---------|
| **Critic** | During Review — security-focused code review |
| **Researcher** | During Discover — security posture assessment of existing codebase |
| **Architect** | During Specify — threat modeling for new features |
| **Orchestrator** | When any phase needs security expertise |

This agent is not part of the standard pipeline flow. It is called on demand when security expertise is needed.

## What It Produces

- **Threat models** — attack surfaces, threat actors, mitigation strategies
- **Security review findings** — vulnerabilities with severity (Critical/High/Medium/Low), evidence, and remediation
- **Dependency audit results** — CVE findings with affected packages and upgrade paths
- **Auth/authz review** — authentication flow analysis, authorization gap identification
- **Secrets audit** — hardcoded secrets, insecure storage, rotation recommendations

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Critic** | Critic evaluates *general code quality*. Security evaluates *attack surface*. |
| **Researcher** | Researcher documents *what exists*. Security finds *what's exploitable*. |
| **DevOps** | DevOps configures infrastructure. Security audits it for vulnerabilities. |

## Tools

- **Read, Glob, Grep** — reviewing code for vulnerability patterns
- **Bash** — running security scanning tools (npm audit, snyk, trivy, semgrep, etc.)

## Model

**Opus** — security requires deep analysis. Missing a vulnerability is worse than missing a code style issue. The Security agent needs to think about edge cases, attack chains, and subtle logic flaws.

## Examples

- *"Review the new API endpoints for security."* → OWASP Top 10 analysis with specific findings
- *"We're adding OAuth2. Is the implementation secure?"* → Auth flow review, token handling audit
- *"Run a dependency audit."* → CVE scan with severity and upgrade recommendations
- *"Threat model the new payment feature."* → Attack surface analysis with mitigations

# Security Model

> **Source:** aid-discover (Phase 1) + aid-interview (Phase 2)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

> ⚠️ **Sensitivity note:** This document should not contain actual credentials, secrets, or sensitive infrastructure details. It describes patterns and architecture — not values.

---

## Authentication

| Property | Value |
|----------|-------|
| **Mechanism** | {JWT Bearer / Session cookies / API Keys / OAuth2 / OIDC / Basic / mTLS / other} |
| **Identity Provider** | {Auth0 / Cognito / Okta / Keycloak / Azure AD / custom / none} |
| **Token storage** | {HttpOnly cookie / localStorage / memory / other} |
| **Token lifetime** | {access token: Xm / refresh token: Xd} |
| **Refresh strategy** | {sliding / absolute / none} |

**Authentication flow:**
```
{Describe the auth flow in plain steps}
1. Client submits credentials to {endpoint}
2. Server validates against {store}
3. Server returns {access token + refresh token}
4. Client includes {Bearer token / cookie} in subsequent requests
```

---

## Authorization

| Property | Value |
|----------|-------|
| **Model** | {RBAC / ABAC / ACL / Permission-based / none} |
| **Role definitions** | {where roles are defined: code / database / identity provider} |
| **Enforcement location** | {middleware / attribute decorators / explicit checks in service layer} |

**Roles defined:**

| Role | Permissions | Notes |
|------|-------------|-------|
| {Admin} | {full access} | |
| {User} | {own data only} | |
| {ReadOnly} | {GET requests only} | |

**Authorization code pattern:**
```csharp
// Example showing how authorization is enforced in this codebase
```

---

## Secrets Management

| Property | Value |
|----------|-------|
| **Approach** | {Environment variables / Azure Key Vault / AWS Secrets Manager / HashiCorp Vault / .env files / user secrets (dev only)} |
| **Dev environment** | {user secrets / .env (git-ignored) / other} |
| **Production** | {vault / cloud secrets / env vars injected at deploy} |
| **Rotation policy** | {manual / automatic / not defined} |

**Secret naming convention:** `{APP_NAME}_{SECRET_NAME}` (e.g., `MYAPP_DATABASE_CONNECTION_STRING`)

---

## Data Protection

| Property | Value |
|----------|-------|
| **Data in transit** | {TLS 1.2+ / TLS 1.3 / mixed} |
| **Data at rest** | {encrypted (DB-level) / encrypted (field-level) / not encrypted} |
| **PII handling** | {stored / not stored / anonymized / pseudonymized} |
| **Sensitive fields** | {list fields that contain PII or sensitive data} |

---

## Compliance Requirements

| Requirement | Status | Notes |
|-------------|--------|-------|
| {GDPR} | {Compliant / Partial / Not addressed} | |
| {HIPAA} | {N/A / Compliant / other} | |
| {SOC 2} | {Certified / In progress / N/A} | |
| {PCI DSS} | {N/A / Compliant — outsourced to Stripe / other} | |

---

## Input Validation & Injection Prevention

| Attack Surface | Mitigation |
|---------------|-----------|
| {SQL injection} | {ORM parameterization / raw query policy} |
| {XSS} | {output encoding / CSP headers / React auto-escaping} |
| {CSRF} | {SameSite cookies / CSRF tokens / stateless JWT} |
| {File upload} | {type validation / size limits / virus scan / isolated storage} |

---

## Known Security Concerns

> Security issues identified during discovery that should be addressed.

| Concern | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| {e.g., Hardcoded API key in config.json} | {Critical} | {path/to/file} | {Move to secrets manager immediately} |
| {e.g., SQL query string concatenation in legacy module} | {High} | {path/to/file} | {Parameterize before next feature work} |
| {e.g., No rate limiting on authentication endpoint} | {Medium} | {/api/auth} | {Add rate limiting middleware} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover + aid-interview | Initial security model |

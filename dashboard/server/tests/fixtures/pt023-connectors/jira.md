---
name: "Jira"
connection_type: api
endpoint: "https://acme.atlassian.net/rest/api/3"
auth_method: token
secret_reference: "file:.aid/connectors/.secrets/jira"
preset: custom
objective: "Connect to Jira via api at https://acme.atlassian.net/rest/api/3."
summary: "Jira (api) -- auth: token."
tags: [connector, api]
audience: [developer, architect]
---

# Jira

> Connection: api · Mode: aid-managed · Auth: token (reference: file:.aid/connectors/.secrets/jira)

Resolve the credential via `file:.aid/connectors/.secrets/jira` at use-time; AID never stores the secret value in this descriptor.

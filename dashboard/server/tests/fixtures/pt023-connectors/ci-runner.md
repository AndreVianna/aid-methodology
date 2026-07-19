---
name: "CI Runner"
connection_type: cli
endpoint: "ci-runner-cli --profile prod"
auth_method: pat
secret_reference: "file:.aid/connectors/.secrets/ci-runner"
preset: custom
objective: "Connect to CI Runner via cli at ci-runner-cli --profile prod."
summary: "CI Runner (cli) -- auth: pat."
tags: [connector, cli]
audience: [developer, architect]
---

# CI Runner

> Connection: cli · Mode: aid-managed · Auth: pat (reference: file:.aid/connectors/.secrets/ci-runner)

Resolve the credential via `file:.aid/connectors/.secrets/ci-runner` at use-time; AID never stores the secret value in this descriptor.

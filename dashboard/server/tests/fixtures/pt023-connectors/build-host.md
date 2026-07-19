---
name: "Build Host"
connection_type: ssh
endpoint: "build.internal.example.com:22"
auth_method: ssh-key
secret_reference: "file:.aid/connectors/.secrets/build-host"
preset: custom
objective: "Connect to Build Host via ssh at build.internal.example.com:22."
summary: "Build Host (ssh) -- auth: ssh-key."
tags: [connector, ssh]
audience: [developer, architect]
---

# Build Host

> Connection: ssh · Mode: aid-managed · Auth: ssh-key (reference: file:.aid/connectors/.secrets/build-host)

Resolve the credential via `file:.aid/connectors/.secrets/build-host` at use-time; AID never stores the secret value in this descriptor.

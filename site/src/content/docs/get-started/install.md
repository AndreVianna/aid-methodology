---
title: Install AID
description: Choose your install channel and follow the full instructions in the Installation guide.
sidebar:
  order: 2
---

AID is distributed across four install channels. All channels deliver the same `aid` CLI — the
difference is only how `aid` lands on your PATH. Pick one channel per machine.

## Choose your channel

| Channel | Requires | Best for |
|---------|----------|----------|
| **curl / irm** (online bootstrap) | Bash or PowerShell 5.1+ | Most users — Linux, macOS, Windows |
| **npm** | Node >=18 | Node-heavy environments; global install via npm |
| **PyPI (pipx)** | Python >=3.8 | Python environments; isolated install |
| **Offline bundle** | Bash or PowerShell 5.1+ | Air-gapped machines; teams pinning to a specific release |

## Follow the full install guide

The [Installation guide](/guides/installation/) has the complete per-channel and per-OS
instructions, including:

- [Bootstrap the `aid` CLI (Step 1)](/guides/installation/#step-1--bootstrap-the-aid-cli) — pinned
  one-liners for Linux, macOS, and Windows across all four channels.
- [Add AID to your project (Step 2)](/guides/installation/#step-2--add-aid-to-your-project) — per-tool
  tabs for Claude Code, Codex, Cursor, Copilot CLI, and Antigravity.
- [Update and remove](/guides/installation/#update) — staying current and cleaning up.

## After install

Once `aid` is on your PATH, head to [Your first work](/get-started/first-work/) for a guided
walkthrough of running your first work through the pipeline.

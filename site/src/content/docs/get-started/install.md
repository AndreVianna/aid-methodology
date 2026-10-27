---
title: Install
description: This page shows you which channel to use to install the AID command on Linux, macOS or Windows.
sidebar:
  label: Install
  order: 2
---

This page shows you which channel to use to install the AID command on Linux, macOS or Windows.

AID reaches your machine through one of four [install channels](/reference/glossary/#install-channel). Every channel installs the same `aid` command. The channels differ only in how `aid` gets onto your PATH. Pick one channel per machine.

## Choose your channel

| Channel | Requires | Best for |
|---------|----------|----------|
| curl or irm | Bash, or PowerShell 5.1 or later | Most people, on Linux, macOS or Windows |
| npm | Node 22 or later | Machines that already use Node |
| PyPI | Python 3.8 or later | Machines that already use Python, with `pipx` |
| Offline bundle | Bash, or PowerShell 5.1 or later | Machines without network access, or teams that pin one release |

## Install the command

On Linux or macOS, run this command:

```bash
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash
```

On Windows, run this command in PowerShell:

```powershell
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex
```

Open a new shell afterwards, so your PATH picks up the `aid` command.

## Add AID to a project

Run this command inside your repository. Use another tool name if you do not use Claude Code.

```bash
aid add claude-code
```

The [Installation guide](/guides/installation/) has the full steps. It covers the npm, PyPI and offline channels, [adding AID to a project](/guides/installation/#step-2--add-aid-to-your-project), and [updating and removing AID](/guides/installation/#update).

## Next step

Once `aid` is on your PATH, follow [Your first work](/get-started/first-work/) to run a first piece of work through the pipeline.

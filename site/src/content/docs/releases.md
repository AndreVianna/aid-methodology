---
title: Releases
description: Where to find release notes and how to move to a newer version of AID.
sidebar:
  order: 1
---

Release notes live on GitHub, next to the downloadable install bundles:

- [AID releases on GitHub](https://github.com/AndreVianna/aid-methodology/releases): every version, newest first.

## See what you have

```bash
aid version
```

## Move to the newest version

Update the `aid` command itself, then the AID files in a project:

```bash
aid update self
aid update
```

Run the second command inside each project. `aid update all` updates every project the CLI knows about. See the [CLI reference](/reference/cli/) for the flags, and the [install guide](/get-started/install/) for pinning an exact version.

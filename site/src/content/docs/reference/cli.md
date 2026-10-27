---
title: The aid command
description: Every aid subcommand, flag, exit code and environment variable, plus where the CLI keeps its state.
sidebar:
  order: 1
---

`aid` is the command-line tool that installs AID into a project, keeps it up to date, and starts the helper programs (the dashboard and the agent chat node). It does not run the AID skills. You run those inside your AI coding tool.

To install the `aid` command itself, see the [Install guide](/get-started/install/). This page lists what the command can do.

## Commands at a glance

| Command | What it does |
|---|---|
| `aid` | Prints a text summary: the AID version, the tools installed in this project, and the help. |
| `aid status` | Shows the AID state of the current project. |
| `aid add <tool>[,<tool>...]` | Adds one or more AI coding tools to the current project. |
| `aid update` | Updates the CLI and every tool in the current project to one version. |
| `aid update self` | Updates only the `aid` CLI. |
| `aid update all` | Updates every registered project in one run. |
| `aid remove` | Removes all of AID from the current project (asks first). |
| `aid remove <tool>...` | Removes the named tools from the current project. |
| `aid remove self` | Removes the `aid` CLI from this machine. |
| `aid version` | Prints the CLI version. `aid --version` and `aid -V` do the same. |
| `aid dashboard start` / `stop` | Starts or stops the local pipeline dashboard. |
| `aid projects` | Lists, registers, unregisters or scans for AID projects. |
| `aid chat` | Lets one AI coding session talk to another. |

Add `-h` or `--help` to any command for its own help, for example `aid add -h`.

The text summary you get from bare `aid` is not the web dashboard. To open the web dashboard, see the [Dashboard guide](/guides/dashboard/).

## Tool names

`aid add` and `aid remove` take these tool names. Upper case is accepted. `claudecode` and `copilotcli` also work.

| Tool name | Tool |
|---|---|
| `claude-code` | Claude Code |
| `codex` | Codex |
| `cursor` | Cursor |
| `copilot-cli` | GitHub Copilot CLI |
| `antigravity` | Antigravity |

## Shared flags

These flags work on `add`, `update` and `remove` unless the table says otherwise.

| Flag | What it does |
|---|---|
| `--version <v>` | Pins a release, for example `3.1.3` or `v3.1.3`. Not the same as `aid --version`. Cannot be combined with `--from-bundle`. |
| `--from-bundle <path>` | Installs from a local download instead of fetching the latest release. The path can be an npm `.tgz`, a PyPI `.whl`, or a release staging folder that holds `install.sh`. |
| `--force`, `-y` | Skips confirmation prompts and overwrites files that differ. |
| `--dry-run` | Prints the plan and changes nothing. Used by `update`, `update self`, `update all` and `remove self`. |
| `--target <dir>` | Uses `<dir>` as the project root instead of the current folder. The folder must exist. Also works on `status`. |
| `--verbose` | Prints one line per file. Also works on `status`, `projects` and `dashboard`. |
| `--no-path` | Skips editing your shell `PATH`. Only for the bootstrap installer and `update self`. |

On Windows, `aid.cmd` runs `aid.ps1` in PowerShell. The PowerShell script accepts the `--` forms above and the PowerShell forms: `-Force`, `-Verbose`, `-Version <v>`, `-FromBundle <path>`, `-Target <dir>`, `-DryRun` and `-NoPath`.

## aid status

```bash
aid status [--verbose] [--target <dir>]
```

Shows the AID version, the tools installed in the project, and whether the shared files still match what was installed. A shared file that changed is listed as `modified`, `missing` or `extra`. With `--verbose`, each tool also shows how many files it installed.

```text
AID 3.1.3  (project: /path/to/your/project)
Installed tools - all at v3.1.3:
  claude-code
Shared files: clean
```

If the folder has no `.aid/` folder at all, `aid status` offers to set one up and exits 0. If it finds `.aid/` but no manifest, it prints `No AID install found` and exits 7.

## aid add

```bash
aid add <tool>[,<tool>...] [--version <v>] [--from-bundle <path>] [--force] [--verbose] [--target <dir>]
```

Installs the named tools into the current project. You can separate tools with commas or spaces. If you name no tool, `aid add` looks for a tool folder (such as `.claude` or `.cursor`) and uses it. It stops with exit 2 if it finds none or several.

```bash
aid add claude-code
aid add codex,cursor
aid add claude-code --version 3.1.3
```

Adding a tool also registers the project (see [aid projects](#aid-projects)). `aid add` refuses to run while an upgrade from an older layout is waiting. Run `aid update` first.

## aid update

```bash
aid update [--version <v>] [--from-bundle <path>] [--force] [--dry-run] [--target <dir>]
aid update self [--from-bundle <path>] [--dry-run]
aid update all [--version <v>] [--dry-run] [--force]
```

| Form | What it does |
|---|---|
| `aid update` inside a project | Updates the CLI first, then every installed tool to one version. Old project layouts are migrated. |
| `aid update` outside a project | Updates the CLI only. It does nothing if the CLI is already the latest. |
| `aid update self` | Updates the CLI only, by the same route you installed it. |
| `aid update all` | Updates every project in `aid projects list`. It downloads each tool once, reuses the download for every project, keeps going if one project fails, and prints a summary at the end. It does not accept `--target`. |

All tools in a project always move together, because they share one set of files. If you name a tool (`aid update cursor`), `aid` still updates every installed tool and prints which ones it added to the set.

`aid update self` picks the update route from how the CLI was installed:

| Install route | What `aid update self` runs |
|---|---|
| npm | `npm i -g` |
| PyPI | `pipx upgrade` |
| curl or PowerShell bootstrap | Runs the bootstrap installer again |

It asks for `sudo` only when the install folder needs it. After `aid update self`, `aid` offers to migrate each registered project. Set `AID_MIGRATE_YES=1` to say yes to all of them without a prompt.

## aid remove

```bash
aid remove [<tool>[,<tool>...]] [--force] [--verbose] [--target <dir>]
aid remove self [--force] [--dry-run]
```

| Form | What it does |
|---|---|
| `aid remove` | Removes all AID from the project. It asks you to confirm unless you pass `--force`. |
| `aid remove <tool>...` | Removes only those tools. |
| `aid remove self` | Removes the `aid` CLI by the route that installed it (`npm uninstall -g`, `pipx uninstall`, or deleting `$AID_HOME` and its `PATH` line). It asks first. |

Removal follows the manifest (see [Settings and manifest](/reference/settings/)). Only files that `aid add` wrote are removed. A project with no manifest exits 6.

## aid dashboard

```bash
aid dashboard start <node|python> [--remote] [--allow-writes] [--port <n>]
aid dashboard stop
```

| Option | What it does |
|---|---|
| `<node\|python>` | Required for `start`. Picks the runtime that runs the dashboard server. |
| `--port <n>` | Listens on this port. A whole number from 1024 to 65535. The default is 8787. |
| `--remote` | Also shares the dashboard over your private Tailscale network. It never opens a public port. |
| `--allow-writes` | Lets a `--remote` dashboard make changes. On your own machine, changes are always allowed, so the flag does nothing there. |

The server listens on `127.0.0.1` only. `stop` is safe to run when nothing is running, and it also removes the `--remote` sharing. Both commands work from any folder. See the [Dashboard guide](/guides/dashboard/).

## aid projects

```bash
aid projects [list] [--local|--shared] [--verbose]
aid projects add [<path>] [--local|--shared]
aid projects remove [<path>|<N>]
aid projects scan [--path <folder>|--all] [--dry-run] [--depth <n>] [--include-network] [--include-removable] [--local|--shared] [--verbose]
```

The registry is the list of projects this machine knows about. The dashboard and `aid update all` read it.

| Command | What it does |
|---|---|
| `list` (the default) | Shows each project with a number, its state, its tools and its tier. A `*` marks the current folder. |
| `add [path]` | Registers a project. If the folder is not an AID project yet, it creates a bare `.aid/` with no tools. Safe to repeat. |
| `remove [path\|N]` | Unregisters a project. It deletes no files. `N` is the row number from `list`. A path or number that is not registered exits 2. |
| `scan` | Searches for folders that contain `.aid/` and registers them. It never installs, updates or changes anything inside a project. |

A tier says where a registry entry is kept: `user` (your account) or `shared` (the whole machine, for global installs). `--local` forces `user`. `--shared` forces `shared`. `scan` uses `user` unless you pass `--shared`.

These options apply to `scan`:

| Option | What it does |
|---|---|
| (none) | Scans your home folder. |
| `--path <folder>` | Scans only that folder. It must be a folder, or the command exits 2. |
| `--all` | Scans the whole machine: fixed drives on Windows, or `/` on Linux and macOS. Cannot be combined with `--path`. |
| `--dry-run` | Shows what it would register and writes nothing. |
| `--depth <n>` | Stops `n` levels below each starting folder. Must be 0 or more. |
| `--include-network`, `--include-removable` | With `--all` on Windows, also scans network or removable drives. Without `--all` they exit 2. On Linux and macOS they do nothing. |

`scan` skips folders that are usually large or irrelevant, such as `node_modules`, `.git`, `dist` and `build`. You can add more names in `scan-config.yml` (see [Where state lives](#where-state-lives)). That file holds a `schema: 1` line and a `prune_dirs:` list. It can add names but never remove the built-in ones.

## aid chat

```bash
aid chat <verb> [options]
```

`aid chat` lets one AI coding session send messages to another. This table lists the verbs. For plain-language steps, see the [Agent chat guide](/guides/agent-chat/).

| Verb | What it does |
|---|---|
| `register --name <n> [--tool <t>]` | Gives this session a name. If you leave out `--name`, one is made up, such as `green-giraffe`. |
| `rename [--name <old>] --to <new>` | Renames the session and keeps its channel. |
| `open --name <n> --channel <c>` | Creates a channel and joins it. |
| `join --name <n> --channel <c>` | Joins an open channel. |
| `leave --name <n>` | Leaves the channel. The channel closes when the last member leaves. |
| `list --name <n>` | Lists the open channels. |
| `roster --name <n>` | Lists the agents on the hub and whether each is free. |
| `connect --name <n> --target <t>` | Pulls one named agent into your channel. |
| `send --name <n> --body <text>` | Sends a message. Optional: `--key`, `--whisper-to`, `--mention`, `--reply-to`, `--correlation-id`. |
| `inbox --name <n> [--cursor <c>]` | Reads messages after your acknowledged position. |
| `ack --name <n> --cursor <c>` | Marks messages up to a position as read. |
| `heartbeat --name <n>` | Tells the hub the session is still alive. |
| `subscribe --name <n> [--host-timeout <s>] [--follow]` | Waits for one message. The stop hook runs this. |
| `hook --tool <claude-code\|cursor> [--timeout <s>] [--check\|--install\|--uninstall] [--yes]` | Prints, checks, installs or removes the stop hook. |
| `node start [--port <n>]` | Starts the local chat node (the hub). |
| `node stop`, `node status` | Stops the node, or reports whether it is running. |

For operators, these verbs inspect and manage the hub:

| Verb | What it does |
|---|---|
| `show` | Lists machines, sessions, channels, members, unread counts and idle time. |
| `audit [--limit <n>]` | Shows what happened, never what was said. A whisper appears with its two parties and no text. |
| `evict --name <n>` | Removes a session from its channel. |
| `retention [--set <key>=<value>]` | Shows or changes how long messages are kept and similar limits. |
| `peers [--add\|--remove --machine <host[:port]>] [--discover]` | Lists, adds or removes other machines' hubs. Naming an address always works. `--discover` is best effort. |
| `reap --name <n>` (or `--name --all`, as the help prints it) | Gives up on a session that is gone. |

`--name` can be left out if the environment variable `AID_CHAT_SESSION` is set, or if the node can tell which name belongs to this folder and tool. `--cursor` on `inbox` re-reads from that point and moves no position.

The node needs Node.js 22.13.0 or later. The default port is 8812, on `127.0.0.1`. `--port 0` picks a free port.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success. "Nothing to do" is also success. |
| 1 | A runtime failure, such as a failed extract or write. |
| 2 | A usage error: unknown command, bad flag, a tool name that is not valid, a folder that does not exist, or `--from-bundle` with `--version`. Also returned while an upgrade is waiting and you run `add` or `remove`. |
| 3 | A network failure, or a dashboard server that exited at start-up. |
| 4 | The checksum of a download did not match. |
| 6 | No manifest: `update` or `remove` found nothing installed. |
| 7 | `aid status` found `.aid/` with no manifest. Also: the dashboard or chat node is missing from the install folder. |
| 8 | The dashboard or the chat node is already running. |
| 9 | The runtime you chose (`node` or `python3`) is not on your `PATH`. |
| 10 | `--remote` was requested but Tailscale sharing is not available. The local dashboard keeps running. |
| 14 | The chat node refused a valid request. The first word on stderr is the reason, such as `solo_channel`, `no_channel`, `already_in_channel` or `overflow`. |

## Environment variables

Flags win over variables.

| Variable | What it does |
|---|---|
| `AID_HOME` | Where the CLI is installed and where it keeps its state, such as the registry. The installer's default is `~/.aid` on Linux and macOS and `%LOCALAPPDATA%\aid` on Windows. |
| `AID_TARGET` | Same as `--target`. |
| `AID_TOOL` | The tool name for `add`, `update` or `remove` when you give none. |
| `AID_VERSION` | Same as `--version <v>`. |
| `AID_FORCE` | `1` or `true` works like `--force`. |
| `AID_VERBOSE` | `1` works like `--verbose`. |
| `AID_NO_PATH` | `1` skips `PATH` editing in the bootstrap installer and `update self`. |
| `AID_NO_UPDATE_CHECK` | `1` turns off the "a newer CLI is available" notice. |
| `AID_NO_MIGRATE` | `1` hides the notice that a project uses an older layout. It never allows a newer layout to be used. |
| `AID_MIGRATE_YES` | `1` accepts project migration without a prompt after `update self`. Without it, a script that has no terminal skips migration. |
| `AID_CHAT_SESSION` | The session name for `aid chat`, so you can leave out `--name`. |
| `AID_CHAT_TOOL` | The tool name `aid chat` uses to find the session registered for this folder. |
| `AID_CHAT_PORT` | The chat node port when you do not pass `--port`. Default 8812. |
| `AID_CHAT_RUNTIME` | The folder for the chat node's pid, port and log files. Default `~/.aid/chat`. |

The chat node also reads `AID_CHAT_LINK_PORT` (the port other machines use to reach it, default 8814, `off` to disable) and limit variables such as `AID_CHAT_TTL_MS`. See the [Agent chat guide](/guides/agent-chat/).

These are meant for testing and the package wrappers, so leave them alone in normal use: `AID_LIB_PATH`, `AID_LIB_BASE`, `AID_LIB_VERSION`, `AID_SUMS_URL`, `AID_INSECURE_SKIP_LIB_VERIFY`, `AID_CLI_BUNDLE_URL`, `AID_CLI_BUNDLE_BASE`, `AID_INSTALL_URL`, `AID_UPDATE_CHECK_URL`, `AID_ALLOW_ENDPOINT_OVERRIDE`, `AID_INSTALL_CHANNEL`, `AID_SKIP_SELF_INSTALL` and `AID_SHARED_STATE_HOME`.

## Where state lives

| Location | What it holds |
|---|---|
| `<project>/.aid/.aid-manifest.json` | What AID installed in this project, with file hashes. |
| `<project>/.aid/settings.yml` | The project's settings. See [Settings and manifest](/reference/settings/). |
| `$AID_HOME/registry.yml` | The list of registered projects. |
| `$AID_HOME/scan-config.yml` | Extra folder names `aid projects scan` should skip. Created on the first real scan. |
| `~/.aid/.update-check` | The cached result of the update check. It is refreshed at most once a day. |
| `~/.aid/.temp/dashboard.pid` and `dashboard.log` | The running dashboard's process record and log. |
| `~/.aid/chat/` | The chat node's pid, port, log and database. |

A global install (a CLI folder you cannot write to) keeps the registry in a machine-wide folder instead: `/var/lib/aid` on Linux and macOS, `%ProgramData%\aid` on Windows. `AID_HOME` overrides that.

On Windows, replace `~` with your user profile folder.

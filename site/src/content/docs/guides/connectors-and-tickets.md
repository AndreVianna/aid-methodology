---
title: Connectors and tickets
description: Connect AID to your issue tracker and other tools, read and file tickets from the command line, and know exactly where credentials are kept.
sidebar:
  order: 4
---

A connector is a small file that tells AID about a tool your project uses, such as Jira, GitHub or Docker. With a connector in place, AID can read a ticket for context, and you can file or update tickets without leaving your session.

## What you can do

| Command | What it does |
|---|---|
| `/aid-set-connector <tool> <type>` | Add a connector, or change an existing one |
| `/aid-unset-connector <tool>` | Remove a connector and its stored secret |
| `/aid-read-ticket [<connector>:]<id>` | Show a ticket's fields |
| `/aid-create-ticket <description>` | File a new ticket, after you confirm |
| `/aid-update-ticket <part> [<connector>:]<id> <content>` | Change a ticket's description, add a comment, or set its status, after you confirm |

All of these are optional and run on demand. None of them is a phase of the pipeline, and none needs `/aid-discover` to run first.

## Connection types

The `<type>` you give `/aid-set-connector` must be one of four values. Anything else is refused.

| Type | Who handles the connection | Credential kept by AID |
|---|---|---|
| `mcp` | Your host tool's own MCP server or plugin | None |
| `api` | A web API at the endpoint you give | Optional, see below |
| `ssh` | A host you reach with ssh keys | None |
| `cli` | A command-line tool, such as `docker` | None |

**`mcp` is the type that does the most today.** AID asks your host tool (Claude Code, for example) for the connection and uses whatever tools that connection exposes. AID does not launch the MCP server, does not wire it, and holds no credential for it.

**`api`, `ssh` and `cli` connectors are recorded but not called.** AID writes their descriptors so agents and people can discover and cite them. The ticket skills and the pipeline do not make live calls through them. That is planned work, not current behavior.

## Add a connector

1. Run the command with the tool name and the type:

   ```text
   /aid-set-connector Jira mcp
   ```

2. Answer the questions it asks. For `mcp` it only asks for a name and an optional informational endpoint. For `api` it also asks for the endpoint and the authentication method. For `ssh` and `cli` it asks for the host or command.

3. Check the result. You should see `.aid/connectors/jira.md` and an updated `.aid/connectors/INDEX.md`, and a one-line summary such as:

   ```text
   [aid-set-connector] jira: ADD (mcp); secret unchanged; INDEX regenerated.
   ```

Running the same command again for the same tool updates that connector in place, even if you give a different type. It never touches other connectors.

If the tool matches a known preset (GitHub, GitLab, Jira, Slack, Confluence, Notion, Jenkins or Docker), the questions start with sensible defaults. The type you type always wins over the preset's. Any other tool is accepted as a custom connector.

## Where connectors live

Everything is under `.aid/connectors/`:

| Path | What it is |
|---|---|
| `.aid/connectors/<tool>.md` | One descriptor per connector. The file name is the tool name in lowercase, with anything other than letters and digits turned into `-`. |
| `.aid/connectors/INDEX.md` | A generated table of all connectors. Agents read it first. |
| `.aid/connectors/.gitignore` | Contains `.secrets/` so secrets are never committed |
| `.aid/connectors/.secrets/<tool>` | The one place a stored secret can live |

A descriptor is a Markdown file with frontmatter: `name`, `connection_type`, `endpoint`, `auth_method`, `secret_reference` (only when there is one), `preset`, plus a summary and tags. It never contains a secret value.

## How secrets are handled

Only one case ever involves a secret: an `api` connector whose authentication method is `token`, `pat` or `oauth`. For every other connector, there is nothing to store.

For that case, the descriptor holds a reference, and the value lives elsewhere. You choose the form of the reference:

| Reference form | Where the value is | What AID stores |
|---|---|---|
| `file:.aid/connectors/.secrets/<tool>` (the default) | A local file | The file, readable by you only |
| `env:<VAR>` | An environment variable you manage | Only the variable name |
| `keychain:<key>` | Your system keychain | Only the key name |

With the default `file:` form:

1. AID first makes sure `.aid/connectors/.gitignore` exists and ignores `.secrets/`.
2. It asks for the value in a prompt that does not echo what you type.
3. It writes the value to `.aid/connectors/.secrets/<tool>`, owner-only.
4. It writes only the reference into the descriptor.

If the `.secrets/` folder is not git-ignored, the write is refused and nothing is saved. Names containing `/`, `\` or `..` are also refused.

To replace a stored secret without changing anything else, run `/aid-set-connector <tool> <type> --rotate-secret`. If you change a connector from `api` to `mcp`, the old secret file is deleted. `/aid-unset-connector` deletes the descriptor and its secret together, and running it for a connector that does not exist is harmless.

Two things to remember:

- The `.secrets/` folder is on your machine only. A teammate must add their own secret.
- The `env:` and `keychain:` forms store no value in the repository at all.

## Read, file and update tickets

The three ticket skills share one way of choosing a connector:

1. If you name one (`jira:PROJ-123`, or `--connector jira` when creating), that one is used. It must exist and be tagged `issue-tracker`.
2. Otherwise AID looks in `INDEX.md` for `mcp` connectors tagged `issue-tracker`. One match is used silently. Several matches make AID ask you which.
3. If none is catalogued, AID asks your host tool for its own issue-tracker MCP.
4. If there is none of those, it tells you `no issue-tracker connector found.` and stops.

The shipped Jira preset is an `api` connector, so it is not used for tickets. To use Jira tickets, register an MCP connector yourself, such as `/aid-set-connector Jira mcp`.

### Read

```text
/aid-read-ticket jira:PROJ-123
```

You should see the ticket's fields. Reading never asks for confirmation and never changes anything.

### File

```text
/aid-create-ticket --level story --parent PROJ-12 "Add pagination to the orders list"
```

You can give `--connector`, `--level epic|story|task` and `--parent`, in any order, before the description. AID maps the level to the tracker's real issue type, shows you the exact payload, and asks you to choose: file it, edit it, or cancel. Nothing is sent before you confirm.

### Update

```text
/aid-update-ticket status jira:PROJ-9 "In Progress"
```

The part must be `description` (replaces), `comment` (appends) or `status` (sets). AID shows the exact change first and waits for your confirmation. An invalid status lists the valid ones and sends nothing.

The ticket skills write no files in your repository.

## Linking work to a ticket

A work, feature, delivery or task can carry a `ticket_ref` such as `jira:PROJ-123`. When you name a ticket while describing a change, AID reads it through `/aid-read-ticket` and records the link. A unit with no `ticket_ref` of its own inherits the nearest one above it. Agents such as the developer and researcher may read a linked ticket for context. No part of the pipeline files, comments on or changes a ticket by itself. After a task finishes, `/aid-execute` only suggests that you update the ticket.

## Related pages

- [The Knowledge Base](/guides/knowledge-base/) explains how `/aid-discover` also catalogues connectors.
- [`/aid-set-connector` reference](/reference/skills/aid-set-connector/) has every option.
- [Repository structure](/reference/repository-structure/) shows where `.aid/` sits.

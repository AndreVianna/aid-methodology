# aid-installer

Install [AID](https://github.com/AndreVianna/aid-methodology) (Agentic Iterative Development)
into your repository.

`npm i -g aid-installer` (or `npx aid-installer ...`) puts an `aid` command on your PATH.
Then, inside a project:

    aid add claude-code      # add tool(s): claude-code, codex, cursor, copilot-cli, antigravity
    aid status               # show installed tools
    aid update [tool|self]   # update to latest
    aid remove [tool|self]   # remove

This package is a thin wrapper that spawns the cross-platform AID CLI (bash / PowerShell).
Requires Node >= 18 plus bash (Linux / macOS / WSL / Git Bash) or PowerShell (Windows).

Full guide: https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md

# aid-installer

Install [AID](https://github.com/AndreVianna/aid-methodology) (AI Integrated Development)
into your repository. This package always installs the matching AID release.

`npm i -g aid-installer` (or `npx aid-installer ...`) puts an `aid` command on your PATH.
Then, inside a project:

    aid add claude-code      # add tool(s): claude-code, codex, cursor, copilot-cli, antigravity
    aid status               # show installed tools
    aid update [tool|self]   # update to latest; "self" migrates existing projects to the new layout
    aid projects             # list / add / remove the projects AID tracks
    aid dashboard start node|python  # open a local web view of all tracked projects
    aid remove [tool|self]   # remove

This package is a thin wrapper that spawns the cross-platform AID CLI (bash / PowerShell).
Requires Node >= 18 plus bash (Linux / macOS / WSL / Git Bash) or PowerShell (Windows).

Full guide: https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md

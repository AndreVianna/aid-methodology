# aid-installer

Install [AID](https://aid.casuloailabs.com) (AI Integrated Development) into your repository.
This package always installs the matching AID release.

`pipx install aid-installer` (recommended) puts a persistent `aid` command on your PATH;
`pip install --user aid-installer` also works.

```bash
pipx install aid-installer
aid add claude-code     # install the AID toolset into the current repository
aid --help
```

AID is a full-lifecycle methodology for building software with AI agents — a phased
skill + specialized-agent pipeline over a per-project Knowledge Base, rendered from a
single source into host-tool install trees for Claude Code, Codex, Cursor, GitHub
Copilot CLI, and Antigravity.

- Documentation: <https://aid.casuloailabs.com>
- Source & issues: <https://github.com/AndreVianna/aid-methodology>

Licensed under the MIT License.

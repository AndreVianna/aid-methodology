---
kb-category: primary
source: hand-authored
intent: |
  Documents the AID content-isolation cornerstone: the two content classes
  (AID-own vs. tool-native), the aid/-nest rule for AID-own folders, the
  aid- prefix rule for tool-native AID files, the prune basis (aid- prefix
  + new-manifest membership), and the root-agent AID:BEGIN/AID:END marker
  boundary. Read this when authoring or reviewing any AID-delivered file to
  confirm it is correctly isolated from user content.
contracts:
  - "Every AID-delivered file is either nested under an aid/ subtree or carries the aid- prefix; nothing AID-owned is un-prefixed outside an aid/ subtree"
  - "AID-own folders (scripts/, templates/, recipes/) nest under <assets-root>/aid/{scripts,templates,recipes} in every profile"
  - "Tool-native AID files inside agents/, skills/, rules/ carry the aid- prefix"
  - "Orphan prune basis is aid- prefix + new-manifest membership — NOT old-manifest diff"
  - "Root-agent AID-managed content is fenced by <!-- AID:BEGIN --> / <!-- AID:END --> markers; updates replace only the marked region in place"
changelog:
  - 2026-06-18: Created — work-003-content-isolation task-009
---

# AID Content Isolation Cornerstone

> Standing convention — applies to every AID-delivered file, in every
> profile, in every install channel. Enforced by the reviewer as a standing
> check item.

## Invariant

**Every AID-delivered file is either nested under an `aid/` subtree OR
carries the `aid-` prefix. Nothing AID-owned is un-prefixed outside an
`aid/` subtree.**

This invariant lets install/update prune stale AID files without touching
user content, because the two populations are mutually exclusive by path.

---

## Content Classes

AID-delivered content falls into three classes based on where the host tool
requires the path to live:

| Class | Definition | Isolation mechanism |
|-------|------------|---------------------|
| **AID-own folders** | Generic names AID invented; the host tool does NOT require the path: `scripts/`, `templates/`, `recipes/` | Nest under `<assets-root>/aid/` |
| **Tool-native folders** | The host tool requires the exact path: `agents/`, `skills/`, `rules/` | AID files inside carry the `aid-` prefix |
| **Root-agent files** | `CLAUDE.md` / `AGENTS.md` — shared with user-owned sections | AID content fenced by `<!-- AID:BEGIN -->` / `<!-- AID:END -->` markers |

---

## Rule 1 — The `aid/` Nest Rule (AID-own folders)

`scripts/`, `templates/`, and `recipes/` are AID-invented names — the host
tool has no requirement for them. They nest under an `aid/` subtree inside
the profile's assets root:

| Profile | Assets root | AID-own install path |
|---------|-------------|----------------------|
| claude-code | `.claude/` | `.claude/aid/{scripts,templates,recipes}` |
| codex | `.agents/` | `.agents/aid/{scripts,templates,recipes}` (NOT under `.codex/`) |
| cursor | `.cursor/` | `.cursor/aid/{scripts,templates,recipes}` |
| copilot-cli | `.github/` | `.github/aid/{scripts,templates,recipes}` |
| antigravity | `.agent/` | `.agent/aid/{scripts,templates,recipes}` |

**Scope notes:**

- **`.github/` (copilot-cli — R1):** the `.github` root is shared GitHub
  user content; AID-own content lands under `.github/aid/` ONLY;
  `.github/{agents,skills}` are tool-native; nothing AID-owned is placed
  at the `.github` root level.
- **Codex split (R6):** the nest applies to `.agents/`; `.codex/` ships
  only `agents/` (no `aid/` subtree under `.codex/`).

The nest is implemented at the single generator chokepoint
(`render_lib.py rewrite_install_paths`) plus the three dst builders
(`render_canonical_scripts`, `render_templates`, `render_recipes`).
The chokepoint constant, the builders, and the toml `*_dir` keys stay
lockstep (SD-1 in SPEC.md).

---

## Rule 2 — The `aid-` Prefix Rule (tool-native AID files)

Tool-native directories (`agents/`, `skills/`, `rules/`) keep their exact
paths because the host tool requires them. Every AID-delivered file or
directory INSIDE a tool-native directory carries the `aid-` prefix:

- Agent files: `agents/aid-architect.md`, `agents/aid-developer.md`, …
- Skill dirs: `skills/aid-config/`, `skills/aid-discover/`, …
- Skills README: `skills/aid-README.md` (NOT `skills/README.md` — R2)
- Rules: `rules/aid-*.mdc`

User content in the same directory does NOT carry the `aid-` prefix. The
prefix is the exclusive signal that identifies an AID-managed entry.

---

## Rule 3 — The Prune Basis

Orphan pruning removes stale AID files after an install/update without
touching user content. The prune basis is:

> **`aid-` prefix + new-manifest membership** — NOT old-manifest diff.

An entry is a prune candidate if it carries the `aid-` prefix (for
tool-native dirs) or lives under the `aid/` subtree (for AID-own dirs).
It is removed when its path is NOT in the new manifest's path set.

Prune semantics in detail:

- **(a) `aid-`-prefixed FILE** inside a tool-native dir (e.g.
  `agents/aid-old.md`): removed when its path is absent from the new
  manifest.
- **(b) `aid-`-prefixed DIRECTORY** inside a tool-native dir (e.g.
  `skills/aid-old-skill/`): removed when NONE of its files appear in the
  new manifest. A directory whose files ARE in the manifest is kept.
- **(c) FILE under `aid/` subtree**: removed when its path is absent from
  the new manifest; now-empty `aid/` subdirs are pruned.

**Non-`aid-`-prefixed entries** (user content) are NEVER touched, even
inside a tool-native directory.

**Scope (copilot-cli — R1):** the prune walks only `.github/{agents,skills,aid}`;
it never deletes anything at the `.github` root or outside those scoped
directories.

Both the bash (`install_tool` / `lib/aid-install-core.sh`) and PowerShell
(`Install-Tool` / `lib/AidInstallCore.psm1`) implementations enforce
byte-equivalent prune semantics.

---

## Rule 4 — Root-Agent Marker Boundary

`CLAUDE.md` and `AGENTS.md` are shared between AID-managed sections and
user-authored sections. The AID-managed region is fenced by:

```
<!-- AID:BEGIN -->
…AID-managed content…
<!-- AID:END -->
```

The AID-managed region covers (in order): `## Tracking discipline (IMPERATIVE)`,
`## Knowledge Base`, `## Review output format`, `## Permissions`. The
user-authored `## Project` / `## Project Overview` section lives OUTSIDE
the markers.

The installer updates ONLY the region between the markers (in place,
losslessly). No `.aid-new` backup/sidecar file is ever written.

**Migration when markers are absent:**

- Destination matches the AID-recorded sha → clean full rewrite to the
  marked source.
- Destination does NOT match → excise the known AID-managed sections and
  re-insert them inside markers in place, preserving user content. No
  backup is written.

---

## Reviewer Standing Check

The reviewer applies this as a standing criterion on every change that
adds or moves an AID-delivered file:

1. Is the file nested under an `aid/` subtree, OR does it carry the
   `aid-` prefix? → If neither, flag as isolation violation.
2. Is the file inside a tool-native directory without the `aid-` prefix?
   → Flag as isolation violation.
3. Does any new AID content appear at the `.github` root level
   (copilot-cli) or under `.codex/aid/` (codex)? → Flag as scoping
   violation.
4. Does the prune logic use the correct basis (new-manifest membership,
   not old-manifest diff)? → Flag any old-manifest-diff approach.
5. Does any root-agent update write a `.aid-new` sidecar? → Flag as
   region-update violation.

**Citation:** cite this document (`content-isolation.md`) when raising
any of the above issues in a review ledger.

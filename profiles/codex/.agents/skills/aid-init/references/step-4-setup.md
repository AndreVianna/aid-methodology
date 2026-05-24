# State: SETUP

Configure `AGENTS.md`, `.gitignore`, and install skill templates.

> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [✓ COLLECT ] → [✓ SCAFFOLD ] → [✓ META-DOCS ] → [● SETUP ] → [ DONE ]
> ```

Check if `AGENTS.md` exists in the project root.

- **If it doesn't exist:** Create it with the AID template:

```markdown
# {Project Name}

<!-- AID-DISCOVER project-description -->
{One-line description from Q3}
<!-- /AID-DISCOVER -->

## Project Overview
<!-- AID-DISCOVER project-overview -->
(pending discovery)
<!-- /AID-DISCOVER -->

## Build & Test
<!-- AID-DISCOVER build-test -->
(pending discovery)
<!-- /AID-DISCOVER -->

## Code Conventions
<!-- AID-DISCOVER code-conventions -->
(pending discovery)
<!-- /AID-DISCOVER -->

## Architecture
<!-- AID-DISCOVER architecture -->
(pending discovery)
<!-- /AID-DISCOVER -->

## AID Workspace

The `.aid/` directory contains the Knowledge Base and work artifacts.
Read `.aid/knowledge/INDEX.md` to find what you need.
```

- **If it already exists:** Do NOT overwrite. Check for `<!-- AID-DISCOVER -->` placeholders.
  If none exist, append an "AID Workspace" section at the end pointing to
  `.aid/knowledge/INDEX.md`.
  Print: `[Init] AGENTS.md exists — appended workspace reference.`

### .gitignore

What happens here depends on the user's answer to **Q7**:

- **If the user chose [1] — commit `.aid/`:** Do NOT add a `.aid/` entry,
  but ALWAYS add `.aid/.heartbeat/` (heartbeat files are ephemeral runtime
  artifacts that should never be committed, even if `.aid/` is tracked).
  If `.gitignore` exists and doesn't contain `.aid/.heartbeat/`, append it.
  If no `.gitignore` exists, create one with just `.aid/.heartbeat/`.
  Print: `[Init] .aid/ will be tracked by Git (your Q7 choice); .aid/.heartbeat/ excluded.`

- **If the user chose [2] — keep `.aid/` local:**
  - If `.gitignore` doesn't exist: create it with `.aid/` as the only entry.
  - If it already exists: check whether `.aid/` is already listed; if not,
    append `.aid/` on a new line at the end of the file.
  - Print: `[Init] .gitignore updated — added .aid/ entry (workspace stays local).`

---

## Step 4b: Install Skill Templates

Some skills need template assets installed in the project at runtime (not just
scaffolded once). Currently:

### `knowledge-summary/` for `/aid-summarize`

If the source tree exists at `../../templates/knowledge-summary/` (relative to this
skill — i.e., `.claude/templates/knowledge-summary/`), copy the entire tree into the
project at `.aid/templates/knowledge-summary/`:

```bash
SRC="$(dirname "$0")/../../templates/knowledge-summary"
DST=".aid/templates/knowledge-summary"
if [ -d "$SRC" ]; then
    mkdir -p "$DST"
    cp -R "$SRC/." "$DST/"
    chmod +x "$DST"/scripts/*.sh 2>/dev/null || true
    echo "[Init] Installed knowledge-summary templates → $DST"
else
    echo "[Init] knowledge-summary templates not found at $SRC — skipping."
    echo "       /aid-summarize will not be available until you install them."
fi
```

The `knowledge-summary/` tree contains the CSS, JS, HTML skeleton, design tokens,
mermaid examples, accessibility checklist, grading rubric, profile section
templates, and validation scripts that `/aid-summarize` uses to build the visual
HTML summary. The skill is the orchestrator; these templates are the assets.

If a project doesn't intend to use `/aid-summarize`, this step is harmless — the
templates just sit unused.

**Advance:** Next state is `DONE` — when this state's work completes, router prints `Next: [State: DONE] — run /aid-init again` and exits.

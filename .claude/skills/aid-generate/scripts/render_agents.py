#!/usr/bin/env python3
# render_agents.py — AID canonical-generator agent renderer
#
# Purpose:
#   Render canonical/agents/<name>/AGENT.md into per-tool install trees using the
#   per-tool profile. Supports both markdown (Claude Code, Cursor) and
#   TOML (Codex) output formats.
#
# Usage:
#   python render_agents.py --canonical-root <repo-root> --profile <path/to/profile.toml> --output-root <dest>
#   python render_agents.py --self-test
#
# Requirements: Python 3.11+
from __future__ import annotations

import argparse
import json
import re
import sys
import tomllib
from pathlib import Path
from typing import Any

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import load_profile, validate, Profile, ModelTierSimple, ModelTierDetailed  # noqa: E402
from render_lib import (  # noqa: E402
    read_canonical_file,
    write_output_file,
    substitute_filenames,
    rewrite_install_paths,
    sha256_hex,
    EmissionManifest,
)


# ---------------------------------------------------------------------------
# YAML-lite frontmatter parser (no external deps)
# ---------------------------------------------------------------------------

def _parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    """
    Parse YAML frontmatter delimited by ``---`` lines.

    Returns
    -------
    tuple[dict[str, Any], str]
        ``(frontmatter_dict, body_text)`` where *body_text* is the content
        after the closing ``---``.  Returns ``({}, text)`` if no frontmatter found.
    """
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return {}, text

    end_idx = None
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end_idx = i
            break

    if end_idx is None:
        return {}, text

    fm_lines = lines[1:end_idx]
    body = "".join(lines[end_idx + 1:])

    # Simple YAML key:value parser (no anchors, no nested maps needed)
    fm: dict[str, Any] = {}
    i = 0
    while i < len(fm_lines):
        raw = fm_lines[i].rstrip("\n")
        if not raw.strip() or raw.strip().startswith("#"):
            i += 1
            continue
        if ":" in raw:
            key, _, val = raw.partition(":")
            key = key.strip()
            val = val.strip()
            if val == ">":
                # Folded block scalar — collect continuation lines
                block_lines = []
                i += 1
                while i < len(fm_lines):
                    cont = fm_lines[i]
                    if cont and cont[0] in (" ", "\t"):
                        block_lines.append(cont.strip())
                        i += 1
                    else:
                        break
                fm[key] = " ".join(block_lines)
                continue
            else:
                # Strip inline quotes
                if (val.startswith('"') and val.endswith('"')) or \
                   (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                fm[key] = val
        i += 1

    return fm, body


def _build_frontmatter_md(fields: dict[str, Any]) -> str:
    """
    Serialize a flat dict as YAML frontmatter block (``---`` delimited).
    Description uses a single quoted string if it contains special chars,
    otherwise bare string.
    """
    lines = ["---"]
    for key, val in fields.items():
        if isinstance(val, bool):
            lines.append(f"{key}: {'true' if val else 'false'}")
        elif isinstance(val, str):
            # Use quoted form if value contains YAML-special characters
            if any(c in val for c in (':', '"', "'", '{', '}', '[', ']', '#', '&', '*', '!', '|', '>', '%')):
                # Escape inner double-quotes and wrap
                escaped = val.replace('"', '\\"')
                lines.append(f'{key}: "{escaped}"')
            else:
                lines.append(f"{key}: {val}")
        else:
            lines.append(f"{key}: {val}")
    lines.append("---")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Constants for _yaml_scalar quoting decisions (module-level for efficiency)
# ---------------------------------------------------------------------------

# Characters that make a YAML plain scalar unsafe regardless of position.
# Kept as the original indicator set so existing emitted output stays byte-identical.
_YAML_UNSAFE_ANYWHERE: frozenset[str] = frozenset(
    [':', '"', "'", '{', '}', '[', ']', '#', '&', '*', '!', '|', '>', '%']
)

# Characters that are only unsafe as the FIRST character of a plain scalar.
# '@' and '`' are reserved/forbidden as YAML 1.1 first chars; '-' and '?' start
# sequences/mapping-keys when followed by whitespace (triggering parse errors).
_YAML_UNSAFE_FIRST: frozenset[str] = frozenset(['-', '?', '@', '`'])

# Bare words that YAML 1.1 resolves to non-string types (null, bool).
_YAML_BOOL_NULL_WORDS: frozenset[str] = frozenset([
    'null', 'Null', 'NULL', '~',
    'true', 'True', 'TRUE',
    'false', 'False', 'FALSE',
    'yes', 'Yes', 'YES',
    'no', 'No', 'NO',
    'on', 'On', 'ON',
    'off', 'Off', 'OFF',
])

# Pattern matching int / float / hex / octal / infinity / NaN literals that
# YAML 1.1 would coerce to numeric types.
_YAML_NUMBER_RE: re.Pattern[str] = re.compile(
    r'^[-+]?(\d+\.?\d*|\d*\.\d+)([eE][-+]?\d+)?$'
    r'|^0x[0-9a-fA-F]+$'
    r'|^0o[0-7]+$'
    r'|^\.inf$|^-\.inf$|^\.nan$',
    re.IGNORECASE,
)


def _yaml_scalar(val: str) -> str:
    """
    Serialize a string scalar for Copilot-safe YAML frontmatter.

    Returns the value in plain (unquoted) form only when it is unambiguously
    safe as a YAML 1.1 plain scalar.  Otherwise double-quotes the value and
    escapes backslashes, double-quotes, and ASCII control characters.

    A value is considered unsafe (and therefore quoted) if any of the following
    hold:

    * The string is empty.
    * It has leading or trailing whitespace.
    * It contains any YAML indicator/special character that is problematic
      anywhere in a plain scalar: ``:  "  '  {  }  [  ]  #  &  *  !  |  >  %``
    * Its first character is one of the chars unsafe only at position 0:
      ``-  ?  @  ` ``
    * It contains ASCII control characters (U+0000–U+001F or U+007F), including
      tab and newline.
    * It is a bare YAML-resolved word (``null``, ``true``, ``false``, ``yes``,
      ``no``, ``on``, ``off``, and their case variants, plus ``~``).
    * It looks like a YAML numeric literal (integer, float, hex, octal,
      ``.inf``, ``-.inf``, ``.nan``).
    * It ends with ``:`` (trailing colon is a mapping-key indicator).

    The conservative "quote unless clearly plain-safe" approach means new
    description edge-cases never silently produce invalid or mistyped YAML.
    The renderer stays stdlib-only (no ``import yaml``).
    """
    needs_quote = (
        not val
        or val != val.strip()
        or any(c in val for c in _YAML_UNSAFE_ANYWHERE)
        or val[0] in _YAML_UNSAFE_FIRST
        or any(ord(c) < 0x20 or ord(c) == 0x7F for c in val)
        or val in _YAML_BOOL_NULL_WORDS
        or bool(_YAML_NUMBER_RE.match(val))
        or val.endswith(':')
    )
    if needs_quote:
        escaped = val.replace('\\', '\\\\').replace('"', '\\"')
        escaped = escaped.replace('\t', '\\t').replace('\n', '\\n').replace('\r', '\\r')
        return f'"{escaped}"'
    return val


def _build_frontmatter_md_copilot(fields: dict[str, Any]) -> str:
    """
    Serialize a Copilot ``.agent.md`` frontmatter block (``---`` delimited).

    Differences from ``_build_frontmatter_md``:
    - A ``list`` value for a key is serialized as a YAML block sequence
      (one ``- item`` line per element).  An empty list emits ``key: []``
      (flow form; no dangling key without a value).
    - Scalar quoting uses ``_yaml_scalar``, identical to the existing str-branch
      quoting rules.
    - Bool values use the same ``true``/``false`` lowercased form.

    This function is introduced by task-006 (feature-002 E1) as the format-branch
    serializer for ``"copilot-agent"``-format agents.  A future agent-format value
    (feature-003 ``"antigravity-rule"``) reuses the same per-format-branch
    mechanism (add a new format branch in ``_render_agent_for_profile`` with its
    own serializer).

    Parameters
    ----------
    fields : dict[str, Any]
        Ordered mapping of frontmatter key → value.  Keys are emitted in
        iteration order (Python 3.7+ dict ordering).

    Returns
    -------
    str
        ``---`` … ``---`` delimited YAML frontmatter block, LF-terminated.
    """
    lines = ["---"]
    for key, val in fields.items():
        if isinstance(val, bool):
            lines.append(f"{key}: {'true' if val else 'false'}")
        elif isinstance(val, list):
            if not val:
                lines.append(f"{key}: []")
            else:
                lines.append(f"{key}:")
                for item in val:
                    lines.append(f"  - {_yaml_scalar(str(item))}")
        elif isinstance(val, str):
            lines.append(f"{key}: {_yaml_scalar(val)}")
        else:
            lines.append(f"{key}: {val}")
    lines.append("---")
    return "\n".join(lines) + "\n"


def _build_frontmatter_md_antigravity(fields: dict[str, Any]) -> str:
    """
    Serialize an Antigravity ``.agent/rules/*.md`` frontmatter block
    (``---`` delimited).

    Antigravity rule frontmatter shape (SPEC §"Renderer Increment" + §B.1 +
    provider-mapping.md Q-I / Q-D):

    * ``trigger: always_on``  — for always-loaded sub-agent personas (all 22
      AID sub-agents; sub-agent personas map to ``always_on`` per SPEC).
    * ``trigger: glob``       — for glob-triggered rules (with ``globs:`` key).
    * ``trigger: model_decision`` — for model-decision rules.
    * ``trigger: manual``     — for manual rules.
    * ``description:``        — from the canonical AGENT ``description`` field.
    * ``globs:``              — only present when trigger is ``glob``; emitted as
      a YAML block sequence (one ``- item`` per glob) or ``[]`` for empty.

    Scalar quoting uses ``_yaml_scalar``, identical to the copilot-agent branch.
    List values use the same YAML block-sequence form as ``_build_frontmatter_md_copilot``.
    This function is introduced by task-012 (feature-003-antigravity / delivery-003)
    as the format-branch serializer for ``"antigravity-rule"``-format agents.
    It does NOT reuse E1's Copilot output shape; it produces a different
    (rule-shaped) frontmatter.

    Parameters
    ----------
    fields : dict[str, Any]
        Ordered mapping of frontmatter key → value.  Keys are emitted in
        iteration order (Python 3.7+ dict ordering).

    Returns
    -------
    str
        ``---`` … ``---`` delimited YAML frontmatter block, LF-terminated.
    """
    lines = ["---"]
    for key, val in fields.items():
        if isinstance(val, bool):
            lines.append(f"{key}: {'true' if val else 'false'}")
        elif isinstance(val, list):
            if not val:
                lines.append(f"{key}: []")
            else:
                lines.append(f"{key}:")
                for item in val:
                    lines.append(f"  - {_yaml_scalar(str(item))}")
        elif isinstance(val, str):
            lines.append(f"{key}: {_yaml_scalar(val)}")
        else:
            lines.append(f"{key}: {val}")
    lines.append("---")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Model tier resolution
# ---------------------------------------------------------------------------

def _resolve_model(profile: Profile, tier: str) -> str:
    """Return the model string for a given tier alias."""
    tier_val = profile.model_tiers.get(tier)
    if tier_val is None:
        raise ValueError(f"Unknown tier {tier!r} in profile {profile.name!r}")
    return tier_val.model


def _resolve_reasoning_effort(profile: Profile, tier: str) -> str:
    """Return the reasoning_effort for a given tier alias (Codex only)."""
    tier_val = profile.model_tiers.get(tier)
    if tier_val is None:
        raise ValueError(f"Unknown tier {tier!r} in profile {profile.name!r}")
    if not isinstance(tier_val, ModelTierDetailed):
        raise ValueError(
            f"Profile {profile.name!r} tier {tier!r} has no reasoning_effort "
            f"(not a ModelTierDetailed)"
        )
    return tier_val.reasoning_effort


# ---------------------------------------------------------------------------
# Tool name remapping
# ---------------------------------------------------------------------------

def _remap_tools(tools_str: str, tool_names: dict[str, str]) -> str:
    """
    Apply tool_names remapping to a comma-separated tools string.

    Only entries present as keys in *tool_names* are substituted;
    all others pass through unchanged.

    Examples
    --------
    >>> _remap_tools("Read, Glob, Grep, Bash, Write", {"Bash": "Terminal"})
    'Read, Glob, Grep, Terminal, Write'
    """
    if not tool_names:
        return tools_str
    parts = [t.strip() for t in tools_str.split(",")]
    remapped = [tool_names.get(t, t) for t in parts]
    return ", ".join(remapped)


def _remap_tools_list(tools_str: str, tool_names: dict[str, str]) -> list[str]:
    """
    Apply tool_names remapping to a comma-separated tools string, returning a list.

    Like _remap_tools but returns a list of individual tool name strings rather
    than a comma-joined string.  Used by the copilot-agent emitter to build a
    list value for YAML block-sequence serialization.

    Examples
    --------
    >>> _remap_tools_list("Read, Glob, Bash, Write", {"Bash": "shell"})
    ['Read', 'Glob', 'shell', 'Write']
    >>> _remap_tools_list("", {})
    []
    """
    if not tools_str.strip():
        return []
    parts = [t.strip() for t in tools_str.split(",") if t.strip()]
    if not tool_names:
        return parts
    return [tool_names.get(t, t) for t in parts]


# ---------------------------------------------------------------------------
# TOML value serializer (for Codex agent TOML output)
# ---------------------------------------------------------------------------

def _toml_str(value: str) -> str:
    """Return a TOML-quoted string literal."""
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def _render_codex_toml(
    name: str,
    description: str,
    model: str,
    reasoning_effort: str,
    body: str,
) -> str:
    """
    Render a Codex agent TOML file.

    The body becomes a triple-quoted TOML multi-line string
    assigned to ``developer_instructions``.
    """
    # Strip leading newline from body (comes from the blank line after --- in the canonical)
    # and trailing whitespace. The TOML multi-line string starts immediately after """\n.
    body_content = body.lstrip("\n").rstrip("\n")
    lines = [
        f"name = {_toml_str(name)}",
        f"description = {_toml_str(description)}",
        f"model = {_toml_str(model)}",
        f"model_reasoning_effort = {_toml_str(reasoning_effort)}",
        f'developer_instructions = """',
        body_content,
        '"""',
        "",  # trailing newline
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Per-agent render
# ---------------------------------------------------------------------------

def _render_agent_for_profile(
    canonical_path: Path,
    profile: Profile,
    manifest: EmissionManifest,
    output_base: Path,
    canonical_root: Path,
) -> Path:
    """
    Render one canonical agent file for the given profile.

    Returns the output path.
    """
    raw_text = read_canonical_file(canonical_path)
    fm, body = _parse_frontmatter(raw_text)

    agent_name = fm.get("name", canonical_path.parent.name)
    description = fm.get("description", "")
    tier = fm.get("tier", "medium")
    tools_str = fm.get("tools", "")
    permission_mode = fm.get("permissionMode")
    background = fm.get("background")

    # Apply the install-path rewrite to the frontmatter description too.
    # (round-4 NEW-HIGH-1 fix.) The description field flows through a separate
    # code path (re-emitted via _build_frontmatter_md / _render_codex_toml) that
    # the body rewrite below does not touch. Any canonical/{scripts,templates,
    # skills,agents,rules,recipes}/ reference inside a description must be
    # rewritten to the profile's install root, exactly as in the body.
    description = substitute_filenames(description, profile.filename_map)
    description = rewrite_install_paths(description, profile.layout.install_root())

    # Apply filename substitution to body, then install-path rewrite.
    # Policy: every text-emitting renderer (render_skills, render_templates,
    # render_canonical_scripts, render_agents, render_recipes) MUST apply BOTH
    # substitute_filenames AND rewrite_install_paths in that order. Any
    # canonical/{scripts,templates,skills,agents,rules,recipes}/ reference in
    # a body becomes <install_root>/<dir>/ in the rendered output so adopter
    # projects (which have no canonical/ at root) can resolve the paths.
    # Adding a new renderer? Apply both. (See render_lib.py rewrite_install_paths
    # docstring.)
    body = substitute_filenames(body, profile.filename_map)
    body = rewrite_install_paths(body, profile.layout.install_root())

    if profile.agent.format == "toml":
        # Codex: emit TOML file
        model = _resolve_model(profile, tier)
        reasoning_effort = _resolve_reasoning_effort(profile, tier)
        content = _render_codex_toml(
            name=agent_name,
            description=description,
            model=model,
            reasoning_effort=reasoning_effort,
            body=body,
        )
        out_name = f"{agent_name}.toml"
        agents_root = Path(profile.layout.agents_root)  # type: ignore[arg-type]
        out_path = output_base / agents_root / profile.layout.agents_dir / out_name
    elif profile.agent.format == "copilot-agent":
        # GitHub Copilot CLI: emit .agent.md with Copilot YAML frontmatter (E1, task-006).
        #
        # Frontmatter field set: name, description, tools, model (in that order) per FR1 Q-A.
        # - name / description: pass-through (with substitute_filenames + rewrite_install_paths
        #   already applied to description above, same as the markdown/toml branches).
        # - tools: remapped via [tool_names] (Bash→shell per Q-F), emitted as a YAML sequence.
        # - model: resolved via _resolve_model(tier) from [model_tiers].
        # Optional Copilot fields (target / user-invocable / disable-model-invocation /
        # mcp-servers / metadata) are omitted — AID has no per-agent source for them and
        # the agent defaults are correct (FR1 Q-A).  No MCP field is emitted (E3 dropped, Q-B).
        #
        # The .agent.md suffix is a property of this branch — NOT a data-driven agent_suffix key
        # (confirmed: no such key exists in the Profile schema, per task-005 / SPEC §E1).
        model = _resolve_model(profile, tier)
        remapped_tools_list = _remap_tools_list(tools_str, profile.tool_names)

        # Build the ordered frontmatter dict: exactly name, description, tools, model.
        copilot_fm: dict[str, Any] = {
            "name": agent_name,
            "description": description,
            "tools": remapped_tools_list,
            "model": model,
        }

        fm_block = _build_frontmatter_md_copilot(copilot_fm)
        content = fm_block + body

        # Suffix is .agent.md — a property of the copilot-agent format branch.
        out_name = f"{agent_name}.agent.md"
        output_root = Path(profile.layout.output_root)  # type: ignore[arg-type]
        out_path = output_base / output_root / profile.layout.agents_dir / out_name
    elif profile.agent.format == "antigravity-rule":
        # Google Antigravity: emit .agent/rules/<name>.md with rule-shaped frontmatter
        # (task-012 / feature-003-antigravity / delivery-003).
        #
        # Reshape: the canonical AGENT frontmatter (name/description/tools/model) is
        # dropped/replaced by rule frontmatter (trigger/description[/globs]) per:
        #   - SPEC §"Renderer Increment": "drops/replaces AGENT name/description/tools/model
        #     set with rule frontmatter (trigger:/description/globs)"
        #   - SPEC §B.1 + provider-mapping.md Q-D: "Antigravity rules carry no tools/model
        #     frontmatter"
        #   - SPEC §"Renderer Increment": "AID's always-loaded sub-agent personas map to
        #     trigger: always_on"
        #
        # Field mapping (source: SPEC §"Renderer Increment" / provider-mapping.md Q-D):
        #   trigger:     → always "always_on" (all 22 AID sub-agents are always-loaded
        #                  personas; SPEC: "AID's always-loaded sub-agent personas map to
        #                  trigger: always_on")
        #   description: → canonical AGENT description (pass-through, already rewritten above)
        #   globs:       → NOT emitted for always_on triggers (no globs needed / present)
        #
        # tools / model are intentionally DROPPED — Antigravity rules have no tools/model
        # frontmatter (§B.1). name is also dropped (not a rule frontmatter key).
        #
        # Output suffix is .md (Q-I: Antigravity uses .md, not .mdc or .agent.md).
        # Output path is under agents_dir (= "rules" in antigravity.toml → .agent/rules/).
        # This is NOT a reuse of E1's copilot-agent output — it is a DIFFERENT, rule-shaped
        # frontmatter on top of E1's format-branch dispatch machinery.

        # Rule frontmatter dict: trigger + description only (always_on → no globs needed).
        antigravity_fm: dict[str, Any] = {
            "trigger": "always_on",
            "description": description,
        }

        fm_block = _build_frontmatter_md_antigravity(antigravity_fm)
        content = fm_block + body

        # Suffix is .md — a property of the antigravity-rule format branch (Q-I).
        out_name = f"{agent_name}.md"
        output_root = Path(profile.layout.output_root)  # type: ignore[arg-type]
        out_path = output_base / output_root / profile.layout.agents_dir / out_name
    else:
        # Markdown (Claude Code or Cursor)
        model = _resolve_model(profile, tier)
        remapped_tools = _remap_tools(tools_str, profile.tool_names)

        # Build ordered frontmatter fields
        new_fm: dict[str, Any] = {
            "name": agent_name,
            "description": description,
            "tools": remapped_tools,
            "model": model,
        }
        # Emit optional fields only when present in canonical
        if permission_mode is not None:
            new_fm["permissionMode"] = permission_mode
        if background is not None:
            # Convert string "true"/"false" to Python bool if needed
            if isinstance(background, str):
                background = background.lower() == "true"
            new_fm["background"] = background

        fm_block = _build_frontmatter_md(new_fm)
        content = fm_block + body

        out_name = f"{agent_name}.md"
        output_root = Path(profile.layout.output_root)  # type: ignore[arg-type]
        out_path = output_base / output_root / profile.layout.agents_dir / out_name

    # src is relative to canonical_root
    src = str(canonical_path.relative_to(canonical_root)).replace("\\", "/")
    # dst is relative to the manifest's common_parent directory
    common_parent = Path(profile.layout.common_parent())
    dst = str(out_path.relative_to(output_base / common_parent)).replace("\\", "/")

    encoded = content.encode("utf-8")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(encoded)

    manifest.add(
        profile=profile.name,
        src=src,
        dst=dst,
        sha256=sha256_hex(encoded),
    )

    return out_path


# ---------------------------------------------------------------------------
# Top-level renderer
# ---------------------------------------------------------------------------

def render_agents(
    canonical_root: str | Path,
    profile: Profile,
    manifest: EmissionManifest,
    output_base: str | Path,
) -> list[Path]:
    """
    Render all canonical agents for the given profile.

    Parameters
    ----------
    canonical_root : str | Path
        Root of the repository (contains ``canonical/agents/``).
    profile : Profile
        Loaded and validated profile.
    manifest : EmissionManifest
        Manifest to record emitted files into.
    output_base : str | Path
        Destination root (usually same as canonical_root for in-tree generation,
        or a temp dir for determinism testing).

    Returns
    -------
    list[Path]
        Sorted list of output paths.
    """
    canonical_root = Path(canonical_root)
    output_base = Path(output_base)
    agents_dir = canonical_root / "canonical" / "agents"

    agent_files = sorted(agents_dir.glob("*/AGENT.md"))
    if not agent_files:
        raise FileNotFoundError(f"No agent files found in {agents_dir}")

    output_paths: list[Path] = []
    for agent_file in agent_files:
        out_path = _render_agent_for_profile(
            canonical_path=agent_file,
            profile=profile,
            manifest=manifest,
            output_base=output_base,
            canonical_root=canonical_root,
        )
        output_paths.append(out_path)

    return output_paths


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="render_agents.py",
        description=(
            "Render canonical/agents/ into per-tool install trees. "
            "Supports markdown (Claude Code, Cursor) and TOML (Codex) output."
        ),
    )
    parser.add_argument(
        "--canonical-root",
        required=True,
        metavar="PATH",
        help="Repo root (parent of canonical/, profiles/, claude-code/, etc.)",
    )
    parser.add_argument(
        "--profile",
        metavar="PATH",
        help="Path to the profile TOML (e.g. profiles/claude-code.toml); required unless --self-test",
    )
    parser.add_argument(
        "--output-root",
        metavar="PATH",
        help="Destination root for rendered output; required unless --self-test",
    )
    parser.add_argument(
        "--manifest-path",
        metavar="PATH",
        help="Where to write the emission manifest JSONL (optional; skipped if not given)",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run built-in determinism self-test and exit (requires --canonical-root only)",
    )
    args = parser.parse_args()

    if args.self_test:
        return _self_test(args.canonical_root)

    if not args.profile or not args.output_root:
        parser.error("--profile and --output-root are required unless --self-test is given")

    try:
        profile = load_profile(args.profile)
    except Exception as exc:
        print(f"ERROR loading profile: {exc}", file=sys.stderr)
        return 1

    errors = validate(profile)
    if errors:
        for err in errors:
            print(f"ERROR: {err}", file=sys.stderr)
        return 1

    manifest = EmissionManifest(profile_name=profile.name)

    try:
        paths = render_agents(
            canonical_root=args.canonical_root,
            profile=profile,
            manifest=manifest,
            output_base=args.output_root,
        )
    except Exception as exc:
        print(f"ERROR during rendering: {exc}", file=sys.stderr)
        return 1

    print(f"Rendered {len(paths)} agents for profile {profile.name!r}")
    for p in paths:
        print(f"  {p}")

    if args.manifest_path:
        manifest.write(args.manifest_path)
        print(f"Manifest written to {args.manifest_path}")

    return 0


def _self_test(canonical_root_arg: str) -> int:
    """
    Determinism self-test: render twice into separate scratch dirs,
    compare byte-for-byte.
    """
    import tempfile
    import os

    if not canonical_root_arg:
        print("ERROR: --canonical-root required for --self-test", file=sys.stderr)
        return 1

    canonical_root = Path(canonical_root_arg)
    profiles_dir = canonical_root / "profiles"
    if not profiles_dir.exists():
        print(f"ERROR: profiles/ not found at {profiles_dir}", file=sys.stderr)
        return 1

    failures: list[str] = []

    for profile_path in sorted(profiles_dir.glob("*.toml")):
        profile = load_profile(str(profile_path))
        errors = validate(profile)
        if errors:
            failures.append(f"{profile.name}: validation failed: {errors}")
            continue

        with tempfile.TemporaryDirectory() as tmp1, tempfile.TemporaryDirectory() as tmp2:
            m1 = EmissionManifest(profile_name=profile.name)
            m2 = EmissionManifest(profile_name=profile.name)

            paths1 = render_agents(canonical_root, profile, m1, tmp1)
            paths2 = render_agents(canonical_root, profile, m2, tmp2)

            if len(paths1) != len(paths2):
                failures.append(
                    f"{profile.name}: run1 emitted {len(paths1)} files, run2 emitted {len(paths2)}"
                )
                continue

            for p1, p2 in zip(paths1, paths2):
                b1 = Path(p1).read_bytes()
                b2 = Path(p2).read_bytes()
                if b1 != b2:
                    failures.append(
                        f"{profile.name}: {p1.name} is not byte-identical across two runs"
                    )

            print(
                f"  {profile.name}: {len(paths1)} agents rendered, "
                f"determinism: {'OK' if not [f for f in failures if profile.name in f] else 'FAIL'}"
            )

    if failures:
        print(f"\nSELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print("\nOK: render_agents self-test passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

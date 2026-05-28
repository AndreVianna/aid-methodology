#!/usr/bin/env python3
# render_agents.py — AID canonical-generator agent renderer (task-019)
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
import sys
import tomllib
from pathlib import Path
from typing import Any

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import load_profile, validate, Profile, ModelTierSimple, ModelTierDetailed  # noqa: E402
from harness import (  # noqa: E402
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
    # render_scripts, render_agents, render_recipes) MUST apply BOTH
    # substitute_filenames AND rewrite_install_paths in that order. Any
    # canonical/{scripts,templates,skills,agents,rules,recipes}/ reference in
    # a body becomes <install_root>/<dir>/ in the rendered output so adopter
    # projects (which have no canonical/ at root) can resolve the paths.
    # Adding a new renderer? Apply both. (See harness.py rewrite_install_paths
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

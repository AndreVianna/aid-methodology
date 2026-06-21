#!/usr/bin/env python3
# render.py -- AID copy-based generator core (task-005, work-005 feature-002)
#
# Purpose:
#   Collapses the 5-renderer pipeline into a single copy-based generator.
#   "Render profile X" = copy canonical trees into the profile's host root dir,
#   applying a per-tool translate step (tool_names remap, model resolution) to
#   agent/skill frontmatter. The canonical/aid/ tree is copied verbatim.
#
#   Public API:
#     copy_tree(src, dst, profile, manifest, translate) -- copy one canonical tree
#     render_profile(canonical_root, profile, manifest, output_base) -- render all trees
#
#   Translate steps (the one proven surviving transform):
#     copy_agents   -- tool_names remap on allowed-tools + model resolution
#     copy_skills   -- tool_names remap on allowed-tools (strip claude_code_optional
#                       fields on non-claude-code profiles)
#     copy_aid      -- verbatim (no translate)
#
#   Manifest schema (UNCHANGED -- C5/NFR2 preserved):
#     {"_manifest_version": 1}
#     {"dst": ..., "profile": ..., "sha256": ..., "src": ...}  -- sorted by dst
#     LF-only, binary write.
#
#   Codex dormant TOML branch:
#     agent_format="toml" triggers _render_codex_toml() for agent files only.
#     Retained DORMANT (not deleted) until E-CODEX-1 reaches high confidence.
#     All other format branches (copilot-agent, antigravity-rule) are DELETED.
#
# Usage:
#   python render.py --self-test --canonical-root <repo-root>
#   (Imported by run_generator.py; also runnable standalone for self-test)
#
# Requirements: Python 3.11+
# ASCII-only (C3 -- CI-guarded)
from __future__ import annotations

import argparse
import re
import stat
import sys
import tempfile
import tomllib
from pathlib import Path
from typing import Any, Callable

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import (  # noqa: E402
    load_profile,
    validate,
    Profile,
    ModelTierSimple,
    ModelTierDetailed,
)
from render_lib import (  # noqa: E402
    substitute_filenames,
    rewrite_install_paths,
    sha256_hex,
    EmissionManifest,
)


# ---------------------------------------------------------------------------
# Constants -- internal uniform shape (hardcoded, NFR5: adding a 6th tool
# needs only a new profile TOML row, never new dir keys)
# ---------------------------------------------------------------------------

# The three canonical source subdirectory names under canonical/
_AGENTS_DIR = "agents"
_SKILLS_DIR = "skills"
_AID_DIR    = "aid"     # canonical/aid/ -> {root}/aid/ (verbatim copy)

# Extensions that receive text transforms (substitute_filenames + rewrite_install_paths)
_TEXT_EXTENSIONS = frozenset({
    ".md", ".txt", ".sh", ".ps1", ".mjs", ".js", ".html", ".css", ".py",
})

# The filename_map for all profiles: these three placeholders are tool-agnostic
# except project_context_file which differs for claude-code vs the other 4.
_FILENAME_MAP_COMMON = {
    "reviewer_output_file": "STATE.md",
    "open_questions_file": "additional-info.md",
}


# ---------------------------------------------------------------------------
# Minimal filename_map builder
# ---------------------------------------------------------------------------

def _build_filename_map(profile: Profile) -> dict[str, str]:
    """Build the filename substitution map from the profile."""
    return {
        "project_context_file": profile.root_file,
        **_FILENAME_MAP_COMMON,
    }


# ---------------------------------------------------------------------------
# Tool-name remapping helpers (the one surviving translate step)
# ---------------------------------------------------------------------------

def _remap_tools(tools_str: str, tool_names: dict[str, str]) -> str:
    """
    Apply tool_names remapping to a comma-separated tools string.

    Only entries present as keys in tool_names are substituted;
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
    Apply tool_names remapping and return a list of tool name strings.

    Used by the dormant TOML branch for Codex (where tools may appear as a list).

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
# YAML-lite frontmatter parser (no external deps)
# ---------------------------------------------------------------------------

def _parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    """
    Parse YAML frontmatter delimited by --- lines.

    Returns
    -------
    tuple[dict[str, Any], str]
        (frontmatter_dict, body_text). Returns ({}, text) if no frontmatter found.
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
                if (val.startswith('"') and val.endswith('"')) or \
                   (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                fm[key] = val
        i += 1

    return fm, body


def _build_frontmatter_md(fields: dict[str, Any]) -> str:
    """Serialize a flat dict as YAML frontmatter block (--- delimited)."""
    lines = ["---"]
    for key, val in fields.items():
        if isinstance(val, bool):
            lines.append(f"{key}: {'true' if val else 'false'}")
        elif isinstance(val, str):
            if any(c in val for c in (':', '"', "'", '{', '}', '[', ']', '#', '&', '*', '!', '|', '>', '%')):
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
    """Return the reasoning_effort for a given tier alias (Codex dormant branch only)."""
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
# Include resolver ({{include:<name>}} tokens in agent body)
# ---------------------------------------------------------------------------

_INCLUDE_RE = re.compile(r"\{\{include:([^}]+)\}\}")


def _resolve_includes(body: str, canonical_root: Path, install_root: str) -> str:
    """
    Expand {{include:<name>}} tokens in body using the matching template file.

    Reads canonical/aid/templates/<name>.md, applies rewrite_install_paths
    to the template content, then replaces the token.
    """
    def _replace_include(match: re.Match) -> str:  # type: ignore[type-arg]
        name = match.group(1).strip()
        template_path = canonical_root / "canonical" / "aid" / "templates" / f"{name}.md"
        template_content = template_path.read_text(encoding="utf-8")
        return rewrite_install_paths(template_content, install_root)

    return _INCLUDE_RE.sub(_replace_include, body)


# ---------------------------------------------------------------------------
# Codex dormant TOML branch (retained until E-CODEX-1 reaches high confidence)
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
    Render a Codex agent TOML file (DORMANT branch -- retained until E-CODEX-1 is high).

    The body becomes a triple-quoted TOML multi-line string
    assigned to developer_instructions.
    """
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
# Agent translate step
# ---------------------------------------------------------------------------

def _translate_agent(
    src_path: Path,
    profile: Profile,
    canonical_root: Path,
    filename_map: dict[str, str],
) -> tuple[str, str]:
    """
    Translate one canonical agent file into the profile's format.

    Returns
    -------
    tuple[str, str]
        (content, out_filename)
    """
    raw_text = src_path.read_text(encoding="utf-8")
    fm, body = _parse_frontmatter(raw_text)

    agent_name = fm.get("name", src_path.parent.name)
    description = fm.get("description", "")
    tier = fm.get("tier", "medium")
    tools_str = fm.get("tools", "")
    permission_mode = fm.get("permissionMode")
    background = fm.get("background")

    install_root = profile.root_dir

    # Apply filename substitution + path rewrite to description
    description = substitute_filenames(description, filename_map)
    description = rewrite_install_paths(description, install_root)

    # Apply filename substitution + path rewrite to body
    body = substitute_filenames(body, filename_map)
    body = rewrite_install_paths(body, install_root)

    # Resolve {{include:<name>}} tokens
    body = _resolve_includes(body, canonical_root, install_root)

    # Dormant TOML branch for Codex (E-CODEX-1 gated)
    if profile.agent_format == "toml":
        model = _resolve_model(profile, tier)
        reasoning_effort = _resolve_reasoning_effort(profile, tier)
        content = _render_codex_toml(
            name=agent_name,
            description=description,
            model=model,
            reasoning_effort=reasoning_effort,
            body=body,
        )
        return content, f"{agent_name}.toml"

    # Uniform markdown branch (all other tools: claude-code, cursor, copilot, antigravity)
    model = _resolve_model(profile, tier)
    remapped_tools = _remap_tools(tools_str, profile.tool_names)

    new_fm: dict[str, Any] = {
        "name": agent_name,
        "description": description,
        "tools": remapped_tools,
        "model": model,
    }
    if permission_mode is not None:
        new_fm["permissionMode"] = permission_mode
    if background is not None:
        if isinstance(background, str):
            background = background.lower() == "true"
        new_fm["background"] = background

    fm_block = _build_frontmatter_md(new_fm)
    content = fm_block + body
    return content, f"{agent_name}.md"


# ---------------------------------------------------------------------------
# Skill translate step
# ---------------------------------------------------------------------------

def _split_frontmatter_raw(text: str) -> tuple[list[str], str]:
    """
    Split text into raw frontmatter lines and body.

    Returns (fm_lines, body) where fm_lines does NOT include the ---
    delimiters.  Returns ([], text) if no frontmatter found.
    """
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return [], text

    end_idx = None
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end_idx = i
            break

    if end_idx is None:
        return [], text

    fm_lines = lines[1:end_idx]
    body = "".join(lines[end_idx + 1:])
    return fm_lines, body


def _rewrite_skill_frontmatter(
    fm_lines: list[str],
    tool_names: dict[str, str],
    is_claude_code: bool,
) -> list[str]:
    """
    Rewrite raw frontmatter lines:
    - Apply tool_names remapping to the allowed-tools: line.
    - Drop claude_code_optional fields (context:, agent:) for non-Claude-Code profiles.

    Returns the rewritten list of lines (still without --- delimiters).
    """
    # claude_code_optional fields dropped for non-claude-code profiles
    _CC_OPTIONAL = frozenset({"context", "agent"})

    result: list[str] = []
    i = 0
    while i < len(fm_lines):
        line = fm_lines[i]
        stripped = line.strip()

        if stripped and not line[0].isspace():
            key = stripped.split(":")[0].strip()

            # Drop claude_code_optional for non-claude-code profiles
            if not is_claude_code and key in _CC_OPTIONAL:
                i += 1
                while i < len(fm_lines) and fm_lines[i] and fm_lines[i][0].isspace():
                    i += 1
                continue

            # Remap allowed-tools
            if key == "allowed-tools" and tool_names:
                colon_idx = line.index(":")
                tools_part = line[colon_idx + 1:].rstrip("\n")
                remapped = _remap_tools(tools_part.strip(), tool_names)
                result.append(f"allowed-tools: {remapped}\n")
                i += 1
                continue

        result.append(line)
        i += 1

    return result


# ---------------------------------------------------------------------------
# copy_tree -- the heart of the copy generator
# ---------------------------------------------------------------------------

def copy_tree(
    src_dir: Path,
    dst_dir: Path,
    profile: Profile,
    manifest: EmissionManifest,
    canonical_root: Path,
    output_base: Path,
    translate: str = "none",
) -> list[Path]:
    """
    Copy all files from src_dir into dst_dir, applying per-tool translation.

    Parameters
    ----------
    src_dir : Path
        Source directory (e.g. canonical/agents).
    dst_dir : Path
        Destination directory (e.g. profiles/claude-code/.claude/agents).
    profile : Profile
        Loaded and validated profile (provides root_dir, tool_names, etc.).
    manifest : EmissionManifest
        Manifest to record emitted files into.
    canonical_root : Path
        Repo root (used for include resolution and src-relative paths).
    output_base : Path
        Destination root (usually repo root for in-tree generation, or a temp
        dir for determinism testing).
    translate : str
        One of "agents", "skills", "none".
        - "agents": apply agent frontmatter translate (tool_names remap + model resolution)
        - "skills": apply skill frontmatter translate (allowed-tools remap + CC-optional strip)
        - "none"  : verbatim copy (no text transforms beyond filename substitution + path rewrite)

    Returns
    -------
    list[Path]
        Sorted list of output paths.
    """
    filename_map = _build_filename_map(profile)
    install_root = profile.root_dir
    common_parent = Path(profile.common_parent())
    out_paths: list[Path] = []

    if translate == "agents":
        # Agent files live in canonical/agents/<name>/AGENT.md
        agent_files = sorted(src_dir.glob("*/AGENT.md"))
        if not agent_files:
            raise FileNotFoundError(f"No agent files found in {src_dir}")

        for agent_file in agent_files:
            content, out_name = _translate_agent(
                src_path=agent_file,
                profile=profile,
                canonical_root=canonical_root,
                filename_map=filename_map,
            )
            out_path = dst_dir / out_name
            out_path.parent.mkdir(parents=True, exist_ok=True)
            encoded = content.encode("utf-8")
            out_path.write_bytes(encoded)

            src_rel = str(agent_file.relative_to(canonical_root)).replace("\\", "/")
            dst_rel = str(out_path.relative_to(output_base / common_parent)).replace("\\", "/")
            manifest.add(
                profile=profile.name,
                src=src_rel,
                dst=dst_rel,
                sha256=sha256_hex(encoded),
            )
            out_paths.append(out_path)

    elif translate == "skills":
        # Skill directories: canonical/skills/<slug>/SKILL.md + references/*.md + scripts/
        skill_dirs = sorted(d for d in src_dir.iterdir() if d.is_dir())
        if not skill_dirs:
            raise FileNotFoundError(f"No skill directories found in {src_dir}")

        is_claude_code = (profile.name == "claude-code")

        for skill_dir in skill_dirs:
            skill_slug = skill_dir.name
            out_skill_dir = dst_dir / skill_slug

            # SKILL.md (required)
            skill_md = skill_dir / "SKILL.md"
            if not skill_md.exists():
                raise FileNotFoundError(f"SKILL.md missing in {skill_dir}")

            raw = skill_md.read_text(encoding="utf-8")
            fm_lines, body = _split_frontmatter_raw(raw)
            new_fm_lines = _rewrite_skill_frontmatter(fm_lines, profile.tool_names, is_claude_code)

            fm_block = "---\n" + "".join(new_fm_lines) + "---\n"
            fm_block = substitute_filenames(fm_block, filename_map)
            fm_block = rewrite_install_paths(fm_block, install_root)
            body = substitute_filenames(body, filename_map)
            body = rewrite_install_paths(body, install_root)
            content = fm_block + body

            out_path = out_skill_dir / "SKILL.md"
            out_path.parent.mkdir(parents=True, exist_ok=True)
            encoded = content.encode("utf-8")
            out_path.write_bytes(encoded)

            src_rel = str(skill_md.relative_to(canonical_root)).replace("\\", "/")
            dst_rel = str(out_path.relative_to(output_base / common_parent)).replace("\\", "/")
            manifest.add(
                profile=profile.name, src=src_rel, dst=dst_rel, sha256=sha256_hex(encoded)
            )
            out_paths.append(out_path)

            # references/*.md (optional)
            ref_dir = skill_dir / "references"
            if ref_dir.is_dir():
                for ref_file in sorted(ref_dir.glob("*.md")):
                    raw_ref = ref_file.read_text(encoding="utf-8")
                    content_ref = substitute_filenames(raw_ref, filename_map)
                    content_ref = rewrite_install_paths(content_ref, install_root)
                    out_ref = out_skill_dir / "references" / ref_file.name
                    out_ref.parent.mkdir(parents=True, exist_ok=True)
                    enc_ref = content_ref.encode("utf-8")
                    out_ref.write_bytes(enc_ref)
                    src_rel_r = str(ref_file.relative_to(canonical_root)).replace("\\", "/")
                    dst_rel_r = str(out_ref.relative_to(output_base / common_parent)).replace("\\", "/")
                    manifest.add(
                        profile=profile.name, src=src_rel_r, dst=dst_rel_r, sha256=sha256_hex(enc_ref)
                    )
                    out_paths.append(out_ref)

            # scripts/ (verbatim copy)
            scripts_dir = skill_dir / "scripts"
            if scripts_dir.is_dir():
                for script_file in sorted(scripts_dir.iterdir()):
                    if not script_file.is_file():
                        continue
                    enc_s = script_file.read_bytes()
                    out_s = out_skill_dir / "scripts" / script_file.name
                    out_s.parent.mkdir(parents=True, exist_ok=True)
                    out_s.write_bytes(enc_s)
                    src_rel_s = str(script_file.relative_to(canonical_root)).replace("\\", "/")
                    dst_rel_s = str(out_s.relative_to(output_base / common_parent)).replace("\\", "/")
                    manifest.add(
                        profile=profile.name, src=src_rel_s, dst=dst_rel_s, sha256=sha256_hex(enc_s)
                    )
                    out_paths.append(out_s)

    else:
        # translate="none": verbatim copy of the entire src_dir tree.
        # This covers canonical/aid/ -> {root}/aid/ (verbatim).
        if not src_dir.exists():
            return out_paths

        all_files = sorted(
            f for f in src_dir.rglob("*")
            if f.is_file() and not f.name.startswith(".")
        )

        for src_file in all_files:
            rel = src_file.relative_to(src_dir)
            out_path = dst_dir / rel

            # Text files receive substitute_filenames + rewrite_install_paths
            if src_file.suffix.lower() in _TEXT_EXTENSIONS:
                try:
                    raw = src_file.read_text(encoding="utf-8")
                    content_t = substitute_filenames(raw, filename_map)
                    content_t = rewrite_install_paths(content_t, install_root)
                    encoded = content_t.encode("utf-8")
                except UnicodeDecodeError:
                    encoded = src_file.read_bytes()
            else:
                encoded = src_file.read_bytes()

            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_bytes(encoded)

            # Preserve executable bit for shell/script files on POSIX
            if src_file.suffix.lower() in {".sh", ".ps1", ".mjs", ".py"}:
                try:
                    mode = src_file.stat().st_mode | 0o111
                    out_path.chmod(mode)
                except (PermissionError, OSError):
                    pass  # best-effort; no-op on Windows

            # Manifest src: normalize canonical/aid/<sub>/ -> canonical/<sub>/
            # for manifest src stability (downstream traceability paths unchanged).
            src_rel = str(src_file.relative_to(canonical_root)).replace("\\", "/")
            for _sub in ("scripts", "templates", "recipes"):
                src_rel = src_rel.replace(f"canonical/aid/{_sub}/", f"canonical/{_sub}/", 1)

            dst_rel = str(out_path.relative_to(output_base / common_parent)).replace("\\", "/")
            manifest.add(
                profile=profile.name, src=src_rel, dst=dst_rel, sha256=sha256_hex(encoded)
            )
            out_paths.append(out_path)

    return out_paths


# ---------------------------------------------------------------------------
# render_profile -- render all three canonical trees for one profile
# ---------------------------------------------------------------------------

def render_profile(
    canonical_root: str | Path,
    profile: Profile,
    manifest: EmissionManifest,
    output_base: str | Path,
) -> list[Path]:
    """
    Render all canonical trees for the given profile.

    Copies:
      canonical/agents/ -> {output_base}/{profile.root_dir}/agents/  (translate=agents)
      canonical/skills/ -> {output_base}/{profile.root_dir}/skills/  (translate=skills)
      canonical/aid/    -> {output_base}/{profile.root_dir}/aid/     (translate=none)

    Returns
    -------
    list[Path]
        All emitted paths (sorted within each tree; agents then skills then aid).
    """
    canonical_root = Path(canonical_root)
    output_base = Path(output_base)
    root = profile.root_dir
    # Use the common_parent to locate the actual output root relative to output_base
    # The layout is: output_base/profiles/<name>/{root_dir}/...
    common_parent = Path(profile.common_parent())
    profile_out = output_base / common_parent / root

    all_paths: list[Path] = []

    # 1. Agents
    all_paths.extend(copy_tree(
        src_dir=canonical_root / "canonical" / _AGENTS_DIR,
        dst_dir=profile_out / _AGENTS_DIR,
        profile=profile,
        manifest=manifest,
        canonical_root=canonical_root,
        output_base=output_base,
        translate="agents",
    ))

    # 2. Skills
    all_paths.extend(copy_tree(
        src_dir=canonical_root / "canonical" / _SKILLS_DIR,
        dst_dir=profile_out / _SKILLS_DIR,
        profile=profile,
        manifest=manifest,
        canonical_root=canonical_root,
        output_base=output_base,
        translate="skills",
    ))

    # 3. AID own tree (verbatim)
    all_paths.extend(copy_tree(
        src_dir=canonical_root / "canonical" / _AID_DIR,
        dst_dir=profile_out / _AID_DIR,
        profile=profile,
        manifest=manifest,
        canonical_root=canonical_root,
        output_base=output_base,
        translate="none",
    ))

    return all_paths


# ---------------------------------------------------------------------------
# Self-test
# ---------------------------------------------------------------------------

def _self_test(canonical_root_arg: str) -> int:
    """
    Self-test suite for render.py public methods.

    Tests:
      T1. copy_tree translate=none: verbatim copy produces byte-identical output
      T2. copy_tree translate=agents: two runs produce byte-identical output (determinism)
      T3. copy_tree translate=skills: two runs produce byte-identical output
      T4. copy_tree translate=agents: tool_names remap applied (Bash->Terminal for cursor)
      T5. copy_tree translate=agents: Codex dormant TOML branch produces .toml files
      T6. render_profile: all three trees are emitted and manifest is populated
      T7. copy_tree translate=none: executable bit preserved on .sh files
      T8. copy_tree translate=agents: manifest schema correct (sentinel + sorted dst)
    """
    if not canonical_root_arg:
        print("ERROR: --canonical-root required for --self-test", file=sys.stderr)
        return 1

    canonical_root = Path(canonical_root_arg)
    profiles_dir = canonical_root / "profiles"
    failures: list[str] = []

    # Load all profiles
    profile_paths = sorted(profiles_dir.glob("*.toml"))
    if not profile_paths:
        print("ERROR: no profile TOMLs found", file=sys.stderr)
        return 1

    profiles = []
    for pp in profile_paths:
        p = load_profile(str(pp))
        errs = validate(p)
        if errs:
            failures.append(f"Profile {p.name} invalid: {errs}")
        else:
            profiles.append(p)

    if failures:
        print(f"SELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    # T1: verbatim copy determinism (canonical/aid/)
    print("T1: copy_tree translate=none -- verbatim copy determinism...")
    aid_src = canonical_root / "canonical" / "aid"
    if aid_src.exists():
        with tempfile.TemporaryDirectory() as tmp1, tempfile.TemporaryDirectory() as tmp2:
            p = profiles[0]
            m1 = EmissionManifest(profile_name=p.name)
            m2 = EmissionManifest(profile_name=p.name)
            cp = Path(p.common_parent())
            dst1 = Path(tmp1) / cp / p.root_dir / "aid"
            dst2 = Path(tmp2) / cp / p.root_dir / "aid"
            paths1 = copy_tree(aid_src, dst1, p, m1, canonical_root, Path(tmp1), "none")
            paths2 = copy_tree(aid_src, dst2, p, m2, canonical_root, Path(tmp2), "none")
            if len(paths1) != len(paths2):
                failures.append(f"T1 FAIL: different file counts {len(paths1)} vs {len(paths2)}")
            else:
                for pa, pb in zip(paths1, paths2):
                    if pa.read_bytes() != pb.read_bytes():
                        failures.append(f"T1 FAIL: {pa.name} not byte-identical across two runs")
            if not failures:
                print("  PASS")

    # T2: agents copy determinism (all profiles)
    print("T2: copy_tree translate=agents -- determinism across two runs...")
    agents_src = canonical_root / "canonical" / "agents"
    for p in profiles:
        with tempfile.TemporaryDirectory() as tmp1, tempfile.TemporaryDirectory() as tmp2:
            m1 = EmissionManifest(profile_name=p.name)
            m2 = EmissionManifest(profile_name=p.name)
            cp = Path(p.common_parent())
            dst1 = Path(tmp1) / cp / p.root_dir / "agents"
            dst2 = Path(tmp2) / cp / p.root_dir / "agents"
            try:
                paths1 = copy_tree(agents_src, dst1, p, m1, canonical_root, Path(tmp1), "agents")
                paths2 = copy_tree(agents_src, dst2, p, m2, canonical_root, Path(tmp2), "agents")
            except Exception as exc:
                failures.append(f"T2 FAIL [{p.name}]: {exc}")
                continue
            if len(paths1) != len(paths2):
                failures.append(f"T2 FAIL [{p.name}]: {len(paths1)} vs {len(paths2)} files")
            else:
                for pa, pb in zip(paths1, paths2):
                    if pa.read_bytes() != pb.read_bytes():
                        failures.append(f"T2 FAIL [{p.name}]: {pa.name} not byte-identical")
    if not failures:
        print("  PASS")

    # T3: skills copy determinism (all profiles)
    print("T3: copy_tree translate=skills -- determinism across two runs...")
    skills_src = canonical_root / "canonical" / "skills"
    for p in profiles:
        with tempfile.TemporaryDirectory() as tmp1, tempfile.TemporaryDirectory() as tmp2:
            m1 = EmissionManifest(profile_name=p.name)
            m2 = EmissionManifest(profile_name=p.name)
            cp = Path(p.common_parent())
            dst1 = Path(tmp1) / cp / p.root_dir / "skills"
            dst2 = Path(tmp2) / cp / p.root_dir / "skills"
            try:
                paths1 = copy_tree(skills_src, dst1, p, m1, canonical_root, Path(tmp1), "skills")
                paths2 = copy_tree(skills_src, dst2, p, m2, canonical_root, Path(tmp2), "skills")
            except Exception as exc:
                failures.append(f"T3 FAIL [{p.name}]: {exc}")
                continue
            if len(paths1) != len(paths2):
                failures.append(f"T3 FAIL [{p.name}]: {len(paths1)} vs {len(paths2)} files")
            else:
                for pa, pb in zip(paths1, paths2):
                    if pa.read_bytes() != pb.read_bytes():
                        failures.append(f"T3 FAIL [{p.name}]: {pa.name} not byte-identical")
    if not failures:
        print("  PASS")

    # T4: tool_names remap applied for cursor (Bash->Terminal)
    print("T4: copy_tree translate=agents -- Bash->Terminal remap for cursor...")
    cursor_profiles = [p for p in profiles if p.name == "cursor"]
    if cursor_profiles:
        cp_cursor = cursor_profiles[0]
        with tempfile.TemporaryDirectory() as tmp:
            m = EmissionManifest(profile_name="cursor")
            cp_path = Path(cp_cursor.common_parent())
            dst = Path(tmp) / cp_path / cp_cursor.root_dir / "agents"
            paths = copy_tree(agents_src, dst, cp_cursor, m, canonical_root, Path(tmp), "agents")
            # Check that no rendered agent file contains "tools: Bash" (should be Terminal)
            for p_path in paths:
                if p_path.suffix == ".md":
                    text = p_path.read_text(encoding="utf-8")
                    if "tools: Bash" in text or "Bash," in text:
                        failures.append(f"T4 FAIL: cursor agent {p_path.name} still has 'Bash' in tools")
        if not failures:
            print("  PASS")

    # T5: Codex dormant TOML branch produces .toml files
    print("T5: copy_tree translate=agents -- Codex TOML branch (dormant)...")
    codex_profiles = [p for p in profiles if p.name == "codex" and p.agent_format == "toml"]
    if codex_profiles:
        cp_codex = codex_profiles[0]
        with tempfile.TemporaryDirectory() as tmp:
            m = EmissionManifest(profile_name="codex")
            cp_path = Path(cp_codex.common_parent())
            dst = Path(tmp) / cp_path / cp_codex.root_dir / "agents"
            paths = copy_tree(agents_src, dst, cp_codex, m, canonical_root, Path(tmp), "agents")
            toml_paths = [p for p in paths if p.suffix == ".toml"]
            if not toml_paths:
                failures.append("T5 FAIL: Codex TOML branch produced no .toml agent files")
            else:
                # Verify the first TOML file parses correctly
                try:
                    with toml_paths[0].open("rb") as fh:
                        tomllib.load(fh)
                    print(f"  PASS ({len(toml_paths)} TOML files produced)")
                except Exception as exc:
                    failures.append(f"T5 FAIL: Codex TOML file does not parse: {exc}")
    else:
        print("  SKIP (no Codex profile with format=toml found)")

    # T6: render_profile emits all three trees and populates manifest
    print("T6: render_profile -- all three trees emitted and manifest populated...")
    p = profiles[0]  # use first profile (claude-code)
    with tempfile.TemporaryDirectory() as tmp:
        m = EmissionManifest(profile_name=p.name)
        try:
            paths = render_profile(canonical_root, p, m, Path(tmp))
        except Exception as exc:
            failures.append(f"T6 FAIL: render_profile raised: {exc}")
        else:
            if not paths:
                failures.append("T6 FAIL: render_profile returned no paths")
            if not m._records:
                failures.append("T6 FAIL: manifest has no records after render_profile")
            # Check all three trees present
            cp_path = Path(p.common_parent())
            out_root = Path(tmp) / cp_path / p.root_dir
            missing_trees = []
            for tree in ("agents", "skills", "aid"):
                if not (out_root / tree).exists():
                    missing_trees.append(tree)
            if missing_trees:
                failures.append(f"T6 FAIL: missing output trees: {missing_trees}")
            else:
                print(f"  PASS ({len(paths)} files emitted, {len(m._records)} manifest records)")

    # T7: executable bit preserved on .sh files (translate=none)
    print("T7: copy_tree translate=none -- .sh exec bit preserved...")
    aid_scripts = canonical_root / "canonical" / "aid" / "scripts"
    sh_files = list(aid_scripts.rglob("*.sh")) if aid_scripts.exists() else []
    if sh_files:
        p = profiles[0]
        with tempfile.TemporaryDirectory() as tmp:
            m = EmissionManifest(profile_name=p.name)
            cp_path = Path(p.common_parent())
            dst = Path(tmp) / cp_path / p.root_dir / "aid"
            copy_tree(aid_src, dst, p, m, canonical_root, Path(tmp), "none")
            # Find emitted .sh files
            emitted_sh = list((dst / "scripts").rglob("*.sh")) if (dst / "scripts").exists() else []
            for sh in emitted_sh:
                mode = sh.stat().st_mode
                if not (mode & stat.S_IXUSR):
                    failures.append(f"T7 FAIL: {sh.name} lost executable bit")
            if emitted_sh and not any("T7 FAIL" in f for f in failures):
                print(f"  PASS ({len(emitted_sh)} .sh files with exec bit)")
            elif not emitted_sh:
                print("  SKIP (no .sh files in canonical/aid/scripts)")
    else:
        print("  SKIP (no .sh files found)")

    # T8: manifest schema -- sentinel + sorted dst + LF-only
    print("T8: copy_tree translate=agents -- manifest schema correct...")
    import json as _json
    p = profiles[0]
    with tempfile.TemporaryDirectory() as tmp:
        m = EmissionManifest(profile_name=p.name)
        cp_path = Path(p.common_parent())
        dst = Path(tmp) / cp_path / p.root_dir / "agents"
        copy_tree(agents_src, dst, p, m, canonical_root, Path(tmp), "agents")
        manifest_path = Path(tmp) / cp_path / "emission-manifest.jsonl"
        payload = m.write(str(manifest_path))
        lines_bytes = [ln for ln in payload.split(b"\n") if ln.strip()]
        if not lines_bytes:
            failures.append("T8 FAIL: empty manifest payload")
        else:
            first = _json.loads(lines_bytes[0])
            if "_manifest_version" not in first:
                failures.append(f"T8 FAIL: first line is not sentinel: {first}")
            dsts = [_json.loads(ln)["dst"] for ln in lines_bytes[1:] if ln.strip()]
            if dsts != sorted(dsts):
                failures.append(f"T8 FAIL: manifest records not sorted by dst: {dsts[:5]}")
            if b"\r\n" in payload:
                failures.append("T8 FAIL: manifest contains CRLF -- expected LF only")
            if not payload.endswith(b"\n"):
                failures.append("T8 FAIL: manifest does not end with LF")
        if not any("T8 FAIL" in f for f in failures):
            print("  PASS")

    # Results
    if failures:
        print(f"\nSELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print(f"\nOK: all render.py self-tests passed (8 tests)")
    return 0


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="render.py",
        description=(
            "AID copy-based generator core. "
            "Run with --self-test to verify correctness."
        ),
    )
    parser.add_argument("--canonical-root", metavar="PATH", help="Repo root (required for --self-test)")
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run built-in self-tests and exit 0 on success, 1 on failure.",
    )
    args = parser.parse_args()

    if args.self_test:
        return _self_test(args.canonical_root or ".")

    parser.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())

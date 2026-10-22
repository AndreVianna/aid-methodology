#!/usr/bin/env python3
# render.py -- agents-only profile renderer
#
# Purpose:
#   Render canonical agents for each host, retaining only tool-name remapping,
#   model resolution, Codex TOML output, and {{include:...}} expansion. Every
#   other profile-specific value is emitted in aid-tool.conf.
#
# Usage:
#   python render.py --self-test --canonical-root <repo-root>
#
# Requirements: Python 3.11+; standard library only.
from __future__ import annotations

import argparse
import re
import sys
import tempfile
import tomllib
from pathlib import Path
from typing import Any

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import (  # noqa: E402
    ModelTierDetailed,
    Profile,
    load_profile,
    validate,
)
from render_lib import write_output_file  # noqa: E402

_INCLUDE_RE = re.compile(r"\{\{include:([^}]+)\}\}")
_BLOCK_SEQUENCE_KEYS = frozenset({"review-criteria"})


class _RawBlock(str):
    """Already-serialized block YAML retained verbatim during frontmatter rebuild."""


def _parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    """Parse the flat agent frontmatter subset and retain its body."""
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return {}, text
    end_idx = next((i for i, line in enumerate(lines[1:], 1) if line.strip() == "---"), None)
    if end_idx is None:
        return {}, text
    fm_lines = lines[1:end_idx]
    body = "".join(lines[end_idx + 1:])
    fm: dict[str, Any] = {}
    i = 0
    while i < len(fm_lines):
        raw = fm_lines[i].rstrip("\n")
        if not raw.strip() or raw.lstrip().startswith("#"):
            i += 1
            continue
        if ":" not in raw:
            i += 1
            continue
        key, _, val = raw.partition(":")
        key, val = key.strip(), val.strip()
        if key in _BLOCK_SEQUENCE_KEYS and not val:
            block: list[str] = []
            i += 1
            while i < len(fm_lines) and (not fm_lines[i].strip() or fm_lines[i][0].isspace()):
                block.append(fm_lines[i].rstrip("\n"))
                i += 1
            fm[key] = _RawBlock("\n".join(block))
            continue
        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
            val = val[1:-1]
        fm[key] = val
        i += 1
    return fm, body


def _build_frontmatter(fields: dict[str, Any]) -> str:
    """Serialize the renderer's flat YAML frontmatter fields."""
    lines = ["---"]
    for key, value in fields.items():
        if isinstance(value, _RawBlock):
            lines.append(f"{key}:")
            lines.extend(value.split("\n"))
        elif isinstance(value, bool):
            lines.append(f"{key}: {'true' if value else 'false'}")
        elif isinstance(value, str):
            if any(char in value for char in (":", '"', "'", "{", "}", "[", "]", "#", "&", "*", "!", "|", ">", "%")):
                lines.append(f'{key}: "{value.replace(chr(34), chr(92) + chr(34))}"')
            else:
                lines.append(f"{key}: {value}")
        else:
            lines.append(f"{key}: {value}")
    lines.append("---")
    return "\n".join(lines) + "\n"


def _remap_tools(tools: str, mapping: dict[str, str]) -> str:
    """Apply a profile's tool-name aliases to comma-separated tools."""
    return ", ".join(mapping.get(name.strip(), name.strip()) for name in tools.split(","))


def _resolve_model(profile: Profile, tier: str) -> str:
    """Resolve a canonical tier name to this profile's model identifier."""
    value = profile.model_tiers.get(tier)
    if value is None:
        raise ValueError(f"Unknown tier {tier!r} in profile {profile.name!r}")
    return value.model


def _resolve_includes(body: str, canonical_root: Path) -> str:
    """Replace each include token with its canonical template bytes."""
    def replace(match: re.Match[str]) -> str:
        name = match.group(1).strip()
        source = canonical_root / "canonical" / "aid" / "templates" / f"{name}.md"
        return source.read_text(encoding="utf-8")
    return _INCLUDE_RE.sub(replace, body)


def _toml_string(value: str) -> str:
    """Return a quoted TOML string."""
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _render_codex_toml(name: str, description: str, model: str, effort: str, body: str) -> str:
    """Render an agent in Codex TOML form."""
    body = body.lstrip("\n").rstrip("\n")
    return "\n".join([
        f"name = {_toml_string(name)}",
        f"description = {_toml_string(description)}",
        f"model = {_toml_string(model)}",
        f"model_reasoning_effort = {_toml_string(effort)}",
        'developer_instructions = """', body, '"""', "",
    ])


def _translate_agent(src_path: Path, profile: Profile, canonical_root: Path) -> tuple[str, str]:
    """Apply the supported agent transforms and reject unresolved canonical paths."""
    fm, body = _parse_frontmatter(src_path.read_text(encoding="utf-8"))
    name = fm.get("name", src_path.parent.name)
    description = fm.get("description", "")
    tier = fm.get("tier", "medium")
    tools = fm.get("tools", "")
    body = _resolve_includes(body, canonical_root)

    if profile.agent_format == "toml":
        tier_value = profile.model_tiers.get(tier)
        if not isinstance(tier_value, ModelTierDetailed):
            raise ValueError(f"Profile {profile.name!r} tier {tier!r} has no reasoning_effort")
        content = _render_codex_toml(name, description, _resolve_model(profile, tier), tier_value.reasoning_effort, body)
        filename = f"{name}.toml"
    else:
        fields: dict[str, Any] = {
            "name": name,
            "description": description,
            "tools": _remap_tools(tools, profile.tool_names),
            "model": _resolve_model(profile, tier),
        }
        for key in ("permissionMode", "background", "review-criteria"):
            if key in fm:
                value = fm[key]
                if key == "background" and isinstance(value, str):
                    value = value.lower() == "true"
                fields[key] = value
        content = _build_frontmatter(fields) + body
        filename = f"{name}.md"

    if "canonical/" in content:
        raise ValueError(f"Rendered agent {src_path} retains a canonical/ token")
    return content, filename


def _descriptor(profile: Profile) -> str:
    """Build the ASCII, LF-delimited aid-tool.conf for one profile."""
    lines = [f"tool={profile.name}"]
    lines.extend(f"skill_mirror={mirror}" for mirror in profile.skill_mirrors)
    if profile.worktree_root:
        lines.append(f"worktree_root={profile.worktree_root}")
    if profile.context_import:
        lines.append(f"context_import={profile.context_import}")
    if profile.rules_inline:
        lines.append("rules_inline=true")
    if profile.hooks.stop:
        lines.append(f"hook_settings={profile.hooks.settings}")
        lines.extend(f"hook=Stop:{hook}" for hook in profile.hooks.stop)
    payload = "\n".join(lines) + "\n"
    payload.encode("ascii")
    return payload


def render_profile(canonical_root: str | Path, profile: Profile, output_base: str | Path) -> list[Path]:
    """Render only agents and aid-tool.conf for a profile."""
    canonical_root, output_base = Path(canonical_root), Path(output_base)
    profile_dir = output_base / profile.common_parent()
    agents_src = canonical_root / "canonical" / "agents"
    agent_files = sorted(agents_src.glob("*/AGENT.md"))
    if not agent_files:
        raise FileNotFoundError(f"No agent files found in {agents_src}")
    output_paths: list[Path] = []
    for source in agent_files:
        content, filename = _translate_agent(source, profile, canonical_root)
        destination = profile_dir / profile.root_dir / "agents" / filename
        write_output_file(destination, content)
        output_paths.append(destination)
    conf = profile_dir / "aid-tool.conf"
    write_output_file(conf, _descriptor(profile))
    output_paths.append(conf)
    return output_paths


def _self_test(canonical_root: Path) -> int:
    """Exercise neutral rendering, tool remapping, descriptor output, and Codex TOML."""
    failures: list[str] = []
    try:
        profiles = [load_profile(str(path)) for path in sorted((canonical_root / "profiles").glob("*.toml"))]
        for profile in profiles:
            errors = validate(profile)
            if errors:
                failures.extend(errors)
        with tempfile.TemporaryDirectory() as temp:
            for profile in profiles:
                files = render_profile(canonical_root, profile, temp)
                if len(files) != len(list((canonical_root / "canonical" / "agents").glob("*/AGENT.md"))) + 1:
                    failures.append(f"{profile.name}: unexpected output count")
                conf = Path(temp) / profile.common_parent() / "aid-tool.conf"
                if conf.read_bytes() != _descriptor(profile).encode("ascii"):
                    failures.append(f"{profile.name}: descriptor mismatch")
                conf_lines = conf.read_text(encoding="ascii").splitlines()
                want_hooks = [f"hook=Stop:{hook}" for hook in profile.hooks.stop]
                if [line for line in conf_lines if line.startswith("hook=")] != want_hooks:
                    failures.append(f"{profile.name}: descriptor hook lines mismatch")
                has_settings = any(line.startswith("hook_settings=") for line in conf_lines)
                if has_settings != bool(profile.hooks.stop):
                    failures.append(f"{profile.name}: descriptor hook_settings mismatch")
                if profile.hooks.stop and f"hook_settings={profile.hooks.settings}" not in conf_lines:
                    failures.append(f"{profile.name}: descriptor hook_settings value mismatch")
    except Exception as exc:
        failures.append(str(exc))
    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1
    print("OK: renderer self-tests passed")
    return 0


def main() -> int:
    """Expose the renderer self-test command."""
    parser = argparse.ArgumentParser(prog="render.py")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--canonical-root", required=True, metavar="PATH")
    args = parser.parse_args()
    return _self_test(Path(args.canonical_root)) if args.self_test else 0


if __name__ == "__main__":
    sys.exit(main())

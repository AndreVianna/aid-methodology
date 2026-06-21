#!/usr/bin/env python3
# aid_profile.py -- AID canonical-generator profile parser (shrunk schema, task-005)
#
# Purpose:
#   Load a per-tool profile TOML and expose it as a typed Profile dataclass.
#   Run validate(profile) to surface schema problems before rendering begins.
#
#   Schema (shrunk from work-005 feature-002):
#     root_dir     = ".claude"   # host-required root basename
#     root_file    = "CLAUDE.md" # AGENTS.md for non-claude tools (install lib uses it)
#     agent_format = "markdown"  # "markdown" for 4 tools; "toml" dormant for Codex (E-CODEX-1)
#     [tool_names]               # surviving translation: Bash->Terminal (cursor), Bash->shell (copilot)
#     [model_tiers]              # feeds agent execution-metadata translation
#     [capabilities]             # 4 flags consumed by skills graceful-degradation
#
#   Dropped: [layout] (*_dir/*_root/rules_dir/[extras]), [skill], [agent.frontmatter],
#            filename_map, LayoutConfig split-root, ExtrasConfig, RuleEntry.
#   Kept dormant: agent_format="toml" validator value (E-CODEX-1 gated).
#
# Usage:
#   python aid_profile.py --profile profiles/claude-code.toml
#
# Requirements: Python 3.11+ (tomllib is stdlib)
from __future__ import annotations

import argparse
import json
import sys
import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Dataclasses mirroring the shrunk TOML schema
# ---------------------------------------------------------------------------

@dataclass
class ModelTierSimple:
    """Single string value for a tier (Claude Code / Cursor / Copilot style)."""
    model: str


@dataclass
class ModelTierDetailed:
    """Sub-table value for a tier with model + reasoning_effort (Codex / Antigravity)."""
    model: str
    reasoning_effort: str


@dataclass
class CapabilitiesConfig:
    """[capabilities] table."""
    hooks: bool = False
    skill_chaining: bool = True
    background_execution: bool = False
    stop_hook_autocontinue: bool = False


@dataclass
class Profile:
    """
    Top-level profile dataclass (shrunk to the minimal copy-generator schema).

    Fields:
      name          -- derived from the filename stem (e.g. "claude-code")
      root_dir      -- host-required root basename (e.g. ".claude", ".cursor")
      root_file     -- root context filename (e.g. "CLAUDE.md", "AGENTS.md")
      agent_format  -- "markdown" for 4 tools; "toml" dormant for Codex
      tool_names    -- the one surviving translate step (Bash->Terminal, Bash->shell)
      model_tiers   -- tier aliases to model strings (feeds frontmatter translate)
      capabilities  -- 4 capability flags (consumed by skills graceful-degradation)
    """
    name: str
    root_dir: str = ".claude"
    root_file: str = "CLAUDE.md"
    agent_format: str = "markdown"
    tool_names: dict[str, str] = field(default_factory=dict)
    model_tiers: dict[str, ModelTierSimple | ModelTierDetailed] = field(default_factory=dict)
    capabilities: CapabilitiesConfig = field(default_factory=CapabilitiesConfig)
    # Raw TOML dict preserved for lossless round-trip checks
    _raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    # -----------------------------------------------------------------------
    # Compatibility shim: install_root() used by rewrite_install_paths callers
    # -----------------------------------------------------------------------
    def install_root(self) -> str:
        """Return the root basename (e.g. '.claude') -- same as root_dir."""
        return self.root_dir

    def common_parent(self) -> str:
        """
        Return the common parent directory for this profile's output.

        Format: profiles/<name>
        This is where the emission-manifest.jsonl is placed.
        """
        return f"profiles/{self.name}"


# ---------------------------------------------------------------------------
# Loader
# ---------------------------------------------------------------------------

def _parse_model_tiers(raw: dict[str, Any]) -> dict[str, ModelTierSimple | ModelTierDetailed]:
    """
    Handle both:
      large = "opus"           -> ModelTierSimple("opus")
      [large]
        model = "gpt-5.5"     -> ModelTierDetailed("gpt-5.5", "high")
        reasoning_effort = "high"
    """
    result: dict[str, ModelTierSimple | ModelTierDetailed] = {}
    for tier_name, tier_value in raw.items():
        if isinstance(tier_value, str):
            result[tier_name] = ModelTierSimple(model=tier_value)
        elif isinstance(tier_value, dict):
            result[tier_name] = ModelTierDetailed(
                model=tier_value.get("model", ""),
                reasoning_effort=tier_value.get("reasoning_effort", ""),
            )
    return result


def _parse_capabilities(raw: dict[str, Any]) -> CapabilitiesConfig:
    return CapabilitiesConfig(
        hooks=raw.get("hooks", False),
        skill_chaining=raw.get("skill_chaining", True),
        background_execution=raw.get("background_execution", False),
        stop_hook_autocontinue=raw.get("stop_hook_autocontinue", False),
    )


def load_profile(path: str) -> "Profile":
    """
    Load a profile TOML file and return a typed Profile dataclass.

    Parameters
    ----------
    path : str
        Repo-relative or absolute path to the *.toml profile file.

    Returns
    -------
    Profile
        Parsed and structured profile.

    Raises
    ------
    FileNotFoundError
        If the profile file does not exist.
    tomllib.TOMLDecodeError
        If the file is not valid TOML.
    """
    p = Path(path)
    with p.open("rb") as fh:
        raw = tomllib.load(fh)

    name = p.stem  # e.g. "claude-code", "codex", "cursor"

    return Profile(
        name=name,
        root_dir=raw.get("root_dir", ".claude"),
        root_file=raw.get("root_file", "CLAUDE.md"),
        agent_format=raw.get("agent_format", "markdown"),
        tool_names=raw.get("tool_names", {}),
        model_tiers=_parse_model_tiers(raw.get("model_tiers", {})),
        capabilities=_parse_capabilities(raw.get("capabilities", {})),
        _raw=raw,
    )


# ---------------------------------------------------------------------------
# Validator
# ---------------------------------------------------------------------------

_KNOWN_TIERS = {"large", "medium", "small"}

# "toml" retained DORMANT for Codex (E-CODEX-1 not yet high-confidence).
# All other format branches (copilot-agent, antigravity-rule) deleted per task-005.
_KNOWN_AGENT_FORMATS = {"markdown", "toml"}


def validate(profile: "Profile") -> list[str]:
    """
    Validate a loaded Profile and return a list of error strings.
    An empty list means the profile is valid.
    """
    errors: list[str] = []
    name = profile.name

    # root_dir must be set and relative
    if not profile.root_dir:
        errors.append(f"[{name}] root_dir is missing or empty")
    elif profile.root_dir.startswith("/") or profile.root_dir.startswith("\\"):
        errors.append(f"[{name}] root_dir must be a relative basename, got: {profile.root_dir!r}")

    # root_file must be set
    if not profile.root_file:
        errors.append(f"[{name}] root_file is missing or empty")

    # agent_format check
    if profile.agent_format not in _KNOWN_AGENT_FORMATS:
        errors.append(
            f"[{name}] agent_format must be one of {sorted(_KNOWN_AGENT_FORMATS)}, "
            f"got: {profile.agent_format!r}"
        )

    # model_tiers: at least one tier required
    if not profile.model_tiers:
        errors.append(f"[{name}] [model_tiers] is empty -- at least one tier alias required")
    else:
        for tier_name, tier_val in profile.model_tiers.items():
            if tier_name not in _KNOWN_TIERS:
                errors.append(
                    f"[{name}] [model_tiers] unknown tier {tier_name!r} -- "
                    f"expected one of {sorted(_KNOWN_TIERS)}"
                )
            if isinstance(tier_val, ModelTierSimple):
                if not tier_val.model:
                    errors.append(f"[{name}] [model_tiers].{tier_name} is empty string")
            elif isinstance(tier_val, ModelTierDetailed):
                if not tier_val.model:
                    errors.append(f"[{name}] [model_tiers.{tier_name}].model is empty")
                if not tier_val.reasoning_effort:
                    errors.append(
                        f"[{name}] [model_tiers.{tier_name}].reasoning_effort is empty"
                    )

    return errors


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="aid_profile.py",
        description=(
            "Load and validate an AID generator profile TOML. "
            "Exits 0 if valid, 1 if validation errors are found."
        ),
    )
    parser.add_argument(
        "--profile",
        required=True,
        metavar="PATH",
        help="Path to the profile TOML file (e.g. profiles/claude-code.toml)",
    )
    parser.add_argument(
        "--json",
        dest="as_json",
        action="store_true",
        help="Print the parsed profile as JSON and exit",
    )
    args = parser.parse_args()

    try:
        profile = load_profile(args.profile)
    except FileNotFoundError:
        print(f"ERROR: profile file not found: {args.profile}", file=sys.stderr)
        return 1
    except tomllib.TOMLDecodeError as exc:
        print(f"ERROR: TOML parse error in {args.profile}: {exc}", file=sys.stderr)
        return 1

    if args.as_json:
        summary = {
            "name": profile.name,
            "root_dir": profile.root_dir,
            "root_file": profile.root_file,
            "agent_format": profile.agent_format,
            "tool_names": profile.tool_names,
            "model_tiers": {
                tier: (
                    {"model": v.model}
                    if isinstance(v, ModelTierSimple)
                    else {"model": v.model, "reasoning_effort": v.reasoning_effort}
                )
                for tier, v in profile.model_tiers.items()
            },
            "capabilities": {
                "hooks": profile.capabilities.hooks,
                "skill_chaining": profile.capabilities.skill_chaining,
                "background_execution": profile.capabilities.background_execution,
                "stop_hook_autocontinue": profile.capabilities.stop_hook_autocontinue,
            },
        }
        print(json.dumps(summary, indent=2, sort_keys=True))
        return 0

    errors = validate(profile)
    if errors:
        print(f"Validation FAILED for {args.profile} ({len(errors)} error(s)):", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"OK: {args.profile} -- profile {profile.name!r} is valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
# aid_profile.py -- AID canonical-generator profile parser
#
# Purpose:
#   Load a per-tool profile TOML and expose it as a typed Profile dataclass.
#   Run validate(profile) to surface schema problems before rendering begins.
#
#   Schema (shrunk from work-005 feature-002):
#     root_dir     = ".claude"   # host-required root basename
#     root_file    = "AGENTS.md" # shared agent-context entry point
#     skill_mirrors = [".claude/skills"] # optional tool-owned skill mirror
#     worktree_root = ".claude/worktrees" # optional per-tool worktree location
#     context_import = "CLAUDE.md" # optional host context import
#     rules_inline = false # optional host inline-rules fallback
#     agent_format = "markdown"  # "markdown" for 4 tools; "toml" dormant for Codex (E-CODEX-1)
#     [tool_names]               # surviving translation: Bash->Terminal (cursor), Bash->shell (copilot)
#     [model_tiers]              # feeds agent execution-metadata translation
#     [capabilities]             # 4 flags consumed by skills graceful-degradation
#     [hooks]                    # optional host hooks the installer places (claude-code only)
#       settings = ".claude/settings.json"  # host settings file, <root_dir>/settings.json
#       stop     = ["aid-question-form"]    # Stop-event handlers, names start with aid-
#
#   Generator emits only agents plus aid-tool.conf.
#
# Usage:
#   python aid_profile.py --profile profiles/claude-code.toml
#
# Requirements: Python 3.11+ (tomllib is stdlib)
from __future__ import annotations

import argparse
import copy
import json
import re
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
class HooksConfig:
    """[hooks] table: the host hooks the installer places in the host settings file."""
    settings: str | None = None
    stop: list[str] = field(default_factory=list)


@dataclass
class Profile:
    """
    Top-level profile dataclass (shrunk to the minimal copy-generator schema).

    Fields:
      name          -- derived from the filename stem (e.g. "claude-code")
      root_dir      -- host-required root basename (e.g. ".claude", ".cursor")
      root_file     -- shared root context filename (always "AGENTS.md")
      agent_format  -- "markdown" for 4 tools; "toml" dormant for Codex
      tool_names    -- the one surviving translate step (Bash->Terminal, Bash->shell)
      model_tiers   -- tier aliases to model strings (feeds frontmatter translate)
      capabilities  -- 4 capability flags (consumed by skills graceful-degradation)
      skill_mirrors -- optional tool-owned skill mirror paths
      worktree_root -- optional worktree directory
      context_import -- optional host context import
      rules_inline  -- whether to inline rules in root context
      hooks         -- optional [hooks] table (host settings path and Stop handlers)
    """
    name: str
    root_dir: str = ".claude"
    root_file: str = "AGENTS.md"
    agent_format: str = "markdown"
    tool_names: dict[str, str] = field(default_factory=dict)
    model_tiers: dict[str, ModelTierSimple | ModelTierDetailed] = field(default_factory=dict)
    capabilities: CapabilitiesConfig = field(default_factory=CapabilitiesConfig)
    skill_mirrors: list[str] = field(default_factory=list)
    worktree_root: str | None = None
    context_import: str | None = None
    rules_inline: bool = False
    hooks: HooksConfig = field(default_factory=HooksConfig)
    # Raw TOML dict preserved for lossless round-trip checks
    _raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)

    def common_parent(self) -> str:
        """Return this profile's output directory."""
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


def _parse_hooks(raw: Any) -> HooksConfig:
    if not isinstance(raw, dict):
        return HooksConfig(settings=None, stop=[])
    return HooksConfig(settings=raw.get("settings"), stop=raw.get("stop", []))


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
        root_file=raw.get("root_file", "AGENTS.md"),
        agent_format=raw.get("agent_format", "markdown"),
        tool_names=raw.get("tool_names", {}),
        model_tiers=_parse_model_tiers(raw.get("model_tiers", {})),
        capabilities=_parse_capabilities(raw.get("capabilities", {})),
        skill_mirrors=raw.get("skill_mirrors", []),
        worktree_root=raw.get("worktree_root"),
        context_import=raw.get("context_import"),
        rules_inline=raw.get("rules_inline", False),
        hooks=_parse_hooks(raw.get("hooks")),
        _raw=raw,
    )


# ---------------------------------------------------------------------------
# Validator
# ---------------------------------------------------------------------------

_KNOWN_TIERS = {"large", "medium", "small"}

# "toml" retained DORMANT for Codex (E-CODEX-1 not yet high-confidence).
# All other format branches (copilot-agent, antigravity-rule) deleted per task-005.
_KNOWN_AGENT_FORMATS = {"markdown", "toml"}


_HOOK_NAME_RE = re.compile(r"aid-[a-z0-9]+(-[a-z0-9]+)*")
# Only these profiles may declare [hooks] for now; the other hook-capable hosts follow later.
_HOOK_PROFILES = frozenset({"claude-code"})


def _validate_hooks(profile: "Profile") -> list[str]:
    """Validate the optional [hooks] table (empty list means valid)."""
    name = profile.name
    hooks = profile.hooks
    errors: list[str] = []
    if not isinstance(hooks, HooksConfig):
        return [f"[{name}] hooks must be a table"]
    if not isinstance(hooks.stop, list):
        return [f"[{name}] [hooks].stop must be a list"]
    if hooks.settings is None and not hooks.stop:
        return errors
    if name not in _HOOK_PROFILES:
        errors.append(f"[{name}] [hooks] is declared for claude-code only")
    if not profile.capabilities.hooks:
        errors.append(f"[{name}] [hooks] needs capabilities.hooks = true")
    root = profile.root_dir.rstrip("/")
    if not isinstance(hooks.settings, str) or not hooks.settings:
        errors.append(f"[{name}] [hooks].settings is required when hooks are declared")
    elif hooks.settings != f"{root}/settings.json":
        errors.append(f"[{name}] [hooks].settings must be {root}/settings.json: {hooks.settings!r}")
    if not hooks.stop:
        errors.append(f"[{name}] [hooks].stop must name at least one hook when settings is declared")
    seen: set[str] = set()
    for hook in hooks.stop:
        if not isinstance(hook, str) or not _HOOK_NAME_RE.fullmatch(hook):
            errors.append(f"[{name}] [hooks].stop entry must match aid-<name> (lower-case, digits, hyphens): {hook!r}")
        elif hook in seen:
            errors.append(f"[{name}] [hooks].stop names {hook!r} twice")
        else:
            seen.add(hook)
    return errors


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

    if profile.root_file != "AGENTS.md":
        errors.append(f'[{name}] root_file must be "AGENTS.md"')

    # Optional descriptor values have a deliberately small, portable grammar.
    if not isinstance(profile.skill_mirrors, list):
        errors.append(f"[{name}] skill_mirrors must be a list")
    else:
        for mirror in profile.skill_mirrors:
            if not isinstance(mirror, str) or not re.fullmatch(r"\.[a-z]+/skills", mirror):
                errors.append(f"[{name}] skill_mirrors entry must match ^\\.[a-z]+/skills$: {mirror!r}")
            elif mirror == ".agents/skills":
                errors.append(f"[{name}] skill_mirrors must not include .agents/skills")
            elif not mirror.startswith(profile.root_dir.rstrip("/") + "/"):
                errors.append(f"[{name}] skill_mirrors entry must sit under {profile.root_dir}: {mirror!r}")

    if profile.worktree_root is not None:
        value = profile.worktree_root
        valid = value == ".aid/.worktrees" or value == f"{profile.root_dir.rstrip('/')}/worktrees"
        if not isinstance(value, str) or not value or value.startswith("/") or ".." in value.split("/") or not valid:
            errors.append(f"[{name}] worktree_root must be .aid/.worktrees or <root_dir>/worktrees, relative and without ..: {value!r}")

    if profile.context_import is not None and profile.context_import != "CLAUDE.md":
        errors.append(f"[{name}] context_import accepts only CLAUDE.md")

    if not isinstance(profile.rules_inline, bool):
        errors.append(f"[{name}] rules_inline must be a boolean")

    errors.extend(_validate_hooks(profile))

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
        metavar="PATH",
        help="Path to the profile TOML file (e.g. profiles/claude-code.toml)",
    )
    parser.add_argument("--self-test", action="store_true", help="Run focused validation checks")
    parser.add_argument(
        "--json",
        dest="as_json",
        action="store_true",
        help="Print the parsed profile as JSON and exit",
    )
    args = parser.parse_args()

    if args.self_test:
        profile = Profile(name="self-test", root_dir=".claude", model_tiers={"medium": ModelTierSimple("test")})
        invalid_mirror = copy.deepcopy(profile)
        invalid_mirror.skill_mirrors = [".agents/skills"]
        if not any("must not include .agents/skills" in error for error in validate(invalid_mirror)):
            print("FAIL: skill_mirrors accepted .agents/skills", file=sys.stderr)
            return 1
        invalid_inline = copy.deepcopy(profile)
        invalid_inline.rules_inline = "true"
        if not any("rules_inline must be a boolean" in error for error in validate(invalid_inline)):
            print("FAIL: rules_inline accepted a string", file=sys.stderr)
            return 1
        valid_hooks = copy.deepcopy(profile)
        valid_hooks.name = "claude-code"
        valid_hooks.capabilities = CapabilitiesConfig(hooks=True)
        valid_hooks.hooks = HooksConfig(settings=".claude/settings.json", stop=["aid-question-form"])
        if validate(valid_hooks):
            print("FAIL: a valid [hooks] table was refused", file=sys.stderr)
            return 1
        bad_hooks = (
            (HooksConfig(settings=".claude/other.json", stop=["aid-question-form"]), "must be .claude/settings.json"),
            (HooksConfig(settings=".claude/settings.json", stop=["question-form"]), "must match aid-<name>"),
            (HooksConfig(settings=".claude/settings.json", stop=[]), "must name at least one hook"),
        )
        for hooks, expect in bad_hooks:
            bad = copy.deepcopy(valid_hooks)
            bad.hooks = hooks
            if not any(expect in error for error in validate(bad)):
                print(f"FAIL: [hooks] check missing: {expect}", file=sys.stderr)
                return 1
        no_cap = copy.deepcopy(valid_hooks)
        no_cap.capabilities = CapabilitiesConfig(hooks=False)
        if not any("needs capabilities.hooks" in error for error in validate(no_cap)):
            print("FAIL: [hooks] accepted capabilities.hooks = false", file=sys.stderr)
            return 1
        other = copy.deepcopy(valid_hooks)
        other.name = "cursor"
        if not any("claude-code only" in error for error in validate(other)):
            print("FAIL: [hooks] accepted a profile other than claude-code", file=sys.stderr)
            return 1
        print("OK: aid_profile validation self-tests passed (7 checks)")
        return 0

    if not args.profile:
        parser.error("--profile is required unless --self-test is used")

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
            "hooks": {"settings": profile.hooks.settings, "stop": profile.hooks.stop},
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

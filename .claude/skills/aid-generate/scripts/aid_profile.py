#!/usr/bin/env python3
# aid_profile.py — AID canonical-generator profile parser
#
# Purpose:
#   Load a per-tool profile TOML and expose it as a typed Profile dataclass.
#   Run `validate(profile)` to surface schema problems before rendering begins.
#
# Usage:
#   python aid_profile.py --profile profiles/claude-code.toml
#   python -c "from aid_profile import load_profile, validate; p = load_profile('profiles/claude-code.toml'); print(validate(p))"
#
# Requirements: Python 3.11+ (tomllib is stdlib from 3.11)
from __future__ import annotations

import argparse
import json
import sys
import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Dataclasses mirroring the TOML schema
# ---------------------------------------------------------------------------

@dataclass
class LayoutConfig:
    """[layout] table — where rendered files go."""
    # Single-root tools (Claude Code, Cursor)
    output_root: str | None = None
    # Split-root tool (Codex)
    agents_root: str | None = None
    assets_root: str | None = None
    # Sub-directory names (relative to their root)
    agents_dir: str = "agents"
    skills_dir: str = "skills"
    templates_dir: str = "templates"
    recipes_dir: str = "recipes"
    scripts_dir: str = "scripts"
    # Cursor-specific
    rules_dir: str | None = None
    # Repo-root file name for the project-context document
    project_context_file: str = "CLAUDE.md"

    def install_root(self) -> str:
        """
        Return the install-root path adopters see from their project root.

        This is the basename of the directory where renderer output lands
        (e.g., ``.claude`` for Claude Code, ``.agents`` for Codex assets,
        ``.cursor`` for Cursor). Skill bodies that reference
        ``canonical/scripts/...`` or ``canonical/templates/...`` get rewritten
        to ``<install_root>/scripts/...`` / ``<install_root>/templates/...``
        so they resolve in any adopter project (not just the dogfood repo).

        For Codex's split layout, returns the *assets_root* basename
        (``.agents``) since scripts + templates + skills all live there;
        ``.codex`` only holds agent TOMLs and has no scripts/.

        Examples
        --------
        - Claude Code: ``output_root="profiles/claude-code/.claude"`` → ``".claude"``
        - Codex split: ``assets_root="profiles/codex/.agents"`` → ``".agents"``
        - Cursor: ``output_root="profiles/cursor/.cursor"`` → ``".cursor"``
        """
        from pathlib import PurePosixPath

        target = self.assets_root if self.assets_root is not None else self.output_root
        if target is None:
            raise ValueError(
                "LayoutConfig has neither assets_root nor output_root — cannot determine install_root"
            )
        return PurePosixPath(target).name

    def common_parent(self) -> str:
        """
        Return the deepest common parent directory of the profile's output roots.

        This is the directory where ``emission-manifest.jsonl`` is placed
        (per EMISSION-MANIFEST.md §"Filename and Location").

        Examples
        --------
        - Claude Code: ``output_root="profiles/claude-code/.claude"`` → ``"profiles/claude-code"``
        - Codex split: ``agents_root="profiles/codex/.codex"`` → ``"profiles/codex"``
        - Cursor: ``output_root="profiles/cursor/.cursor"`` → ``"profiles/cursor"``

        Raises
        ------
        ValueError
            If neither ``output_root`` nor ``agents_root`` is set (invalid layout).
        """
        from pathlib import PurePosixPath

        if self.output_root is not None:
            parent = str(PurePosixPath(self.output_root).parent)
            return "." if parent == "." else parent
        if self.agents_root is not None:
            parent = str(PurePosixPath(self.agents_root).parent)
            return "." if parent == "." else parent
        raise ValueError(
            "LayoutConfig has neither output_root nor agents_root — cannot determine common_parent"
        )


@dataclass
class FrontmatterConfig:
    """[agent.frontmatter] or [skill.frontmatter] table."""
    required: list[str] = field(default_factory=list)
    optional: list[str] = field(default_factory=list)
    # Claude Code-specific optional fields injected by the renderer
    claude_code_optional: list[str] = field(default_factory=list)


@dataclass
class AgentConfig:
    """[agent] table."""
    format: str = "markdown"  # "markdown" | "toml"
    frontmatter: FrontmatterConfig = field(default_factory=FrontmatterConfig)


@dataclass
class SkillConfig:
    """[skill] table."""
    decomposition: str = "references"  # always "references" per Decision F
    frontmatter: FrontmatterConfig = field(default_factory=FrontmatterConfig)


@dataclass
class ModelTierSimple:
    """Single string value for a tier (Claude Code / Cursor style)."""
    model: str


@dataclass
class ModelTierDetailed:
    """Sub-table value for a tier with model + reasoning_effort (Codex style)."""
    model: str
    reasoning_effort: str


@dataclass
class RuleEntry:
    """One [[extras.rules]] entry (Cursor/Antigravity)."""
    filename: str
    always_apply: bool
    description: str = ""
    globs: list[str] = field(default_factory=list)
    # Optional output filename override (task-012 / feature-003-antigravity / Q-I):
    # When set, _render_cursor_extras writes the source (rule.filename) to the
    # output path named rule.output_filename — enabling .mdc → .md renames for
    # Antigravity (Q-I: Antigravity uses .md, not .mdc; source stays .mdc).
    # Default None → source name preserved, so cursor is byte-identical.
    output_filename: str | None = None


@dataclass
class ExtrasConfig:
    """[extras] table."""
    rules: list[RuleEntry] = field(default_factory=list)


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
    Top-level profile dataclass.  All data from a single *.toml profile file.

    model_tiers is typed as dict[str, ModelTierSimple | ModelTierDetailed]
    to accommodate both:
      [model_tiers]           (Claude Code / Cursor — simple string values)
      large = "opus"
    and:
      [model_tiers.large]     (Codex — sub-tables with model + reasoning_effort)
      model = "gpt-5.5"
      reasoning_effort = "high"
    """
    name: str  # derived from the filename stem
    layout: LayoutConfig = field(default_factory=LayoutConfig)
    agent: AgentConfig = field(default_factory=AgentConfig)
    skill: SkillConfig = field(default_factory=SkillConfig)
    model_tiers: dict[str, ModelTierSimple | ModelTierDetailed] = field(default_factory=dict)
    tool_names: dict[str, str] = field(default_factory=dict)
    filename_map: dict[str, str] = field(default_factory=dict)
    extras: ExtrasConfig = field(default_factory=ExtrasConfig)
    capabilities: CapabilitiesConfig = field(default_factory=CapabilitiesConfig)
    # Raw TOML dict preserved for lossless round-trip checks
    _raw: dict[str, Any] = field(default_factory=dict, repr=False, compare=False)


# ---------------------------------------------------------------------------
# Loader
# ---------------------------------------------------------------------------

def _parse_layout(raw: dict[str, Any]) -> LayoutConfig:
    return LayoutConfig(
        output_root=raw.get("output_root"),
        agents_root=raw.get("agents_root"),
        assets_root=raw.get("assets_root"),
        agents_dir=raw.get("agents_dir", "agents"),
        skills_dir=raw.get("skills_dir", "skills"),
        templates_dir=raw.get("templates_dir", "templates"),
        recipes_dir=raw.get("recipes_dir", "recipes"),
        rules_dir=raw.get("rules_dir"),
        project_context_file=raw.get("project_context_file", "CLAUDE.md"),
    )


def _parse_frontmatter(raw: dict[str, Any]) -> FrontmatterConfig:
    return FrontmatterConfig(
        required=raw.get("required", []),
        optional=raw.get("optional", []),
        claude_code_optional=raw.get("claude_code_optional", []),
    )


def _parse_agent(raw: dict[str, Any]) -> AgentConfig:
    fm_raw = raw.get("frontmatter", {})
    return AgentConfig(
        format=raw.get("format", "markdown"),
        frontmatter=_parse_frontmatter(fm_raw),
    )


def _parse_skill(raw: dict[str, Any]) -> SkillConfig:
    fm_raw = raw.get("frontmatter", {})
    return SkillConfig(
        decomposition=raw.get("decomposition", "references"),
        frontmatter=_parse_frontmatter(fm_raw),
    )


def _parse_model_tiers(raw: dict[str, Any]) -> dict[str, ModelTierSimple | ModelTierDetailed]:
    """
    Handle both:
      large = "opus"           → ModelTierSimple("opus")
      [large]
        model = "gpt-5.5"     → ModelTierDetailed("gpt-5.5", "high")
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
        # else: unexpected type — validation will catch it
    return result


def _parse_extras(raw: dict[str, Any]) -> ExtrasConfig:
    rules_raw = raw.get("rules", [])
    rules = [
        RuleEntry(
            filename=r.get("filename", ""),
            always_apply=r.get("always_apply", False),
            description=r.get("description", ""),
            globs=r.get("globs", []),
            output_filename=r.get("output_filename"),  # None when absent → cursor byte-identical
        )
        for r in rules_raw
    ]
    return ExtrasConfig(rules=rules)


def _parse_capabilities(raw: dict[str, Any]) -> CapabilitiesConfig:
    return CapabilitiesConfig(
        hooks=raw.get("hooks", False),
        skill_chaining=raw.get("skill_chaining", True),
        background_execution=raw.get("background_execution", False),
        stop_hook_autocontinue=raw.get("stop_hook_autocontinue", False),
    )


def load_profile(path: str) -> Profile:
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
        layout=_parse_layout(raw.get("layout", {})),
        agent=_parse_agent(raw.get("agent", {})),
        skill=_parse_skill(raw.get("skill", {})),
        model_tiers=_parse_model_tiers(raw.get("model_tiers", {})),
        tool_names=raw.get("tool_names", {}),
        filename_map=raw.get("filename_map", {}),
        extras=_parse_extras(raw.get("extras", {})),
        capabilities=_parse_capabilities(raw.get("capabilities", {})),
        _raw=raw,
    )


# ---------------------------------------------------------------------------
# Validator
# ---------------------------------------------------------------------------

_CANONICAL_FILENAME_MAP_KEYS = {
    "project_context_file",
    "reviewer_output_file",
    "open_questions_file",
}

_KNOWN_TIERS = {"large", "medium", "small"}

# "copilot-agent" added by task-005 (feature-002-copilot-cli / delivery-002):
#   Registers the E1 agent-format value so the validator accepts
#   `[agent].format = "copilot-agent"` in profiles/copilot-cli.toml.
#   E2 ([skill].emit_as knob) is NOT added — skills are native Agent Skills,
#   emitted as folders by the existing render_skills pass (FR1 Q-A ruling).
#   E3 (MCP table / mcp-config.json) is NOT added — AID ships no MCP servers;
#   grep -ri mcp canonical/ profiles/*.toml returns zero matches (FR1 Q-B ruling).
#   Both omissions are intentional and sourced to provider-mapping.md Q-A / Q-B.
# "antigravity-rule" added by task-012 (feature-003-antigravity / delivery-003):
#   Registers the sub-agents→.agent/rules/ reshape format so the validator accepts
#   `[agent].format = "antigravity-rule"` in profiles/antigravity.toml.
#   This reuses feature-002's E1 new-agent-format-branch mechanism; it is a second
#   branch on the same dispatch (NOT a reuse of copilot-agent output, NOT the deleted
#   E2). Source: SPEC §"Renderer Increment" + provider-mapping.md Q-D.
_KNOWN_AGENT_FORMATS = {"markdown", "toml", "copilot-agent", "antigravity-rule"}

_KNOWN_DECOMPOSITIONS = {"references"}


def validate(profile: Profile) -> list[str]:
    """
    Validate a loaded Profile and return a list of error strings.
    An empty list means the profile is valid.

    Parameters
    ----------
    profile : Profile
        The profile to validate.

    Returns
    -------
    list[str]
        Zero or more human-readable error messages.
    """
    errors: list[str] = []
    name = profile.name

    # -----------------------------------------------------------------------
    # Layout checks
    # -----------------------------------------------------------------------
    layout = profile.layout
    has_output_root = layout.output_root is not None
    has_split_roots = layout.agents_root is not None or layout.assets_root is not None

    if not has_output_root and not has_split_roots:
        errors.append(
            f"[{name}] [layout] must declare either output_root or "
            f"(agents_root + assets_root)"
        )
    if has_output_root and has_split_roots:
        errors.append(
            f"[{name}] [layout] cannot declare both output_root and "
            f"agents_root/assets_root — choose one layout style"
        )
    if has_split_roots:
        if layout.agents_root is None:
            errors.append(f"[{name}] [layout] agents_root missing (required with assets_root)")
        if layout.assets_root is None:
            errors.append(f"[{name}] [layout] assets_root missing (required with agents_root)")

    # Paths must be relative (no leading /)
    for field_name, value in [
        ("output_root", layout.output_root),
        ("agents_root", layout.agents_root),
        ("assets_root", layout.assets_root),
    ]:
        if value is not None and (value.startswith("/") or value.startswith("\\")):
            errors.append(
                f"[{name}] [layout].{field_name} must be a relative path, got: {value!r}"
            )

    # -----------------------------------------------------------------------
    # Agent format check
    # -----------------------------------------------------------------------
    if profile.agent.format not in _KNOWN_AGENT_FORMATS:
        errors.append(
            f"[{name}] [agent].format must be one of {sorted(_KNOWN_AGENT_FORMATS)}, "
            f"got: {profile.agent.format!r}"
        )

    # -----------------------------------------------------------------------
    # Skill decomposition check
    # -----------------------------------------------------------------------
    if profile.skill.decomposition not in _KNOWN_DECOMPOSITIONS:
        errors.append(
            f"[{name}] [skill].decomposition must be one of {sorted(_KNOWN_DECOMPOSITIONS)}, "
            f"got: {profile.skill.decomposition!r}"
        )

    # -----------------------------------------------------------------------
    # Model-tier checks
    # -----------------------------------------------------------------------
    if not profile.model_tiers:
        errors.append(f"[{name}] [model_tiers] is empty — at least one tier alias required")
    else:
        for tier_name, tier_val in profile.model_tiers.items():
            if tier_name not in _KNOWN_TIERS:
                errors.append(
                    f"[{name}] [model_tiers] unknown tier {tier_name!r} — "
                    f"expected one of {sorted(_KNOWN_TIERS)}"
                )
            if isinstance(tier_val, ModelTierSimple):
                if not tier_val.model:
                    errors.append(
                        f"[{name}] [model_tiers].{tier_name} is empty string"
                    )
            elif isinstance(tier_val, ModelTierDetailed):
                if not tier_val.model:
                    errors.append(
                        f"[{name}] [model_tiers.{tier_name}].model is empty"
                    )
                if not tier_val.reasoning_effort:
                    errors.append(
                        f"[{name}] [model_tiers.{tier_name}].reasoning_effort is empty"
                    )

    # -----------------------------------------------------------------------
    # filename_map checks
    # -----------------------------------------------------------------------
    missing_keys = _CANONICAL_FILENAME_MAP_KEYS - set(profile.filename_map.keys())
    if missing_keys:
        errors.append(
            f"[{name}] [filename_map] missing required keys: {sorted(missing_keys)}"
        )
    for key, value in profile.filename_map.items():
        if not value:
            errors.append(f"[{name}] [filename_map].{key} is empty")

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
        help="Print the parsed profile as JSON and exit (structural fields only)",
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
        # Emit structural fields as JSON (for round-trip / spot-check use)
        summary = {
            "name": profile.name,
            "layout": {
                "output_root": profile.layout.output_root,
                "agents_root": profile.layout.agents_root,
                "assets_root": profile.layout.assets_root,
                "agents_dir": profile.layout.agents_dir,
                "skills_dir": profile.layout.skills_dir,
                "templates_dir": profile.layout.templates_dir,
                "recipes_dir": profile.layout.recipes_dir,
                "rules_dir": profile.layout.rules_dir,
                "project_context_file": profile.layout.project_context_file,
            },
            "agent": {
                "format": profile.agent.format,
            },
            "skill": {
                "decomposition": profile.skill.decomposition,
            },
            "model_tiers": {
                tier: (
                    {"model": v.model}
                    if isinstance(v, ModelTierSimple)
                    else {"model": v.model, "reasoning_effort": v.reasoning_effort}
                )
                for tier, v in profile.model_tiers.items()
            },
            "tool_names": profile.tool_names,
            "filename_map": profile.filename_map,
            "extras": {
                "rules": [
                    {
                        "filename": r.filename,
                        "always_apply": r.always_apply,
                        "description": r.description,
                        "globs": r.globs,
                    }
                    for r in profile.extras.rules
                ]
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

    print(f"OK: {args.profile} — profile {profile.name!r} is valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())

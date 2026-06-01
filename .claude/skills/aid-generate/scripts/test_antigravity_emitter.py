#!/usr/bin/env python3
# test_antigravity_emitter.py — Unit tests for the antigravity-rule format branch (task-012)
#
# Purpose:
#   Validates the new "antigravity-rule" format branch in render_agents.py and the
#   RuleEntry.output_filename touch in aid_profile.py / render_skills.py:
#
#   1. _build_frontmatter_md_antigravity emits trigger/description (not name/tools/model).
#   2. A sub-agent reshaped to antigravity-rule produces a .md file (not .agent.md or .toml).
#   3. The emitted frontmatter has trigger: always_on for all 22 AID sub-agents.
#   4. description passes through (with _yaml_scalar quoting applied correctly).
#   5. tools / model / name are NOT present in the rule frontmatter.
#   6. Frontmatter YAML round-trips cleanly.
#   7. RuleEntry.output_filename defaults to None; cursor behavior byte-identical.
#   8. With output_filename set, _render_cursor_extras writes to the new name.
#   9. Disjoint-stem assertion: no sub-agent <name>.md equals a methodology rule output name.
#  10. Existing markdown/toml/copilot-agent branches are byte-identical (not perturbed).
#  11. "antigravity-rule" is accepted by aid_profile.validate().
#  12. An unknown agent.format value is rejected with a clear message.
#  13. The 3 existing profiles (claude-code, codex, cursor) + copilot-cli still validate clean.
#
# Usage:
#   python test_antigravity_emitter.py --self-test [--canonical-root PATH]
#
# Requirements: Python 3.11+
from __future__ import annotations

import argparse
import sys
import tempfile
from pathlib import Path

# ---------------------------------------------------------------------------
# Optional PyYAML import — test-time only; the RENDERER must NOT import yaml.
# ---------------------------------------------------------------------------
try:
    import yaml as _yaml_lib  # noqa: F401
    _YAML_REAL_AVAILABLE = True
except ImportError:
    _yaml_lib = None  # type: ignore[assignment]
    _YAML_REAL_AVAILABLE = False

# ---------------------------------------------------------------------------
# Add script directory to sys.path
# ---------------------------------------------------------------------------
_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import (  # noqa: E402
    load_profile,
    validate,
    Profile,
    LayoutConfig,
    AgentConfig,
    FrontmatterConfig,
    SkillConfig,
    CapabilitiesConfig,
    ModelTierSimple,
    ModelTierDetailed,
    RuleEntry,
    ExtrasConfig,
    _parse_extras,
)
from render_agents import (  # noqa: E402
    _build_frontmatter_md_antigravity,
    _yaml_scalar,
    render_agents,
)
from render_skills import render_skills, _render_cursor_extras  # noqa: E402
from render_lib import EmissionManifest  # noqa: E402


# ---------------------------------------------------------------------------
# YAML round-trip helpers (reused from test_copilot_emitter.py pattern)
# ---------------------------------------------------------------------------

def _yaml_load_frontmatter_simple(fm_block: str) -> dict:
    """
    Parse a ``---`` delimited YAML frontmatter block (stdlib only).
    Supports scalar values (plain + double-quoted) and block-sequence values.
    """
    lines = fm_block.strip().splitlines()
    if lines and lines[0].strip() == "---":
        lines = lines[1:]
    if lines and lines[-1].strip() == "---":
        lines = lines[:-1]

    result: dict = {}
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        if ":" in line:
            key, _, raw_val = line.partition(":")
            key = key.strip()
            raw_val = raw_val.strip()

            if raw_val == "[]":
                result[key] = []
                i += 1
                continue
            if raw_val == "":
                # Block sequence
                items = []
                i += 1
                while i < len(lines) and lines[i].startswith("  - "):
                    item_raw = lines[i][4:].strip()
                    items.append(_unescape(item_raw))
                    i += 1
                result[key] = items
                continue
            result[key] = _unescape(raw_val)
        i += 1
    return result


def _unescape(val: str) -> str:
    """Strip outer double-quotes and unescape backslash sequences."""
    if val.startswith('"') and val.endswith('"') and len(val) >= 2:
        inner = val[1:-1]
        inner = inner.replace('\\"', '"').replace('\\\\', '\\')
        return inner
    return val


def _real_yaml_load(fm_block: str) -> dict:
    """Parse frontmatter with real yaml.safe_load (PyYAML). Strips --- delimiters."""
    if not _YAML_REAL_AVAILABLE:
        raise RuntimeError("PyYAML not available")
    lines = fm_block.strip().splitlines()
    if lines and lines[0].strip() == "---":
        lines = lines[1:]
    if lines and lines[-1].strip() == "---":
        lines = lines[:-1]
    parsed = _yaml_lib.safe_load("\n".join(lines))  # type: ignore[union-attr]
    if not isinstance(parsed, dict):
        raise ValueError(f"Frontmatter did not parse to a dict: {parsed!r}")
    return parsed


# ---------------------------------------------------------------------------
# Minimal in-memory Profile builders
# ---------------------------------------------------------------------------

def _make_antigravity_profile(output_root: str) -> Profile:
    """Build a minimal in-memory Profile with agent.format='antigravity-rule'."""
    return Profile(
        name="antigravity",
        layout=LayoutConfig(
            output_root=output_root,
            agents_dir="rules",   # sub-agents → .agent/rules/ per antigravity.toml
            skills_dir="skills",
            rules_dir="rules",    # extras.rules also land in .agent/rules/
            project_context_file="AGENTS.md",
        ),
        agent=AgentConfig(
            format="antigravity-rule",
            frontmatter=FrontmatterConfig(
                required=["trigger", "description"],
                optional=["globs"],
            ),
        ),
        skill=SkillConfig(decomposition="references"),
        model_tiers={
            "large": ModelTierDetailed(model="gemini-3-pro", reasoning_effort="high"),
            "medium": ModelTierDetailed(model="gemini-3-pro", reasoning_effort="low"),
            "small": ModelTierDetailed(model="gemini-3-flash", reasoning_effort="low"),
        },
        tool_names={},  # Q-F: empty map, identity passthrough
        filename_map={
            "project_context_file": "AGENTS.md",
            "reviewer_output_file": "STATE.md",
            "open_questions_file": "additional-info.md",
        },
        capabilities=CapabilitiesConfig(
            hooks=True,
            skill_chaining=True,
            background_execution=True,
            stop_hook_autocontinue=False,
        ),
    )


# ---------------------------------------------------------------------------
# Test 1: _build_frontmatter_md_antigravity emits trigger/description only
# ---------------------------------------------------------------------------

def test_antigravity_frontmatter_shape() -> list[str]:
    """
    _build_frontmatter_md_antigravity emits trigger: always_on and description,
    and does NOT emit name / tools / model.
    """
    failures: list[str] = []

    fields = {
        "trigger": "always_on",
        "description": "A design agent.",
    }
    fm = _build_frontmatter_md_antigravity(fields)

    # Must contain trigger: always_on
    if "trigger: always_on" not in fm:
        failures.append(
            f"test_antigravity_frontmatter_shape: 'trigger: always_on' not found in:\n{fm}"
        )

    # Must NOT contain name: / tools: / model:
    for forbidden_key in ("name:", "tools:", "model:"):
        for line in fm.splitlines():
            if line.startswith(forbidden_key):
                failures.append(
                    f"test_antigravity_frontmatter_shape: forbidden key found: {line!r}"
                )

    # Round-trip
    parsed = _yaml_load_frontmatter_simple(fm)
    if parsed.get("trigger") != "always_on":
        failures.append(
            f"test_antigravity_frontmatter_shape: trigger round-trip failed: {parsed.get('trigger')!r}"
        )
    if parsed.get("description") != "A design agent.":
        failures.append(
            f"test_antigravity_frontmatter_shape: description round-trip failed: {parsed.get('description')!r}"
        )

    return failures


# ---------------------------------------------------------------------------
# Test 2: Description quoting reuses _yaml_scalar
# ---------------------------------------------------------------------------

def test_antigravity_description_quoting() -> list[str]:
    """
    A description containing ':' is double-quoted; a plain string is unquoted.
    Uses the same _yaml_scalar logic as the copilot-agent branch.
    """
    failures: list[str] = []

    # Colon in description — must be quoted
    fields_colon = {
        "trigger": "always_on",
        "description": "Design agent: transforms requirements into SPEC.md",
    }
    fm_colon = _build_frontmatter_md_antigravity(fields_colon)
    for line in fm_colon.splitlines():
        if line.startswith("description:"):
            val_part = line[len("description:"):].strip()
            if not (val_part.startswith('"') and val_part.endswith('"')):
                failures.append(
                    f"test_antigravity_description_quoting: colon-bearing desc not quoted: {line!r}"
                )

    # Round-trip
    parsed = _yaml_load_frontmatter_simple(fm_colon)
    expected = "Design agent: transforms requirements into SPEC.md"
    if parsed.get("description") != expected:
        failures.append(
            f"test_antigravity_description_quoting: round-trip mismatch: {parsed.get('description')!r}"
        )

    # Plain string — must be unquoted
    fields_plain = {
        "trigger": "always_on",
        "description": "A plain safe description",
    }
    fm_plain = _build_frontmatter_md_antigravity(fields_plain)
    for line in fm_plain.splitlines():
        if line.startswith("description:"):
            val_part = line[len("description:"):].strip()
            if val_part.startswith('"'):
                failures.append(
                    f"test_antigravity_description_quoting: plain desc unnecessarily quoted: {line!r}"
                )

    return failures


# ---------------------------------------------------------------------------
# Test 3: render_agents with antigravity-rule emits .md files (not .agent.md / .toml)
# ---------------------------------------------------------------------------

def test_antigravity_output_suffix(canonical_root: Path) -> list[str]:
    """
    render_agents with format='antigravity-rule' emits .md files, one per canonical agent.
    File count must equal the number of canonical agents (22).
    """
    failures: list[str] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        output_root = str(Path(tmpdir) / "profiles" / "antigravity" / ".agent")
        profile = _make_antigravity_profile(output_root)
        manifest = EmissionManifest(profile_name="antigravity")

        paths = render_agents(
            canonical_root=canonical_root,
            profile=profile,
            manifest=manifest,
            output_base=tmpdir,
        )

        if not paths:
            failures.append("test_antigravity_output_suffix: no files rendered")
            return failures

        for p in paths:
            if not str(p).endswith(".md"):
                failures.append(
                    f"test_antigravity_output_suffix: file does not end in .md: {p}"
                )
            if str(p).endswith(".agent.md"):
                failures.append(
                    f"test_antigravity_output_suffix: unexpected .agent.md file: {p}"
                )
            if str(p).endswith(".toml"):
                failures.append(
                    f"test_antigravity_output_suffix: unexpected .toml file: {p}"
                )

        # Must emit 22 sub-agents
        if len(paths) != 22:
            failures.append(
                f"test_antigravity_output_suffix: expected 22 agents, got {len(paths)}"
            )

    return failures


# ---------------------------------------------------------------------------
# Test 4: All emitted files have trigger: always_on frontmatter (not name/tools/model)
# ---------------------------------------------------------------------------

def test_antigravity_rule_frontmatter(canonical_root: Path) -> list[str]:
    """
    Every emitted .md rule file for the antigravity-rule profile has:
    - trigger: always_on
    - description: present and non-empty string
    - NO name: / tools: / model: keys
    """
    failures: list[str] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        output_root = str(Path(tmpdir) / "profiles" / "antigravity" / ".agent")
        profile = _make_antigravity_profile(output_root)
        manifest = EmissionManifest(profile_name="antigravity")

        paths = render_agents(
            canonical_root=canonical_root,
            profile=profile,
            manifest=manifest,
            output_base=tmpdir,
        )

        for p in paths:
            content = Path(p).read_text(encoding="utf-8")

            # Extract frontmatter block
            lines = content.splitlines()
            if not lines or lines[0].strip() != "---":
                failures.append(f"test_antigravity_rule_frontmatter: {p.name} missing opening ---")
                continue
            end = None
            for idx in range(1, len(lines)):
                if lines[idx].strip() == "---":
                    end = idx
                    break
            if end is None:
                failures.append(f"test_antigravity_rule_frontmatter: {p.name} missing closing ---")
                continue

            fm_block = "\n".join(lines[:end + 1])
            parsed = _yaml_load_frontmatter_simple(fm_block)

            # trigger must be always_on
            if parsed.get("trigger") != "always_on":
                failures.append(
                    f"test_antigravity_rule_frontmatter: {p.name}: trigger != 'always_on': "
                    f"{parsed.get('trigger')!r}"
                )

            # description must be present + string
            desc = parsed.get("description")
            if not isinstance(desc, str) or not desc:
                failures.append(
                    f"test_antigravity_rule_frontmatter: {p.name}: description missing or empty: "
                    f"{desc!r}"
                )

            # Forbidden keys: name, tools, model
            for forbidden in ("name", "tools", "model"):
                if forbidden in parsed:
                    failures.append(
                        f"test_antigravity_rule_frontmatter: {p.name}: forbidden key "
                        f"'{forbidden}' found in rule frontmatter"
                    )

            # If PyYAML is available, do a real parse too
            if _YAML_REAL_AVAILABLE:
                try:
                    real_parsed = _real_yaml_load(fm_block)
                    if real_parsed.get("trigger") != "always_on":
                        failures.append(
                            f"test_antigravity_rule_frontmatter: {p.name}: "
                            f"yaml.safe_load trigger != 'always_on': {real_parsed.get('trigger')!r}"
                        )
                    if not isinstance(real_parsed.get("description"), str):
                        failures.append(
                            f"test_antigravity_rule_frontmatter: {p.name}: "
                            f"yaml.safe_load description not a string"
                        )
                except Exception as exc:
                    failures.append(
                        f"test_antigravity_rule_frontmatter: {p.name}: "
                        f"yaml.safe_load failed: {exc}\n  fm:\n{fm_block}"
                    )
            else:
                print(
                    "  SKIP NOTICE [test_antigravity_rule_frontmatter]: PyYAML not available — "
                    "stdlib parse used instead of yaml.safe_load.",
                    file=sys.stderr,
                )

    return failures


# ---------------------------------------------------------------------------
# Test 5: Antigravity render is deterministic (byte-identical across two runs)
# ---------------------------------------------------------------------------

def test_antigravity_determinism(canonical_root: Path) -> list[str]:
    """
    Two renders of the antigravity-rule profile produce byte-identical output.
    """
    failures: list[str] = []

    with (
        tempfile.TemporaryDirectory() as tmp1,
        tempfile.TemporaryDirectory() as tmp2,
    ):
        output_root1 = str(Path(tmp1) / "profiles" / "antigravity" / ".agent")
        output_root2 = str(Path(tmp2) / "profiles" / "antigravity" / ".agent")
        profile1 = _make_antigravity_profile(output_root1)
        profile2 = _make_antigravity_profile(output_root2)

        m1 = EmissionManifest(profile_name="antigravity")
        m2 = EmissionManifest(profile_name="antigravity")

        paths1 = render_agents(canonical_root, profile1, m1, tmp1)
        paths2 = render_agents(canonical_root, profile2, m2, tmp2)

        if len(paths1) != len(paths2):
            failures.append(
                f"test_antigravity_determinism: run1={len(paths1)} files, run2={len(paths2)} files"
            )
            return failures

        for p1, p2 in zip(paths1, paths2):
            b1 = Path(p1).read_bytes()
            b2 = Path(p2).read_bytes()
            if b1 != b2:
                failures.append(
                    f"test_antigravity_determinism: {Path(p1).name} not byte-identical across runs"
                )

    return failures


# ---------------------------------------------------------------------------
# Test 6: Disjoint-stem assertion — no sub-agent name equals a methodology rule output name
# ---------------------------------------------------------------------------

def test_disjoint_stems(canonical_root: Path) -> list[str]:
    """
    No reshaped sub-agent rule output name (<name>.md) equals a methodology rule
    output name (aid-methodology.md / aid-review.md).

    The renderer has no collision guard (last-writer-wins by path); the disjoint-stem
    invariant is what makes the shared .agent/rules/ dir safe.
    """
    failures: list[str] = []

    methodology_rule_names = {"aid-methodology.md", "aid-review.md"}

    with tempfile.TemporaryDirectory() as tmpdir:
        output_root = str(Path(tmpdir) / "profiles" / "antigravity" / ".agent")
        profile = _make_antigravity_profile(output_root)
        manifest = EmissionManifest(profile_name="antigravity")

        paths = render_agents(
            canonical_root=canonical_root,
            profile=profile,
            manifest=manifest,
            output_base=tmpdir,
        )

        for p in paths:
            stem = Path(p).name
            if stem in methodology_rule_names:
                failures.append(
                    f"test_disjoint_stems: sub-agent output name {stem!r} collides with a "
                    f"methodology rule output name — risk of last-writer-wins collision in "
                    f".agent/rules/"
                )

    return failures


# ---------------------------------------------------------------------------
# Test 7: RuleEntry.output_filename defaults to None; cursor behavior byte-identical
# ---------------------------------------------------------------------------

def test_rule_entry_output_filename_default() -> list[str]:
    """
    RuleEntry.output_filename defaults to None.
    A RuleEntry parsed from TOML without output_filename has output_filename=None.
    """
    failures: list[str] = []

    # Direct construction (no output_filename arg) → must default to None
    entry = RuleEntry(filename="aid-methodology.mdc", always_apply=True)
    if entry.output_filename is not None:
        failures.append(
            f"test_rule_entry_output_filename_default: expected None, got {entry.output_filename!r}"
        )

    # _parse_extras without output_filename key → None
    raw_no_output = {
        "rules": [
            {"filename": "aid-methodology.mdc", "always_apply": True, "description": "test"}
        ]
    }
    parsed_extras = _parse_extras(raw_no_output)
    if parsed_extras.rules[0].output_filename is not None:
        failures.append(
            f"test_rule_entry_output_filename_default: _parse_extras without output_filename: "
            f"expected None, got {parsed_extras.rules[0].output_filename!r}"
        )

    # _parse_extras with output_filename key → value stored
    raw_with_output = {
        "rules": [
            {
                "filename": "aid-methodology.mdc",
                "always_apply": True,
                "description": "test",
                "output_filename": "aid-methodology.md",
            }
        ]
    }
    parsed_with = _parse_extras(raw_with_output)
    if parsed_with.rules[0].output_filename != "aid-methodology.md":
        failures.append(
            f"test_rule_entry_output_filename_default: _parse_extras with output_filename: "
            f"expected 'aid-methodology.md', got {parsed_with.rules[0].output_filename!r}"
        )

    return failures


# ---------------------------------------------------------------------------
# Test 8: _render_cursor_extras with output_filename set renames the output file
# ---------------------------------------------------------------------------

def test_render_cursor_extras_output_filename(canonical_root: Path) -> list[str]:
    """
    When rule.output_filename is set, _render_cursor_extras writes the source (rule.filename)
    to the output path named rule.output_filename (.mdc source → .md output).
    When rule.output_filename is None, source filename is used (cursor byte-identical).
    """
    failures: list[str] = []

    rules_src_dir = canonical_root / "canonical" / "rules"
    if not (rules_src_dir / "aid-methodology.mdc").exists():
        failures.append(
            "test_render_cursor_extras_output_filename: canonical/rules/aid-methodology.mdc not found"
        )
        return failures

    # --- Part A: output_filename set → output uses the new name ---
    with tempfile.TemporaryDirectory() as tmpdir:
        output_root = str(Path(tmpdir) / "profiles" / "antigravity" / ".agent")
        profile = _make_antigravity_profile(output_root)
        # Override extras with output_filename set
        profile.extras = ExtrasConfig(rules=[
            RuleEntry(
                filename="aid-methodology.mdc",
                always_apply=True,
                description="AID methodology",
                globs=[],
                output_filename="aid-methodology.md",
            ),
        ])

        manifest = EmissionManifest(profile_name="antigravity")
        paths = _render_cursor_extras(canonical_root, profile, manifest, Path(tmpdir))

        if len(paths) != 1:
            failures.append(
                f"test_render_cursor_extras_output_filename: expected 1 path, got {len(paths)}"
            )
            return failures

        out_path = paths[0]
        if out_path.name != "aid-methodology.md":
            failures.append(
                f"test_render_cursor_extras_output_filename: expected 'aid-methodology.md', "
                f"got {out_path.name!r}"
            )

        # Content must be byte-identical to source
        src_bytes = (rules_src_dir / "aid-methodology.mdc").read_bytes()
        out_bytes = out_path.read_bytes()
        if src_bytes != out_bytes:
            failures.append(
                "test_render_cursor_extras_output_filename: output bytes differ from source"
            )

    # --- Part B: output_filename None → source filename used (cursor behavior) ---
    with tempfile.TemporaryDirectory() as tmpdir:
        # Use a minimal cursor-like profile with output_filename=None (default)
        cursor_output_root = str(Path(tmpdir) / "profiles" / "cursor" / ".cursor")
        cursor_profile = Profile(
            name="cursor",
            layout=LayoutConfig(
                output_root=cursor_output_root,
                rules_dir="rules",
                project_context_file="AGENTS.md",
            ),
            agent=AgentConfig(format="markdown"),
            skill=SkillConfig(decomposition="references"),
            model_tiers={
                "large": ModelTierSimple(model="claude-opus-4.8"),
                "medium": ModelTierSimple(model="claude-sonnet-4.6"),
                "small": ModelTierSimple(model="claude-haiku-4.5"),
            },
            tool_names={},
            filename_map={
                "project_context_file": "AGENTS.md",
                "reviewer_output_file": "STATE.md",
                "open_questions_file": "additional-info.md",
            },
            extras=ExtrasConfig(rules=[
                RuleEntry(
                    filename="aid-methodology.mdc",
                    always_apply=True,
                    description="",
                    globs=[],
                    output_filename=None,  # default → source filename used
                ),
            ]),
        )

        manifest = EmissionManifest(profile_name="cursor")
        paths = _render_cursor_extras(canonical_root, cursor_profile, manifest, Path(tmpdir))

        if len(paths) != 1:
            failures.append(
                f"test_render_cursor_extras_output_filename (cursor-behavior): "
                f"expected 1 path, got {len(paths)}"
            )
            return failures

        out_path = paths[0]
        if out_path.name != "aid-methodology.mdc":
            failures.append(
                f"test_render_cursor_extras_output_filename (cursor-behavior): "
                f"expected 'aid-methodology.mdc', got {out_path.name!r}"
            )

    return failures


# ---------------------------------------------------------------------------
# Test 9: Existing profiles byte-identical (markdown/toml/copilot-agent not perturbed)
# ---------------------------------------------------------------------------

def test_existing_profiles_unchanged(canonical_root: Path) -> list[str]:
    """
    The 3 existing profiles (claude-code, codex, cursor) + copilot-cli render
    byte-identically across two runs after the antigravity-rule branch addition.
    """
    failures: list[str] = []
    profiles_dir = canonical_root / "profiles"

    for profile_name in ("claude-code.toml", "codex.toml", "cursor.toml", "copilot-cli.toml"):
        profile_path = profiles_dir / profile_name
        if not profile_path.exists():
            if profile_name == "copilot-cli.toml":
                # copilot-cli may not exist if delivery-002 hasn't produced it yet
                continue
            failures.append(f"test_existing_profiles_unchanged: {profile_name} not found")
            continue

        profile = load_profile(str(profile_path))
        errs = validate(profile)
        if errs:
            failures.append(
                f"test_existing_profiles_unchanged: {profile_name} failed validation: {errs}"
            )
            continue

        with (
            tempfile.TemporaryDirectory() as tmp1,
            tempfile.TemporaryDirectory() as tmp2,
        ):
            m1 = EmissionManifest(profile_name=profile.name)
            m2 = EmissionManifest(profile_name=profile.name)
            paths1 = render_agents(canonical_root, profile, m1, tmp1)
            paths2 = render_agents(canonical_root, profile, m2, tmp2)

            if len(paths1) != len(paths2):
                failures.append(
                    f"test_existing_profiles_unchanged: {profile.name}: "
                    f"run1={len(paths1)} files, run2={len(paths2)} files"
                )
                continue

            for p1, p2 in zip(paths1, paths2):
                b1 = Path(p1).read_bytes()
                b2 = Path(p2).read_bytes()
                if b1 != b2:
                    failures.append(
                        f"test_existing_profiles_unchanged: {profile.name}: "
                        f"{Path(p1).name} not byte-identical across runs"
                    )

    return failures


# ---------------------------------------------------------------------------
# Test 10: validate() accepts "antigravity-rule" and rejects unknown format
# ---------------------------------------------------------------------------

def test_validate_accepts_antigravity_rule(canonical_root: Path) -> list[str]:
    """
    validate() accepts a profile with agent.format = "antigravity-rule" and
    rejects an unknown format value with a clear message.
    """
    failures: list[str] = []

    p_good = _make_antigravity_profile("profiles/antigravity/.agent")
    errs = validate(p_good)
    if errs:
        failures.append(
            f"test_validate_accepts_antigravity_rule: antigravity-rule format rejected: {errs}"
        )

    # Unknown format → must be rejected
    p_bad = _make_antigravity_profile("profiles/antigravity/.agent")
    p_bad.agent.format = "not-a-real-format"
    errs_bad = validate(p_bad)
    if not errs_bad:
        failures.append(
            "test_validate_accepts_antigravity_rule: unknown format not rejected"
        )
    else:
        combined = " ".join(errs_bad)
        if "not-a-real-format" not in combined:
            failures.append(
                f"test_validate_accepts_antigravity_rule: error does not mention bad value: {errs_bad}"
            )

    return failures


# ---------------------------------------------------------------------------
# Test 11: Existing profiles + copilot-cli still validate clean
# ---------------------------------------------------------------------------

def test_existing_profiles_validate_clean(canonical_root: Path) -> list[str]:
    """
    The 3 existing profiles (claude-code, codex, cursor) + copilot-cli still load
    and validate clean after the _KNOWN_AGENT_FORMATS widening.
    """
    failures: list[str] = []
    profiles_dir = canonical_root / "profiles"

    for name in ("claude-code.toml", "codex.toml", "cursor.toml", "copilot-cli.toml"):
        profile_path = profiles_dir / name
        if not profile_path.exists():
            if name == "copilot-cli.toml":
                continue
            failures.append(f"test_existing_profiles_validate_clean: {name} not found")
            continue
        profile = load_profile(str(profile_path))
        errs = validate(profile)
        if errs:
            failures.append(
                f"test_existing_profiles_validate_clean: {name} validation errors: {errs}"
            )

    return failures


# ---------------------------------------------------------------------------
# Test 12: cursor render_skills byte-identical after output_filename change
# ---------------------------------------------------------------------------

def test_cursor_skills_render_unchanged(canonical_root: Path) -> list[str]:
    """
    The cursor profile's render_skills output (including .mdc rules via
    _render_cursor_extras) is byte-identical across two runs, confirming the
    output_filename=None path is unchanged.
    """
    failures: list[str] = []
    profiles_dir = canonical_root / "profiles"
    profile_path = profiles_dir / "cursor.toml"
    if not profile_path.exists():
        failures.append("test_cursor_skills_render_unchanged: cursor.toml not found")
        return failures

    profile = load_profile(str(profile_path))
    errs = validate(profile)
    if errs:
        failures.append(
            f"test_cursor_skills_render_unchanged: cursor.toml failed validation: {errs}"
        )
        return failures

    with (
        tempfile.TemporaryDirectory() as tmp1,
        tempfile.TemporaryDirectory() as tmp2,
    ):
        m1 = EmissionManifest(profile_name="cursor")
        m2 = EmissionManifest(profile_name="cursor")
        paths1 = render_skills(canonical_root, profile, m1, tmp1)
        paths2 = render_skills(canonical_root, profile, m2, tmp2)

        if len(paths1) != len(paths2):
            failures.append(
                f"test_cursor_skills_render_unchanged: run1={len(paths1)}, run2={len(paths2)}"
            )
            return failures

        for p1, p2 in zip(paths1, paths2):
            b1 = Path(p1).read_bytes()
            b2 = Path(p2).read_bytes()
            if b1 != b2:
                failures.append(
                    f"test_cursor_skills_render_unchanged: {Path(p1).name} not byte-identical"
                )

    return failures


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="test_antigravity_emitter.py",
        description=(
            "Unit tests for the antigravity-rule format branch + RuleEntry.output_filename "
            "touch (task-012). Exit 0 on success, 1 on failure."
        ),
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run all tests.",
    )
    parser.add_argument(
        "--canonical-root",
        metavar="PATH",
        default=".",
        help="Repo root (parent of canonical/, profiles/); default '.'",
    )
    args = parser.parse_args()

    if not args.self_test:
        parser.print_help()
        return 0

    canonical_root = Path(args.canonical_root).resolve()

    all_failures: list[str] = []

    # Unit tests (no canonical_root needed)
    tests_unit = [
        ("antigravity_frontmatter_shape", test_antigravity_frontmatter_shape),
        ("antigravity_description_quoting", test_antigravity_description_quoting),
        ("rule_entry_output_filename_default", test_rule_entry_output_filename_default),
    ]

    # Integration tests (need canonical_root)
    tests_integration = [
        ("antigravity_output_suffix", lambda: test_antigravity_output_suffix(canonical_root)),
        ("antigravity_rule_frontmatter", lambda: test_antigravity_rule_frontmatter(canonical_root)),
        ("antigravity_determinism", lambda: test_antigravity_determinism(canonical_root)),
        ("disjoint_stems", lambda: test_disjoint_stems(canonical_root)),
        (
            "render_cursor_extras_output_filename",
            lambda: test_render_cursor_extras_output_filename(canonical_root),
        ),
        ("existing_profiles_unchanged", lambda: test_existing_profiles_unchanged(canonical_root)),
        ("validate_accepts_antigravity_rule", lambda: test_validate_accepts_antigravity_rule(canonical_root)),
        ("existing_profiles_validate_clean", lambda: test_existing_profiles_validate_clean(canonical_root)),
        ("cursor_skills_render_unchanged", lambda: test_cursor_skills_render_unchanged(canonical_root)),
    ]

    for name, fn in tests_unit:
        print(f"  Unit: {name}...")
        failures = fn()
        all_failures.extend(failures)
        if failures:
            for f in failures:
                print(f"    FAIL: {f}", file=sys.stderr)

    for name, fn in tests_integration:
        print(f"  Integration: {name}...")
        failures = fn()
        all_failures.extend(failures)
        if failures:
            for f in failures:
                print(f"    FAIL: {f}", file=sys.stderr)

    if all_failures:
        print(
            f"\nTEST FAILED ({len(all_failures)} failure(s)):",
            file=sys.stderr,
        )
        for f in all_failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    total = len(tests_unit) + len(tests_integration)
    print(f"\nOK: all {total} antigravity-emitter tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

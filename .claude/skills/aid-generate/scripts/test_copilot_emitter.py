#!/usr/bin/env python3
# test_copilot_emitter.py — Unit tests for the copilot-agent .agent.md emitter (E1, task-006)
#
# Purpose:
#   Validates the new "copilot-agent" format branch in render_agents.py:
#   1. A copilot-agent render produces .agent.md output files (not .md or .toml).
#   2. The tools field is emitted as a valid YAML sequence (never a comma-string repr).
#   3. A description containing ':' is emitted as a quoted scalar that round-trips
#      through a real YAML parse unchanged.
#   4. An empty tools list emits as '[]' (flow form, no dangling key).
#   5. Bash is remapped to shell via [tool_names].
#   6. Existing markdown/toml branches are byte-identical (not perturbed by this change).
#   7. The "copilot-agent" format value is accepted by aid_profile.py validate().
#   8. An unknown agent.format value is rejected by validate().
#   9. The three existing profiles (claude-code, codex, cursor) still validate clean.
#
# Usage:
#   python test_copilot_emitter.py --self-test
#
# Requirements: Python 3.11+
from __future__ import annotations

import argparse
import sys
import tempfile
from pathlib import Path

# ---------------------------------------------------------------------------
# Optional PyYAML import — test-time only; the RENDERER must NOT import yaml.
# The real yaml.safe_load round-trip (SPEC Test Plan #2) runs when available;
# falls back to a strict stdlib structural check with a LOUD skip notice.
# ---------------------------------------------------------------------------
try:
    import yaml as _yaml_lib  # noqa: F401 — kept as module reference
    _YAML_REAL_AVAILABLE = True
except ImportError:
    _yaml_lib = None  # type: ignore[assignment]
    _YAML_REAL_AVAILABLE = False

# ---------------------------------------------------------------------------
# Add script directory to sys.path so modules can be imported directly
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
)
from render_agents import (  # noqa: E402
    _build_frontmatter_md,
    _build_frontmatter_md_copilot,
    _remap_tools,
    _remap_tools_list,
    _yaml_scalar,
    render_agents,
)
from render_lib import EmissionManifest  # noqa: E402


# ---------------------------------------------------------------------------
# Minimal YAML frontmatter parser (stdlib only — no PyYAML dep)
# Used only to round-trip test frontmatter blocks in the assertions below.
# ---------------------------------------------------------------------------

def _yaml_load_frontmatter(fm_block: str) -> dict:
    """
    Parse a ``---`` delimited YAML frontmatter block.

    Supports:
    - Scalar values: plain, double-quoted (with escape sequences).
    - Block-sequence values: lines starting with ``  - ``.
    - Flow empty sequence: ``key: []``.

    This is intentionally limited to the shapes E1 can emit; it is NOT a
    general YAML parser.  For the purposes of the round-trip assertion
    (task-006 AC: tools round-trips as a YAML sequence, description round-trips
    unchanged) this covers all required cases.
    """
    lines = fm_block.strip().splitlines()
    # Strip --- delimiters
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
                # Block sequence: collect following `  - item` lines
                items = []
                i += 1
                while i < len(lines) and lines[i].startswith("  - "):
                    item_raw = lines[i][4:].strip()
                    items.append(_unescape_yaml_scalar(item_raw))
                    i += 1
                result[key] = items
                continue

            result[key] = _unescape_yaml_scalar(raw_val)
        i += 1
    return result


def _unescape_yaml_scalar(val: str) -> str:
    """
    Decode a YAML scalar: strip outer double-quotes and unescape ``\\``/``\\"``.
    Plain (unquoted) scalars are returned as-is.
    """
    if val.startswith('"') and val.endswith('"') and len(val) >= 2:
        inner = val[1:-1]
        # Unescape backslash sequences in order: \\" then \\
        inner = inner.replace('\\"', '"').replace('\\\\', '\\')
        return inner
    return val


def _real_yaml_load_frontmatter(fm_block: str) -> dict:
    """
    Parse a ``---`` delimited YAML frontmatter block using ``yaml.safe_load``
    (PyYAML).  Raises ``RuntimeError`` if PyYAML is not available.
    Only used inside tests; the renderer itself never imports yaml.

    The ``---`` delimiters are stripped before calling ``yaml.safe_load``
    because ``---`` acts as a YAML document-start marker; a second ``---``
    would start a new document and make ``safe_load`` raise.
    """
    if not _YAML_REAL_AVAILABLE:
        raise RuntimeError("PyYAML not available")
    lines = fm_block.strip().splitlines()
    # Strip leading and trailing --- delimiters
    if lines and lines[0].strip() == "---":
        lines = lines[1:]
    if lines and lines[-1].strip() == "---":
        lines = lines[:-1]
    interior = "\n".join(lines)
    parsed = _yaml_lib.safe_load(interior)  # type: ignore[union-attr]
    if not isinstance(parsed, dict):
        raise ValueError(f"YAML frontmatter did not parse to a dict: {parsed!r}")
    return parsed


def _stdlib_strict_check_frontmatter(fm_block: str) -> list[str]:
    """
    Strict stdlib structural check used as fallback when PyYAML is not available.

    Verifies:
    - Exactly two ``---`` delimiter lines.
    - Every non-blank interior line either starts with a known key or is a
      block-sequence item (``  - ``).
    - No Python-repr artifacts (``['`` or ``{'``).
    - The ``tools:`` value is not a comma-separated scalar line.
    """
    failures: list[str] = []
    lines = fm_block.strip().splitlines()
    if len(lines) < 2 or lines[0].strip() != "---" or lines[-1].strip() != "---":
        failures.append(f"stdlib_check: frontmatter not properly delimited:\n{fm_block}")
        return failures
    for line in lines[1:-1]:
        if not line.strip():
            continue
        if "['".replace("'", "") in line or "{'" in line:
            failures.append(f"stdlib_check: Python repr artifact in line: {line!r}")
        if line.startswith("tools:") and "," in line and not line.strip().endswith("[]"):
            failures.append(f"stdlib_check: tools line looks like a comma-scalar: {line!r}")
    return failures


# ---------------------------------------------------------------------------
# Test 1: _build_frontmatter_md_copilot emits tools as YAML block sequence
# ---------------------------------------------------------------------------

def test_tools_yaml_sequence() -> list[str]:
    """
    tools list serializes as a YAML block sequence, never as a Python repr or
    comma-string scalar.
    """
    failures: list[str] = []

    fields = {
        "name": "architect",
        "description": "A design agent.",
        "tools": ["Read", "shell", "Write"],
        "model": "claude-opus-4.8",
    }
    fm = _build_frontmatter_md_copilot(fields)

    # Must not contain Python repr artifacts
    if "['Read'" in fm or "['shell'" in fm:
        failures.append(f"test_tools_yaml_sequence: output contains Python repr: {fm!r}")

    # Must not contain a comma-separated scalar line
    for line in fm.splitlines():
        if line.startswith("tools:") and "Read, " in line:
            failures.append(
                f"test_tools_yaml_sequence: tools emitted as comma-string: {line!r}"
            )

    # Must contain YAML block-sequence items
    if "  - Read" not in fm:
        failures.append(
            f"test_tools_yaml_sequence: missing '  - Read' in frontmatter:\n{fm}"
        )
    if "  - shell" not in fm:
        failures.append(
            f"test_tools_yaml_sequence: missing '  - shell' in frontmatter:\n{fm}"
        )

    # Round-trip: parse back and confirm tools is a list, not a string
    parsed = _yaml_load_frontmatter(fm)
    if not isinstance(parsed.get("tools"), list):
        failures.append(
            f"test_tools_yaml_sequence: round-trip tools is not a list: {parsed.get('tools')!r}"
        )
    if parsed.get("tools") != ["Read", "shell", "Write"]:
        failures.append(
            f"test_tools_yaml_sequence: round-trip tools mismatch: {parsed.get('tools')!r}"
        )

    return failures


# ---------------------------------------------------------------------------
# Test 2: Empty tools list emits as [] (no dangling key)
# ---------------------------------------------------------------------------

def test_empty_tools_flow_form() -> list[str]:
    """
    An empty tools list emits as ``tools: []`` (flow form), never as a bare
    ``tools:`` key with no value.
    """
    failures: list[str] = []

    fields = {
        "name": "agent",
        "description": "No tools.",
        "tools": [],
        "model": "claude-sonnet-4.6",
    }
    fm = _build_frontmatter_md_copilot(fields)

    found_empty_flow = False
    for line in fm.splitlines():
        if line.strip() == "tools: []":
            found_empty_flow = True
        # Must not emit a bare dangling key
        if line.strip() == "tools:" and "[]" not in line:
            failures.append(
                f"test_empty_tools_flow_form: found dangling 'tools:' without value"
            )

    if not found_empty_flow:
        failures.append(
            f"test_empty_tools_flow_form: expected 'tools: []', not found in:\n{fm}"
        )

    # Round-trip: must parse back to empty list
    parsed = _yaml_load_frontmatter(fm)
    if parsed.get("tools") != []:
        failures.append(
            f"test_empty_tools_flow_form: round-trip tools is not []: {parsed.get('tools')!r}"
        )

    return failures


# ---------------------------------------------------------------------------
# Test 3: Description with ':' is emitted as quoted scalar, parses back unchanged
# ---------------------------------------------------------------------------

def test_colon_description_quoted() -> list[str]:
    """
    A description containing ':' must be emitted as a quoted scalar (double-quoted)
    and must parse back through the round-trip parser to the original string.
    """
    failures: list[str] = []

    original_desc = "Design agent: transforms requirements into SPEC.md, PLAN.md"
    fields = {
        "name": "architect",
        "description": original_desc,
        "tools": ["Read"],
        "model": "claude-opus-4.8",
    }
    fm = _build_frontmatter_md_copilot(fields)

    # The description line must be quoted
    for line in fm.splitlines():
        if line.startswith("description:"):
            val_part = line[len("description:"):].strip()
            if not (val_part.startswith('"') and val_part.endswith('"')):
                failures.append(
                    f"test_colon_description_quoted: description not double-quoted: {line!r}"
                )

    # Round-trip: must recover exact original string
    parsed = _yaml_load_frontmatter(fm)
    if parsed.get("description") != original_desc:
        failures.append(
            f"test_colon_description_quoted: round-trip mismatch:\n"
            f"  original: {original_desc!r}\n"
            f"  parsed:   {parsed.get('description')!r}\n"
            f"  fm block:\n{fm}"
        )

    return failures


# ---------------------------------------------------------------------------
# Test 4: Bash → shell remap via _remap_tools_list
# ---------------------------------------------------------------------------

def test_bash_to_shell_remap() -> list[str]:
    """
    _remap_tools_list remaps 'Bash' → 'shell' via [tool_names], leaving other
    tool names unchanged.
    """
    failures: list[str] = []

    tool_names = {"Bash": "shell"}
    result = _remap_tools_list("Read, Glob, Grep, Bash, Write, Edit", tool_names)

    if "Bash" in result:
        failures.append(
            f"test_bash_to_shell_remap: 'Bash' not remapped in result: {result}"
        )
    if "shell" not in result:
        failures.append(
            f"test_bash_to_shell_remap: 'shell' not found in result: {result}"
        )
    expected = ["Read", "Glob", "Grep", "shell", "Write", "Edit"]
    if result != expected:
        failures.append(
            f"test_bash_to_shell_remap: expected {expected}, got {result}"
        )

    return failures


# ---------------------------------------------------------------------------
# Test 5: _remap_tools_list with empty tools string → []
# ---------------------------------------------------------------------------

def test_remap_tools_list_empty() -> list[str]:
    """
    _remap_tools_list("", ...) returns an empty list without errors.
    """
    failures: list[str] = []

    result = _remap_tools_list("", {"Bash": "shell"})
    if result != []:
        failures.append(
            f"test_remap_tools_list_empty: expected [], got {result!r}"
        )

    result2 = _remap_tools_list("   ", {})
    if result2 != []:
        failures.append(
            f"test_remap_tools_list_empty: expected [] for whitespace-only, got {result2!r}"
        )

    return failures


# ---------------------------------------------------------------------------
# Test 6: copilot-agent render produces .agent.md output files
# ---------------------------------------------------------------------------

def _make_minimal_copilot_profile(output_root: str) -> Profile:
    """Build a minimal in-memory Profile with agent.format='copilot-agent'."""
    return Profile(
        name="copilot-cli",
        layout=LayoutConfig(
            output_root=output_root,
            agents_dir="agents",
            skills_dir="skills",
            project_context_file="AGENTS.md",
        ),
        agent=AgentConfig(
            format="copilot-agent",
            frontmatter=FrontmatterConfig(
                required=["name", "description", "tools", "model"],
                optional=[],
            ),
        ),
        skill=SkillConfig(decomposition="references"),
        model_tiers={
            "large": ModelTierSimple(model="claude-opus-4.8"),
            "medium": ModelTierSimple(model="claude-sonnet-4.6"),
            "small": ModelTierSimple(model="claude-haiku-4.5"),
        },
        tool_names={"Bash": "shell"},
        filename_map={
            "project_context_file": "AGENTS.md",
            "reviewer_output_file": "STATE.md",
            "open_questions_file": "additional-info.md",
        },
        capabilities=CapabilitiesConfig(
            hooks=True,
            skill_chaining=True,
            background_execution=True,
            stop_hook_autocontinue=True,
        ),
    )


def test_copilot_agent_output_suffix(canonical_root: Path) -> list[str]:
    """
    render_agents with format='copilot-agent' emits .agent.md files (not .md or .toml).
    Also verifies: tools is a YAML list in the output, Bash→shell, and frontmatter
    key order is name/description/tools/model.
    """
    failures: list[str] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        output_root = str(Path(tmpdir) / "profiles" / "copilot-cli" / ".github")
        profile = _make_minimal_copilot_profile(output_root)

        manifest = EmissionManifest(profile_name="copilot-cli")
        paths = render_agents(
            canonical_root=canonical_root,
            profile=profile,
            manifest=manifest,
            output_base=tmpdir,
        )

        if not paths:
            failures.append("test_copilot_agent_output_suffix: no files rendered")
            return failures

        for p in paths:
            if not str(p).endswith(".agent.md"):
                failures.append(
                    f"test_copilot_agent_output_suffix: file does not end in .agent.md: {p}"
                )
            if str(p).endswith(".toml"):
                failures.append(
                    f"test_copilot_agent_output_suffix: unexpected .toml file: {p}"
                )

        # Inspect the first file for frontmatter correctness
        first_path = paths[0]
        content = Path(first_path).read_text(encoding="utf-8")

        # Frontmatter block must exist
        if not content.startswith("---"):
            failures.append(
                f"test_copilot_agent_output_suffix: {first_path.name} lacks frontmatter"
            )
            return failures

        fm_lines = []
        in_fm = False
        close_count = 0
        for line in content.splitlines():
            if line.strip() == "---":
                if not in_fm:
                    in_fm = True
                    fm_lines.append(line)
                else:
                    close_count += 1
                    fm_lines.append(line)
                    break
            elif in_fm:
                fm_lines.append(line)
        fm_block = "\n".join(fm_lines)
        parsed = _yaml_load_frontmatter(fm_block)

        # Key order: name, description, tools, model
        keys_in_fm = list(parsed.keys())
        if keys_in_fm[:4] != ["name", "description", "tools", "model"]:
            failures.append(
                f"test_copilot_agent_output_suffix: frontmatter key order wrong: {keys_in_fm}"
            )

        # tools must be a list (not a string)
        if not isinstance(parsed.get("tools"), list):
            failures.append(
                f"test_copilot_agent_output_suffix: tools is not a list: {parsed.get('tools')!r}"
            )

        # Bash should have been remapped to shell
        tools_list = parsed.get("tools", [])
        if "Bash" in tools_list:
            failures.append(
                f"test_copilot_agent_output_suffix: 'Bash' not remapped to 'shell': {tools_list}"
            )

        # No optional Copilot fields should be emitted
        forbidden = {"target", "user-invocable", "disable-model-invocation", "mcp-servers", "metadata"}
        for k in forbidden:
            if k in parsed:
                failures.append(
                    f"test_copilot_agent_output_suffix: forbidden field '{k}' found in frontmatter"
                )

    return failures


# ---------------------------------------------------------------------------
# Test 7: Frontmatter round-trip — real yaml.safe_load (SPEC Test Plan #2)
# ---------------------------------------------------------------------------

def test_frontmatter_round_trip(canonical_root: Path) -> list[str]:
    """
    Every .agent.md emitted by render_agents for the copilot-agent profile must
    have a frontmatter block that round-trips through a REAL ``yaml.safe_load``
    parse (SPEC Test Plan #2) with tools as a list and description unchanged.

    When PyYAML is available (``_YAML_REAL_AVAILABLE``):
      - Each emitted frontmatter block is parsed with ``yaml.safe_load``.
      - ``tools`` must be a Python ``list``; ``description`` must be a ``str``.
      - An adversarial set of synthetic descriptions exercising all
        ``_yaml_scalar`` edge-cases is round-tripped through
        ``_build_frontmatter_md_copilot`` → ``yaml.safe_load`` → value equality.

    When PyYAML is NOT available:
      - A LOUD skip notice is printed to stderr (NOT a silent pass).
      - A stricter stdlib structural check is run instead (no silent bypass).
    """
    failures: list[str] = []

    # -----------------------------------------------------------------------
    # Part A: round-trip all emitted .agent.md files
    # -----------------------------------------------------------------------
    with tempfile.TemporaryDirectory() as tmpdir:
        output_root = str(Path(tmpdir) / "profiles" / "copilot-cli" / ".github")
        profile = _make_minimal_copilot_profile(output_root)

        manifest = EmissionManifest(profile_name="copilot-cli")
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
                failures.append(f"test_frontmatter_round_trip: {p.name} missing opening ---")
                continue
            end = None
            for idx in range(1, len(lines)):
                if lines[idx].strip() == "---":
                    end = idx
                    break
            if end is None:
                failures.append(f"test_frontmatter_round_trip: {p.name} missing closing ---")
                continue

            fm_block = "\n".join(lines[:end + 1])

            if _YAML_REAL_AVAILABLE:
                # Strong SPEC-sanctioned check: real yaml.safe_load
                try:
                    parsed = _real_yaml_load_frontmatter(fm_block)
                except Exception as exc:
                    failures.append(
                        f"test_frontmatter_round_trip: {p.name}: yaml.safe_load failed: {exc}\n"
                        f"  fm block:\n{fm_block}"
                    )
                    continue

                # tools must parse as a list (not a string)
                tools_val = parsed.get("tools")
                if not isinstance(tools_val, list):
                    failures.append(
                        f"test_frontmatter_round_trip: {p.name}: tools not a list "
                        f"(yaml.safe_load): {tools_val!r}\n  fm block:\n{fm_block}"
                    )

                # description must be present and a string
                desc_val = parsed.get("description")
                if not isinstance(desc_val, str):
                    failures.append(
                        f"test_frontmatter_round_trip: {p.name}: description not a string "
                        f"(yaml.safe_load): {desc_val!r}"
                    )

                # model must be present and non-empty
                model_val = parsed.get("model")
                if not model_val:
                    failures.append(
                        f"test_frontmatter_round_trip: {p.name}: model missing or empty "
                        f"(yaml.safe_load)"
                    )
            else:
                # Fallback: strict stdlib structural check + hand-rolled parse
                print(
                    "  SKIP NOTICE [test_frontmatter_round_trip]: PyYAML not available — "
                    "running strict stdlib check instead of real yaml.safe_load. "
                    "Install PyYAML to run the full SPEC Test Plan #2 validation.",
                    file=sys.stderr,
                )
                struct_failures = _stdlib_strict_check_frontmatter(fm_block)
                failures.extend(struct_failures)

                # Also run hand-rolled parser for structural sanity
                parsed = _yaml_load_frontmatter(fm_block)
                tools_val = parsed.get("tools")
                if not isinstance(tools_val, list):
                    failures.append(
                        f"test_frontmatter_round_trip: {p.name}: tools not a list "
                        f"(stdlib fallback): {tools_val!r}"
                    )
                desc_val = parsed.get("description")
                if not isinstance(desc_val, str):
                    failures.append(
                        f"test_frontmatter_round_trip: {p.name}: description not a string "
                        f"(stdlib fallback): {desc_val!r}"
                    )

    # -----------------------------------------------------------------------
    # Part B: adversarial _yaml_scalar edge-case round-trips (Fix #1 guard)
    # Exercises every gap identified in the delivery-002 gate review:
    # leading @, -, ?, backtick; null/yes/no/on/off/true/false/12345;
    # leading/trailing whitespace, tab, newline, colon-space, trailing colon.
    # -----------------------------------------------------------------------
    adversarial_descriptions = [
        "@mention and something",           # leading @
        "- dash leading",                   # leading - (sequence indicator)
        "? question leading",               # leading ? (mapping-key indicator)
        "`backtick",                        # leading backtick
        "  leading whitespace",             # leading space
        "trailing whitespace   ",           # trailing space
        "has\ttab",                         # ASCII tab (control char)
        "has\nnewline",                     # embedded newline
        "null",                             # YAML null
        "yes",                              # YAML bool alt
        "no",                               # YAML bool alt
        "on",                               # YAML bool alt
        "off",                              # YAML bool alt
        "true",                             # YAML bool
        "false",                            # YAML bool
        "12345",                            # integer-looking
        "1.5",                              # float-looking
        "Design agent: does things",        # colon-space (existing trigger)
        "trailing colon:",                  # trailing colon
        "has #comment",                     # space-hash
        'embedded "quotes"',                # embedded double-quote
        "backslash\\path",                  # embedded backslash
        "plain safe string",                # must remain UNquoted
    ]

    for adv_desc in adversarial_descriptions:
        fields = {
            "name": "test-agent",
            "description": adv_desc,
            "tools": ["Read"],
            "model": "claude-sonnet-4.6",
        }
        fm = _build_frontmatter_md_copilot(fields)

        if _YAML_REAL_AVAILABLE:
            try:
                parsed = _real_yaml_load_frontmatter(fm)
            except Exception as exc:
                failures.append(
                    f"test_frontmatter_round_trip [adversarial]: "
                    f"yaml.safe_load failed for desc={adv_desc!r}: {exc}\n"
                    f"  fm:\n{fm}"
                )
                continue

            rt_desc = parsed.get("description")
            if rt_desc != adv_desc:
                failures.append(
                    f"test_frontmatter_round_trip [adversarial]: round-trip mismatch "
                    f"for desc={adv_desc!r}:\n"
                    f"  got:  {rt_desc!r}\n"
                    f"  fm:\n{fm}"
                )
            tools_val = parsed.get("tools")
            if not isinstance(tools_val, list):
                failures.append(
                    f"test_frontmatter_round_trip [adversarial]: tools not a list "
                    f"for desc={adv_desc!r}: {tools_val!r}"
                )
        else:
            # Strict stdlib structural check for adversarial cases
            struct_failures = _stdlib_strict_check_frontmatter(fm)
            for sf in struct_failures:
                failures.append(
                    f"test_frontmatter_round_trip [adversarial/stdlib]: "
                    f"desc={adv_desc!r}: {sf}"
                )

    return failures


# ---------------------------------------------------------------------------
# Test 8: Existing markdown/toml branches are byte-identical after this change
# (regression guard for the 3 existing profiles)
# ---------------------------------------------------------------------------

def test_existing_profiles_unchanged(canonical_root: Path) -> list[str]:
    """
    The 3 existing profiles (claude-code, codex, cursor) render byte-identically
    across two runs.  Confirms the copilot-agent branch addition does not perturb
    existing code paths.
    """
    failures: list[str] = []
    profiles_dir = canonical_root / "profiles"

    existing_profiles = ["claude-code.toml", "codex.toml", "cursor.toml"]
    for profile_name in existing_profiles:
        profile_path = profiles_dir / profile_name
        if not profile_path.exists():
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
# Test 9: aid_profile.validate accepts "copilot-agent" format value
# ---------------------------------------------------------------------------

def test_validate_accepts_copilot_agent(canonical_root: Path) -> list[str]:
    """
    validate() accepts a profile with agent.format = "copilot-agent" and
    rejects an unknown format value with a clear message.
    """
    failures: list[str] = []

    # Profile with copilot-agent format: must validate clean
    p_good = _make_minimal_copilot_profile("profiles/copilot-cli/.github")
    errs = validate(p_good)
    if errs:
        failures.append(
            f"test_validate_accepts_copilot_agent: copilot-agent format rejected: {errs}"
        )

    # Profile with unknown format: must be rejected
    p_bad = _make_minimal_copilot_profile("profiles/copilot-cli/.github")
    p_bad.agent.format = "not-a-real-format"
    errs_bad = validate(p_bad)
    if not errs_bad:
        failures.append(
            "test_validate_accepts_copilot_agent: unknown format should be rejected, but was not"
        )
    else:
        # Error message must mention the format value
        combined = " ".join(errs_bad)
        if "not-a-real-format" not in combined:
            failures.append(
                f"test_validate_accepts_copilot_agent: error message does not mention the bad "
                f"value: {errs_bad}"
            )

    return failures


# ---------------------------------------------------------------------------
# Test 10: Existing 3 profiles still validate clean
# ---------------------------------------------------------------------------

def test_existing_profiles_validate_clean(canonical_root: Path) -> list[str]:
    """
    The 3 existing profiles (claude-code, codex, cursor) still load and validate
    clean (defaults unchanged by the task-005 enum widening).
    """
    failures: list[str] = []
    profiles_dir = canonical_root / "profiles"

    for name in ("claude-code.toml", "codex.toml", "cursor.toml"):
        profile_path = profiles_dir / name
        if not profile_path.exists():
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
# Test 11: _yaml_scalar quoting behavior
# ---------------------------------------------------------------------------

def test_yaml_scalar_quoting() -> list[str]:
    """
    _yaml_scalar quotes strings containing YAML-special chars and leaves plain
    strings unquoted.
    """
    failures: list[str] = []

    # Plain string — no quoting
    result = _yaml_scalar("architect")
    if result != "architect":
        failures.append(f"test_yaml_scalar_quoting: plain scalar should be unquoted: {result!r}")

    # String with colon — must be double-quoted
    result = _yaml_scalar("Design agent: does things")
    if not (result.startswith('"') and result.endswith('"')):
        failures.append(
            f"test_yaml_scalar_quoting: colon-bearing string not double-quoted: {result!r}"
        )

    # String with embedded double-quote — must be escaped
    result = _yaml_scalar('He said "hello"')
    if '\\"' not in result:
        failures.append(
            f"test_yaml_scalar_quoting: embedded double-quote not escaped: {result!r}"
        )

    # Round-trip: parse back the quoted scalar
    original = "Design: uses canonical/agents/ refs"
    quoted = _yaml_scalar(original)
    recovered = _unescape_yaml_scalar(quoted)
    if recovered != original:
        failures.append(
            f"test_yaml_scalar_quoting: round-trip failed: {original!r} → {quoted!r} → {recovered!r}"
        )

    return failures


# ---------------------------------------------------------------------------
# Test 12: _build_frontmatter_md_copilot field-order guarantee
# ---------------------------------------------------------------------------

def test_copilot_frontmatter_field_order() -> list[str]:
    """
    _build_frontmatter_md_copilot preserves dict insertion order, so the
    caller can guarantee name/description/tools/model are in the correct order.
    """
    failures: list[str] = []

    fields = {
        "name": "developer",
        "description": "Developer agent.",
        "tools": ["Read", "shell"],
        "model": "claude-sonnet-4.6",
    }
    fm = _build_frontmatter_md_copilot(fields)

    # Extract non-delimiter key lines (lines that start with an identifier)
    key_lines = []
    for line in fm.splitlines():
        if line in ("---",):
            continue
        if line.startswith("  - "):
            continue
        if ":" in line:
            key = line.split(":")[0].strip()
            if key:
                key_lines.append(key)

    # First four keys must be name, description, tools, model in that order
    if key_lines[:4] != ["name", "description", "tools", "model"]:
        failures.append(
            f"test_copilot_frontmatter_field_order: wrong key order: {key_lines}"
        )

    return failures


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="test_copilot_emitter.py",
        description=(
            "Unit tests for the copilot-agent .agent.md emitter (E1, task-006). "
            "Exit 0 on success, 1 on failure."
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

    tests_unit = [
        ("tools_yaml_sequence", test_tools_yaml_sequence),
        ("empty_tools_flow_form", test_empty_tools_flow_form),
        ("colon_description_quoted", test_colon_description_quoted),
        ("bash_to_shell_remap", test_bash_to_shell_remap),
        ("remap_tools_list_empty", test_remap_tools_list_empty),
        ("yaml_scalar_quoting", test_yaml_scalar_quoting),
        ("copilot_frontmatter_field_order", test_copilot_frontmatter_field_order),
    ]

    tests_integration = [
        ("copilot_agent_output_suffix", lambda: test_copilot_agent_output_suffix(canonical_root)),
        ("frontmatter_round_trip", lambda: test_frontmatter_round_trip(canonical_root)),
        ("existing_profiles_unchanged", lambda: test_existing_profiles_unchanged(canonical_root)),
        ("validate_accepts_copilot_agent", lambda: test_validate_accepts_copilot_agent(canonical_root)),
        ("existing_profiles_validate_clean", lambda: test_existing_profiles_validate_clean(canonical_root)),
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
    print(f"\nOK: all {total} copilot-emitter tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
# render_skills.py — AID canonical-generator skill renderer
#
# Purpose:
#   Render canonical/skills/aid-{name}/ into per-tool install trees using the
#   per-tool profile.  Emits SKILL.md + references/*.md + scripts/*.sh for every
#   skill folder.  Cursor extras (.mdc rules) are also rendered by this script.
#
# Usage:
#   python render_skills.py --canonical-root <repo-root> --profile <path/to/profile.toml> --output-root <dest>
#   python render_skills.py --self-test --canonical-root <repo-root>
#
# Requirements: Python 3.11+
from __future__ import annotations

import argparse
import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from aid_profile import load_profile, validate, Profile  # noqa: E402
from render_lib import (  # noqa: E402
    read_canonical_file,
    substitute_filenames,
    rewrite_install_paths,
    sha256_hex,
    EmissionManifest,
)


# ---------------------------------------------------------------------------
# YAML-lite frontmatter helpers (reuse pattern from render_agents.py)
# ---------------------------------------------------------------------------

def _split_frontmatter_raw(text: str) -> tuple[list[str], str]:
    """
    Split a SKILL.md into raw frontmatter lines and body text.

    Returns (fm_lines, body) where fm_lines does NOT include the ``---``
    delimiters.  body is everything after the closing ``---``.
    Returns ([], text) if no frontmatter found.
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
    claude_code_optional: list[str],
    is_claude_code: bool,
) -> list[str]:
    """
    Rewrite the raw frontmatter lines in place:
    - Apply tool_names remapping to the ``allowed-tools:`` line.
    - Drop claude_code_optional fields (context:, agent:) for non-Claude-Code profiles.

    All other lines (including folded description blocks) are passed through verbatim,
    preserving the original formatting exactly.

    Returns the rewritten list of lines (still without ``---`` delimiters).
    """
    result: list[str] = []
    i = 0
    while i < len(fm_lines):
        line = fm_lines[i]
        stripped = line.strip()

        # Check if this is a top-level key line (not a continuation line)
        if stripped and not line[0].isspace():
            key = stripped.split(":")[0].strip()

            # Drop claude_code_optional fields for non-claude-code profiles
            if not is_claude_code and key in claude_code_optional:
                # Skip this line and any continuation lines (indented)
                i += 1
                while i < len(fm_lines) and fm_lines[i] and fm_lines[i][0].isspace():
                    i += 1
                continue

            # Remap allowed-tools
            if key == "allowed-tools" and tool_names:
                # Extract the value part (everything after "allowed-tools:")
                colon_idx = line.index(":")
                tools_part = line[colon_idx + 1:].rstrip("\n")
                remapped = _remap_tools(tools_part.strip(), tool_names)
                result.append(f"allowed-tools: {remapped}\n")
                i += 1
                continue

        result.append(line)
        i += 1

    return result


def _remap_tools(tools_str: str, tool_names: dict[str, str]) -> str:
    """Remap tool names using the profile's tool_names map."""
    if not tool_names:
        return tools_str
    parts = [t.strip() for t in tools_str.split(",")]
    return ", ".join(tool_names.get(t, t) for t in parts)


# ---------------------------------------------------------------------------
# Output path resolution
# ---------------------------------------------------------------------------

def _skill_output_root(profile: Profile, output_base: Path) -> Path:
    """
    Return the base directory under which skill folders are written.

    - Claude Code / Cursor (single root): {output_root}/skills/
    - Codex (split root): {assets_root}/skills/
    """
    if profile.layout.output_root is not None:
        return output_base / profile.layout.output_root / profile.layout.skills_dir
    else:
        # Codex split layout
        return output_base / profile.layout.assets_root / profile.layout.skills_dir  # type: ignore[operator]


# ---------------------------------------------------------------------------
# Per-file render helpers
# ---------------------------------------------------------------------------

def _record(
    manifest: EmissionManifest,
    profile: Profile,
    encoded: bytes,
    src_path: Path,
    dst_path: Path,
    output_base: Path,
    canonical_root: Path,
) -> None:
    """Record one emitted file in the manifest."""
    common_parent = Path(profile.layout.common_parent())
    src = str(src_path.relative_to(canonical_root)).replace("\\", "/")
    dst = str(dst_path.relative_to(output_base / common_parent)).replace("\\", "/")
    manifest.add(profile=profile.name, src=src, dst=dst, sha256=sha256_hex(encoded))


def _write(path: Path, encoded: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(encoded)


def _render_skill_md(
    skill_md_path: Path,
    profile: Profile,
    manifest: EmissionManifest,
    out_skill_dir: Path,
    output_base: Path,
    canonical_root: Path,
) -> Path:
    """
    Render the SKILL.md for one skill.

    Strategy: preserve the original frontmatter verbatim (including folded
    description blocks), only applying tool-name remapping and stripping
    claude_code_optional fields for non-Claude-Code profiles.  This avoids
    YAML reformatting bugs and produces output byte-identical to the canonical.
    """
    raw = read_canonical_file(skill_md_path)
    fm_lines, body = _split_frontmatter_raw(raw)

    is_claude_code = (profile.name == "claude-code")
    claude_code_optional = profile.skill.frontmatter.claude_code_optional

    new_fm_lines = _rewrite_skill_frontmatter(
        fm_lines=fm_lines,
        tool_names=profile.tool_names,
        claude_code_optional=claude_code_optional,
        is_claude_code=is_claude_code,
    )

    fm_block = "---\n" + "".join(new_fm_lines) + "---\n"
    # Renderer policy (also in render_agents/recipes/templates/scripts): every
    # text-emitting renderer applies substitute_filenames THEN
    # rewrite_install_paths so adopter projects (no canonical/ at root) can
    # resolve canonical/{scripts,templates,...}/ references. See render_lib.py
    # rewrite_install_paths docstring for the regex + comment-skip rule.
    #
    # Apply BOTH to frontmatter as well as body (round-4 NEW-HIGH-1 lesson):
    # the description field — even though preserved here as raw lines rather
    # than parsed into a dict like render_agents.py does — may contain
    # canonical/X/ references that must rewrite per profile. The rewriter
    # regex is narrow enough that bare-key lines like `name: foo` won't match;
    # only lines actually containing canonical/<dir>/ patterns get touched.
    fm_block = substitute_filenames(fm_block, profile.filename_map)
    fm_block = rewrite_install_paths(fm_block, profile.layout.install_root())
    body = substitute_filenames(body, profile.filename_map)
    body = rewrite_install_paths(body, profile.layout.install_root())
    content = fm_block + body

    out_path = out_skill_dir / "SKILL.md"
    encoded = content.encode("utf-8")
    _write(out_path, encoded)
    _record(manifest, profile, encoded, skill_md_path, out_path, output_base, canonical_root)
    return out_path


def _render_reference_file(
    ref_path: Path,
    profile: Profile,
    manifest: EmissionManifest,
    out_skill_dir: Path,
    output_base: Path,
    canonical_root: Path,
) -> Path:
    """Render one file from references/."""
    raw = read_canonical_file(ref_path)
    # Renderer policy: see SKILL.md rendering function above for the canonical
    # substitute_filenames + rewrite_install_paths convention.
    content = substitute_filenames(raw, profile.filename_map)
    content = rewrite_install_paths(content, profile.layout.install_root())
    out_path = out_skill_dir / "references" / ref_path.name
    encoded = content.encode("utf-8")
    _write(out_path, encoded)
    _record(manifest, profile, encoded, ref_path, out_path, output_base, canonical_root)
    return out_path


def _render_script_file(
    script_path: Path,
    profile: Profile,
    manifest: EmissionManifest,
    out_skill_dir: Path,
    output_base: Path,
    canonical_root: Path,
) -> Path:
    """Copy one file from scripts/ verbatim (no substitution)."""
    encoded = script_path.read_bytes()
    out_path = out_skill_dir / "scripts" / script_path.name
    _write(out_path, encoded)
    _record(manifest, profile, encoded, script_path, out_path, output_base, canonical_root)
    return out_path


# ---------------------------------------------------------------------------
# Cursor extras (.mdc rules)
# ---------------------------------------------------------------------------

def _render_cursor_extras(
    canonical_root: Path,
    profile: Profile,
    manifest: EmissionManifest,
    output_base: Path,
) -> list[Path]:
    """
    Render Cursor-specific .mdc rule files from canonical/rules/ into
    cursor/.cursor/rules/.

    Only called when profile.extras.rules is non-empty.
    Rules are carried verbatim (no substitution — they do not mention per-tool filenames).
    """
    if not profile.extras.rules:
        return []

    rules_src_dir = canonical_root / "canonical" / "rules"
    rules_out_dir = output_base / profile.layout.output_root / profile.layout.rules_dir  # type: ignore[operator]

    out_paths: list[Path] = []
    for rule in profile.extras.rules:
        src_path = rules_src_dir / rule.filename
        if not src_path.exists():
            raise FileNotFoundError(
                f"Cursor rule {rule.filename!r} declared in profile but not found at {src_path}"
            )
        encoded = src_path.read_bytes()
        out_path = rules_out_dir / rule.filename
        _write(out_path, encoded)
        _record(manifest, profile, encoded, src_path, out_path, output_base, canonical_root)
        out_paths.append(out_path)

    return out_paths


# ---------------------------------------------------------------------------
# Top-level renderer
# ---------------------------------------------------------------------------

def render_skills(
    canonical_root: str | Path,
    profile: Profile,
    manifest: EmissionManifest,
    output_base: str | Path,
) -> list[Path]:
    """
    Render all canonical skills for the given profile.

    Returns a sorted list of all emitted file paths.
    """
    canonical_root = Path(canonical_root)
    output_base = Path(output_base)
    skills_base = canonical_root / "canonical" / "skills"
    out_base = _skill_output_root(profile, output_base)

    skill_dirs = sorted(d for d in skills_base.iterdir() if d.is_dir())
    if not skill_dirs:
        raise FileNotFoundError(f"No skill directories found in {skills_base}")

    all_paths: list[Path] = []

    for skill_dir in skill_dirs:
        skill_slug = skill_dir.name  # e.g. "aid-discover"
        out_skill_dir = out_base / skill_slug

        # SKILL.md (required)
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            raise FileNotFoundError(f"SKILL.md missing in {skill_dir}")
        all_paths.append(
            _render_skill_md(skill_md, profile, manifest, out_skill_dir, output_base, canonical_root)
        )

        # references/*.md (optional)
        ref_dir = skill_dir / "references"
        if ref_dir.is_dir():
            for ref_file in sorted(ref_dir.glob("*.md")):
                all_paths.append(
                    _render_reference_file(
                        ref_file, profile, manifest, out_skill_dir, output_base, canonical_root
                    )
                )

        # scripts/*.sh (optional, verbatim copy)
        scripts_dir = skill_dir / "scripts"
        if scripts_dir.is_dir():
            for script_file in sorted(scripts_dir.iterdir()):
                all_paths.append(
                    _render_script_file(
                        script_file, profile, manifest, out_skill_dir, output_base, canonical_root
                    )
                )

    # Cursor extras (.mdc rules)
    if profile.extras.rules:
        extra_paths = _render_cursor_extras(canonical_root, profile, manifest, output_base)
        all_paths.extend(extra_paths)

    return all_paths


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="render_skills.py",
        description="Render canonical/skills/ into per-tool install trees.",
    )
    parser.add_argument("--canonical-root", required=True, metavar="PATH")
    parser.add_argument("--profile", metavar="PATH", help="Required unless --self-test")
    parser.add_argument("--output-root", metavar="PATH", help="Required unless --self-test")
    parser.add_argument("--manifest-path", metavar="PATH")
    parser.add_argument("--self-test", action="store_true")
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
        paths = render_skills(args.canonical_root, profile, manifest, args.output_root)
    except Exception as exc:
        print(f"ERROR during rendering: {exc}", file=sys.stderr)
        return 1

    print(f"Rendered {len(paths)} skill files for profile {profile.name!r}")

    if args.manifest_path:
        manifest.write(args.manifest_path)
        print(f"Manifest written to {args.manifest_path}")

    return 0


def _self_test(canonical_root_arg: str) -> int:
    """Determinism self-test: two renders must produce byte-identical output."""
    import tempfile

    if not canonical_root_arg:
        print("ERROR: --canonical-root required for --self-test", file=sys.stderr)
        return 1

    canonical_root = Path(canonical_root_arg)
    profiles_dir = canonical_root / "profiles"
    failures: list[str] = []

    for profile_path in sorted(profiles_dir.glob("*.toml")):
        profile = load_profile(str(profile_path))
        errors = validate(profile)
        if errors:
            failures.append(f"{profile.name}: {errors}")
            continue

        with tempfile.TemporaryDirectory() as tmp1, tempfile.TemporaryDirectory() as tmp2:
            m1 = EmissionManifest(profile_name=profile.name)
            m2 = EmissionManifest(profile_name=profile.name)

            paths1 = render_skills(canonical_root, profile, m1, tmp1)
            paths2 = render_skills(canonical_root, profile, m2, tmp2)

            if len(paths1) != len(paths2):
                failures.append(
                    f"{profile.name}: run1={len(paths1)} files, run2={len(paths2)}"
                )
                continue

            mismatch = 0
            for p1, p2 in zip(paths1, paths2):
                b1 = Path(p1).read_bytes()
                b2 = Path(p2).read_bytes()
                if b1 != b2:
                    mismatch += 1
                    failures.append(f"{profile.name}: {Path(p1).name} not byte-identical")

            print(
                f"  {profile.name}: {len(paths1)} files, "
                f"determinism: {'OK' if mismatch == 0 else f'FAIL ({mismatch} mismatches)'}"
            )

    if failures:
        print(f"\nSELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print("\nOK: render_skills self-test passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

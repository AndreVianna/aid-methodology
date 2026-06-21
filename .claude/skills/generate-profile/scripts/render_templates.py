#!/usr/bin/env python3
# render_templates.py — AID canonical-generator template renderer
#
# Purpose:
#   Copy the entire canonical/templates/ subtree into the profile's templates
#   location, applying filename substitution to .md files and carrying binary/
#   asset files byte-identical.
#
# Output locations:
#   Claude Code: profiles/claude-code/.claude/templates/...
#   Codex:       profiles/codex/.agents/templates/...  (split layout)
#   Cursor:      profiles/cursor/.cursor/templates/...
#
# Usage:
#   python render_templates.py --canonical-root <repo-root> --profile <profile.toml> --output-root <dest>
#   python render_templates.py --self-test --canonical-root <repo-root>
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
    substitute_filenames,
    rewrite_install_paths,
    sha256_hex,
    EmissionManifest,
)


# ---------------------------------------------------------------------------
# File-type classification
# ---------------------------------------------------------------------------

# Extensions that receive filename substitution (text-based content)
_TEXT_EXTENSIONS = {
    ".md", ".txt", ".sh", ".ps1", ".mjs", ".js", ".html", ".css",
}

# Extensions that are always carried verbatim (binary or already text-but-safe)
_VERBATIM_EXTENSIONS: set[str] = set()

# Everything else is treated as verbatim (binary files, etc.)


def _is_text_file(path: Path) -> bool:
    """Return True if the file should have filename substitution applied."""
    return path.suffix.lower() in _TEXT_EXTENSIONS


# ---------------------------------------------------------------------------
# Output path resolution
# ---------------------------------------------------------------------------

def _templates_output_root(profile: Profile, output_base: Path) -> Path:
    """
    Return the root directory under which the templates/ subtree is written.

    templates/ is an AID-own directory — it nests under aid/ in the install tree
    to isolate AID content from user content (SD-1 convention: aid/ parent
    encoded in the builder, *_dir key stays as bare leaf name).

    - Single-root (Claude Code, Cursor, etc.): {output_root}/aid/templates/
    - Codex split:                             {assets_root}/aid/templates/
    """
    if profile.layout.output_root is not None:
        return output_base / profile.layout.output_root / "aid" / profile.layout.templates_dir
    else:
        return output_base / profile.layout.assets_root / "aid" / profile.layout.templates_dir  # type: ignore[operator]


# ---------------------------------------------------------------------------
# Top-level renderer
# ---------------------------------------------------------------------------

def render_templates(
    canonical_root: str | Path,
    profile: Profile,
    manifest: EmissionManifest,
    output_base: str | Path,
) -> list[Path]:
    """
    Render the entire canonical/templates/ subtree for the given profile.

    Text files receive filename substitution; binary / asset files are
    copied verbatim.

    Returns a sorted list of all emitted output paths.
    """
    canonical_root = Path(canonical_root)
    output_base = Path(output_base)
    templates_src = canonical_root / "canonical" / "aid" / "templates"
    templates_dst = _templates_output_root(profile, output_base)

    common_parent = Path(profile.layout.common_parent())
    out_paths: list[Path] = []

    # Walk sorted for determinism
    all_files = sorted(
        f for f in templates_src.rglob("*") if f.is_file()
    )

    for src_file in all_files:
        rel = src_file.relative_to(templates_src)
        dst_file = templates_dst / rel

        if _is_text_file(src_file):
            try:
                raw = src_file.read_text(encoding="utf-8")
                # Renderer policy (also in render_agents/recipes/scripts/skills):
                # every text-emitting renderer applies substitute_filenames THEN
                # rewrite_install_paths so adopter projects (no canonical/ at root)
                # can resolve canonical/{scripts,templates,...}/ references.
                # See render_lib.py rewrite_install_paths docstring.
                content = substitute_filenames(raw, profile.filename_map)
                content = rewrite_install_paths(content, profile.layout.install_root())
                encoded = content.encode("utf-8")
            except UnicodeDecodeError:
                # Fallback: treat as binary if UTF-8 decode fails
                encoded = src_file.read_bytes()
        else:
            encoded = src_file.read_bytes()

        dst_file.parent.mkdir(parents=True, exist_ok=True)
        dst_file.write_bytes(encoded)

        # Manifest record
        src_rel = str(src_file.relative_to(canonical_root)).replace("\\", "/")
        # Normalize: canonical/aid/templates/ -> canonical/templates/ for manifest src
        # stability across the A4 canonical/aid/ reshape (task-003 — structural move only,
        # no manifest src change so downstream consumers see unchanged traceability paths).
        src_rel = src_rel.replace("canonical/aid/templates/", "canonical/templates/", 1)
        dst_rel = str(dst_file.relative_to(output_base / common_parent)).replace("\\", "/")
        manifest.add(
            profile=profile.name,
            src=src_rel,
            dst=dst_rel,
            sha256=sha256_hex(encoded),
        )

        out_paths.append(dst_file)

    return out_paths


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        prog="render_templates.py",
        description="Render canonical/templates/ into per-tool install trees.",
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
        paths = render_templates(args.canonical_root, profile, manifest, args.output_root)
    except Exception as exc:
        print(f"ERROR during rendering: {exc}", file=sys.stderr)
        return 1

    print(f"Rendered {len(paths)} template files for profile {profile.name!r}")

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

            paths1 = render_templates(canonical_root, profile, m1, tmp1)
            paths2 = render_templates(canonical_root, profile, m2, tmp2)

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
                f"  {profile.name}: {len(paths1)} template files, "
                f"determinism: {'OK' if mismatch == 0 else f'FAIL ({mismatch} mismatches)'}"
            )

    if failures:
        print(f"\nSELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print("\nOK: render_templates self-test passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
# render_recipes.py — AID canonical-generator recipe renderer
#
# Purpose:
#   Copy the entire canonical/recipes/ subtree into the profile's recipes
#   location. Recipes are plain Markdown files (passthrough renderer — no
#   format conversion or frontmatter injection). Filename substitution is
#   applied to .md files; binary / asset files are carried byte-identical.
#
# Output locations:
#   Claude Code: profiles/claude-code/.claude/recipes/...
#   Codex:       profiles/codex/.agents/recipes/...  (split layout, assets_root)
#   Cursor:      profiles/cursor/.cursor/recipes/...
#
# Usage:
#   python render_recipes.py --canonical-root <repo-root> --profile <profile.toml> --output-root <dest>
#   python render_recipes.py --self-test --canonical-root <repo-root>
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


def _is_text_file(path: Path) -> bool:
    """Return True if the file should have filename substitution applied."""
    return path.suffix.lower() in _TEXT_EXTENSIONS


# ---------------------------------------------------------------------------
# Output path resolution
# ---------------------------------------------------------------------------

def _recipes_output_root(profile: Profile, output_base: Path) -> Path:
    """
    Return the root directory under which the recipes/ subtree is written.

    recipes/ is an AID-own directory — it nests under aid/ in the install tree
    to isolate AID content from user content (SD-1 convention: aid/ parent
    encoded in the builder, *_dir key stays as bare leaf name).

    - Single-root (Claude Code, Cursor, etc.): {output_root}/aid/recipes/
    - Codex split:                             {assets_root}/aid/recipes/
                                               (NOT under agents_root — R6)
    """
    if profile.layout.output_root is not None:
        return output_base / profile.layout.output_root / "aid" / profile.layout.recipes_dir
    else:
        return output_base / profile.layout.assets_root / "aid" / profile.layout.recipes_dir  # type: ignore[operator]


# ---------------------------------------------------------------------------
# Top-level renderer
# ---------------------------------------------------------------------------

def render_recipes(
    canonical_root: str | Path,
    profile: Profile,
    manifest: EmissionManifest,
    output_base: str | Path,
) -> list[Path]:
    """
    Render the entire canonical/recipes/ subtree for the given profile.

    Text files receive filename substitution; binary / asset files are
    copied verbatim. If canonical/recipes/ does not exist or is empty,
    returns an empty list (no-op — generator is idempotent before the
    first recipe is authored).

    Returns a sorted list of all emitted output paths.
    """
    canonical_root = Path(canonical_root)
    output_base = Path(output_base)
    recipes_src = canonical_root / "canonical" / "aid" / "recipes"
    recipes_dst = _recipes_output_root(profile, output_base)

    common_parent = Path(profile.layout.common_parent())
    out_paths: list[Path] = []

    # If the canonical/recipes/ directory does not exist, no-op.
    if not recipes_src.exists():
        return out_paths

    # Walk sorted for determinism; skip .gitkeep and other hidden bookkeeping files
    all_files = sorted(
        f for f in recipes_src.rglob("*")
        if f.is_file() and not f.name.startswith(".")
    )

    for src_file in all_files:
        rel = src_file.relative_to(recipes_src)
        dst_file = recipes_dst / rel

        if _is_text_file(src_file):
            try:
                raw = src_file.read_text(encoding="utf-8")
                # Renderer policy (also in render_agents/templates/scripts/skills):
                # every text-emitting renderer applies substitute_filenames THEN
                # rewrite_install_paths so adopter projects (no canonical/ at root)
                # can resolve canonical/{scripts,templates,skills,agents,rules,
                # recipes}/ references. The rewriter skips lines starting with
                # `#` so prose-about-the-mechanism in comments survives intact.
                # See render_lib.py rewrite_install_paths docstring for the regex
                # + comment-skip rule.
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
        # Normalize: canonical/aid/recipes/ -> canonical/recipes/ for manifest src
        # stability across the A4 canonical/aid/ reshape (task-003 — structural move only,
        # no manifest src change so downstream consumers see unchanged traceability paths).
        src_rel = src_rel.replace("canonical/aid/recipes/", "canonical/recipes/", 1)
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
        prog="render_recipes.py",
        description="Render canonical/recipes/ into per-tool install trees.",
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
        paths = render_recipes(args.canonical_root, profile, manifest, args.output_root)
    except Exception as exc:
        print(f"ERROR during rendering: {exc}", file=sys.stderr)
        return 1

    print(f"Rendered {len(paths)} recipe files for profile {profile.name!r}")

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

            paths1 = render_recipes(canonical_root, profile, m1, tmp1)
            paths2 = render_recipes(canonical_root, profile, m2, tmp2)

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
                f"  {profile.name}: {len(paths1)} recipe files, "
                f"determinism: {'OK' if mismatch == 0 else f'FAIL ({mismatch} mismatches)'}"
            )

    if failures:
        print(f"\nSELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print("\nOK: render_recipes self-test passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

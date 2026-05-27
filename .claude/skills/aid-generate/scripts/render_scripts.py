#!/usr/bin/env python3
# render_scripts.py — AID canonical-generator scripts renderer (F1 fix)
#
# Purpose:
#   Copy the entire canonical/scripts/ subtree into the profile's scripts
#   location (e.g., .claude/scripts/, .agents/scripts/, .cursor/scripts/),
#   applying install-path rewrites to text files so cross-script references
#   resolve correctly in the install tree.
#
#   Closes the adopter script-distribution gap that made Phase B's
#   .aid/settings.yml SoT machinery non-deliverable: skills emit literal
#   canonical/scripts/config/read-setting.sh calls, but canonical/ does not
#   exist in adopter projects. After this pass, every profile install has its
#   own scripts/ subtree AND every skill body is rewritten to point at it.
#
# Output locations:
#   Claude Code: profiles/claude-code/.claude/scripts/...
#   Codex:       profiles/codex/.agents/scripts/...  (split layout — assets root)
#   Cursor:      profiles/cursor/.cursor/scripts/...
#
# Usage:
#   python render_scripts.py --canonical-root <repo-root> --profile <profile.toml> --output-root <dest>
#   python render_scripts.py --self-test --canonical-root <repo-root>
#
# Requirements: Python 3.11+
from __future__ import annotations

import argparse
import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from profile import load_profile, validate, Profile  # noqa: E402
from harness import (  # noqa: E402
    substitute_filenames,
    rewrite_install_paths,
    sha256_hex,
    EmissionManifest,
)


# Extensions that receive substitution + path rewriting (text-based content)
_TEXT_EXTENSIONS = {".sh", ".ps1", ".mjs", ".js", ".py", ".txt", ".md"}


def _is_text_file(path: Path) -> bool:
    return path.suffix.lower() in _TEXT_EXTENSIONS


def _scripts_output_root(profile: Profile, output_base: Path) -> Path:
    """
    Return the root directory under which the scripts/ subtree is written.

    - Claude Code / Cursor: {output_root}/scripts/
    - Codex split:          {assets_root}/scripts/  (NOT under agents_root)
    """
    if profile.layout.output_root is not None:
        return output_base / profile.layout.output_root / profile.layout.scripts_dir
    return output_base / profile.layout.assets_root / profile.layout.scripts_dir  # type: ignore[operator]


def render_scripts(
    canonical_root: str | Path,
    profile: Profile,
    manifest: EmissionManifest,
    output_base: str | Path,
) -> list[Path]:
    """
    Render the entire canonical/scripts/ subtree for the given profile.

    Text files receive filename substitution + install-path rewriting; binary
    files are copied verbatim.

    Returns a sorted list of all emitted output paths.
    """
    canonical_root = Path(canonical_root)
    output_base = Path(output_base)
    scripts_src = canonical_root / "canonical" / "scripts"
    scripts_dst = _scripts_output_root(profile, output_base)
    install_root = profile.layout.install_root()

    common_parent = Path(profile.layout.common_parent())
    out_paths: list[Path] = []

    if not scripts_src.exists():
        # No scripts/ to ship — emit nothing.
        return out_paths

    all_files = sorted(f for f in scripts_src.rglob("*") if f.is_file())

    for src_file in all_files:
        rel = src_file.relative_to(scripts_src)
        dst_file = scripts_dst / rel

        if _is_text_file(src_file):
            try:
                raw = src_file.read_text(encoding="utf-8")
                content = substitute_filenames(raw, profile.filename_map)
                content = rewrite_install_paths(content, install_root)
                encoded = content.encode("utf-8")
            except UnicodeDecodeError:
                encoded = src_file.read_bytes()
        else:
            encoded = src_file.read_bytes()

        dst_file.parent.mkdir(parents=True, exist_ok=True)
        dst_file.write_bytes(encoded)

        # Preserve executable bit for .sh/.ps1 on POSIX (no-op on Windows)
        if src_file.suffix.lower() in {".sh", ".ps1", ".mjs", ".py"}:
            try:
                mode = src_file.stat().st_mode | 0o111
                dst_file.chmod(mode)
            except (PermissionError, OSError):
                pass  # Best-effort; Windows doesn't honor +x anyway

        src_rel = str(src_file.relative_to(canonical_root)).replace("\\", "/")
        dst_rel = str(dst_file.relative_to(output_base / common_parent)).replace("\\", "/")
        manifest.add(
            profile=profile.name,
            src=src_rel,
            dst=dst_rel,
            sha256=sha256_hex(encoded),
        )
        out_paths.append(dst_file)

    return out_paths


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="render_scripts.py",
        description="Render canonical/scripts/ into per-tool install trees (F1 fix).",
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

    profile = load_profile(args.profile)
    errors = validate(profile)
    if errors:
        for err in errors:
            print(f"ERROR: {err}", file=sys.stderr)
        return 1

    manifest = EmissionManifest(profile_name=profile.name)
    paths = render_scripts(args.canonical_root, profile, manifest, args.output_root)

    print(f"Rendered {len(paths)} script files for profile {profile.name!r}")

    if args.manifest_path:
        manifest.write(args.manifest_path)
        print(f"Manifest written to {args.manifest_path}")

    return 0


def _self_test(canonical_root_arg: str) -> int:
    import tempfile

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

            paths1 = render_scripts(canonical_root, profile, m1, tmp1)
            paths2 = render_scripts(canonical_root, profile, m2, tmp2)

            if len(paths1) != len(paths2):
                failures.append(
                    f"{profile.name}: run1={len(paths1)} files, run2={len(paths2)}"
                )
                continue

            mismatch = 0
            for p1, p2 in zip(paths1, paths2):
                if Path(p1).read_bytes() != Path(p2).read_bytes():
                    mismatch += 1
                    failures.append(f"{profile.name}: {Path(p1).name} not byte-identical")

            print(
                f"  {profile.name}: {len(paths1)} script files, "
                f"determinism: {'OK' if mismatch == 0 else f'FAIL ({mismatch} mismatches)'}"
            )

    if failures:
        print(f"\nSELF-TEST FAILED ({len(failures)} failure(s)):", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1

    print("\nOK: render_scripts self-test passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Live generator run: render all profiles from canonical, then verify."""
# task-005 (work-005 feature-002): slimmed to use copy-based render.py core.
# Dropped: 5-renderer import block (render_agents, render_skills, render_templates,
#          render_canonical_scripts, render_recipes).
# Kept: load/validate -> render_profile -> diff/prune -> manifest/write -> verify spine.
import subprocess
import sys
from pathlib import Path

# Resolve imports from the script's own directory regardless of CWD.
sys.path.insert(0, str(Path(__file__).parent))
from aid_profile import load_profile, validate
from render_lib import EmissionManifest
from render import render_profile
from verify_deterministic import run_verify
from verify_advisory import run_advisory

repo = Path('.')
profiles_dir = repo / 'profiles'

total_emitted = 0
total_deleted = 0

for profile_path in sorted(profiles_dir.glob('*.toml')):
    profile = load_profile(str(profile_path))
    errors = validate(profile)
    if errors:
        print(f"ERROR: {profile.name}: {errors}")
        sys.exit(1)

    print(f"\n[RENDER] {profile.name}...")

    # Load previous manifest (if any)
    manifest_path = repo / profile.common_parent() / 'emission-manifest.jsonl'
    prev_manifest = None
    if manifest_path.exists():
        prev_manifest = EmissionManifest.load(str(manifest_path), profile_name=profile.name)

    # Render
    manifest = EmissionManifest(profile_name=profile.name)
    render_profile(repo, profile, manifest, repo)

    # Deletion pass (pure-mirror: remove files that were in prev manifest but not current)
    deleted = []
    if prev_manifest is not None:
        _added, removed, _changed = manifest.diff(prev_manifest)
        for rel_dst in removed:
            target = repo / profile.common_parent() / rel_dst
            if target.exists():
                target.unlink()
                deleted.append(rel_dst)
                # Prune empty parents
                parent = target.parent
                common = repo / profile.common_parent()
                while parent != common and parent.exists():
                    try:
                        parent.rmdir()
                        parent = parent.parent
                    except OSError:
                        break

    # Write manifest
    manifest.write(str(manifest_path))

    emitted = len(manifest._records)
    total_emitted += emitted
    total_deleted += len(deleted)
    print(f"  Emitted: {emitted} files, Deleted: {len(deleted)}, Manifest: {manifest_path}")

print(f"\nTotal: {total_emitted} files emitted, {total_deleted} deleted")
print("\nRunning VERIFY (deterministic)...")
passed, _report = run_verify(str(repo))
if not passed:
    print("VERIFY (deterministic) FAILED", file=sys.stderr)
    print(
        "  (re-run with `python verify_deterministic.py --canonical-root . "
        "--report-path /tmp/verify-deterministic.json` for details)",
        file=sys.stderr,
    )
    sys.exit(1)
print("VERIFY (deterministic): PASS")

print("\nRunning VERIFY (advisory)...")
report_advisory = run_advisory(str(repo))
print(
    f"VERIFY (advisory): skipped={report_advisory['skipped_count']} "
    f"checked={report_advisory['checked_count']}"
)

# The dogfood resync, run HERE rather than left to whoever remembers.
#
# `.claude/` and `.cursor/` at the repository root are this repo eating its own output, and
# `test-dogfood-byte-identity.sh` compares them byte-for-byte against the profile emission manifests.
# So a render that is not followed by a resync leaves those trees stale and CI red -- which is exactly
# what happened: the resync script carried that warning in its own header and NOTHING called it, in CI,
# in the generator, or in release.sh. It was a manual step with no enforcement, and it was missed twice
# in one sitting before three checks went red over it.
#
# Chaining it to the render removes the opportunity to forget. A failure here is fatal, because
# finishing "successfully" with trees the byte-identity guard will reject is worse than stopping.
print("\nResyncing dogfood trees (.claude/ and .cursor/)...")
_sync = Path(__file__).resolve().parent / "sync_dogfood.py"
_res = subprocess.run(
    [sys.executable, str(_sync)],
    cwd=str(repo),
    capture_output=True,
    text=True,
)
sys.stdout.write(_res.stdout)
if _res.returncode != 0:
    sys.stderr.write(_res.stderr)
    print("DOGFOOD RESYNC FAILED -- .claude/ and .cursor/ may not match the manifests", file=sys.stderr)
    sys.exit(1)

print("\nDone. Install trees updated, dogfood trees resynced.")

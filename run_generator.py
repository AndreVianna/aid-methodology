#!/usr/bin/env python3
"""Live generator run: render all profiles from canonical, then verify."""
import sys
import json
from pathlib import Path

sys.path.insert(0, '.claude/skills/aid-generate/scripts')
from aid_profile import load_profile, validate
from harness import EmissionManifest
from render_agents import render_agents
from render_skills import render_skills
from render_templates import render_templates
from render_scripts import render_scripts
from render_recipes import render_recipes
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
    manifest_path = repo / profile.layout.common_parent() / 'emission-manifest.jsonl'
    prev_manifest = None
    if manifest_path.exists():
        prev_manifest = EmissionManifest.load(str(manifest_path), profile_name=profile.name)

    # Render
    manifest = EmissionManifest(profile_name=profile.name)
    render_agents(repo, profile, manifest, repo)
    render_skills(repo, profile, manifest, repo)
    render_templates(repo, profile, manifest, repo)
    render_scripts(repo, profile, manifest, repo)
    render_recipes(repo, profile, manifest, repo)

    # Deletion pass
    deleted = []
    if prev_manifest is not None:
        _added, removed, _changed = manifest.diff(prev_manifest)
        for rel_dst in removed:
            target = repo / profile.layout.common_parent() / rel_dst
            if target.exists():
                target.unlink()
                deleted.append(rel_dst)
                # Prune empty parents
                parent = target.parent
                common = repo / profile.layout.common_parent()
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
    print("  (re-run with `python -m verify_deterministic --canonical-root . --report-path /tmp/verify-deterministic.json` for details)", file=sys.stderr)
    sys.exit(1)
print("VERIFY (deterministic): PASS")

print("\nRunning VERIFY (advisory)...")
report_advisory = run_advisory(str(repo))
print(f"VERIFY (advisory): skipped={report_advisory['skipped_count']} checked={report_advisory['checked_count']}")

print("\nDone. Install trees updated.")

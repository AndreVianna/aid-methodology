ad13_count_class() {
    ( cd "$REPO" && PATTERN="$1" python3 - <<'PY'
import os, pathlib, re, subprocess

pattern = re.compile(os.environ["PATTERN"])
# Absence statements, retirement notes, and the deliberate legacy-fallback prose are not
# offences -- the same argument AD04/AD10 already make. A sentence explaining that an
# artifact is dead is the opposite of sending someone to it.
skip = re.compile(
    r"\bno\b|not\b|never|retire[sd]?|gone|abolished|superseded|folded|formerly|legacy|"
    r"un-migrated|fallback|presence rule|sentinel|renamed|migration|era|IMPEDIMENT|"
    r"was |rejected|deprecated",
    re.I,
)
EXCLUDE = (
    "profiles/", ".claude/", ".cursor/", ".codex/", ".agent/",   # generated renders
    # Installed copies of canonical/skills and canonical/aid (dogfood trees). Counting them
    # too would count every shared-layout reference twice.
    ".agents/", ".aid/runtime/",
    ".aid/works/",                                              # transient work state
    # A rule that quotes the string it governs is not an offence against itself;
    # counting this file would make the ceiling track its own prose.
    "tests/canonical/test-artifact-discipline.sh",
)
SUFFIXES = {".md", ".mdx", ".py", ".mjs", ".sh", ".ps1", ".yml", ".yaml", ".astro", ".ts", ".js"}

# TRACKED files only. Counting the working tree made the ceiling depend on whatever build
# output a developer happened to have on disk: a local package build drops ~180 copies of
# the repo under packages/, which would trip the ratchet for reasons that have nothing to
# do with the change under test. A ceiling that a stray directory can breach is a ceiling
# people learn to raise.
listed = subprocess.run(["git", "ls-files", "-z"], capture_output=True, text=True).stdout
total = 0
for name in listed.split("\0"):
    if not name or any(x in name for x in EXCLUDE):
        continue
    path = pathlib.Path(name)
    if path.suffix not in SUFFIXES or not path.is_file():
        continue
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if pattern.search(line) and not skip.search(line):
            total += 1
print(total)
PY
    )
}

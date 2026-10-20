REPO="$1"
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
for spec in \
 "work STATE.md|65|works?[ \`]{0,4}['\"'\"'\\\`]?STATE\.md|works/\{work\}/STATE\.md" \
 ; do :; done
p1='works?[ `]{0,4}['"'"'\`]?STATE\.md|works/\{work\}/STATE\.md'
p2='BLUEPRINT\.md'
p3='(?<!IMPEDIMENT-)(?<!execute-)\btask-NNN\.md'
p4='features/[*a-zA-Z0-9_-]*/SPEC\.md|per-feature[ `]+SPEC'
p5='## (Cross-phase Q&A|Tasks Status|Tasks State|Features State|Deploy State|Pipeline State|Delivery Gate|Seed Authoring|Interview State)'
echo "C1 $(ad13_count_class "$p1") ceiling 65"
echo "C2 $(ad13_count_class "$p2") ceiling 154"
echo "C3 $(ad13_count_class "$p3") ceiling 16"
echo "C4 $(ad13_count_class "$p4") ceiling 3"
echo "C5 $(ad13_count_class "$p5") ceiling 235"

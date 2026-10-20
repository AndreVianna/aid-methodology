import re, subprocess, os, collections
REPO = os.getcwd()
def git_grep(args, pathspec):
    cmd = ["git", "grep", "-n", "-I"] + args + ["--"] + pathspec
    out = subprocess.run(cmd, capture_output=True, text=True, cwd=REPO).stdout
    rows = []
    for line in out.splitlines():
        m = re.match(r"^([^:]+):(\d+):(.*)$", line)
        if m: rows.append((m.group(1), int(m.group(2)), m.group(3)))
    return rows
def ls_files(): return subprocess.run(["git","ls-files"],capture_output=True,text=True,cwd=REPO).stdout.splitlines()
def read(p):
    with open(os.path.join(REPO,p),encoding="utf-8",errors="replace") as f: return f.read()

SKILLS = sorted(os.path.basename(os.path.dirname(p)) for p in ls_files() if re.match(r"canonical/skills/[^/]+/SKILL\.md$", p))
DOORWAYS = {s for s in SKILLS if re.search(r"^# Shortcut", read(f"canonical/skills/{s}/SKILL.md"), re.M)}
def groups():
    g = {}
    def add(task, names):
        for n in names: g[n] = task
    add("task-060", ["aid-brainstorm","aid-design"] + [s for s in SKILLS if s.startswith("aid-design-")])
    add("task-061", [f"aid-{v}-{a}" for v in ("create","update") for a in ("architecture","backlog","cicd","mvp","roadmap","stack","testing-strategy")])
    add("task-063", ["aid-describe"])
    add("task-064", ["aid-define","aid-specify"])
    add("task-065", ["aid-plan","aid-detail","aid-execute"])
    add("task-066", ["aid-discover"])
    add("task-067", ["aid-update-kb","aid-ask","aid-summarize","aid-housekeep"])
    add("task-068", ["aid-deploy","aid-monitor","aid-read-ticket","aid-create-ticket","aid-update-ticket","aid-config","aid-set-connector","aid-unset-connector","aid-chat"])
    add("task-069", ["aid-research","aid-review","aid-test","aid-test-data-quality","aid-test-performance","aid-test-security","aid-prototype","aid-prototype-ui","aid-report","aid-create-document","aid-update-document","aid-orchestrate","aid-create-diagram","aid-document"] + [f"aid-document-{x}" for x in ("architecture","changelog","decision","guideline","runbook","standard","tutorial")])
    return g
GROUP = groups()
DOOR_NOTE = "no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder)"
def skill_owner(s):
    if s in DOORWAYS: return DOOR_NOTE
    if s in GROUP: return GROUP[s]
    return "no change needed here (no delivery-003 task names this file; see Delta)"
FILE_OWNER = {
 "canonical/aid/templates/shortcut-engine.md":"task-062",
 "canonical/aid/templates/design-lifecycle.md":"task-060",
 "canonical/aid/templates/agent-boilerplate.md":"task-059",
 "canonical/aid/templates/state-machine-chaining.md":"task-074",
 "canonical/aid/templates/agent-dispatch-tiering.md":"task-072",
 "canonical/aid/templates/reviewer-dispatch.md":"task-072",
 "canonical/aid/templates/connectors/ticket-resolution.md":"task-068",
 "canonical/aid/scripts/connectors/write-connector.sh":"task-068",
 "canonical/aid/scripts/summarize/validate-diagram-content.mjs":"history, left as is",
 "site/src/content/docs/reference/agents.md":"task-072",
 "site/src/content/docs/concepts/methodology.md":"task-076",
 "docs/aid-methodology.md":"task-076","docs/diagram-content-reference.md":"task-076",
 "examples/brownfield-lite-path/README.md":"task-076","examples/greenfield/README.md":"task-076",
 "skills/aid-describe.md":"task-076",
 "tests/cost-baseline.tsv":"baseline, re-recorded at the gate","tests/coverage-baseline.tsv":"baseline, re-recorded at the gate",
 "tests/coverage-accepted-removals.tsv":"history, left as is","tests/coverage-rehome-allowlist.tsv":"history, left as is",
 "tests/conversation/protocol-checks.md":"task-075","tests/conversation/run.py":"task-071",
 "tests/conversation/deferred.tsv":"task-078 (then task-080)",
 "tests/canonical/skill-steps-exempt.tsv":"task-074",
 "tests/canonical/test-pipeline-status-walkthrough.sh":"task-074",
 "tests/canonical/test-artifact-discipline.sh":"task-078",
 "tests/canonical/test-skill-steps.sh":"task-078 (then task-081)",
 "tests/canonical/test-describe-full-only.sh":"task-063",
 "tests/canonical/test-shortcut-engine-contract.sh":"task-062",
 "tests/canonical/test-conversation-runner.sh":"task-071",
 "tests/canonical/test-ticket-skills-structural.sh":"task-068",
 "tests/canonical/test-connector-skills-structural.sh":"task-068",
 "tests/canonical/test-doc-counts.sh":"task-072 (then task-076)",
 "tests/canonical/test-disjoint-merge.sh":"no change needed here (migration-era fixture of the delivery qa key; the edited files are not its subject)",
 "tests/canonical/test-work-state-template.sh":"no change needed here (asserts delivery-state-template.yml, which no task edits)",
 "tests/canonical/test-migrate-hierarchy.sh":"no change needed here (migration script suite; the spec keeps the migration)",
 "canonical/aid/scripts/migrate/migrate-work-hierarchy.sh":"no change needed here (migration script: reads the old shapes; outside SS-06, spec keeps it)",
 "canonical/aid/scripts/migrate/migrate-work-hierarchy.ps1":"no change needed here (migration script: reads the old shapes; outside SS-06, spec keeps it)",
 "canonical/aid/templates/delivery-state-template.yml":"no change needed here (delivery template; Feature 006 retires it, no task edits it; see Delta)",
 "canonical/aid/templates/work-initiation-gate.md":"no change needed here (delivery-002 converted this gate; no delivery-003 task edits it)",
 "canonical/aid/templates/work-state-template.yml":"no change needed here (its delivery-layout comments; Feature 006 retires the delivery files; no task edits it; see Delta)",
 "canonical/aid/templates/question-protocol.md":"no change needed here (the protocol itself: its qa example is the work-level record)",
 "canonical/aid/templates/skill-steps.md":"no change needed here (the step rules; its --ask line is the work-level record)",
 "bin/aid":"no change needed here (CLI reader of the old heading; spec keeps it; see Delta)",
 "bin/aid.ps1":"no change needed here (CLI reader of the old heading; spec keeps it; see Delta)",
}
INSTALLED_PREFIX = (".claude/", ".agents/", ".aid/runtime/", ".cursor/", "profiles/", ".codex/")
def owner_of(path):
    if path.startswith(INSTALLED_PREFIX) or path == ".aid/.aid-manifest.json" or path == "dashboard/scripts/write-connector.sh":
        return "installed copy (resync)"
    if path.startswith("recovery/") or path.startswith("packages/"):
        return "no change needed here (recovery or packaging snapshot, not a live source; see Delta)"
    if path in FILE_OWNER: return FILE_OWNER[path]
    m = re.match(r"canonical/skills/([^/]+)/", path)
    if m: return skill_owner(m.group(1))
    m = re.match(r"site/src/content/docs/skills/([^/]+)\.md$", path) or re.match(r"site/src/data/skill-flows/([^/]+)\.flow\.json$", path)
    if m: return skill_owner(m.group(1)) if m.group(1) in SKILLS else "UNOWNED"
    if path.startswith("canonical/agents/"): return "task-072"
    if path.startswith(".aid/knowledge/"):
        b = os.path.basename(path)
        if b in ("kb.html","release-tracking.md"): return "history, left as is"
        if b == "test-landscape.md": return "task-081"
        if b in ("architecture.md","decisions.md","module-map.md","tech-debt.md","artifact-schemas.md","domain-glossary.md","pipeline-contracts.md"): return "task-077"
        return "no change needed here (no delivery-003 task names this file; see Delta)"
    if path.startswith("dashboard/server/tests/") or path.startswith("dashboard/reader/tests/"): return "task-079"
    if path == "dashboard/home.html": return "task-073"
    if path.startswith("dashboard/reader/") or path.startswith("dashboard/server/"): return "task-070"
    if path.startswith("tests/canonical/fixtures/"): return "no change needed here (test fixture of the old shape, read by the migration suites)"
    if path.startswith("site/scripts/__tests__/") or path.startswith("site/src/lib/__tests__/"): return "no change needed here (no delivery-003 task names this file; see Delta)"
    return "no change needed here (no delivery-003 task names this file; see Delta)"

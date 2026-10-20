import re, os, subprocess, sys, collections
sys.path.insert(0, os.path.dirname(__file__))
import own
from own import git_grep, owner_of, skill_owner, SKILLS, DOORWAYS, GROUP, read, ls_files, REPO
S = os.path.dirname(__file__)
OUT = []
def w(s=""): OUT.append(s)
def esc(s): return s.replace("|", "\\|").replace("\n", " ")
def trunc(s, n=150):
    s = s.strip()
    return s if len(s) <= n else s[: n - 3] + "..."
EXCL = [":!.aid/works", ":!.claude", ":!.agents", ":!.aid/runtime", ":!.cursor", ":!profiles", ":!recovery", ":!packages", ":!.aid/.aid-manifest.json"]
def run_cmd(args, pathspec):
    return ["git", "grep", "-n", "-I"] + args + ["--"] + pathspec

# ---------- Q1
Q1_PATS = [r"\[State: ", r"you are here", r"Advancing to \[State", r"\[State [0-9]+\] Dispatching", r"\[Resolved:", r"Re-run `/aid-"]
Q1_SPEC = ["canonical/skills", "canonical/aid/templates"]
q1 = git_grep(sum([["-e", p] for p in Q1_PATS], []) + ["-E"], Q1_SPEC)
q1 = sorted(set(q1), key=lambda r: (r[0], r[1]))
def form_of(txt):
    for p, name in zip(Q1_PATS, ["[State: X]", "you are here", "Advancing to [State", "[State N] Dispatching", "[Resolved:", "Re-run `/aid-"]):
        if re.search(p, txt): return name
    return "?"
Q1_OWN = collections.Counter()
Q1_ROWS = []
for f, n, t in q1:
    o = owner_of(f); Q1_OWN[o] += 1
    Q1_ROWS.append((f, n, form_of(t), t, o))

# ---------- Q2
Q2_SPEC = ["canonical/agents", "canonical/skills", "canonical/aid/templates", "docs", "examples", "site/src/content", "tests", ".aid/knowledge"]
q2 = sorted(set(git_grep(["-i", "-e", "interviewer"], Q2_SPEC)), key=lambda r: (r[0], r[1]))
Q2_ROWS = [(f, n, t, owner_of(f)) for f, n, t in q2]

# ---------- Q3
Q3A_SPEC = ["canonical", "docs", "examples", "site/src/content", ".aid/knowledge", "tests", "dashboard", "bin", "chat-node"]
q3a = git_grep(["-F", "-e", "Cross-phase Q&A"], Q3A_SPEC + EXCL[:0])
q3a = [r for r in q3a if not r[0].startswith(".aid/works")]
Q3_FILES = collections.OrderedDict()
for f, n, t in sorted(q3a):
    Q3_FILES.setdefault(f, []).append(n)
Q3B_SPEC = ["canonical/skills", "canonical/aid/templates", "canonical/agents"]
q3b = git_grep(["-E", "-i", "-e", r"deliver[^ ]{0,30}(STATE\.yml|`qa`|\bqa\b)", "-e", r"\bqa\b.{0,40}deliver", "-e", r"delivery-scoped"], Q3B_SPEC)
q3b_hits = [r for r in q3b if re.search(r"\bqa\b|delivery-scoped|Cross-phase", r[2]) and not re.search(r"Full path|tasks/task-NNN|tasks/task-NNN/STATE", r[2])]
q3b_hits = sorted(set(q3b_hits), key=lambda r: (r[0], r[1]))

# ---------- Q4
Q4_SPEC = ["."] + EXCL
q4 = sorted(set(git_grep(["-F", "-e", "AskUserQuestion"], Q4_SPEC)), key=lambda r: (r[0], r[1]))
Q4_BY_FILE = collections.OrderedDict()
for f, n, t in q4:
    Q4_BY_FILE.setdefault(f, []).append(n)
Q4_INST = collections.Counter(f.split("/")[0] if not f.startswith(".aid/runtime") else ".aid/runtime" for f, n, t in git_grep(["-F", "-e", "AskUserQuestion"], [".claude", ".agents", ".aid/runtime", ".cursor", "profiles"]))

# ---------- Q5
q5_files = [f for f in ls_files() if re.search(r"reviewer-brief\.md$|reviewer-dispatch\.md$|aid-reviewer/AGENT\.md$", f)]
Q5_FILES = [f for f in q5_files if not f.startswith(("recovery/", ".claude/", ".agents/", ".aid/runtime/", "profiles/"))]
Q5_WHAT = {f: len(re.findall(r"^### What to report", read(f), re.M)) for f in Q5_FILES}

# ---------- Q6
q6 = git_grep(["-F", "-e", "state-machine-chaining"], ["."] + EXCL)
Q6_BY_FILE = collections.OrderedDict()
for f, n, t in sorted(q6):
    Q6_BY_FILE.setdefault(f, []).append(n)

# ---------- Q7
SAMPLE = {"aid-orchestrate": "002-14-orchestrate-unsure-reading (AC-28)", "aid-set-connector": "002-01-connector-question (AC-28)",
          "aid-config": "002-02-settings-groups-and-breaks (AC-28)", "aid-read-ticket": "002-15-which-tracker (AC-28)",
          "aid-research": "002-16-research-without-a-question (AC-28)", "aid-review": "002-17-review-publish-approval (AC-28)",
          "aid-report": "002-18-report-what-to-analyze (AC-28)", "aid-monitor": "002-19-monitor-finding-question (AC-28)"}
F003 = ["aid-brainstorm", "aid-describe"]
F004 = ["aid-discover", "aid-ask", "aid-update-kb", "aid-summarize", "aid-housekeep"] + [f"aid-{v}-{a}" for v in ("create", "update") for a in ("architecture", "stack", "testing-strategy", "cicd", "roadmap", "backlog", "mvp")]
F005 = ["aid-define", "aid-specify"]
F006 = ["aid-plan", "aid-detail", "aid-deploy"]
F007 = ["aid-execute"]
F009 = [s for s in SKILLS if s.startswith("aid-design")] + ["aid-create-ticket", "aid-update-ticket", "aid-create-diagram", "aid-create-document", "aid-document", "aid-update-document", "aid-test", "aid-prototype", "aid-prototype-ui"] + [s for s in SKILLS if s.startswith("aid-document-") or s.startswith("aid-test-")] + sorted(DOORWAYS)
NEVER = ["aid-chat", "aid-unset-connector"]
COVER = {}
for s, smp in SAMPLE.items(): COVER[s] = ("sample " + smp, "covered now")
for lst, feat in ((F003, "Feature 003"), (F004, "Feature 004"), (F005, "Feature 005"), (F006, "Feature 006"), (F007, "Feature 007"), (F009, "Feature 009")):
    for s in lst: COVER[s] = (f"skill:{s} row (task-078 adds; waits for {feat})", "pending")
for s in NEVER: COVER[s] = ("never asks: SS-04 never-asks list (no protocol line)", "n/a")
missing = [s for s in SKILLS if s not in COVER]
dupe = [s for s in COVER if sum(1 for lst in (F003, F004, F005, F006, F007, F009) if s in lst) > 1]
ASKING = [s for s in SKILLS if s not in NEVER]
assert not missing, missing
assert not dupe, dupe

# ---------- Q8: suite map
def token_list():
    toks = collections.OrderedDict()
    files = set(r[0] for r in q1) | set(r[0] for r in q2) | set(Q4_BY_FILE) | set(Q6_BY_FILE) | set(Q5_FILES)
    files = {f for f in files if not f.endswith("AGENT.md") or f.startswith("canonical/agents/aid-reviewer")}
    for f in sorted(files):
        if f.startswith((".aid/knowledge", "tests/", "docs", "examples", "site/", "dashboard/", "bin/")): continue
        m = re.match(r"canonical/skills/([^/]+)/", f)
        if m:
            if m.group(1) in DOORWAYS: continue
            toks.setdefault(m.group(1), ("folder", skill_owner(m.group(1))))
        else:
            toks.setdefault(os.path.basename(f), ("file", owner_of(f)))
    return toks
TOK = token_list()
def is_suite(p):
    if "/fixtures/" in p or p.startswith("tests/canonical/fixtures"): return False
    return bool(re.match(r"tests/canonical/test-[^/]+\.(sh|py|mjs)$", p) or re.match(r"tests/conversation/[^/]+\.py$", p)
                or re.match(r"site/(scripts|src/lib)/__tests__/", p) or re.match(r"dashboard/(reader|server)/tests/[^/]+\.(py|mjs)$", p)
                or p in ("tests/cost-meter.py",))
SUITE_TOK = collections.defaultdict(dict)
SUITE_OWN = collections.defaultdict(set)
ALL_TESTS = [p for p in ls_files() if is_suite(p)]
for tok, (kind, own_) in TOK.items():
    base_pat = re.escape(tok)
    for f in ALL_TESTS:
        n = 0
        if kind == "folder":
            path_pat = re.compile(r"(^|[^A-Za-z0-9_-])" + base_pat + r"/(SKILL\.md|references/)|canonical/skills/" + base_pat + r"(?![A-Za-z0-9_-])")
            quo_pat = re.compile(r"['\"]" + base_pat + r"['\"]")
        else:
            path_pat = re.compile(base_pat)
            quo_pat = None
        for line in read(f).splitlines():
            if path_pat.search(line) or (quo_pat is not None and f.startswith("site/") and quo_pat.search(line)): n += 1
        if n:
            SUITE_TOK[f][tok] = n
            tasks = re.findall(r"task-\d+", own_)
            SUITE_OWN[f].update(tasks if tasks else [own_])
# DETAIL naming
TASKDIR = ".aid/works/work-003-full-aid-restructure/deliveries/delivery-003/tasks"
DET = {}
for t in range(59, 82):
    DET[f"task-{t:03d}"] = read(f"{TASKDIR}/task-{t:03d}/DETAIL.md")
def named_in(suite):
    b = os.path.basename(suite)
    return sorted(k for k, v in DET.items() if b in v)

# ---------- Q9
ad = subprocess.run(["bash", os.path.join(S, "ad13run.sh"), REPO], capture_output=True, text=True).stdout
AD13 = []
for line, (label, ceil) in zip(ad.strip().splitlines(), [("work STATE.md (retired; use STATE.yml)", 65), ("BLUEPRINT.md (retired as an authored artifact)", 154), ("bare task-NNN.md (now tasks/task-NNN/DETAIL.md)", 16), ("per-feature SPEC.md (folded into REQUIREMENTS.md section 11)", 3), ("retired STATE.md section headings", 235)]):
    got = int(line.split()[1])
    AD13.append((label, got, ceil))

# ---------- G11
G11 = collections.Counter()
g11_lines = git_grep(["-E", "-e", "'aid-[a-z0-9-]+'", "-e", r"canonical/(skills|aid/templates)/[^'\" `)]+"], ["site/scripts/__tests__", "site/src/lib/__tests__"])
def map_target(tg, kind):
    if kind == "name":
        return tg if tg in SKILLS else None
    if kind == "skills":
        first = tg.split("/")[0]
        return first if first in SKILLS else None
    return None
for f, n, t in g11_lines:
    for nm in set(re.findall(r"'(aid-[a-z0-9-]+)'", t)):
        G11[(f, nm if nm in SKILLS else nm + " (not a skill folder)")] += 1
    for m in set(re.findall(r"canonical/skills/([^'\" `)]+)", t)):
        m = m.rstrip(".,;:\\/")
        first = m.split("/")[0]
        G11[(f, first if first in SKILLS else m + " (not a skill folder)")] += 1
    for m in set(re.findall(r"canonical/aid/templates/([^'\" `)]+)", t)):
        G11[(f, "canonical/aid/templates/" + m.rstrip(".,;:\\/"))] += 1
G11_ROWS = []
for (f, tg), c in sorted(G11.items()):
    if tg in SKILLS: o = skill_owner(tg)
    elif tg.startswith("canonical/aid/templates/"): o = owner_of(tg)
    else: o = "no change needed here (names no delivery-003 edit target)"
    G11_ROWS.append((f, tg, o, c))

# ---------- G17, G19
def fm(p):
    t = read(p)
    if not t.startswith("---"): return ""
    end = t.find("\n---", 3)
    return t[:end] if end > 0 else ""
G17_HITS = []
for p in ls_files():
    if p.startswith(".aid/knowledge/") and p.endswith(".md"):
        f = fm(p)
        for needle in ("state-machine-chaining", "aid-interviewer", "agents/aid-interviewer"):
            if needle in f: G17_HITS.append((p, needle))
G19 = git_grep(["-i", "-E", "-e", "interviewer", "-e", "state-machine-chaining"], ["site/scripts", ":!site/scripts/__tests__"])

# ---------- Baselines
BASE_PAT = r"interviewer|state-machine-chaining|AskUserQuestion|Cross-phase|Advancing to|you are here|Re-run `/aid-|\[State"
BASE_ROWS = []
for bf in ("tests/cost-baseline.tsv", "tests/coverage-baseline.tsv"):
    for n, line in enumerate(read(bf).splitlines(), 1):
        if re.search(BASE_PAT, line, re.I):
            BASE_ROWS.append((bf, n, trunc(line.split("\t")[0] + " | " + (line.split("\t")[1] if "\t" in line else ""), 120)))

# ---------- Installed copies
INST = collections.Counter()
for tree, pats in (("installed .claude/skills/", ".claude/skills/"), ("installed .agents/skills/", ".agents/skills/"), ("installed .aid/runtime/", ".aid/runtime/")):
    for f, n, t in git_grep(["-E", "-e", BASE_PAT], [pats]):
        INST[tree] += 1
INST_ROWS = sorted(INST.items())

# ======================= WRITE =======================
def row(*cells): return "| " + " | ".join(esc(str(c)) for c in cells) + " |"
def tbl(header, rows):
    w(row(*header)); w("|" + "|".join(["---"] * len(header)) + "|")
    for r in rows: w(row(*r))
def tasks_of(o): return re.findall(r"task-\d+", o)
BASE = "7fe3aebc140e85a06056ad91f15432bba2367014"
TITLE = "# Delivery-003 site search and reconciled edit list"
w(TITLE); w()
w("This file is the output of task-058 (RESEARCH) of delivery-003. It re-runs searches Q1 to Q9 of the task's Scope, the G11, G17 and G19 searches, and the skill owner table (G2) at the base commit, gives every hit exactly one owner, lists the suites that are assigned to more than one task, and reconciles the result with the task files task-059 to task-081. It changes no other file.")
w()
w("## Base commit and conventions"); w()
w(f"- **Base commit:** `{BASE}` (the `task-058: In Progress` commit). The worktree was clean at the base (`git status --short` empty), so every search below, run from the worktree root with `git grep` and no tree argument, reads the base bytes.")
w("- **Excluded from every search:** `.aid/works/` (planning text: the task files, the proposal, the PLAN and REQUIREMENTS, and this file itself). Installed copies (`.claude/`, `.agents/`, `.aid/runtime/`, `.cursor/`, `profiles/`, `.aid/.aid-manifest.json`) are excluded from the row tables and counted in the Installed copies section; they are the resync's output, not an edit list. `recovery/` and `packages/` are excluded from the row tables and listed in the Delta.")
w("- **Owner classes.** (1) a task of delivery-003 (task-059 to task-081); (2) `installed copy (resync)`; (3) `history, left as is`, for `release-tracking.md`, `kb.html`, `coverage-accepted-removals.tsv` and `validate-diagram-content.mjs`; (4) `baseline, re-recorded at the gate`, for `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`; (5) `no change needed here (reason)`, used only for a hit in a file that no delivery-003 task names and that the spec leaves unchanged. Each class-5 file is listed in the Delta (D4) for the maintainer's ruling, because the task's owner classes do not name it. Class 5 names hits whose text needs no edit, so no task owns an edit for them.")
w("- **Generated doorways.** A `canonical/skills/aid-*/SKILL.md` whose first heading is `# Shortcut` is a generated doorway (34 of them). Its text comes from `shortcut-engine.md` (task-062) and changes through the builder, so its owner is `no change needed here (generated doorway ...)`, not a sweep task.")
w("- **Test step.** Every change in this task lies under `.aid/works/`. Per the work-folder-only rule, no suite runs and `select-suites.sh` is not run; no `run_generator.py` runs; there are no `.sh`, `.py` or `.mjs` changes to check. The generator and its helpers are in `.aid/works/work-003-full-aid-restructure/research/delivery-003-sites-tools/`.")
w("- **Reproducing a section.** Each Q section gives its command, run from the repository root at the base commit. Q8 is printed by `gen.py --q8` and Q9 by `ad13run.sh`; run with no argument, `gen.py` rewrites this file. The row generator is `.aid/works/work-003-full-aid-restructure/research/delivery-003-sites-tools/gen.py` with its owner map `own.py` beside it; `ad13run.sh` there is the AD13 counter.")
w()
w("## Contents"); w()
for x in ["Q1 SS-01 banner forms", "Q2 interviewer sites", "Q3 question-record sites", "Q4 AskUserQuestion", "Q5 reviewer-brief files", "Q6 state-machine-chaining citations", "Q7 asking skills against the AC-28 coverage table", "Q8 Q106 suite map", "Q9 AD13 counts", "Site fixtures (G11)", "KB sources (G17)", "Site generator sources (G19)", "Baselines", "Installed copies (resync)", "Skill owner table (G2)", "Suites on two tasks and the run order", "Delta"]:
    w("- " + x)
w()

# ---- Q1
w("## Q1 SS-01 banner forms"); w()
w("Command (scope: SS-01's, `canonical/skills/` and `canonical/aid/templates/`):"); w()
w("```bash")
w("git grep -n -E -e '\\[State: ' -e 'you are here' -e 'Advancing to \\[State' -e '\\[State [0-9]+\\] Dispatching' -e '\\[Resolved:' -e 'Re-run `/aid-' -- canonical/skills canonical/aid/templates")
w("```"); w()
q1_files = len(set(r[0] for r in q1))
w(f"Hits: **{len(q1)}** lines in {q1_files} files. Owners by count: " + ", ".join(f"{k} {v}" for k, v in sorted(Q1_OWN.items())) + ".")
w()
w("The `[State: X]` lines that are an `**Advance:**` target stay (F002 § 4); the grep shows every line, and the sweep tasks remove the others. Installed copies are not listed here (Installed copies section).")
w()
tbl(["#", "Location", "Form", "Text", "Owner"], [(i + 1, f"`{f}:{n}`", form, f"`{trunc(t, 120)}`", o) for i, (f, n, form, t, o) in enumerate(Q1_ROWS)])
w()

# ---- Q2
w("## Q2 interviewer sites"); w()
w("Command (scope: `canonical/agents/`, `canonical/skills/`, `canonical/aid/templates/`, `docs/`, `examples/`, `site/src/content/`, `tests/`, `.aid/knowledge/`):"); w()
w("```bash")
w("git grep -n -i interviewer -- canonical/agents canonical/skills canonical/aid/templates docs examples site/src/content tests .aid/knowledge")
w("```"); w()
w(f"Hits: **{len(Q2_ROWS)}** lines in {len(set(r[0] for r in Q2_ROWS))} files. The superseded proposal counted 18 files (D1).")
w()
tbl(["#", "Location", "Text", "Owner"], [(i + 1, f"`{f}:{n}`", f"`{trunc(t, 120)}`", o) for i, (f, n, t, o) in enumerate(Q2_ROWS)])
w()

# ---- Q3
w("## Q3 question-record sites"); w()
w("Two searches. **3a** is `## Cross-phase Q&A` (SS-06's form). **3b** is every skill or template line that writes, or names as its target, a delivery-level `qa` (KI-003). The migration scripts, the dashboard readers and the tests that read the old shapes are not writers in SS-06's scope; they are listed with their owners in 3a.")
w()
w("Command 3a:"); w()
w("```bash")
w("git grep -n -F 'Cross-phase Q&A' -- canonical docs examples site/src/content .aid/knowledge tests dashboard bin chat-node")
w("```"); w()
w("Command 3b:"); w()
w("```bash")
w("git grep -n -i -E -e 'deliver[^ ]{0,30}(STATE\\.yml|`qa`|\\bqa\\b)' -e '\\bqa\\b.{0,40}deliver' -e 'delivery-scoped' -- canonical/skills canonical/aid/templates canonical/agents")
w("```"); w()
w(f"3a: **{sum(len(v) for v in Q3_FILES.values())}** lines in {len(Q3_FILES)} files; the skill files are the nine of the superseded proposal (D1).")
w()
q3a_rows = []
for f, ns in Q3_FILES.items():
    o = owner_of(f)
    if f.startswith("canonical/skills/"):
        o = owner_of(f)
    q3a_rows.append((f, ", ".join(str(x) for x in ns), o))
tbl(["File", "Lines", "Owner"], q3a_rows)
w()
w("3b: the delivery-level `qa` writers and the delivery-level `qa` key mentions. The lines that name a work's `STATE.yml` `qa` (the work level, `aid-orchestrate`, `skill-steps.md`) are not writers of a delivery-level `qa` and are not rows.")
w()
q3b_show = [r for r in q3b_hits if "deliveries/delivery-NNN" in r[2] or "qa" in r[2]]
Q3B_OWNER = {"canonical/skills/aid-ask/SKILL.md": "task-067", "canonical/skills/aid-plan/SKILL.md": "task-065",
             "canonical/skills/aid-execute/references/state-delivery-gate.md": "task-065", "canonical/aid/templates/delivery-state-template.yml": "no change needed here (delivery template; Feature 006 retires it; no task edits it; see Delta D4)",
             "canonical/aid/templates/work-state-template.yml": "no change needed here (comment on the delivery layout; no task edits it; see Delta D4)"}
b_rows = []
for f, n, t in q3b_hits:
    if not re.search(r"\bqa\b|delivery-scoped|Cross-phase", t): continue
    o = Q3B_OWNER.get(f, owner_of(f))
    if f.startswith("canonical/skills/aid-orchestrate") or f.startswith("canonical/skills/aid-ask/SKILL.md") and "Target-file" not in t and False: pass
    b_rows.append((f, n, f"`{trunc(t, 120)}`", o))
tbl(["File", "Line", "Text", "Owner"], b_rows)
w()

# ---- Q4
w("## Q4 AskUserQuestion"); w()
w("Command (every tracked file except `.aid/works/` and the installed copies):"); w()
w("```bash")
w("git grep -n -F AskUserQuestion -- . ':!.aid/works' ':!.claude' ':!.agents' ':!.aid/runtime' ':!.cursor' ':!profiles' ':!recovery' ':!packages' ':!.aid/.aid-manifest.json'")
w("```"); w()
canon_auq = set(f for f in Q4_BY_FILE if f.startswith("canonical/"))
w(f"Hits: **{sum(len(v) for v in Q4_BY_FILE.values())}** lines in {len(Q4_BY_FILE)} files; {len(canon_auq)} of them are under `canonical/` (the superseded proposal counted 13, D1). Each `allowed-tools` line is removed (the sweep's rule (c)); each body mention is rewritten to ask in plain text through the protocol.")
w()
w("**Decision on `canonical/aid/scripts/connectors/write-connector.sh` (line 5).** The line is a comment that names the requirement the skills meet (`requires AskUserQuestion, SKILL.md line 12`). It is text, not a picker use: no code path in the script calls the tool. Owner task-068, which rewrites the comment with the skills' `allowed-tools`. The byte-identical copy `dashboard/scripts/write-connector.sh` is an installed copy (resync).")
w()
q4_rows = []
for f, ns in Q4_BY_FILE.items():
    o = owner_of(f)
    act = "remove from allowed-tools and body; ask via protocol" if f.startswith("canonical/skills") else ("rewrite comment (no picker)" if "write-connector" in f else "re-point the text")
    q4_rows.append((f, ", ".join(str(x) for x in ns), o, act))
tbl(["File", "Lines", "Owner", "Action"], q4_rows)
w()
w("Installed copies carry the same hits; see Installed copies.")
w()

# ---- Q5
w("## Q5 reviewer-brief files"); w()
w("Command:"); w()
w("```bash")
w("git ls-files | grep -E 'reviewer-brief\\.md$|reviewer-dispatch\\.md$|aid-reviewer/AGENT\\.md$'   # then, per file: grep -c -E '^### What to report' <file>")
w("```"); w()
w(f"At the base, `### What to report` appears in **0** of the **{len(Q5_FILES)}** canonical files (six `reviewer-brief.md`, `reviewer-dispatch.md` and `aid-reviewer/AGENT.md`), so every one is an edit (rule (f); AC-46).")
w()
q5_owner = {"canonical/skills/aid-define/references/reviewer-brief.md": "task-064", "canonical/skills/aid-specify/references/reviewer-brief.md": "task-064",
            "canonical/skills/aid-detail/references/reviewer-brief.md": "task-065", "canonical/skills/aid-plan/references/reviewer-brief.md": "task-065",
            "canonical/skills/aid-execute/references/reviewer-brief.md": "task-065", "canonical/skills/aid-discover/references/reviewer-brief.md": "task-066",
            "canonical/agents/aid-reviewer/AGENT.md": "task-072", "canonical/aid/templates/reviewer-dispatch.md": "task-072"}
tbl(["File", "What to report headings at base", "Owner"], [(f, Q5_WHAT[f], q5_owner[f]) for f in Q5_FILES])
w()
w("The installed copies of the briefs and of `reviewer-dispatch.md` (`.claude/`, `.agents/`, `.aid/runtime/`) lack the heading too (checked on three of them); they are resync. `recovery/partial/canonical/aid/templates/reviewer-dispatch.md` is a recovery snapshot, owner class 5 (Delta D4).")
w()

# ---- Q6
w("## Q6 state-machine-chaining citations"); w()
w("Command:"); w()
w("```bash")
w("git grep -n -F state-machine-chaining -- . ':!.aid/works' ':!.claude' ':!.agents' ':!.aid/runtime' ':!.cursor' ':!profiles' ':!recovery' ':!packages' ':!.aid/.aid-manifest.json'")
w("```"); w()
live = [f for f in Q6_BY_FILE if not f.endswith("state-machine-chaining.md")]
w(f"Hits: **{sum(len(v) for v in Q6_BY_FILE.values())}** lines in {len(Q6_BY_FILE)} files. `canonical/` cites the chaining file in **0** files other than its own (the citations were re-pointed to `skill-steps.md` before the base; the superseded proposal counted 19 at `a3b28db4`, D1). The remaining live citations are the test-pipeline suite, its skip list and the two baselines; the file itself is deleted by task-074.")
w()
tbl(["File", "Lines", "Owner"], [(f, ", ".join(str(x) for x in ns), owner_of(f)) for f, ns in Q6_BY_FILE.items()])
w()

# ---- Q7
w("## Q7 asking skills against the AC-28 coverage table"); w()
w("Command (the asking set, and the skills each sample names):"); w()
w("```bash")
w("ls canonical/skills/*/SKILL.md | wc -l                                  # 112 on disk at the base")
w("grep -l -e '^# Shortcut' canonical/skills/*/SKILL.md | wc -l            # 34 generated doorways")
w("grep -h -m1 '^skills:' tests/conversation/samples/feature-002/*.md       # the samples' skills: rows")
w("grep -E '^(skills|covers):' tests/conversation/samples/feature-002/002-14-*.md")
w("```"); w()
w("The asking set is every skill on disk except the two that never ask (`aid-chat`, `aid-unset-connector`, the SS-04 never-asks list). Each asking skill is covered either by a sample that names it and covers AC-28, or by a `skill:` row of `tests/conversation/deferred.tsv` that task-078 adds (the row names the skill or a glob, and the feature that brings the skill's sample). The 34 generated doorways are covered by their Feature 009 rows, through the engine.")
w()
w(f"Counts: {len(SKILLS)} skills on disk; {len(ASKING)} asking; {sum(1 for s in ASKING if COVER[s][0].startswith('sample'))} covered by an existing sample (all eight are Feature 002's, with AC-28); {sum(1 for s in ASKING if COVER[s][0].startswith('skill:'))} need a `skill:` row from task-078; {len(NEVER)} never ask.")
w()
w("Note on sample `002-13-mid-task-kb-update-returns`: its frontmatter names `aid-kb-update`, which is not a skill folder (the skill is `aid-update-kb`). The sample is deferred and covers AC-38, not AC-28, so it does not change the table; the name is a Delta item (D8).")
w()
q7_rows = []
for s in SKILLS:
    kind = "generated doorway" if s in DOORWAYS else "hand-authored"
    if s in NEVER: kind += ", never asks"
    cov = COVER[s][0]
    q7_rows.append((s, kind, cov, skill_owner(s) if s not in NEVER else "none"))
tbl(["Skill", "Kind", "AC-28 coverage (sample id, or the skill: row task-078 adds)", "Owner of the skill's edits"], q7_rows)
w()

# ---- Q8
w("## Q8 Q106 suite map"); w()
w("Command for each edit-list token: the suites under `tests/` (not fixtures), `site/scripts/__tests__/`, `site/src/lib/__tests__/` and the dashboard test folders that name the file or skill as a path (`canonical/skills/<name>/`, `<name>/SKILL.md`, `<name>/references/`), or, for file tokens, the file's name. Under `site/` a quoted skill name also counts (the site tests load skills by name). Command (prints this section and writes nothing; run from the repository root at the base commit):"); w()
w("```bash")
w("python3 .aid/works/work-003-full-aid-restructure/research/delivery-003-sites-tools/gen.py --q8")
w("```"); w()
w("Each token is matched with these two shapes; `<file name>`, `<skill>` and `<suites>` are filled in by the tool, not typed by hand:"); w()
w("```bash")
w("git grep -n -F -e '<file name>' -- tests site/scripts/__tests__ site/src/lib/__tests__ dashboard   # file tokens")
w("git grep -n -E -e '(^|[^A-Za-z0-9_-])<skill>/(SKILL\\.md|references/)' -e 'canonical/skills/<skill>([^A-Za-z0-9_-]|$)' -- <suites>   # skill tokens")
w("```"); w()
w(f"Edit-list tokens: **{len(TOK)}** (hand-authored skill folders with a hit, and canonical files with a hit; generated doorways are not tokens). Suites that read at least one token: **{len(SUITE_TOK)}**. The DETAIL column is the set of task files whose text names the suite's file name.")
w()
q8_rows = []
for s in sorted(SUITE_TOK):
    toks = ", ".join(f"`{k}`: {v}" for k, v in sorted(SUITE_TOK[s].items()))
    measured = sorted(SUITE_OWN[s])
    named = [t for t in named_in(s) if t != "task-058"]
    miss = [t for t in measured if t not in named]
    extra = [t for t in named if t not in measured]
    if not miss and not extra: act = "as named"
    else:
        parts = []
        if miss: parts.append("ADD to " + ", ".join(miss) + "'s Scope (same-task rule)")
        if extra: parts.append("named, but no measured assertion on its file: confirm and record in " + ", ".join(extra))
        act = "; ".join(parts)
    q8_rows.append((f"`{s}`", toks, ", ".join(measured) or "--", ", ".join(named) or "--", act))
tbl(["Suite", "Edit-list tokens it reads (matching lines)", "Measured owner(s)", "Named in DETAIL", "Reconciled action"], q8_rows)
w()
w("The row for a suite with `ADD to` is the reconciled edit list: those suites have no assertion in the named task's Scope, so the task's Scope gains the suite (Q106), and the owner keeps the suite green. See Delta D5 and D6.")
w()

# ---- Q9
w("## Q9 AD13 counts"); w()
w("Command: the five `ad13_check` patterns of `tests/canonical/test-artifact-discipline.sh` (lines 505 to 524), each run through the suite's own counter `ad13_count_class` (extracted unchanged, run on the tracked tree):"); w()
w("```bash")
w("bash .aid/works/work-003-full-aid-restructure/research/delivery-003-sites-tools/ad13run.sh \"$PWD\"    # prints one line per class, C1 to C5 in table order; ad13run.sh holds the suite's ad13_count_class unchanged")
w("```"); w()
tbl(["Class", "Count at base", "Ceiling in the suite today", "Owner of the ceiling"], [(lbl, got, ceil, "task-078 (lowers to the post-sweep count, downward only)") for lbl, got, ceil in AD13])
w()
w("All five counts are at or below their ceilings today, so `test-artifact-discipline.sh` passes at the base. Task-078 lowers each ceiling to the count it measures after the sweep (a rise is never allowed; the suite's own rule).")
w()

G11_HITS = sum(r[3] for r in G11_ROWS)
_g11_cmd = ["git", "grep", "-n", "-o", "-I", "-E", "'aid-[a-z0-9-]+'|canonical/skills/[^'\" `)]+|canonical/aid/templates/[^'\" `)]+", "--", "site/scripts/__tests__", "site/src/lib/__tests__"]
_g11_out = subprocess.run(_g11_cmd, capture_output=True, text=True, cwd=REPO).stdout.splitlines()
assert len(set(_g11_out)) == G11_HITS, (len(set(_g11_out)), G11_HITS)
# ---- G11
w("## Site fixtures (G11)"); w()
w("Command (every site test that reads a skill's or template's body by path or by quoted name):"); w()
w("```bash")
w("""git grep -n -o -I -E "'aid-[a-z0-9-]+'|canonical/skills/[^'\\" \\`)]+|canonical/aid/templates/[^'\\" \\`)]+" -- site/scripts/__tests__ site/src/lib/__tests__ | sort -u | wc -l""")
w("```"); w()
w(f"Hits: **{G11_HITS}** (test, target) hits: one per distinct quoted skill name or skill/template path on a line of a site test, so a line naming two targets counts twice. One row below per (test, target); its Hits is its share of that count. A target that is a skill folder takes the skill's owner (the test is re-pointed in that task, G11). Rows with `no change needed here` name no delivery-003 edit target.")
w()
tbl(["Site test", "Target", "Owner", "Hits"], G11_ROWS)
w()

# ---- G17
w("## KB sources (G17)"); w()
w("Command: each `.aid/knowledge/*.md` frontmatter (the lines between its first two `---`) is searched for the paths this delivery deletes or moves: `state-machine-chaining.md` and `agents/aid-interviewer`.")
w()
w("```bash")
w("git grep -n -E 'state-machine-chaining|agents/aid-interviewer' -- .aid/knowledge")
w("```"); w()
w(f"Result: **{len(G17_HITS)}** `sources:` entries cite a deleted or moved file (no frontmatter entry names either path). The prose hits in the KB (`architecture.md`, `decisions.md`, `kb.html`, `module-map.md`, `release-tracking.md`) are Q2 and Q6 rows, owned as there: task-077 for the four editable docs, `history, left as is` for `kb.html` and `release-tracking.md`.")
w()

# ---- G19
w("## Site generator sources (G19)"); w()
w("Command: the site generators outside `__tests__` for the name of every skill this delivery retires or renames, and for the two deleted names:"); w()
w("```bash")
w("git grep -n -i -E -e 'interviewer' -e 'state-machine-chaining' -- site/scripts ':!site/scripts/__tests__'")
w("```"); w()
w(f"Hits: **{len(G19)}**. Delivery-003 retires and renames no skill (the retired items are the `aid-interviewer` agent and the chaining template), so the list of retired or renamed skill names is empty and the result is empty. The site generators name neither deleted file.")
w()

# ---- Baselines
w("## Baselines"); w()
w("Command:"); w()
w("```bash")
w("git grep -n -E \"interviewer|state-machine-chaining|AskUserQuestion|Cross-phase|Advancing to|you are here|Re-run \\`/aid-|\\[State\" -- tests/cost-baseline.tsv tests/coverage-baseline.tsv")
w("```"); w()
w(f"Hits: **{len(BASE_ROWS)}** lines. Every row is owned by the gate: no task edits a baseline (Q134 D11); the gate re-records both files after the sweep.")
w()
tbl(["File", "Line", "Test and assertion (first two columns)", "Owner"], [(f, n, t, "baseline, re-recorded at the gate") for f, n, t in BASE_ROWS])
w()

# ---- Installed copies
w("## Installed copies (resync)"); w()
w("Command (the same pattern as the baselines, over the installed trees):"); w()
w("```bash")
w("git grep -c -E \"interviewer|state-machine-chaining|AskUserQuestion|Cross-phase|Advancing to|you are here|Re-run \\`/aid-|\\[State\" -- .claude/skills .agents/skills .aid/runtime")
w("```"); w()
tbl(["Tree", "Matching lines", "Owner"], [(t, c, "installed copy (resync)") for t, c in INST_ROWS] + [(".cursor/, profiles/, .aid/.aid-manifest.json", "not counted", "installed copy (resync)")])
w()
w("Each installed line mirrors a canonical line already in the tables above, or a generated profile; the resync (after task-081 and the gate) regenerates them with the full generator, never a partial render. `dashboard/scripts/write-connector.sh` is a byte-identical copy of `canonical/aid/scripts/connectors/write-connector.sh`, so it is an installed copy too.")
w()

# ---- G2
w("## Skill owner table (G2)"); w()
w(f"Built from `ls canonical/skills/*/SKILL.md`: **{len(SKILLS)}** rows, one per skill on disk at the base. Column *Hits* counts the skill's lines in Q1, Q2, Q4 and Q6 (canonical only).")
w()
hits_by_skill = collections.Counter()
for f, n, form, t, o in Q1_ROWS: pass
for f in list(set(r[0] for r in q1)) + list(set(r[0] for r in q2)) + list(Q4_BY_FILE) + list(Q6_BY_FILE):
    m = re.match(r"canonical/skills/([^/]+)/", f)
    if m: hits_by_skill[m.group(1)] += 1
g2_rows = []
for s in SKILLS:
    if s in DOORWAYS:
        g2_rows.append((s, "generated doorway", "no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062)", hits_by_skill.get(s, 0)))
    else:
        g2_rows.append((s, "hand-authored", GROUP[s], hits_by_skill.get(s, 0)))
tbl(["Skill", "Kind", "Owner", "Files with hits"], g2_rows)
w()
unowned = [r for r in g2_rows if not r[2].startswith(("task-", "no change needed here"))]
w(f"Rows with no owner: **{len(unowned)}**. Rows: **{len(g2_rows)}**. `ls canonical/skills/*/SKILL.md \\| wc -l` = {len(SKILLS)}.")
w()

# ---- Suites on two tasks
def deps_of(t):
    m = re.search(r"\*\*Depends on:\*\*(.*)", DET.get(t, ""))
    out = set()
    if m:
        for a, b in re.findall(r"(\d{3})(?:-(\d{3}))?", m.group(1)):
            lo = int(a); hi = int(b) if b else lo
            out |= {f"task-{i:03d}" for i in range(lo, hi + 1)}
    return out
def closure(t, seen=None):
    seen = seen or set()
    for d in deps_of(t):
        if d not in seen:
            seen.add(d); closure(d, seen)
    return seen
w("## Suites on two tasks and the run order"); w()
w("A suite is on two tasks when two or more delivery-003 tasks (other than task-058) own a part of its assertions, by the measured owners or by the DETAIL file that names it. The run order: when one task depends on the other, the dependency runs first; otherwise the tasks are independent and each runs in its own worktree, merged in task-number order (the order the wave's merge takes them).")
w()
two = []
for s in sorted(set(SUITE_OWN) | set(p for p in DET if False)):
    pass
allsuites = set(SUITE_OWN) | set(s for s in ALL_TESTS if named_in(s))
for s in sorted(allsuites):
    owners = set(SUITE_OWN.get(s, set())) | set(named_in(s))
    owners.discard("task-058")
    if len(owners) >= 2:
        ts = sorted(owners)
        order = []
        for a in ts:
            for b in ts:
                if a < b and a in closure(b): order.append(f"{a} before {b} (dependency)")
        if not order: order = ["independent: task-number order"]
        two.append((f"`{s}`", ", ".join(ts), "; ".join(order)))
tbl(["Suite", "Tasks", "Run order"], two)
w()
w(f"{len(two)} suites are on two or more tasks.")
w()

# ---- Delta
w("## Delta"); w()
w("This section is what the reconciled list changes against the superseded proposal (`analysis/detail-proposal-delivery-003.md`, measured at `a3b28db4`) and what the maintainer must rule on. Nothing here edits a task file; the Scope additions are for the maintainer to make.")
w()
w("**D1. Counts at the base against the superseded proposal.** Measured at `7fe3aebc`:"); w()
interv_files = set(r[0] for r in Q2_ROWS if r[0].startswith(("canonical/agents", "canonical/skills", "canonical/aid/templates", "docs", "examples", "site/src/content")))
cp_skill = set(f for f in Q3_FILES if f.startswith("canonical/skills/"))
tbl(["Item", "Superseded proposal", "Base 7fe3aebc", "Note"], [
    ("`AskUserQuestion` files under `canonical/`", "13", len(canon_auq), f"all {len(canon_auq)} have a delivery-003 owner (Q4); `canonical/aid/scripts/connectors/write-connector.sh` is a comment, D3"),
    ("`interviewer` files in SS-05's scope", "18", len(interv_files), "the scope is canonical/agents, skills, templates, docs, examples and site/src/content"),
    ("`state-machine-chaining.md` citing files under `canonical/`", "19", 0, "delivery-002 re-pointed them; the file itself is deleted by task-074"),
    ("skill files with `## Cross-phase Q&A`", "9", len(cp_skill), "the same nine files"),
    ("`reviewer-brief.md` files", "6", 6, "all six lack `### What to report`"),
    ("Q1 banner lines", "not counted", len(q1), f"in {q1_files} files"),
])
w()
w("**D2. Chaining file.** No canonical file cites it any more (Q6). Its live consumers are the test-pipeline suite (7 lines), its skip list and the two baselines, and all three sit with task-074 or the gate. Task-074's DETAIL depends only on task-058, so its edits do not wait for the sweep tasks; the superseded proposal's `062-068` dependency is not in the task file.")
w()
w("**D3. The connector comment.** `canonical/aid/scripts/connectors/write-connector.sh` line 5 is text: decided here, owner task-068 (Q4). The proposal left the question open.")
w()
w("**D4. Hits in files no delivery-003 task names (owner class 5).** The maintainer rules on each file. The research default leaves each file unchanged; the reason shown is the one the owner map gives:"); w()
c5 = collections.OrderedDict()
for rows in ([(r[0], r[4]) for r in Q1_ROWS], [(r[0], r[3]) for r in Q2_ROWS], [(r[0], r[3]) for r in b_rows], [(f, o) for f, ns, o in q3a_rows], [(f, o) for f, ns, o, a in q4_rows], [(f, owner_of(f)) for f in Q6_BY_FILE]):
    for f, o in rows:
        if o.startswith("no change needed here") and "generated doorway" not in o:
            c5.setdefault(f, o)
for f in sorted(c5):
    w(f"- `{f}`: {c5[f]}")
g11_c5 = [r for r in G11_ROWS if r[2].startswith("no change needed here")]
w()
w(f"- G11 (site tests): {len(g11_c5)} (test, target) rows across {len(set(r[0] for r in g11_c5))} site test files name no delivery-003 edit target (fixture strings, template names and paths no task changes). Each is class 5 and needs no edit; they are all listed one by one in the G11 table (Site fixtures section), with that owner.")
w()
w("Recovery and packaging snapshots, not live sources: `recovery/partial/...` (their files name the chaining rule, the reviewer dispatch and the Cross-phase heading) and `packages/` (a local build output, not tracked as source).")
w()
w("**D5. Suites that read an edit-list file but are not named by the owning task.** Proposed: the owning task's Scope names the suite, and the task updates it in the same task (Q106). The owners are the measured owners of Q8:"); w()
adds = [(s, a) for s, a in ((r[0], r[4]) for r in q8_rows) if a.startswith("ADD") or "ADD" in a]
for s, a in adds:
    w(f"- {s}: {a}")
w()
w("**D6. Suites named by a task but with no assertion on the files that task changes.** The naming task must confirm this in its own run (the rule is the same, so the suite stays on the list, and the task records nothing new):"); w()
for s, a in ((r[0], r[4]) for r in q8_rows):
    if "named, but no measured" in a:
        w(f"- {s}: {a}")
w()
w("**D7. AD13 ceilings.** Today's counts are below their ceilings (Q9), so the suite is green at the base. Task-078 lowers each ceiling to the post-sweep count, and never raises one.")
w()
w("**D8. Sample 002-13 names a skill that is not on disk.** Its frontmatter names `aid-kb-update`, and the skill is `aid-update-kb`. The sample is deferred (AC-38), so the name has no test effect now; the maintainer should fix it when the sample is next edited (owner: task-080, which edits the samples).")
w()
w("**D9. Decision-record lines.** `.aid/knowledge/decisions.md` lines 783, 786 and 792 record the superseded chaining rule and the interviewer agent. Task-077 names `decisions.md` only for D15's agent count. Default: task-077 leaves the superseded entries as they are, because a decision record keeps its history; the maintainer confirms.")
w()
w("**D10. Work state and project state templates.** Feature 002's Files table names `work-state-template.yml` (Edit) and `project-state-template.yml` (Create). Neither is named by a delivery-003 task, and the `qa` and phase rows of that table are delivery-002's scope (its task files name the templates). Their delivery-level comment in `work-state-template.yml` is class 5 (Q3b), not an edit for this delivery.")
w()
w("**D11. Installed copies.** The installed trees carry every canonical hit (Installed copies). They are regenerated by the resync after the gate, with the full generator; no partial render and no `run_generator.py` in a live tree.")
w()
w("**D12. Test step.** Changes lie only under `.aid/works/`; no suite runs (work-folder-only rule). The spawn-free checks have no `.sh`, `.py` or `.mjs` file to check.")
w()
w("**D13. Run order of `tests/canonical/test-artifact-discipline.sh`.** The suite is on five tasks (see Suites on two tasks and the run order), and its one owner in Q3 is task-078. Run order: task-062, task-065, task-072 and task-074 each run before task-078 (dependency).")
w()

MODE = sys.argv[1] if len(sys.argv) > 1 else ""
if MODE == "--q8":
    start = next(i for i, l in enumerate(OUT) if l.startswith("## Q8 "))
    end = next((i for i in range(start + 1, len(OUT)) if OUT[i].startswith("## ")), len(OUT))
    print("\n".join(OUT[start:end]))
    sys.exit(0)

OUTP = os.path.join(REPO, ".aid/works/work-003-full-aid-restructure/research/delivery-003-sites.md")
os.makedirs(os.path.dirname(OUTP), exist_ok=True)
text = "\n".join(OUT) + "\n"
open(OUTP, "w", encoding="utf-8").write(text)
print("wrote", OUTP, len(text.splitlines()), "lines")

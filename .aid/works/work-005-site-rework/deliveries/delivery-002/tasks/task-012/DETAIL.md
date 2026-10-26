# task-012: Glossary term anchors and glossary page audit

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** feature-001-content-audit -> delivery-002 -> AC-3, AC-12

**Depends on:** task-006

**Scope:**
- Feature 001 § Data Model 3 "Glossary anchors", and § Feature Flow steps 2-5 for one page:
  `site/src/content/docs/reference/glossary.md` (/reference/glossary/). It runs before the other audit
  tasks (tasks 013-022), because their rule-P2 links point at the anchors made here.
- Anchors (§ Data Model 3):
  - Keep every `##` group heading.
  - Turn each term, written today as a paragraph that opens `**Term:**`, into an `###` heading whose text
    is the term alone, followed by its definition as a paragraph. A parenthetical is moved into the
    definition: `### Knowledge Base`, whose definition opens with "(KB)". The anchor is the id Starlight
    generates from the heading (`knowledge-base`); links to a term use `/reference/glossary/#<anchor>`.
  - Add `tableOfContents: { maxHeadingLevel: 2 }` to the frontmatter, so the table of contents lists the
    groups, not every term.
  - Same-page links (`](#...)`) still resolve after the change.
- Audit of the page (Feature Flow steps 2-5):
  - List every checkable claim and check it against the row's sources (DOC `docs/glossary.md`, SK, SC,
    TPL; codes in the audit's § Sources of truth), with the checks of Feature 001 § Feature Flow step 3.
  - Correct each false or stale claim, and delete a claim that no source can prove. A term whose whole
    definition is unprovable is deleted, and the Correction cell names it.
  - Bring the page in line with rules P1-P9 (Feature 001 § Feature Flow, "Plain-language rules"). P1: the
    first paragraph under the `h1` is one sentence of purpose, identical to `description`. P4: the
    hand-written skill, catalog and document counts go (a Specify lead names this page). P5: the
    change-history wording goes (a lead names this page).
  - Record, in `.aid/works/work-005-site-rework/site-audit.md`: set the `reference/glossary.md` row of
    § Pages to `ok` or `corrected`, with one sentence per change naming the source that proved it. Remove
    `/reference/glossary/` from the Page cell of every row of § Leads found at Specify, after moving what
    the lead said into the page row; a lead row left with no page is deleted.
- The `sourceDoc:` frontmatter line stays: Feature 005 step 4 removes it in delivery-003.
- Not in this task:
  - No other page edited. Links from other pages to the new anchors are added by their own audit tasks.
  - No `site/astro.config.mjs` edit, no `<Tabs>` change, no diagram.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`).
    Inside that set, only the glossary page, the audit file and the helper file below change.
- Audit check helpers. Before running its checks, this task writes
  `.aid/works/work-005-site-rework/audit-checks.sh` with exactly the content below. It is the single copy
  of the helpers that every audit task (012-022) sources; the tasks 013-022 only set their own `P`, `U`
  and extra variables after sourcing it, and a later fix to a helper is made in this file, not in a task.
  The `p1` helper compares the first paragraph with `description` as plain text (a Markdown or `<a>` link
  counts as its link text; `**`, `__` and backticks are ignored), so a rule-P2 glossary link inside the
  purpose sentence does not fail rule P1.

```bash
D=src/content/docs
A=../.aid/works/work-005-site-rework/site-audit.md
code() { awk '/^ *(```|~~~)/{c=!c;next} !c' "$1" | sed 's/`[^`]*`//g'; }
row() { local n; n=$(grep -cF "| \`$D/$1\` " "$A"); [ "$n" = 1 ] || echo "rows=$n: $1"
  grep -F "| \`$D/$1\` " "$A" | awk -F'|' -v p="$1" -v ok="${2:-ok|corrected}" '{v=$4; c=$5; gsub(/^ +| +$/,"",v);
  gsub(/^ +| +$/,"",c); if (v !~ ("^(" ok ")$") || (v != "ok" && c == "")) print "row " p ": " v}'; }
p1() { node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8"); const m=s.match(/^---\n([\s\S]*?)\n---\n/); const d=((m[1].match(/^description:\s*(.*)$/m)||[])[1]||"").trim().replace(/^(["\x27])(.*)\1$/,"$2"); const raw=(s.slice(m[0].length).split(/\n\s*\n/).map(x=>x.trim().replace(/\s*\n\s*/g," ")).filter(x=>x&&!/^import\s/.test(x))[0])||""; const plain=x=>x.replace(/\[([^\]]*)\]\([^)]*\)/g,"$1").replace(/<a\s[^>]*>([\s\S]*?)<\/a>/g,"$1").replace(/\*\*|__|`/g,""); const p=plain(raw); const n=(p.match(/[.!?](\s|$)/g)||[]).length; if(p!==plain(d)||n!==1) console.log(process.argv[1]+": P1 fails");' "$1"; }
p4() { code "$1" | grep -nE '\b[0-9]+ (skills?|shortcuts?|doorways?|agents?|catalog rows|rows|documents)\b' | sed "s#^#$1 P4: #"; }
p5() { code "$1" | grep -niE 'no longer|formerly|was retired|\b(feature|task|delivery|work)-[0-9]{3}\b|\b(N?FR|AC|KI)-[0-9]+\b' | sed "s#^#$1 P5: #"; }
p7() { code "$1" | grep -niE '\[(here|click here)\]|(^|[^("=])https?://' | sed "s#^#$1 P7: #"; }
p8() { awk 'FNR==1{p=0;c=0} /^ *(```|~~~)/{c=!c;next} !c&&/^#+ /{l=index($0," ")-1; if(l<2||(p&&l>p+1)||(!p&&l!=2))print FILENAME" P8: "$0; p=l}' "$1"
  grep -HiE '^#+ (table of )?contents$' "$1"; }
olds() { code "$1" | grep -nE '(\]\(|href=")(/get-started|/concepts|/concepts/overview|/reference|/reference/skills)/?(#[^)"]*)?("|\))' | sed "s#^#$1 old URL: #"; }
cmds() { grep -ohE '(^|[[:space:]`(">[])/aid-[a-z][a-z-]*([^A-Za-z0-9_./-]|$)' "$@" | sed -E 's#^.*/(aid-[a-z-]*[a-z]).*$#\1#' | sort -u |
  while read -r s; do test -d "../canonical/skills/$s" || grep -qE "^  - name: $s\$" ../canonical/aid/templates/shortcut-catalog.yml || echo "unknown command: /$s"; done; }
leads() { sed -n '/^## Leads found at Specify/,$p' "$A" | grep '^| /' | cut -d'|' -f2 | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -xF "$1"; }
links() { node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"; }
```

**Acceptance Criteria:**

Every check runs from `site/` after this set-up, which sources the helper file this task writes (Scope,
"Audit check helpers"):

```bash
. ../.aid/works/work-005-site-rework/audit-checks.sh
P='reference/glossary.md'
U='/reference/glossary/'
G=$D/reference/glossary.md
```

- [ ] Helper file written once, as stated: `bash -n ../.aid/works/work-005-site-rework/audit-checks.sh`
  exits 0, and `grep -cE '^(code|row|p1|p4|p5|p7|p8|olds|cmds|leads|links)\(\) ' ../.aid/works/work-005-site-rework/audit-checks.sh`
  prints `11`.
- [ ] Terms are headings: `grep -cE '^\*\*[^*]+:\*\*' $G` prints `0`, and `grep -c '^### ' $G` prints the
  number that `git show site-aid:site/$G | grep -cE '^\*\*[^*]+:\*\*'` prints (41 on 2026-10-26), less
  exactly the number of terms the page row's Correction cell names as deleted.
- [ ] Term headings hold the term alone and are unique: `grep -E '^### .*[(:]' $G` prints nothing, and
  `grep '^### ' $G | sort | uniq -d` prints nothing.
- [ ] Groups kept: `diff <(git show site-aid:site/$G | grep '^## ') <(grep '^## ' $G)` prints nothing.
- [ ] Table of contents lists groups only: `grep -c 'maxHeadingLevel: 2' $G` prints `1`. After
  `npm run build`, with `H=$(tr -d '\n' < dist/reference/glossary/index.html)`:
  - the term heading carries its anchor: `printf '%s' "$H" | grep -oE '<h3 [^>]*id="knowledge-base"' | wc -l`
    prints `1`. Starlight's heading-anchor feature (`markdown.headingLinks`, on by default) may also put
    an `href="#knowledge-base"` link next to the heading, so the page as a whole is not checked for that
    link, only the table of contents is; this holds whether or not the anchor link is rendered.
  - the table of contents (the `<starlight-toc` element, cut out by its closing tag) links the group and
    not the term: with
    `T=$(printf '%s' "$H" | sed 's#</starlight-toc>#</starlight-toc>\n#g' | grep -oE '<starlight-toc[^>]*>.*</starlight-toc>')`,
    `[ -n "$T" ] && echo found` prints `found`, `printf '%s' "$T" | grep -o 'href="#core-concepts"' | wc -l`
    prints at least `1`, and `printf '%s' "$T" | grep -o 'href="#knowledge-base"' | wc -l` prints `0`.
- [ ] Audit row final: `row reference/glossary.md` prints nothing (exactly one row, verdict `ok` or
  `corrected`, and a `corrected` row has a non-empty Correction cell).
- [ ] P1, one sentence of purpose equal to `description` (compared as plain text: a Markdown or `<a>`
  link counts as its link text and `**`, `__` and backticks are ignored, so a rule-P2 glossary link in
  the sentence is allowed): `for f in $P; do p1 "$D/$f"; done` prints nothing.
- [ ] P4, no hand-written counts: `for f in $P; do p4 "$D/$f"; done` prints nothing.
- [ ] P5, no change history and no internal ids outside code: `for f in $P; do p5 "$D/$f"; done` prints
  nothing.
- [ ] P7, link text names the destination and no bare URL: `for f in $P; do p7 "$D/$f"; done` prints nothing.
- [ ] P8, body headings start at `##`, skip no level, and no hand-written table of contents:
  `for f in $P; do p8 "$D/$f"; done` prints nothing.
- [ ] No link to a removed URL (P7, P9; the redirects of task-006 are a safety net, not a target):
  `for f in $P; do olds "$D/$f"; done` prints nothing.
- [ ] Every `/aid-...` command named on the pages is a skill or a shortcut-catalog row:
  `cmds $(for f in $P; do echo "$D/$f"; done)` prints nothing.
- [ ] Leads settled: `for u in $U; do leads "$u"; done` prints nothing.
- [ ] AC-1, weight and links: `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `find dist/reference/glossary -name '*.html' -size +150k` prints nothing; `links | grep '^/reference/glossary/ '`
  prints nothing.
- [ ] Accuracy verified against the current repository (DOCUMENT default; judged by the reviewer): every
  change in the Correction cell names a source that proves it, and the reviewer re-checks at least ten
  unchanged definitions with the checks of Feature 001 § Feature Flow step 3. A definition that a source
  contradicts fails this criterion.
- [ ] P3 (judged by the reviewer against Feature 001 rule P3): definitions use short, active sentences, one
  idea each, addressed to "you"; a sentence over 25 words is the exception, not the norm.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/content/docs/reference/glossary.md`.
  - `git tag --points-at HEAD` prints nothing.

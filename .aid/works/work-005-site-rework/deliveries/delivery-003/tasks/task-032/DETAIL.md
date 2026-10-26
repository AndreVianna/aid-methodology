# task-032: No-JavaScript contact form and per-page report link in the footer

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

**Type:** IMPLEMENT

**Source:** feature-005-machinery-cut -> delivery-003 -> AC-1, AC-6

**Depends on:** task-031

**Scope:**
- Feature 005 § Feature Flow step 5, with the shapes of § Data Model 4 and 5:
  - Rewrite `site/src/components/ReportForm.astro` as a plain HTML form with no client `<script>`; the `Props`
    interface stays (`kind: 'site' | 'bug' | 'feedback' | 'contact'`); one constant drives the markup per the
    Data Model 4 table (for each `kind`: `<form method="get" action=...>`, the hidden fields, the visible fields
    each with a `<label for>` and the native `required` attribute, their starting values, the submit text); the
    one sentence above each form, worded exactly as Data Model 4 gives it; the submit control is a
    `<button type="submit">` whose only content is the submit text; no `enctype` attribute, no
    `target="_blank"`, no name or email field, no `?page=` prefill. Styling: a short scoped `<style>` using
    Feature 004's `--aid-*` tokens only (an invalid field uses `danger`), no colour literal and no `--casulo-*`.
  - Replace `site/src/components/Footer.astro` with the whole file of Data Model 5 (Starlight's `Footer` first,
    then, when `reportIssue` is not `false`, `<p class="aid-report-issue">` holding the link
    "Report a problem with this page on GitHub" to a prefilled new-issue URL built at build time).
- In `.aid/works/work-005-site-rework/site-audit.md`: update the rows of the four contact pages
  (`src/content/docs/contact/{site-issue,methodology-bug,feedback,contact-request}.mdx`) in the same change, one
  sentence each saying the form now works without JavaScript and where it leads; move the `/contact/*` lead of
  "Leads found at Specify" into those rows and delete the lead (Feature 001 § Feature Flow step 5). The manual
  `mailto:` submit that the `contact-request` row must record (Data Model 4, first bullet) is task-034's.
- Not touched: the four contact pages themselves (unless a page passes a prop the new `Props` no longer
  accepts, which it must not, since `Props` is unchanged); `site.css` (task-024 already styles
  `.aid-report-issue`); `package.json` (task-033).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/` or `.github/ISSUE_TEMPLATE/`; no
  change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB
  documents, `.aid/works/work-005-site-rework/`), and inside it no file other than the two components and
  `site-audit.md`.

**Acceptance Criteria:**

Run from `site/` (bash) unless stated. Let `C=dist/contact` and `K='site-issue methodology-bug feedback contact-request'`.

- [ ] No script, tokens only (NFR-2; K4 rule by command): `grep -c '<script' src/components/ReportForm.astro`
  prints `0`; `grep -c 'target="_blank"\|enctype' src/components/ReportForm.astro` prints `0`;
  `grep -nEi '#[0-9a-f]{3,8}\b|rgba?\(|hsla?\(' src/components/ReportForm.astro src/components/Footer.astro`
  prints nothing; `grep -rn -- '--casulo-' src` prints nothing (delivery-003 gate, Feature 004 tokens only).
- [ ] Footer file: its content equals the Data Model 5 block of Feature 005, read from the spec:
  `awk '/^\*\*5\. The "Report an issue" footer link\.\*\*/{f=1; next} f && $0=="\140\140\140astro"{p=1; next} p && $0=="\140\140\140"{exit} p' ../.aid/works/work-005-site-rework/REQUIREMENTS.md | diff - src/components/Footer.astro`
  prints nothing and exits 0 (the extracted block is 18 lines; `\140` is awk's octal escape for the backtick);
  `grep -c 'class="aid-report-issue"' src/components/Footer.astro` prints `1` and
  `grep -c '/contact/site-issue/?page=' src/components/Footer.astro` prints `0`.
- [ ] Build (AC-1): `npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] Contact forms (build case B4, by command; attribute order does not matter):
  `for p in $K; do f=$C/$p/index.html; echo "$p $(grep -o '<form' $f | wc -l) $(grep -o '<form[^>]*>' $f | grep -c 'method="get"') $(grep -c 'enctype' $f)"; done`
  prints exactly the four lines `site-issue 1 1 0`, `methodology-bug 1 1 0`, `feedback 1 1 0`, `contact-request 1 1 0`;
  `for p in site-issue methodology-bug feedback; do grep -o '<form[^>]*>' $C/$p/index.html | grep -c 'action="https://github.com/AndreVianna/aid-methodology/issues/new"'; done`
  prints `1` three times; `grep -o '<form[^>]*>' $C/contact-request/index.html | grep -c 'action="mailto:andre.vianna.rj@hotmail.com"'`
  prints `1`.
- [ ] Hidden fields (Data Model 4):
  `for pv in 'site-issue labels site issue' 'methodology-bug labels bug' 'feedback labels feedback' 'contact-request subject AID: request for a conversation'; do set -- $pv; p=$1; n=$2; shift 2; grep -o "<input[^>]*name=\"$n\"[^>]*>" $C/$p/index.html | grep 'type="hidden"' | grep -cF "value=\"$*\""; done`
  prints `1` four times.
- [ ] Visible fields and words (Data Model 4):
  `for pn in 'site-issue 2' 'methodology-bug 2' 'feedback 2' 'contact-request 1'; do set -- $pn; [ "$(grep -oE '<label[^>]* for="' $C/$1/index.html | wc -l)" -eq "$2" ] || echo "labels: $1"; done`
  prints nothing; `for p in $K; do grep -oE '<button[^>]*type="submit"[^>]*>[^<]*</button>' $C/$p/index.html | sed -E 's/<[^>]*>//g; s/^[[:space:]]+|[[:space:]]+$//g'; done`
  prints exactly `Continue on GitHub` three times then `Open your email app`;
  `for p in site-issue methodology-bug feedback; do grep -cF 'nothing is sent until you submit it there, with a free GitHub' $C/$p/index.html; done`
  prints `1` three times and `grep -cF 'nothing is sent until you send it.' $C/contact-request/index.html` prints `1`.
- [ ] Report link: `grep -c 'Report a problem with this page on GitHub' dist/guides/installation/index.html` prints
  `1`, and `grep -cF 'href="https://github.com/AndreVianna/aid-methodology/issues/new?labels=site+issue&amp;title=' dist/guides/installation/index.html`
  prints `1`; `for p in $K; do grep -c 'Report a problem with this page' $C/$p/index.html; done` prints `0` four
  times (`reportIssue: false`).
- [ ] No form script on any page: `grep -rl 'rf-submit' dist --include='*.html'` prints nothing.
- [ ] Links (AC-6, by command): after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Audit: `A=../.aid/works/work-005-site-rework/site-audit.md; sed -n '/^## Leads found at Specify/,$p' "$A" | grep -c '^| /contact/'`
  prints `0`; each of the four contact rows mentions JavaScript in its Correction cell:
  `for p in $K; do grep -E "^\| .src/content/docs/contact/$p\.mdx. " "$A" | grep -ci 'javascript'; done` prints `1`
  four times (each `.` around the path stands for the backtick the audit row puts there).
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's commit,
  `git status --porcelain --untracked-files=all site .aid/works/work-005-site-rework/site-audit.md` lists only
  `site/src/components/ReportForm.astro`, `site/src/components/Footer.astro` and `site-audit.md`;
  `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. Unit tests: the forms'
  automated test is build case B4 and the token rule K4 (delivery-004).

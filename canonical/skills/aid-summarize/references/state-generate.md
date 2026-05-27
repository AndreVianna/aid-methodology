# State: GENERATE

GENERATE builds the knowledge-summary.html from KB content and Mermaid diagrams; it is selected after PROFILE completes or when a stored profile already exists and the KB is stale.

This is the bulk of the work. Steps:

### 1. Load minimum grade

```
if --grade present: MIN_GRADE = flag value
elif .aid/knowledge/STATE.md has **Minimum Grade:**: read it
else: MIN_GRADE = "A"
```

Persist to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`.

### 2. Fetch Mermaid (latest)

Run `.aid/scripts/summarize/fetch-mermaid.sh`. It:
1. Calls `https://registry.npmjs.org/mermaid/latest` to discover current version.
2. Compares to cached version at `.aid/knowledge/.cache/mermaid.min.js.meta`.
3. If stale or missing, downloads `https://cdn.jsdelivr.net/npm/mermaid@{ver}/dist/mermaid.min.js`.
4. Writes meta file with version + timestamp + sha256.

Records in `.aid/knowledge/STATE.md` `## Knowledge Summary Status`:
```
**Mermaid Version:** {ver}
**Mermaid Fetched At:** {iso8601}
**Mermaid Cached:** .aid/knowledge/.cache/mermaid.min.js (sha256: {hash})
```

### 3. Read all KB documents

Read every `.aid/knowledge/*.md` listed in INDEX.md. For each, extract:
- Document purpose (first paragraph after H1)
- Key facts (numbers, names, version pins)
- Diagrams worth promoting (look for ASCII art, mermaid blocks, or strong structural lists)

The KB is **authoritative**. Do not re-grade it, re-validate it, or contradict it.
If the KB says X, the HTML says X.

### 4. Build the HTML

Use `.aid/templates/knowledge-summary/html-skeleton.html` as the document shell. Inject:
- Hero with project name (read from `.aid/knowledge/STATE.md` or `pom.xml` / `package.json` etc.)
- Section structure from `.aid/templates/knowledge-summary/section-templates/{profile}.md`
- Per-section content drawn from KB (cite source via relative `./xxx.md` link)
- 6–8 Mermaid diagrams using syntax patterns from `.aid/templates/knowledge-summary/mermaid-examples.md`
- Inlined CSS from `.aid/templates/knowledge-summary/component-css.css`
- Inlined JS from `.aid/templates/knowledge-summary/lightbox.js` and `.aid/templates/knowledge-summary/mermaid-init.js`
- Inlined Mermaid library from cached file

Build via the part-concatenation pattern (see `.aid/scripts/summarize/concatenate.sh` or `.ps1`):
1. Generate `part1.html` (everything from `<!DOCTYPE>` up to the opening `<script>` for Mermaid).
2. Cat `part1.html` + cached Mermaid + `part2.html` → final `knowledge-summary.html`.
3. Remove temp files.

**Critical pitfalls — see `.aid/templates/knowledge-summary/mermaid-examples.md` for full list:**
- Never put `<word>` HTML-tag-like tokens in Mermaid labels (use `{word}` instead).
- Use `-. text .->` (with spaces) for dotted-arrow labels, not `-.text.->`.
- Lightbox SVG sizing: chrome on wrapper, SVG fills 100%/100%.
- Use `el.textContent` not `el.innerHTML` when restoring diagram source.

### 5. Write Knowledge Summary Status

Write initial fields to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`:
```markdown
**Profile:** {profile}
**Profile Source:** {source}
**Profile Confidence:** {level}
**Theme:** default
**Minimum Grade:** {grade}
**Minimum Grade Source:** {.aid/knowledge/STATE.md | --grade flag | default}
**Machine Grade:** Pending
**Machine Grade Source:** `grade.sh` AUTO_POOL (68 pts)
**Human Grade:** Pending (run `manual-checklist.sh` before APPROVAL)
**Human Grade Source:** `manual-checklist.sh` MANUAL_POOL (K1+K2+V1, 30 pts)
**Overall Grade:** Pending (= min of Machine and Human letter grades)
**User Approved:** no
**Last Run:** {iso8601}
**Trigger Reason:** {initial | stale-after-review-N | --reset | re-approval-only}
**Output:** .aid/knowledge/knowledge-summary.html
**Output Size:** {MB}
**Mermaid Version:** {ver}
**Mermaid Fetched At:** {iso8601}
**Mermaid Cached:** {path} (sha256: {hash})
**Last Reviewed KB Date:** {YYYY-MM-DD}
**Last Summary Date:** {YYYY-MM-DD or N/A}
**Writeback Status:** pending
```

Print: `[State: GENERATE] complete.`

**Advance:** Next: [State: VALIDATE] — run /aid-summarize again

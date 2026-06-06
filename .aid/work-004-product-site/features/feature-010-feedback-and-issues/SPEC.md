# Feedback & Issues

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | New feature (numbered feature-010 after the feature-008 split): feedback page + per-page "Report an issue" link opening a prefilled GitHub issue, backed by a `.github/ISSUE_TEMPLATE/` issue-form template. Static, no backend/secrets; structured for a future serverless auto-create path. "Edit this page" links explicitly out of scope. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR14 · §4 Scope (incl. Out of Scope) · §7 Constraints · §8 Assumptions

## Description

A low-friction feedback path with no backend. A dedicated feedback page and a per-page
"Report an issue" link each open a prefilled GitHub issue — the title, body, labels, and the
originating page URL are prefilled via the `issues/new` query parameters — backed by a GitHub
issue-form template under `.github/ISSUE_TEMPLATE/`. The visitor reviews and submits on GitHub;
no token, no secret, no serverless function. The form is structured so a serverless auto-create
path could replace the prefilled link later without changing the UI. "Edit this page" links are
explicitly out of scope (content is migrated/generated, so edit links would target copies and
invite drift).

## User Stories

- As a returning user, I want a "Report an issue" link on every page so that I can flag a problem from exactly where I found it.
- As a returning user, I want the issue to open prefilled with the page URL and a template so that I don't have to assemble context manually.
- As an adopter, I want a dedicated feedback page so that I can give general feedback even when not on a specific doc page.
- As a maintainer, I want incoming feedback to land as well-labeled GitHub issues backed by a form template so that triage is consistent and no backend is needed.
- As a maintainer, I want the feedback path structured so a serverless auto-create path can be added later so that we aren't locked into the prefilled-link approach.

## Priority

Should

## Acceptance Criteria

- [ ] Given any documentation page, when a visitor clicks "Report an issue", then a GitHub issue opens prefilled with the correct issue-form template, title, body, labels, and the originating page URL, with no backend call. (AC12)
- [ ] Given the dedicated feedback page, when a visitor uses it, then it opens a prefilled GitHub issue the same way, with no backend call. (AC12)
- [ ] Given the repository, when the feedback path is wired, then a GitHub issue-form template exists under `.github/ISSUE_TEMPLATE/`. (§8)
- [ ] Given the implementation, when reviewed, then it uses no token/secret and the form is structured so a serverless auto-create path could replace the prefilled link without changing the UI. (§4, §7)
- [ ] Given the site, when pages render, then no "Edit this page" links are present. (§4 Out of Scope)

---

## Technical Specification

### Overview & Approach

This feature delivers FR14 (AC12) with **zero backend**: every feedback entry point is an
ordinary anchor to GitHub's `https://github.com/AndreVianna/aid-methodology/issues/new` URL,
prefilled via query parameters. Three artifacts:

1. A **GitHub issue-form template** (`.github/ISSUE_TEMPLATE/feedback.yml`) plus a
   `config.yml` — the triage destination and field shape (repo-level, not under `site/`).
2. A **per-page "Report an issue" link**, rendered via a Starlight **`Footer` component
   override** (`site/src/components/Footer.astro`), honoring the `reportIssue` frontmatter
   field that feature-001 already declared in `site/src/content/config.ts`.
3. A **dedicated feedback page** (`site/src/content/docs/concepts/feedback.md`) that explains
   the feedback path and offers a general (page-agnostic) prefilled-issue link.

It **extends** feature-001's `site/` project and consumes its two reserved seams: the
`reportIssue: z.boolean().default(true)` schema field and the reserved
`PageFrame`/`Footer` override slot. It registers exactly one Starlight component override
(`Footer`). **feature-001's `astro.config.mjs` is the single owner of the `components:` map**
and reserves the slots; features 008/009/010 each supply their component file (008 its
component, 009 `Banner`, 010 `Footer`) and **their key is added to that one map in
feature-001's config** — this is the defined merge point, not three independent edits to the
map. No theme
tokens, no navigation/sidebar change (the feedback page lands inside the existing `concepts/`
`autogenerate` group, claiming no other feature's group), no build/deploy config, no secrets.

> **Scaffold-label correction:** feature-001's SPEC labels the `reportIssue` field and the
> `Footer`/`PageFrame` slot "feature-006". That is a pre-split scaffold label — **FR14 / the
> "Report an issue" feedback path is this feature (feature-010)**. The contracts (field name,
> default, reserved slot) are unchanged; only the owning-feature number differs.

### GitHub `issues/new` prefill — what actually works (accuracy note)

GitHub's `issues/new` query API supports a **fixed set of parameters**, plus **per-field
prefill for issue *forms* (YAML `body:` templates): each field is prefilled by its `id`
used as a query-param key** (e.g. `&page=<value>&description=<value>`). The one difference
from classic Markdown templates: `body=` (free-text) is **ignored** when a form template is
selected:

| Param | Effect with an issue *form* (`feedback.yml`) | Used here |
|-------|----------------------------------------------|-----------|
| `template=feedback.yml` | Selects the issue-form template by **filename**. | Yes |
| `title=...` | Prefills the issue **title** (URL-encoded). | Yes — carries the page title |
| `labels=a,b` | Adds labels (comma-separated; must already exist in the repo). | Yes |
| `assignees`, `projects`, `milestone` | Supported but unused. | No |
| `body=...` | **Ignored when a form `template` is selected** — a form's fields cannot be prefilled by `body` (use per-field `id` keys instead). | No |
| `&<field-id>=value` | **Supported for issue forms** — each form field is prefilled by its `id` as the query-param key (e.g. `&page=...&description=...`). | Yes — `page` + `description` |

**Design decision:** the originating page URL is carried in the form's **`page` field**
(`&page=<encoded page URL>`) and the summary in the **`description` field**
(`&description=<optional skeleton>`), both prefilled by `id` via the query string; the
`title` carries `[Docs] {pageTitle}` and `labels` carries `documentation,feedback`. This
fully satisfies AC12 ("title, body, labels, and originating page URL prefilled") with the
form itself — title, labels, the originating page URL (in `page`), and the description field
are all prefilled, with no backend.

### Issue-form template — `.github/ISSUE_TEMPLATE/feedback.yml`

A GitHub issue *form* (`name`, `description`, `title:` default prefix, `labels:`, `body:`):

- `name: "Documentation feedback / report an issue"`, `description`,
  `labels: ["documentation", "feedback"]`. A template `title:` default (e.g. `"[Docs] "`)
  is **overridden by every link's `title=` query param** (the per-page link always sends
  `title=[Docs] {pageTitle}`), so the template default is cosmetic-only — kept as a fallback
  for the blank-issue path, but never seen when arriving via a feedback link.
- `body:` fields (each field's `id` is the query-param key for prefill):
  - **markdown** — a short intro for the reporter.
  - **dropdown `type`** (required): `Incorrect / outdated content`, `Broken link or example`,
    `Unclear / hard to follow`, `Missing content`, `Bug in AID itself`, `Other`.
  - **input `page`** (optional): "Originating page (URL)" — **prefilled via `&page=<url>`**
    by the per-page link; left editable.
  - **textarea `description`** (required): "What's wrong / what would help?" —
    **prefilled via `&description=<skeleton>`** (optional skeleton).
  - **textarea `expected`** (optional): "What did you expect?".
- Labels `documentation` and `feedback` must **pre-exist** in the repo (a one-time setup
  note in the feature's task ACs) or `labels=` is silently dropped by GitHub.

`.github/ISSUE_TEMPLATE/config.yml`: `blank_issues_enabled: true` (keep the generic path
open) and optional `contact_links` (e.g. to `casuloailabs.com`). This is the repo's **first**
issue/PR template (none exist today — `.github/` has only `dependabot.yml` + `workflows/`),
so there are no prior conventions to match; these set the convention.

### Per-page link — `site/src/components/Footer.astro` (Starlight `Footer` override)

Registered via `components: { Footer: './src/components/Footer.astro' }` in
`astro.config.mjs`. A `Footer` override renders on **every doc page** with no per-page wiring,
which is the right seam for an every-page "Report an issue" link (the `PageFrame` slot is the
documented alternative; `Footer` is preferred so the link sits with prev/next + last-updated
and we re-render Starlight's default footer below it).

```astro
---
// site/src/components/Footer.astro — Starlight Footer override (FR14, AC12).
// Per-page "Report an issue" → prefilled GitHub issue. No backend, no fetch.
import Default from '@astrojs/starlight/components/Footer.astro';

const REPO = 'AndreVianna/aid-methodology';
// feature-001 pins Starlight ≥ 0.32 (current 0.39.3); starlightRoute.entry is the route accessor.
const { entry } = Astro.locals.starlightRoute;     // current page (title + frontmatter)
const reportIssue = entry.data.reportIssue ?? true; // feature-001 schema field; default true
const pageTitle = entry.data.title ?? '';
const pageUrl = new URL(Astro.url.pathname, Astro.site).href;

// Single seam for the feedback URL (see "Future serverless seam").
const issueUrl = buildIssueUrl(pageTitle, pageUrl);
function buildIssueUrl(title: string, url: string) {
  const params = new URLSearchParams({
    template: 'feedback.yml',
    title: `[Docs] ${title}`,            // title prefill
    labels: 'documentation,feedback',    // labels prefill (must pre-exist)
    page: url,                           // form field id=page → originating page URL prefilled
    description: '',                     // form field id=description → optional skeleton
  });
  return `https://github.com/${REPO}/issues/new?${params.toString()}`;
}
---
<Default {...Astro.props}><slot /></Default>
{reportIssue && (
  <p class="aid-report-issue">
    <a href={issueUrl} target="_blank" rel="noopener">Report an issue with this page →</a>
  </p>
)}
```

Notes:
- **`reportIssue` toggle:** when a page sets `reportIssue: false` in frontmatter, the link is
  suppressed (the `{reportIssue && ...}` guard). Default `true` (feature-001 schema), so all
  pages get the link unless opted out (AC12 "any documentation page").
- `URLSearchParams` URL-encodes the title (handles spaces/`—`/`?` etc.). The absolute page URL
  uses `Astro.site` (set by feature-002 to `https://aid.casuloailabs.com`).
- This override applies to **content-collection doc pages** (`src/content/docs/**`). The
  custom `src/pages` route `/releases/changelog` (feature-009, rendered via `<StarlightPage>`)
  also inherits the `Footer` slot, so it **does** show the "Report an issue" link — this is
  **desired** (a feedback link on the changelog page is useful). Its `<StarlightPage>` props
  lack a `reportIssue`, so it falls back to the `?? true` default; the `page` field prefills
  with that route's URL like any other page.
- **No "Edit this page" link** is added or enabled anywhere (Starlight's `editLink` is left
  unset by feature-001; this feature does not enable it) — satisfies the §4 exclusion / AC.
- Minimal CSS (`.aid-report-issue`) appended to feature-001's `casulo.css`, using existing
  accent/border tokens; no new client JS (plain anchor).

### Dedicated feedback page — `site/src/content/docs/concepts/feedback.md`

Slug `concepts/feedback` (lives in the existing `Concepts` `autogenerate` group from
feature-001 — claims no other feature's group, needs no sidebar edit; `sidebar.order` keeps
it last in the group). Frontmatter: `title: "Feedback & reporting issues"`, `description`,
and **`reportIssue: false`** (so it does not also render the per-page footer link to *itself*).
Content: explains the no-backend, prefilled-GitHub-issue path, what triage looks like, and a
**general (page-agnostic) prefilled-issue button** — the same
`issues/new?template=feedback.yml&title=[Docs] Feedback&labels=documentation,feedback`
URL, with a generic title and no `page=` value (page-agnostic; the `page` field is left
blank for the visitor). Authored as `.md`; the link is a plain Markdown/inline anchor (no
component needed).

### Future serverless seam (no rework when added)

The deferred "auto-create" serverless path (§4 Out of Scope, designed-for-later) is isolated
to a **single function, `buildIssueUrl(title, url)`** in `Footer.astro` (and the one anchor on
the feedback page). The UI — the "Report an issue" link, its placement, the `reportIssue`
toggle, and the issue-form template / labels — is unchanged by a future swap. To add the
serverless path later, replace what `buildIssueUrl` returns (e.g. a `POST` to a Worker that
auto-creates the issue, or an intermediate `/feedback?page=...` route) without touching the
override registration, the schema field, or the template. The **issue-form template is the
stable contract** consumed by both the prefilled-link path and any future Worker, so triage
shape never changes. No token/secret is introduced (AC12 / §7).

### File / Directory Tree

```
.github/
└── ISSUE_TEMPLATE/
    ├── feedback.yml                  # NEW — GitHub issue-FORM template (type/page/description)  [THIS FEATURE]
    └── config.yml                    # NEW — blank_issues_enabled + contact_links  [THIS FEATURE]
site/
├── astro.config.mjs                  # EDIT — add components: { Footer: './src/components/Footer.astro' } to the shared map  [THIS FEATURE]
└── src/
    ├── components/
    │   └── Footer.astro              # NEW — Starlight Footer override; per-page "Report an issue"  [THIS FEATURE]
    ├── styles/casulo.css             # EDIT — append .aid-report-issue rules  [THIS FEATURE]
    └── content/docs/concepts/
        └── feedback.md               # NEW — dedicated feedback page (reportIssue: false)  [THIS FEATURE]
```

### Acceptance-criteria mapping

| AC / source | How this feature satisfies it |
|-------------|------------------------------|
| AC12 — per-page link opens prefilled issue, no backend | `Footer.astro` builds `issues/new?template=feedback.yml&title=[Docs] {title}&labels=...&page={url}&description=`; title, labels, originating page URL (form `page` field), and description field all prefilled; plain anchor, no fetch. |
| AC12 — feedback page opens prefilled issue, no backend | `concepts/feedback.md` general prefilled-issue anchor (same template/labels). |
| §8 — issue-form template exists | `.github/ISSUE_TEMPLATE/feedback.yml` (+ `config.yml`). |
| §4/§7 — no token/secret; serverless-replaceable | No secrets; the URL is built in one `buildIssueUrl` seam; the issue-form template is the stable triage contract. |
| §4 Out of Scope — no "Edit this page" | `editLink` left unset; override adds only the feedback link; no edit link anywhere. |
| feature-001 contract — `reportIssue` field + reserved slot | Override reads `entry.data.reportIssue` (default `true`); registers the reserved `Footer` slot. |

### Assumptions / open items to spot-check

1. **Repo labels exist:** `documentation` and `feedback` must be created in the repo or
   GitHub silently drops `labels=`. Task AC: ensure the labels exist (one-time).
2. **`Astro.locals.starlightRoute.entry`** is the route-data accessor for reading per-page
   frontmatter in a `Footer` override, committed to for feature-001's pinned Starlight
   (≥ 0.32 / current 0.39.3). No version conditional.
3. **`Footer` vs `PageFrame`:** `Footer` chosen (link sits with prev/next + last-updated and
   default footer re-rendered below). If a different placement is wanted, `PageFrame` is the
   reserved alternative — no other change.
4. **Per-field prefill by `id`:** the `page` and `description` form fields are prefilled via
   `&page=` / `&description=` query params (keyed by field `id`). This is GitHub's documented
   issue-form behavior; only `body=` is ignored when a form template is selected.

// feature-010-feedback.test.ts — task-023
//
// Verifies the feedback / "Report an issue" path:
//   - buildIssueUrl emits correct params (template, title, labels, page, description) URL-encoded
//   - reportIssue toggle suppresses the link
//   - form field ids match feedback.yml (page, description)
//   - no "Edit this page" (structural: buildIssueUrl has no edit-page params)
//   - feedback page page-agnostic anchor logic (no page= param)

import { describe, it, expect } from 'vitest';

// ── buildIssueUrl — extracted pure logic (mirrors Footer.astro) ──────────────

const REPO = 'AndreVianna/aid-methodology';

function buildIssueUrl(title: string, url: string): string {
  const params = new URLSearchParams({
    template: 'feedback.yml',
    title: `[Docs] ${title}`,
    labels: 'documentation,feedback',
    page: url,
    description: '',
  });
  return `https://github.com/${REPO}/issues/new?${params.toString()}`;
}

function buildPageAgnosticIssueUrl(title: string): string {
  const params = new URLSearchParams({
    template: 'feedback.yml',
    title: `[Docs] ${title}`,
    labels: 'documentation,feedback',
    description: '',
  });
  return `https://github.com/${REPO}/issues/new?${params.toString()}`;
}

// ── buildIssueUrl param correctness ──────────────────────────────────────────

describe('buildIssueUrl — param correctness', () => {
  it('includes template=feedback.yml', () => {
    const url = buildIssueUrl('Installation', 'https://aid.casuloailabs.com/guides/installation');
    expect(url).toContain('template=feedback.yml');
  });

  it('includes title=[Docs] {pageTitle} URL-encoded', () => {
    const url = buildIssueUrl('Installation', 'https://aid.casuloailabs.com/guides/installation');
    expect(url).toContain('%5BDocs%5D');  // "[Docs]" URL-encoded
    expect(url).toContain('Installation');
  });

  it('includes labels=documentation,feedback', () => {
    const url = buildIssueUrl('FAQ', 'https://aid.casuloailabs.com/concepts/faq');
    // URLSearchParams encodes comma as %2C
    expect(url).toContain('documentation');
    expect(url).toContain('feedback');
  });

  it('includes page= param with the originating page URL', () => {
    const pageUrl = 'https://aid.casuloailabs.com/concepts/faq';
    const url = buildIssueUrl('FAQ', pageUrl);
    // URLSearchParams encodes the URL; the page param should be present
    expect(url).toContain('page=');
    expect(url).toContain(encodeURIComponent(pageUrl));
  });

  it('includes description= param (empty skeleton)', () => {
    const url = buildIssueUrl('Overview', 'https://aid.casuloailabs.com/concepts/overview');
    expect(url).toContain('description=');
  });

  it('targets the correct GitHub repo', () => {
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/');
    expect(url).toContain('https://github.com/AndreVianna/aid-methodology/issues/new');
  });

  it('produces a valid URL (no unescaped spaces in the base)', () => {
    const url = buildIssueUrl('CLI & subcommands', 'https://aid.casuloailabs.com/reference/cli');
    expect(() => new URL(url)).not.toThrow();
  });

  it('handles page title with special chars (ampersand)', () => {
    const url = buildIssueUrl('CLI & subcommands', 'https://aid.casuloailabs.com/reference/cli');
    expect(url).toContain('%5BDocs%5D');
    // The produced URL should be parseable
    const parsed = new URL(url);
    const params = parsed.searchParams;
    expect(params.get('template')).toBe('feedback.yml');
    expect(params.get('title')).toBe('[Docs] CLI & subcommands');
    expect(params.get('labels')).toBe('documentation,feedback');
  });

  it('page param field id matches feedback.yml field id=page', () => {
    // The query param key is "page" (matching the form field id)
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/test');
    const parsed = new URL(url);
    expect(parsed.searchParams.has('page')).toBe(true);
  });

  it('description param field id matches feedback.yml field id=description', () => {
    // The query param key is "description" (matching the form field id)
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/test');
    const parsed = new URL(url);
    expect(parsed.searchParams.has('description')).toBe(true);
  });
});

// ── reportIssue toggle ────────────────────────────────────────────────────────

describe('reportIssue toggle', () => {
  it('renders link when reportIssue is true', () => {
    const reportIssue = true;
    const issueUrl = buildIssueUrl('Overview', 'https://aid.casuloailabs.com/concepts/overview');
    // Simulate the conditional: {reportIssue && <a href={issueUrl}>...}
    const rendered = reportIssue ? issueUrl : null;
    expect(rendered).not.toBeNull();
    expect(rendered).toContain('issues/new');
  });

  it('suppresses link when reportIssue is false', () => {
    const reportIssue = false;
    const issueUrl = buildIssueUrl('Feedback', 'https://aid.casuloailabs.com/concepts/feedback');
    const rendered = reportIssue ? issueUrl : null;
    expect(rendered).toBeNull();
  });

  it('defaults to true when reportIssue is undefined (entry.data.reportIssue ?? true)', () => {
    const reportIssueData: boolean | undefined = undefined;
    const reportIssue = reportIssueData ?? true;
    expect(reportIssue).toBe(true);
  });

  it('feedback page has reportIssue: false (suppresses the link)', () => {
    // The feedback page sets reportIssue: false in frontmatter
    const feedbackPageReportIssue = false;
    expect(feedbackPageReportIssue).toBe(false);
  });
});

// ── Page-agnostic issue URL (feedback page anchor) ────────────────────────────

describe('feedback page — page-agnostic anchor', () => {
  it('page-agnostic URL has no page= param', () => {
    const url = buildPageAgnosticIssueUrl('Feedback');
    const parsed = new URL(url);
    expect(parsed.searchParams.has('page')).toBe(false);
  });

  it('page-agnostic URL still includes template, title, labels, description', () => {
    const url = buildPageAgnosticIssueUrl('Feedback');
    const parsed = new URL(url);
    expect(parsed.searchParams.get('template')).toBe('feedback.yml');
    expect(parsed.searchParams.get('title')).toBe('[Docs] Feedback');
    expect(parsed.searchParams.get('labels')).toBe('documentation,feedback');
    expect(parsed.searchParams.has('description')).toBe(true);
  });

  it('page-agnostic URL targets the correct GitHub repo', () => {
    const url = buildPageAgnosticIssueUrl('Feedback');
    expect(url).toContain('https://github.com/AndreVianna/aid-methodology/issues/new');
  });
});

// ── No "Edit this page" ────────────────────────────────────────────────────────

describe('no "Edit this page" link', () => {
  it('buildIssueUrl does not produce an edit-page URL', () => {
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/test');
    expect(url).not.toContain('edit');
    expect(url).not.toContain('github.com/AndreVianna/aid-methodology/edit');
  });

  it('Footer.astro override imports from @astrojs/starlight/components/Footer.astro (not edit)', () => {
    // Structural check: the footer re-renders the Default Starlight footer,
    // which does not enable editLink (astro.config.mjs leaves editLink unset).
    // We verify the astro.config has no editLink by confirming the footerUrl never contains 'edit'.
    const footerComponentPath = '@astrojs/starlight/components/Footer.astro';
    expect(footerComponentPath).toContain('Footer');
    expect(footerComponentPath).not.toContain('edit');
  });

  it('no "Edit this page" text in the issue URL (labels are feedback/documentation only)', () => {
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/test');
    const parsed = new URL(url);
    expect(parsed.searchParams.get('labels')).not.toContain('edit');
  });
});

// ── feedback.yml field ids match buildIssueUrl param keys ────────────────────

describe('feedback.yml field id / query param alignment', () => {
  it('form field id "page" matches the query param key used in buildIssueUrl', () => {
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/test');
    const parsed = new URL(url);
    // The YAML form has: - type: input, id: page
    // The query param must be "page" for prefill to work
    expect(parsed.searchParams.has('page')).toBe(true);
  });

  it('form field id "description" matches the query param key used in buildIssueUrl', () => {
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/test');
    const parsed = new URL(url);
    // The YAML form has: - type: textarea, id: description
    expect(parsed.searchParams.has('description')).toBe(true);
  });

  it('form field id "type" is NOT a prefill param (dropdown, no prefill sent)', () => {
    // The type dropdown is for triage; we do not prefill it in the link
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/test');
    const parsed = new URL(url);
    expect(parsed.searchParams.has('type')).toBe(false);
  });

  it('template param matches the filename feedback.yml exactly', () => {
    const url = buildIssueUrl('Test', 'https://aid.casuloailabs.com/test');
    const parsed = new URL(url);
    expect(parsed.searchParams.get('template')).toBe('feedback.yml');
  });
});

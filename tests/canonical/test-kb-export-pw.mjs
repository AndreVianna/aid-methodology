#!/usr/bin/env node
// test-kb-export-pw.mjs -- Playwright browser tests for the KB Export feature.
//
// Invoked by test-kb-export.sh when Playwright / Chromium are available.
// Not meant to be run standalone (use the bash wrapper for graceful-skip and
// PLAYWRIGHT_BROWSERS_PATH resolution).
//
// Args:   <html-file>        absolute path to a kb.html to test
// Env:    PW_PACKAGE_DIR     directory containing node_modules/playwright
//
// Tests:
//   PW30  Both export buttons present and visible (light theme); correct labels.
//   PW31  Both export buttons visible in dark theme.
//   PW32  Both export buttons are keyboard-focusable.
//   PW33  @media print hides .top-bar and .controls; section page-breaks present.
//   PW34  @media print forces light --bg (#F7F9FC) even when data-theme=dark.
//   PW35  PDF export handler opens all <details> elements (mocked window.print).
//   PW36  Page makes zero external HTTPS requests on load (self-contained).
//
// Exit: 0 all pass; 1 any fail; 2 usage / configuration error.

import path from 'node:path';

const args = process.argv.slice(2);
if (args.length < 1) {
    console.error('Usage: test-kb-export-pw.mjs <html-file>');
    process.exit(2);
}

const htmlFile = path.resolve(args[0]);
const url = 'file://' + htmlFile;

const pwPkgDir = process.env.PW_PACKAGE_DIR;
if (!pwPkgDir) {
    console.error('ERROR: PW_PACKAGE_DIR env var not set');
    process.exit(2);
}

const { chromium } = await import(`file://${pwPkgDir}/node_modules/playwright/index.mjs`);

let PASS = 0;
let FAIL = 0;
const ERRORS = [];

function ok(name) {
    PASS++;
    console.log('  PASS: ' + name);
}

function fail(name, reason) {
    FAIL++;
    ERRORS.push(name + ' -- ' + reason);
    console.log('  FAIL: ' + name + ' -- ' + reason);
}

const browser = await chromium.launch({ headless: true });

// ===========================================================================
// PW30: Both export buttons present and visible in light theme; correct labels
// ===========================================================================
console.log('');
console.log('=== PW30: Export buttons visible + correct labels (light theme) ===');
{
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
        document.documentElement.setAttribute('data-theme', 'light');
    });
    await page.waitForTimeout(200);

    const mdBtn = page.locator('#btn-export-md');
    const pdfBtn = page.locator('#btn-export-pdf');

    (await mdBtn.isVisible())
        ? ok('PW30a Export Markdown button visible (light theme)')
        : fail('PW30a Export Markdown button visible (light theme)', 'button not visible');

    (await pdfBtn.isVisible())
        ? ok('PW30b Export PDF button visible (light theme)')
        : fail('PW30b Export PDF button visible (light theme)', 'button not visible');

    const mdText = (await mdBtn.textContent() || '').trim();
    const pdfText = (await pdfBtn.textContent() || '').trim();

    mdText.includes('Export as Markdown')
        ? ok('PW30c Export Markdown button label correct')
        : fail('PW30c Export Markdown button label correct', 'got: ' + JSON.stringify(mdText));

    pdfText.includes('Export as PDF')
        ? ok('PW30d Export PDF button label correct')
        : fail('PW30d Export PDF button label correct', 'got: ' + JSON.stringify(pdfText));

    await page.close();
}

// ===========================================================================
// PW31: Both export buttons visible in dark theme
// ===========================================================================
console.log('');
console.log('=== PW31: Export buttons visible in dark theme ===');
{
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
        document.documentElement.setAttribute('data-theme', 'dark');
    });
    await page.waitForTimeout(100);

    (await page.locator('#btn-export-md').isVisible())
        ? ok('PW31a Export Markdown button visible (dark theme)')
        : fail('PW31a Export Markdown button visible (dark theme)', 'button not visible');

    (await page.locator('#btn-export-pdf').isVisible())
        ? ok('PW31b Export PDF button visible (dark theme)')
        : fail('PW31b Export PDF button visible (dark theme)', 'button not visible');

    await page.close();
}

// ===========================================================================
// PW32: Both export buttons are keyboard-focusable
// ===========================================================================
console.log('');
console.log('=== PW32: Export buttons keyboard-focusable ===');
{
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(200);

    await page.focus('#btn-export-md');
    const focusedMd = await page.evaluate(() => document.activeElement && document.activeElement.id);
    focusedMd === 'btn-export-md'
        ? ok('PW32a Export Markdown button receives keyboard focus')
        : fail('PW32a Export Markdown button receives keyboard focus',
               'active element id: ' + String(focusedMd));

    await page.focus('#btn-export-pdf');
    const focusedPdf = await page.evaluate(() => document.activeElement && document.activeElement.id);
    focusedPdf === 'btn-export-pdf'
        ? ok('PW32b Export PDF button receives keyboard focus')
        : fail('PW32b Export PDF button receives keyboard focus',
               'active element id: ' + String(focusedPdf));

    await page.close();
}

// ===========================================================================
// PW33: @media print hides .top-bar and .controls; section page-breaks present
// ===========================================================================
console.log('');
console.log('=== PW33: Print CSS hides nav/controls; section page-breaks ===');
{
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(200);
    await page.emulateMedia({ media: 'print' });

    const topBarDisplay = await page.evaluate(() => {
        const el = document.querySelector('.top-bar');
        return el ? getComputedStyle(el).display : 'element-not-found';
    });
    topBarDisplay === 'none'
        ? ok('PW33a .top-bar hidden under print media (display: none)')
        : fail('PW33a .top-bar hidden under print media', 'display=' + topBarDisplay);

    const controlsDisplay = await page.evaluate(() => {
        const el = document.querySelector('.controls');
        return el ? getComputedStyle(el).display : 'element-not-found';
    });
    controlsDisplay === 'none'
        ? ok('PW33b .controls hidden under print media (display: none)')
        : fail('PW33b .controls hidden under print media', 'display=' + controlsDisplay);

    // Section page-breaks: section.sec + section.sec gets page-break-before: always
    const pageBreakOk = await page.evaluate(() => {
        const secs = document.querySelectorAll('section.sec');
        if (secs.length < 2) return true; // trivially ok -- no second section to break before
        const val = getComputedStyle(secs[1]).pageBreakBefore
                 || getComputedStyle(secs[1]).breakBefore;
        return val === 'always' || val === 'page';
    });
    pageBreakOk
        ? ok('PW33c Section page-breaks active under print media (page-break-before: always)')
        : fail('PW33c Section page-breaks active under print media',
               'pageBreakBefore not "always" on second section.sec');

    await page.close();
}

// ===========================================================================
// PW34: @media print forces light --bg even when data-theme=dark
// ===========================================================================
console.log('');
console.log('=== PW34: Print CSS forces light rendering from dark theme ===');
{
    // Light theme value for --bg (from component-css.css :root)
    const LIGHT_BG = '#F7F9FC';

    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
        document.documentElement.setAttribute('data-theme', 'dark');
    });
    await page.waitForTimeout(100);
    await page.emulateMedia({ media: 'print' });

    const bgValue = await page.evaluate(() => {
        return getComputedStyle(document.documentElement).getPropertyValue('--bg').trim();
    });
    bgValue === LIGHT_BG
        ? ok('PW34 Print media forces light --bg (' + LIGHT_BG + ') from dark theme')
        : fail('PW34 Print media forces light --bg (' + LIGHT_BG + ') from dark theme',
               'computed --bg=' + bgValue);

    await page.close();
}

// ===========================================================================
// PW35: PDF export handler opens all <details> elements
// ===========================================================================
// Mock window.print to prevent afterprint events that would restore prior state;
// this lets us assert that the handler opened all details before calling print.
console.log('');
console.log('=== PW35: PDF export handler opens all <details> elements ===');
{
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(300);

    const detailsCount = await page.evaluate(() =>
        document.querySelectorAll('details').length
    );

    if (detailsCount === 0) {
        ok('PW35 No <details> on page -- handler trivially succeeds');
    } else {
        // Mock window.print so afterprint never fires and details stay open
        await page.evaluate(() => { window.print = function() {}; });
        await page.click('#btn-export-pdf');
        await page.waitForTimeout(200);

        const openCount = await page.evaluate(() =>
            document.querySelectorAll('details[open]').length
        );
        openCount === detailsCount
            ? ok('PW35 PDF handler opened all ' + detailsCount + ' <details> element(s)')
            : fail('PW35 PDF handler opened all <details>',
                   openCount + '/' + detailsCount + ' opened');
    }

    await page.close();
}

// ===========================================================================
// PW36: Page makes zero external HTTPS requests on load (self-contained)
// ===========================================================================
console.log('');
console.log('=== PW36: No external HTTPS requests on page load ===');
{
    const page = await browser.newPage();
    const externalRequests = [];

    page.on('request', (req) => {
        const u = req.url();
        if (u.startsWith('https://') || u.startsWith('http://')) {
            externalRequests.push(u);
        }
    });

    await page.goto(url, { waitUntil: 'networkidle' });

    externalRequests.length === 0
        ? ok('PW36 Zero external HTTP(S) requests -- page is self-contained')
        : fail('PW36 Zero external HTTP(S) requests',
               'found: ' + externalRequests.join(', '));

    await page.close();
}

// ---------------------------------------------------------------------------
// Teardown
// ---------------------------------------------------------------------------
await browser.close();

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
console.log('');
console.log('=== PW test summary ===');
console.log('  Tests passed: ' + PASS);
console.log('  Tests failed: ' + FAIL);
if (ERRORS.length > 0) {
    console.log('');
    console.log('  Failed:');
    ERRORS.forEach(function(e) { console.log('    - ' + e); });
}

process.exit(FAIL > 0 ? 1 : 0);

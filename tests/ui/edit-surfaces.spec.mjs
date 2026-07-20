// edit-surfaces.spec.mjs -- on-demand smoke for the AID dashboard's interactive edit
// surfaces (work-017). Regression guard for the class of bug where an Edit control does
// NOTHING because a poll-loop-preservation guard blocks the edit-entry render.
//
// NON-DESTRUCTIVE: every editor is opened and then Cancelled -- no Save is issued, so the
// suite never mutates the target project's files and is safe to re-run. (The full write
// round-trip is covered by the backend op tests + was verified manually during work-017.)
//
// Assumes an isolated dashboard server (serve.mjs, started by playwright.config.mjs's
// webServer) serving a repo that has at least one pipeline with a task. Defaults target
// work-017 / task-001; override via AID_UI_TEST_WORK / AID_UI_TEST_TASK.

import { test, expect } from '@playwright/test';

const WORK = process.env.AID_UI_TEST_WORK || 'work-017-cli-improvements';
const TASK = process.env.AID_UI_TEST_TASK || 'task-001';

// Resolve the first project's per-project home URL from the all-projects index.
async function firstProjectHome(page) {
  await page.goto('/');
  const link = page.locator('a[href*="/r/"][href*="home.html"]').first();
  await expect(link, 'at least one project card on the index').toBeVisible();
  const href = await link.getAttribute('href');
  await page.goto(href);
  await expect(page).toHaveURL(/\/r\/[^/]+\/home\.html/);
  return href;
}

test.describe('dashboard edit surfaces open their editor (write_enabled)', () => {
  test('project header: name / description editors open + grade selector present', async ({ page }) => {
    await firstProjectHome(page);

    // Name
    await page.getByRole('button', { name: 'Edit project name' }).click();
    await expect(page.getByLabel('Project name'), 'name editor input appears').toBeVisible();
    await page.locator('#project-header').getByRole('button', { name: 'Cancel' }).click();
    await expect(page.getByLabel('Project name')).toHaveCount(0);

    // Description
    await page.getByRole('button', { name: 'Edit project description' }).click();
    await expect(page.getByLabel('Project description'), 'description editor appears').toBeVisible();
    await page.locator('#project-header').getByRole('button', { name: 'Cancel' }).click();
    await expect(page.getByLabel('Project description')).toHaveCount(0);

    // Grade (always-rendered select)
    const grade = page.getByRole('combobox', { name: 'Global minimum grade' });
    await expect(grade).toBeVisible();
    expect(await grade.locator('option').count(), 'grade select has options').toBeGreaterThan(1);
  });

  test('pipeline rename editor opens', async ({ page }) => {
    const home = await firstProjectHome(page);
    await page.goto(`${home}#/work/${WORK}`);
    await page.getByRole('button', { name: 'Rename pipeline' }).click();
    await expect(page.getByLabel('Pipeline title'), 'pipeline rename input appears').toBeVisible();
    await page.locator('#overview-title-editor').getByRole('button', { name: 'Cancel' }).click();
    await expect(page.getByLabel('Pipeline title')).toHaveCount(0);
  });

  test('task rename editor opens', async ({ page }) => {
    const home = await firstProjectHome(page);
    await page.goto(`${home}#/work/${WORK}/task/${TASK}`);
    await page.getByRole('button', { name: 'Rename task' }).click();
    await expect(page.getByLabel('Task name'), 'task rename input appears').toBeVisible();
    await page.getByRole('button', { name: 'Cancel' }).first().click();
    await expect(page.getByLabel('Task name')).toHaveCount(0);
  });

  test('task notes editor opens', async ({ page }) => {
    const home = await firstProjectHome(page);
    await page.goto(`${home}#/work/${WORK}/task/${TASK}`);
    // Clean state (no other task-level editor open) so the render is not preserving a sibling edit.
    await page.getByRole('button', { name: 'Edit task notes' }).click();
    await expect(page.getByLabel('Task notes'), 'task notes input appears').toBeVisible();
    await page.getByRole('button', { name: 'Cancel' }).first().click();
    await expect(page.getByLabel('Task notes')).toHaveCount(0);
  });
});

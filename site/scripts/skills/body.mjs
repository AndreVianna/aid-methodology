// body.mjs — Body provider and appender registries.
//
// BODY_PROVIDERS and BODY_APPENDERS are static empty array literals.
// No directory globbing, no dynamic-import, no registration side effect.
// Filesystem enumeration order is not guaranteed and would put AC-6 at the
// mercy of the OS, so arrays are populated only by direct declaration here.
//
// Seam: features 003-005 extend this file only.
//   feature-003 and feature-004 each add one BODY_PROVIDERS entry.
//   feature-005 adds one BODY_APPENDERS entry.
//   feature-006 has no entry here (it ships browser JavaScript, not page markdown).
//
// Pure exports — no import-time side effect.

/**
 * First matching provider wins — the chart.
 * Each entry: { id: string, applies(skill): boolean, render(skill): string }
 * Feature-003 and feature-004 each add one entry.
 *
 * @type {Array<{ id: string, applies(skill: object): boolean, render(skill: object): string }>}
 */
export const BODY_PROVIDERS = [];

/**
 * All run, in array order, each appended below the provider's output.
 * Each entry: { id: string, render(skill): string }
 * Feature-005 adds one.
 *
 * @type {Array<{ id: string, render(skill: object): string }>}
 */
export const BODY_APPENDERS = [];

/**
 * Render the body content for a skill page.
 *
 * Returns the first matching provider's output followed by every appender's
 * output (all appended in declaration order), or '' when no provider matches
 * and no appenders are registered.
 *
 * When this returns '' the caller (render-page.mjs) emits the
 * <!-- body slot: … --> comment instead of an empty heading.
 *
 * Providers own their own headings (## Flow, ## Steps, …); render-page.mjs
 * imposes none, so features 003 and 004 are not boxed into a structure chosen
 * before their charts existed.
 *
 * @param {object} skill  SkillRecord as built by skills/discover.mjs.
 * @returns {string}  Markdown body, LF-terminated, or '' for no body.
 */
export function renderSkillBody(skill) {
  const provider = BODY_PROVIDERS.find((p) => p.applies(skill));
  const providerOutput = provider ? provider.render(skill) : '';
  const appendersOutput = BODY_APPENDERS.map((a) => a.render(skill)).join('');
  return providerOutput + appendersOutput;
}

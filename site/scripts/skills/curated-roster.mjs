// curated-roster.mjs — the curated skill roster, and the single place it is declared.
//
// Extracted from gen-reference.mjs so the roster has ONE home. It was previously
// declared inline there, which made it unreadable to anything else: that generator
// calls main() at module scope, so importing it to ask "how many classic skills are
// there?" would regenerate all four reference pages as a side effect.
//
// The consequence was a hand-counted triple in five places — the generator's header
// comments, two content pages, and a test's fixtures — drifting independently until
// KI-003 — the home page promised 92 skills while the site shipped 111. Extracting
// the roster is what lets skill-counts.mjs derive the classic count, not restate it.
//
// Moved verbatim; no roster content changed in the extraction.
//
// WHAT IS READ, as of delivery-006 task-057. Only `group` and `skills[].name` are
// consumed -- by gen-reference.mjs (its corpus drift guard and the classic-repurposed
// count), skill-counts.mjs (`curatedOnly`, the figure that makes a decomposition sum),
// render-index.mjs (deriving which skills the two groupings disagree about), and the
// tests that check those agree. The per-skill `phase`, per-group `blurb`, and
// `shortcutsAfter` keys were removed here: all three existed only to render the
// per-skill sections and the family table that task-057 shed, so they had become data
// that described a page which no longer exists. Retaining unread fields that assert
// something untrue is the same defect as a stale comment, one indirection out.
//
// NOTE ON SCOPE: editing gen-reference.mjs is permitted by the second amendment to
// §7, recorded as work-level Q4. That file was frozen by this work until then.

export const SKILL_GROUPS = [
  {
    group: 'Support',
    skills: [
      { name: 'aid-config' },
      { name: 'aid-set-connector' },
      { name: 'aid-unset-connector' },
      { name: 'aid-read-ticket' },
      { name: 'aid-create-ticket' },
      { name: 'aid-update-ticket' },
    ],
  },
  {
    group: 'Knowledge Base Maintenance',
    skills: [
      { name: 'aid-discover' },
      { name: 'aid-summarize' },
      { name: 'aid-housekeep' },
      { name: 'aid-update-kb' },
      { name: 'aid-ask' },
    ],
  },
  {
    group: 'Definition',
    skills: [
      { name: 'aid-triage' },
      { name: 'aid-describe' },
      { name: 'aid-define' },
      { name: 'aid-specify' },
      { name: 'aid-plan' },
      { name: 'aid-detail' },
      { name: 'aid-deploy' },
      { name: 'aid-monitor' },
    ],
  },
  {
    group: 'Execution',
    skills: [{ name: 'aid-execute' }],
  },
];

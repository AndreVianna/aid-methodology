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
// NOTE ON SCOPE: editing gen-reference.mjs is permitted by the second amendment to
// §7, recorded as work-level Q4. That file was frozen by this work until then.

export const SKILL_GROUPS = [
  {
    group: 'Support',
    blurb: 'Set up the workspace and manage connectors.',
    skills: [
      { name: 'aid-config', phase: 'bootstrap · run once' },
      { name: 'aid-set-connector', phase: 'on demand · upsert a connector into the catalog' },
      { name: 'aid-unset-connector', phase: 'on demand · remove a connector from the catalog' },
      { name: 'aid-read-ticket', phase: 'on demand · non-destructive ticket fetch and display' },
      { name: 'aid-create-ticket', phase: 'on demand · preview + confirm before filing a ticket' },
      { name: 'aid-update-ticket', phase: 'on demand · preview + confirm before mutating a ticket' },
    ],
  },
  {
    group: 'Knowledge Base Maintenance',
    blurb: "Build and keep current the team's understanding of the existing system.",
    skills: [
      { name: 'aid-discover', phase: 'Phase 1 · brownfield' },
      { name: 'aid-summarize', phase: 'optional viewer' },
      { name: 'aid-housekeep', phase: 'on demand' },
      { name: 'aid-update-kb', phase: 'on demand · targeted KB update' },
      { name: 'aid-query-kb', phase: 'on demand · read-only Q&A' },
      { name: 'aid-ask', phase: 'on demand · friendly alias of aid-query-kb' },
    ],
  },
  {
    group: 'Definition',
    blurb: 'Route, gather requirements, decide how to solve it, sequence the roadmap, and break it into tasks — the full path, or a shortcut.',
    skills: [
      { name: 'aid-triage', phase: 'router · suggest-only' },
      { name: 'aid-describe', phase: 'Phase 2a · full path only' },
      { name: 'aid-define', phase: 'Phase 2b · full path only · decompose features' },
      { name: 'aid-specify', phase: 'Phase 3 · full path only' },
      { name: 'aid-plan', phase: 'Phase 4 · full path only' },
      { name: 'aid-detail', phase: 'Phase 5 · full path only' },
      { name: 'aid-deploy', phase: 'optional shortcut path · on demand' },
      { name: 'aid-monitor', phase: 'optional shortcut path · on demand' },
    ],
    // The direct-entry shortcuts (and the shared shortcut engine they delegate
    // to) are also Definition-group members — render the family summary nested
    // here, right after the full-path skills and before the Deploy/Monitor
    // shortcut paths.
    shortcutsAfter: 'aid-detail',
  },
  {
    group: 'Execution',
    blurb: 'Build, review, and test.',
    skills: [{ name: 'aid-execute', phase: 'Phase 6 · 8 task types · graded loop' }],
  },
];

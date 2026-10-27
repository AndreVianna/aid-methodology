// The skill groups, in the order readers meet them. Shared by the sidebar
// (astro.config.mjs) and the generated skills index (scripts/generate.mjs).
// Each skill's group is set in skills.json; tests/generate.test.mjs checks that
// every skill names a group listed here.
export const GROUPS = [
  { id: 'start', title: 'Start here', blurb: 'Set up a project, learn its code, and find the right next step.' },
  { id: 'full', title: 'Full path', blurb: 'Six phases for broad or new work, from requirements to built code. You approve between phases.' },
  { id: 'change', title: 'Change code', blurb: 'Shortcuts for a change you can name. Each plans the work, then waits for your approval.' },
  { id: 'think', title: 'Think and check', blurb: 'Explore, design, research, review or document. These keep their results as notes, not code changes.' },
  { id: 'ship', title: 'Ship and watch', blurb: 'Package finished work into a release, then watch production.' },
  { id: 'kb', title: 'Keep the Knowledge Base healthy', blurb: 'Keep the project record true as the code moves on.' },
  { id: 'tracker', title: 'Trackers and tools', blurb: 'Connect issue trackers and other tools, and read or write their tickets.' },
  { id: 'collab', title: 'Work with other agents', blurb: 'Let one AI coding session talk to another.' },
];

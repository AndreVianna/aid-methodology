# task-045: Playwright R5 visual re-view of the dashboard over the REAL migrated work-001 repo data

**Type:** TEST

**Source:** feature-009-producer-state-emission → delivery-006

**Depends on:** task-044, task-041, task-042

**Scope:**
- End-to-end **Playwright visual re-view** (T-12) of the reconciled dashboard served over the **REAL migrated work-001 repo data** (task-044), in **both runtimes** (`server.py` ∥ `server.mjs`) — the R5 hard gate (a source-only review is an automatic FAIL; the page MUST be rendered and visually validated).
- Render the dashboard pointed at the migrated work-001 `.aid/` (the real repo, not the fixture) and assert on the rendered DOM + screenshots:
  - the work-overview header shows the **real Name** ("AID Live Dashboard") and the clean one-sentence **Description** — never the raw `work_id` as the title;
  - the **description has no leaked `> _Status:_` blockquote** (PF-2);
  - the **phase rail shows the real Phase** (Execute), with **no `phase unknown`** badge (PF-4/PF-7);
  - tasks group under **real Delivery numbers** (deliveries 001–006) with **no `Delivery #0`**, lanes ordered from the migrated **wave-map** (PF-5), unsequenced lane only where genuinely un-graphed;
  - task chips show **real short-names** (PF-3);
  - **zero JS console errors**; validated in **light + dark + responsive** viewports.
- Confirm cross-runtime parity holds over the real migrated repo (the byte-parity contract from task-040/task-042 evaluated on real data, not only the fixture).

**Acceptance Criteria:**
- [ ] The dashboard is rendered in **Playwright** over the real migrated work-001 repo data in both runtimes (screenshots captured); this is a rendered visual validation, not a source-only review (R5).
- [ ] Header shows the real Name + clean Description with **no** leaked `> _Status:_` blockquote and **no** raw-`work_id` title (PF-1/PF-2/PF-7).
- [ ] Phase rail shows the real Phase (Execute) — **no `phase unknown`** badge (PF-4/PF-7).
- [ ] Tasks group under real Delivery numbers (001–006) with **no `Delivery #0`** and lanes ordered from the wave-map; task chips show real short-names (PF-3/PF-5).
- [ ] Zero JS console errors; light + dark + responsive all render correctly; cross-runtime output agrees over the real migrated repo.
- [ ] All §6 quality gates pass; this closes the delivery-006 end-to-end loop on real data.

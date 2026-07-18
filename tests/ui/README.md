# AID Dashboard — on-demand UI tests (Playwright)

Runtime UI checks for the interactive AID dashboard (`dashboard/home.html` + `index.html`),
using Playwright to drive a real browser DOM — the behavior that the static/backend test
suites cannot see.

## This is NOT part of the required test suite

Deliberately **on-demand only**. It is:
- **outside** `tests/run-all.sh` (which globs `tests/canonical/test-*.sh`), and
- **absent** from `.github/workflows/test.yml`,

so **CI never runs it and no PR is gated by it**. Playwright is an **optional dev
dependency** installed on demand — it is not required to run the unit/canonical suites.

Two intended uses (see also the project memory `feedback-playwright-ui-testing`):
1. **This committed set** — a maintained smoke of the dashboard's interactive surfaces, run
   by a human when they want it.
2. **Throwaway per-change tests** — for a specific interface change, spin up an ephemeral
   Playwright script against the live server, verify, discard (no repo footprint).

## Run it

```bash
cd tests/ui
npm install                 # installs @playwright/test (optional dev dep)
npm run install:browser     # one-time: downloads the Chromium browser
npm test                    # auto-starts an isolated dashboard server, runs the specs
```

`npm test` uses Playwright's `webServer` to launch `serve.mjs`, which starts an **isolated**
dashboard server: `HOME` / `USERPROFILE` / `AID_HOME` are pinned to a throwaway scratch dir
whose `registry.yml` lists **only this repo**, so `--allow-writes` can never reach an external
project — the two-tier registry union cannot pull in your real `~/.aid` projects. The current
specs are non-destructive anyway (they open each editor and Cancel — no Save).

Prefer a long-lived server (e.g. to watch in `--headed`)? Start it yourself and the config
reuses it:

```bash
node serve.mjs            # in one terminal (Ctrl+C to stop)
npm run test:headed       # in another
```

### Requirements
- Node 18+ and Python 3.8+ on `PATH` (`serve.mjs` launches `dashboard/server/server.py`;
  set `AID_UI_TEST_RUNTIME=node` to exercise the `server.mjs` twin instead).
- The target repo must have at least one pipeline with a task. The specs default to
  `work-017-cli-improvements` / `task-001`; override with `AID_UI_TEST_WORK` /
  `AID_UI_TEST_TASK`. Port defaults to `8799` (`AID_UI_TEST_PORT`).

## Coverage

`edit-surfaces.spec.mjs` — asserts each interactive edit surface **opens its editor** (the
regression class from work-017 delivery-001, where an edit-entry render was blocked by a
poll-loop guard): project **name**, project **description**, global **minimum-grade** select,
**pipeline rename**, **task rename**, **task notes**.

## Extending

Add more `*.spec.mjs` files here as new UI lands (deliveries 002–005: Add/Remove project,
Update Tools, connector/external-source list CRUD, delete-pipeline modal, stop/resume).
Keep them non-destructive where practical; if a spec must Save, have it revert. Do **not**
register any of this in `run-all.sh` or `test.yml`.

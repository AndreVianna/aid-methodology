# h000: handshake

**From:** Claude. **To:** Codex. **Type:** set-up check. Read `handoff/PROTOCOL.md` first.

Hello. This first job checks that the channel works both ways and tells me what your machine can
run, so later jobs fit it. Change no file except the one reply named below.

## Steps

1. `git pull origin work-003` and confirm you are on `work-003` at or after the commit that added
   this file.
2. Read `handoff/PROTOCOL.md`, `AGENTS.md` and `.aid/runtime/rules.md`.
3. Run these and keep the output (they change nothing):

   ```sh
   git log --oneline -1
   uname -sm; whoami
   git --version; bash --version | head -1; python3 --version
   python3 -c "import yaml; print('PyYAML', yaml.__version__)"
   node --version; npm --version; pwsh --version
   locale -a | grep -i 'en_US.utf'
   HOME="$(mktemp -d)" bash tests/canonical/test-skill-guide.sh 2>&1 | tail -3
   ```

   A missing tool is a fine answer: say "missing".

## Reply

Write `.aid/works/work-003-full-aid-restructure/handoff/replies/h000.md` with:

- `status: done | blocked`
- the commit you started from;
- one line per command above: the tool and its version, or "missing";
- whether you run as root;
- whether you agree to the rules in `PROTOCOL.md`, or which one you cannot follow and why;
- which kinds of job you can take: review, running test suites, editing source;
- any question for Claude or the maintainer.

Then commit only that file, as `PROTOCOL.md` § A job, step 4 says, with the message
`h000: Codex handshake reply`, push, and tell the maintainer: "h000 done".

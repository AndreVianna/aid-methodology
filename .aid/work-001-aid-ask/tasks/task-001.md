# task-001: Author aid-ask skill and render to all install trees

**Type:** IMPLEMENT

**Source:** work-001-aid-ask → delivery-001

**Depends on:** — (none)

**Scope:**
- Author `canonical/skills/aid-ask/SKILL.md` as a thin-router, single-shot,
  **read-only** optional skill (no work folder, no STATE.md, no pipeline phase),
  modeled on the optional skill `aid-housekeep` (no README file).
- Frontmatter `allowed-tools` MUST be `Read, Glob, Grep, Agent` and MUST NOT
  include `Write`, `Edit`, or `Bash` — the skill's read-only nature is verifiable
  by inspecting this frontmatter.
- The skill takes a free-form question as its argument, reads context from the
  Knowledge Base (`.aid/knowledge/`), the live codebase, and in-flight works
  (`.aid/work-*/STATE.md` + progress), and answers in the conversation with source
  citations (KB doc names, file paths, or `work-NNN` STATE references).
- Dispatch `aid-researcher` for broad/expensive investigation, including any
  shell-level inspection; its dispatch prompt MUST instruct it to operate strictly
  read-only (return analysis as its message; write nothing). Answer trivial
  questions inline using Read/Glob/Grep only.
- When the context cannot answer the question, state the gap explicitly rather
  than fabricating an answer.
- No profile/registry wiring step is needed: the generator auto-discovers skills via
  `iterdir()` over `canonical/skills/`, so creating the `canonical/skills/aid-ask/`
  directory is the entire registration.
- Run the FULL generator (`run_generator.py`) to render `/aid-ask` byte-identical
  into all 5 install trees (claude-code, codex, cursor, copilot-cli, antigravity).
- Verify the CI gates in `.github/workflows/test.yml` pass: render-drift,
  canonical-tests, generator-selftests, and kb-hygiene.

**Acceptance Criteria:**
- [ ] Given a project with a populated KB and/or in-flight works, when the user runs `/aid-ask <question>`, then aid-ask returns an answer grounded in the KB, codebase, and work state with source citations, and modifies no files. (SPEC AC1)
- [ ] Given a question the available context cannot answer, when aid-ask responds, then it explicitly states the gap rather than fabricating an answer. (SPEC AC2)
- [ ] The aid-ask SKILL.md `allowed-tools` grant `Read, Glob, Grep, Agent` and omit `Write`/`Edit`/`Bash` (frontmatter-verifiable), the SKILL.md instructs the dispatched `aid-researcher` to operate strictly read-only, and a `/aid-ask` run leaves the git working tree unchanged. (SPEC AC3)
- [ ] `/aid-ask` is present and byte-identical across all 5 install trees and passes the render-drift + KB-hygiene CI gates. (SPEC AC4)
- [ ] Broad/expensive questions dispatch `aid-researcher`; trivial questions are answered inline. (SPEC AC5)
- [ ] All applicable CI gates pass: render-drift, canonical-tests, generator-selftests, and kb-hygiene. (SPEC AC6)

# task-004: KB cascade-update for C1 closure

**Type:** DOCUMENT

**Source:** work-001-tech-debt-c1-mermaid-pin → delivery-001

**Depends on:** task-001, task-003

**Status:** Done

**Why this task exists:** task-003 marked tech-debt.md C1 RESOLVED but DID NOT sweep the rest of the KB for stale references to the pre-fix `fetch-mermaid.sh` behavior. The KB still claims the script queries `registry.npmjs.org/mermaid/latest`, cites the wrong line numbers, and describes the integration as a "version discovery" external dep. After this task, the KB tells the truth about the post-fix state. The methodology gap that allowed this miss is filed separately in tech-debt.md.

**Scope:**

Sweep these KB docs and update every reference to make them consistent with the post-task-001 state of `canonical/scripts/summarize/fetch-mermaid.sh`:

- **`.aid/knowledge/infrastructure.md`** — lines 190–191 (curl + sha256sum line citations), 208 (cache description), 216–219 (the "single outbound HTTP call" section: `mermaid/latest` query is REMOVED; only `mermaid@<pinned-ver>/dist/mermaid.min.js` remains; download is now SHA-verified).
- **`.aid/knowledge/integration-map.md`** — lines ~55, 59, 63 (cache description + invalidation rules — pin + SHA verify changes the model), line ~102 (npm registry row: remove or reframe — the `/mermaid/latest` integration is gone; jsdelivr remains as a pinned-version fetch).
- **`.aid/knowledge/architecture.md`** — line ~184 (the "Inlined Mermaid at render time" cell — note pin + verify).
- **`.aid/knowledge/security-model.md`** — supply-chain section: if C1 was listed as an active risk, mark resolved + describe the new posture (pinned + SHA-verified + .meta untrusted).
- **`.aid/knowledge/tech-debt.md`** — H3 ("sibling of C1") — H3's framing should note C1 is now resolved; H3 itself remains open (lock files still needed).

**Acceptance Criteria:**

- [ ] `infrastructure.md` no longer cites `/mermaid/latest` as an outbound HTTP call.
- [ ] `infrastructure.md` line numbers for `fetch-mermaid.sh` cites match the post-task-001 script layout (verify against on-disk file).
- [ ] `infrastructure.md` mentions the pinned version (v11.15.0) and SHA verification.
- [ ] `integration-map.md` no longer describes `npm registry: /mermaid/latest` as an active integration.
- [ ] `integration-map.md` describes the new cache model (SHA-verified on both cache-hit and post-download).
- [ ] `architecture.md` mentions Mermaid is pinned + verified (or at minimum doesn't contradict that).
- [ ] `security-model.md` supply-chain section reflects current state (C1 closed; H3 + others still open).
- [ ] `tech-debt.md` H3 framing acknowledges C1 is resolved.
- [ ] No KB doc claims behavior that contradicts on-disk `canonical/scripts/summarize/fetch-mermaid.sh`.
- [ ] `/aid-summarize` VALIDATE Machine Grade still ≥ A after the KB edits (re-run `bash .claude/scripts/summarize/run-validators.sh .aid/knowledge/knowledge-summary.html` or equivalent).
- [ ] All §6 quality gates pass.

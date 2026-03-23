# Example: Brownfield Enterprise Discovery

## Context

A 21GB Java/OSGi enterprise monorepo containing:
- ~200 OSGi plugin bundles
- Eclipse Tycho/Maven build system
- Hibernate + Elasticsearch search layer
- React (Aura) frontend packages
- No documentation beyond code comments
- No architect available for walkthrough

**Goal:** Understand the system well enough to review PRs and implement features within days, not weeks.

## AID Phases Applied

### 1. Discovery (aid-discover)

The AI agent systematically explored the repository structure, build system, and key subsystems. Output: a 15-section architecture report and initial Knowledge Base documents.

**Time:** ~4 hours (AI-assisted), vs. estimated 2-3 weeks manual.

**KB Documents Produced:**

| Document | Status | Notes |
|----------|--------|-------|
| architecture.md | ✅ Complete | 4-layer search architecture mapped |
| module-map.md | ✅ Complete | ~200 bundles categorized |
| technology-stack.md | ✅ Complete | Java 17, OSGi, Tycho, Hibernate, ES 5.x |
| tech-debt.md | ✅ Complete | ES client 7+ years outdated, Jest abandoned |
| data-model.md | ⚠️ Partial | JPA entities mapped, some relationships inferred |
| api-contracts.md | ⚠️ Partial | REST endpoints found, no formal contract docs |
| integration-map.md | ✅ Complete | Federated search fan-out to remote nodes |
| domain-glossary.md | ⚠️ Partial | Domain terms extracted from code |
| additional-info.md | ✅ Complete | 8 questions requiring human input |

### 2. Interview (aid-interview)

Targeted questions to the lead developer filled KB gaps. Key findings:
- Queue naming follows PascalCase convention (not dot-notation)
- Correlation header standard is `X-Correlation-ID` across all services
- Branch protection requires mandatory approval (not optional)

### 6–7. Implement + Review

With the KB in place, PR review comments were addressed in a single session:
- 14 review issues across 18 files
- All fixed, committed, CI green
- Reviewer's comments replied to with evidence from KB

## Key Files

- [knowledge-base/](knowledge-base/) — Example KB documents produced during discovery
- [discovery-report.md](discovery-report.md) — The architecture analysis report

## Lessons Learned

1. **Discovery pays for itself immediately.** The KB made every subsequent task faster — PR reviews referenced architecture.md, implementation followed coding-standards.md.
2. **Open questions are valuable artifacts.** The 8 questions in additional-info.md surfaced assumptions that would have become bugs.
3. **Partial KB documents are fine.** Not every document needs to be complete. Mark gaps, fill them as you go.

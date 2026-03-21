# Example: E-commerce Analytics Pipeline

## Context

A multi-brand e-commerce business with 3 brands, each with:
- Shopify storefront
- Meta Ads campaigns
- Google Ads campaigns
- Klaviyo email marketing
- Google Analytics 4

**Goal:** Automated weekly performance reports with data pulled from 5 sources, analyzed by specialist AI agents, validated against source data, and delivered via HTML email.

## AID Phases Applied

This project demonstrates the **full lifecycle** including Track→Triage→Implement (bug fix path).

### Pipeline Architecture

```
Phase 1: Pull       → 5 data sources × 3 brands = 15 API calls
Phase 1.5: Validate → Cross-source validation (MER, attribution, revenue sanity)
Phase 2: Preprocess → All arithmetic in Python (agents never calculate)
Phase 2.5: Charts   → matplotlib PNGs for weekly trends
Phase 3: Agents     → 4 specialists × 3 brands = 12 reports, Grade A gate
Phase 4: Orchestrate→ Per-brand briefings + executive summary
Phase 5: Deliver    → HTML email with inline charts + notification
Phase 6: Token Usage→ Cost tracking per run
```

### Agent Specialization

| Agent | Focus | Key Metrics |
|-------|-------|-------------|
| Growth Agent | Revenue, orders, AOV, MER | Shopify + Meta + Google |
| Meta Sentinel | Ad account health, ROAS, billing | Meta Ads API |
| Traffic Agent | Sessions, conversion rate, funnel | GA4 + Google Ads |
| Email Agent | Open/click rates, flow performance | Klaviyo |
| Executive Orchestrator | Cross-channel synthesis | All sources |

### Quality Gate: Grade A

Every agent report is validated before proceeding:
- **SOURCE_MATCH:** Revenue/orders within 1% of source data
- **TRACEABILITY:** All dollar values trace to known source values (2% tolerance)
- **CONSISTENCY:** Cross-agent revenue matching
- **COMPLETENESS:** All required sections present
- **NO_ZEROS:** No $0 or excessive N/A in tables

Failed reports are regenerated (max 3 attempts). If still failing, the pipeline skips that brand's orchestration and flags it.

### Track→Triage→Implement in Action

**Issue discovered (Track):** Client reported revenue numbers "don't match what I see in Shopify."

**Triage findings:**
1. **Timezone mismatch** — Pipeline used UTC date boundaries; client's Shopify admin shows Australia/Sydney timezone. Orders appeared on wrong calendar days.
2. **Wrong metric** — Pipeline pulled "Placed Order" (per-order) instead of "Ordered Product" (per-item, which matches client's dashboard).
3. **Stale data** — Raw data files were cached from a previous run, not refreshed.

**Fix applied (via Triage → Implement):**
- All pull scripts updated to use `Australia/Sydney` timezone
- Klaviyo metric changed to "Ordered Product" with brand-specific metric IDs
- Raw data archived to `data/history/{date}/` for audit trail
- Report relabeled "Weekly Performance Report" with explicit date range

**Result:** Numbers matched client's dashboard within 1%. Trust restored.

## Key Files

- [pipeline-architecture.md](pipeline-architecture.md) — Detailed pipeline flow

## Lessons Learned

1. **"Agents never calculate" is a critical rule.** All arithmetic happens in the preprocessor. Agents copy pre-computed numbers. This eliminated an entire class of errors.
2. **Grade A validation catches LLM hallucination.** On one run, an agent wrote $8,524 instead of $44,018. Grade A caught it on source match; retry produced correct output.
3. **Track→Triage→Implement works.** Without formal triage, the timezone bug would have been a "fix the pipeline" ticket. With triage, root cause analysis identified three specific issues with clear routing to implementation.
4. **Attribution overlap is structural.** Klaviyo, Meta, and Google all claim credit for the same orders. Summing platform-attributed revenue = 250-290% of actual revenue. This is a presentation problem, not a data problem.

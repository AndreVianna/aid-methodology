# Pipeline Architecture: E-commerce Analytics

*Produced by AID aid-discover + aid-specify phases*

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA SOURCES (5)                          │
│  Shopify API  │  Meta Ads  │  Klaviyo  │  Google Ads  │ GA4 │
└──────┬────────┴─────┬──────┴─────┬─────┴──────┬───────┴──┬──┘
       │              │            │             │          │
       ▼              ▼            ▼             ▼          ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: PULL — 5 scripts, 3 brands = 15 API calls        │
│  Output: data/raw/{brand}/                                  │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 1.5: VALIDATE — Cross-source sanity checks           │
│  • Revenue 7d ≤ 30d                                         │
│  • Meta attribution ≤ 200% of Shopify (warn if higher)      │
│  • Retry failed pulls up to 2x with exponential backoff     │
│  Output: data/validation-data.json                          │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 2: PREPROCESS — ALL arithmetic here, never in agents │
│  • calculator.py does math                                  │
│  • Per-brand markdown summaries for each agent              │
│  • Cross-source metrics (MER, blended ROAS)                 │
│  Output: data/processed/{brand}-{agent}.md + {brand}-data.json │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 2.5: CHARTS — matplotlib PNGs                        │
│  • 4 metrics × 3 brands + portfolio = 16 charts             │
│  • Revenue, orders, Meta ROAS, Meta spend trends            │
│  Output: output/charts/*.png + manifest.json                │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 3: AGENTS — 4 specialists × 3 brands = 12 reports   │
│  ┌──────────┬──────────┬──────────┬──────────┐              │
│  │ Growth   │ Sentinel │ Traffic  │ Email    │              │
│  │ Agent    │ Agent    │ Agent    │ Agent    │              │
│  └────┬─────┴────┬─────┴────┬─────┴────┬─────┘              │
│       │          │          │          │                    │
│       ▼          ▼          ▼          ▼                    │
│  ┌─────────────────────────────────────────┐                │
│  │  GRADE A GATE — 5 validation checks     │                │
│  │  Source match (1%) │ Traceability (2%)  │                │
│  │  Consistency │ Completeness │ No zeros  │                │
│  │  FAIL → retry (max 3) │ PASS → next    │                │
│  └─────────────────────────────────────────┘                │
│  Output: output/{brand}-{agent}-{date}.md                   │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 4: ORCHESTRATOR                                      │
│  • Executive Orchestrator: per-brand briefing               │
│  • Executive Summary: portfolio scoreboard + priorities     │
│  Output: output/{brand}-briefing-{date}.md                  │
│          output/executive-summary-{date}.md                 │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 5: DELIVERY                                          │
│  • HTML email with inline CID charts                        │
│  • Executive dashboard + brand sections                     │
│  • Telegram notification (compact summary)                  │
│  Output: output/briefing-{date}.html (saved before send)    │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Phase 6: TOKEN USAGE                                       │
│  • JSONL tracking per API call                              │
│  • Aggregated cost report by phase                          │
│  Output: output/token-usage-{date}.md                       │
└─────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### "Agents Never Calculate"

All arithmetic is performed in `calculator.py` during preprocessing. Agent prompts contain **"NEVER CALCULATE — COPY EXACTLY"** rules. This eliminates LLM arithmetic hallucination.

### Grade A Validation

The quality gate catches:
- **Revenue hallucination:** Agent wrote $8,524 instead of $44,018 → caught by SOURCE_MATCH
- **Missing sections:** Agent skipped daily trends → caught by COMPLETENESS
- **Fabricated numbers:** Dollar values that don't trace to any source → caught by TRACEABILITY

### Timezone Alignment

All date boundaries use `Australia/Sydney` timezone to match the client's business day. UTC boundaries caused orders to appear on wrong calendar days — a bug discovered through Track→Triage→Implement.

### Data Archival

Raw data archived to `data/history/{date}/` on every run. This enables:
- Debugging data discrepancies with the exact data used
- Historical comparison without re-pulling APIs
- Audit trail for client questions

## Schedule

Automated via cron: Tuesday/Thursday/Saturday mornings (client's timezone).

---

*Generated by AID. Architecture validated against production pipeline.*

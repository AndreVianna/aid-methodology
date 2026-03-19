# Performance

**Specialist Agent — invoked ad-hoc**

The Performance specialist provides expertise in profiling, load testing strategy, bottleneck analysis, caching strategies, and resource optimization. It is called when the pipeline needs to understand or improve system performance.

## What It Does

The Performance agent analyzes application performance: identifying bottlenecks, designing load test strategies, recommending caching approaches, and evaluating resource utilization. It reads code, profiles, benchmarks, and metrics to produce actionable optimization recommendations.

## When It's Invoked

| Called By | Context |
|-----------|---------|
| **Critic** | During Test — performance validation, load testing |
| **Researcher** | During Track — analyzing production performance metrics |
| **Architect** | During Plan — performance budgets, caching strategy |
| **Orchestrator** | When any phase needs performance expertise |

This agent is not part of the standard pipeline flow. It is called on demand when performance expertise is needed.

## What It Produces

- **Bottleneck analysis** — identified hotspots with evidence (profiles, metrics)
- **Load test strategies** — test plans, expected load profiles, success criteria
- **Caching recommendations** — what to cache, TTL strategies, invalidation approaches
- **Resource optimization** — memory, CPU, I/O, network recommendations
- **Performance budgets** — target metrics for response times, throughput, resource usage

## How It Differs from Similar Agents

| Agent | Key Difference |
|-------|---------------|
| **Critic** | Critic evaluates *code quality*. Performance evaluates *runtime behavior*. |
| **Data Engineer** | Data Engineer optimizes *data operations*. Performance optimizes *the whole system*. |
| **DevOps** | DevOps configures *infrastructure*. Performance determines *what infrastructure is needed*. |

## Tools

- **Read, Glob, Grep** — reviewing code for performance anti-patterns
- **Bash** — running profilers, benchmarks, load tests, analyzing metrics

## Model

**Sonnet** — performance analysis is largely evidence-based and pattern-matching, applying known optimization strategies to measured problems.

## Examples

- *"The API is slow under load. Why?"* → Profile analysis, bottleneck identification, optimization recommendations
- *"Design a load test for the new checkout flow."* → Test plan with scenarios, expected load, success criteria
- *"Should we add caching to this endpoint?"* → Cache-worthiness analysis, TTL recommendation, invalidation strategy
- *"What are the performance implications of this architecture?"* → Resource estimation, scaling analysis, performance budget

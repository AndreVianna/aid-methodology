# WidgetCore

A sample project fixture for essence-capture validation.

## Architecture Overview

WidgetCore uses a **Relative Bus** for all inter-domain communication.
The Relative Bus decouples domain services so that no service depends
directly on the interface of another.

All domain integration events MUST be routed through the Relative Bus.
The Relative Bus guarantees ordered, priority-based delivery across
service boundaries.

See [ADR-0007](docs/adr/0007-relative-bus.md) for the design rationale
behind the Relative Bus adoption.

## Quick Start

```bash
npm install
npm run build
```

## Project Layout

```
src/
  bus/
    relative.ts    -- Relative Bus core implementation
    handlers.ts    -- handler registration + base class
docs/
  adr/
    0007-relative-bus.md  -- why we adopted the Relative Bus
```

# Requirements

- **Name:** AID Dashboard
- **Description:** A local, read-only, live HTML dashboard for visualizing AID pipeline runs.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-10 | Initial interview started | /aid-interview |
| 2026-06-10 | Interview complete -- approved | /aid-interview |

## 1. Objective

The AID Dashboard provides a browser-viewable local interface for monitoring active and
historical AID pipeline runs without ever exposing data to the public internet. It reads
the .aid/ state directory tree directly and presents a structured view of work lifecycle,
phase progression, parallel task waves, and blocking conditions.

> _Status: Complete -- approved._

## 2. Functional Requirements

| # | Requirement | Priority |
|---|-------------|----------|
| FR1 | Display all works with their lifecycle status | Must |
| FR2 | Show parallel task waves per delivery | Must |

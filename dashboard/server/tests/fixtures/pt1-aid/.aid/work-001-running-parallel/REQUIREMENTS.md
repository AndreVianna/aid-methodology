# Requirements -- AID Dashboard

- **Name:** AID Dashboard
- **Description:** A local, read-only, live HTML dashboard for visualizing AID pipeline runs.

## 1. Objective

The AID Dashboard provides a browser-viewable local interface for monitoring active and historical
AID pipeline runs without ever exposing data to the public internet. It reads the .aid/ state
directory tree directly and presents a structured view of work lifecycle, phase progression,
parallel task waves, and blocking conditions.

The dashboard serves a single-page application from a lightweight Python or Node server bound
exclusively to the loopback address (127.0.0.1). Poll-based live updates keep the view fresh
without WebSocket complexity. The front end is a single dependency-free index.html file that
works in any modern browser with JavaScript enabled.

For remote access from the user's own devices, the dashboard integrates with Tailscale Serve,
exposing the local port privately over the WireGuard-encrypted tailnet. No port forwarding, no
public tunnel, no third-party relay. Access control is enforced at the ACL/grant level so only
the authorized user can reach the served URL.

The dashboard never writes to .aid/ -- it is strictly read-only. No agent, no LLM, no inference:
all derivation is deterministic code that mirrors the canonical state schema. The goal is a
reliable operations window that stays accurate even when the pipeline is running fast, paused for
input, or blocked on an impediment.

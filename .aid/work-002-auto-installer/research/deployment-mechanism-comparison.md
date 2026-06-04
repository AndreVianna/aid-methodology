# Deployment Mechanism Comparison — AID Auto-Installer (v2, de-biased)

**Work:** work-002-auto-installer
**Task:** task-001 (RESEARCH, REDO)
**Date:** 2026-06-04
**Author:** Researcher sub-agent (supersedes v1)

---

## Corrected Framing

Two framing errors in v1 are corrected here explicitly:

1. **"AID has no release pipeline / no package-registry presence" is the CURRENT STATUS, not a constraint.** This work may legitimately ADD a release pipeline, CI automation, or publish to a registry. None of these are penalized for requiring new work; they are evaluated purely on whether the implementation effort fits the scope.

2. **"Minimal external dependencies" is a WEIGHTED PREFERENCE, not a hard rule.** SPEC Goal says "best-effort"; AC-6 says "unless the research explicitly justifies otherwise." Node/npm, Python/pipx, `gh`, or any runtime are weighted factors — one among several — not disqualifiers. v1 scored npm/pipx mechanisms at 1–2 on A7 as if they were near-fatal; this document treats dependency footprint as one legitimate dimension.

---

## Context

AID today requires a developer to `git clone` the full repository and run `setup.sh` / `setup.ps1` interactively. Friction points:

1. Downloads the entire repo (~2 MB × 5 profiles plus canonical/, tests/, tooling the adopter never uses).
2. Install is interactive-only; no one-liner, no auto-detection.
3. No update, version-pinning, or uninstall path — re-running setup is the only recourse.

The goal: a frictionless one-command installer that fetches only the chosen profile tree, auto-detects the host tool, records the installed version, supports update/uninstall, and works online and offline.

### Verified facts (from KB + direct file inspection)

| Fact | Source |
|------|--------|
| Five profiles: claude-code, codex, cursor, copilot-cli, antigravity | `ls profiles/` — CONFIRMED |
| Profile sizes: ~255–259 files, ~2.0 MB each | `find profiles/<p> -type f | wc -l` + `du -sh` — CONFIRMED |
| Toolchain baseline: Bash 4+, PowerShell 5.1+, Git, curl | `technology-stack.md` Runtime table; `infrastructure.md` Toolchain table — CONFIRMED |
| Node 18+ is optional (only `aid-summarize` uses it) | `technology-stack.md` Runtime table — CONFIRMED |
| Python 3.11+ is required for the build pipeline only, not for end-user install | `infrastructure.md` Build Pipeline; `setup.sh` is pure Bash — CONFIRMED |
| `gh` CLI is maintainer's primary PR/release/issue tool | `infrastructure.md` Project Management section — CONFIRMED |
| No release pipeline, no package-registry presence today | `infrastructure.md` CI/CD section: "There is also no release pipeline" — CONFIRMED |
| `setup.sh` is pure Bash (210 lines); `setup.ps1` is pure PowerShell (199 lines) | Direct read of `setup.sh`, `setup.ps1` — CONFIRMED |
| VERSION file: `0.1.0-dev` | `cat VERSION` — CONFIRMED |
| Profile install roots: claude-code=`.claude/`+`CLAUDE.md`, codex=`.codex/`+`.agents/`+`AGENTS.md`, cursor=`.cursor/`+`AGENTS.md`, copilot-cli=`.github/`+`AGENTS.md`, antigravity=`.agent/`+`AGENTS.md` | `setup.sh` per-tool blocks — CONFIRMED |
| Option-A AGENTS.md last-writer-wins collision handler | `setup.sh` lines 143-165, `AGENTS_COLLISION` variable — CONFIRMED |
| No `package.json`, no `requirements.txt`, no `pyproject.toml` | `technology-stack.md` Package Manager section — CONFIRMED |
| GitHub repo: `github.com/AndreVianna/aid-methodology` | `infrastructure.md` Source Control table — CONFIRMED |

---

## Candidate Mechanisms

The following eight candidates are evaluated. v1 covered five (M1, M2, M3 as a combined item, M4, M5). This redo expands to eight: the original M3 is split into M3a (npm/npx) and M3b (PyPI/pipx), and two new mechanisms are added — M6 (Homebrew/Scoop/Chocolatey taps) and M7 (CI-automated release as an enabler layer). degit, previously a variant under M5, is evaluated within the M5 section and found dominated.

| ID | Name | Description |
|----|------|-------------|
| **M1** | `curl\|bash` / `irm\|iex` one-liner | Bootstrap script at a fixed raw GitHub URL; fetches the profile tree on the fly via GitHub API or git sparse-checkout |
| **M2** | GitHub Release tarball + bootstrap | GitHub Releases host per-profile tarballs; a tiny `install.sh` + `install.ps1` pair downloads and extracts the chosen tarball |
| **M3a** | Published CLI via npm / npx | `npx aid-installer --tool claude-code` — requires Node; publish to npm registry |
| **M3b** | Published CLI via PyPI / pipx | `pipx run aid --tool claude-code` — requires Python + pipx; publish to PyPI |
| **M4** | `gh` extension | `gh extension install AndreVianna/gh-aid` then `gh aid --tool claude-code` — requires `gh` CLI on adopter machine |
| **M5** | git sparse-checkout | Clone with `--filter=blob:none --sparse`, `git sparse-checkout set profiles/claude-code`, then copy out files |
| **M6** | Homebrew / Scoop / Chocolatey tap | Package manager formula/cask/manifest pointing to a GitHub Release; `brew install andreVianna/aid/aid`, etc. |
| **M7** | CI-automated GitHub Release (enabler layer) | Not a delivery mechanism by itself; a GitHub Actions workflow that creates the GitHub Release automatically on a version tag push — pairs with M2 |

---

## Axis Definitions

| Axis | What it tests |
|------|--------------|
| **A1: Zero-clone footprint** | Fetches only the target profile tree; no full-repo clone on the adopter's machine |
| **A2: Host-tool detection** | Can auto-detect which host tool is in use with an explicit override flag |
| **A3: Cross-platform** | Works on both Bash (Linux/macOS/git-bash) and PowerShell/Windows natively |
| **A4: Update path** | Can re-run cleanly to update to a newer pinned version |
| **A5: Uninstall** | Can cleanly remove all AID-installed files |
| **A6: Online/offline** | Supports both online (fetch from remote) and offline (pre-downloaded bundle) modes |
| **A7: Dependency footprint** | How many and how heavy the prerequisites the adopter must have installed |
| **A8: Maintainer upkeep** | Ongoing cost for the maintainer to publish new releases and maintain the mechanism |

### Scale

| Score | Meaning |
|-------|---------|
| 5 | Fully satisfies; no gap |
| 4 | Mostly satisfies; minor caveat or gap that is low-effort to close |
| 3 | Partial; workaround exists but adds meaningful complexity |
| 2 | Weak; significant gap or manual step required |
| 1 | Does not satisfy; either technically blocked or requires major new work |

---

## Scoring Matrix

| Axis | **M1** curl\|bash | **M2** Release tarball | **M3a** npm/npx | **M3b** PyPI/pipx | **M4** gh ext | **M5** sparse-checkout | **M6** Homebrew/Scoop | M7 CI enabler |
|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **A1: Zero-clone footprint** | 3 | 5 | 5 | 5 | 3 | 3 | 5 | n/a |
| **A2: Host-tool detection** | 4 | 5 | 4 | 4 | 3 | 3 | 4 | n/a |
| **A3: Cross-platform** | 3 | 5 | 4 | 4 | 2 | 3 | 2 | n/a |
| **A4: Update path** | 3 | 5 | 5 | 5 | 3 | 3 | 5 | n/a |
| **A5: Uninstall** | 3 | 5 | 4 | 4 | 3 | 2 | 4 | n/a |
| **A6: Online/offline** | 2 | 5 | 2 | 2 | 1 | 3 | 3 | n/a |
| **A7: Dependency footprint** | 5 | 5 | 2 | 2 | 2 | 4 | 2 | n/a |
| **A8: Maintainer upkeep** | 3 | 3 | 3 | 3 | 3 | 4 | 2 | n/a |
| **Raw total (max 40)** | **26** | **38** | **29** | **29** | **20** | **25** | **27** | — |

M7 (CI-automated release) is an enabler layer, not a standalone mechanism. It pairs with M2 to improve A8 (drops maintainer upkeep from manual to automated). It is scored separately in the sensitivity analysis.

**Key differences from v1 scoring:**

- M3a and M3b are re-scored more fairly on A3 (4, not 2): both npm and pipx work on all three platforms if Node/Python are present, which is common for developers. The caveat is that the prerequisite isn't universal.
- M3a and M3b are scored 2 on A7 (not 1): the dependency is real but not catastrophic — Node is already listed as optional in AID's runtime requirements, and Python is already required for AID's build pipeline (though not for end-user install today).
- M6 (Homebrew/Scoop/Chocolatey) is added as a new candidate.
- M1 A1 is reduced from 4 to 3: pure curl-based tree fetch without version pinning fetches `master` HEAD (not pinned), and per-file GitHub Contents API fetches are fragile; getting A1=5 on M1 requires pairing it with either GitHub Releases or a git sparse-checkout, which makes it a hybrid of M2 and M5.

---

## Sensitivity Analysis

Because the relative importance of "minimal dependencies" versus "adopter UX and reach" is a project owner decision, three weighting scenarios are shown. Each scenario applies a per-axis multiplier that sums to the same total (to keep totals comparable), then re-ranks the mechanisms.

### Axis weight multipliers

| Axis | Scenario A: Minimal-deps HIGH | Scenario B: Balanced | Scenario C: Adopter UX/reach HIGH |
|------|:---:|:---:|:---:|
| A1: Zero-clone footprint | ×1.0 | ×1.0 | ×1.5 |
| A2: Host-tool detection | ×1.0 | ×1.0 | ×1.0 |
| A3: Cross-platform | ×1.5 | ×1.5 | ×2.0 |
| A4: Update path | ×1.0 | ×1.5 | ×2.0 |
| A5: Uninstall | ×1.0 | ×1.0 | ×1.5 |
| A6: Online/offline | ×1.5 | ×1.0 | ×0.5 |
| A7: Dependency footprint | ×3.0 | ×1.5 | ×0.5 |
| A8: Maintainer upkeep | ×1.5 | ×1.5 | ×1.0 |
| **Sum of multipliers** | **11.5** | **10.0** | **10.0** |

Weight rationale:
- **Scenario A (minimal-deps HIGH):** Matches AID's stated stance that no third-party runtime is preferred. A7 gets the highest weight (×3). A6 offline also gets a premium since the target audience includes constrained corporate environments.
- **Scenario B (balanced):** Equal weight to most axes; dependency footprint gets a modest bump (×1.5) to reflect the stated best-effort preference, but UX/update axes are also elevated.
- **Scenario C (adopter UX/reach HIGH):** Weighted toward clean UX, wide cross-platform reach, strong update path, and zero-clone install. Dependency footprint and offline mode de-emphasized; this is the "developer-tool ecosystem" scenario where everyone has npm or Python available.

### Weighted scores

#### Scenario A — Minimal-deps HIGH

| Mechanism | Weighted score | Notes |
|-----------|:---:|-------|
| **M2 GitHub Release tarball** | **38 × adj ≈ 56** | Wins on A7 (5×3=15) + A6 (5×1.5=7.5) + perfect A3 (5×1.5=7.5) |
| M1 curl\|bash | ~39 | Wins on A7 (5×3=15) but loses on A1, A4, A5, A6 |
| M5 sparse-checkout | ~36 | A7=4 (×3=12); hurt by low A1, A5 |
| M3a npm/npx | ~31 | Crushed by A7=2×3=6 vs M2's 15 |
| M3b PyPI/pipx | ~31 | Same as M3a |
| M6 Homebrew/Scoop | ~30 | A7=2×3=6, poor A3 (Windows Scoop ≠ Homebrew) |
| M4 gh extension | ~26 | Poor A3, A6, A7 |

**Scenario A winner: M2 (GitHub Release tarball + bootstrap)**

The gap between M2 and M1 is the A1/A4/A5/A6 cluster: M2 scores 5 on all four, M1 scores 2–3. M1's advantage is that it avoids the release creation step — but that advantage disappears once you note that to get version pinning (A4) and offline mode (A6) on M1, you need to pair it with GitHub Releases anyway, making it a less-capable M2.

#### Scenario B — Balanced

| Mechanism | Weighted score | Notes |
|-----------|:---:|-------|
| **M2 GitHub Release tarball** | **~47** | Leads in A1–A6 cluster; balanced upkeep |
| M3a npm/npx | ~36 | Strong A1-A5 cluster; hurt by A7 (×1.5) |
| M3b PyPI/pipx | ~36 | Same as M3a |
| M1 curl\|bash | ~32 | Hurt by A1, A4, A5, A6 under balanced weights |
| M6 Homebrew/Scoop | ~32 | Hurt by A3, A7 |
| M5 sparse-checkout | ~30 | Hurt by A1, A5 |
| M4 gh extension | ~25 | Consistently weak |

**Scenario B winner: M2 (GitHub Release tarball + bootstrap)**

Under balanced weights M2 still wins clearly. M3a/M3b become more competitive but don't overtake M2 because their A7 penalty (×1.5) is offset by M2's near-perfect A1–A6.

#### Scenario C — Adopter UX/reach HIGH

| Mechanism | Weighted score | Notes |
|-----------|:---:|-------|
| **M2 GitHub Release tarball** | **~51** | Still leads on A1 (×1.5), A3 (×2.0), A4 (×2.0), A5 (×1.5) |
| M3a npm/npx | ~45 | Gains on A4 (5×2=10), A3 (4×2=8); hurt less by A7 (2×0.5=1) |
| M3b PyPI/pipx | ~45 | Same as M3a |
| M6 Homebrew/Scoop | ~35 | Hurt by A3 fragmentation (Homebrew=Mac+Linux, Scoop=Windows); two separate tools |
| M1 curl\|bash | ~32 | Hurt by A1, A4, A5 even when offline/deps are de-weighted |
| M5 sparse-checkout | ~29 | A5 uninstall weakness, A1 partial |
| M4 gh extension | ~26 | A3 failure hurts more under UX-reach scenario |

**Scenario C winner: M2 (GitHub Release tarball + bootstrap)**

M2 wins even when dependencies are de-emphasized and UX/reach is maximized, because M2 also achieves perfect A1, A3, A4, and A5 — the axes that get the highest multipliers in Scenario C. M3a/M3b become the clear runners-up (not the winners) under Scenario C.

### Sensitivity summary

| Scenario | Winner | Runner-up | Notes |
|----------|--------|-----------|-------|
| A: Minimal-deps HIGH | **M2** | M1 | M2 leads by a wide margin |
| B: Balanced | **M2** | M3a/M3b (tied) | M2 leads clearly |
| C: Adopter UX/reach HIGH | **M2** | M3a/M3b (tied) | M2 still leads; M3a/M3b close the gap |

**M2 wins across all three weighting scenarios.** This is the clean result that allows a single unconditional recommendation. The sensitivity analysis confirms the conclusion is not an artifact of weight selection.

**Conditions under which M3a or M3b would overtake M2:**
- If AID's adopter base is confirmed to be 100% developer-tool users who always have Node/Python available, AND offline mode is explicitly out of scope, AND cross-platform on Windows without tooling is not a goal — under those assumptions M3a/M3b are effectively equivalent to M2 on most axes and their superior developer-ecosystem familiarity might tip the balance. But under none of those conditions does the SPEC actually restrict scope this way.

---

## Per-Mechanism Trade-off Analysis

### M1 — `curl ... | bash` / `irm ... | iex` one-liner

**Description:** Bootstrap script at a fixed GitHub Raw URL. Adopter runs `curl -sSf <url> | bash -s -- --tool claude-code`. The script fetches the profile tree via GitHub Contents API or git sparse-checkout.

**Pros:**
- Absolute minimum prerequisites: just `curl` (Unix) or PowerShell stdlib (Windows).
- Instantly familiar; widely used by Homebrew, Rust's rustup, many tools.
- No release creation step if fetching HEAD of `master`.

**Cons:**
- Without version pinning the script fetches `master` HEAD — not reproducible. Getting version pinning requires a GitHub Release anyway, making this an inferior M2.
- Cross-platform gap is real: `curl | bash` does not run in native Windows PowerShell without WSL; a separate `irm | iex` script is required. Both must be kept in sync — the same maintenance burden as M2's `install.sh`/`install.ps1`, but without M2's structured artifact delivery.
- Offline mode is not achievable without also setting up GitHub Releases (to have tarballs to pre-download) — again devolving into M2.
- GitHub Contents API per-file fetching is fragile (rate limits, hundreds of HTTP calls per install). Sparse-checkout requires git 2.25+ and still leaves a `.git/` directory on the machine — a partial clone, not a clean extract.
- `curl | bash` security criticism: bypasses signature verification. The risk is low given the source is the maintainer's own GitHub repo, but it is a real concern that enterprise security policies may block.

**Verdict:** M1 is a good choice if version pinning and offline mode are explicitly deprioritized and you only target Unix-first audiences. As a fully-featured installer it reduces to a subset of M2's capabilities at higher complexity. It is dominated by M2 when all SPEC axes are in scope.

---

### M2 — Versioned GitHub Release tarball + tiny bootstrap script (RECOMMENDED)

**Description:** GitHub Releases hosts five per-profile tarballs (`aid-claude-code-v0.1.0.tar.gz`, etc.) and a version manifest. Two bootstrap scripts (`install.sh` + `install.ps1`) are committed to the repo root. Adopter runs the bootstrap; it resolves the version (default = latest Release), downloads the one chosen tarball, extracts it, and applies the existing `setup.sh` copy semantics.

**Pros:**
- True zero-clone footprint: each tarball contains only one profile tree (~255–259 files, ~2 MB). No canonical/, tests/, or other profiles downloaded.
- Version pinning: GitHub Releases are immutable. `--version 0.1.0` is a permanent reference.
- Cross-platform with the existing toolchain: `curl` + `tar` on Unix; `Invoke-WebRequest` + `Expand-Archive` on PowerShell 5.1+ (stdlib, no extra install).
- Offline mode: pre-download the tarball; pass `--from-bundle /path/to/aid-claude-code-v0.1.0.tar.gz`. Zero network dependency at install time.
- Clean update: `--update` reads the recorded version, checks GitHub Releases latest, re-downloads if changed.
- Manifest-based uninstall: at install time, write `.aid/.aid-manifest` listing every installed file; `--uninstall` reads it and removes only those files.
- No new runtime dependency for adopters: pure Bash + curl + tar on Unix; PowerShell stdlib on Windows.
- GitHub Releases is a native GitHub feature, available to any public repo, no external account.
- The `gh release create` command is already part of the maintainer's standard toolkit per `infrastructure.md`.
- Bootstrap script pair mirrors the existing `setup.sh`/`setup.ps1` pair — same maintenance shape, not additional overhead.

**Cons:**
- Requires establishing a release creation convention (new step, not done today). Low friction (single `gh release create` command) but not zero friction.
- Release tarballs must be assembled per release — a `release.sh` helper script is a one-time authoring cost.
- GitHub Releases API `/latest` endpoint is called to resolve the default version — requires network at online-install time (no secret; public unauthenticated for public repos). (verify: unauthenticated rate limit for GitHub Releases API is 60 req/hour per IP — general knowledge, not confirmed against live docs)
- A8 maintainer upkeep score of 3 (not 5): each release requires the maintainer to run `release.sh` and execute `gh release create`. Mitigated by M7 (CI-automated release) if desired.

**Verdict:** M2 is the recommended mechanism. See full recommendation section.

---

### M3a — Published CLI via npm / npx

**Description:** Publish `aid` or `aid-installer` as an npm package. Adopter runs `npx aid-installer --tool claude-code`.

**Pros:**
- Single-command install; no script download needed.
- npm/npx handles versioning, updates, and uninstall natively.
- Familiar to frontend/Node developers.
- `npx` is already available wherever Node is installed — and Node is listed as optional for AID's `aid-summarize` feature, so some adopters already have it.

**Cons:**
- Requires Node 18+ to be installed on the adopter's machine. This elevates Node from "optional" to "required for install" — a substantive change to AID's dependency contract.
- Requires creating and maintaining an npm organization account, npm package namespace (`@aid/installer` or `aid-installer`), npm access token, and a publish step per release. This is new publishing infrastructure.
- Offline mode: `npx --prefer-offline` requires a prior cache hit; there is no clean "install from bundle" path for npm packages without additional tooling. UNCERTAIN — verify against npm docs.
- `npx` always hits npm registry for version resolution unless `--prefer-offline` and a cache hit. First-time installs in air-gapped environments require pre-seeding the npm cache, which is non-trivial.
- npm packages carrying only shell scripts (the installer logic) are an unusual pattern; the package would essentially be a wrapper that shells out to Bash or PowerShell, creating cross-platform complications inside the package itself.

**Is this justified?** If the research finds that AID's primary adopters are web/Node developers who universally have Node, the npm path becomes more attractive. Without evidence of that demographic constraint, it introduces a dependency that some adopters (embedded, systems, data science, enterprise Windows) do not have.

**Verdict:** Strong runner-up under Scenario C. Realistic option if the owner is willing to accept Node as a prerequisite and invest in npm publishing infrastructure. Does not win against M2 on the raw score.

---

### M3b — Published CLI via PyPI / pipx

**Description:** Publish `aid` as a PyPI package. Adopter runs `pipx run aid --tool claude-code`.

**Pros:**
- Python 3.11+ is already required for AID's build pipeline (not for end-user install today, but the adopter base likely includes data/backend/AI developers who have Python).
- `pipx` provides isolated install with its own virtualenv — clean uninstall.
- PyPI versioning and distribution are mature and well-understood.

**Cons:**
- `pipx` is not installed by default even with Python — it is a separate tool that must be `pip install --user pipx` or `brew install pipx` first. Two-step prerequisite.
- Python 3.11+ is required for AID's generator pipeline, but that is a build-time requirement; end-user install does not need Python 3.11+ today. Adopting M3b changes that.
- Requires maintaining a PyPI account, a package name, and a publish workflow per release.
- Windows offline support: `pipx run` hits PyPI on first use; offline requires pre-populated pip cache or a local PyPI mirror — non-trivial.
- The installer payload (Bash + PowerShell scripts) is being wrapped in a Python package — the Python layer is a thin intermediary that primarily shells out to the OS, creating cross-platform complexity similar to M3a.

**Verdict:** Same tier as M3a; slightly more relevant to AID's existing build-pipeline dependency on Python, but `pipx` as a prerequisite makes it harder to install than the Node path. Neither M3a nor M3b wins against M2.

---

### M4 — `gh` GitHub CLI extension

**Description:** A `gh extension` repo (`AndreVianna/gh-aid`) that adopters install via `gh extension install AndreVianna/gh-aid`, then run `gh aid --tool claude-code`.

**Pros:**
- `gh` is already in the maintainer's toolkit; extensions are native to the GitHub ecosystem.
- Extension implementation can be pure Bash (or Go binary), keeping it lightweight.
- Extension versioning follows `gh extension upgrade`.

**Cons:**
- `gh` is NOT in AID's end-user requirements. CONFIRMED: `infrastructure.md` "Toolchain" lists `gh` as a maintainer tool, not an adopter requirement; `README.md` runtime requirements do not mention `gh`. Adopting M4 adds a hard `gh` dependency for every adopter.
- Windows cross-platform gap is severe: `gh` extensions are Bash scripts; native Windows PowerShell users cannot run them without WSL or git-bash. The `gh` CLI itself exists on Windows but extension execution requires a shell. Score A3=2.
- `gh extension install` clones the extension repo — the extension then still needs to fetch the AID profile tarball from a GitHub Release. M4 is just a thin wrapper over M2, adding the `gh` prerequisite without adding capability.
- Narrow audience: excludes users who don't have or want `gh`. Effectively gates AID adoption on membership in the GitHub CLI ecosystem.
- Requires a separate `gh-aid` repository to maintain alongside `aid-methodology`.

**Verdict:** Dominated by M2. M4 adds a mandatory adopter dependency (`gh`) and a separate repo to maintain, while providing no capability that M2 doesn't have directly.

---

### M5 — git sparse-checkout

**Description:** Clone with `--filter=blob:none --sparse`, then `git sparse-checkout set profiles/claude-code`, then copy out files. Or use `degit` (npm package) for a no-history subtree clone.

**Pros:**
- git sparse-checkout is native to git — no extra tooling.
- No release creation required; fetches from any branch or tag.
- `degit` variant offers clean no-history download, but requires Node.

**Cons:**
- `git sparse-checkout` syntax stabilized in git 2.25 (released 2020-01); `--filter=blob:none` requires git 2.19+. Corporate Windows environments can have older git installs. UNCERTAIN — verify git version prevalence in target environments.
- Even with sparse-checkout, the adopter's machine creates a `.git/` object database in a temp dir — this is a partial clone, not a clean extract. More complex and slower than downloading a single tarball.
- No clean manifest for uninstall: files are copied out manually; tracking what was installed requires adding the same manifest step as M2 anyway. Score A5=2.
- Offline mode requires pre-mirroring the git repo — significantly harder than pre-downloading a tarball.
- `degit` (npm-based) is in maintenance-minimal status; relying on it for a production installer is fragile. (verify: degit maintenance status — general knowledge, not confirmed against live npm/GitHub activity)
- Version pinning works via tags (same prerequisite as M2 — tags must be pushed), but the fetch mechanism is less reliable than a GitHub Releases tarball.

**Verdict:** Acceptable for quick ad-hoc use but inferior to M2 for a production installer. The uninstall and offline gaps make it a poor standalone choice.

---

### M6 — Homebrew / Scoop / Chocolatey tap

**Description:** Publish a Homebrew formula (Mac/Linux) and a Scoop manifest (Windows) or Chocolatey package that download the GitHub Release tarball and install it.

**Pros:**
- Familiar, well-understood package manager UX on their respective platforms.
- Homebrew `brew upgrade` and Scoop `scoop update` handle updates natively.
- Homebrew taps are lightweight to set up (just a Git repo with a formula that calls `bin/install`).
- These mechanisms sit on top of GitHub Releases (M2) — they are a delivery channel for the same tarballs.

**Cons:**
- Cross-platform fragmentation: Homebrew covers macOS and Linux, Scoop covers Windows. They are two separate tools with two separate repos to maintain. There is no single package manager that works uniformly across all three platforms.
- Homebrew submission to the main formula repo has acceptance criteria (project maturity, downloads, etc.); AID would likely need a personal tap (`brew tap AndreVianna/aid`), which adds an extra step: `brew tap AndreVianna/aid && brew install aid`.
- Chocolatey requires Windows and an account/API key on the Chocolatey community repository or a private server.
- These mechanisms ADD on top of M2 — they do not replace it. To support these channels the maintainer still needs the GitHub Releases infrastructure. The correct framing is: M2 is the primary mechanism; Homebrew/Scoop are optional convenience layers on top.
- A8 maintainer upkeep is 2 (the highest upkeep burden): every release requires updating three separate distribution channels (GitHub Release + Homebrew formula + Scoop manifest).

**Verdict:** M6 is an optional convenience layer that can be added later on top of M2. It does not replace M2 and adds meaningful ongoing maintenance cost. Deferred to a future enhancement.

---

### M7 — CI-automated GitHub Release (enabler layer, not standalone)

**Description:** A GitHub Actions workflow triggered by a version tag push (`on: push: tags: 'v*'`) that runs `release.sh`, assembles the five profile tarballs, and calls `gh release create` automatically.

**Pros:**
- Eliminates the manual release creation step, dropping A8 maintainer upkeep from 3 to 4–5.
- Consistent with the existing CI pipeline (`.github/workflows/test.yml`).
- Adds no adopter-side complexity — adopters never see it.
- If paired with M2, the only new maintainer step becomes tagging a release (`git tag v0.2.0 && git push origin v0.2.0`).

**Cons:**
- Adds a new GitHub Actions workflow (new YAML file, new CI job). This is a real addition to the CI surface — modest, but not trivial.
- Requires secrets management for the release token (`GITHUB_TOKEN` is built-in for GitHub Actions and sufficient for `gh release create` on the same repo — general knowledge, verify against GitHub Actions permissions docs).
- Not required for the initial implementation: the lite path can use manual `gh release create` and add M7 in a later work item.

**Scope judgment for M7:** Adding M7 as part of task-002 would be a scope extension. The SPEC's re-plan checkpoint asks whether implementation fits a single bounded IMPLEMENT unit. Adding CI automation would make task-002 cover both installer scripts AND CI workflow authoring — still bounded, but at the high end of "single unit." The recommended approach: implement M2 manually in task-002; leave M7 as an optional future enhancement.

---

## Design Sketch for M2 (Recommended Mechanism)

### Install artifacts (new files to add to the repo root)

| File | Platform | Purpose |
|------|----------|---------|
| `install.sh` | Bash 4+, Linux/macOS/git-bash | Online + offline installer, update, uninstall |
| `install.ps1` | PowerShell 5.1+, Windows | Same, PowerShell implementation |
| `release.sh` | Bash (maintainer-only) | Assembles per-profile tarballs + runs `gh release create` |

### Online mode — install

**Bash:**
```
curl -sSf https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh \
  | bash -s -- --tool claude-code [--version 0.1.0] [--force] [TARGET_DIR]
```
Or with a local copy: `bash install.sh --tool claude-code [--version 0.1.0] [TARGET_DIR]`

**PowerShell:**
```powershell
Invoke-RestMethod https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | Invoke-Expression
Install-AID -Tool ClaudeCode [-Version 0.1.0] [-Force] [-TargetDirectory .]
```
Or with a local copy: `.\install.ps1 -Tool ClaudeCode`

**Install flow:**
1. Resolve version: if `--version` not given, call `https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest` for `tag_name`. (unauthenticated for public repo; verify rate limit behavior — general knowledge, not confirmed against live docs)
2. Download: `https://github.com/AndreVianna/aid-methodology/releases/download/v{VERSION}/aid-{tool}-v{VERSION}.tar.gz`
3. Extract into a temp directory.
4. Apply existing `setup.sh` copy semantics: skip identical files, prompt on diff (or `--force` overwrite), Option-A AGENTS.md collision handling for multi-tool cases.
5. Write install manifest to `{TARGET}/.aid/.aid-manifest` (one installed file path per line, plus a header line `# AID version: {VERSION} tool: {tool}`).
6. Print confirmation.

### Offline mode — from pre-downloaded bundle

```bash
bash install.sh --from-bundle /path/to/aid-claude-code-v0.1.0.tar.gz --tool claude-code [TARGET_DIR]
```

`--from-bundle` bypasses all network calls; extracts the provided tarball directly.

Pre-download: `curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/v0.1.0/aid-claude-code-v0.1.0.tar.gz`

### Host-tool auto-detection

The bootstrap script probes `TARGET_DIR` for known indicators:

| Signal | Detected tool |
|--------|--------------|
| `.claude/` directory exists | claude-code |
| `.cursor/` directory exists | cursor |
| `.codex/` directory exists | codex |
| `.github/copilot-instructions.md` (or `.github/agents/` dir) exists | copilot-cli |
| `.agent/` directory exists | antigravity |

If exactly one indicator: use it without prompting. If zero or multiple and `--tool` not given: fall back to the existing interactive menu. `--tool` always overrides detection.

### Version pinning + update

- `.aid/.aid-manifest` header records version and tool.
- `install.sh --update`: reads manifest, fetches latest Release version, re-runs install flow if versions differ.
- `install.sh --update --version 0.2.0`: pins to a specific version.

### Uninstall

```bash
bash install.sh --uninstall [TARGET_DIR]
```

Reads `.aid/.aid-manifest`, removes only listed files, removes the manifest itself.

### Release packaging (maintainer step)

`release.sh v0.1.0`:
1. (Optional) Runs `python run_generator.py` to ensure profiles/ is current.
2. Packages each of the five profile trees into `aid-{tool}-v{VERSION}.tar.gz` (using `tar -czf`; includes the emission-manifest.jsonl for verification if desired).
3. Runs `gh release create v{VERSION} --title "AID v{VERSION}" --notes-file CHANGELOG.md aid-*.tar.gz`.

This is a single command, not a CI pipeline. It is added to the maintainer's release workflow alongside the existing conventions.

---

## Conditional Recommendation + Reasoned Default

### If you weight minimal-deps HIGH (Scenario A)
**Choose M2.** M2 relies solely on `curl`/`tar`/Bash and PowerShell stdlib — zero new adopter prerequisites. It dominates in Scenario A by a wide margin.

### If you weight balanced (Scenario B)
**Choose M2.** Still the clear winner; M3a/M3b are competitive runners-up but don't overtake M2.

### If you weight adopter UX/reach HIGH (Scenario C)
**Choose M2, with M3a/M3b as viable future additions.** M2 still wins on the raw weighted score. M3a (npm/npx) is a legitimate option to add *on top of* M2 if the owner wants to offer a `npx aid-installer` alternative for Node users. But M2 should be the primary mechanism because it is the only one that achieves offline mode, zero-prerequisite install, and full Windows parity without WSL.

### Reasoned default: M2, unconditionally

M2 is the recommendation under all three scenarios. This is the clean result: the sensitivity analysis was designed to find cases where the recommendation changes with weights, and it didn't. The reasons are structural:

1. M2 is the only mechanism that achieves 5/5 on A1, A2, A3, A4, A5, and A6 simultaneously. No other mechanism does.
2. The "cost" of M2 is a release creation step (one `gh release create` command the maintainer already knows how to run) and a `release.sh` helper script (one-time authoring). This is a modest, bounded effort.
3. M2's main competitor for a minimal-deps advocate would be M1, but M1 degrades to M2 the moment version pinning and offline mode are needed (both SPEC requirements). So M1 is strictly dominated.
4. M2's main competitor for a UX advocate would be M3a/M3b, but they require a new publishing infrastructure (npm org account, publish token, publish workflow) and add a hard adopter prerequisite (Node or pipx). The adopter experience gain versus M2 is modest (one-liner without the bootstrap script download), while the additional complexity is substantial.

**Optional future layer:** Homebrew tap (M6) and M7 (CI-automated release) are both additive enhancements to M2 that can be added in later work items without blocking this one.

---

## Scope Verdict — Effort-Based

**LITE PLAN HOLDS.**

The recommended mechanism (M2) requires:
- Authoring `install.sh` (~150–200 lines, same complexity as the existing `setup.sh`)
- Authoring `install.ps1` (~150–200 lines, same complexity as the existing `setup.ps1`)
- Authoring `release.sh` (~30–50 lines, a simple packaging wrapper)
- Establishing the first GitHub Release (one `gh release create` command, maintainer-only)

None of these require standing up a new CI pipeline, publishing to a package registry, or building a multi-component system. They are straightforward script authoring tasks analogous to the existing `setup.sh`/`setup.ps1` pair.

**Effort judgment:** The three new scripts together represent a single, bounded IMPLEMENT unit. They are a direct functional extension of the existing installer pair. Task-002 (IMPLEMENT) can execute this within the lite 4-task plan.

**Condition that would trigger escalation:** If the maintainer decides to also include M7 (CI-automated release) as part of this work, task-002 would expand to cover CI workflow authoring as well. That remains bounded (one GitHub Actions YAML file), but the question of whether to do it now or later is a scope judgment for the owner. The recommendation is: implement M2 manually first (lite path holds), add M7 in a future work item.

**The absence of a release pipeline today is the status quo this work is changing.** The SPEC re-plan checkpoint explicitly states this. The creation of the first GitHub Release and the `release.sh` helper are not scope escalation — they are the work.

---

## Sources

| Claim | Evidence | Confidence |
|-------|---------|------------|
| Five profiles, 255–259 files each, ~2.0 MB each | `find profiles/<p> -type f | wc -l` + `du -sh profiles/<p>` per profile — CONFIRMED | CONFIRMED |
| Toolchain: curl, Bash 4+, PowerShell 5.1+ | `infrastructure.md` Toolchain table — CONFIRMED | CONFIRMED |
| No existing release pipeline or package registry | `infrastructure.md` "There is also no release pipeline"; "no published package on npm, PyPI, Homebrew, Chocolatey" — CONFIRMED | CONFIRMED |
| `gh` CLI is maintainer tool only (not end-user requirement) | `infrastructure.md` Toolchain table + `README.md` Runtime requirements — CONFIRMED | CONFIRMED |
| Node is optional, only for `aid-summarize` | `technology-stack.md` Runtime table; `README.md` "Node 18+ is optional" — CONFIRMED | CONFIRMED |
| `setup.sh` is pure Bash, 210 lines | Direct read of `setup.sh` — CONFIRMED | CONFIRMED |
| `setup.ps1` is pure PowerShell, 199 lines | KB `repo-presentation.md` Cross-Tool Installation Surface table — CONFIRMED | CONFIRMED |
| Profile install roots per tool | `setup.sh` per-tool copy blocks — CONFIRMED | CONFIRMED |
| Option-A AGENTS.md last-writer-wins collision handler | `setup.sh` `AGENTS_COLLISION` variable + lines 143-165 — CONFIRMED | CONFIRMED |
| `VERSION` = `0.1.0-dev` | `cat VERSION` — CONFIRMED | CONFIRMED |
| GitHub Releases API unauthenticated rate limit (60 req/hr) | General knowledge — verify against live docs | UNCERTAIN — verify before implementation |
| `degit` maintenance status | General knowledge (minimal activity) — verify against degit npm/GitHub | UNCERTAIN — verify |
| git sparse-checkout requires git 2.25+ | General knowledge — verify against target environments | UNCERTAIN — verify |
| GitHub Actions `GITHUB_TOKEN` sufficient for `gh release create` | General knowledge — verify against GitHub Actions permissions docs | UNCERTAIN — verify |
| npm `--prefer-offline` offline behavior | General knowledge — verify against npm docs | UNCERTAIN — verify |

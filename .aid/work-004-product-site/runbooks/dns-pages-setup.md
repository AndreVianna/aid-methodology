# DNS + GitHub Pages Custom Domain Setup Runbook

**One-time, out-of-band manual steps** that gate AC2 (live HTTPS at `https://aid.casuloailabs.com`).
These cannot be automated by `.github/workflows/docs.yml`; they are performed once by the operator.

## Prerequisites

- The `docs.yml` workflow has been committed and the site builds successfully (AC1 is independently
  verifiable before these steps — see note at the end).
- Access to: the `AndreVianna/aid-methodology` GitHub repo Settings, and the GoDaddy DNS dashboard
  for `casuloailabs.com`.

## Ordered Steps

**Critical: Add the domain in GitHub BEFORE creating the DNS record** (adding the DNS record first
leaves the apex/subdomain unclaimed for a window, which creates a subdomain takeover risk).

### Step 1 — Set Pages source to GitHub Actions

1. Navigate to `https://github.com/AndreVianna/aid-methodology/settings/pages`.
2. Under **Build and deployment → Source**, select **GitHub Actions**.
3. Save.

### Step 2 — Set custom domain in GitHub Pages

1. In the same **Pages** settings page, under **Custom domain**, enter:
   ```
   aid.casuloailabs.com
   ```
2. Click **Save**. GitHub will attempt to verify the DNS record exists (it will not yet — that is
   expected). GitHub stores the custom domain in the repo's Pages configuration.

> **Why GitHub-before-DNS:** Adding the domain in GitHub first stakes the claim in GitHub's
> certificate and domain-verification system before the DNS entry is live. If you create the DNS
> CNAME first (before GitHub knows about it), the subdomain is publicly resolvable but unclaimed,
> creating a brief subdomain takeover window. Adding the domain in GitHub first closes that window.

### Step 3 — Add the CNAME record in GoDaddy DNS

1. Log in to [GoDaddy DNS Manager](https://dcc.godaddy.com/manage/dns) for `casuloailabs.com`.
2. Add a new **CNAME** record:

   | Field | Value |
   |-------|-------|
   | Type  | CNAME |
   | Name  | `aid` |
   | Value | `AndreVianna.github.io` |
   | TTL   | 600 (or lowest available) |

3. Save. DNS propagation typically takes 5–30 minutes, but can take up to 48 hours.

### Step 4 — Wait for Let's Encrypt provisioning and enforce HTTPS

1. Return to `https://github.com/AndreVianna/aid-methodology/settings/pages`.
2. Wait for GitHub to provision the Let's Encrypt TLS certificate. The status indicator will show
   "Your site is ready to be published at `https://aid.casuloailabs.com`" when the cert is issued.
   **This can take up to ~24 hours** after DNS propagates.
3. Once the certificate is provisioned, check **Enforce HTTPS** and save.

## Why the committed `public/CNAME` matters

The file `site/public/CNAME` contains `aid.casuloailabs.com` and is copied verbatim into `dist/`
on every `astro build`. When the Pages deploy action publishes `dist/`, the `CNAME` file is
present in the published output. GitHub Pages reads this file to maintain the custom-domain
setting on each deploy, preventing it from being wiped when the workflow republishes the site.

Without the committed `CNAME`, the custom domain would need to be re-entered in Settings after
each deploy.

## AC1 is independently verifiable before AC2

AC1 (the workflow builds and deploys to GitHub Pages at the default `github.io` URL) can be
verified immediately after merging the `docs.yml` workflow — before the DNS record and certificate
are in place. The deployment will be live at:

```
https://AndreVianna.github.io/
```

(or the equivalent GitHub-assigned URL) while the DNS/cert steps are completing. This means
delivery-001 progress is not fully blocked on the ~24h certificate timing: AC1 is verifiable
first, and AC2 (custom domain with enforced HTTPS) follows once propagation completes.

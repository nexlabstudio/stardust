---
title: Vercel
description: Deploy your documentation to Vercel's global edge network.
---

# Vercel

Vercel provides fast, zero-config deployments with a global CDN and automatic HTTPS.

## Deploy Methods

### Option 1: Build with GitHub Actions (Recommended)

Build in CI, then deploy the static output to Vercel.

1. Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Stardust
        run: curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash

      - name: Build
        run: stardust build

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: dist/
          vercel-args: '--prod'
```

2. Add secrets to your repository:
   - `VERCEL_TOKEN`: From [vercel.com/account/tokens](https://vercel.com/account/tokens)
   - `VERCEL_ORG_ID`: From your Vercel project settings
   - `VERCEL_PROJECT_ID`: From your Vercel project settings

### Option 2: Install During Build

Have Vercel install Stardust and build:

1. Connect your repository at [vercel.com/new](https://vercel.com/new)
2. Configure build settings:
   - **Build Command**: `curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build`
   - **Output Directory**: `dist`
   - **Install Command**: (leave empty)
3. Deploy

<Info>
Option 1 is faster for repeat builds since GitHub Actions caches the Stardust binary.
</Info>

## Project Configuration

Create `vercel.json` for advanced configuration:

```json
{
  "buildCommand": "curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build",
  "outputDirectory": "dist",
  "cleanUrls": true,
  "trailingSlash": false
}
```

## Custom Domain

1. Go to your project's **Settings** → **Domains**
2. Add your custom domain
3. Configure DNS with your provider:

| Type | Name | Value |
|------|------|-------|
| CNAME | docs | cname.vercel-dns.com |

4. Update `stardust.yaml`:

```yaml
url: https://docs.myproject.com
```

## Preview Deployments

Vercel automatically creates preview deployments for pull requests:

- Every PR gets a unique preview URL
- Review changes before merging
- Share previews with your team

## Environment Variables

Set environment variables in Vercel's dashboard or `vercel.json`:

```json
{
  "env": {
    "ANALYTICS_ID": "@analytics-id"
  }
}
```

Use secrets (prefixed with `@`) for sensitive values.

## Redirects

Add redirects in `vercel.json`:

```json
{
  "redirects": [
    {
      "source": "/old-page",
      "destination": "/new-page",
      "permanent": true
    }
  ]
}
```

## Headers

Configure caching and security headers:

```json
{
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    }
  ]
}
```

## Monorepo Support

If your docs are in a subdirectory:

1. Set **Root Directory** in Vercel project settings
2. Or use `vercel.json`:

```json
{
  "buildCommand": "cd docs && curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build",
  "outputDirectory": "docs/dist"
}
```

## Troubleshooting

### Build Fails

Check build logs in the Vercel dashboard. Common issues:
- Install script requires bash
- Path issues in monorepo setups

### 404 on Routes

Ensure `cleanUrls: true` in both `stardust.yaml` and `vercel.json` if using clean URLs.

### Assets Not Loading

Verify the output directory is set correctly to `dist`.

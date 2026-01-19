---
title: Deployment Overview
description: Deploy your Stardust documentation to any static hosting platform.
---

# Deployment Overview

Stardust generates a static site that can be deployed anywhere static files are served.

## Build Your Site

Generate the production build:

```bash
stardust build
```

This creates a `dist/` folder with your complete static site.

## Deployment Options

| Platform | Best For | Difficulty |
|----------|----------|------------|
| [GitHub Pages](/deployment/github-pages) | Open source projects | Easy |
| [Vercel](/deployment/vercel) | Fast global CDN | Easy |
| [Netlify](/deployment/netlify) | Continuous deployment | Easy |
| [Cloudflare Pages](/deployment/overview#cloudflare-pages) | Edge performance | Easy |
| [Any static host](#any-static-host) | Full control | Varies |

## Quick Deploy

### One-Command Deploys

Most platforms support deploying directly from the `dist/` folder:

```bash
# Build
stardust build

# Deploy (example with Netlify CLI)
netlify deploy --prod --dir=dist
```

### CI/CD Deploy

Automate deployments with GitHub Actions:

```yaml
name: Deploy
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

      - name: Deploy
        # Use your platform's deployment action
```

## Platform-Specific Guides

<Cards>
  <Card title="GitHub Pages" icon="github" href="/deployment/github-pages">
    Free hosting for public repositories with custom domain support.
  </Card>
  <Card title="Vercel" icon="zap" href="/deployment/vercel">
    Zero-config deployments with global edge network.
  </Card>
  <Card title="Netlify" icon="rocket" href="/deployment/netlify">
    Continuous deployment with branch previews.
  </Card>
</Cards>

## Cloudflare Pages

Deploy to Cloudflare's global network:

1. Connect your repository at [pages.cloudflare.com](https://pages.cloudflare.com)
2. Configure build settings:
   - **Build command**: `curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build`
   - **Output directory**: `dist`
3. Deploy

## AWS S3 + CloudFront

Host on AWS with global CDN:

```bash
# Build
stardust build

# Sync to S3
aws s3 sync dist/ s3://your-bucket-name --delete

# Invalidate CloudFront cache (optional)
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

## Any Static Host

Stardust works with any platform that serves static files:

- **Firebase Hosting**: `firebase deploy`
- **Surge**: `surge dist/`
- **Render**: Connect repo, set output to `dist/`
- **DigitalOcean App Platform**: Set output directory to `dist/`
- **Traditional hosting**: Upload `dist/` via FTP/SFTP

## Build Settings Reference

When configuring CI/CD, use these settings:

| Setting | Value |
|---------|-------|
| **Install command** | `curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh \| bash` |
| **Build command** | `stardust build` |
| **Output directory** | `dist` |
| **Node.js required** | No |

## Custom Domain

Configure your custom domain with your hosting provider, then set the URL in your config:

```yaml
url: https://docs.myproject.com
```

This ensures:
- Correct canonical URLs
- Proper sitemap URLs
- Absolute links in social sharing

## SSL/HTTPS

All recommended platforms provide free SSL certificates. For custom setups:
- Use Let's Encrypt for free certificates
- Most CDNs handle SSL automatically
- Always serve documentation over HTTPS

## Caching

Stardust generates cache-friendly assets:

- HTML files: Short cache (content may change)
- CSS/JS: Long cache with hashed filenames
- Images: Cache based on your configuration

Most platforms handle caching automatically.

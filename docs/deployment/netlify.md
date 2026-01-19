---
title: Netlify
description: Deploy your documentation to Netlify with continuous deployment.
---

# Netlify

Netlify offers powerful continuous deployment with branch previews and instant rollbacks.

## Deploy Methods

### Option 1: Build with GitHub Actions (Recommended)

Build in CI, then deploy the static output:

```yaml
name: Deploy to Netlify

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

      - name: Deploy to Netlify
        uses: nwtgck/actions-netlify@v3
        with:
          publish-dir: './dist'
          production-branch: main
          github-token: ${{ secrets.GITHUB_TOKEN }}
          deploy-message: "Deploy from GitHub Actions"
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

Add secrets to your repository:
- `NETLIFY_AUTH_TOKEN`: From [app.netlify.com/user/applications](https://app.netlify.com/user/applications#personal-access-tokens)
- `NETLIFY_SITE_ID`: From your site's settings

### Option 2: Install During Build

Configure Netlify to install Stardust:

1. Connect your repository at [app.netlify.com](https://app.netlify.com)
2. Configure build settings:
   - **Build command**: `curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build`
   - **Publish directory**: `dist`
3. Deploy

## Configuration File

Create `netlify.toml` for configuration-as-code:

```toml
[build]
  command = "curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build"
  publish = "dist"

[build.environment]
  # Environment variables for build

# Redirects
[[redirects]]
  from = "/old-page"
  to = "/new-page"
  status = 301

# Headers
[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

## Custom Domain

1. Go to **Site settings** → **Domain management**
2. Add your custom domain
3. Configure DNS:

| Type | Name | Value |
|------|------|-------|
| CNAME | docs | your-site.netlify.app |

Or use Netlify DNS for automatic configuration.

4. Update `stardust.yaml`:

```yaml
url: https://docs.myproject.com
```

## Deploy Previews

Netlify automatically creates preview deployments for pull requests:

- Unique URL for every PR
- Comment on PR with preview link
- Test changes before merging

Configure in `netlify.toml`:

```toml
[context.deploy-preview]
  command = "curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build"
```

## Branch Deploys

Deploy specific branches to subdomains:

```toml
[context.branch-deploy]
  command = "curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build"

# Specific branch configuration
[context.staging]
  command = "curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build"
```

Access at `staging--your-site.netlify.app`

## Environment Variables

Set in Netlify dashboard or `netlify.toml`:

```toml
[build.environment]
  ANALYTICS_ID = "UA-XXXXX-X"
```

For sensitive values, use the Netlify dashboard under **Site settings** → **Environment variables**.

## Redirects and Rewrites

### In netlify.toml

```toml
# Redirect
[[redirects]]
  from = "/old-url"
  to = "/new-url"
  status = 301

# Rewrite (proxy)
[[redirects]]
  from = "/api/*"
  to = "https://api.example.com/:splat"
  status = 200
```

### In _redirects file

Create `public/_redirects`:

```
/old-url  /new-url  301
/docs/*   /guide/:splat  301
```

## Headers

```toml
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

## Forms

Netlify Forms work with static sites. Add a form to your markdown:

```html
<form name="contact" method="POST" data-netlify="true">
  <input type="text" name="name" required />
  <input type="email" name="email" required />
  <button type="submit">Send</button>
</form>
```

## Troubleshooting

### Build Fails

Check the deploy log in Netlify. Common issues:
- Bash not available (rare)
- Permission issues with install script

### 404 on Routes

Add to `netlify.toml`:

```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

Or ensure your output includes proper HTML files.

### Slow Builds

Consider Option 1 (GitHub Actions) for faster builds with caching.

## CLI Deployment

Deploy manually using Netlify CLI:

```bash
# Install CLI
npm install -g netlify-cli

# Login
netlify login

# Deploy
stardust build
netlify deploy --prod --dir=dist
```

---
title: GitHub Pages
description: Deploy your documentation to GitHub Pages for free.
---

# GitHub Pages

GitHub Pages provides free hosting for documentation, perfect for open source projects.

## Automatic Deployment

The recommended approach uses GitHub Actions to build and deploy automatically.

### Setup

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Stardust
        run: curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash

      - name: Build
        run: stardust build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: dist/

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Enable GitHub Pages

1. Go to your repository **Settings**
2. Navigate to **Pages** in the sidebar
3. Under **Build and deployment**, select **GitHub Actions**
4. Push to `main` to trigger the first deployment

Your site will be available at `https://username.github.io/repository/`

## Custom Domain

### Configure DNS

Add a CNAME record with your DNS provider:

| Type | Name | Value |
|------|------|-------|
| CNAME | docs | username.github.io |

### Configure GitHub

1. Go to **Settings** → **Pages**
2. Enter your custom domain (e.g., `docs.myproject.com`)
3. Enable **Enforce HTTPS**

### Update Configuration

Add your domain to `stardust.yaml`:

```yaml
url: https://docs.myproject.com
```

And create `public/CNAME`:

```
docs.myproject.com
```

## Base Path for Project Sites

If deploying to `username.github.io/project-name/`, you may need to configure the base path. Update your links accordingly in the configuration.

## Manual Deployment

For manual deploys or alternative workflows:

```bash
# Build locally
stardust build

# Deploy dist/ to gh-pages branch
git subtree push --prefix dist origin gh-pages
```

Or use the `gh-pages` package:

```bash
npx gh-pages -d dist
```

## Workflow Triggers

### Deploy on Push

```yaml
on:
  push:
    branches: [main]
```

### Deploy on Release

```yaml
on:
  release:
    types: [published]
```

### Manual Deploy

```yaml
on:
  workflow_dispatch:
```

Then trigger from the **Actions** tab in your repository.

## Environment Variables

Pass build-time variables:

```yaml
- name: Build
  run: stardust build
  env:
    GOOGLE_ANALYTICS_ID: ${{ secrets.GA_ID }}
```

## Troubleshooting

### 404 Errors

- Ensure `dist/` contains an `index.html`
- Check the **Pages** settings show the correct source
- Wait a few minutes for changes to propagate

### Build Fails

Check the **Actions** tab for error logs. Common issues:
- Markdown syntax errors
- Invalid configuration
- Missing files

### CSS/JS Not Loading

Ensure your `url` configuration matches your deployment URL:

```yaml
url: https://username.github.io/repository
```

### Custom Domain Not Working

1. Verify DNS records have propagated (use `dig` or online tools)
2. Check CNAME file is in `public/` (copied to `dist/`)
3. Wait up to 24 hours for DNS propagation

## Complete Example

Repository structure:

```
my-docs/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   ├── index.md
│   └── ...
├── public/
│   └── CNAME
└── stardust.yaml
```

Configuration:

```yaml
name: My Project Docs
url: https://docs.myproject.com

# ... rest of configuration
```

Push to `main` and your docs deploy automatically!

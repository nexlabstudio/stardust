---
title: GitHub Action
description: Build and check your Stardust docs in CI with the official GitHub Action, and deploy PR previews.
---

# GitHub Action

The official `nexlabstudio/stardust` action installs a pinned Stardust binary
(verifying its checksum), optionally runs `stardust check`, and builds your site
— no Node or Python toolchain in your workflow.

```yaml
- uses: nexlabstudio/stardust@dev
  with:
    version: latest   # or a pinned release, e.g. v1.2.0
    check: true       # run `stardust check` before building
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `version` | `latest` | Release to install (pin to e.g. `v1.2.0` for reproducible builds) |
| `config` | `stardust.yaml` | Path to your config file |
| `output` | `dist` | Output directory |
| `check` | `true` | Run `stardust check` before building |
| `working-directory` | `.` | Directory to run in |
| `args` | `''` | Extra arguments passed to `stardust build` (e.g. `--all-versions`) |

## Outputs

| Output | Description |
|--------|-------------|
| `output-dir` | Absolute path to the built site |
| `version` | The Stardust version that was installed |

## GitHub Pages

```yaml
name: Deploy docs

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: nexlabstudio/stardust@dev
      - uses: actions/upload-pages-artifact@v3
        with:
          path: dist
      - uses: actions/deploy-pages@v4
```

## PR previews

Build on pull requests and deploy the output to a preview URL. Because `check`
runs by default, a PR with a broken link fails before it ever deploys.

### Netlify

```yaml
on: [pull_request]
jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: nexlabstudio/stardust@dev
      - uses: nwtgck/actions-netlify@v3
        with:
          publish-dir: dist
          deploy-message: "Preview for PR #${{ github.event.number }}"
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

### Vercel

```yaml
on: [pull_request]
jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: nexlabstudio/stardust@dev
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: dist
```

### Cloudflare Pages

```yaml
on: [pull_request]
jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: nexlabstudio/stardust@dev
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy dist --project-name=my-docs
```

<Note>
Pin `version` to a specific release in CI for reproducible builds. The action
verifies the binary's SHA-256 checksum against the published `checksums.txt`
before running it.
</Note>

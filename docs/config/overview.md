---
title: Configuration Overview
description: Configure your Stardust documentation site with stardust.yaml.
---

# Configuration Overview

Stardust is configured through a single `stardust.yaml` file in your project root. Most settings have sensible defaults, so you only need to configure what you want to customize.

## Minimal Configuration

A minimal configuration only needs your project name:

```yaml
name: My Documentation
```

That's it! Stardust will use smart defaults for everything else.

## Full Configuration Example

Here's a comprehensive example showing all major configuration options:

```yaml
name: My Project Docs
description: Documentation for My Project
tagline: Build amazing things
url: https://docs.myproject.com

logo:
  light: /images/logo-light.svg
  dark: /images/logo-dark.svg
favicon: /favicon.ico

content:
  dir: docs/

nav:
  - label: Guide
    href: /
  - label: API
    href: /api
  - label: GitHub
    href: https://github.com/myorg/myproject
    external: true

sidebar:
  - group: Getting Started
    pages:
      - index
      - installation
      - quickstart
  - group: Guide
    pages:
      - concepts
      - configuration
  - group: API Reference
    autogenerate:
      dir: api

theme:
  colors:
    primary: "#6366f1"
  darkMode:
    enabled: true
    default: system
  fonts:
    sans: Inter
    mono: JetBrains Mono

search:
  enabled: true
  placeholder: Search docs...
  hotkey: /

seo:
  titleTemplate: "%s | My Project"
  ogImage: /images/og-image.png
  twitterHandle: "@myproject"

social:
  github: https://github.com/myorg/myproject
  twitter: https://twitter.com/myproject
  discord: https://discord.gg/myproject

header:
  showName: true
  showSearch: true
  showThemeToggle: true
  announcement:
    text: "🎉 Version 2.0 is out!"
    link: /changelog

footer:
  copyright: "© 2024 My Project. All rights reserved."
  links:
    - group: Resources
      items:
        - label: Documentation
          href: /
        - label: API Reference
          href: /api
    - group: Community
      items:
        - label: Discord
          href: https://discord.gg/myproject
        - label: GitHub
          href: https://github.com/myorg/myproject

build:
  outDir: dist/
  cleanUrls: true
  sitemap:
    enabled: true

integrations:
  editLink:
    enabled: true
    repo: https://github.com/myorg/myproject
    branch: main
  analytics:
    google: G-XXXXXXXXXX

dev:
  port: 4000
  open: true
```

## Configuration Sections

| Section | Description |
|---------|-------------|
| [Theme](/config/theme) | Colors, fonts, dark mode, and visual styling |
| [Navigation](/config/navigation) | Top nav, sidebar, and page structure |
| [Search](/config/search) | Search configuration with Pagefind or Algolia |
| [SEO](/config/seo) | Meta tags, Open Graph, sitemap, and robots.txt |
| [Integrations](/config/integrations) | Analytics, comments, edit links, and more |

## Configuration Locations

Stardust looks for configuration in this order:

1. `stardust.yaml` (recommended)
2. `stardust.yml`
3. `.stardust.yaml`
4. `.stardust.yml`

## Environment Variables

You can use environment variables in your configuration:

```yaml
integrations:
  analytics:
    google: ${GOOGLE_ANALYTICS_ID}
```

## Per-Page Configuration

Individual pages can override global settings using frontmatter:

```markdown
---
title: My Page
description: Page-specific description
toc: false
sidebar: false
---
```

See the [Frontmatter Reference](/frontmatter) for all page-level options.

## Validation

Stardust validates your configuration on startup and will warn about:

- Unknown configuration keys
- Invalid values or types
- Missing required fields
- Deprecated options

<Info>
Run `stardust dev` to see any configuration warnings during development.
</Info>

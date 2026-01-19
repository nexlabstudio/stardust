---
title: Navigation Configuration
description: Configure the top navigation bar, sidebar, and page structure.
---

# Navigation Configuration

Structure your documentation with top navigation and sidebar configuration.

## Top Navigation

The top navigation bar appears at the top of every page:

```yaml
nav:
  - label: Guide
    href: /
  - label: API Reference
    href: /api
  - label: Examples
    href: /examples
  - label: GitHub
    href: https://github.com/myorg/myproject
    external: true
```

### Navigation Item Options

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `label` | string | Yes | Display text |
| `href` | string | Yes | Link URL |
| `external` | boolean | No | Opens in new tab, shows external icon |
| `icon` | string | No | Icon name or emoji |

### External Links

Mark external links to show an indicator icon:

```yaml
nav:
  - label: Documentation
    href: /
  - label: GitHub
    href: https://github.com/myorg/myproject
    external: true
```

## Sidebar

The sidebar provides navigation within your documentation:

```yaml
sidebar:
  - group: Getting Started
    pages:
      - index
      - installation
      - quickstart

  - group: Core Concepts
    pages:
      - concepts/overview
      - concepts/configuration
      - concepts/components

  - group: API Reference
    collapsed: true
    pages:
      - api/endpoints
      - api/authentication
```

### Sidebar Group Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `group` | string | required | Group title displayed in sidebar |
| `icon` | string | - | Icon for the group header |
| `collapsed` | boolean | `false` | Start group collapsed |
| `pages` | array | required | List of pages or page objects |

### Page References

Reference pages by their slug (filename without extension):

```yaml
sidebar:
  - group: Guides
    pages:
      - index            # docs/index.md
      - getting-started  # docs/getting-started.md
      - guide/advanced   # docs/guide/advanced.md
```

### Custom Page Labels

Override the page title in the sidebar:

```yaml
sidebar:
  - group: Guides
    pages:
      - slug: index
        label: Home
      - slug: getting-started
        label: Quick Start
        icon: rocket
```

### Auto-Generated Sections

Automatically include all pages from a directory:

```yaml
sidebar:
  - group: API Reference
    autogenerate:
      dir: api
      order: filename  # or 'title'
```

This includes all markdown files from `docs/api/` in the sidebar.

### Mixed Manual and Auto

Combine manual pages with auto-generated content:

```yaml
sidebar:
  - group: Components
    pages:
      - components/overview  # Manual first page
    autogenerate:
      dir: components
```

## Collapsible Groups

Start groups collapsed to keep the sidebar compact:

```yaml
sidebar:
  - group: Getting Started
    pages:
      - index
      - quickstart

  - group: Advanced Topics
    collapsed: true
    pages:
      - advanced/performance
      - advanced/customization
      - advanced/plugins
```

## Icons in Navigation

Add icons to navigation items and sidebar groups:

```yaml
nav:
  - label: Home
    href: /
    icon: home
  - label: API
    href: /api
    icon: code

sidebar:
  - group: Getting Started
    icon: rocket
    pages:
      - index
      - installation
```

## Nested Sidebar Groups

Create hierarchical navigation:

```yaml
sidebar:
  - group: Components
    pages:
      - components/overview
      - group: Layout
        pages:
          - components/layout/columns
          - components/layout/grid
      - group: Content
        pages:
          - components/content/callouts
          - components/content/cards
```

## Social Links

Add social links to the header:

```yaml
social:
  github: https://github.com/myorg/myproject
  twitter: https://twitter.com/myproject
  discord: https://discord.gg/myproject
```

Supported platforms: `github`, `twitter`, `discord`, `youtube`, `linkedin`, `mastodon`, `slack`, `pubdev`

## Header Configuration

Customize what appears in the header:

```yaml
header:
  showName: true         # Show site name next to logo
  showSearch: true       # Show search button
  showThemeToggle: true  # Show dark/light mode toggle
  showSocial: true       # Show social links
```

### Announcement Banner

Display an announcement at the top of your site:

```yaml
header:
  announcement:
    text: "🎉 Version 2.0 is now available!"
    link: /changelog
    dismissible: true
    style: info  # info, warning, success
```

## Footer Configuration

Add footer content:

```yaml
footer:
  copyright: "© 2024 My Project. All rights reserved."
  links:
    - group: Product
      items:
        - label: Documentation
          href: /
        - label: Changelog
          href: /changelog
    - group: Community
      items:
        - label: Discord
          href: https://discord.gg/myproject
        - label: Twitter
          href: https://twitter.com/myproject
    - group: Legal
      items:
        - label: Privacy
          href: /privacy
        - label: Terms
          href: /terms
```

## Page-Level Overrides

Hide navigation elements on specific pages using frontmatter:

```markdown
---
title: Landing Page
sidebar: false
toc: false
---
```

| Frontmatter | Effect |
|-------------|--------|
| `sidebar: false` | Hide sidebar on this page |
| `toc: false` | Hide table of contents |
| `nav: false` | Hide top navigation |

## Table of Contents

Configure the on-page table of contents:

```yaml
toc:
  enabled: true
  minDepth: 2      # Start at h2
  maxDepth: 4      # Include up to h4
  title: "On this page"
```

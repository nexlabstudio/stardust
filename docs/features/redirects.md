---
title: Redirects
description: Set up URL redirects for moved or renamed pages.
---

# Redirects

Stardust supports redirects for when you move, rename, or restructure pages. Redirects ensure old URLs continue to work, preserving SEO and preventing broken links.

## Frontmatter Redirects

The simplest way to redirect old URLs to a page is using `redirect_from` in frontmatter:

```yaml
---
title: Getting Started
redirect_from:
  - /quick-start
  - /docs/introduction
---
```

This creates redirects from `/quick-start` and `/docs/introduction` to the current page.

## Config-Based Redirects

For more control, define redirects in `stardust.yaml`:

```yaml
build:
  redirects:
    - from: /old-page
      to: /new-page
    - from: /blog/2023/post
      to: /articles/post
      status: 302
```

### Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `from` | `string` | required | Source path to redirect from |
| `to` | `string` | required | Destination path to redirect to |
| `status` | `int` | `301` | HTTP status code (301, 302, 307, 308) |

## Wildcards and Patterns

Config-based redirects support wildcards for bulk redirects:

```yaml
build:
  redirects:
    # Redirect entire directory
    - from: /docs/*
      to: /guide/:splat

    # Named parameters
    - from: /posts/:slug
      to: /blog/:slug
```

<Warning>
Wildcards and named parameters only work on Netlify, Vercel, and Cloudflare. For GitHub Pages, use exact paths only.
</Warning>

## Examples

### Renaming a Page

When you rename `quick-start.md` to `getting-started.md`:

```yaml
---
title: Getting Started
redirect_from:
  - /quick-start
---
```

### Restructuring Docs

When moving pages to a new structure:

```yaml
build:
  redirects:
    - from: /api/auth
      to: /reference/authentication
    - from: /api/users
      to: /reference/users
```

### Bulk Redirects

When moving an entire section:

```yaml
build:
  redirects:
    - from: /v1/*
      to: /v2/:splat
```

## Status Codes

| Code | Type | Use Case |
|------|------|----------|
| 301 | Permanent | Default. Page permanently moved |
| 302 | Temporary | Page temporarily at different location |
| 307 | Temporary | Preserve request method |
| 308 | Permanent | Preserve request method |

<Note>
Use 301 for most redirects. Search engines will update their index to the new URL.
</Note>

## Limitations

- Cannot redirect from `/` (root path)
- Pattern redirects require a supported hosting platform

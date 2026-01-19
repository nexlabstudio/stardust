---
title: SEO Configuration
description: Optimize your documentation for search engines with meta tags, sitemaps, and structured data.
---

# SEO Configuration

Stardust automatically handles SEO best practices, with options to customize meta tags, Open Graph, and more.

## Basic SEO

At minimum, set your site URL:

```yaml
name: My Project Docs
description: Documentation for My Project
url: https://docs.myproject.com
```

This enables:
- Canonical URLs
- Sitemap generation
- Open Graph URLs

## Page Titles

### Title Template

Customize how page titles appear in browser tabs and search results:

```yaml
seo:
  titleTemplate: "%s | My Project"
```

The `%s` is replaced with the page title. Examples:

| Template | Page Title | Result |
|----------|------------|--------|
| `%s \| My Project` | Installation | Installation \| My Project |
| `%s - Docs` | Quick Start | Quick Start - Docs |
| `My Project: %s` | API | My Project: API |

### Per-Page Titles

Override titles in frontmatter:

```markdown
---
title: Getting Started
seo:
  title: How to Get Started with My Project
---
```

## Meta Descriptions

Set a default description in your config:

```yaml
description: Documentation for My Project - guides, API reference, and examples.
```

Override per-page in frontmatter:

```markdown
---
title: Installation
description: Learn how to install My Project on macOS, Linux, and Windows.
---
```

<Tip>
Keep descriptions between 150-160 characters for optimal display in search results.
</Tip>

## Open Graph

Open Graph tags control how your pages appear when shared on social media.

### Default Image

Set a default social sharing image:

```yaml
seo:
  ogImage: /images/og-default.png
```

Recommended dimensions: 1200×630 pixels.

### Per-Page Images

```markdown
---
title: New Features in v2.0
seo:
  ogImage: /images/v2-features.png
---
```

## Twitter Cards

Configure Twitter-specific sharing:

```yaml
seo:
  twitterCard: summary_large_image
  twitterHandle: "@myproject"
```

Twitter card types:
- `summary` - Small card with thumbnail
- `summary_large_image` - Large featured image

## Sitemap

Stardust automatically generates a sitemap at `/sitemap.xml`:

```yaml
build:
  sitemap:
    enabled: true
    changefreq: weekly
    priority: 0.7
```

### Sitemap Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Generate sitemap |
| `changefreq` | string | `weekly` | How often content changes |
| `priority` | number | `0.7` | Default page priority (0.0-1.0) |

### Per-Page Priority

```markdown
---
title: Home
sitemap:
  priority: 1.0
  changefreq: daily
---
```

## Robots.txt

Control search engine crawling:

```yaml
build:
  robots:
    enabled: true
    allow:
      - /
    disallow:
      - /admin/
      - /internal/
```

The generated `robots.txt`:

```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /internal/

Sitemap: https://docs.myproject.com/sitemap.xml
```

### Exclude Pages

Exclude specific pages from indexing via frontmatter:

```markdown
---
title: Internal Page
robots: noindex
---
```

## Structured Data

Stardust generates JSON-LD structured data for better search engine understanding:

```yaml
seo:
  structuredData: true
```

This adds:
- Organization schema
- WebSite schema
- BreadcrumbList for navigation
- Article schema for documentation pages

## Canonical URLs

Canonical URLs are automatically set based on your `url` configuration. Override per-page:

```markdown
---
title: Installation Guide
canonical: https://docs.myproject.com/install
---
```

## Complete SEO Configuration

```yaml
name: My Project
description: The complete documentation for My Project
url: https://docs.myproject.com

seo:
  titleTemplate: "%s | My Project Docs"
  ogImage: /images/og-default.png
  twitterCard: summary_large_image
  twitterHandle: "@myproject"
  structuredData: true

build:
  sitemap:
    enabled: true
    changefreq: weekly
    priority: 0.7
  robots:
    enabled: true
    allow:
      - /
    disallow:
      - /drafts/
```

## SEO Checklist

<Steps>
  <Step title="Set your site URL">
    Add `url` to your configuration for canonical URLs and sitemap.
  </Step>
  <Step title="Write good descriptions">
    Add `description` to your config and important pages.
  </Step>
  <Step title="Create an OG image">
    Design a 1200×630 image for social sharing.
  </Step>
  <Step title="Verify sitemap">
    Check `/sitemap.xml` after building to ensure all pages are included.
  </Step>
  <Step title="Submit to search engines">
    Submit your sitemap to Google Search Console and Bing Webmaster Tools.
  </Step>
</Steps>

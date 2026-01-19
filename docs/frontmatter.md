---
title: Frontmatter
description: Configure page metadata using YAML frontmatter at the top of your markdown files.
---

# Frontmatter

Frontmatter is YAML metadata at the top of your markdown files, enclosed by triple dashes (`---`). It controls page titles, descriptions, ordering, and more.

## Basic Example

```markdown
---
title: Getting Started
description: Learn how to get started with our product.
---

# Getting Started

Your content here...
```

## Available Fields

### title

The page title, used in the browser tab and navigation.

```yaml
---
title: Installation Guide
---
```

<Note>
If no `title` is specified, Stardust uses the first `# Heading` in your content.
</Note>

### description

A brief description of the page, used for SEO meta tags.

```yaml
---
title: API Reference
description: Complete API documentation for all endpoints.
---
```

### order

Control the order of pages within a sidebar group.

```yaml
---
title: Quick Start
order: 1
---
```

Pages are sorted by `order` (ascending), then alphabetically by filename.

### icon

Add an icon next to the page title in the sidebar.

```yaml
---
title: Installation
icon: download
---
```

You can use:
- Built-in icon names: `download`, `rocket`, `book`, `code`, `settings`, etc.
- Emoji: `icon: "🚀"`

### draft

Mark a page as a draft to exclude it from production builds.

```yaml
---
title: Upcoming Feature
draft: true
---
```

<Warning>
Draft pages are visible during development (`stardust dev`) but excluded from `stardust build`.
</Warning>

### tags

Add tags for categorization (used in search).

```yaml
---
title: Authentication
tags:
  - security
  - api
  - oauth
---
```

### hidden

Hide a page from the sidebar while keeping it accessible via URL.

```yaml
---
title: Secret Page
hidden: true
---
```

## Complete Example

Here's a page using all available frontmatter fields:

```yaml
---
title: Advanced Configuration
description: Learn about advanced configuration options for power users.
order: 5
icon: settings
draft: false
tags:
  - configuration
  - advanced
hidden: false
---

# Advanced Configuration

Content goes here...
```

## SEO Fields

Stardust automatically generates SEO meta tags from frontmatter:

| Frontmatter | Meta Tag |
|-------------|----------|
| `title` | `<title>`, `og:title`, `twitter:title` |
| `description` | `meta[name="description"]`, `og:description`, `twitter:description` |

### Custom Open Graph Image

Override the default Open Graph image for a specific page:

```yaml
---
title: Product Launch
description: Announcing our new product.
ogImage: /images/launch-og.png
---
```

## Accessing Frontmatter

Within your content, frontmatter values are used automatically:

- **Title**: Displayed in browser tab and can be used in sidebar
- **Description**: Added to page's meta tags
- **Icon**: Shown in sidebar navigation
- **Tags**: Indexed for search

## Tips

<Accordion title="When to use title vs # heading">
Always include both:
- `title` in frontmatter for metadata
- `# Heading` in content for the visible page title

They can be the same or different. For example, a short title for the sidebar but a longer heading for the page:

```yaml
---
title: Auth
---

# Authentication and Authorization
```
</Accordion>

<Accordion title="Ordering pages">
Use `order` values with gaps (10, 20, 30) to make it easier to insert pages later:

```yaml
# index.md
order: 10

# installation.md
order: 20

# quickstart.md
order: 30
```
</Accordion>

## Next Steps

<Card title="Components" icon="code" href="/components/callouts">
  Learn about JSX-style components for rich content.
</Card>

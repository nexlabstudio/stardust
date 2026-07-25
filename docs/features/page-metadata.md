---
title: Page Metadata
description: Show reading time, last-updated dates, and contributors from git on every page.
---

# Page Metadata

Show reading time and git-derived history — last-updated date and contributors —
below each article. All three are off by default; enable what you want:

```yaml
pageInfo:
  readingTime: true
  lastUpdated: true
  contributors: true
```

| Option | Source | Description |
|--------|--------|-------------|
| `readingTime` | content | Estimated reading time (~200 words/min) |
| `lastUpdated` | git | Date of the last commit that touched the page |
| `contributors` | git | Authors who have edited the page, most recent first |

## How the git data is gathered

When `lastUpdated` or `contributors` is on, Stardust runs a single `git log`
pass at build time and maps each source file to its history — so enabling both
costs one git invocation, not one per page. The repository root is resolved with
`git rev-parse`, so it works whether your docs are the repo root or a subdirectory
of a monorepo. If the build isn't inside a git repository, the git fields are
simply omitted (reading time still works).

## Labels

The labels are translatable via [i18n strings](/features/i18n#ui-strings):
`page.readingTime` (default `"%s min read"`) and `page.lastUpdated` (default
`"Last updated %s"`), where `%s` is filled in.

## Per-page overrides

Frontmatter still wins for SEO fields — set `ogImage` on a page to override its
Open Graph image, or `title`/`description` for its meta tags.

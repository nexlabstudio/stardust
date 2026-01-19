---
title: Full-Text Search
description: Instant, client-side search powered by Pagefind.
---

# Full-Text Search

Stardust includes powerful full-text search that works entirely client-side—no API keys, no external services, no tracking.

## How It Works

Search is powered by [Pagefind](https://pagefind.app/), which creates a compact search index during build time. When users search:

1. The search UI loads instantly
2. Only the relevant index chunks are downloaded (typically 10-50KB)
3. Results appear as you type
4. Everything runs in the browser

## Using Search

### Opening Search

- Click the search icon in the header
- Press `/` (default hotkey)
- Press `Cmd+K` (Mac) or `Ctrl+K` (Windows/Linux)

### Keyboard Navigation

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate through results |
| `Enter` | Go to selected result |
| `Escape` | Close search dialog |

### Search Tips

- **Simple searches**: Just type keywords like `configuration` or `dark mode`
- **Multiple terms**: `sidebar navigation` finds pages with both terms
- **Phrases**: `"code blocks"` with quotes for exact phrases

## Configuration

Search works with zero configuration, but you can customize it:

```yaml
search:
  enabled: true
  placeholder: "Search documentation..."
  hotkey: "/"
```

See [Search Configuration](/config/search) for all options.

## Search Quality

Stardust optimizes search results by:

- Giving higher weight to headings and titles
- Including page descriptions in the index
- Preserving code block content for searchability
- Generating contextual snippets for results

### Improve Your Search Results

<Tip>
- Write clear, descriptive headings
- Add page descriptions in frontmatter
- Use consistent terminology
- Break content into logical sections
</Tip>

## Excluding Content

### Exclude Entire Pages

```markdown
---
title: Internal Notes
search: false
---
```

### Exclude Sections

Wrap content to exclude it from the search index:

```html
<div data-pagefind-ignore>
This content won't appear in search results.
</div>
```

## Search Index Size

Pagefind creates an extremely efficient index:

| Documentation Size | Typical Index Size |
|--------------------|-------------------|
| 10 pages | 5-15 KB |
| 50 pages | 25-75 KB |
| 200 pages | 100-300 KB |
| 1000 pages | 500 KB - 1.5 MB |

Users only download chunks relevant to their search query.

## Algolia Alternative

For very large documentation sites (1000+ pages) or advanced features like AI search, you can use Algolia:

```yaml
search:
  provider: algolia
  algolia:
    appId: YOUR_APP_ID
    apiKey: YOUR_SEARCH_API_KEY
    indexName: YOUR_INDEX_NAME
```

[Apply for free DocSearch](https://docsearch.algolia.com/apply) for open-source projects.

## Development Mode

During `stardust dev`, search uses a temporary index that updates as you edit. The full optimized index is generated during `stardust build`.

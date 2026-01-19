---
title: Search Configuration
description: Configure full-text search with Pagefind or Algolia.
---

# Search Configuration

Stardust includes powerful full-text search powered by [Pagefind](https://pagefind.app/), with optional Algolia integration.

## Default Search (Pagefind)

Search works out of the box with zero configuration:

```yaml
search:
  enabled: true
```

Pagefind provides:
- Full-text search across all pages
- Instant results as you type
- Works entirely client-side (no API keys needed)
- Automatic search index built during `stardust build`

## Customizing Search

### Placeholder Text

```yaml
search:
  placeholder: "Search documentation..."
```

### Keyboard Shortcut

Change the hotkey to open search:

```yaml
search:
  hotkey: "k"  # Opens with Cmd+K (Mac) or Ctrl+K (Windows/Linux)
```

Default is `/` (press `/` to open search).

### Disabling Search

```yaml
search:
  enabled: false
```

Or hide just the search button while keeping functionality:

```yaml
header:
  showSearch: false
```

## Algolia Search

For larger documentation sites, you can use Algolia DocSearch:

```yaml
search:
  enabled: true
  provider: algolia
  algolia:
    appId: YOUR_APP_ID
    apiKey: YOUR_SEARCH_API_KEY
    indexName: YOUR_INDEX_NAME
```

<Warning>
Only use public search-only API keys in your configuration. Never expose admin API keys.
</Warning>

### Applying for DocSearch

[Algolia DocSearch](https://docsearch.algolia.com/) is free for open-source documentation:

1. Apply at [docsearch.algolia.com/apply](https://docsearch.algolia.com/apply)
2. Wait for approval (typically 1-2 weeks)
3. Receive your credentials via email
4. Add them to your configuration

## Search Behavior

### Opening Search

Users can open search by:
- Clicking the search button in the header
- Pressing the hotkey (`/` by default)
- Pressing `Cmd+K` (Mac) or `Ctrl+K` (Windows/Linux)

### Keyboard Navigation

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate results |
| `Enter` | Go to selected result |
| `Escape` | Close search |

### Search Syntax

Pagefind supports:
- Simple keywords: `configuration`
- Multiple terms: `dark mode theme`
- Phrases: `"code blocks"`

## Excluding Content from Search

### Exclude Pages

Use frontmatter to exclude specific pages:

```markdown
---
title: Internal Page
search: false
---
```

### Exclude Sections

Add `data-pagefind-ignore` to HTML elements:

```html
<div data-pagefind-ignore>
  This content won't be indexed.
</div>
```

Or in markdown with custom components:

```markdown
<div data-pagefind-ignore>

Content here won't appear in search results.

</div>
```

## Search Index

### Build Index

The search index is automatically built when you run:

```bash
stardust build
```

The index is stored in `dist/pagefind/` and is approximately 1-5% of your content size.

### Development Mode

During development (`stardust dev`), search uses a temporary index that updates automatically as you edit content.

## Performance Tips

<Info>
- Keep page titles and descriptions concise for better search results
- Use clear headings that match what users might search for
- The search index is typically very small (a few KB to a few MB)
</Info>

## Complete Search Configuration

```yaml
search:
  enabled: true
  provider: pagefind  # or 'algolia'
  placeholder: "Search docs..."
  hotkey: "/"

  # Only needed for Algolia
  algolia:
    appId: YOUR_APP_ID
    apiKey: YOUR_SEARCH_API_KEY
    indexName: YOUR_INDEX_NAME
```

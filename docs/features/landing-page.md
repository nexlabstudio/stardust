---
title: Landing Page
description: Give your docs a product homepage with a full-width splash layout and a frontmatter-driven hero.
---

# Landing Page

Set `layout: splash` in a page's frontmatter to turn it into a full-width
landing page — no sidebar, no table of contents, no prev/next — opening with a
hero (title, tagline, call-to-action buttons, optional image) followed by your
normal markdown body rendered full-width.

## Example

```markdown
---
title: Stardust
layout: splash
hero:
  tagline: A Dart-native documentation generator. Beautiful docs, zero config.
  image: /images/logo.svg
  actions:
    - label: Get Started
      href: /quickstart
      variant: primary
    - label: View on GitHub
      href: https://github.com/nexlabstudio/stardust
      external: true
---

<Cards cols="3">
  <Card title="Zero Config" icon="zap">Sensible defaults out of the box.</Card>
  <Card title="Blazing Fast" icon="rocket">A native Dart binary.</Card>
  <Card title="Full-Text Search" icon="search" href="/features/search">Powered by Pagefind.</Card>
</Cards>
```

## The `hero` block

`hero` is optional even on a splash page — a splash page can be pure `<Cards>`.

| Key | Type | Description |
|-----|------|-------------|
| `title` | `string` | Hero heading. Defaults to the page `title` |
| `tagline` | `string` | Subheading under the title |
| `image` | `string` | Optional logo/illustration above the title (site-absolute, relative, or external) |
| `actions` | `array` | Call-to-action buttons |

Each entry in `actions` has:

| Key | Type | Description |
|-----|------|-------------|
| `label` | `string` | Button text (required) |
| `href` | `string` | Destination (required) |
| `variant` | `string` | `primary` (filled) or `secondary` (bordered, default) |
| `external` | `boolean` | Opens in a new tab with `rel="noopener"` |

Internal `href`s and the hero image are prefixed with your site's base path, so
they resolve correctly on subpath deploys. All hero text is HTML-escaped and
`href`s are sanitized — a malformed `actions` entry is skipped rather than
breaking the build.

## Call-to-action buttons

Beyond the hero, the `<Button>` component drops a styled call-to-action anywhere
in your markdown body:

```markdown
<Button href="/quickstart" variant="primary">Get Started</Button>
<Button href="https://github.com/nexlabstudio/stardust" external>GitHub</Button>
```

| Attribute | Description |
|-----------|-------------|
| `href` | Destination (base-path-prefixed for internal links, sanitized) |
| `variant` | `primary` (filled) or `secondary` (bordered, default) |
| `external` | Opens in a new tab with `rel="noopener"` |

## Notes

- Any `layout` value other than `splash` (or none) renders the normal docs layout.
- The splash body is still indexed for search and carries the usual meta/OpenGraph tags, so your homepage stays discoverable and shareable.
- Styling uses the theme's design tokens (`--color-primary`, `--color-border`, `--radius`), so the hero matches your palette in light and dark mode.

---
title: stardust check
description: Validate internal links, anchors, images, and sidebar entries.
---

# stardust check

Scan your content for broken internal links, links to missing heading anchors,
missing images, orphaned sidebar entries, and duplicate page paths — before you
deploy. Exits non-zero when errors are found, so it drops straight into CI.

```bash
stardust check
```

Example output:

```
❌ docs/guide.md: broken link -> /instalation (did you mean /installation?)
❌ docs/api.md: link to missing anchor -> /config/theme#colours
❌ docs/media.md: missing image -> /images/example.png
⚠️  stardust.yaml: sidebar entry "old-page" in group "Guides" has no matching page

3 error(s), 1 warning(s)
```

## What it checks

| Check | Severity |
|-------|----------|
| Internal link to a page that does not exist (with a "did you mean" suggestion) | error |
| Link to a heading anchor that does not exist on the target page | error |
| Site-absolute image (`/images/…`) with no file under the assets directory | error |
| Two source files producing the same page path | error |
| Sidebar entry whose slug has no matching page | warning |

External links (`http`, `mailto:`, `tel:`), protocol-relative URLs, and links
or images inside code blocks are ignored.

## Excluding a page

Pages whose links are intentionally illustrative — component demos, generated API
stubs — can opt out with `check: false` in their frontmatter:

```yaml
---
title: Cards
check: false
---
```

The page is still indexed as a link *target* (links pointing to it are validated),
but its own links, anchors, and images are skipped.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `-c, --config` | Path to config file | `stardust.yaml` |

## In CI

`stardust check` exits `1` when any error is found (warnings alone exit `0`), so
add it as a step before your build:

```yaml
- run: stardust check
- run: stardust build
```

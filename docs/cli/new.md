---
title: stardust new
description: Scaffold a new documentation page.
---

# stardust new

Create a new markdown page in your content directory with frontmatter filled in.

```bash
stardust new getting-started
stardust new guides/install --title "Install Guide"
```

The command prints the sidebar snippet to add to `stardust.yaml`. Existing
files are never overwritten.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `<slug>` | Page slug, may include directories | required |
| `-t, --title` | Page title | slug in title case |
| `-c, --config` | Path to config file | `stardust.yaml` |

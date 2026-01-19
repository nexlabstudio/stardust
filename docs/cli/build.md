---
title: stardust build
description: Build your documentation for production deployment.
---

# stardust build

Generate a production-ready static site from your documentation.

## Usage

```bash
stardust build [options]
```

## Examples

### Basic Build

```bash
stardust build
```

Creates optimized output in the `dist/` directory.

### Custom Output Directory

```bash
stardust build --output public
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--output, -o` | `dist/` | Output directory |
| `--clean` | `true` | Clean output directory before build |
| `--no-clean` | - | Keep existing files in output |

## What Gets Built

The build process:

1. **Parses** all markdown files
2. **Renders** HTML pages with styling
3. **Copies** static assets from `public/`
4. **Generates** search index (Pagefind)
5. **Creates** sitemap.xml and robots.txt
6. **Optimizes** for production

## Output Structure

<Tree>
  <Folder name="dist" open>
    <File name="index.html" />
    <File name="installation.html" />
    <Folder name="guide">
      <File name="index.html" />
      <File name="configuration.html" />
    </Folder>
    <Folder name="pagefind">
      <File name="pagefind.js" />
      <File name="pagefind-ui.js" />
      <File name="pagefind-ui.css" />
    </Folder>
    <Folder name="assets">
      <File name="styles.css" />
      <File name="scripts.js" />
    </Folder>
    <File name="sitemap.xml" />
    <File name="robots.txt" />
    <File name="llms.txt" />
  </Folder>
</Tree>

## Configuration

Configure build options in `stardust.yaml`:

```yaml
build:
  outDir: dist/
  cleanUrls: true      # /guide instead of /guide.html
  trailingSlash: false # /guide not /guide/

  sitemap:
    enabled: true
    changefreq: weekly

  robots:
    enabled: true
    allow: ["/"]
    disallow: ["/admin/"]

  llms:
    enabled: true
```

### Clean URLs

With `cleanUrls: true` (default):
- `/guide/` serves `guide/index.html`
- `/installation` serves `installation.html`

With `cleanUrls: false`:
- Explicit `.html` extensions required

## Preview the Build

Test your production build locally:

```bash
stardust build

# Serve the dist folder
cd dist
python -m http.server 8000
# Or use any static file server
npx serve
```

Open http://localhost:8000 to preview.

## Build Performance

Stardust builds are fast:

| Documentation Size | Typical Build Time |
|--------------------|--------------------|
| 10 pages | < 1 second |
| 100 pages | 1-3 seconds |
| 500 pages | 5-10 seconds |

<Info>
Build times depend on page count, component complexity, and search index size.
</Info>

## Continuous Integration

### GitHub Actions

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Stardust
        run: curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash

      - name: Build
        run: stardust build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: dist/
```

### Other CI Systems

The build command requires no special environment—just the Stardust binary:

```bash
# Install and build in any CI
curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash
stardust build
```

## Troubleshooting

### Build Fails

Check the terminal output for:
- Markdown syntax errors
- Invalid frontmatter
- Missing referenced files
- Configuration issues

### Large Output Size

If your `dist/` folder is larger than expected:
- Check for large images in `public/`
- Review if all files in `public/` are needed
- Consider optimizing images before adding them

### Search Not Working

Ensure:
1. `search.enabled: true` in config
2. Build completed without errors
3. `dist/pagefind/` directory exists

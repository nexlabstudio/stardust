---
title: stardust dev
description: Start the development server with hot reload.
---

# stardust dev

Start a local development server with live reload for writing documentation.

## Usage

```bash
stardust dev [options]
```

## Examples

### Basic Usage

```bash
stardust dev
```

Opens your documentation at http://localhost:4000 with:
- Live reload on file changes
- Instant preview of edits
- Development-mode search

### Custom Port

```bash
stardust dev --port 3000
```

### Don't Auto-Open Browser

```bash
stardust dev --no-open
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--port, -p` | `4000` | Port to run the server on |
| `--host` | `localhost` | Host to bind to |
| `--open` | `true` | Open browser automatically |
| `--no-open` | - | Don't open browser |

## Features

### Live Reload

The dev server watches for changes and automatically refreshes:

- **Markdown files** - Content updates instantly
- **Configuration** - `stardust.yaml` changes apply immediately
- **Static assets** - Images and files in `public/`

<Tip>
Save your file and the browser refreshes automatically. No manual refresh needed!
</Tip>

### Error Overlay

When there's a parsing error in your markdown, the dev server shows a helpful overlay with:

- The file containing the error
- Line number
- Description of the issue

### Development Search

Search works during development with a temporary index. For the optimized production index, run `stardust build`.

## Configuration

Set default dev server options in `stardust.yaml`:

```yaml
dev:
  port: 4000
  host: localhost
  open: true
  watch:
    - docs/
    - public/
```

### Watch Directories

By default, Stardust watches `docs/` and `public/`. Add custom directories:

```yaml
dev:
  watch:
    - docs/
    - public/
    - examples/
```

## Network Access

To access from other devices on your network:

```bash
stardust dev --host 0.0.0.0
```

Then access from other devices using your computer's IP address.

## Stopping the Server

Press `Ctrl+C` in the terminal to stop the development server.

## Troubleshooting

### Port Already in Use

If port 4000 is taken:

```bash
stardust dev --port 4001
```

Or find and kill the process using the port:

```bash
# macOS/Linux
lsof -i :4000
kill -9 <PID>

# Windows
netstat -ano | findstr :4000
taskkill /PID <PID> /F
```

### Changes Not Reflecting

1. Check the terminal for errors
2. Try a hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)
3. Restart the dev server

### Slow Reload

For large documentation sites:
- Ensure you're not watching unnecessary directories
- Check for circular includes or large files

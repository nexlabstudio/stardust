---
title: stardust mcp
description: Serve a built site's docs to AI clients over the Model Context Protocol (stdio).
---

# stardust mcp

Serve a built Stardust site to AI clients (Claude Desktop, Cursor, and other [MCP](https://modelcontextprotocol.io/) clients) over the stdio transport. See [MCP Server](/features/mcp) for the full guide.

## Usage

```bash
stardust mcp [dir] [options]
```

`[dir]` is the built site directory. When omitted, it resolves from `build.outDir` in `stardust.yaml`, falling back to `dist`.

The site must be built first — the server reads the `llms.json` manifest and per-page `.md` files that `stardust build` emits (with `build.llms` enabled, the default).

## Examples

```bash
# Build, then serve dist/ over MCP
stardust build
stardust mcp dist

# Inside a project, resolve the output dir from stardust.yaml
stardust mcp
```

## What it exposes

- **`list_pages`** tool — the table of contents (path, title, description), with an optional path-prefix filter.
- **`search_docs`** tool — full-text search across the documentation.
- **`read_page`** tool — the full markdown of a page by its path.
- **Resources** — one `text/markdown` resource per page.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `[dir]` | `build.outDir` (else `dist`) | Built site directory to serve |
| `-c`, `--config` | `stardust.yaml` | Config file, used only to resolve the output dir when `[dir]` is omitted |

## Notes

- Communication is JSON-RPC on **stdin/stdout**; all logs go to **stderr**, keeping stdout a clean protocol channel.
- The server is **read-only** and holds no state between runs — clients launch it as a subprocess.

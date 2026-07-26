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

## Serve over HTTP

By default the server speaks the **stdio** transport (clients launch it as a subprocess). Pass `--http` to serve a live **Streamable HTTP** `/mcp` endpoint instead — for self-hosters who run the binary as a service:

```bash
stardust mcp dist --http --port 8080
# → Endpoint: http://localhost:8080/mcp
```

It binds to `localhost` and validates the `Origin` header (DNS-rebinding guard); loopback origins and non-browser clients are always allowed, other browser origins need `--allow-origin`. See [MCP Server](/features/mcp) for details.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `[dir]` | `build.outDir` (else `dist`) | Built site directory to serve |
| `-c`, `--config` | `stardust.yaml` | Config file, used only to resolve the output dir when `[dir]` is omitted |
| `--http` | off | Serve Streamable HTTP (a live `/mcp` endpoint) instead of stdio |
| `-p`, `--port` | `8080` | Port for `--http` |
| `--host` | `localhost` | Bind host for `--http` |
| `--allow-origin` | — | Allowed browser `Origin` for `--http` (repeatable; `*` for any) |

## Notes

- In stdio mode, communication is JSON-RPC on **stdin/stdout** and all logs go to **stderr**, keeping stdout a clean protocol channel. In `--http` mode, requests come over `POST /mcp`.
- The server is **read-only** and holds no state between runs.

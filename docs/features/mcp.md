---
title: MCP Server
description: Serve any built site's docs to Claude, Cursor, and other AI clients over the Model Context Protocol — locally, air-gapped, no service to run.
---

# MCP Server

Every hosted docs platform now auto-generates an [MCP](https://modelcontextprotocol.io/) server so AI assistants can search and read the docs. Stardust brings that to **static, self-hosted sites**: `stardust mcp` turns the binary you already have into an MCP server over any built site — no service to run, works air-gapped.

A Claude or Cursor user points their client at `stardust mcp <dir>` and gets:

- **`list_pages`** — the table of contents (path, title, description), optionally filtered by a path prefix.
- **`search_docs`** — full-text search across your documentation, returning matching pages with snippets.
- **`read_page`** — the full markdown of any page by its path.
- **Resources** — every page exposed as a `text/markdown` resource, so clients can browse and attach pages directly.

The server reads a **built** site — its `llms.json` manifest and the per-page `.md` files that `stardust build` already emits. It never re-parses your markdown and needs no `stardust.yaml` at serve time, so it can serve any built site, even one you didn't build.

## Usage

Build your site, then serve it:

```bash
stardust build          # emits dist/, including llms.json + per-page .md
stardust mcp dist       # serves dist/ over MCP on stdio
```

With no directory argument, `stardust mcp` resolves the output directory from `stardust.yaml` (falling back to `dist`), so inside a project you can just run:

```bash
stardust mcp
```

The server speaks the [stdio transport](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports): it reads JSON-RPC requests on stdin and writes responses on stdout. All logging goes to stderr, so stdout stays a clean protocol channel.

## Connect a client

MCP clients launch the server as a subprocess. Point yours at the `stardust` binary with `mcp` and your built directory.

**Claude Desktop / Cursor** (`claude_desktop_config.json` or the client's MCP settings):

```json
{
  "mcpServers": {
    "my-docs": {
      "command": "stardust",
      "args": ["mcp", "/absolute/path/to/dist"]
    }
  }
}
```

Restart the client and your docs appear as a connected server — search and read your guides without leaving the chat.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `[dir]` | `build.outDir` (else `dist`) | The built site directory to serve |
| `-c`, `--config` | `stardust.yaml` | Config file, used only to resolve the output dir when `[dir]` is omitted |

## Consume without a server

The same build also produces a static, machine-readable manifest — `llms.json` — plus per-page `.md` files and `llms.txt`. Remote agents that can't launch a subprocess can fetch these directly over HTTP, no MCP server required. See [LLM-Friendly Output](/features/llm-output).

<Note>
The MCP server is **read-only** and requires a built site. Run `stardust build` (with `build.llms` enabled, the default) first — the manifest and per-page markdown it emits are what the server serves.
</Note>

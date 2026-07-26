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

## Serve over HTTP (self-hosting)

Hosted docs platforms expose a live `https://yoursite/mcp` endpoint because they run a server for you. If **you** run a server — a VPS, on-prem box, or air-gapped host — `--http` gives you the same thing:

```bash
stardust mcp dist --http --port 8080
# → Endpoint: http://localhost:8080/mcp
```

This is the MCP [Streamable HTTP transport](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports): a single `/mcp` endpoint answering JSON-RPC over `POST`. Point any MCP client that accepts a URL at `http://your-host:8080/mcp`.

<Warning>
A **pure static host** (GitHub Pages, Netlify, a plain CDN) can't serve `--http` — a live endpoint needs a running process. Those deployments use the static [`llms.json` + `.md` files](/features/llm-output) instead (see below). `--http` is for when you actually run the binary as a service.
</Warning>

**Security.** The server binds to `localhost` by default and validates the `Origin` header to block [DNS-rebinding](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#security-warning) attacks: loopback origins and non-browser clients (which send no `Origin`) are always allowed; other browser origins must be listed with `--allow-origin`. To expose it beyond localhost, set `--host 0.0.0.0` and add each browser origin (`--allow-origin https://app.example.com`, or `--allow-origin '*'` to accept any), ideally behind your own TLS/auth proxy. The server is read-only and stateless.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `[dir]` | `build.outDir` (else `dist`) | The built site directory to serve |
| `-c`, `--config` | `stardust.yaml` | Config file, used only to resolve the output dir when `[dir]` is omitted |
| `--http` | off | Serve Streamable HTTP (a live `/mcp` endpoint) instead of stdio |
| `-p`, `--port` | `8080` | Port for `--http` |
| `--host` | `localhost` | Bind host for `--http` |
| `--allow-origin` | — | Allowed browser `Origin` for `--http` (repeatable; `*` for any) |

## Consume without a server

The same build also produces a static, machine-readable manifest — `llms.json` — plus per-page `.md` files and `llms.txt`. Remote agents that can't launch a subprocess can fetch these directly over HTTP, no MCP server required. See [LLM-Friendly Output](/features/llm-output).

<Note>
The MCP server is **read-only** and requires a built site. Run `stardust build` (with `build.llms` enabled, the default) first — the manifest and per-page markdown it emits are what the server serves.
</Note>

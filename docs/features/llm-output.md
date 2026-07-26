---
title: LLM-Friendly Output
description: Generate consolidated documentation for AI assistants and language models.
---

# LLM-Friendly Output

Stardust can generate a consolidated text file optimized for consumption by AI assistants and large language models (LLMs).

## What Is It?

When enabled, Stardust generates a `/llms.txt` file following the [llms.txt convention](https://llmstxt.org/): a structured index of your documentation with a link and description for every page. This makes it easy for AI tools to:

- Understand your project's documentation
- Answer questions about your API or features
- Generate code examples based on your docs
- Provide accurate assistance to your users

## Enabling LLM Output

```yaml
build:
  llms:
    enabled: true
```

After building, you'll have `dist/llms.txt` alongside your regular documentation.

## Output Format

The generated file mirrors your sidebar structure, with a linked entry per page:

```
# Project Name

> Project description

Website: https://example.com

## Getting Started

- [Introduction](/): What this project does and why.
- [Installation](/installation): Install on macOS, Linux, or Windows.

## API Reference

- [Users](/api/users): Manage user accounts.

...
```

Each entry links to the page and carries its frontmatter description, so an AI tool can discover and fetch exactly the pages it needs.

## llms-full.txt

Alongside the index, Stardust writes `llms-full.txt`: every page's full markdown
content in one file, each section prefixed with the page title and URL. Point
an AI assistant at this single file to give it your entire documentation.

## Per-Page Markdown

Every page is also published as raw markdown next to its HTML — append `.md`
to any page URL:

```
https://example.com/guide      → the rendered page
https://example.com/guide.md   → its markdown source
```

Readers get the same thing through the **Copy page as Markdown** button at the
top of each page — one click to paste a page into an AI chat.

## Machine-Readable Manifest (llms.json)

Alongside `llms.txt`, Stardust writes `llms.json` — a structured index of every
page with its `path`, `title`, `description`, absolute `url`, and the `md` path
to its raw markdown:

```json
{
  "name": "My Project",
  "description": "…",
  "url": "https://example.com",
  "generator": "stardust",
  "pages": [
    { "path": "/guide", "title": "Guide", "description": "…",
      "url": "https://example.com/guide", "md": "/guide.md" }
  ]
}
```

Where `llms.txt` is written for a model to read, `llms.json` is written for a
program to parse: a remote agent can fetch it, enumerate pages, and pull exactly
the `.md` files it needs — consuming the whole site with no server to run. It is
also what powers the [MCP Server](/features/mcp): `stardust mcp` serves a built
site to Claude, Cursor, and other AI clients straight from this manifest.

Pages with `llm: false` are excluded here too. The manifest is written whenever
`build.llms` is enabled (the default).

## Use Cases

### AI Chatbots

Give your support chatbot access to your full documentation:

```python
# Example: Using with an AI assistant
with open('docs/llms.txt') as f:
    documentation = f.read()

response = ai.chat(
    system=f"You are a helpful assistant. Use this documentation:\n{documentation}",
    user="How do I configure dark mode?"
)
```

### RAG Systems

Use `llms.txt` as a knowledge source for Retrieval-Augmented Generation:

1. Chunk the document by sections
2. Generate embeddings for each chunk
3. Store in a vector database
4. Query relevant chunks when users ask questions

### IDE Integrations

AI coding assistants can use your documentation for better suggestions:

```bash
# Point your AI tool to your docs
export DOCS_URL="https://docs.myproject.com/llms.txt"
```

## Content Included

The LLM output includes:

- ✅ All markdown content
- ✅ Code examples
- ✅ API documentation
- ✅ Configuration references
- ✅ Page titles and descriptions

The output excludes:

- ❌ Navigation/sidebar markup
- ❌ Header/footer content
- ❌ Interactive components
- ❌ Images (referenced by URL only)

## Best Practices

<Tip>
**Optimize your docs for AI consumption:**

- Write clear, self-contained explanations
- Include complete code examples
- Use consistent terminology
- Add context that might be obvious to humans but not AI
</Tip>

## Excluding Content

Exclude sensitive or internal pages from LLM output:

```markdown
---
title: Internal Notes
llm: false
---
```

## File Size Considerations

llms.txt is an index — one line per page — so it stays small (a few KB) even for large sites. `llms-full.txt` grows with your content; agents that need everything fetch it once.

## Why This Matters

As AI assistants become more prevalent, having machine-readable documentation helps:

1. **Users get better AI assistance** with your product
2. **AI tools provide accurate answers** instead of hallucinating
3. **Your documentation stays the source of truth** for both humans and AI
4. **Integration is simple**—just point AI tools to one URL

## Accessing the File

After running `stardust build`, access your LLM-friendly docs at:

```
https://your-docs-site.com/llms.txt
```

Or for local development:

```
http://localhost:4000/llms.txt
```

---
title: LLM-Friendly Output
description: Generate consolidated documentation for AI assistants and language models.
---

# LLM-Friendly Output

Stardust can generate a consolidated text file optimized for consumption by AI assistants and large language models (LLMs).

## What Is It?

When enabled, Stardust generates a `/llms.txt` file containing all your documentation in a single, structured text format. This makes it easy for AI tools to:

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

The generated file includes:

```
# Project Name

## Introduction
[Content from index.md]

## Installation
[Content from installation.md]

## API Reference
[Content from api/index.md]

### GET /users
[Endpoint documentation]

...
```

Each page is clearly delimited with its title and full content, making it easy for LLMs to parse and reference.

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

| Documentation Size | Approximate llms.txt Size |
|--------------------|--------------------------|
| 20 pages | 50-100 KB |
| 100 pages | 250-500 KB |
| 500 pages | 1-2 MB |

Most LLMs can handle several hundred KB of context effectively.

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

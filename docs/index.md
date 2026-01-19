---
title: Introduction
description: Stardust is a Dart-native documentation framework that generates beautiful, static documentation sites with zero configuration.
---

# Introduction

Stardust is a **Dart-native documentation framework** that generates beautiful, static documentation sites with zero configuration required.

<Info>
Stardust is built entirely in Dart — no Node.js, no npm, no JavaScript toolchain required.
</Info>

## Why Stardust?

Building documentation shouldn't require a complex JavaScript toolchain. Stardust provides:

<Tiles columns={3}>
  <Tile title="Zero Config" icon="sparkles">
    Sensible defaults out of the box. Start writing immediately.
  </Tile>
  <Tile title="Blazing Fast" icon="zap">
    Native Dart binary. Builds in milliseconds, not minutes.
  </Tile>
  <Tile title="Beautiful" icon="star">
    Clean, modern design with automatic dark mode support.
  </Tile>
</Tiles>

## Key Features

- **Markdown-based** — Write docs in Markdown with powerful JSX-style components
- **30+ Components** — Callouts, tabs, code groups, API docs, and more
- **Full-text Search** — Powered by Pagefind, works entirely client-side
- **SEO Optimized** — Automatic sitemap, robots.txt, Open Graph, and Twitter Cards
- **OpenAPI Import** — Generate API documentation from Swagger/OpenAPI specs
- **LLM-friendly** — Generate `llms.txt` for AI assistants
- **Dark Mode** — Automatic dark mode that respects system preferences

## Quick Example

Create a markdown file with JSX-style components:

```markdown
# Getting Started

<Info>
This guide will help you get up and running in 5 minutes.
</Info>

<Steps>
  <Step title="Install Stardust">
    Run the installation command for your platform.
  </Step>
  <Step title="Initialize a project">
    Use `stardust init` to create a new docs project.
  </Step>
  <Step title="Start writing">
    Create markdown files in the `docs/` directory.
  </Step>
</Steps>
```

## Ready to get started?

<Cards>
  <Card title="Installation" icon="download" href="/installation">
    Install Stardust on macOS, Linux, or Windows.
  </Card>
  <Card title="Quick Start" icon="rocket" href="/quickstart">
    Create your first documentation site in 5 minutes.
  </Card>
</Cards>

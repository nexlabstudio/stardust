---
title: Cards
description: Create visually appealing navigation and content cards.
---

# Cards

Cards provide an attractive way to highlight content, create navigation, and organize information into visual blocks.

## Basic Cards

<Cards>
  <Card title="Getting Started" icon="rocket" href="/quickstart">
    Learn the basics and create your first project.
  </Card>
  <Card title="Components" icon="code" href="/components/callouts">
    Explore the built-in component library.
  </Card>
  <Card title="Configuration" icon="settings" href="/config/overview">
    Customize your documentation site.
  </Card>
</Cards>

```markdown
<Cards>
  <Card title="Getting Started" icon="rocket" href="/quickstart">
    Learn the basics and create your first project.
  </Card>
  <Card title="Components" icon="code" href="/components/callouts">
    Explore the built-in component library.
  </Card>
  <Card title="Configuration" icon="settings" href="/config/overview">
    Customize your documentation site.
  </Card>
</Cards>
```

## Single Card

Use a standalone card for featured content:

<Card title="New in v2.0" icon="sparkles" href="/changelog">
  Check out the latest features including OpenAPI import and LLM-friendly output.
</Card>

```markdown
<Card title="New in v2.0" icon="sparkles" href="/changelog">
  Check out the latest features including OpenAPI import and LLM-friendly output.
</Card>
```

## Cards with Emoji Icons

<Cards>
  <Card title="Documentation" icon="📖" href="/docs">
    Comprehensive guides and references.
  </Card>
  <Card title="Examples" icon="💡" href="/examples">
    Real-world usage examples.
  </Card>
  <Card title="Community" icon="👥" href="/community">
    Join our community discussions.
  </Card>
</Cards>

```markdown
<Cards>
  <Card title="Documentation" icon="📖" href="/docs">
    Comprehensive guides and references.
  </Card>
  <Card title="Examples" icon="💡" href="/examples">
    Real-world usage examples.
  </Card>
</Cards>
```

## External Links

Cards can link to external URLs:

<Cards>
  <Card title="GitHub" icon="github" href="https://github.com/nexlabstudio/stardust">
    View source code and contribute.
  </Card>
  <Card title="Discord" icon="discord" href="https://discord.gg/example">
    Chat with the community.
  </Card>
</Cards>

## Cards Without Links

Cards without `href` are purely informational:

<Cards>
  <Card title="Fast Builds" icon="zap">
    Native Dart binary compiles documentation in milliseconds.
  </Card>
  <Card title="Zero Config" icon="sparkles">
    Sensible defaults mean you can start writing immediately.
  </Card>
  <Card title="Beautiful Design" icon="star">
    Modern, clean design with automatic dark mode.
  </Card>
</Cards>

## Available Icons

Built-in icon names you can use:

<Columns>
  <Column>
    - `arrow-right`
    - `arrow-left`
    - `check`
    - `x`
    - `info`
    - `warning`
    - `star`
    - `heart`
    - `home`
    - `settings`
  </Column>
  <Column>
    - `search`
    - `menu`
    - `close`
    - `copy`
    - `external-link`
    - `github`
    - `twitter`
    - `discord`
    - `rocket`
    - `book`
  </Column>
  <Column>
    - `code`
    - `terminal`
    - `file`
    - `folder`
    - `download`
    - `upload`
    - `link`
    - `mail`
    - `user`
    - `zap`
  </Column>
</Columns>

## Feature Highlights Example

<Cards>
  <Card title="Markdown-Based" icon="file">
    Write documentation in familiar Markdown with powerful extensions.
  </Card>
  <Card title="30+ Components" icon="code">
    Callouts, tabs, accordions, steps, and more built-in.
  </Card>
  <Card title="Full-Text Search" icon="search">
    Pagefind-powered search works entirely client-side.
  </Card>
  <Card title="SEO Optimized" icon="sparkles">
    Automatic sitemap, meta tags, and Open Graph support.
  </Card>
</Cards>

## Use Cases

| Use Case | Example |
|----------|---------|
| Navigation | Link to major sections of your docs |
| Feature highlights | Showcase product capabilities |
| Related content | Suggest next steps or related pages |
| Quick links | Provide shortcuts to common destinations |

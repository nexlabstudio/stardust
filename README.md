# ✨ Stardust

A Dart-native documentation framework. Beautiful docs, zero config.

## Features

- 📝 **Markdown-based** — Write docs in Markdown with powerful extensions
- 🎨 **Beautiful by default** — Clean, modern design out of the box
- 🌙 **Dark mode** — Automatic dark mode support
- ⚡ **Fast** — Static site generation for instant page loads
- 🎯 **Dart-native** — No Node.js, no JavaScript toolchain required
- 🧩 **Components** — Callouts, tabs, code groups, and more

## Installation

```bash
dart pub global activate stardust
```

## Quick Start

```bash
# Create a new docs project
stardust init my-docs
cd my-docs

# Start the dev server
stardust dev

# Build for production
stardust build
```

## Project Structure

```
my-docs/
├── docs/           # Your markdown files
│   ├── index.md    # Home page
│   └── ...
├── public/         # Static assets (images, etc.)
├── docs.yaml       # Configuration
└── dist/           # Build output (generated)
```

## Configuration

Create a `docs.yaml` file in your project root:

```yaml
name: My Project
description: Documentation for My Project

content:
  dir: docs/

nav:
  - label: Guide
    href: /
  - label: GitHub
    href: https://github.com/user/repo
    external: true

sidebar:
  - group: Getting Started
    pages:
      - index
      - installation
      - quickstart

theme:
  colors:
    primary: "#6366f1"
  darkMode:
    enabled: true
    default: system
```

## Components

Stardust uses JSX-style components, similar to docs.page and Mintlify.

### Callouts

```markdown
<Info>This is an informational callout.</Info>

<Warning>This is a warning callout.</Warning>

<Danger>This is a danger/error callout.</Danger>

<Tip>This is a helpful tip.</Tip>

<Note>This is a side note.</Note>

<Success>This is a success message.</Success>
```

With custom title:

```markdown
<Info title="Did you know?">
You can customize the title of any callout.
</Info>
```

### Tabs

```markdown
<Tabs>
  <Tab name="JavaScript">
    console.log('Hello, world!');
  </Tab>
  <Tab name="Dart">
    print('Hello, world!');
  </Tab>
  <Tab name="Python">
    print('Hello, world!')
  </Tab>
</Tabs>
```

### Code Groups

```markdown
<CodeGroup>
  <Code title="main.dart" language="dart">
    void main() => print('hello');
  </Code>
  <Code title="pubspec.yaml" language="yaml">
    name: my_app
  </Code>
</CodeGroup>
```

### Accordion

```markdown
<Accordion title="Click to expand">
This content is hidden by default.
</Accordion>
```

Group multiple accordions:

```markdown
<AccordionGroup>
  <Accordion title="First section">
    Content for first section.
  </Accordion>
  <Accordion title="Second section">
    Content for second section.
  </Accordion>
</AccordionGroup>
```

### Steps

```markdown
<Steps>
  <Step title="Install dependencies">
    Run `dart pub get` to install all dependencies.
  </Step>
  <Step title="Configure your project">
    Create a `docs.yaml` file with your configuration.
  </Step>
  <Step title="Start writing">
    Create markdown files in the `docs/` directory.
  </Step>
</Steps>
```

### Cards

```markdown
<Cards>
  <Card title="Getting Started" icon="🚀" href="/guide">
    Learn the basics in 5 minutes
  </Card>
  <Card title="API Reference" icon="📖" href="/api">
    Full API documentation
  </Card>
</Cards>
```

Standalone card:

```markdown
<Card title="Featured" href="/featured">
  Check out this featured content.
</Card>
```

### Columns

```markdown
<Columns>
  <Column>
    Left column content goes here.
  </Column>
  <Column>
    Right column content goes here.
  </Column>
</Columns>
```

With custom width:

```markdown
<Columns gap="2rem">
  <Column width="30%">Sidebar</Column>
  <Column>Main content area</Column>
</Columns>
```

### Tiles

```markdown
<Tiles columns={3}>
  <Tile title="Fast" icon="⚡">Lightning quick builds</Tile>
  <Tile title="Simple" icon="✨">Zero configuration</Tile>
  <Tile title="Beautiful" icon="🎨">Gorgeous defaults</Tile>
</Tiles>
```

With links:

```markdown
<Tiles columns={2}>
  <Tile title="Guide" icon="📖" href="/guide">
    Step-by-step tutorials
  </Tile>
  <Tile title="API" icon="🔧" href="/api">
    Reference documentation
  </Tile>
</Tiles>
```

### Panel

```markdown
<Panel title="Important Information" icon="ℹ️">
  This is highlighted content in a panel.
</Panel>
```

With variants:

```markdown
<Panel title="Success" variant="success">
  Operation completed successfully!
</Panel>

<Panel title="Warning" variant="warning">
  Please review before continuing.
</Panel>
```

### Badge

```markdown
<Badge>Default</Badge>
<Badge variant="primary">Primary</Badge>
<Badge variant="success">Success</Badge>
<Badge variant="warning">Warning</Badge>
<Badge variant="danger">Danger</Badge>
```

With sizes:

```markdown
<Badge size="sm">Small</Badge>
<Badge size="md">Medium</Badge>
<Badge size="lg">Large</Badge>
```

### Icon

```markdown
<Icon name="rocket" />
<Icon name="github" size="24" />
<Icon name="star" color="#f59e0b" />
```

Emoji icons:

```markdown
<Icon name="🚀" size="32" />
```

Available built-in icons: `arrow-right`, `arrow-left`, `check`, `x`, `info`, `warning`, `star`, `heart`, `home`, `settings`, `search`, `menu`, `close`, `copy`, `external-link`, `github`, `twitter`, `discord`, `rocket`, `book`, `code`, `terminal`, `file`, `folder`, `download`, `upload`, `link`, `mail`, `user`, `users`, `zap`, `sparkles`.

### Image

```markdown
<Image src="/screenshot.png" alt="Screenshot" />
```

With zoom (click to enlarge):

```markdown
<Image src="/screenshot.png" alt="Screenshot" zoom />
```

With caption and styling:

```markdown
<Image 
  src="/screenshot.png" 
  alt="Screenshot" 
  caption="Figure 1: Application screenshot"
  rounded
  border
/>
```

### Tree

Display file/folder structures:

```markdown
<Tree>
  <Folder name="src" open>
    <Folder name="components">
      <File name="Button.tsx" />
      <File name="Card.tsx" />
    </Folder>
    <File name="index.ts" />
  </Folder>
  <File name="package.json" />
  <File name="README.md" />
</Tree>
```

Files automatically get icons based on extension (e.g., 🎯 for `.dart`, 🐍 for `.py`).

### Mermaid

Render diagrams with Mermaid:

```markdown
<Mermaid>
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Do something]
    B -->|No| D[Do something else]
    C --> E[End]
    D --> E
</Mermaid>
```

With caption:

```markdown
<Mermaid caption="Figure 2: User flow diagram">
sequenceDiagram
    User->>App: Request
    App->>API: Fetch data
    API-->>App: Response
    App-->>User: Display
</Mermaid>
```

Supports flowcharts, sequence diagrams, class diagrams, state diagrams, and more.

### Tooltip

Add hover tooltips:

```markdown
<Tooltip content="This is the tooltip text">Hover me</Tooltip>
```

With different positions:

```markdown
<Tooltip content="Top tooltip" position="top">Top</Tooltip>
<Tooltip content="Bottom tooltip" position="bottom">Bottom</Tooltip>
<Tooltip content="Left tooltip" position="left">Left</Tooltip>
<Tooltip content="Right tooltip" position="right">Right</Tooltip>
```

### YouTube

Embed YouTube videos:

```markdown
<YouTube id="dQw4w9WgXcQ" />
```

With options:

```markdown
<YouTube 
  id="dQw4w9WgXcQ" 
  title="Video title"
  start="30"
  aspectRatio="16/9"
/>
```

Also accepts full URLs:

```markdown
<YouTube id="https://www.youtube.com/watch?v=dQw4w9WgXcQ" />
<YouTube id="https://youtu.be/dQw4w9WgXcQ" />
```

### Vimeo

Embed Vimeo videos:

```markdown
<Vimeo id="123456789" />
```

With options:

```markdown
<Vimeo 
  id="123456789" 
  title="Video title"
  aspectRatio="16/9"
/>
```

### Video

Embed self-hosted videos:

```markdown
<Video src="/videos/demo.mp4" />
```

With options:

```markdown
<Video 
  src="/videos/demo.mp4" 
  poster="/images/poster.jpg"
  autoplay
  loop
  muted
/>
```

### Zapp

Embed Dart/Flutter playgrounds from [zapp.run](https://zapp.run):

```markdown
<Zapp id="flutter_counter" />
```

With options:

```markdown
<Zapp 
  id="flutter_counter" 
  theme="dark"
  height="600px"
/>
```

### CodePen

Embed CodePen pens:

```markdown
<CodePen user="username" id="pen-id" />
```

With options:

```markdown
<CodePen 
  user="css-tricks" 
  id="abcdef"
  height="400"
  defaultTab="css,result"
  theme="dark"
  editable
/>
```

### StackBlitz

Embed StackBlitz projects:

```markdown
<StackBlitz id="project-id" />
```

With options:

```markdown
<StackBlitz 
  id="vitejs-vite-abc123"
  height="600px"
  file="src/App.tsx"
  view="preview"
  hideNavigation
  hideDevTools
/>
```

### Field (API Docs)

Document request body fields:

```markdown
<Field name="email" type="string" required>
  The user's email address.
</Field>

<Field name="age" type="number" default="18">
  The user's age in years.
</Field>

<Field name="role" type="string" deprecated>
  Use `permissions` instead.
</Field>
```

### ResponseField (API Docs)

Document API response fields:

```markdown
<ResponseField name="id" type="string">
  Unique identifier for the resource.
</ResponseField>

<ResponseField name="metadata" type="object" nullable>
  Optional metadata object.
</ResponseField>
```

### ParamField (API Docs)

Document URL or query parameters:

```markdown
<ParamField name="id" type="string" paramType="path" required>
  The resource ID.
</ParamField>

<ParamField name="limit" type="integer" paramType="query" default="10">
  Number of results to return.
</ParamField>
```

### Api (API Endpoint)

Document API endpoints:

```markdown
<Api method="GET" path="/users/{id}" auth="Bearer token">

Get a user by ID.

<ParamField name="id" type="string" paramType="path" required>
  The user ID.
</ParamField>

**Response**

<ResponseField name="id" type="string">
  The user's unique identifier.
</ResponseField>

<ResponseField name="email" type="string">
  The user's email address.
</ResponseField>

</Api>
```

### Frame

Display content in browser or phone frames:

```markdown
<Frame type="browser" url="https://example.com">
  <Image src="/screenshot.png" alt="App screenshot" />
</Frame>
```

Phone frame:

```markdown
<Frame type="phone">
  <Image src="/mobile-screenshot.png" alt="Mobile view" />
</Frame>
```

### Update

Changelog entries:

```markdown
<Update label="New Feature" version="2.0.0" date="2024-01-15" type="feature">
  Added dark mode support with automatic system preference detection.
</Update>

<Update label="Bug Fix" type="fix">
  Fixed issue where sidebar would not scroll on mobile devices.
</Update>

<Update label="Breaking Change" version="2.0.0" type="breaking">
  The `config.theme` option has been renamed to `config.appearance`.
</Update>
```

Update types: `feature`, `fix`, `breaking`, `deprecation`, `improvement`, `default`.

## Commands

### `stardust init [directory]`

Initialize a new Stardust documentation project.

Options:
- `-n, --name` — Project name
- `-f, --force` — Overwrite existing files

### `stardust dev`

Start the development server with hot reload.

Options:
- `-c, --config` — Path to config file (default: `docs.yaml`)
- `-p, --port` — Port to serve on (default: `4000`)
- `--host` — Host to bind to (default: `localhost`)
- `-o, --open` — Open browser automatically

### `stardust build`

Build the static documentation site.

Options:
- `-c, --config` — Path to config file (default: `docs.yaml`)
- `-o, --output` — Output directory (default: `dist`)
- `--clean` — Clean output directory before building (default: `true`)
- `--skip-search` — Skip search index generation
- `-v, --verbose` — Verbose output

## Search

Stardust includes full-text search powered by [Pagefind](https://pagefind.app/). **No installation required** — Stardust automatically downloads the Pagefind binary on first build.

### How it works

1. Run `stardust build` to generate your site
2. Pagefind binary is downloaded automatically (cached in `~/.stardust/bin/`)
3. All pages are indexed
4. Users can search using the search button or keyboard shortcuts

### Configuration

Configure search in `docs.yaml`:

```yaml
search:
  enabled: true
  provider: pagefind    # currently only pagefind is supported
  placeholder: "Search docs..."
  hotkey: "/"           # keyboard shortcut to open search
```

To disable search:

```yaml
search:
  enabled: false
```

Or skip search indexing for a single build:

```bash
stardust build --skip-search
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `/` | Open search |
| `Cmd/Ctrl + K` | Open/close search |
| `Escape` | Close search |
| `↑` `↓` | Navigate results |
| `Enter` | Select result |

## Frontmatter

Each markdown file can have optional frontmatter:

```markdown
---
title: My Page Title
description: A description for SEO
order: 1
icon: 🚀
draft: false
tags:
  - guide
  - tutorial
---

# My Page Title

Content goes here...
```

## Deployment

Stardust generates a static site in the `dist/` directory. Deploy it anywhere:

- **GitHub Pages** — Push to `gh-pages` branch
- **Any static host** — Just upload the `dist/` folder

## SEO

Stardust automatically generates `sitemap.xml` and `robots.txt` for search engine optimization.

### Sitemap

To enable sitemap generation, set the `url` in your `docs.yaml`:

```yaml
url: https://your-docs.com

build:
  sitemap:
    enabled: true        # default: true
    changefreq: weekly   # always, hourly, daily, weekly, monthly, yearly, never
    priority: 0.7        # 0.0 to 1.0
```

This generates `/sitemap.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://your-docs.com/</loc>
    <lastmod>2025-01-18</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.7</priority>
  </url>
  <!-- ... more pages -->
</urlset>
```

The `lastmod` date is automatically set from each file's modification time.

### Robots.txt

Configure crawling rules:

```yaml
build:
  robots:
    enabled: true        # default: true
    allow:
      - /
    disallow:
      - /internal/
      - /drafts/
```

This generates `/robots.txt`:

```
User-agent: *
Allow: /
Disallow: /internal/
Disallow: /drafts/

Sitemap: https://your-docs.com/sitemap.xml
```

### Open Graph & Twitter Cards

Page metadata is automatically generated from frontmatter:

```yaml
seo:
  titleTemplate: "%s | My Docs"    # %s = page title
  ogImage: /assets/og-image.png
  twitterCard: summary_large_image
  twitterHandle: "@youraccount"
```

Each page's `title` and `description` frontmatter are used for meta tags.

## License

MIT
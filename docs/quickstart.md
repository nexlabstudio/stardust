---
title: Quick Start
description: Create your first Stardust documentation site in under 5 minutes.
---

# Quick Start

Get up and running with Stardust in under 5 minutes.

## Create a New Project

<Steps>
  <Step title="Initialize your project">
    Create a new documentation project:

    ```bash
    stardust init my-docs
    cd my-docs
    ```

    This creates the following structure:

    <Tree>
      <Folder name="my-docs" open>
        <Folder name="docs" open>
          <File name="index.md" />
          <File name="getting-started.md" />
        </Folder>
        <Folder name="public">
        </Folder>
        <File name="stardust.yaml" />
      </Folder>
    </Tree>
  </Step>
  <Step title="Start the development server">
    Run the development server with hot reload:

    ```bash
    stardust dev
    ```

    Open [http://localhost:4000](http://localhost:4000) in your browser.

    <Tip>
    Use `stardust dev --open` to automatically open your browser.
    </Tip>
  </Step>
  <Step title="Edit your content">
    Open `docs/index.md` and make some changes. The browser will automatically refresh.
  </Step>
  <Step title="Build for production">
    When you're ready to deploy:

    ```bash
    stardust build
    ```

    Your static site is generated in the `dist/` directory.
  </Step>
</Steps>

## Project Structure

A Stardust project has the following structure:

```
my-docs/
├── docs/              # Your markdown files
│   ├── index.md       # Home page (required)
│   ├── guide.md       # Additional pages
│   └── api/           # Nested pages
│       └── overview.md
├── public/            # Static assets (images, etc.)
├── stardust.yaml      # Configuration file
└── dist/              # Build output (generated)
```

### Key Files

| File | Description |
|------|-------------|
| `stardust.yaml` | Configuration file for your site |
| `docs/index.md` | The home page of your documentation |
| `public/` | Static assets copied to the build output |
| `dist/` | Generated static site (created by `stardust build`) |

## Basic Configuration

Edit `stardust.yaml` to customize your site:

```yaml
name: My Project
description: Documentation for My Project
url: https://docs.myproject.com

nav:
  - label: Docs
    href: /
  - label: GitHub
    href: https://github.com/myorg/myproject
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
```

## Writing Your First Page

Create a new file `docs/guide.md`:

```markdown
---
title: User Guide
description: Learn how to use My Project effectively.
---

# User Guide

Welcome to the user guide!

<Info>
This guide covers the basics of using My Project.
</Info>

## Getting Started

Here's how to get started...
```

Then add it to your sidebar in `stardust.yaml`:

```yaml
sidebar:
  - group: Getting Started
    pages:
      - index
      - guide  # Add this line
```

## Next Steps

<Cards>
  <Card title="Markdown" icon="file" href="/markdown">
    Learn about Markdown syntax and extensions.
  </Card>
  <Card title="Components" icon="code" href="/components/callouts">
    Explore the built-in component library.
  </Card>
  <Card title="Configuration" icon="settings" href="/config/overview">
    Customize your documentation site.
  </Card>
  <Card title="Deployment" icon="upload" href="/deployment/overview">
    Deploy your site to production.
  </Card>
</Cards>

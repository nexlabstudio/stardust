---
title: stardust init
description: Create a new Stardust documentation project.
---

# stardust init

Create a new Stardust documentation project with a single command.

## Usage

```bash
stardust init [directory]
```

If no directory is specified, creates the project in the current directory.

## Examples

### Create in a New Directory

```bash
stardust init my-docs
cd my-docs
stardust dev
```

### Create in Current Directory

```bash
mkdir my-docs && cd my-docs
stardust init
```

## What Gets Created

The `init` command creates a complete documentation project:

<Tree>
  <Folder name="my-docs" open>
    <Folder name="docs" open>
      <File name="index.md" />
    </Folder>
    <Folder name="public">
      <File name=".gitkeep" />
    </Folder>
    <File name="stardust.yaml" />
    <File name=".gitignore" />
  </Folder>
</Tree>

### Generated Files

**stardust.yaml** - Configuration file:

```yaml
name: My Docs
description: Documentation powered by Stardust

nav:
  - label: Home
    href: /

sidebar:
  - group: Getting Started
    pages:
      - index
```

**docs/index.md** - Your first page:

```markdown
---
title: Welcome
description: Welcome to your new documentation site.
---

# Welcome

Welcome to your documentation site powered by Stardust!

## Next Steps

- Edit this page in `docs/index.md`
- Add more pages to the `docs/` directory
- Customize `stardust.yaml` to configure your site
```

**.gitignore** - Ignores build output:

```
dist/
.stardust/
```

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help for the init command |

## After Initialization

<Steps>
  <Step title="Start the dev server">
    ```bash
    stardust dev
    ```

    Open http://localhost:4000 to see your site.
  </Step>
  <Step title="Edit your content">
    Open `docs/index.md` in your editor and start writing.
  </Step>
  <Step title="Add more pages">
    Create new `.md` files in the `docs/` directory.
  </Step>
  <Step title="Configure your site">
    Edit `stardust.yaml` to customize navigation, theme, and more.
  </Step>
</Steps>

## Tips

<Info>
- The `docs/` directory is where all your markdown files go
- The `public/` directory is for static assets (images, files)
- Configuration is in `stardust.yaml`
</Info>

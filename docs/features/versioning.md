---
title: Versioning
description: Serve multiple versions of your documentation side by side.
---

# Versioning

Stardust supports versioned documentation, allowing you to maintain docs for multiple releases simultaneously. Each version is built independently and Stardust renders a version dropdown and optional warning banner.

## How It Works

Stardust follows a **single-build-per-version** model:

1. Each `stardust build` invocation produces one version of your docs
2. The `versions` config tells Stardust about all versions so it can render the UI (dropdown, banner)
3. You deploy each version's output to a different path (e.g. `/v1/`, `/v2/`)
4. Orchestration (building multiple versions, merging outputs) is handled externally — typically in CI

This is the same proven approach used by [mike](https://github.com/jimporter/mike) (MkDocs) and similar tools.

## Configuration

Add a `versions` section to your `stardust.yaml`:

```yaml
versions:
  enabled: true
  current: "2.0"
  dropdown: true
  list:
    - version: "2.0"
      label: "v2.0 (Latest)"
      path: /v2/
    - version: "1.0"
      label: "v1.0"
      path: /v1/
      banner: "You're viewing docs for v1.0. <a href='/v2/'>Switch to latest</a>."
```

### Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enabled` | `boolean` | `false` | Enable versioning UI |
| `current` | `string` | — | The version this build represents |
| `default` | `string` | — | The default version (for future use) |
| `dropdown` | `boolean` | `true` | Show version dropdown in header |
| `list` | `array` | `[]` | All available versions |

### Version Entry

Each item in `list` has:

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `version` | `string` | Yes | Version identifier (e.g. `"2.0"`) |
| `path` | `string` | Yes | URL path where this version is deployed |
| `label` | `string` | No | Display label in dropdown. Defaults to `v{version}` |
| `banner` | `string` | No | Warning banner text (supports HTML). Shown when viewing this version |

## Version Dropdown

When `dropdown: true`, a version selector appears in the header next to the theme toggle. It shows the current version and lists all available versions as links.

To hide the dropdown while still using the banner:

```yaml
versions:
  enabled: true
  current: "1.0"
  dropdown: false
  list:
    - version: "1.0"
      path: /
      banner: "This version is outdated."
```

## Version Banner

If the current version's entry has a `banner` field, an amber warning bar appears above the header. This is typically used on older versions to direct users to the latest.

The banner supports HTML, so you can include links:

```yaml
banner: "You're viewing v1.0 docs. <a href='/v2/'>Switch to the latest version</a>."
```

The banner is dismissible — users can close it and their preference is saved in `localStorage`.

## Workflow

### Setting Up Versioning

**Step 1**: Decide on your version paths. A common convention:

| Version | Path | Notes |
|---------|------|-------|
| Latest (v2.0) | `/v2/` or `/` | Your main docs |
| Previous (v1.0) | `/v1/` | Older version |

**Step 2**: Add the `versions` config to each version's `stardust.yaml`. The `list` stays the same across all versions — only `current` changes.

For **v2.0** (latest):

```yaml
versions:
  enabled: true
  current: "2.0"
  list:
    - version: "2.0"
      label: "v2.0 (Latest)"
      path: /v2/
    - version: "1.0"
      label: "v1.0"
      path: /v1/
      banner: "You're viewing an older version. <a href='/v2/'>Go to latest</a>."

build:
  outDir: build/v2
```

For **v1.0** (previous):

```yaml
versions:
  enabled: true
  current: "1.0"
  list:
    - version: "2.0"
      label: "v2.0 (Latest)"
      path: /v2/
    - version: "1.0"
      label: "v1.0"
      path: /v1/
      banner: "You're viewing an older version. <a href='/v2/'>Go to latest</a>."

build:
  outDir: build/v1
```

**Step 3**: Build each version and merge the outputs:

```bash
# Build v2 (from main branch)
git checkout main
stardust build

# Build v1 (from v1 branch or tag)
git checkout v1.0
stardust build

# Merge into deploy directory
mkdir -p deploy
cp -r build/v2/* deploy/v2/
cp -r build/v1/* deploy/v1/
```

### Using Git Branches

The most common approach is one branch per version:

```
main       → v2.0 (latest)
v1.x       → v1.0
```

Each branch has its own `stardust.yaml` with `versions.current` set appropriately. The `versions.list` is identical across branches.

### Using Git Tags

Alternatively, use tags to snapshot versions:

```bash
git tag v1.0
# Continue developing on main for v2.0
```

Build from the tag when needed:

```bash
git checkout v1.0
stardust build
```

## CI Example

### GitHub Actions

```yaml
name: Deploy Versioned Docs

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Stardust
        run: curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash

      # Build latest (v2) — uses build.outDir from stardust.yaml
      - run: stardust build

      # Build v1 from tag
      - run: |
          git checkout v1.0
          stardust build

      # Merge and deploy
      - run: |
          mkdir -p deploy
          cp -r build/v2/* deploy/v2/
          cp -r build/v1/* deploy/v1/

      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./deploy
```

<Tip>
Each version's `stardust.yaml` should have a different `build.outDir` (e.g. `build/v2` for latest, `build/v1` for previous) so the outputs don't overwrite each other.
</Tip>

## Styling

The version UI components can be customized with CSS variables and class overrides.

### CSS Variables

```css
:root {
  --version-banner-color: #b45309;
  --version-banner-bg: color-mix(in srgb, #f59e0b 10%, var(--color-bg));
}

.dark {
  --version-banner-color: #fbbf24;
}
```

### Custom Styling

Override via [custom CSS](/config/theme#custom-css):

```yaml
theme:
  custom:
    css: |
      /* Red banner for deprecated versions */
      :root {
        --version-banner-color: #dc2626;
        --version-banner-bg: color-mix(in srgb, #ef4444 10%, var(--color-bg));
      }

      /* Styled dropdown trigger */
      .version-dropdown-trigger {
        background: var(--color-primary);
        color: white;
        border-color: var(--color-primary);
      }
```

See [Theme Configuration — CSS Classes Reference](/config/theme#css-classes-reference) for the full list of versioning classes.

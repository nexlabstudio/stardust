---
title: Theme Configuration
description: Customize colors, fonts, and visual appearance of your documentation.
---

# Theme Configuration

Customize the look and feel of your documentation site with theme settings.

## Colors

### Primary Color

Set your brand's primary color:

```yaml
theme:
  colors:
    primary: "#6366f1"
```

The primary color is used for:
- Links
- Active navigation items
- Buttons
- Accent elements

### Additional Colors

```yaml
theme:
  colors:
    primary: "#6366f1"
    secondary: "#ec4899"
    accent: "#f59e0b"
```

### Background and Text Colors

Customize background and text colors for light and dark modes:

```yaml
theme:
  colors:
    background:
      light: "#ffffff"
      dark: "#0f172a"
    text:
      light: "#1e293b"
      dark: "#e2e8f0"
```

## Dark Mode

### Enable/Disable

Dark mode is enabled by default. To disable:

```yaml
theme:
  darkMode:
    enabled: false
```

### Default Mode

Set the default theme mode:

```yaml
theme:
  darkMode:
    enabled: true
    default: system  # Options: 'system', 'light', 'dark'
```

| Value | Behavior |
|-------|----------|
| `system` | Follow user's OS preference (default) |
| `light` | Start in light mode |
| `dark` | Start in dark mode |

Users can still toggle the theme unless you hide the toggle:

```yaml
header:
  showThemeToggle: false
```

## Fonts

### Sans-Serif and Monospace

```yaml
theme:
  fonts:
    sans: Inter
    mono: JetBrains Mono
```

Default fonts:
- **Sans-serif**: Inter
- **Monospace**: JetBrains Mono

### Google Fonts

Stardust automatically loads fonts from Google Fonts. Any Google Font name works:

```yaml
theme:
  fonts:
    sans: "Roboto"
    mono: "Fira Code"
```

### System Fonts

Use system font stacks for faster loading:

```yaml
theme:
  fonts:
    sans: "system-ui, -apple-system, sans-serif"
    mono: "ui-monospace, monospace"
```

## Border Radius

Control the roundness of UI elements:

```yaml
theme:
  radius: "8px"  # Default
```

| Value | Appearance |
|-------|------------|
| `0` | Sharp corners |
| `4px` | Slightly rounded |
| `8px` | Moderately rounded (default) |
| `12px` | More rounded |
| `9999px` | Fully rounded (pill shape) |

## Custom CSS

Add custom styles to your site inline or via a CSS file.

### Inline CSS

```yaml
theme:
  custom:
    css: |
      :root {
        --custom-variable: #ff0000;
      }

      .sidebar {
        border-right: 1px solid var(--border-color);
      }
```

### CSS File

Point to an external CSS file for larger customizations:

```yaml
theme:
  custom:
    cssFile: styles/custom.css
```

You can use both together — the file is loaded first, then inline CSS is appended:

```yaml
theme:
  custom:
    cssFile: styles/base.css
    css: |
      .header { border-bottom: 2px solid var(--color-primary); }
```

### CSS Variables

Stardust exposes CSS variables you can override:

```css
:root {
  /* Colors */
  --color-primary: #6366f1;
  --color-bg: #ffffff;
  --color-bg-secondary: #f8fafc;
  --color-text: #1e293b;
  --color-text-secondary: #64748b;
  --color-border: #e2e8f0;

  /* Fonts */
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;

  /* Spacing */
  --radius: 8px;
}
```

In dark mode (`.dark`), the color variables are automatically updated. You can target dark mode specifically:

```css
.dark {
  --color-bg: #0f172a;
  --color-bg-secondary: #1e293b;
  --color-text: #e2e8f0;
  --color-text-secondary: #94a3b8;
  --color-border: #334155;
}
```

### CSS Classes Reference

Use your browser's DevTools to inspect elements and discover classes. Here are the main targetable classes:

**Layout**

| Class | Element |
|-------|---------|
| `.header` | Top navigation bar |
| `.header-inner` | Header content container |
| `.logo` | Logo link |
| `.logo-text` | Site name text |
| `.nav` | Desktop navigation links |
| `.header-actions` | Search, theme toggle, social links area |
| `.sidebar` | Left sidebar navigation |
| `.content` | Main content area |
| `.toc` | Table of contents (right side) |
| `.footer` | Page footer |

**Sidebar**

| Class | Element |
|-------|---------|
| `.sidebar-group` | A sidebar section |
| `.sidebar-group-title` | Group heading (clickable when collapsible) |
| `.sidebar-group-label` | Group name text |
| `.sidebar-group-icon` | Icon next to group name |
| `.sidebar-links` | List of links in a group |
| `.sidebar-link` | Individual sidebar link |
| `.sidebar-link.active` | Currently active page link |

**Content**

| Class | Element |
|-------|---------|
| `.prose` | Markdown content wrapper |
| `.code-block` | Fenced code block container |
| `.code-header` | Code block header (language label + copy button) |
| `.copy-button` | Code copy button |

**Components**

| Class | Element |
|-------|---------|
| `.callout` | Callout/admonition blocks (Tip, Warning, etc.) |
| `.tabs` | Tab container |
| `.code-group` | Code group (tabbed code blocks) |
| `.accordion` | Accordion/details element |
| `.steps` | Step-by-step guide |
| `.cards` | Card grid container |
| `.card` | Individual card |
| `.tiles` | Tile grid container |
| `.panel` | Panel component |
| `.badge` | Badge component |
| `.tree` | File tree component |

**Navigation**

| Class | Element |
|-------|---------|
| `.page-nav` | Previous/next page links |
| `.page-nav-link` | Individual prev/next link |
| `.edit-link` | "Edit this page" link |
| `.search-button` | Search trigger button |
| `.theme-toggle` | Dark mode toggle button |

<Tip>
Your custom CSS is injected after all built-in styles, so your rules will naturally override defaults. Use browser DevTools (right-click → Inspect) to explore the full class hierarchy and test styles live.
</Tip>

## Code Themes

Configure syntax highlighting themes:

```yaml
code:
  theme:
    light: github-light
    dark: github-dark
```

Available themes include:
- `github-light`, `github-dark`
- `dracula`
- `nord`
- `one-dark-pro`
- `material-theme`
- `monokai`
- And many more...

See [Code Configuration](/config/overview#code-configuration) for more code-related settings.

## Logo

### Single Logo

```yaml
logo: /images/logo.svg
```

### Separate Light/Dark Logos

```yaml
logo:
  light: /images/logo-light.svg
  dark: /images/logo-dark.svg
```

<Tip>
Use SVG logos for best quality at all sizes. Place logo files in the `public/` directory.
</Tip>

## Complete Theme Example

```yaml
theme:
  colors:
    primary: "#3b82f6"
    secondary: "#8b5cf6"
    background:
      light: "#fafafa"
      dark: "#0a0a0a"
    text:
      light: "#171717"
      dark: "#fafafa"

  darkMode:
    enabled: true
    default: system

  fonts:
    sans: "Inter"
    mono: "Fira Code"

  radius: "8px"

  custom:
    cssFile: styles/custom.css
    css: |
      /* Add a gradient to the header */
      .header {
        background: linear-gradient(90deg, var(--color-primary), var(--color-secondary));
      }

code:
  theme:
    light: github-light
    dark: one-dark-pro
  lineNumbers: false
  copyButton: true
```

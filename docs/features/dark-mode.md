---
title: Dark Mode
description: Automatic dark mode with system preference detection.
---

# Dark Mode

Stardust includes beautiful dark mode that works automatically—respecting user preferences while allowing manual control.

## How It Works

By default, Stardust:

1. Detects the user's system preference (light/dark)
2. Automatically applies the matching theme
3. Provides a toggle for manual override
4. Remembers the user's choice

## Default Behavior

Out of the box, dark mode is enabled and follows system preferences:

```yaml
theme:
  darkMode:
    enabled: true
    default: system
```

| Default Value | Behavior |
|---------------|----------|
| `system` | Follow OS light/dark setting |
| `light` | Always start in light mode |
| `dark` | Always start in dark mode |

## Configuration

### Disable Dark Mode

Force light mode only:

```yaml
theme:
  darkMode:
    enabled: false
```

### Default to Dark

Start in dark mode but allow users to switch:

```yaml
theme:
  darkMode:
    enabled: true
    default: dark
```

### Hide the Toggle

Keep dark mode but remove the toggle button:

```yaml
header:
  showThemeToggle: false

theme:
  darkMode:
    enabled: true
    default: system  # Users can't override
```

## Theme Toggle

The theme toggle appears in the header by default. Users can:

- Click to cycle between light/dark
- The choice is saved in localStorage
- Persists across sessions and page reloads

## Custom Colors

Customize colors for both themes:

```yaml
theme:
  colors:
    primary: "#6366f1"
    background:
      light: "#ffffff"
      dark: "#0f172a"
    text:
      light: "#1e293b"
      dark: "#e2e8f0"
```

## Different Logos

Use different logos for each theme:

```yaml
logo:
  light: /images/logo-dark.svg    # Shown on light background
  dark: /images/logo-light.svg    # Shown on dark background
```

<Tip>
Name logos by what color they appear, not the background they're on. A dark logo shows on light backgrounds.
</Tip>

## Code Block Themes

Set different syntax highlighting for each mode:

```yaml
code:
  theme:
    light: github-light
    dark: github-dark
```

Popular theme combinations:

| Light Theme | Dark Theme |
|-------------|------------|
| `github-light` | `github-dark` |
| `one-light` | `one-dark-pro` |
| `solarized-light` | `solarized-dark` |

## CSS Customization

Target themes with CSS:

```yaml
theme:
  custom:
    css: |
      /* Light mode styles */
      :root {
        --custom-bg: #f0f0f0;
      }

      /* Dark mode styles */
      .dark {
        --custom-bg: #1a1a1a;
      }
```

## No Flash on Load

Stardust prevents the "flash of wrong theme" on page load by:

1. Reading the saved preference immediately
2. Applying the theme before content renders
3. Using inline critical CSS for theme colors

Users never see a flash of light mode when they prefer dark (or vice versa).

## Accessibility

Dark mode in Stardust maintains:

- Sufficient contrast ratios (WCAG AA)
- Readable text on all backgrounds
- Visible focus indicators
- Consistent visual hierarchy

## System Detection

Stardust uses the `prefers-color-scheme` media query:

```css
@media (prefers-color-scheme: dark) {
  /* User prefers dark mode */
}
```

This detects:
- macOS: System Preferences → Appearance
- Windows: Settings → Personalization → Colors
- iOS: Settings → Display & Brightness
- Android: Settings → Display → Dark theme

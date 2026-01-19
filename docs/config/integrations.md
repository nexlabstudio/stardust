---
title: Integrations
description: Connect analytics, comments, edit links, and other third-party services.
---

# Integrations

Stardust integrates with popular services for analytics, comments, and more.

## Edit on GitHub

Let users suggest edits to your documentation:

```yaml
integrations:
  editLink:
    enabled: true
    repo: https://github.com/myorg/myproject
    branch: main
    path: docs/
    text: Edit this page on GitHub
```

This adds an "Edit this page" link to every documentation page.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable edit links |
| `repo` | string | required | Repository URL |
| `branch` | string | `main` | Branch name |
| `path` | string | `docs/` | Path to docs in repo |
| `text` | string | `Edit this page on GitHub` | Link text |

### GitLab or Other Hosts

```yaml
integrations:
  editLink:
    enabled: true
    repo: https://gitlab.com/myorg/myproject
    text: Edit on GitLab
```

## Last Updated

Show when pages were last modified:

```yaml
integrations:
  lastUpdated:
    enabled: true
    format: "MMM d, yyyy"
    text: "Last updated"
```

This reads the last git commit date for each file.

### Date Formats

| Format | Example |
|--------|---------|
| `MMM d, yyyy` | Jan 15, 2024 |
| `MMMM d, yyyy` | January 15, 2024 |
| `yyyy-MM-dd` | 2024-01-15 |
| `d MMM yyyy` | 15 Jan 2024 |

## Analytics

### Google Analytics

```yaml
integrations:
  analytics:
    google: G-XXXXXXXXXX
```

### Plausible Analytics

Privacy-friendly analytics:

```yaml
integrations:
  analytics:
    plausible: myproject.com
```

### PostHog

```yaml
integrations:
  analytics:
    posthog:
      key: phc_xxxxxxxxxxxxx
      host: https://app.posthog.com  # or your self-hosted instance
```

### Multiple Analytics

You can enable multiple analytics providers:

```yaml
integrations:
  analytics:
    google: G-XXXXXXXXXX
    plausible: myproject.com
```

## Comments

Add discussions to your documentation pages.

### Giscus (GitHub Discussions)

```yaml
integrations:
  comments:
    provider: giscus
    giscus:
      repo: myorg/myproject
      repoId: R_xxxxxxxxxx
      category: Documentation
      categoryId: DIC_xxxxxxxxxx
```

To get your Giscus configuration:
1. Go to [giscus.app](https://giscus.app/)
2. Enter your repository
3. Copy the configuration values

### Disqus

```yaml
integrations:
  comments:
    provider: disqus
    disqus:
      shortname: my-project-docs
```

### Disabling Comments Per-Page

```markdown
---
title: FAQ
comments: false
---
```

## Social Links

Add social media links to your header:

```yaml
social:
  github: https://github.com/myorg/myproject
  twitter: https://twitter.com/myproject
  discord: https://discord.gg/myproject
  youtube: https://youtube.com/@myproject
  linkedin: https://linkedin.com/company/myproject
  mastodon: https://mastodon.social/@myproject
  slack: https://myproject.slack.com
  pubdev: https://pub.dev/publishers/myproject.com
```

Only add the platforms you use—empty values are ignored.

## LLM-Friendly Output

Generate a consolidated file for AI/LLM consumption:

```yaml
build:
  llms:
    enabled: true
```

This creates `/llms.txt` containing all your documentation in a format optimized for language models.

## Custom Integrations

### Custom Head Tags

Add custom tags to the `<head>`:

```yaml
theme:
  custom:
    head: |
      <script src="https://example.com/widget.js"></script>
      <link rel="preconnect" href="https://fonts.gstatic.com">
```

### Custom Scripts

Add scripts before the closing `</body>`:

```yaml
theme:
  custom:
    scripts: |
      <script>
        console.log('Custom script loaded');
      </script>
```

## Complete Integration Example

```yaml
integrations:
  editLink:
    enabled: true
    repo: https://github.com/myorg/myproject
    branch: main
    path: docs/

  lastUpdated:
    enabled: true
    format: "MMM d, yyyy"

  analytics:
    google: G-XXXXXXXXXX
    plausible: myproject.com

  comments:
    provider: giscus
    giscus:
      repo: myorg/myproject
      repoId: R_xxxxxxxxxx
      category: Documentation
      categoryId: DIC_xxxxxxxxxx

social:
  github: https://github.com/myorg/myproject
  twitter: https://twitter.com/myproject
  discord: https://discord.gg/myproject

build:
  llms:
    enabled: true
```

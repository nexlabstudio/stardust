---
title: Other Components
description: Badges, icons, tooltips, embeds, and utility components.
---

# Other Components

Additional components for badges, tooltips, code playgrounds, and more.

## Badge

Inline badges for labels, status indicators, and tags:

<Badge>Default</Badge>
<Badge variant="success">Success</Badge>
<Badge variant="warning">Warning</Badge>
<Badge variant="danger">Danger</Badge>

```markdown
<Badge>Default</Badge>
<Badge variant="success">Success</Badge>
<Badge variant="warning">Warning</Badge>
<Badge variant="danger">Danger</Badge>
```

### Badge Sizes

<Badge size="sm">Small</Badge>
<Badge size="md">Medium</Badge>
<Badge size="lg">Large</Badge>

```markdown
<Badge size="sm">Small</Badge>
<Badge size="md">Medium</Badge>
<Badge size="lg">Large</Badge>
```

### Badge with Icon

<Badge icon="star">Featured</Badge>
<Badge icon="🚀" variant="success">New</Badge>

```markdown
<Badge icon="star">Featured</Badge>
<Badge icon="🚀" variant="success">New</Badge>
```

## Icon

Display icons inline with text:

<Icon name="star" /> Star icon
<Icon name="check" color="green" /> Checkmark
<Icon name="warning" size="24" /> Warning

```markdown
<Icon name="star" /> Star icon
<Icon name="check" color="green" /> Checkmark
<Icon name="warning" size="24" /> Warning
```

### Available Icons

Common icon names: `star`, `heart`, `check`, `x`, `info`, `warning`, `settings`, `search`, `home`, `user`, `code`, `terminal`, `file`, `folder`, `download`, `upload`, `link`, `external-link`, `github`, `twitter`, `discord`, `rocket`, `zap`, `book`, `copy`, `menu`, `close`, `arrow-right`, `arrow-left`, `mail`

You can also use emoji: <Icon name="🎯" /> <Icon name="✨" /> <Icon name="📚" />

## Tooltip

Add hover tooltips to any content:

Hover over <Tooltip content="This is a tooltip!">this text</Tooltip> to see the tooltip.

```markdown
Hover over <Tooltip content="This is a tooltip!">this text</Tooltip> to see the tooltip.
```

### Tooltip Positions

<Tooltip content="Top tooltip" position="top">Top</Tooltip> |
<Tooltip content="Bottom tooltip" position="bottom">Bottom</Tooltip> |
<Tooltip content="Left tooltip" position="left">Left</Tooltip> |
<Tooltip content="Right tooltip" position="right">Right</Tooltip>

```markdown
<Tooltip content="Appears on top" position="top">Top</Tooltip>
<Tooltip content="Appears below" position="bottom">Bottom</Tooltip>
```

## Update

Highlight version updates and announcements:

<Update version="2.0.0" date="2024-01-15">
  Major release with OpenAPI import, new components, and performance improvements.
</Update>

```markdown
<Update version="2.0.0" date="2024-01-15">
  Major release with OpenAPI import, new components, and performance improvements.
</Update>
```

### Update Types

<Update label="New Feature" version="2.1.0">
  Added support for Mermaid diagrams.
</Update>

<Update label="Bug Fix" version="2.0.1">
  Fixed sidebar navigation on mobile devices.
</Update>

## Code Playgrounds

### Zapp (Dart/Flutter)

Embed interactive Dart and Flutter playgrounds:

```markdown
<Zapp id="flutter_counter" />
```

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | string | required | Zapp project ID |
| `theme` | string | `"dark"` | `"dark"` or `"light"` |
| `lazy` | boolean | `true` | Lazy load the embed |
| `height` | string | `"500px"` | Container height |

### CodePen

Embed CodePen examples:

```markdown
<CodePen id="abc123" user="username" />
```

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | string | required | Pen ID |
| `user` | string | required | CodePen username |
| `title` | string | `"CodePen"` | Embed title |
| `height` | string | `"400"` | Height in pixels |
| `defaultTab` | string | `"result"` | `"result"`, `"html"`, `"css"`, `"js"` |
| `theme` | string | `"dark"` | Theme ID |
| `editable` | boolean | `false` | Allow editing |

### StackBlitz

Embed StackBlitz projects:

```markdown
<StackBlitz id="my-project" />
```

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | string | required | Project ID |
| `title` | string | `"StackBlitz"` | Embed title |
| `height` | string | `"500px"` | Container height |
| `file` | string | - | File to open |
| `hideNavigation` | boolean | `false` | Hide nav bar |
| `hideDevTools` | boolean | `false` | Hide dev tools |
| `view` | string | `"preview"` | `"preview"` or `"editor"` |

## Attributes Reference

### Badge

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `variant` | string | `"default"` | Visual style |
| `size` | string | `"md"` | `"sm"`, `"md"`, `"lg"` |
| `icon` | string | - | Icon name or emoji |

### Icon

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | required | Icon name or emoji |
| `size` | string | `"20"` | Size in pixels |
| `color` | string | - | CSS color value |

### Tooltip

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `content` | string | required | Tooltip text |
| `position` | string | `"top"` | `"top"`, `"bottom"`, `"left"`, `"right"` |

### Update

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `label` | string | `"Update"` | Update label |
| `version` | string | - | Version number |
| `date` | string | - | Release date |
| `type` | string | `"default"` | Visual style |

## When to Use

| Component | Use Case |
|-----------|----------|
| Badge | Status indicators, labels, tags, version numbers |
| Icon | Inline icons, visual cues, decoration |
| Tooltip | Additional context, definitions, hints |
| Update | Changelog entries, version announcements |
| Zapp/CodePen/StackBlitz | Interactive code examples |

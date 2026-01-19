---
title: Layout Components
description: Organize content with columns, panels, and device frames.
---

# Layout Components

Layout components help you structure content beyond simple linear flow.

## Columns

Create multi-column layouts for side-by-side content:

<Columns>
  <Column>
    **Left Column**

    This content appears on the left side.
  </Column>
  <Column>
    **Right Column**

    This content appears on the right side.
  </Column>
</Columns>

```markdown
<Columns>
  <Column>
    **Left Column**

    This content appears on the left side.
  </Column>
  <Column>
    **Right Column**

    This content appears on the right side.
  </Column>
</Columns>
```

### Three Columns

<Columns>
  <Column>
    **First**

    Column one content.
  </Column>
  <Column>
    **Second**

    Column two content.
  </Column>
  <Column>
    **Third**

    Column three content.
  </Column>
</Columns>

### Custom Column Widths

Use the `width` attribute for custom proportions:

<Columns>
  <Column width="30%">
    **Sidebar**

    Narrower column.
  </Column>
  <Column width="70%">
    **Main Content**

    Wider column takes more space.
  </Column>
</Columns>

```markdown
<Columns>
  <Column width="30%">
    **Sidebar**

    Narrower column.
  </Column>
  <Column width="70%">
    **Main Content**

    Wider column takes more space.
  </Column>
</Columns>
```

### Custom Gap

Adjust spacing between columns:

<Columns gap="2rem">
  <Column>Column A</Column>
  <Column>Column B</Column>
</Columns>

```markdown
<Columns gap="2rem">
  <Column>Column A</Column>
  <Column>Column B</Column>
</Columns>
```

## Panel

Create bordered sections with optional titles:

<Panel title="Configuration" icon="settings">
  Configure your project by editing `stardust.yaml` in the project root.
</Panel>

```markdown
<Panel title="Configuration" icon="settings">
  Configure your project by editing `stardust.yaml` in the project root.
</Panel>
```

### Panel Without Title

<Panel>
  A simple bordered panel without a header.
</Panel>

### Panel with Code

<Panel title="Example Code" icon="code">
  ```dart
  void main() {
    print('Hello, Stardust!');
  }
  ```
</Panel>

## Frame

Display content in browser or device mockups:

### Browser Frame

<Frame type="browser" url="https://example.com">
  <div style="padding: 2rem; text-align: center;">
    Your website preview appears here.
  </div>
</Frame>

```markdown
<Frame type="browser" url="https://example.com">
  Your website preview appears here.
</Frame>
```

### Phone Frame

<Frame type="phone">
  <div style="padding: 1rem; text-align: center;">
    Mobile app preview
  </div>
</Frame>

```markdown
<Frame type="phone">
  Mobile app preview
</Frame>
```

## Attributes Reference

### Columns

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `gap` | string | `"1rem"` | Space between columns |

### Column

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `width` | string | auto | CSS width (e.g., `"50%"`, `"300px"`) |

### Panel

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | string | - | Optional panel title |
| `icon` | string | - | Emoji or icon name |
| `variant` | string | `"default"` | Visual style variant |

### Frame

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `type` | string | `"browser"` | `"browser"` or `"phone"`/`"mobile"` |
| `url` | string | - | URL to display in browser address bar |
| `device` | string | `"iphone"` | Device type for phone frame |

## Use Cases

| Component | Best For |
|-----------|----------|
| Columns | Comparing options, showing before/after, sidebar layouts |
| Panel | Highlighting important sections, grouping related content |
| Frame | Showcasing websites, app screenshots, UI previews |

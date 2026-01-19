---
title: Media Components
description: Embed images, videos, diagrams, and file trees in your documentation.
---

# Media Components

Display rich media content including images, videos, diagrams, and file structures.

## Image

Enhanced images with captions, zoom, and styling options:

<Image
  src="/images/example.png"
  alt="Example screenshot"
  caption="An example image with caption"
  rounded
/>

```markdown
<Image
  src="/images/example.png"
  alt="Example screenshot"
  caption="An example image with caption"
  rounded
/>
```

### Image with Zoom

Enable click-to-zoom for detailed images:

```markdown
<Image
  src="/images/diagram.png"
  alt="Architecture diagram"
  zoom
/>
```

### Styled Images

```markdown
<!-- Rounded corners -->
<Image src="/images/photo.jpg" alt="Photo" rounded />

<!-- With border -->
<Image src="/images/screenshot.png" alt="Screenshot" border />

<!-- Custom size -->
<Image src="/images/logo.png" alt="Logo" width="200px" />
```

## Video

Embed native HTML5 videos:

```markdown
<Video
  src="/videos/demo.mp4"
  poster="/images/video-poster.jpg"
  controls
/>
```

### Autoplay Video

```markdown
<Video
  src="/videos/background.mp4"
  autoplay
  loop
  muted
/>
```

## YouTube

Embed YouTube videos:

<YouTube id="dQw4w9WgXcQ" />

```markdown
<YouTube id="dQw4w9WgXcQ" />
```

### With Start Time

```markdown
<YouTube id="dQw4w9WgXcQ" start="60" />
```

### Custom Aspect Ratio

```markdown
<YouTube id="dQw4w9WgXcQ" aspectRatio="4/3" />
```

## Vimeo

Embed Vimeo videos:

```markdown
<Vimeo id="148751763" />
```

## Mermaid Diagrams

Create diagrams using Mermaid syntax:

<Mermaid>
graph LR
    A[Write Markdown] --> B[Run Stardust]
    B --> C[Beautiful Docs]
</Mermaid>

````markdown
<Mermaid>
graph LR
    A[Write Markdown] --> B[Run Stardust]
    B --> C[Beautiful Docs]
</Mermaid>
````

### Flowchart

<Mermaid caption="User Registration Flow">
flowchart TD
    A[User visits site] --> B{Has account?}
    B -->|Yes| C[Login]
    B -->|No| D[Register]
    D --> E[Verify email]
    E --> C
    C --> F[Dashboard]
</Mermaid>

### Sequence Diagram

<Mermaid>
sequenceDiagram
    participant User
    participant API
    participant Database

    User->>API: POST /users
    API->>Database: INSERT user
    Database-->>API: User created
    API-->>User: 201 Created
</Mermaid>

### Class Diagram

<Mermaid>
classDiagram
    class Document {
        +String title
        +String content
        +render()
    }
    class Page {
        +String slug
        +Frontmatter meta
    }
    Document <|-- Page
</Mermaid>

## Tree

Display file and folder structures:

<Tree>
  <Folder name="my-docs" open>
    <Folder name="docs" open>
      <File name="index.md" />
      <File name="guide.md" />
      <Folder name="api">
        <File name="overview.md" />
        <File name="endpoints.md" />
      </Folder>
    </Folder>
    <Folder name="public">
      <File name="logo.png" />
    </Folder>
    <File name="stardust.yaml" />
  </Folder>
</Tree>

```markdown
<Tree>
  <Folder name="my-docs" open>
    <Folder name="docs" open>
      <File name="index.md" />
      <File name="guide.md" />
      <Folder name="api">
        <File name="overview.md" />
        <File name="endpoints.md" />
      </Folder>
    </Folder>
    <Folder name="public">
      <File name="logo.png" />
    </Folder>
    <File name="stardust.yaml" />
  </Folder>
</Tree>
```

### With Custom Icons

```markdown
<Tree>
  <Folder name="src" open>
    <File name="main.dart" icon="🎯" />
    <File name="config.json" icon="⚙️" />
    <File name="README.md" icon="📖" />
  </Folder>
</Tree>
```

## Attributes Reference

### Image

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `src` | string | required | Image URL or path |
| `alt` | string | required | Alt text for accessibility |
| `caption` | string | - | Caption below image |
| `width` | string | - | CSS width |
| `height` | string | - | CSS height |
| `zoom` | boolean | `false` | Enable click-to-zoom |
| `rounded` | boolean | `false` | Rounded corners |
| `border` | boolean | `false` | Add border |

### Video

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `src` | string | required | Video URL or path |
| `poster` | string | - | Poster image URL |
| `autoplay` | boolean | `false` | Auto-play video |
| `loop` | boolean | `false` | Loop playback |
| `muted` | boolean | `false` | Mute audio |
| `controls` | boolean | `true` | Show playback controls |

### YouTube

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | string | required | Video ID or full URL |
| `title` | string | `"YouTube video"` | Accessible title |
| `start` | number | - | Start time in seconds |
| `aspectRatio` | string | `"16/9"` | Video aspect ratio |

### Vimeo

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | string | required | Video ID or full URL |
| `title` | string | `"Vimeo video"` | Accessible title |
| `aspectRatio` | string | `"16/9"` | Video aspect ratio |

### Mermaid

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `caption` | string | - | Diagram caption |
| `theme` | string | `"default"` | Mermaid theme |

### Tree/Folder/File

| Component | Attribute | Type | Description |
|-----------|-----------|------|-------------|
| Folder | `name` | string | Folder name |
| Folder | `open` | boolean | Expanded state |
| File | `name` | string | File name |
| File | `icon` | string | Optional emoji or icon |

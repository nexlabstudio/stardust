---
title: Markdown
description: Write documentation using standard Markdown with Stardust extensions.
---

# Markdown

Stardust uses standard Markdown with some powerful extensions. If you're familiar with GitHub-flavored Markdown, you'll feel right at home.

## Basic Syntax

### Headings

```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
```

<Warning>
Only use one `# Heading 1` per page — this becomes the page title.
</Warning>

### Text Formatting

```markdown
**Bold text**
*Italic text*
~~Strikethrough~~
`Inline code`
```

### Links

```markdown
[External link](https://example.com)
[Internal link](/getting-started)
[Link with title](https://example.com "Title text")
```

### Images

```markdown
![Alt text](/images/screenshot.png)
![Alt text](/images/screenshot.png "Optional title")
```

<Tip>
Place images in the `public/` directory and reference them with absolute paths like `/images/screenshot.png`.
</Tip>

### Lists

**Unordered lists:**

```markdown
- Item one
- Item two
  - Nested item
  - Another nested item
- Item three
```

**Ordered lists:**

```markdown
1. First item
2. Second item
3. Third item
```

### Blockquotes

```markdown
> This is a blockquote.
> It can span multiple lines.
```

> This is a blockquote.
> It can span multiple lines.

## Code Blocks

### Fenced Code Blocks

Use triple backticks with an optional language identifier:

````markdown
```dart
void main() {
  print('Hello, Stardust!');
}
```
````

Renders as:

```dart
void main() {
  print('Hello, Stardust!');
}
```

### Supported Languages

Stardust supports syntax highlighting for 100+ languages including:

<Columns>
  <Column>
    - Dart
    - JavaScript/TypeScript
    - Python
    - Go
    - Rust
    - Java
    - C/C++
  </Column>
  <Column>
    - Ruby
    - PHP
    - Swift
    - Kotlin
    - SQL
    - YAML/JSON
    - Bash/Shell
  </Column>
</Columns>

### Code Block Titles

Add a title to code blocks using the `title` attribute:

````markdown
```dart title="main.dart"
void main() => runApp(MyApp());
```
````

## Tables

```markdown
| Feature | Stardust | Others |
|---------|----------|--------|
| Zero config | ✅ | ❌ |
| Dart-native | ✅ | ❌ |
| Fast builds | ✅ | ⚠️ |
```

Renders as:

| Feature | Stardust | Others |
|---------|----------|--------|
| Zero config | ✅ | ❌ |
| Dart-native | ✅ | ❌ |
| Fast builds | ✅ | ⚠️ |

### Table Alignment

```markdown
| Left | Center | Right |
|:-----|:------:|------:|
| L    | C      | R     |
```

## Horizontal Rules

```markdown
---
```

---

## JSX-Style Components

Stardust extends Markdown with JSX-style components:

```markdown
<Info>
This is an informational callout.
</Info>

<Tabs>
  <Tab name="JavaScript">console.log('Hello')</Tab>
  <Tab name="Python">print('Hello')</Tab>
</Tabs>
```

<Info>
Components must be on their own lines with blank lines before and after.
</Info>

See the [Components](/components/callouts) section for the full component library.

## HTML in Markdown

You can use raw HTML when needed:

```markdown
<div style="text-align: center">
  Centered content
</div>
```

<Warning>
Avoid inline styles when possible. Use Stardust's built-in components for consistent styling.
</Warning>

## Escaping

Use backslashes to escape special characters:

```markdown
\*Not italic\*
\`Not code\`
\# Not a heading
```

## Next Steps

<Cards>
  <Card title="Frontmatter" icon="file" href="/frontmatter">
    Learn about page metadata with frontmatter.
  </Card>
  <Card title="Components" icon="code" href="/components/callouts">
    Explore the built-in component library.
  </Card>
</Cards>

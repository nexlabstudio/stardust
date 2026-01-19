---
title: Accordion
description: Organize content into collapsible sections to reduce page clutter.
---

# Accordion

Accordions let you hide content until the user wants to see it, perfect for FAQs, optional details, or long reference content.

## Single Accordion

<Accordion title="What is Stardust?">
Stardust is a Dart-native documentation framework that generates beautiful, static documentation sites with zero configuration required.
</Accordion>

```markdown
<Accordion title="What is Stardust?">
Stardust is a Dart-native documentation framework that generates beautiful, static documentation sites with zero configuration required.
</Accordion>
```

## Accordion Group

Group related accordions together:

<AccordionGroup>
  <Accordion title="How do I install Stardust?">
    Install using Homebrew on macOS:

    ```bash
    brew tap nexlabstudio/tap
    brew install stardust
    ```

    Or use the curl installer on any platform.
  </Accordion>
  <Accordion title="What languages are supported?">
    Stardust supports syntax highlighting for 100+ programming languages including Dart, JavaScript, Python, Go, Rust, and many more.
  </Accordion>
  <Accordion title="Can I use custom themes?">
    Yes! You can customize colors, fonts, and more in your `stardust.yaml` configuration file.
  </Accordion>
</AccordionGroup>

```markdown
<AccordionGroup>
  <Accordion title="How do I install Stardust?">
    Install using Homebrew on macOS:

    \`\`\`bash
    brew tap nexlabstudio/tap
    brew install stardust
    \`\`\`
  </Accordion>
  <Accordion title="What languages are supported?">
    Stardust supports syntax highlighting for 100+ programming languages.
  </Accordion>
  <Accordion title="Can I use custom themes?">
    Yes! Customize in your `stardust.yaml` configuration file.
  </Accordion>
</AccordionGroup>
```

## Default Open

Use the `open` attribute to expand an accordion by default:

<Accordion title="This accordion is open by default" open>
Users will see this content immediately without needing to click.
</Accordion>

```markdown
<Accordion title="This accordion is open by default" open>
Users will see this content immediately without needing to click.
</Accordion>
```

## Rich Content

Accordions support full Markdown including code blocks, lists, and other components:

<Accordion title="Example with rich content">
### Subheading

You can include:

- **Bold text** and *italic text*
- `Inline code` snippets
- Links to [other pages](/installation)

And code blocks:

```dart
void main() {
  print('Hello from inside an accordion!');
}
```

<Info>
Even nested components work inside accordions!
</Info>
</Accordion>

## FAQ Example

A typical FAQ section using accordions:

<AccordionGroup>
  <Accordion title="Is Stardust free?">
    Yes! Stardust is free and open source under the Apache 2.0 license.
  </Accordion>
  <Accordion title="Do I need to know Dart?">
    No. Stardust is written in Dart, but you write your documentation in Markdown. No Dart knowledge required.
  </Accordion>
  <Accordion title="Can I deploy anywhere?">
    Yes. Stardust generates a static site that can be deployed to GitHub Pages, Vercel, Netlify, Cloudflare Pages, or any static hosting provider.
  </Accordion>
  <Accordion title="How do I get help?">
    - Check the [documentation](/)
    - Open an issue on [GitHub](https://github.com/nexlabstudio/stardust/issues)
    - Join our community discussions
  </Accordion>
</AccordionGroup>

## Use Cases

| Use Case | Example |
|----------|---------|
| FAQs | Frequently asked questions |
| Reference docs | API parameters, options |
| Troubleshooting | Common problems and solutions |
| Changelog | Version history with details |
| Optional info | "Learn more" sections |

## Best Practices

<Tip>
- Use clear, descriptive titles that indicate what's inside
- Keep accordion content focused on a single topic
- Use `AccordionGroup` for related questions
- Consider using `open` for the most important item
</Tip>

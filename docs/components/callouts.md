---
title: Callouts
description: Draw attention to important information with callout components.
---

# Callouts

Callouts highlight important information, warnings, tips, and other notices.

## Basic Callouts

Stardust provides six callout types:

### Info

<Info>
This is an informational callout for general information.
</Info>

```markdown
<Info>
This is an informational callout for general information.
</Info>
```

### Tip

<Tip>
This is a tip callout for helpful suggestions.
</Tip>

```markdown
<Tip>
This is a tip callout for helpful suggestions.
</Tip>
```

### Note

<Note>
This is a note callout for side notes and additional context.
</Note>

```markdown
<Note>
This is a note callout for side notes and additional context.
</Note>
```

### Warning

<Warning>
This is a warning callout for important cautions.
</Warning>

```markdown
<Warning>
This is a warning callout for important cautions.
</Warning>
```

### Danger

<Danger>
This is a danger callout for critical warnings and errors.
</Danger>

```markdown
<Danger>
This is a danger callout for critical warnings and errors.
</Danger>
```

### Success

<Success>
This is a success callout for positive confirmations.
</Success>

```markdown
<Success>
This is a success callout for positive confirmations.
</Success>
```

## Custom Titles

Override the default title with the `title` attribute:

<Info title="Did you know?">
You can customize the title of any callout using the `title` attribute.
</Info>

```markdown
<Info title="Did you know?">
You can customize the title of any callout using the `title` attribute.
</Info>
```

<Warning title="Breaking Change">
The API signature has changed in version 2.0.
</Warning>

```markdown
<Warning title="Breaking Change">
The API signature has changed in version 2.0.
</Warning>
```

## Markdown Inside Callouts

Callouts support full Markdown syntax:

<Info title="Formatting Support">
You can use **bold**, *italic*, `code`, and even:

- Lists
- With multiple items

And [links](https://example.com) too!
</Info>

```markdown
<Info title="Formatting Support">
You can use **bold**, *italic*, `code`, and even:

- Lists
- With multiple items

And [links](https://example.com) too!
</Info>
```

## Code Blocks in Callouts

<Tip title="Pro Tip">
You can include code blocks inside callouts:

```dart
final result = await api.fetch();
print(result);
```
</Tip>

```markdown
<Tip title="Pro Tip">
You can include code blocks inside callouts:

\`\`\`dart
final result = await api.fetch();
print(result);
\`\`\`
</Tip>
```

## When to Use Each Type

| Type | Use For |
|------|---------|
| `<Info>` | General information, facts, explanations |
| `<Tip>` | Helpful suggestions, best practices, shortcuts |
| `<Note>` | Side notes, additional context, clarifications |
| `<Warning>` | Important cautions, potential issues, deprecations |
| `<Danger>` | Critical warnings, destructive actions, security concerns |
| `<Success>` | Confirmations, completed steps, positive outcomes |

## Best Practices

<Accordion title="Keep callouts concise">
Callouts work best when they're brief and scannable. If you have a lot of content, consider using regular prose or breaking it into multiple callouts.
</Accordion>

<Accordion title="Don't overuse callouts">
If everything is highlighted, nothing stands out. Reserve callouts for genuinely important information.
</Accordion>

<Accordion title="Choose the right type">
Use `<Danger>` sparingly — only for truly critical information. Overusing it diminishes its impact.
</Accordion>

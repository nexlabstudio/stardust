---
title: Tabs
description: Organize content into switchable tabs for cleaner presentation.
---

# Tabs

Tabs let you organize related content into switchable panels, perfect for showing alternatives like different programming languages or platforms.

## Basic Tabs

<Tabs>
  <Tab name="JavaScript">
    ```javascript
    console.log('Hello, world!');
    ```
  </Tab>
  <Tab name="Python">
    ```python
    print('Hello, world!')
    ```
  </Tab>
  <Tab name="Dart">
    ```dart
    print('Hello, world!');
    ```
  </Tab>
</Tabs>

````markdown
<Tabs>
  <Tab name="JavaScript">
    ```javascript
    console.log('Hello, world!');
    ```
  </Tab>
  <Tab name="Python">
    ```python
    print('Hello, world!')
    ```
  </Tab>
  <Tab name="Dart">
    ```dart
    print('Hello, world!');
    ```
  </Tab>
</Tabs>
````

## Tabs with Rich Content

Tabs can contain any Markdown content, not just code:

<Tabs>
  <Tab name="macOS">
    ### Installing on macOS

    Use Homebrew for the easiest installation:

    ```bash
    brew install stardust
    ```

    Or download the binary directly from the releases page.
  </Tab>
  <Tab name="Linux">
    ### Installing on Linux

    Use the install script:

    ```bash
    curl -sSL https://example.com/install.sh | bash
    ```

    Supports x64 and ARM64 architectures.
  </Tab>
  <Tab name="Windows">
    ### Installing on Windows

    Use Scoop:

    ```powershell
    scoop install stardust
    ```

    Or download the `.zip` from the releases page.
  </Tab>
</Tabs>

## Package Manager Examples

A common use case — showing installation commands for different package managers:

<Tabs>
  <Tab name="npm">
    ```bash
    npm install my-package
    ```
  </Tab>
  <Tab name="yarn">
    ```bash
    yarn add my-package
    ```
  </Tab>
  <Tab name="pnpm">
    ```bash
    pnpm add my-package
    ```
  </Tab>
  <Tab name="bun">
    ```bash
    bun add my-package
    ```
  </Tab>
</Tabs>

````markdown
<Tabs>
  <Tab name="npm">
    ```bash
    npm install my-package
    ```
  </Tab>
  <Tab name="yarn">
    ```bash
    yarn add my-package
    ```
  </Tab>
  <Tab name="pnpm">
    ```bash
    pnpm add my-package
    ```
  </Tab>
  <Tab name="bun">
    ```bash
    bun add my-package
    ```
  </Tab>
</Tabs>
````

## Framework Comparison

<Tabs>
  <Tab name="React">
    ```jsx
    function App() {
      return <h1>Hello, React!</h1>;
    }
    ```
  </Tab>
  <Tab name="Vue">
    ```vue
    <template>
      <h1>Hello, Vue!</h1>
    </template>
    ```
  </Tab>
  <Tab name="Svelte">
    ```svelte
    <h1>Hello, Svelte!</h1>
    ```
  </Tab>
</Tabs>

## Best Practices

<Info>
- Use tabs when showing equivalent alternatives (languages, platforms, methods)
- Keep tab names short and descriptive
- Ensure each tab has similar content structure
- Don't nest tabs inside tabs
</Info>

## Persistent Tab Selection

Tab selections are remembered within the page. When a user selects "Python" in one tab group, other tab groups with a "Python" option will also switch.

<Tabs>
  <Tab name="Python">
    Variable declaration in Python:
    ```python
    name = "Stardust"
    ```
  </Tab>
  <Tab name="JavaScript">
    Variable declaration in JavaScript:
    ```javascript
    const name = "Stardust";
    ```
  </Tab>
</Tabs>

<Tabs>
  <Tab name="Python">
    Function definition in Python:
    ```python
    def greet(name):
        return f"Hello, {name}!"
    ```
  </Tab>
  <Tab name="JavaScript">
    Function definition in JavaScript:
    ```javascript
    function greet(name) {
      return `Hello, ${name}!`;
    }
    ```
  </Tab>
</Tabs>

Select a language above and watch both tab groups sync!

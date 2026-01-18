import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Initialize a new Stardust documentation project
class InitCommand extends Command<int> {
  @override
  final name = 'init';

  @override
  final description = 'Initialize a new Stardust documentation project';

  InitCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Project name',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Overwrite existing files',
    );
  }

  @override
  Future<int> run() async {
    final args = argResults;
    if (args == null) return 1;

    final targetDir = args.rest.isNotEmpty ? args.rest.first : Directory.current.path;
    final projectName = args['name'] as String? ?? p.basename(targetDir);
    final force = args['force'] as bool;

    print('✨ Creating Stardust project: $projectName');
    print('   Location: $targetDir');
    print('');

    await _createProject(targetDir, projectName, force);

    print('');
    print('🚀 Project created successfully!');
    print('');
    print('Next steps:');
    print('  cd ${p.relative(targetDir)}');
    print('  stardust dev');
    print('');

    return 0;
  }

  Future<void> _createProject(
      String targetDir, String projectName, bool force) async {
    final dir = Directory(targetDir);

    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    // Create docs.yaml
    await _createFile(
      p.join(targetDir, 'docs.yaml'),
      _docsYamlTemplate(projectName),
      force,
      'docs.yaml',
    );

    // Create docs directory
    final docsDir = Directory(p.join(targetDir, 'docs'));
    if (!docsDir.existsSync()) {
      await docsDir.create(recursive: true);
    }

    // Create index.md
    await _createFile(
      p.join(targetDir, 'docs', 'index.md'),
      _indexMdTemplate(projectName),
      force,
      'docs/index.md',
    );

    // Create getting-started.md
    await _createFile(
      p.join(targetDir, 'docs', 'getting-started.md'),
      _gettingStartedTemplate(),
      force,
      'docs/getting-started.md',
    );

    // Create public directory
    final publicDir = Directory(p.join(targetDir, 'public'));
    if (!publicDir.existsSync()) {
      await publicDir.create(recursive: true);
    }

    // Create .gitignore
    await _createFile(
      p.join(targetDir, '.gitignore'),
      _gitignoreTemplate(),
      force,
      '.gitignore',
    );
  }

  Future<void> _createFile(
      String path, String content, bool force, String displayName) async {
    final file = File(path);

    if (file.existsSync() && !force) {
      print('  ⏭️  Skipping $displayName (already exists)');
      return;
    }

    await file.writeAsString(content);
    print('  ✅ Created $displayName');
  }

  String _docsYamlTemplate(String projectName) => '''
# Stardust Documentation Configuration
# Full reference: https://stardust.dev/docs/configuration

name: $projectName
description: Documentation for $projectName

# Content settings
content:
  dir: docs/

# Navigation
nav:
  - label: Guide
    href: /
  - label: GitHub
    href: https://github.com/your-org/$projectName
    external: true

# Sidebar
sidebar:
  - group: Getting Started
    pages:
      - index
      - getting-started

# Theme
theme:
  colors:
    primary: "#6366f1"
  darkMode:
    enabled: true
    default: system

# Code blocks
code:
  theme:
    light: github-light
    dark: github-dark
  copyButton: true

# Search
search:
  enabled: true
  provider: pagefind
''';

  String _indexMdTemplate(String projectName) => '''
---
title: Introduction
description: Welcome to $projectName documentation
---

# Welcome to $projectName

This is your documentation home page. Edit this file at `docs/index.md`.

## Features

<Info>
Stardust makes it easy to create beautiful documentation with zero configuration.
</Info>

- 📝 **Markdown-based** — Write docs in Markdown with powerful extensions
- 🎨 **Beautiful by default** — Clean, modern design out of the box
- 🌙 **Dark mode** — Automatic dark mode support
- 🔍 **Full-text search** — Fast, client-side search with Pagefind
- ⚡ **Fast** — Static site generation for instant page loads

## Quick Example

<CodeGroup>
  <Code title="main.dart" language="dart">
void main() {
  print('Hello, Stardust! ✨');
}
  </Code>
  <Code title="pubspec.yaml" language="yaml">
name: my_app
description: A sample app
  </Code>
</CodeGroup>

## Installation

<Tabs>
  <Tab name="Dart">
dart pub global activate stardust
  </Tab>
  <Tab name="From Source">
git clone https://github.com/stardust-docs/stardust
cd stardust
dart pub global activate --source path .
  </Tab>
</Tabs>

## Next Steps

<Cards>
  <Card title="Getting Started" icon="🚀" href="/getting-started">
    Learn the basics of Stardust in 5 minutes
  </Card>
  <Card title="Configuration" icon="⚙️" href="/configuration">
    Customize your documentation site
  </Card>
</Cards>
''';

  String _gettingStartedTemplate() => '''
---
title: Getting Started
description: Get up and running with Stardust in minutes
---

# Getting Started

This guide will help you get up and running with Stardust.

## Installation

Install Stardust globally using Dart:

```bash
dart pub global activate stardust
```

## Create a New Project

<Steps>
  <Step title="Initialize">
Run the init command to create a new documentation project:

```bash
stardust init my-docs
cd my-docs
```
  </Step>
  <Step title="Start Development">
Run the development server with hot reload:

```bash
stardust dev
```

Your docs are now live at `http://localhost:4000`.
  </Step>
  <Step title="Build for Production">
Generate a static site for deployment:

```bash
stardust build
```

The output will be in the `dist/` directory.
  </Step>
</Steps>

## Project Structure

```
my-docs/
├── docs/           # Your markdown files
│   ├── index.md    # Home page
│   └── ...
├── public/         # Static assets (images, etc.)
├── docs.yaml       # Configuration
└── dist/           # Build output (generated)
```

## Components

Stardust supports JSX-style components in your markdown:

<AccordionGroup>
  <Accordion title="Callouts" defaultOpen="true">
Use callouts to highlight important information:

<Info>This is an informational callout.</Info>

<Warning>This is a warning callout.</Warning>

<Tip>This is a helpful tip!</Tip>
  </Accordion>
  <Accordion title="Tabs">
Use tabs to show alternative content:

<Tabs>
  <Tab name="npm">npm install package</Tab>
  <Tab name="yarn">yarn add package</Tab>
  <Tab name="pnpm">pnpm add package</Tab>
</Tabs>
  </Accordion>
</AccordionGroup>

## What's Next?

<Tip>
Explore the full list of components available in Stardust, including code groups, cards, steps, and more.
</Tip>
''';

  String _gitignoreTemplate() => '''
# Stardust build output
dist/

# Dart
.dart_tool/
.packages
pubspec.lock

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
''';
}

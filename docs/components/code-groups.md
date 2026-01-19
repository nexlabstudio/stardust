---
title: Code Groups
description: Display multiple related code files in a tabbed interface.
---

# Code Groups

Code Groups let you show multiple related code files together, perfect for showing different files in a project or different versions of the same code.

## Basic Code Group

<CodeGroup>
  <Code title="main.dart" language="dart">
void main() {
  runApp(MyApp());
}
  </Code>
  <Code title="pubspec.yaml" language="yaml">
name: my_app
dependencies:
  flutter:
    sdk: flutter
  </Code>
</CodeGroup>

```markdown
<CodeGroup>
  <Code title="main.dart" language="dart">
void main() {
  runApp(MyApp());
}
  </Code>
  <Code title="pubspec.yaml" language="yaml">
name: my_app
dependencies:
  flutter:
    sdk: flutter
  </Code>
</CodeGroup>
```

## Project Structure Example

Show how files work together:

<CodeGroup>
  <Code title="lib/main.dart" language="dart">
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const MyApp());
}
  </Code>
  <Code title="lib/app.dart" language="dart">
import 'package:flutter/material.dart';
import 'home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: const HomePage(),
    );
  }
}
  </Code>
  <Code title="lib/home_page.dart" language="dart">
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Hello!')),
    );
  }
}
  </Code>
</CodeGroup>

## Configuration Files

<CodeGroup>
  <Code title="stardust.yaml" language="yaml">
name: My Docs
description: Documentation for My Project

nav:
  - label: Docs
    href: /

sidebar:
  - group: Getting Started
    pages:
      - index
      - installation
  </Code>
  <Code title="package.json" language="json">
{
  "name": "my-docs",
  "scripts": {
    "dev": "stardust dev",
    "build": "stardust build"
  }
}
  </Code>
</CodeGroup>

## API Request/Response

<CodeGroup>
  <Code title="Request" language="bash">
curl -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John", "email": "john@example.com"}'
  </Code>
  <Code title="Response" language="json">
{
  "id": "usr_123",
  "name": "John",
  "email": "john@example.com",
  "created_at": "2024-01-15T10:30:00Z"
}
  </Code>
</CodeGroup>

## Before/After Example

<CodeGroup>
  <Code title="Before" language="dart">
// Old approach - manual state management
class Counter {
  int _value = 0;

  void increment() {
    _value++;
    notifyListeners();
  }
}
  </Code>
  <Code title="After" language="dart">
// New approach - using Riverpod
final counterProvider = StateProvider<int>((ref) => 0);

// In widget
ref.read(counterProvider.notifier).state++;
  </Code>
</CodeGroup>

## Supported Languages

Code Groups support all the same languages as regular code blocks:

- `dart`, `javascript`, `typescript`, `python`, `go`, `rust`
- `java`, `kotlin`, `swift`, `c`, `cpp`, `csharp`
- `ruby`, `php`, `sql`, `graphql`
- `yaml`, `json`, `toml`, `xml`
- `bash`, `shell`, `powershell`
- `html`, `css`, `scss`
- And many more...

## Code Groups vs Tabs

<Info>
Use **Code Groups** when showing related files that work together.

Use **Tabs** when showing alternative implementations (different languages doing the same thing).
</Info>

**Code Groups** - Multiple files in one project:
<CodeGroup>
  <Code title="index.html" language="html">
<div id="app"></div>
  </Code>
  <Code title="style.css" language="css">
#app { padding: 20px; }
  </Code>
</CodeGroup>

**Tabs** - Same thing in different languages:
<Tabs>
  <Tab name="JavaScript">
    ```javascript
    console.log('Hello');
    ```
  </Tab>
  <Tab name="Python">
    ```python
    print('Hello')
    ```
  </Tab>
</Tabs>

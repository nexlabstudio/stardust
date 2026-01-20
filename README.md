# Stardust

**A Dart-native documentation generator. Beautiful docs, zero config.**

[![CI](https://github.com/nexlabstudio/stardust/actions/workflows/ci.yml/badge.svg)](https://github.com/nexlabstudio/stardust/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/nexlabstudio/stardust/branch/dev/graph/badge.svg?token=XoNeoaL5pi)](https://codecov.io/gh/nexlabstudio/stardust)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

---

## Why Stardust?

Building documentation shouldn't require a JavaScript toolchain. Stardust is a **fast, native documentation generator** built entirely in Dart — no Node.js, no npm, no webpack. Just beautiful docs.

- **Zero Configuration** — Sensible defaults out of the box. Start writing immediately.
- **Blazing Fast** — Native Dart binary. Builds in milliseconds, not minutes.
- **Beautiful by Default** — Clean, modern design with automatic dark mode.
- **Rich Components** — Callouts, tabs, code groups, API docs, and 30+ components.
- **Full-Text Search** — Powered by Pagefind. No external services required.
- **SEO Optimized** — Automatic sitemap, robots.txt, Open Graph, and Twitter Cards.
- **OpenAPI Import** — Generate API documentation from your Swagger/OpenAPI specs.

---

## Installation

### macOS

**Homebrew** (recommended)

```bash
brew tap nexlabstudio/tap
brew install stardust
```

**curl**

```bash
curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash
```

### Linux

**curl** (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash
```

**Snap**

```bash
snap install stardust
```

### Windows

**Scoop** (recommended)

```powershell
scoop install https://raw.githubusercontent.com/nexlabstudio/stardust/dev/scoop/stardust.json
```

**Chocolatey**

```powershell
choco install stardust
```

### Dart/Flutter Developers

If you already have Dart installed:

```bash
dart pub global activate stardust
```

### Manual Download

Download pre-built binaries from the [Releases](https://github.com/nexlabstudio/stardust/releases) page.

| Platform | Architecture | Download |
|----------|--------------|----------|
| macOS | Apple Silicon | `stardust-darwin-arm64.tar.gz` |
| macOS | Intel | `stardust-darwin-x64.tar.gz` |
| Linux | x64 | `stardust-linux-x64.tar.gz` |
| Linux | ARM64 | `stardust-linux-arm64.tar.gz` |
| Windows | x64 | `stardust-windows-x64.zip` |

---

## Quick Start

**1. Create a new project**

```bash
stardust init my-docs
cd my-docs
```

**2. Start the dev server**

```bash
stardust dev
```

Open [http://localhost:4000](http://localhost:4000) to see your docs with live reload.

**3. Build for production**

```bash
stardust build
```

Your static site is ready in `dist/`. Deploy anywhere.

---

## Project Structure

```
my-docs/
├── docs/              # Your markdown files
│   ├── index.md       # Home page
│   └── guide.md       # Additional pages
├── public/            # Static assets (images, etc.)
├── stardust.yaml      # Configuration
└── dist/              # Build output (generated)
```

---

## Features

### Rich Component Library

Write expressive documentation with JSX-style components:

```markdown
<Info>This is an informational callout.</Info>

<Tabs>
  <Tab name="npm">npm install package</Tab>
  <Tab name="yarn">yarn add package</Tab>
</Tabs>

<Steps>
  <Step title="Install">Run the installer</Step>
  <Step title="Configure">Edit the config file</Step>
  <Step title="Deploy">Push to production</Step>
</Steps>
```

**30+ built-in components:** Callouts, Tabs, Accordions, Cards, Steps, Code Groups, API docs, YouTube/Vimeo embeds, Mermaid diagrams, and more.

### API Documentation

Document your APIs beautifully:

```markdown
<Api method="GET" path="/users/{id}">
  <ParamField name="id" type="string" required>User ID</ParamField>
  <ResponseField name="email" type="string">User's email</ResponseField>
</Api>
```

Or import directly from OpenAPI/Swagger:

```bash
stardust openapi openapi.yaml -o docs/api
```

### Full-Text Search

Search is built-in and works offline. Powered by [Pagefind](https://pagefind.app/).

- Press `/` or `Cmd+K` to search
- No external services or API keys required
- Works entirely client-side

### Dark Mode

Automatic dark mode that respects system preferences. Or let users toggle manually.

### SEO Ready

- Automatic `sitemap.xml` generation
- Configurable `robots.txt`
- Open Graph and Twitter Card meta tags
- Clean, semantic HTML output

---

## Configuration

Create a `stardust.yaml` in your project root:

```yaml
name: My Project
description: Documentation for My Project
url: https://docs.myproject.com

nav:
  - label: Guide
    href: /
  - label: API
    href: /api
  - label: GitHub
    href: https://github.com/myorg/myproject
    external: true

sidebar:
  - group: Getting Started
    pages:
      - index
      - installation
      - quickstart

theme:
  colors:
    primary: "#6366f1"
  darkMode:
    enabled: true
    default: system

search:
  enabled: true
  placeholder: "Search docs..."
  hotkey: "/"
```

---

## Commands

| Command | Description |
|---------|-------------|
| `stardust init [dir]` | Create a new documentation project |
| `stardust dev` | Start dev server with hot reload |
| `stardust build` | Build static site for production |
| `stardust openapi <spec>` | Generate docs from OpenAPI spec |

---

## Deployment

Stardust generates a static site in `dist/`. Deploy anywhere static files are served.

### GitHub Pages (recommended)

Use GitHub Actions to build and deploy automatically:

```yaml
# .github/workflows/deploy.yml
- run: curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash
- run: stardust build
- uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./dist
```

### Vercel / Netlify / Cloudflare Pages

These platforms don't have Stardust pre-installed. Two options:

**Option 1: Build with GitHub Actions, deploy output**

Build in CI, then deploy the `dist/` folder. Set your platform to serve from the build output.

**Option 2: Install during build**

```bash
# Build command (Vercel/Netlify/Cloudflare)
curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash && stardust build

# Output directory
dist
```

### Any Static Host

Just upload the `dist/` folder to any web server, CDN, or object storage (S3, GCS, etc.).

---

## Comparison

| Feature | Stardust | docs.page | Mintlify | Starlight | Docusaurus | VitePress | GitBook |
|---------|----------|-----------|----------|-----------|------------|-----------|---------|
| No Node.js required | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Zero config | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| Self-hosted | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Free & open source | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Freemium |
| JSX-style components | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Built-in search | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| OpenAPI/Swagger import | ✅ | ❌ | ✅ | Plugin | Plugin | Plugin | ✅ |
| Dark mode | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SEO (sitemap, meta tags) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Edit on GitHub | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| i18n / Multi-language | 🚧 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Versioning | 🚧 | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |
| API documentation | ✅ | ✅ | ✅ | Plugin | Plugin | Plugin | ✅ |
| LLM-friendly output | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Mermaid diagrams | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Dart/Flutter focus | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

✅ = Built-in | 🚧 = Coming soon | Plugin = Requires plugin/addon | ❌ = Not available

---

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting a PR.

```bash
# Clone the repo
git clone https://github.com/nexlabstudio/stardust.git
cd stardust

# Install dependencies
dart pub get

# Run tests
dart test

# Run locally
dart run bin/stardust.dart --help
```

---

## License

Apache-2.0 — See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with Dart. Made for developers who value simplicity.
</p>

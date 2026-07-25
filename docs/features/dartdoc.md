---
title: Dart API Docs (dartdoc)
description: Co-host a Dart package's API reference inside your Stardust site — guides and API in one place, with unified search.
---

# Dart API Docs

`stardust dartdoc` runs Dart's official [`dart doc`](https://dart.dev/tools/dart-doc) on a package and folds the generated API reference into your Stardust site: guides and API reference live under one domain, one deploy, and **one search box**.

Every API page gets a Stardust top-bar linking back to your docs, and its content is indexed by the site's search — so a reader searching your docs finds API symbols alongside your guides. dartdoc renders the API bodies (accurate and always up to date with the language); Stardust owns the surrounding chrome and search.

## Usage

Run it from anywhere, pointing at the Dart package (defaults to the current directory):

```bash
# Resolve the package's dependencies first
dart pub get

# Generate the API docs into public/api/
stardust dartdoc . -o public/api
```

Then build as usual — the `public/` directory is copied into your site and indexed automatically:

```bash
stardust build
```

Your API reference is now live at `/api/`, searchable from the main search box.

<Note>
`stardust dartdoc` is a generation step you run when your package's API changes (like `stardust openapi`), not on every build — `dart doc` takes a few seconds. Commit the generated `public/api/` or regenerate it in CI before `stardust build`.
</Note>

## Wire up the navigation

Add a link to your API docs in `stardust.yaml`:

```yaml
nav:
  - label: API
    href: /api/
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `[package-path]` | `.` | Path to the Dart package to document |
| `-o`, `--output` | `public/api` | Where to write the API docs |
| `-c`, `--config` | `stardust.yaml` | Config file (used for the top-bar name + back-link) |

## Requirements

- The **Dart SDK** must be installed and on your `PATH` (`stardust dartdoc` shells out to `dart doc`).
- Run `dart pub get` in the package first so its dependencies resolve.

## What's co-hosted vs. native

The API page **bodies** keep dartdoc's own styling — Stardust adds the top-bar and unified search around them, rather than re-rendering the API content. This keeps the integration robust and zero-maintenance as the language and dartdoc evolve. Full Stardust-native styling of API bodies is a future enhancement.

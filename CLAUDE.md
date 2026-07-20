# CLAUDE.md

Stardust — a Dart-native static documentation generator (no Node/JS toolchain). CLI in `bin/stardust.dart`, everything else under `lib/src/`: `cli/` (commands), `config/` (stardust.yaml parsing), `content/` (markdown + component pipeline), `generator/` (HTML/CSS/JS output builders), `openapi/`, `search/` (Pagefind), `core/` (FileSystem/Logger DI).

## Commands

```bash
dart test                      # run all tests (~4s, must stay green)
dart test test/config/        # run one suite
dart analyze                   # lint — zero warnings expected
dart format .                  # 120-col page width, trailing commas automated
dart run bin/stardust.dart build   # build the docs/ site into dist/
dart run bin/stardust.dart dev     # dev server with live reload
```

## Coding style

We are big on Dart 3 idioms. These rules override any generic Dart habits:

### Pattern matching & switch expressions — always
Prefer `switch` *expressions* with patterns over if/else chains, switch statements, and type-check-then-cast:

```dart
// YES — the house style (see config/*.dart fromYaml factories)
factory TocConfig.fromYaml(Map? yaml) => switch (yaml) {
      final Map yaml => TocConfig(
          title: yaml['title'] as String? ?? 'On this page',
        ),
      _ => const TocConfig(),
    };

// NO
if (yaml is Map) { ... } else { ... }
```

Use if-case for single-pattern refinement: `if (node case {'type': final String type})`.

### Destructuring — use it
Records, list/map/object patterns over positional access and repeated lookups:

```dart
// YES
final (light, dark) = resolveThemePair(config);
final {'method': final String method, 'path': final String path} = endpoint;
for (final MapEntry(:key, :value) in map.entries) { ... }

// NO
final light = pair.$1; final dark = pair.$2;
```

### No bang operators — ever
Never use the null-assertion operator `!`. Pattern match the null where appropriate, or use `??` when a default value is all you need:

```dart
// YES — null-check pattern when the null case changes control flow
if (config.versions case final versions?) { use(versions); }

final banner = switch (versions.current) {
  final current? => buildBanner(current),
  null => '',
};

// YES — ?? when a fallback value suffices
final label = entry.label ?? entry.version;

// NO
use(config.versions!);
final label = entry.label!;
```

Pick by intent: `??` for "use this default", patterns for "do something different when absent".

If you believe a value can't be null but the type says otherwise, fix the type or destructure — a `!` is a latent crash and will not pass review. The same goes for `as` casts where a pattern would do.

### Comments — only when the code can't say it
No unnecessary comments, ever — and remove them on sight when touching existing code. Never write comments that narrate what the next line does, restate the name of the thing, or justify a change to a reviewer. A comment is warranted only for a constraint the code cannot express (a non-obvious invariant, a deliberate deviation, a "why" that isn't visible). Public API gets a single-line `///` doc stating what it is — no multi-paragraph essays.

### General
- Expression bodies (`=>`) over block bodies when the body is a single expression (`prefer_expression_function_bodies` is enforced).
- Single quotes; string interpolation over concatenation; 120-column lines; trailing commas (the formatter automates them).
- `final` everywhere it's possible (`prefer_final_locals`/`prefer_final_fields` are enforced).
- Exhaustive switches over enums/sealed types — no `default:` arms that hide missing cases; use `_` only for genuinely open types (e.g. raw YAML).

## Project conventions

- **Dependency injection**: all file access goes through the `FileSystem` abstraction and all output through `Logger` (`lib/src/core/`). Never use raw `dart:io` `File`/`Directory`/`stdout` inside `lib/` — it breaks testability. Roughly ten files still violate this (the CLI commands, `config_loader`, `pagefind_runner`, `site_generator`'s glob, `openapi_importer`) — they are legacy debt scheduled with the CLI test-coverage work, not precedents; do not add new raw `dart:io` even in those files.
- **Escape at every interpolation** into generated output: HTML text/attributes via `encodeHtml` (`lib/src/utils/html_utils.dart`), query params via `Uri.encodeQueryComponent`, and never interpolate raw config/frontmatter strings into JS or XML. Unescaped interpolation will not pass review.
- **Errors**: throw the project exception types (`ConfigException`, `ContentException` — `lib/src/utils/exceptions.dart`) with actionable messages, never bare `Exception` or raw casts that surface as `TypeError` stack traces to users.
- **Tests accompany every change**: suites mirror `lib/` structure under `test/`, use `MockFileSystem` (`test/mocks/`) rather than the real disk. Prefer asserting behavior/semantic fragments over full-HTML snapshots.
- **Path separators in tests**: `MockFileSystem` normalizes every path to forward slashes and its collections are private, so seed with `p.join` or `/` literals interchangeably and assert through the accessors — `fileAt`, `binaryFileAt`, `hasFile`, `hasDirectory`, `filePaths`, and `MockFileSystem.op(action, path, recursive: ...)` for operation-log entries. The compiler now enforces this; there is no raw-collection path to get separator-wrong.
- Component builders live in `lib/src/content/components/` and register in `ComponentTransformer`; shared regexes belong in `lib/src/utils/patterns.dart`, not inline.
- Docs (`docs/`) and the JSON schema (`schema/stardust.json`) must be updated in the same change as any config/feature work — documented-but-unimplemented behavior is treated as a bug.

## Git

- Commit messages are short, direct, and imperative, written in the first person as the repo maintainer. Never add `Co-Authored-By`, `Generated with …`, or any AI/tool attribution — commits read as if the maintainer wrote them by hand.

# Theming API Spec (v2 — "full theming")

*Drafted 2026-07-24. Extends Theming v1 (tokens + `footer.poweredBy` + HTML slots, shipped on `feat/theming`) into a full theming API: partial template overrides, an `eject` command, and component template overrides. Goal: flip the §2 matrix row "Theming/extensibility API" from ⚠️ to ✅.*

## 1. Goal

Let an author restructure the site's chrome — not just recolor it — **without forking the generator**. Three capabilities, in priority order:

1. **Partial overrides** — replace the HTML of a layout region (header, footer, sidebar, page shell) with your own template, using `{{ placeholders }}` for the dynamic pieces so you keep nav/search/content/etc.
2. **`stardust eject`** — write a region's default template to disk as a starting point for an override.
3. **Component template overrides** — provide an HTML template for a component (`Card`, `Callout`, …). The least tractable tier (see §6); scoped last.

### Non-goals
- A JS/React component runtime or client-side theming. Static HTML only.
- A general template language (loops, conditionals, expressions). We add **only** `{{ name }}` substitution — no dependency, no logic in templates. Anything needing logic stays in Dart.
- Overriding `<head>`/meta/SEO/scripts. Those stay generator-owned (correctness-critical); only visible chrome is themeable.

## 2. Where we are vs what's missing

| Piece | Status |
|---|---|
| CSS token overrides (`theme.tokens` / `tokensDark`) | ✅ v1 |
| `footer.poweredBy: false` | ✅ v1 |
| HTML slots (append into header/footer/sidebar) | ✅ v1 |
| Custom CSS (inline + file) | ✅ pre-v1 |
| **Replace** a layout region's HTML | ❌ |
| **Eject** default templates | ❌ |
| **Component** template override | ❌ |

The blocker: `PageLayoutBuilder` and the component builders **concatenate HTML strings in Dart**. There is no template artifact to override or eject. This spec's core is turning those regions into *templates the builders fill*, so override + eject fall out of one source of truth.

## 3. The core refactor — render from embedded templates

Today (`page_layout_builder.dart`):

```dart
String buildHeader([String currentPath = '/']) => '''
  <header class="header"> ...hardcoded HTML with $interpolations... </header>''';
```

Proposed: each region has a **default template** stored as an embedded asset (like CSS in `stardust_css.dart`), rendered by filling named placeholders:

```
assets/templates/header.html
  <header class="header">
    <div class="header-inner">
      {{ mobileToggle }}
      {{ logo }}
      <nav class="nav">{{ nav }}</nav>
      <div class="header-actions">{{ localeDropdown }}{{ versionDropdown }}{{ search }}{{ themeToggle }}{{ social }}{{ slotHeader }}</div>
    </div>
  </header>
```

```dart
String buildHeader([String currentPath = '/']) => renderTemplate(_template('header'), {
      'mobileToggle': _mobileToggle(),
      'logo': _buildLogo(),
      'nav': _navLinks(),
      'search': _searchButton(),
      'themeToggle': _themeToggle(),
      'localeDropdown': _buildLocaleDropdown(currentPath),
      'versionDropdown': _buildVersionDropdown(currentPath),
      'social': _buildSocialLinks(),
      'slotHeader': config.theme.slots.header ?? '',
    });
```

- **`renderTemplate(tpl, values)`**: replace each `{{ name }}` with `values[name] ?? ''`; unknown `{{ x }}` → empty (never throws). ~15 lines, no dependency. Values are **already-built HTML fragments** (each `_x()` helper still owns its own escaping), so the placeholder substitution injects trusted generator output, not user data.
- **Embedded defaults**: a `tool/embed_templates.dart` (mirrors `embed_css.dart`) turns `assets/templates/*.html` into `lib/src/generator/builders/stardust_templates.dart` (a `Map<String,String>`), with a sync test (mirrors `css_sync`). One source of truth for default + eject.
- **Override**: if `theme.partials[region]` is set, load that file's content instead of the embedded default and fill the **same** placeholders. Missing placeholders in a user template just render nothing; extra generator values are ignored — so a user template can be as minimal as they want.

Regions (increment 1): `header`, `footer`, `sidebar`, and `page` (the docs body shell: `{{ header }}{{ sidebar }}{{ content }}{{ toc }}{{ editLink }}{{ pageNav }}{{ footer }}`). Splash shell (`hero` + `splash`) can be a later region.

### 3a. Placeholder catalogs (the stable contract)

Each region documents its placeholders. Draft:

- **header**: `mobileToggle`, `logo`, `nav`, `search`, `themeToggle`, `localeDropdown`, `versionDropdown`, `social`, `slotHeader`
- **footer**: `links`, `copyright`, `social`, `poweredBy`, `slotFooter`
- **sidebar**: `close`, `groups`, `slotSidebar`
- **page** (docs shell): `header`, `mobileOverlay`, `sidebar`, `copyPageButton`, `content`, `editLink`, `pageNav`, `toc`, `footer`

This catalog *is* the theming API surface — versioned and documented like the CSS tokens.

## 4. Config

```yaml
theme:
  partials:
    header: theme/header.html      # relative to project root
    footer: theme/footer.html
    sidebar: theme/sidebar.html
    page: theme/page.html
  components:                      # increment 3
    Card: theme/card.html
```

- New `theme.partials` (`Map<String,String>` of region → file path) and `theme.components` (component name → file path). Add to `ThemeConfig`, schema, and docs.
- Files are read at build time. Reads must go through the `FileSystem` abstraction; today `PageLayoutBuilder` has no `FileSystem` — thread one in (small DI change), or (simpler) resolve partial contents in `SiteGenerator` (which has `FileSystem`) and pass a `Map<String,String>` of resolved partials into `PageBuilder`/`PageLayoutBuilder`, mirroring how `resolvedCssFileContent` is already injected. **Prefer the latter** — no new `dart:io` in builders, consistent with the CSS-file precedent.
- Missing partial file → build error via `ContentException` with the path (fail loud, like a missing content dir).

## 5. `stardust eject`

```
stardust eject <region>        # header | footer | sidebar | page | component:Card
stardust eject --list          # show ejectable regions
stardust eject header -o theme/ # write theme/header.html (default: ./theme/)
```

- Writes the embedded default template (`stardustTemplates[region]`) to `theme/<region>.html`, then the author wires it via `theme.partials`. Refuses to overwrite without `--force`.
- Because the builder renders from the *same* embedded template, an ejected-then-unmodified partial produces byte-identical output — the guarantee that makes eject trustworthy. A test asserts this per region.
- New `EjectCommand` in `cli/commands/`, registered in `cli_runner.dart`. DI'd `FileSystem`/`Logger` like the other commands.

## 6. Component overrides (increment 3 — honest limits)

Components (`CardBuilder`, etc.) emit HTML from attributes + nested content. A template override:

```
theme/card.html
  <a class="card card-link" href="{{ href }}">{{ icon }}<h3 class="card-title">{{ title }}</h3><div class="card-content">{{ content }}</div></a>
```

`ComponentTransformer` checks `theme.components[tagName]` before the default builder; if present, fills that component's documented placeholders (`title`, `icon`, `href`, `content`, plus raw `attrs`).

**Limits to state plainly in the docs:**
- Only components with a **stable, documented placeholder set** are overridable (start with `Card`; expand deliberately). Not every one of the 30+ components — many have irregular structure (tabs, steps, API blocks) that a flat placeholder map can't express.
- `content` is already-rendered child HTML; the template controls the wrapper, not the inner structure.
- This tier is genuinely weaker than a component runtime. Say so — don't imply Rspress-parity on component swapping.

## 7. Escaping & security

- Placeholder **values** are generator-built HTML fragments that already escape their own dynamic inputs — substitution injects trusted output. No user data flows through a placeholder unescaped.
- Partial/component **template files** are author-controlled raw HTML (same trust as `custom.css` and v1 slots). Documented as such. They can contain `{{ placeholders }}` and arbitrary markup; they cannot inject unescaped *user* content because the only dynamic content comes from the pre-escaped value map.
- `{{ }}` scan must ignore anything outside the known catalog (render empty) so a stray `{{ toc }}` in prose or a typo can't error the build.

## 8. Files

| File | Change |
|---|---|
| `assets/templates/*.html` | New — default region templates (header, footer, sidebar, page). |
| `tool/embed_templates.dart` | New — embed templates → `stardust_templates.dart`; add a sync test. |
| `lib/src/generator/builders/stardust_templates.dart` | Generated. |
| `lib/src/utils/template.dart` (or util) | `renderTemplate(tpl, values)` + a `{{ }}` scanner. |
| `lib/src/generator/builders/page_layout_builder.dart` | Render header/footer/sidebar from templates; keep the `_x()` fragment helpers. |
| `lib/src/generator/page_builder.dart` | Render the docs shell (`page`) from a template; accept resolved partials. |
| `lib/src/generator/site_generator.dart` | Resolve `theme.partials`/`components` files via `FileSystem`, inject into `PageBuilder`. |
| `lib/src/config/theme_config.dart` | `partials` + `components` maps. |
| `lib/src/content/component_transformer.dart` | Component override lookup (increment 3). |
| `lib/src/cli/commands/eject_command.dart` + `cli_runner.dart` | `stardust eject`. |
| `schema/stardust.json` | `theme.partials`, `theme.components`. |
| `docs/config/theme.md`, new `docs/features/theming.md` | Placeholder catalogs, eject, component-override limits. |
| tests | Template render/scan, per-region override, eject byte-identical guarantee, missing-file error, component override. |

## 9. Increments

1. **Template engine + layout partials** — `renderTemplate`, embedded templates + sync test, refactor header/footer/sidebar/page to render from them, `theme.partials`, resolve via `SiteGenerator`. Ship with a byte-identical-output regression guard (the refactor must not change default HTML). *This is the bulk of the value and the highest-risk step.*
2. **`stardust eject`** — command + per-region byte-identical test.
3. **Component overrides** — `theme.components`, start with `Card`, documented placeholder catalog + limits.

Each increment is independently shippable and flips more of the row; after 1–2 the matrix row is a defensible ✅ (override + eject), with 3 as the stretch.

## 10. Risks

- **R1 — layout regression (highest)**: converting string-building to template-filling can subtly change output (whitespace, attribute order, conditional blocks). Mitigation: a golden-output test that renders every region with default config *before* and *after* the refactor and asserts equality; land increment 1 behind that guard.
- **R2 — conditional chunks**: today regions use inline conditionals (e.g. search button only when `search.enabled`). In templates these become placeholders that render empty when disabled — verify each conditional maps cleanly to an empty-string value, and that the surrounding template degrades (no empty `<div>` artifacts that break layout).
- **R3 — two sources of truth**: default template files vs the Dart that used to hold the markup. The embed + sync test keeps them honest, but the templates and the fragment helpers must agree on class names/structure. Single-source via embedded templates is the whole point — resist re-hardcoding HTML in Dart.
- **R4 — scope creep on components**: 30+ components, most not cleanly templatable. Hold the line at a documented, small, stable set; never imply full component-swap parity.
- **R5 — file reads in builders**: keep `dart:io` out of builders; resolve partial files in `SiteGenerator` and inject, per the `resolvedCssFileContent` precedent.

## 11. Future direction — the rendering model

**Keep the `{{ }}` layer deliberately minimal. It is a boundary, not a new engine.**

Stardust renders HTML by string concatenation in Dart builders, escaping at each interpolation (see the CLAUDE.md "escape at every interpolation" rule). This spec does **not** change that for the internals — it adds a shallow template surface *only* where users override chrome. During increment 1 the themed regions therefore run **two rendering models at once**: `{{ }}`-filled templates for structure, and the existing string-building fragment helpers (`_buildLogo()`, `_navLinks()`, …) for the dynamic pieces. That coexistence is intentional and temporary-shaped, but it is also the seam where a larger "how does Stardust render HTML?" decision could get forced. Whoever builds this should hold that seam open, not close it:

- **Do not grow `{{ }}` into a template language.** No loops, conditionals, filters, or expressions — ever, in this layer. The moment templates need logic, that logic belongs in Dart, exposed as another named placeholder. A logic-bearing template language is a dependency and a lock-in we'd struggle to walk back, and it fights the zero-dependency single-binary ethos. The whole point of keeping it dumb is that it commits us to nothing.

- **The likely long-term evolution is *not* a template engine.** If Stardust ever moves meaningfully off string concatenation, the higher-value direction is a small **typed, escape-by-construction HTML helper** (e.g. `el('a', {'href': url}, [text(label)])`) introduced *incrementally*, builder-by-builder, starting where escaping is riskiest (attributes, raw frontmatter interpolation). That would retire the manual-escaping rule — the real latent-bug source — without a rewrite, and without a template language. The `{{ }}` override layer and a future typed-node internals layer are orthogonal: templates are the *user* seam, typed nodes would be the *internal* safety upgrade.

- **The forcing function to watch** is not theming demand — it's an escaping incident. A shipped XSS traced to a missed `encodeHtml` is what would justify the typed-node investment. Until then, string-building is the correct, fast, dependency-free default for a tool whose pitch is "a native binary with no toolchain," and the theming layer should stay a thin skin over it.

## 12. Roadmap placement

Not a v0.7 "Table Stakes" item — this is a **v0.8 "Wedge"-adjacent** capability (matches Rspress's theming depth, the one competitor at parity on versioning/i18n). Proposed ROADMAP entry: *"Theming v2 — partial/template overrides + `stardust eject` + component templates"* (L–XL, increments per §9). Sequence after the remaining v0.7 S-items (synced tabs, git metadata, GitHub Action); it's the piece that turns the last ⚠️ matrix cell into ✅.

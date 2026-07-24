# Landing / Splash Page Spec

*Drafted 2026-07-19. Adds a sidebar-less landing-page layout with a frontmatter-driven hero and CTA buttons, so a Stardust site can have a product homepage like bloclibrary.dev / kaisel.dev (both Astro Starlight `template: splash`).*

## 1. Goal

Let any page opt into a full-width **splash** layout — no sidebar, no TOC, no prev/next — that opens with a frontmatter-driven **hero** (title, tagline, CTA buttons, optional image) and then renders normal markdown body content (feature cards, prose) full-width.

Reproduces what both reference sites actually are: a splash template + a `<CardGrid>` of cards. Stardust already ships the card grid (`<Cards>`/`<Card>`); the two gaps are the layout switch and the hero.

### Non-goals (v1)
- Animations, parallax, marketing-JS. Static HTML+CSS only (matches the references — neither uses runtime JS beyond stock theme/search).
- Per-section background images / gradients beyond a single optional hero image.
- A page-builder/blocks system. Content stays markdown + existing components.

## 2. What already exists vs what's missing

| Piece | Status |
|---|---|
| Feature card grid (`<Cards cols>` + `<Card title href>`) | ✅ shipped (`card_builder.dart`, `.cards` CSS) |
| Callouts, steps, tabs, code blocks | ✅ shipped |
| Top nav bar (header) | ✅ shipped (`buildHeader`) |
| **Sidebar-less full-width layout** | ❌ — `PageBuilder.build` has one fixed layout |
| **Frontmatter hero (title + tagline + CTA buttons + image)** | ❌ new |
| **Standalone CTA `<Button>` component** (for body use) | ❌ optional add |

## 3. Frontmatter contract

Read from `page.frontmatter` (already a `Map<String, dynamic>` on `Page`; no config or schema change — frontmatter is free-form). Example `docs/index.md`:

```yaml
---
title: Stardust
layout: splash
hero:
  tagline: A Dart-native documentation generator. Beautiful docs, zero config.
  image: /images/stardust-logo.svg     # optional; site-absolute or relative
  actions:
    - label: Get Started
      href: /quickstart
      variant: primary                  # primary | secondary (default secondary)
    - label: View on GitHub
      href: https://github.com/nexlabstudio/stardust
      variant: secondary
      external: true                    # opens in new tab, adds rel=noopener
---

<Cards cols="3">
  <Card title="Zero Config" icon="zap">Sensible defaults out of the box.</Card>
  <Card title="Blazing Fast" icon="rocket">Native Dart binary.</Card>
  <Card title="Full-Text Search" icon="search" href="/features/search">Powered by Pagefind.</Card>
</Cards>
```

- `layout: splash` is the switch. Any other value (or absent) → the normal docs layout, unchanged.
- `hero` is optional even on a splash page (a splash page could be pure cards). Its `title` defaults to `page.title`.
- `hero.actions` is a YAML list of `{label, href, variant?, external?}`. Parse defensively with patterns; skip malformed entries.

## 4. PageBuilder changes

`PageBuilder.build(page, {sidebar})` branches on the layout:

```dart
String build(Page page, {required List<SidebarGroup> sidebar}) {
  final isSplash = page.frontmatter['layout'] == 'splash';
  // ... shared <head> (unchanged) ...
  final body = isSplash ? _buildSplashBody(page, basePath) : _buildDocsBody(page, sidebar, basePath);
  return '<!DOCTYPE html> ... <body>$body ...</body>';
}
```

- `_buildDocsBody` = the current header + sidebar + prose + toc + footer (extracted verbatim from today's `build`).
- `_buildSplashBody` = header + `_buildHero(page)` + full-width `<main class="splash">` containing the (markdown-rendered) `page.content` + footer. **No** sidebar / TOC / edit-link / page-nav.
- Content still passes through `_prefixContentPaths` (subpath deploys) and carries `data-pagefind-body` unless `search: false` — search indexing of the homepage keeps working.
- The shared `<head>`, theme-init, meta, assets, and the search modal / `app.js` include stay identical for both layouts (one code path for those).

`_buildHero(Page page)` renders from `page.frontmatter['hero']`:

```html
<section class="hero">
  <div class="hero-inner">
    {optional <img class="hero-image" src=... alt="{title}">}
    <h1 class="hero-title">{page.title}</h1>
    <p class="hero-tagline">{hero.tagline}</p>
    <div class="hero-actions">
      <a class="hero-action hero-action--primary" href="{esc(sanitizeUrl(href))}" {externalAttrs}>{label}</a>
      ...
    </div>
  </div>
</section>
```

- **Escaping is mandatory** (house rule): title/tagline/label via `encodeHtml`, `href` via `encodeHtmlAttribute(sanitizeUrl(...))`, internal hrefs prefixed via the same `UrlResolver.href` used elsewhere; `external` → `target="_blank" rel="noopener"`. Reuse `html_utils`.
- Hero image `src`: `sanitizeUrl` + base-path prefix if site-relative.

## 5. CTA button component (optional, v1.1)

For CTA buttons *inside* markdown body (not just the hero), add a small `<Button href variant>Label</Button>` component in `content/components/` registered in `ComponentTransformer`, emitting the same `.hero-action`/`.button` markup. The hero already covers the homepage case, so this is additive; ship it if cheap, defer otherwise.

## 6. CSS (new `assets/css/NN-landing.css`)

Scoped, theme-token-based, ships through the existing embed pipeline:

- `.splash` — full-width centered column (`max-width` ~ 60rem, `margin-inline: auto`, generous vertical padding); no grid, no sidebar reservation.
- `.hero` — centered, large `.hero-title` (clamp-sized), muted `.hero-tagline`, `.hero-image` max-height.
- `.hero-actions` — flex row, wraps on mobile.
- `.hero-action--primary` — filled with `--color-primary`; `--secondary` — bordered/subtle. Reuse `--radius`, hover states like existing buttons.
- Reuse the existing `.cards` grid untouched — splash cards are the same component.
- Mobile: hero stacks, actions full-width.

Run `dart run tool/embed_css.dart`; `css_sync` test covers it.

## 7. Files

| File | Change |
|---|---|
| `lib/src/generator/page_builder.dart` | Layout branch; extract `_buildDocsBody`; add `_buildSplashBody` + `_buildHero`. |
| `assets/css/NN-landing.css` | New hero/splash/button styles; regenerate embed. |
| `lib/src/content/components/button_builder.dart` (opt) | `<Button>` component + register in `ComponentTransformer`. |
| `test/generator/page_builder_test.dart` | Splash-layout tests (below). |
| `docs/features/landing-page.md` + sidebar entry | Document `layout: splash` + `hero:` frontmatter. |
| `stardust.yaml` / `docs/index.md` (optional) | Make our own homepage a splash page — dogfood + showcase. |

No schema change (frontmatter is not schema-validated today). Optional follow-up: a frontmatter validator, out of scope here.

## 8. Verification

1. Unit (`page_builder_test`): a page with `layout: splash` →
   - contains `class="hero"`, the tagline, and each action with correct href/variant/external attrs;
   - contains **no** sidebar / TOC / page-nav / edit-link markup;
   - non-splash page still renders sidebar (regression guard);
   - hero label/tagline with `<`/`"` are escaped; a `javascript:` action href is stripped.
2. `tool/embed_css.dart` sync; `css_sync` green.
3. Real build: set `docs/index.md` to `layout: splash` with a hero + `<Cards>`, `stardust build`, serve, eyeball against kaisel.dev.
4. `dart test` + `dart analyze --fatal-infos` + `dart format --set-exit-if-changed` clean; deterministic rebuild.
5. Subpath check: hero action internal hrefs and the hero image resolve under `/stardust/`.

## 9. Risks

- **R1 — frontmatter shape drift**: `hero.actions` is nested YAML; parse with switch/patterns, skip malformed entries, never throw on a bad hero (degrade to no hero).
- **R2 — escaping**: hero is author-controlled but PRs happen; every interpolation escaped, `href` sanitized. Same discipline as the rest of the generator.
- **R3 — search/SEO on the homepage**: splash body keeps `data-pagefind-body` and the normal meta/canonical, so the homepage stays indexed and shareable.
- **R4 — scope creep** into a blocks/marketing-page system: explicitly out. Hero + full-width + existing cards is the whole surface.

## 10. Roadmap placement

Not currently in ROADMAP.md. Proposed: a **v0.7 "Table Stakes"** item — "Landing/splash page layout (frontmatter hero + CTA buttons; reuse existing cards)". Rationale: both flagship Dart-ecosystem docs sites (bloclibrary.dev, kaisel.dev) use exactly this, it's a top reason Dart/Flutter authors pick Starlight, and it directly serves Stardust's stated beachhead audience — for ~1–2 days of work, most of which (cards) already exists.

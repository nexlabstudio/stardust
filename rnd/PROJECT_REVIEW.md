# Stardust — Full Project Review

*Reviewed 2026-07-18 on branch `dev` (post-versioning merge, with uncommitted i18n work in the tree). ~10,300 lines of Dart across `lib/` and `bin/`.*

---

## 1. Executive summary

Stardust is a genuinely promising idea with a real market gap behind it: **a single-binary docs generator with Mintlify-quality output and no Node.js toolchain**. The packaging story (Homebrew, Scoop, Chocolatey, Snap, curl installer, `dart pub global`) is unusually mature for a v0.x, the build is fast (36 pages + 36 OG images in ~2.3s under JIT), and the component set is ambitious.

But the implementation has three structural problems that will cap it if not addressed:

1. **The entire frontend is Dart string literals.** 2,663 lines of CSS live inside `page_styles_builder.dart` as untooled, unlintable strings, inlined in full into *every* generated page. There is no templating or theming abstraction — users cannot override layout, replace a header, or change component markup.
2. **The content pipeline is regex string-rewriting, not parsing.** Component transformation breaks on same-type nesting, rewrites component syntax inside code fences, and depends on ordering luck. A docs tool's one non-negotiable is faithfully rendering the user's content.
3. **Escaping is nearly absent.** `encodeHtml` exists but is used in ~3 places; everything else interpolates raw. This produces broken HTML on benign input (`Bob's "special" case`) and real XSS on hostile input (docs repos take PRs).
4. **The docs overpromise the code.** Several documented features don't exist: `build.outDir` (which the versioning *and* i18n docs build their entire workflow on) is never read; the Algolia search provider is config-only vaporware; `llm: false` and `search: false` frontmatter flags are documented but unimplemented; "OpenAPI from URL" has zero HTTP handling. Docs, JSON schema, and code are three diverging sources of truth.

There is also one **critical data-loss bug**: `stardust build -o .` recursively deletes the target directory with no safety check, and `--clean` defaults to true.

None of this is fatal — the codebase is small enough to fix all of it. The market position is genuinely good. Below: the details and a prioritized plan.

---

## 2. Product assessment

### What the product gets right
- **Positioning**: "No Node.js, single native binary, zero config" is a real differentiator. The closest analogs are mdBook (Rust, much uglier output) and MkDocs Material (Python, needs pip). Nothing occupies "Mintlify aesthetics without the JS toolchain or SaaS."
- **Natural beachhead audience**: Dart/Flutter package authors. They already have Dart installed, they're underserved (dartdoc output is spartan), and pub.dev has ~50k packages.
- **Distribution**: brew tap, scoop, choco, snap, curl script, pre-built binaries for 5 platform/arch combos. This is ahead of most 0.x projects.
- **Feature checklist** covers the modern table stakes on paper: dark mode, full-text search (Pagefind), OpenAPI import, OG image generation, llms.txt, redirects, analytics, sitemap/robots, versioning UI, i18n (WIP).
- **Development velocity is healthy**: header/footer, versioning, mobile sidebar, analytics, redirects, custom CSS all landed in recent months as clean PR-per-feature work.

### Where the product story leaks
- **"Self-contained" isn't true**: every page loads `lucide@latest` (unpinned — a supply-chain and breakage risk) and `mermaid@10` from jsdelivr, plus Google Fonts from CDN. Docs break offline/air-gapped, which is exactly where "no toolchain, single binary" customers live. Icons/fonts should be vendored; `@latest` must be pinned regardless.
- **Page weight**: `dist/index.html` is 84KB, of which ~57KB is inline CSS and ~10KB inline JS — **79% identical boilerplate repeated on every page**. No shared cached asset. A 500-page site ships ~30MB of redundant CSS.
- **Search is off by default** in the flagship site's own config (`search.enabled: false`) while the README leads with "Full-Text Search."
- **llms.txt is an index only** — no per-page `.md` export, no `llms-full.txt`. Mintlify/Fumadocs now treat those as table stakes for the AI-consumption story, which should be *easy* for Stardust since it starts from markdown.
- **"v1.0 is here!" announcement banner** on a `version: 0.1.0` pubspec.

---

## 3. Competition

> **Update 2026-07-18**: competitor capabilities were verified against live changelogs/repos/pricing pages; the verified matrix and a "what changed in the market" field check live in [ROADMAP.md §2/§2a](ROADMAP.md). Biggest deltas vs the table below: docs.page shipped an AI-native v2 on 2026-07-03 (MCP server per repo, llms-full.txt, Ask AI, built-in search, `docs check`) while still lacking versioning/OpenAPI/static export; MkDocs Material entered maintenance mode (successor: Zensical, Rust, alpha); Rspress 2.0 emerged as an AI-native player; Mintlify added offline/static export at Enterprise tier.

| Competitor | Their strength | Stardust's angle against them |
|---|---|---|
| **Mintlify** | Best-in-class polish, hosted, AI features | Free, self-hosted, no vendor lock-in, no MDX/Node |
| **Docusaurus** | Ecosystem, plugins, versioning/i18n done right | No Node/React toolchain, instant builds, zero config |
| **VitePress / Starlight / Fumadocs** | Vue/Astro/Next ecosystems, themeable | Same — no JS toolchain; but they set the bar for theming APIs |
| **MkDocs Material** | Huge plugin ecosystem, mature i18n/versioning (mike) | No Python env; but Material's feature depth is the realistic benchmark |
| **mdBook** | Single binary (closest architectural sibling) | Far better default design and component set |
| **GitBook** | Hosted simplicity | Open source, own your output |
| **docs.page** (Invertase) | Zero install at all — renders MDX straight from a GitHub repo; free; branch/PR previews; the dominant choice in the Dart/Flutter ecosystem (FlutterFire, Melos) | Static output you own: host anywhere (Pages/S3/intranet/air-gapped), no third-party service in the serving path, works offline. **This is the head-to-head fight for Stardust's beachhead audience** — and why vendoring the CDN assets (§2) matters strategically, not just technically |

**Takeaway**: the "no toolchain" wedge is real, but every competitor above has (a) a theming/extensibility story and (b) real i18n + versioned builds. Those are the two gaps that make Stardust a demo rather than an adoption candidate today. The honest current bar to clear is MkDocs Material and mdBook for the general market — and **docs.page specifically for the Dart/Flutter beachhead**, where the winning argument is "static output you own, no hosted service required." That argument only holds once the CDN dependencies are vendored and the offline story is actually true.

---

## 4. Critical bugs (fix before anything else)

1. **`stardust build -o .` deletes your project** — `build_command.dart:80-83`. `--clean` defaults to `true` and calls `deleteDirectory(outputDir, recursive: true)` with no guard (not cwd, not an ancestor, not "looks like a build dir"). `-o .` or `-o ~` is catastrophic. Add refusal to delete cwd/ancestors and require a marker file (e.g. only clean dirs Stardust created) or make `--clean` opt-in.
2. **Systemic missing escaping / XSS** across all builders (details in §6.3). Highest-value single fix in the repo: escape-by-default at every interpolation point.
3. **JSON-LD `</script>` injection** — `page_meta_builder.dart:206-211`: `_escapeJson` doesn't escape `<`, so a title containing `</script>` breaks out of the structured-data script element. Escape `<` → `<`.
4. **Dark-mode flash on every page load** — theme class is applied by a script at the *end* of `<body>` (`page_scripts_builder.dart:28`); dark-theme users get a white flash on every navigation. The `class="dark-mode-*"` set on `<html>` (`page_builder.dart:40`) is dead code — no CSS references it. Move a tiny blocking theme snippet into `<head>`.
5. **Dev-server live reload is structurally broken with >1 tab** — `dev_command.dart:117-137`: each new SSE connection closes the previous client's stream; the orphaned tab's `onerror` reconnects and kills the other → reload storm; only the last tab ever gets reload events. Also `response.change(body:)` after injecting the reload script keeps the stale `content-length` (`dev_command.dart:97-109`), likely truncating the injected script.
6. **Concurrent overlapping rebuilds** — the 100ms debounce (`dev_command.dart:172-190`) has no "build in progress" guard; any build slower than 100ms can run concurrently with the next, both writing the same files.
7. **Pagefind binary downloaded without checksum verification** — `pagefind_runner.dart:80-136`. Ironic given `install.sh` verifies checksums for Stardust itself. Pagefind publishes checksums; verify them. Also: Windows ARM gets an x86_64 binary (`:63`), and `run()`'s failure return is discarded by both callers — `stardust build` prints success when search indexing failed.
8. **Non-deterministic builds** — `tab_builder.dart:115` seeds tab/code-group IDs from `DateTime.now().millisecondsSinceEpoch`. Every rebuild changes every ID: diff noise, broken deep links, cache churn. Use a per-page counter.
9. **i18n as currently written is SEO-harmful** (uncommitted work — fix before merge): the generator never produces per-locale output, yet hreflang alternates are emitted for every locale on every page (`page_meta_builder.dart:79-90`) — asserting translations at URLs that 404. The locale dropdown always marks the *default* locale active (`page_layout_builder.dart:155-159`), not the one being viewed.
10. **Redirect pages interpolate the destination unescaped** into meta-refresh, href, and a JS string (`redirect_generator.dart:83-96`); also `from.substring(1)` mangles `redirect_from: old-page` (no leading slash) into `ld-page/`, and a redirect can silently overwrite a real page's `index.html`.
11. **`build.outDir` is dead config, but both flagship-feature docs depend on it** — `docs/features/versioning.md` and `docs/features/i18n.md` tell users to set `build.outDir: build/v2` / `build/en` so multi-version/multi-locale builds "don't overwrite each other", but `build_command.dart` reads output *only* from the `--output` flag; `outDir` is parsed and never used. A user following the docs verbatim builds every version and locale into `dist/`, each silently clobbering the last.

---

## 5. Architecture problems

### 5.1 The frontend has no abstraction (`lib/src/generator/builders/`)
- `page_styles_builder.dart` is 2,663 lines; ~2,600 of them are *constant* CSS trapped in Dart strings — no CSS linting, no syntax checking (a typo compiles fine and silently breaks rendering), no minification, no editor tooling. `_buildVersionStyles` (195-254) and `_buildI18nStyles` (257-316) are the identical dropdown ruleset copy-pasted with different prefixes.
- Theming = ~10 CSS custom properties + append-only custom CSS that must fight `!important` (`.logo`, the entire Pagefind section at lines 628-800). Dozens of hardcoded hex values (callouts, panels, badges, API method colors, the syntax theme) aren't tokenized, so a non-default background clashes with fixed secondary colors.
- No way to override layout structure, replace header/footer/sidebar partials, change component markup, or add custom components. **This is the #1 competitive gap** — every competitor has *some* answer here.
- The "Powered by Stardust" footer is hardcoded and non-configurable (`page_layout_builder.dart:437-443`) — fine as a default, but paid/serious users will want it off.
- Header and footer social icons are the same giant SVG literals pasted twice (`page_layout_builder.dart:199-280`); version and locale dropdowns are the same widget pasted twice in HTML, twice in JS, twice in CSS.

**Fix direction**: emit shared `assets/styles.css` + `assets/app.js` once per site (with a small per-site `:root` token block), move CSS to real `.css` files (embed at compile time if single-binary matters), tokenize the palette, and design a minimal theming API (slots/partials or at least documented stable CSS parts).

### 5.2 The content pipeline is regex rewriting, not parsing (`lib/src/content/`)
The chain: protect code fences with `___CODE_N___` placeholders → protect a *hardcoded whitelist* of 14 component names → run markdown → restore components raw → fixpoint-loop lazy-regex transform per component → re-run markdown over six container types by manual `<div>` depth counting → regex-based syntax highlighting. Consequences:

- **Same-type nesting breaks** (`<Panel><Panel>…</Panel></Panel>` pairs the outer open with the inner close; the fixpoint loop then makes it worse).
- **Prefix collisions**: `<Accordion[^>]*>` matches `<AccordionGroup>`; `<Cards />` matches the self-closing `Card` pattern (no word-boundary after tag names, `markdown_parser.dart:132`).
- **Code fences inside components get transformed**: fences are restored *before* the component transformer runs, so a doc showing `<Info>` inside a code example inside a `<Tab>` gets rewritten into callout HTML inside the fence. For a tool whose own docs demo components in fences, this is a landmine.
- The fence-protection regex requires exactly `` ```lang\n `` — an info string (`` ```dart title="x" ``) or even a trailing space defeats protection (`patterns.dart:8`).
- The whitelist omits `Card`, `Api`, `Mermaid`, `Tree`, `Field`, embeds, etc. — top-level uses go through markdown unprotected.
- Attribute parsing: unquoted values (`cols=2`) silently become two boolean attributes; no escapes inside quoted values.
- **O(n²) scanners**: `attribute_parser.dart:78-96` and `markdown_parser.dart:169-173` allocate `content.substring(pos)` per character. Use `startsWith(needle, pos)` / `indexOf(needle, pos)`.
- Duplicate heading IDs across tabs; TOC links point into hidden panels. `base_component.dart:16-52` is dead code duplicating the transformer.

**Fix direction**: one tokenizer pass (text / fence / component-open / component-close) driving a small recursive-descent builder. The correct balanced-tag scanner *already exists* (`attribute_parser.dart:59-110`, `findBalancedTags`) — it's just only used for child extraction. Route everything through it, derive the protected-tag set from registered builders, and keep fences as placeholders *through* the component stage.

### 5.3 Escaping (cross-cutting)
`encodeHtml` (`lib/src/utils/html_utils.dart`) is used in ~3 places. Raw interpolation everywhere else: page titles into `<title>`, nav labels/hrefs, announcement HTML, sidebar labels, TOC text, prev/next titles, card `href` (no `javascript:` check), tab labels, API attributes, image `src`/`alt`, embed URL params (no `Uri.encodeQueryComponent`), analytics IDs, sitemap `<loc>` (no XML escaping), config strings into single-quoted JS (`page_scripts_builder.dart:342-347` — a French search placeholder with an apostrophe kills the entire search script). Also a DOM sink: image-zoom builds `innerHTML` from `data-zoom-src` (`page_scripts_builder.dart:225`).

**Fix direction**: a tiny HTML-builder layer (or discipline + review rule) that escapes by default, one JS-string escaper, one XML escaper. This is a day or two of focused work and removes an entire bug class.

### 5.4 Build performance architecture
- Everything is sequential `await` in loops — pages, OG images, asset copies. No `Future.wait`, no isolates.
- No incremental build: every change in dev re-parses and rewrites the entire site; a 500-page site means 1–5s per save plus 500 log lines per rebuild.
- OG image generation is pure-Dart per-pixel math over all 756k pixels per image (gradient + a full-image `sqrt` scan for the orb, `og_image_generator.dart:176-213`), run for every page on every production build with no skip-if-unchanged.
- Dev-server nits: search index built only at startup (new content never searchable until restart); config reload doesn't re-create watchers (changing `content.dir` keeps watching the old dir); custom CSS file not watched; static handler constructed per request; deleted pages never cleaned from dev output.

### 5.5 URL/basePath handling — four coexisting schemes
Relative `../..` base (Pagefind assets only), absolute `config.basePath` prefixing (most links), raw un-prefixed paths (version/locale dropdown items), and a url-derived basePath that **double-prefixes** OG image URLs (`page_meta_builder.dart:189`) while canonical/og:url ignore basePath entirely — one of the two is wrong for any subpath deployment. Unify into one resolver. Also: edit-link uses substring `indexOf(contentDir)` matching (`page_layout_builder.dart:368-370`) — breaks when the repo path contains "docs"; breadcrumbs synthesize links to intermediate pages that may not exist (404s, also emitted into BreadcrumbList JSON-LD).

---

## 6. Feature-by-feature verdicts

| Feature | Verdict |
|---|---|
| **Components (30+)** | Ambitious set; Accordion (native `<details>`), Tree, Callouts, Mermaid/Tooltip are well done. Tabs (non-deterministic IDs, own markdown path), Embeds (unencoded URL params), Api (all attributes unescaped) need work. |
| **Dark mode** | Works but FOUC on every load; `system` toggle first-click appears dead (`page_scripts_builder.dart:30-34`). |
| **Search (Pagefind)** | Right engine choice; unverified binary download, failures silently swallowed, no offline escape hatch, configured hotkey ignored by the JS (hardcoded ⌘K and `/`). The documented **Algolia provider doesn't exist** — setting `provider: algolia` renders a search button that does nothing (`page_scripts_builder.dart:275,310`). Documented `search: false` frontmatter exclusion is unimplemented. |
| **OpenAPI import** | Good skeleton, real gaps: `oneOf`/`anyOf` silently collapse to the first variant; nested object properties never rendered; path-level `parameters` dropped; `--group-by path` index links all 404; security schemes rendered as a bare name; no webhooks/servers/examples. Docs claim "from URL" import — there is zero HTTP handling in the command. Fine for toy specs, misdocuments real ones. |
| **OG images** | Nice differentiator; brutally slow implementation; needs a cache/skip. |
| **Versioning** | UI only — a dropdown and banner. No multi-version build orchestration (competitors: Docusaurus versioned docs, mike for MkDocs). Dropdown loses your current page and ignores basePath (`page_layout_builder.dart:133`); banner only renders in an edge-case-free happy path; `versions.default` is parsed but unused; the documented `build.outDir` workflow is dead config (§4.11). |
| **i18n (just committed)** | Honest "one build per locale" model, but shallow: no `--locale` flag, no fallback for untranslated pages (they 404), the locale dropdown drops you at the other locale's *root* and always marks the default locale active, hreflang tags are emitted for every locale × every page whether or not translations exist (SEO-negative). Two documented string keys (`toc.title`, `search.placeholder`) are dead — the renderers read the non-i18n config instead (`page_layout_builder.dart:57,349`). Docs recommend `cp stardust.en.yaml stardust.yaml` even though `build --config` already exists. |
| **Redirects** | The most solid feature: exact → meta-refresh pages, patterns → Netlify `_redirects` + `vercel.json`. Remaining: escaping and path-normalization bugs (§4.10), and pattern redirects silently no-op on GitHub Pages. |
| **llms.txt** | Docs claim "full content of each page in a single structured file" — actual output is a link index only (`site_generator.dart:344-396`). Documented `llm: false` frontmatter is unimplemented. Add per-page `.md` and `llms-full.txt` — cheap win, big AI-era story. |
| **Analytics** | Broad provider support; all IDs interpolated unescaped. |
| **CLI** | Only `init`/`dev`/`build`/`openapi`. Raw stack traces on YAML typos. `init` prints success even when everything failed, ships a broken `/configuration` link and a `.gitignore` that doesn't ignore `.stardust/`. Inconsistent flags (`-o` = output vs open). |

---

## 7. Missing features (roughly prioritized)

1. **Link checking / `stardust check`** — broken internal links are the #1 docs quality problem; a static generator that already knows every page can do this almost for free. Every serious competitor has it.
2. **Real theming/extensibility** — custom templates or slots, stable documented CSS tokens, custom components. Without this, anyone with brand requirements bounces.
3. **Real i18n + real versioned builds** — see §6. These are checkbox items enterprises filter on.
4. **Incremental dev rebuilds + shared static assets** — the "blazing fast" claim needs to survive a 500-page site.
5. **`stardust serve`** (preview `dist/` without watch) and **`stardust new <page>`**.
6. **Per-page `.md` export + `llms-full.txt` + "copy page as markdown"** — the AI-consumption bundle.
7. **Vendored icons/fonts, pinned versions** — make the offline/self-contained story true.
8. **Last-updated dates from git**, reading-time, page-level `og:image` override.
9. **Tabs/code-group sync** (choosing "npm" in one group switches all groups) + remembered choice — table stakes in Docusaurus/Material.
10. Later: RSS/changelog feed, API playground ("try it") for OpenAPI pages, plugin hooks, image optimization.

---

## 8. What's genuinely good (keep doing this)

- `FileSystem`/`Logger`/factory DI in `lib/src/core/` is clean and makes most of the codebase testable (Pagefind runner and `init` are the two holdouts that bypass it).
- Feature-per-PR discipline with tests and docs landing together.
- Pinned Pagefind version with a version file — reproducible tooling.
- `install.sh` verifies checksums for Stardust itself (extend the same rigor to Pagefind).
- The docs site (`docs/`) is real documentation, written like a product, and doubles as the test corpus.
- Choice of Pagefind over a hosted search service fits the product thesis.

---

## 9. Suggested order of attack

> **Note**: the canonical execution list is the **v0.5 "Trustworthy" table in [ROADMAP.md](ROADMAP.md) §3** — it absorbs this section's P0 and pulls two P1 items (config validation, dev-server fixes) forward as its rows 7–8. Work is being tracked and committed against that 8-item list.

**P0 — this week (safety & trust):**
1. Guard `--clean` deletion (`build_command.dart:80-83`).
2. Sweep escaping: HTML attr/text, JS strings, XML, JSON-LD `<` → `<`.
3. Fix dark-mode FOUC (blocking snippet in `<head>`; delete dead `dark-mode-*` class).
4. Pin `lucide` version; verify Pagefind checksums; propagate Pagefind failure to exit code.
5. Deterministic component IDs.
6. Reconcile docs with reality: either implement or un-document `build.outDir`, Algolia, `llm:`/`search:` frontmatter, OpenAPI-from-URL, llms.txt "full content", and the two dead i18n string keys. Users following official docs currently get silent wrong behavior.

**P1 — before the next feature (architecture):**
7. Shared `styles.css`/`app.js` assets instead of per-page inlining; move CSS out of Dart strings; dedupe version/locale dropdown code.
8. Rewrite component transform around `findBalancedTags` (tokenize once; fences protected through the whole pipeline; word-boundary tag matching).
9. One URL/basePath resolver; fix OG-image double-prefix vs canonical inconsistency.
10. Dev server: build-overlap guard, multi-client SSE (or plain websockets), fix content-length after injection, re-index search on rebuild.
11. Config validation layer with key-path errors + unknown-key warnings; generate/test the JSON schema from the same source so docs/schema/code can't drift.

**P2 — competitive features:**
12. `stardust check` (links), `serve`, `new`.
13. Make i18n real: per-locale build orchestration (a `--locale` flag or locale loop), fallback to default-locale content for untranslated pages, locale-preserving dropdown links, hreflang only for pages that exist.
14. Real versioned builds (even just "build N source trees into /vN/ with correct switcher links" would beat the current UI-only state).
15. llms-full.txt + per-page markdown export.
16. Parallelize page generation + OG images; incremental dev rebuilds; OG-image cache.
17. Tests for the untested surfaces: CLI commands, OpenAPI importer, Pagefind runner, config error paths; add a "every documented flag has a test" rule.

---

## 10. Config system, tests & docs

### Config validation: one loud failure, everything else silent or cryptic
- The **only** intentional validation in the whole config layer is the `name` check (`config_loader.dart:24-27`). Everything else either silently defaults or explodes with a raw Dart `TypeError`:
  - A wrong-typed *section* (`theme: "blue"`) silently falls back to all defaults, no warning (`theme_config.dart:16-28` and the same pattern everywhere).
  - A wrong-typed or missing *leaf* (`yaml['code'] as String` in `LocaleConfig.fromYaml`, `i18n_config.dart:76-81`; same in `VersionEntry`, `NavItem`, `AlgoliaConfig`) throws a bare `TypeError` with no key path, no file/line, no hint — surfaced to the user as a stack trace via `cli_runner.dart:47-50`. Same for YAML syntax errors.
  - No enum/range validation at runtime: `darkMode.default: purple`, `search.provider: elasticsearch`, `sitemap.changefreq: sometimes`, `redirect status: 999` are all silently accepted.
  - No unknown-key detection: `serach:` or `defualtLocale:` typos are silently ignored; `I18nStrings.fromYaml` explicitly drops unrecognized keys (`i18n_config.dart:131-140`).
  - No cross-field checks: `defaultLocale` needn't appear in `locales`; `versions.current` needn't appear in `list`.
- **Boilerplate duplication**: ~40 near-identical `fromYaml` factories, each restating every default from its constructor. `I18nStrings` states each of its 16 defaults **three times** (constructor, `_keyMap`, factory fallbacks). Two competing sources of truth for the same UI strings (`toc.title` vs `i18nStrings.tocTitle` — and the i18n variant is the dead one).
- **Schema/code drift** (schema uses `additionalProperties: false`, so drift = false errors in editors): `build.basePath` exists in code but not the schema; sidebar page `icon` supported in code, rejected by schema; `content.include` and `code.theme` defaults differ between the two; schema advertises `search.provider: custom` which nothing implements. The JSON schema is pure editor tooling — the loader never consults it.

**Fix direction**: one validation layer that walks the YAML with key-path-aware errors ("`theme.darkMode.default` must be one of light|dark|system, got 'purple' (line 12)"), warns on unknown keys, and generates or tests the JSON schema from the same definitions so the three artifacts can't drift.

### Test suite
- **757 tests, all pass in ~4s.** Real breadth for a project this size, and feature PRs consistently include tests. Credit where due.
- But the style is overwhelmingly **string-contains assertions on generated HTML** (`page_layout_builder_test.dart` alone: 169 `contains(` calls). Brittle to markup refactors, blind to structural validity — nothing ever parses the output or checks well-formedness. Exactly the escaping/nesting bug classes documented above sail through.
- **Error paths are near-untested**: two error tests exist in the entire config suite (missing/empty `name`). The raw-TypeError failure behavior is untested and unowned.
- **Zero coverage** for `lib/src/cli/` (all four commands), `openapi_importer.dart` (892 lines), and `pagefind_runner.dart` — the entire CLI surface and both external integrations.
- Good spots: `redirect_generator_test.dart` and `og_image_generator_test.dart` exercise real file output through the mock filesystem; `site_generator_test.dart` covers drafts/excludes/toggles.

### Docs vs code: three diverging truths
A recurring pattern: docs are written aspirationally, and nothing reconciles docs ↔ schema ↔ code. Confirmed doc claims with no implementation behind them:
- `build.outDir` (the multi-version/multi-locale workflow keystone) — parsed, never read (§4.11).
- llms.txt "full content" — it's a link index.
- `llm: false` and `search: false` frontmatter exclusions.
- Algolia search provider.
- OpenAPI import "from URL".
- i18n string keys `toc.title` / `search.placeholder` — dead code.

Each of these is a user following official docs and getting silent wrong behavior. Before adding features, an "every documented flag has a test that exercises it" rule would pay for itself immediately.

### Development history
Burst-mode: v0.3.3 → v0.4.0 shipped in a 10-day sprint in late January (redirects, analytics, sidebar work, custom CSS, header/footer, versioning UI), then a ~5.5-month gap, then i18n landed today as a single 917-line commit. The PR discipline (feature + docs + tests per branch) is good; the aspirational-docs habit is the thing to break.

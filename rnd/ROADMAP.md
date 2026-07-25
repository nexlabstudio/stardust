# Stardust Feature Roadmap

*Drafted 2026-07-18 against `dev`. Companion to [PROJECT_REVIEW.md](PROJECT_REVIEW.md), which holds the file-level evidence for every "partial/broken" claim below. Competitor facts in this document were verified against live sources (changelogs, repos, pricing pages) on 2026-07-18 — see §2a for what changed in the market recently.*

**Thesis**: Stardust wins as the docs generator you can trust for the next ten years — a single native binary that turns markdown into beautiful, fully self-contained static HTML. No Node, no Python, no hosted service in the serving path, works air-gapped. The two audiences, in order: (1) Dart/Flutter package authors (underserved, already have Dart, currently defaulting to docs.page), (2) anyone burned by JS-toolchain docs rot who wants Mintlify aesthetics without Mintlify's SaaS.

---

## 1. Where we stand

### ✅ Have and working
| Feature | Notes |
|---|---|
| Markdown + frontmatter pipeline | Solid happy path |
| 30+ components (callouts, tabs, steps, cards, accordions, code groups, trees, mermaid, embeds, API blocks…) | Breadth beats VitePress/mdBook already; parser fragility is the risk (see review §5.2) |
| Syntax highlighting + copy button + line numbers | |
| Dark mode | Real (localStorage + system pref); has a FOUC bug |
| Full-text search (Pagefind) | Right engine; binary download is SHA-256-verified; configured hotkey wired; `search: false` frontmatter excludes a page from the index |
| OG image generation | Differentiator — Docusaurus needs a plugin for this; slow implementation |
| Sitemap, robots.txt, canonical/OG/Twitter meta, JSON-LD | |
| Redirects (exact + Netlify/Vercel pattern files) | Most solid feature in the codebase |
| Analytics (GA4, Plausible, Fathom, custom…) | |
| Header/footer/announcement bar, mobile drawer, collapsible sidebar groups | |
| Edit-on-GitHub links, custom CSS file | |
| Dev server with live reload | Full rebuilds only; SSE single-client bug |
| `stardust init` scaffold | Ships a broken link and wrong .gitignore, but exists |
| Distribution: brew, scoop, choco, snap, curl, pub.dev, 5 platform binaries | Genuinely ahead of the market for a v0.x |
| Link checking (`stardust check`) | Broken links/anchors, missing images, duplicate slugs, orphaned sidebar entries; `check: false` opt-out; runs in our own CI |
| Versioned builds (`stardust build --all-versions`) | Each version from a directory **or git tag**, path-prefixed output, page-preserving switcher, per-version sidebar + search, `noindex`/sitemap/robots/root-redirect handled |
| Real i18n | One `stardust build` → all locales routed under `/es/`; translations by subdirectory (`docs/es/`) **or** suffix (`guide.es.md`); untranslated pages fall back to the default with a notice; locale-preserving switcher, per-locale `lang`/`dir`/sidebar/search/hreflang. Composes with versioning (`/v1/es/`, both switchers preserve the other axis) |
| Landing/splash page | `layout: splash` → sidebar-less full-width page with a frontmatter-driven hero (title, tagline, CTA buttons, image) + `<Button>` component; our own homepage uses it |
| Theming v1 | Config-driven design tokens (`theme.tokens`/`tokensDark`), `footer.poweredBy: false`, HTML slots for header/footer/sidebar. Not full override/eject — see [THEMING_SPEC.md](THEMING_SPEC.md) for v2 |
| Page metadata | Reading time + last-updated + contributors from a single `git log` pass (repo-root resolved via `rev-parse`, so monorepo-safe); `pageInfo` toggles; live on our own docs |
| Synced + persisted tabs/code-groups | Opt-in `group="…"` on `<Tabs>`/`<CodeGroup>`; same-group blocks switch together (matched by tab label) and the choice persists across pages via `localStorage`; ungrouped blocks stay independent |
| LLM-friendly output | `llms.txt` index + `llms-full.txt` full content + per-page `.md` twin + "Copy page as Markdown" button; `llm: false` frontmatter opts a page out |
| Official GitHub Action | Composite action: checksum-verified install, `stardust check` + build, outputs the built dir; PR-preview recipes for Netlify/Vercel/Cloudflare Pages. Ships with the `v0.7.0` release |

### ⚠️ Have on paper — partial, broken, or documented-but-unimplemented
| Feature | Reality |
|---|---|
| Algolia search provider | Config parses `provider`, and the search button renders whenever search is enabled — but the modal JS only initializes for `pagefind`, so `provider: algolia` yields a dead button |
| OpenAPI import | Imports from a file **or URL**; resolves `$ref`/`allOf` and the first `oneOf`/`anyOf` variant. Still lossy on deeply combined schemas and shared path-level parameters |
| Theming — full override | v1 shipped (tokens, `poweredBy`, slots); no partial/template replacement, `eject`, or component override yet (spec'd: [THEMING_SPEC.md](THEMING_SPEC.md)) |
| Offline/self-contained output | Lucide icons are now vendored/inlined; Mermaid is a pinned `@10.9.6` CDN load with SRI + a self-host option; **Google Fonts still loads from the CDN** by default |

### ❌ Don't have (and at least two major competitors do)
- **Theming API — full override**: template/partial overrides, custom components (tokens + slots shipped in v1; the rest is [THEMING_SPEC.md](THEMING_SPEC.md))
- **Plugin/extension system** (Docusaurus, MkDocs, Starlight)
- **Cut-a-version command** (`docs:version` in Docusaurus, `mike deploy`, Starlight's auto-archive) — we make you create the dir or tag by hand
- **Cross-version search** (Rspress searches across versions; ours is per-version only)
- **Incremental / cached builds** (Docusaurus, Hugo)
- MCP server for the docs (Mintlify, docs.page v2) — note `llms-full.txt`, per-page `.md`, and the "Copy page as Markdown" button already ship
- **API playground** ("try it" on OpenAPI pages) (Mintlify, Redocly)
- Image pipeline: resize/optimize/responsive `srcset` — lazy-load and zoom ship, but there's no image *processing* (Docusaurus/Starlight via ecosystem)
- Feedback widget ("Was this page helpful?") (Mintlify, GitBook)
- RSS / changelog feed (Docusaurus blog, GitBook)
- Shell completions; a11y/keyboard-nav audit; local font hosting

---

## 2. Competitive feature matrix

*Verified against live sources 2026-07-18; versioning rows re-verified 2026-07-21.* `✅` solid `⚠️` partial `❌` missing

| Capability | **Stardust** | Mintlify | Docusaurus 3.10 | MkDocs Material | Starlight | docs.page v2 | mdBook 0.5 | Rspress 2.0 |
|---|---|---|---|---|---|---|---|---|
| No JS/Python toolchain | ✅ | ❌ | ❌ | ❌ | ❌ | ✅* | ✅ | ❌ |
| Static output you own | ✅ | ⚠️ Enterprise-only export | ✅ | ✅ | ✅ | ❌ (no export; issue open since 2022) | ✅ | ✅ |
| Works fully offline/air-gapped | ⚠️ CDN leaks | ⚠️ zip export; search/AI dead offline | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Beautiful default theme | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ (shadcn presets in v2) | ❌ | ✅ |
| Rich components | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ⚠️ (0.5 added admonitions) | ✅ |
| Full-text search | ✅ | ✅ | ✅ (+AskAI) | ✅ | ✅ | ✅ (FlexSearch, ⌘K — new in v2) | ✅ | ✅ |
| Theming/extensibility API | ⚠️ (tokens + slots; no override/eject yet) | ⚠️ | ✅ | ✅ | ✅ | ⚠️ (presets, no custom CSS) | ⚠️ (0.5 stable extension API) | ✅ (4-tier) |
| Versioned docs builds | ✅ (dirs **or git tags**) | ✅ | ✅ (snapshots) | ⚠️ mike; one deploy per version | ⚠️ community plugin, "early development" | ❌ (issue open since 2023; `~ref` URLs only) | ❌ | ✅ (built-in `multiVersion`) |
| i18n (routed, translated builds) | ✅ (subdir **or** suffix; fallback + notice) | ✅ | ✅ | ✅ | ✅ | ✅ (locale sidebars + switcher) | ❌ | ✅ |
| Link checking / content validation | ✅ (`stardust check`) | ✅ | ✅ built-in | ⚠️ strict mode | ⚠️ community | ✅ (`docs check` in v2 CLI) | ⚠️ third-party | ✅ |
| OpenAPI docs | ⚠️ | ✅ | ⚠️ community | ⚠️ community | ⚠️ community | ❌ (explicitly punts to Mintlify) | ❌ | ✅ (fumadocs-class) |
| API playground | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ |
| llms.txt + llms-full + per-page .md | ✅ (index + full + per-page `.md` + copy button) | ✅ | ⚠️ community plugin | ⚠️ community | ⚠️ community | ✅ (v2, built-in) | ❌ | ✅ (built-in "SSG-MD") |
| MCP server for the docs | ❌ | ✅ auto per site | ❌ | ❌ | ❌ | ✅ (v2, on by default) | ❌ | ❌ |
| OG image generation built in | ✅ | ✅ | ⚠️ plugin | ✅ (now free) | ⚠️ | ✅ | ❌ | ⚠️ |
| Versioning + i18n **without CI gymnastics** | ✅ (one binary, git-tag sourced) | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ❌ | ✅ (versions × locales built in) |
| Instant setup (no install) | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |

\* docs.page needs no local toolchain but is hosted-only, **public GitHub repos only**, rendered at request time by their infra; custom domains require manually filing an issue.

### 2a. Field check — what actually changed in the market (verified 2026-07-18)

1. **docs.page shipped v2.0.0 on 2026-07-03** — a full rewrite pivoting to "AI-ready docs": per-repo MCP server (on by default), llms.txt/llms-full.txt, Ask AI (BYO LLM key), agent skills, built-in FlexSearch with ⌘K palette, Mermaid, shadcn theme presets, `docs check`. What it *still* lacks, confirmed via their own issues/comparison pages: versioning (open since 2023), OpenAPI (they explicitly recommend Mintlify), static export/self-hosting (open since 2022), private repos, self-serve custom domains. Confirmed Dart-ecosystem users: Melos, Jaspr, Widgetbook, home_widget.
2. **llms-full.txt + per-page markdown is now table stakes, not a differentiator.** Built into docs.page v2, Fumadocs, Rspress 2.0, Mintlify, GitBook (all plans); mature community plugins for Docusaurus/VitePress/Starlight (VitePress's plugin is used by Vue, Vite, and Vitest's own docs). Our roadmap had this in v0.8 — **moved to v0.6**.
3. **A per-docs-site MCP server is the new arms race** (Mintlify, GitBook, docs.page, Fumadocs all shipped one). Nobody offers it for *pure static, self-hosted* sites — an opening for us (§v0.8).
4. **MkDocs Material entered maintenance mode** (last feature release Nov 2025; all Insiders features made free; team building **Zensical**, a Rust-core successor claiming millisecond differential builds, currently alpha). Its huge install base must eventually migrate — a real window, but Zensical is the anointed heir, and it attacks our exact "fast native binary" positioning.
5. **Rspress 2.0** (ByteDance, Jan 2026) is a new serious player: AI-native output built in, a 4-tier theming model (CSS vars → class overrides → component swap → eject) that is the pattern our theming v1 should copy, ~50ms dev cold-start claims. Also **seite** — an early single-binary Rust SSG with llms.txt and agent-authoring built in — proof others see the same "native binary + AI-ready" gap.
6. **Mintlify now has offline zip export and Enterprise static export/self-hosting** — the "own your output" argument vs Mintlify only fully applies below Enterprise tier now. Docusaurus's "Faster" build stack went stable (3.10, final v3 minor; v4 in planning). VitePress v2 still alpha with no timeline; both remain Node-toolchain-bound, which keeps our core wedge intact.

7. **Versioning re-check (2026-07-21), against primary docs.** Two corrections to the row above: **Rspress 2.0 has built-in `multiVersion`** (directory-sourced, automatic version prefixing, per-version `_nav.json`, versioned search with an *optional cross-version* mode, and versions × locales together) — it was understated as ⚠️ and is now the closest rival on versioning mechanics. **MkDocs+mike is one deploy per version**, not one command, though it *does* preserve the current page on switch and *does* create a root redirect via alias. Confirmed unchanged: docs.page has no version switcher (only `~ref` URLs), Starlight's `starlight-versions` remains community and self-describes as "early development", mdBook has none, and **no competitor sources a version from a git tag** — that stays ours alone. Nobody but us bundles the SEO layer (banner + `noindex` + sitemap exclusion + single root robots.txt + root redirect) by default.

**Reading the board**: Stardust still ties or wins on *output* (theme, components, search, OG, distribution) and the ownership/offline wedge got *stronger* (docs.page v2 doubled down on hosted-only). Three orchestration gaps closed since this was drafted — **link checking, versioned builds, and real i18n all shipped**, including the version × i18n composition — so what remains is theming API, plugins, and incremental builds. On versioning + i18n we now match Rspress on the matrix while being the only option that needs no Node/Python and can source a version from a git tag; the residual gaps are cut-a-version and cross-version search. Sequencing: make the output trustworthy → close orchestration gaps **and AI baseline** → differentiate on what nobody in the no-toolchain space has (versioning, OpenAPI, dartdoc, static-friendly MCP).

---

## 3. Roadmap

### v0.5 — "Trustworthy" (safety + honesty) · ~2–3 weeks
*Goal: nothing Stardust ships can hurt a user, and every documented flag works. This unblocks recommending it publicly.*

| # | Item | Size |
|---|---|---|
| 1 | Guard `build --clean` deletion (refuse cwd/ancestors; only clean dirs Stardust created) | S |
| 2 | Escaping sweep: HTML/attr, JS-string, XML, JSON-LD `<` — escape-by-default helpers used everywhere | M |
| 3 | Dark-mode blocking snippet in `<head>` (kill FOUC); remove dead `dark-mode-*` class | S |
| 4 | Pin `lucide` version; verify Pagefind checksums; fail the build when indexing fails | S |
| 5 | Deterministic component IDs (per-page counter, not `DateTime.now()`) | S |
| 6 | **Docs/code reconciliation**: implement or un-document `build.outDir`, Algolia, `llm:`/`search:` frontmatter, OpenAPI-from-URL, llms.txt "full content", dead i18n keys | M |
| 7 | Config validation layer: key-path errors ("`theme.darkMode.default` must be light\|dark\|system"), unknown-key warnings, no more raw TypeErrors/stack traces | M |
| 8 | Fix dev server: build-overlap guard, multi-client reload, content-length after injection | M |

**Exit criteria**: a hostile markdown file can't produce script injection; a user following any docs page verbatim gets the documented behavior; `dart test` covers config error paths.

### v0.6 — "Solid Core" (architecture that scales) · ~4–6 weeks
*Goal: output and pipeline quality that survives a 500-page site and a designer's scrutiny.*

| # | Item | Size |
|---|---|---|
| 1 | **Shared static assets**: emit `assets/styles.css` + `assets/app.js` once per site instead of inlining ~67KB into every page | M |
| 2 | Move CSS out of Dart strings into real `.css` files (embedded at compile time to keep the single binary); tokenize the hardcoded palette; dedupe version/locale dropdown code | L |
| 3 | **Parser rewrite**: single tokenizer pass (text/fence/component) + recursive descent via the existing `findBalancedTags`; fences protected end-to-end; word-boundary tag matching; derive protected tags from registered builders | L |
| 4 | One URL/basePath resolver (fixes OG double-prefix, un-prefixed dropdown links, subpath deploys) | M |
| 5 | **Vendor everything**: bundle Lucide icons (inline SVG at build time), local Mermaid opt-in, self-hosted font option — make "works air-gapped" literally true | M |
| 6 | Parallelize page generation and OG images (`Future.wait`/isolates); OG cache (skip unchanged); incremental dev rebuilds (only re-render changed pages) | M |
| 7 | `stardust serve` (preview dist/), `stardust new <slug>`, `stardust clean`; consistent flags; friendly error surface | S |
| 8 | **AI-ready output baseline** *(moved up from v0.8 — the market made it table stakes in 2026)*: `llms-full.txt`, per-page `page.md` alongside `page/index.html`, "Copy page as Markdown" button, `llm: false` respected | M |

**Exit criteria**: 500-page site builds < 2s cold and < 200ms on a single-file change in dev; total dist size scales ~linearly with *content*, not page count × 67KB; docs render correctly with network unplugged; an AI agent can consume any Stardust site as clean markdown.

> **Status (2026-07-19)**: items 1–8 shipped, with one explicit carve-out: the *palette tokenization* half of item 2 is deferred to its own pass (bulk-replacing ~40 paired light/dark hex literals with variables needs per-rule visual review; the CSS extraction made that work tractable). Exit criteria measured on a synthesized 500-page site: warm build 355ms ✅, single-file dev rebuild 173ms ✅, linear dist scaling ✅, air-gapped rendering ✅, markdown consumption ✅; **first-ever cold build 6.3s ❌** — the miss is OG rendering 500 images once (every later build hits the cache). Tracked as debt item D1 below.

### v0.7 — "Table Stakes" (the checkbox features teams filter on) · ~6–8 weeks
*Goal: stop losing evaluations to Docusaurus/MkDocs on the comparison-table round.*

| # | Item | Size |
|---|---|---|
| 1 | **`stardust check`**: broken internal links/anchors, orphaned sidebar entries, missing images, duplicate slugs, frontmatter schema violations. Run it in our own CI. Exit non-zero for CI use | M |
| 2 | **Real versioning**: `stardust build --all-versions` reads a versions manifest (source dir or git tag per version), builds each into `/vN/`, generates a version-aware switcher that preserves the current page, correct banners + `noindex` on old versions | L |
| 3 | **Real i18n**: locale-suffixed content discovery (`page.es.md` or `docs/es/`), one build → all locales routed under `/es/`, fallback to default locale for untranslated pages (with "not yet translated" notice), locale-preserving switcher, hreflang only for pages that exist, per-locale sidebar labels | L |
| 4 | Synced + persisted tabs/code-groups (`group="pkg-manager"`) | S |
| 5 | Last-updated + contributors from git; reading time; page-level `og:image`/frontmatter overrides | S |
| 6 | Theming v1: documented, stable CSS custom-property tokens for the full palette (the v0.6 tokenization made this possible); `theme.footer.poweredBy: false`; slot-level overrides for header/footer/sidebar HTML | M |
| 7 | Official **GitHub Action** (`stardust-build@v1`: install pinned binary, build, check) + PR-preview recipes for Netlify/Vercel/Cloudflare Pages | S |
| 8 | **Landing/splash page**: `layout: splash` frontmatter → sidebar-less full-width template with a frontmatter-driven hero (title, tagline, CTA buttons, optional image); reuse existing `<Cards>` for the feature grid. Full spec: [LANDING_SPEC.md](LANDING_SPEC.md). Both flagship Dart-ecosystem docs sites (bloclibrary.dev, kaisel.dev) are exactly this (Starlight `template: splash`); most of the work (cards) already ships | S |

**Exit criteria**: the §2 matrix rows "versioned builds", "i18n", "link checking" flip to ✅; a Docusaurus user can migrate without losing a feature they use; a Stardust site can present a product homepage matching bloclibrary.dev / kaisel.dev.

> **Status (2026-07-24)**: items 1–3 shipped; **all three exit-criteria matrix rows have flipped** ("link checking", "versioned builds", "i18n"). Item 2 went beyond the spec (git-tag sourcing, per-version sidebars, full SEO layer). Item 3 delivered both translation layouts (subdirectory **and** `guide.es.md` suffix), untranslated fallback + notice, per-locale `lang`/`dir`/sidebar/search/hreflang, **and the versioning × i18n composition** (`/v1/es/`, both switchers preserve the other axis) — which also flips the "Versioning + i18n without CI gymnastics" row. A supporting refactor made the generator read content through the `FileSystem` abstraction, paying down the "site_generator glob" debt. Remaining i18n-adjacent gaps (out of item 3's scope): cut-a-version command, cross-version search, and version-prefixed hreflang on old (noindex) versions.
>
> **Also shipped**: item 8 (landing/splash page — `layout: splash` + hero + `<Button>`, now live on our own homepage) and item 6 (Theming v1 — config tokens, `footer.poweredBy: false`, HTML slots). Both exit criteria are now met: the three matrix rows flipped, *and* a Stardust site can present a product homepage. Full theming (partial/template override + `eject` + component templates) is deferred to a v0.8 "Theming v2" item, spec'd in [THEMING_SPEC.md](THEMING_SPEC.md). Item 5 (git metadata) also shipped — reading time + last-updated + contributors from one `git log` pass (`rev-parse`-resolved root, so it's monorepo-safe), plus the note that page-level `og:image`/frontmatter overrides already existed. At this point items 4 (synced tabs) and 7 (GitHub Action) remained — both S.
>
> **Status (2026-07-25)**: **v0.7 is feature-complete — all eight items shipped.** Item 4 (synced + persisted tabs/code-groups) landed last: an opt-in `group="…"` on `<Tabs>`/`<CodeGroup>` switches every same-group block together, matched by tab **label** (not index), and persists the choice across reloads and pages via `localStorage`; ungrouped blocks stay independent. The two duplicate client tab handlers were unified into one, and the pre-existing "tabs auto-sync" claim in the docs — previously documented-but-unimplemented — was corrected to the real `group` opt-in. Item 7 (GitHub Action) is done and merged; it ships with the `v0.7.0` release (it installs the latest release binary, so it goes live the moment the tag lands — which is the immediate next step). Item 5's git-metadata pass also picked up follow-on hardening (content-scoped `git log`, parse overlapped with markdown parsing, graceful when `git` is absent).

### v0.8 — "The Wedge" (features that win our two audiences) · ~6–8 weeks
*Goal: give Dart/Flutter authors and AI-era teams a reason to pick Stardust specifically, not just tolerate it.*

| # | Item | Size |
|---|---|---|
| 1 | **Static-friendly MCP**: every major platform now auto-generates an MCP server for hosted docs (Mintlify, GitBook, docs.page v2, Fumadocs) — but *nobody* offers it for pure static self-hosted sites. Ship (a) `stardust mcp` — the same binary serves any built site over MCP locally/on-prem, and (b) a generated static manifest + `.md` endpoints so remote agents can consume the site without any server of ours. On-brand: the binary you already have becomes the AI gateway, air-gap included | M |
| 2 | **dartdoc integration**: `stardust dartdoc` imports a Dart package's API docs into the site with Stardust styling and unified search — guides + API reference in one place. *No competitor can do this — docs.page v2 still has no versioning or OpenAPI and punts API docs to Mintlify; this is the kill shot for package authors* | L |
| 3 | **DartPad embeds**: `<DartPad id="...">` / runnable Dart+Flutter snippets — the Flutter community's favorite docs feature | S |
| 4 | OpenAPI depth: render `oneOf`/`anyOf` unions, nested object schemas, path-level params, security schemes properly, examples; import from URL; fix path-mode index links | M |
| 5 | **API playground**: "try it" panel on OpenAPI pages (fetch from the browser, auth header input). Static-host friendly — no backend. Only Mintlify (paid) and Rspress (partial) have this; nobody in the no-toolchain space does | L |
| 6 | Feedback widget ("Was this helpful?" → configurable endpoint/GitHub issue) | S |
| 7 | Image pipeline: build-time resize/encode (we already ship the `image` package for OG), lazy-loading, dimensions to kill CLS | M |

**Exit criteria**: a Flutter package can replace docs.page + dartdoc with one `stardust` command; a Claude/Cursor user can connect to any Stardust site's docs in two clicks without the site owner running a service.

### v1.0 — "Platform" (commit to stability) · when the above is real
- **Compatibility promise**: stable config schema (migrations for breaking changes), stable CSS tokens, stable component syntax.
- **Extensibility**: custom component definitions (user templates mapped to tags — no JS runtime required), pre/post build hooks, and *then* evaluate a full plugin API against real demand.
- A11y audit (keyboard nav, focus traps in search modal, ARIA on tabs/accordions) + Lighthouse ≥ 95 on all four scores as a CI gate.
- Benchmarks page: build-time and page-weight comparisons vs Docusaurus (Faster/Rspack), Rspress, and **Zensical** — the speed claim now has native-speed competitors and must be *measured*, not asserted. Incremental/differential builds (v0.6) are a prerequisite for winning this comparison.
- Showcase + migration guides with converters where feasible: "from docs.page" (config is similar, audience overlaps), "from Docusaurus", "from GitBook" — and **"from MkDocs Material"**, which entered maintenance mode in Nov 2025; its install base must migrate somewhere in the next few years, and Zensical (its official successor) is still alpha. That's a live migration window.

### Post-1.0 candidates (demand-driven, not committed)
- RSS/changelog feed component; `Update` timeline improvements
- Algolia DocSearch as a *real* provider (or remove it forever)
- Hosted preview service or "stardust deploy" (careful: don't become the SaaS we're differentiating against)
- Multi-sidebar / product-tabs IA for large multi-product sites
- PDF/single-page export (enterprise/compliance ask, pairs with air-gapped story)

---

## 3b. Tracked debt (deferred deliberately — not forgotten)

Small items descoped from shipped milestones. Each carries its origin so the descope reasoning isn't lost. Pull them into a milestone when adjacent work makes them cheap, or when one starts hurting.

| # | Item | Origin | Why deferred |
|---|---|---|---|
| D1 | Optimize OG pixel drawing (gradient/orb loops in `og_image_generator.render`) — the 500-page *first-ever* cold build is 6.3s vs the 2s target | v0.6 item 6 | Cache makes it a once-per-site cost; needs profiling of `package:image` primitives |
| D2 | Palette tokenization: replace ~40 paired light/`.dark` hex literals in `assets/css/` with theme variables | v0.6 item 2 | Needs per-rule visual review to avoid dark-mode regressions; extraction to real CSS made it tractable |
| D3 | Dev server: re-create watchers when `content.dir` changes in config; watch `theme.custom.cssFile` | v0.5 item 8 | Rare edge; restart covers it |
| D4 | CLI `dart:io` DI debt: ~10 files in `lib/` bypass the `FileSystem`/`Logger` abstractions (see CLAUDE.md) | rules audit | Proper fix threads abstractions through all commands — belongs with the v0.7+ CLI test-coverage work |
| D5 | Container second-pass still double-renders markdown in component output (`_processContainersOfType` design) | v0.6 item 3 | Correct behavior preserved by the rewrite; a single-render design is a deeper builder-contract change |
| D6 | `stardust build` parse pipeline: residual superlinearity above ~100KB/page inside `package:markdown` | v0.6 item 3 | Real pages are 5–30KB; upstream package behavior |

## 4. Non-goals (saying no is part of the roadmap)
- **No JS component runtime (MDX/React/Vue).** The moment we ship one, we're a worse Docusaurus. Custom components stay declarative (templates + tokens).
- **No hosted rendering service in the core path.** PR previews come from CI recipes, not from us serving docs.
- **No plugin marketplace before a plugin API has ≥3 real internal consumers** (dartdoc import, OpenAPI, link check should be built on the hooks we'd expose).
- **No new components** until the parser rewrite (v0.6) lands — every component added on the regex pipeline is new surface area on a cracked foundation.

## 5. Sequencing logic, in one paragraph
Trust before scale, scale before checkboxes, checkboxes before wedge. Shipping dartdoc integration (v0.8) on today's parser would demo well and collapse under real packages; shipping versioning (v0.7) before the URL resolver (v0.6) would double the basePath bug surface; marketing "AI-ready" while the llms.txt docs still overpromise (fixed in v0.5, baseline shipped in v0.6) would burn credibility with exactly the early adopters we need. The July 2026 field check moved one thing: AI-ready output is no longer a wedge, it's an entry fee — so it ships with the core (v0.6), and the wedge proper becomes what no one in the no-toolchain space has: real versioning + OpenAPI (v0.7–0.8), dartdoc/DartPad for the Dart beachhead, and MCP for static sites (v0.8). Each phase makes the next one cheap.

# Search v2 — Custom Pagefind UI Spec

*Drafted 2026-07-19. Replaces the PagefindUI widget (and its Starlight-derived styling) with an original search UI built on Pagefind's raw `pagefind.search()` API.*

## 1. Goal

Own the entire search experience: our DOM, our class names, our CSS, our icons, our keyboard model. Two outcomes:

1. **Independence** — nothing is copied from Astro Starlight. No shared selectors, no `--search-*` scale, no embedded SVG masks. Result: the `THIRD_PARTY_NOTICES.md` Starlight entry and the `17-pagefind.css` port are deleted, honestly.
2. **Exceed the widget** — real arrow-key result navigation (the ARIA combobox pattern), which `PagefindUI` structurally cannot do because its result DOM is compiled Svelte.

### Non-goals (v2)
- Filters/facets UI (the API supports it; defer until a real need).
- Cross-site `mergeIndex`.
- Changing how the index is built — we keep running Pagefind at build time exactly as now; only the browser consumption changes.

## 2. Architecture

The widget (`pagefind-ui.js` + `pagefind-ui.css`) is dropped entirely. In its place, a self-contained controller script (emitted by `buildSearchModal`) that:

1. Lazy `import()`s the raw module `pagefind/pagefind.js` on first modal open.
2. Calls `pagefind.options({ baseUrl })` for subpath deploys, then `pagefind.init()` to warm the index.
3. Debounced-searches on input, resolves `data()` for the visible page-window, and renders **our** markup.
4. Runs a keyboard controller over a flat list of `role="option"` elements.

The native `<dialog>` chrome, trigger button, `::backdrop`, body-scroll-lock, and `overscroll-behavior: none` from the current implementation are **kept** — those are ours already and work.

## 3. Pagefind raw API contract (the facts we depend on)

Confirmed against Pagefind v1.x docs + TS defs. These are the only external surfaces we couple to:

```js
const pagefind = await import("<basePath>/pagefind/pagefind.js");   // ES module; Pagefind 1.4.0 emits pagefind/
await pagefind.options({ baseUrl: "<basePath>/", excerptLength: 30 });
await pagefind.init();                                               // optional; warms WASM+index
pagefind.preload(term);                                              // on focus/keystroke
const res = await pagefind.debouncedSearch(term, {}, 250);           // null if superseded
// res.results: [{ id, score, words, data: () => Promise<Fragment> }]
const d = await result.data();
```

`Fragment` fields we use:
- `d.url` — already prefixed with `baseUrl`.
- `d.meta.title` — page title (first h1); `d.meta` is a flat `Record<string,string>`.
- `d.excerpt` — **HTML with `<mark>` tags**; surrounding text is entity-encoded by Pagefind, so it is safe to assign via `innerHTML`.
- `d.sub_results[]` — `{ title, url (includes `#anchor`), excerpt }`. First entry is usually the page itself.

Path note: Pagefind 1.4.0 emits `pagefind/` (no underscore — verified in build output), so we import `pagefind/pagefind.js`. (An earlier draft wrongly assumed `_pagefind/`, which caused a deploy-time 404.) `buildPagefindStyles`' `pagefind-ui.css` `<link>` is removed — the raw API needs no widget CSS.

## 4. DOM contract

All classes are `sd-search__*` (ours). Icons are our vendored Lucide SVGs injected at **build time** via `getLucideIcon(...)` in Dart (`search`, `x`, `file-text`, `corner-down-right`) — no runtime icon loading, no third-party masks.

```html
<dialog id="search-modal" class="search-modal" aria-label="{placeholder}">
  <div class="sd-search">
    <div class="sd-search__box" role="combobox" aria-expanded="false"
         aria-owns="sd-search__results" aria-haspopup="listbox">
      {lucide:search}
      <input class="sd-search__input" type="search" autocomplete="off" spellcheck="false"
             role="searchbox" aria-controls="sd-search__results"
             aria-activedescendant="" placeholder="{placeholder}">
      <button class="sd-search__clear" type="button" aria-label="{clearLabel}" hidden>{lucide:x}</button>
    </div>
    <div class="sd-search__status" role="status" aria-live="polite"></div>
    <ul id="sd-search__results" class="sd-search__results" role="listbox" aria-label="Search results"></ul>
    <button class="sd-search__more" type="button" hidden>{loadMoreLabel}</button>
  </div>
</dialog>
```

Rendered per page result (built by the controller):
```html
<li class="sd-search__group">
  <a class="sd-search__page" role="option" id="sd-r-0" href="{d.url}" tabindex="-1">
    {lucide:file-text}
    <span class="sd-search__page-title">{d.meta.title}</span>
  </a>
  <ul class="sd-search__subs">
    <li>
      <a class="sd-search__sub" role="option" id="sd-r-0-1" href="{sub.url}" tabindex="-1">
        {lucide:corner-down-right}
        <span class="sd-search__sub-title">{sub.title}</span>
        <p class="sd-search__excerpt"><!-- sub.excerpt via innerHTML --></p>
      </a>
    </li>
  </ul>
</li>
```

`role="option"` elements are the page link **and** each sub-result link, in visual order — that flat sequence is what the keyboard controller walks.

## 5. Keyboard / interaction state machine

The differentiator. Controller keeps `options = [...all role=option els in DOM order]` and `activeIndex ∈ [-1, options.length)`.

| Key | Action |
|---|---|
| `ArrowDown` | `activeIndex = min(activeIndex+1, last)`; if was -1 → 0 |
| `ArrowUp` | `activeIndex = max(activeIndex-1, 0)`; if -1 → last (wrap to bottom) |
| `Home` / `End` | first / last option |
| `Enter` | if active → navigate to `options[activeIndex].href`; else no-op |
| `Escape` | `dialog.close()` (native also fires) |
| printable / `Backspace` | reset `activeIndex = -1`, re-search |
| mouse `mouseover` on an option | sync `activeIndex` to it (no scroll) |

On every `activeIndex` change: toggle `.is-active` on the element, set `input.aria-activedescendant = el.id`, and `el.scrollIntoView({ block: 'nearest' })`. Arrow keys inside the input call `preventDefault()` so the caret doesn't move.

Focus stays on the `<input>` the whole time (options are `tabindex="-1"`, navigated virtually) — this is the ARIA combobox/`aria-activedescendant` pattern, and it's why the widget can't match it.

## 6. Search flow & data lifecycle

- **Open**: first open → `import()` + `options()` + `init()`; subsequent opens reuse the module. Fallback text if the import fails (missing index / `--skip-search` build).
- **Input**: `preload(term)` immediately; `debouncedSearch(term, {}, 250)`. If it returns `null`, bail (a newer keystroke owns the render). Guard additionally with a monotonically increasing request token so a slow `data()` batch from an older term can't overwrite a newer render.
- **Render window**: resolve `data()` for the first `pageSize` (default 8) results via `Promise.all`, render, reset `activeIndex=-1`. Show `sd-search__status` = the i18n result count. "Load more" (`sd-search__more`) appends the next window and moves focus/active appropriately.
- **Empty / no-results**: distinct states — empty input clears everything; a term with zero results shows the `searchNoResults` i18n string in `sd-search__status`, results list emptied.
- **Excerpt**: `el.innerHTML = fragment.excerpt` (safe per §3). This is the one deliberate `innerHTML` sink; documented inline.

## 7. Subpath URL handling

`pagefind.options({ baseUrl: config.basePath.isEmpty ? '/' : '${config.basePath}/' })`. This prefixes `d.url` and every `sub.url` (including their `#anchor`) — so no manual string-prefixing, and the current `processResult` hack disappears.

**Verification gate**: inspect one real `data().url` from a built subpath index before finalizing — Flag 4 from the API research (stored-URL form can vary). If `baseUrl` double-prefixes or misses, fall back to manual prefixing of `url`/`sub.url`.

## 8. Config surface

Reuse the existing `SearchConfig` (`enabled`, `provider`, `placeholder`, `hotkey`) and all `i18nStrings.search*` translations. Optional additions (only if cheap):
- `search.pageSize` (int, default 8) — results per render window.

No new required config; existing sites keep working unchanged.

## 9. CSS plan

- **New** `assets/css/06-search.css` result rules under `.sd-search__*` — our own layout (flex column, page-title row with icon, indented subs, active/hover states using `--color-primary`, excerpt in `--color-text-secondary`, `<mark>` tinted with `color-mix(--color-primary)`). Written from our design vocabulary, not Starlight's `--search-*` scale.
- **Delete** `assets/css/17-pagefind.css` (the Starlight port) entirely.
- **Delete** the Starlight section from `THIRD_PARTY_NOTICES.md` (keep the file only if any other third-party remains; otherwise remove it).
- Keep the `<dialog>`/backdrop/button/scroll-lock rules already in `06-search.css`.

## 10. Accessibility

- Combobox pattern: `role="searchbox"` input + `role="listbox"` results + `role="option"` items + `aria-activedescendant`.
- `aria-live="polite"` status announces result counts.
- Native `<dialog>` gives focus trap + restore + Escape.
- All interactive result elements reachable by keyboard without leaving the input.

## 11. File-by-file changes

| File | Change |
|---|---|
| `lib/src/generator/builders/page_scripts_builder.dart` | Rewrite `buildSearchModal` → our `<dialog>` DOM + raw-API controller (build-time Lucide icons injected). Change `buildPagefindStyles` → return `''` (no widget CSS) or remove its call site. |
| `assets/css/06-search.css` | Add `.sd-search__*` result styling; keep dialog chrome. |
| `assets/css/17-pagefind.css` | **Delete**; run `tool/embed_css.dart`. |
| `THIRD_PARTY_NOTICES.md` | Remove Starlight entry (delete file if nothing else remains). |
| `test/generator/builders/page_scripts_builder_test.dart` | Rewrite search tests: our DOM present, no `pagefind-ui` refs, no Starlight-derived selectors, `baseUrl` wiring, keyboard handler present, fallback message. |
| `docs/features/search.md`, `docs/config/search.md` | Note keyboard navigation; drop any widget-specific wording. |

## 12. Verification plan

1. Unit (builder): emits `sd-search__*` DOM, imports `pagefind/pagefind.js`, sets `baseUrl`, contains the arrow-key handler, no `PagefindUI`/`pagefind-ui.css`/`--search-*` strings.
2. `tool/embed_css.dart` sync + `17-pagefind.css` gone; `css_sync_test` green.
3. Real build with search enabled on a **subpath** config → serve → manual matrix:
   - type → debounced results; page + sub-results render with icons.
   - Arrow Up/Down/Home/End cycle the highlight; Enter navigates; Escape closes; hover syncs.
   - result + sub-result links land on the correct `/stardust/...#anchor` URL.
   - "Load more" appends; empty and no-results states; `--skip-search` build shows fallback.
4. `dart test` + `dart analyze --fatal-infos` + `dart format --set-exit-if-changed` clean; deterministic rebuild (no `DateTime`/random in the emitted JS).
5. **User visual sign-off** — I verify structure, not pixels; a screenshot confirms parity/quality.

## 13. Risks & open questions

- **R1 — subpath URL form** (Flag 4): must inspect a real `data().url` before finalizing `baseUrl` vs manual prefix. *Gate before merge.*
- **R2 — excerpt `innerHTML`**: RESOLVED. Excerpts pass through `markOnly()`, which neutralizes every tag except a bare `<mark>`/`</mark>` (regex `/<(?!\/?mark>)/gi`), preserving Pagefind's existing entity-encoding without double-escaping. Belt-and-suspenders over Pagefind's own encoding guarantee.
- **R3 — module import under CSP**: dynamic `import()` of a same-origin script is fine; note for any future strict-CSP users.
- **R4 — scope creep**: filters/sort are out of v2. Keep the controller small.
- **R5 — no visual loop for me**: mitigated by user screenshots, as with the current work.

## 14. Rollout

Single feature branch off `dev` (sibling to `feat/pagefind-search`, or stacked on it if that merges first). Because it *removes* the Starlight-derived code, the branch description should state plainly: replaces the widget port with an original raw-API implementation; Starlight attribution removed because its code is no longer present.

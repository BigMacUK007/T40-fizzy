# Fizzy Design System & Mobile Implementation Review

A guide to how Fizzy's design system, CSS architecture, and mobile/native implementation work — intended as a reference for future projects.

Fizzy is a great reference because it deliberately rejects the mainstream stack: **no Tailwind, no Sass, no CSS bundler, no React**. It's vanilla CSS served by Propshaft, Hotwire (Turbo + Stimulus) for behavior, and Hotwire Native bridge components for the iOS/Android apps. Everything below is the "how", with file references you can lift patterns from.

## 1. CSS architecture

**One flat directory of ~63 small component files** (`app/assets/stylesheets/`), each named for one concern (`buttons.css`, `header.css`, `trays.css`...). No nesting, no `components/` subfolders, no build step — Propshaft just serves them all.

**Cascade layers define specificity order globally.** The first line of `_global.css`:

```css
@layer reset, base, components, modules, utilities, native, platform;
```

Every file wraps its rules in a layer (`@layer components { ... }`). This is the modern replacement for ITCSS/specificity wars: utilities always beat components, native/platform overrides always beat everything, regardless of selector specificity or file load order. This single line is probably the most reusable idea in the codebase.

**Design tokens live in one `:root` block** (`_global.css`), in tiers:

- **Primitive color scales** — every hue (`ink`, `red`, `blue`, `uncolor`...) has 7 steps (`darkest` → `lightest`) stored as raw **OKLCH triplets** (`--lch-blue-dark: 57.02% 0.1895 260.46`), not finished colors. This lets them compose alpha later: `oklch(var(--lch-black) / 5%)` in shadows.
- **Named colors** — `--color-ink`, `--color-ink-light`... wrap the LCH values.
- **Semantic abstractions** — `--color-canvas` (background), `--color-link`, `--color-negative/positive`, `--color-selected`, `--color-highlight`. Components only reference this tier, never raw hues.
- **Spacing** — just two base units: `--inline-space: 1ch` and `--block-space: 1rem`, with half/double variants. Note the units: `ch` for horizontal rhythm (scales with font), `rem` for vertical. No 12-step spacing scale — and the codebase stays consistent because there are only 6 options.
- **A documented z-index scale** (`--z-popup: 10` ... `--z-nav-open: 100`), named easing curves, a composable `--shadow` stack, and component constants (`--btn-size`, `--tray-size`).

**Dark mode is a token swap, done twice.** `html[data-theme="dark"]` (explicit user choice, set from `localStorage` by an inline script in `_theme_preference.html.erb` before paint — no flash) and `@media (prefers-color-scheme: dark)` on `html:not([data-theme])` (system fallback). Both blocks redefine only the LCH variables — the scales are *inverted* (darkest becomes lightest) so component CSS never mentions dark mode. The duplication is the one wart; in a new project you could DRY it with a preprocessor or accept it as Fizzy does.

## 2. Component CSS conventions

**BEM naming, modern CSS features.** Blocks/elements/modifiers (`.card-perma__bg`, `.btn--negative`) but written with native nesting, `:has()`, `:is()`/`:where()`, container-style variable overrides, and logical properties (`inline-size`, `padding-block`, `border-start-start-radius`) everywhere — the app is RTL-ready for free.

**Variants are CSS-variable overrides, not new rules.** `buttons.css` is the textbook example: `.btn` reads `var(--btn-background, var(--color-canvas))`, `var(--btn-padding, 0.5em 1.1em)`, etc., and every variant is just:

```css
.btn--negative {
  --btn-background: var(--color-negative);
  --btn-color: var(--color-ink-inverted);
  --focus-ring-color: var(--color-negative);
}
```

This "CSS variables as component API" pattern keeps variants 3–5 lines and means callers can also tune a button inline with a style attribute.

**State is expressed structurally with `:has()`, not JS classes.** Examples worth stealing:

- Toggle buttons: `.btn:has(input:checked)` restyles, the radio/checkbox is invisibly stretched over the button — no Stimulus controller needed.
- Submit spinners: `form[aria-busy] .btn:disabled::after` draws an animated loader — the only JS involvement is Turbo setting `aria-busy`.
- Icon-only buttons detected by accessibility markup: `.btn[aria-label]:has(.icon)` automatically becomes circular — correct a11y is what triggers the styling.
- The header (`header.css`) counts its own buttons to size its grid: `&:has(.header__actions > *:nth-child(2)) { --header-button-count: 2; }`.

**A small, honest utility layer** (`utilities.css`, ~280 lines). Text sizes (`txt-small`), flex/grid helpers, spacing built on the two space tokens (`pad`, `margin-block-half`), fills, borders, and a11y helpers (`.for-screen-reader`). It's Tailwind-shaped but token-bound and finite — utilities for composition in ERB, component classes for anything with identity.

**Typography scales by tokens, not breakpoint rewrites.** Font sizes are tokens (`--text-small`...`--text-xx-large`) that get *redefined* under `max-width: 639px` (bumped up for touch legibility), and the root font-size itself grows to `1.1875rem` on screens wider than `100ch` (`base.css`). Since components use the tokens and `em` units, the whole UI rescales from two declarations.

## 3. Mobile web implementation

Three orthogonal axes, each detected differently — this separation is the key insight:

| Axis | Mechanism | Example |
|---|---|---|
| Screen size | `@media (max-width: 639px)` (main), 799px, 479px | Column layout, circular buttons |
| Input capability | `@media (any-hover: none/hover)` | Hover effects, `.hide-on-touch` |
| Platform/app | `data-platform` attribute + `@layer native/platform` | Native chrome removal |

**Hover is gated, always.** Every `:hover` rule sits inside `@media (any-hover: hover)` so touch devices never get sticky hover states. Touch-only affordances use `.show-on-touch` / `.hide-on-touch` utilities.

**Mobile-specific component behavior stays in the component file**, nested inline rather than in a separate mobile stylesheet. Patterns worth copying from `card-columns.css`:

- On mobile the board switches to `scroll-snap-type: inline mandatory` with one expanded column at a time (`--column-width-expanded: calc(100vw - var(--column-gap) * 4)`) — a native-feeling horizontal pager in pure CSS.
- `body.contained-scrolling` switches the page from document scrolling to an inner-scrolling grid (`100dvh`, `overflow: hidden`) only on small screens — opt-in per page via body class.
- `.btn--circle-mobile` collapses a labeled button to an icon circle under 640px by hiding its text spans.

**Viewport and safe areas:** the meta tag uses `viewport-fit=cover`, and *all* edge padding goes through indirected variables (`_global.css`):

```css
--custom-safe-inset-top: var(--injected-safe-inset-top, env(safe-area-inset-top, 0px));
```

Browser notches use `env()`; the native apps can *override* by injecting `--injected-safe-inset-*` (see §4). Layout code only ever references `--custom-safe-inset-*`. Also note consistent use of `100dvw`/`100dvh` (dynamic viewport units) instead of `vw/vh`, which avoids the mobile URL-bar jump.

**PWA**: a manifest route, `display-mode: standalone/browser` media queries (`.hide-in-pwa`, `.hide-in-browser`), and theme-color metas per color scheme.

## 4. Native apps (Hotwire Native)

The iOS/Android apps are thin native shells around the same web views — one codebase, three platforms.

**Server-side detection** (`app/models/application_platform.rb` + `set_platform.rb` concern): parses the user agent (native apps append "Hotwire Native") and `platform.type` returns `"native ios"`, `"native android"`, `"mobile web"`, or `"desktop web"`. The layout stamps it on the body: `data-platform="<%= platform.type %>"`.

**CSS targets platforms via attribute selectors in dedicated layers:**

- `native.css` (`[data-platform~=native]`) — hides the web footer (`--footer-height: 0`, `.hide-on-native`), removes the web back button and collapses the header to just a safe-area spacer when the native title bar covers it, kills tap highlight.
- `ios.css` / `android.css` — tiny per-OS tweaks, plus iOS maps the native Dynamic Type setting (`data-text-size` attribute) to root font sizes, so web content respects the user's system text size.

**Bridge components** (`app/javascript/controllers/bridge/`) are small Stimulus controllers extending `BridgeComponent` that swap HTML controls for native ones:

- `buttons_controller.js` — sends button metadata to the native shell, which renders real toolbar buttons; tapping one clicks the hidden DOM element. CSS hides the HTML versions only when the native side registers (`[data-bridge-components~=buttons] [data-bridge--buttons-target~=button] { display: none }`) — so the web fallback is automatic.
- `insets_controller.js` — the native app pushes its actual chrome insets into the `--injected-safe-inset-*` CSS variables.
- `form`, `overflow_menu`, `title`, `text_size` — same pattern: HTML is the source of truth, native renders it, CSS hides the duplicate.

**The progressive-enhancement guarantee** is structural: every native affordance is an *attribute-gated subtraction* from a fully working web page. If the bridge never connects, nothing is hidden and the web UI just works.

## 5. What to take into your next project

1. **`@layer reset, base, components, modules, utilities, native, platform;`** — declare cascade order once, end specificity fights forever.
2. **Three-tier tokens** (primitive OKLCH scales → named colors → semantic roles) with dark mode as a pure token swap, applied via `data-theme` + `prefers-color-scheme` fallback and a pre-paint localStorage script.
3. **CSS variables as component APIs** — variants become 3-line variable overrides.
4. **Two spacing units** (`1ch` inline / `1rem` block) + logical properties; you get density consistency and RTL support for free.
5. **Separate the three mobile axes**: width (`max-width: 639px`), input (`any-hover`), platform (`data-platform`). Never use width as a proxy for touch.
6. **`:has()` for state** instead of JS-toggled classes (checked buttons, busy forms, child-count-aware grids).
7. **Safe-area indirection** (`--custom-safe-inset-*` falling back from injected → `env()` → 0) so web and native share one layout system.
8. **One small file per component, BEM names, native nesting, no build step** — the whole system is greppable and has zero tooling to maintain.

The main caveats if you copy this wholesale: it assumes very modern browsers (`:has()`, nesting, OKLCH, layers — no graceful degradation), the light/dark token blocks are duplicated by hand, and the flat utility-plus-BEM mix relies on team discipline rather than tooling to stay consistent. For a small senior team those trade-offs buy an enormous amount of simplicity.

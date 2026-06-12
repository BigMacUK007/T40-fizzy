# Fizzy Design Decisions Review — Area by Area

A capture of the design thinking behind each part of the app — navigation, notifications, cards, trays, and more — intended as a guide for new projects. Companion to [DESIGN_SYSTEM_REVIEW.md](DESIGN_SYSTEM_REVIEW.md), which covers the CSS architecture and mobile implementation.

The unifying philosophy first, because every area below is an expression of it: **Fizzy treats the browser's native primitives as the design system** (`<dialog>`, `<details>`, radio inputs, anchors), layers personality on top with CSS only, and reserves JavaScript for orchestration rather than rendering. The second theme is **opinionated product behavior encoded in the domain model** — entropy, notification bundling, golden cards — where the "design" is a decision about how teams should work, not just how pixels look.

---

## Navigation — a command palette instead of a sidebar

`app/views/my/_menu.html.erb`, `nav.css`

The app has **no persistent sidebar or menu bar**. The entire navigation is one trigger button (the Fizzy logo) in the header that opens a popup which is simultaneously a **menu, a jump palette, and a hotkey pad** — pressing `J` (or `⌘J`) opens it anywhere.

Design decisions worth noting:

- **Navigation is search-first.** The popup is wired with `filter` + `navigable-list` Stimulus controllers: you type to filter boards/views, arrow-key through results, hit enter. The mouse path and keyboard path are the same UI, not two parallel ones.
- **Lazy and persistent.** The menu content is a `turbo_frame` with `loading: :lazy` and `data-turbo-permanent` — fetched once on hover (`mouseenter->dialog#loadLazyFrames`), then surviving page navigations. Prefetch-on-intent without a SPA.
- **A grid of "hotkey cards"** (`.nav__hotkeys`) shows the main destinations as aspect-ratio tiles with their keyboard shortcut printed in the corner — the UI *teaches* the shortcuts. The `kbd` hints hide on touch devices (`@media (any-hover: none)`), with a comment explaining why `any-hover` beats `any-pointer` in practice.
- **Hidden sections reveal during search**: `.nav__section--secret:not([data-is-filtering]) { display: none }` — rarely-needed destinations exist but only surface when you type. Progressive disclosure as one selector.
- The empty state hides itself with pure CSS when any result is visible: `.nav:has(.popup__item:not([hidden]))` — no JS bookkeeping of result counts.

**Takeaway:** for tools used daily, a searchable jump palette beats a sidebar — it scales with content, costs no screen space, and rewards expertise. And `:has()` can manage all of its visibility states declaratively.

## The header — self-measuring, title-centered

`header.css`

A three-column grid (`actions-start | title | actions-end`) like a native mobile title bar — on every screen size, not just mobile. The clever decision: the header **counts its own buttons** with `:has(.header__actions > *:nth-child(2))` and widens the side columns accordingly, so the title stays perfectly centered whether a page has zero or three actions. Pages inject buttons via `yield :header`; the layout self-balances. The skip-navigation link is the first element — accessibility built into the scaffold, not retrofitted.

## The Bar — search styled as a terminal

`bar.css`, `bar/_bar.html.erb`

Global search lives in a **fixed bottom strip styled like a terminal** (`--color-terminal-bg`, monospace accents, uppercase "SEARCH ⌘K" placeholder). Decisions:

- **Bottom placement, not a center modal.** Search is ambient chrome, like a shell prompt — always there, never covering content until you engage. When activated, results slide up into a 75dvh panel *above* the bar (`bar__modal` with `z-index: -1` tucked behind it).
- The input animates from `translateY(50%)` to `0` when the placeholder hides — state driven entirely by `.bar:has(.bar__placeholder[hidden])`. The Stimulus `bar` controller only toggles `hidden`; CSS choreographs everything else.
- The result panel hides itself while the turbo-frame is `[busy]` or incomplete — loading states from frame attributes, no spinner code.

**Takeaway:** giving a feature a *metaphor* (terminal) generates dozens of small consistent decisions (colors, type, placement) for free.

## Trays — pins and notifications as physical card stacks

`trays.css` — the most distinctive UI in the app.

Pinned cards (bottom-left) and notifications (bottom-right) live in **trays that look like fanned stacks of paper**. Collapsed, items overlap with progressive scale (`--tray-item-scale: calc(1 - (var(--tray-item-index) - 1) / 30)`) and z-order; opening the tray animates each card up with a **staggered 20ms-per-item delay** (`--tray-item-delay`) and an overshoot easing curve. All of it is CSS custom-property math — `nth-child` assigns an index variable and everything (margin, scale, z, delay) derives from it.

Other decisions:

- **The skeuomorphism is informative**: you can *see* roughly how many notifications are stacked before opening. A red dot appears only when a 7th item exists — `.tray__dialog:has(.tray__item:nth-child(1n + 7))` — i.e., when the stack overflows what's visible.
- **Capacity adapts to physical screen height** with `max-height`/`min-height` media-query bands (6 pins on short screens up to 10 on tall) — height queries, which almost nobody uses, are exactly right for a bottom-anchored stack.
- **Cards in trays are the same card partial**, restyled by context: `trays.css` hides avatars, tags, steps via descendant selectors. One component, many densities — the CSS adapts the markup rather than the server rendering variants.
- On mobile the trays collapse to icon buttons flanking the search bar; the whole bottom edge becomes a three-zone dock (pins | search | notifications) inside the safe-area inset.

**Takeaway:** a spatial metaphor (stacks at the bottom corners of your desk) plus index-derived CSS variables gives you rich, ordered motion with zero animation JS.

## Notifications — bundled by product design, calm by default

`notification/bundle.rb`, `cards.css` (`.card--notification`)

The deepest design thinking here is in the **model layer**: notifications are not emailed instantly. Each user gets a rolling `Notification::Bundle` window (delivered by a recurring job every 30 min); the mailer sends *one digest* of whatever is unread in the window, in the user's own timezone (`user.in_time_zone do ... deliver`). Overlap validation guarantees no double-sends. The decision: **interrupt at most occasionally, summarize by default** — the anti-Slack stance encoded in a database table.

In the UI, a notification *is a card* — same partial, `card--notification` variant — so the object you're notified about looks like the object itself. Mentions get a highlighted "marker pen" treatment (`border-radius: 0.7em 0.2em 0.7em 0.2em` — deliberately lopsided, like a hand-drawn highlight). The unread indicator is a count badge that morphs into a check button on hover (opacity crossfade between `.badge-count` and `.icon`) — the indicator *is* the dismiss action, no separate control.

## Cards — one color variable generates the whole identity

`cards.css`

Every card has a single input — `--card-color` (from its board, 8 named options in `_global.css`) — and **all card chrome is `color-mix()` derivations of it**:

```css
--card-bg-color:      color-mix(in srgb, var(--card-color) 4%,  var(--color-canvas));
--card-content-color: color-mix(in srgb, var(--card-color) 30%, var(--color-ink));
--card-text-color:    color-mix(in srgb, var(--card-color) 75%, var(--color-ink));
--card-border:        1px solid color-mix(in srgb, var(--card-color) 33%, ...);
```

Tinted backgrounds, readable text, borders, and the board-name flag all stay harmonized in light *and* dark mode (because they mix against `--color-canvas`/`--color-ink`, which already flipped). Adding a ninth color is one variable. This is the strongest "design system" idea in the app: **derive, don't enumerate.**

Other card decisions:

- **Big editorial typography**: card titles are `--text-xx-large` at weight 900 with `text-wrap: balance` — cards read like newspaper clippings, not table rows. The metadata footer is a tiny uppercase grid ("ADDED / BY / LAST UPDATE / ASSIGNED") with hairline borders, like a printed form.
- **The closed stamp**: completed cards get a rotated (`rotate: 5deg`), bordered, backdrop-blurred "stamp" with title, date, and a dashed signature line ("closed by") — paperwork iconography. Simultaneously, the card is drained of color (`--card-color: var(--color-card-complete) !important` via `.card:has(.card__closed)`). Done things become literally and figuratively gray.
- **Golden cards** (`golden-effect.css`, `card/golden.rb`): marking a card important is `card.gild` — it gets a gold gradient and layered glow. Note the controller from STYLE.md: `Cards::GoldnessesController#create` — even "star this" is modeled as a REST resource. Status is celebrated visually, not just flagged.
- Random `nth-child` formulas rotate comment-bubble angles per card so a board feels hand-laid rather than stamped out.

## Card permalink — the "machine" frame

`card-perma.css`

The card detail page renders the card inside a grid of "notches" — colored tooling that surrounds the card (`notch-top / actions-left / card / actions-right / notch-bottom`), tinted by `--color-container` (33% of the card color). The card looks **physically held by a machine** — actions are on the frame, content on the card, and the distinction is structural in the grid template. On mobile, the grid-template-areas are simply re-declared so action rails move *below* the card — same DOM, rearranged at one breakpoint. A nice flourish: ticking the "delete" star input outlines the card in red via `:has(.card-perma__star-input:checked)` — destructive intent previewed before confirmation.

## Board columns — collapse, snap, and peek

`card-columns.css`

- Columns **collapse to thin labeled spines** (`--column-width-collapsed`) instead of scrolling offscreen — the whole workflow stays visible as a map, and off-screen drop targets show a fixed floating column name during drag (`.is-off-screen:after { content: attr(data-column-name); position: fixed }`) so you can drop into a column you can't see.
- On mobile it becomes a **scroll-snap pager**: one column expanded at a time, neighbors peeking at the edges (`calc(100vw - var(--column-gap) * 4)`) to advertise swipeability. No carousel library.
- Triage is a separate top-of-board area: new cards don't pollute columns until sorted — workflow opinion expressed as layout.

## Dialogs & popups — the platform does the work

`dialog.css`, `popup.css`

Everything that floats is a **native `<dialog>`**: the nav menu, card pickers, tag pickers, trays, search modal. Decisions:

- Animation uses the new CSS-only stack: `transition-behavior: allow-discrete` + `@starting-style` + `overlay` transitions — enter/exit animation on a native element with zero JS. Closing runs at *half* the duration of opening (`calc(var(--dialog-duration) / 2)`) — fast exits, gentle entrances, a classic motion principle in two lines.
- Page scroll locks via `html:has(dialog:modal) { overflow: hidden }` — global behavior from a selector.
- Popups handle screen-edge collision with tiny `orient-left/right` helper classes layered over default centering — JS measures once, CSS owns the layout.
- Popup items use `aria-checked`/`aria-selected` as the *styling hooks* (`&[aria-checked="true"] .checked { display: block }`) — accessibility state and visual state cannot drift apart because they're the same attribute.

## Filters — composable queries in the header

`filters.css`

Filters are buttons living *inside the page header*, each opening a popup of checkbox options; selected filters render as removable chips. They're shared, linkable state (filters are a model — `app/models/filter.rb` — so a filtered view is a URL you can send someone). The design decision: filtering is part of *navigation chrome*, not a sidebar form, and `view-transition-name: filters` keeps the filter row visually continuous across page morphs.

## The entropy knob — playful controls for opinionated settings

`knobs.css`, `entropy.rb`

Entropy (auto-postponing stale cards) is configured with a literal **rotary knob**: a hidden `<input type=range>` overlaid on a circular dial, options placed by trigonometric `transform` math (`rotate(...) translateY(...)`) from an index variable, with a chamfered indicator. Under the hood it's a plain accessible range input; the knob is pure CSS.

Two lessons: (1) when a setting embodies product personality (Fizzy *wants* your lists to decay), give it a memorable control — the knob makes entropy feel like tuning a machine rather than filling a form; (2) the touch model stays standard because the real input is native.

Note the model: `Entropy` is polymorphic (`container` = account or board) and `touch_all`s cards on change — board-level override of an account default, two rows, no flags.

## Events / activity — generated summaries, day columns

`events.css`

The activity timeline is grouped into day columns with sticky headers (and on iOS the column header gets a frosted-glass `backdrop-filter` treatment — the one place the web copies native aesthetics, only on the platform where it's idiomatic). AI-generated activity summaries get a distinct **animated pastel gradient** (`animation: gradient 4s ease infinite` over `--color-gradient-1..4`) while generating — "the machine is thinking" has its own visual language, defined once as tokens.

## Motion — a small named vocabulary

`animation.css`

Fifteen keyframes total (`appear-then-fade`, `shake`, `wiggle`, `success`, `zoom-fade`, `submitting`…) plus three named easings in `_global.css` (`--ease-out-overshoot` etc., with a comment crediting easingwizard.com). Everything in the app reuses these — flash messages `appear-then-fade`, buttons flash `success`, invalid forms `shake`. Because the vocabulary is tiny and named, motion feels consistent: same bounce everywhere, 100–350ms, always ease-out. There's a `prefers-reduced-motion` escape hatch. **Decision: motion is a design-token set, not per-feature improvisation.**

## Keyboard layer

`hotkey_controller.js`, `navigable_list_controller.js`, `kbd` styling in `base.css`

Single-letter hotkeys (`J` nav, `K` search) are declared **in the markup** as `data-action="keydown.j@document->hotkey#click"` — the hotkey simply clicks the visible button, so keyboard and pointer paths share one code path and one analytics trail. `kbd` has a global "keycap" style (border + `box-shadow: 0 0.1em 0 currentColor` for a 3D press look), and every hint hides on touch. Lists gain arrow-key navigation from one reusable `navigable-list` controller driving `aria-selected`.

---

## The distilled design-thinking checklist for new projects

1. **Pick a metaphor per feature** (terminal bar, paper stacks, rubber stamp, machine notches, rotary knob). The metaphor makes dozens of micro-decisions for you and gives users a mental model.
2. **Derive colors from one input** with `color-mix()` instead of enumerating palettes per component — it's how Fizzy gets 8 board themes × light/dark with ~10 lines per concern.
3. **Encode product opinions in the domain model** (entropy, bundled digests, triage) — the most "user-friendly" parts of Fizzy are scheduling and decay policies, not pixels.
4. **One partial, many contexts**: render the same card everywhere and let contextual CSS subtract detail (tray vs. board vs. notification). Server stays simple; density is a stylesheet concern.
5. **Let state live in the DOM and react with `:has()`**: badge dots from item counts, scroll-locking from open dialogs, empty states from hidden siblings, danger previews from checked inputs. JS toggles one attribute; CSS does the rest.
6. **Use ARIA attributes as styling hooks** so accessible state and visual state are the same thing.
7. **Make keyboard a first-class citizen in markup** — hotkeys that click visible buttons, hints rendered in the UI, hidden on touch.
8. **Define a tiny named motion vocabulary** (keyframes + easings as tokens); fast exits, springy entrances, staggered delays computed from index variables.
9. **Celebrate and decay**: give success states ceremony (gold glow, stamps) and let stale things visibly fade (gray closed cards, entropy). Emotional design is mostly color and one animation.
10. **Adapt to physical constraints, not just width**: height-based capacity for the pin tray, `any-hover` for input, `display-mode` for PWA, `data-platform` for native — each constraint gets its own honest query.

Building new projects on this template — semantic HTML + native dialogs, derived color, `:has()`-driven state, Hotwire for transport — inherits the property that makes Fizzy feel so polished: **every interaction has exactly one source of truth**, so nothing can fall out of sync.

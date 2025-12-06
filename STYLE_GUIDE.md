# Fizzy CSS Style Guide

A comprehensive design system reference for maintaining brand consistency across 37signals products.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Spacing](#spacing)
5. [Components](#components)
6. [Icons](#icons)
7. [Animation](#animation)
8. [Accessibility](#accessibility)
9. [Responsive Design](#responsive-design)
10. [Utilities](#utilities)

---

## Architecture Overview

### CSS Cascade Layers

The styling system uses CSS Cascade Layers for specificity management:

```css
@layer reset, base, components, modules, utilities;
```

| Layer | Purpose |
|-------|---------|
| `reset` | Modern CSS reset, normalizing browser defaults |
| `base` | Base element styles and typography |
| `components` | Reusable UI components |
| `modules` | Page-specific modules |
| `utilities` | Single-purpose utility classes |

### Design Principles

- **Pure CSS** - No preprocessors (Sass/Less); uses native CSS custom properties
- **OKLCH Colors** - Perceptually uniform color model for consistent light/dark modes
- **CSS Variables** - All design tokens defined as custom properties
- **Mobile-first** - Responsive by default with progressive enhancement
- **Accessibility-first** - Full keyboard navigation and screen reader support

---

## Color System

### Color Model: OKLCH

Colors use the **OKLCH** (Lightness, Chroma, Hue) model for perceptual uniformity:

```css
oklch(lightness% chroma hue)
```

### Base Colors

```css
--lch-black: 0% 0 0;
--lch-white: 100% 0 0;
```

### Color Palette

Each color family has 7 shades: `darkest`, `darker`, `dark`, `medium`, `light`, `lighter`, `lightest`

#### Ink (Neutral Gray)

| Shade | Light Mode | Usage |
|-------|------------|-------|
| `--lch-ink-darkest` | `26% 0.05 264` | Primary text |
| `--lch-ink-darker` | `40% 0.026 262` | Secondary text |
| `--lch-ink-dark` | `56% 0.014 260` | Subtle text |
| `--lch-ink-medium` | `66% 0.008 258` | Muted text |
| `--lch-ink-light` | `84% 0.005 256` | Borders |
| `--lch-ink-lighter` | `92% 0.003 254` | Dividers |
| `--lch-ink-lightest` | `96% 0.002 252` | Backgrounds |

#### Primary Colors

| Color | Dark Shade (Primary) | Hue |
|-------|---------------------|-----|
| **Red** | `59% 0.19 38` | 34-46 |
| **Yellow** | `58% 0.156 60` | 40-100 |
| **Lime** | `56.5% 0.142 111` | 109-115 |
| **Green** | `55% 0.162 147` | 143-149 |
| **Aqua** | `55.5% 0.122 210` | 202-214 |
| **Blue** | `57.02% 0.1895 260.46` | 252-264 |
| **Violet** | `58% 0.216 287.6` | 280-292 |
| **Purple** | `58% 0.21 310` | 302-314 |
| **Pink** | `59% 0.188 344` | 336-348 |

#### Uncolor (Warm Neutral)

| Shade | Value | Hue |
|-------|-------|-----|
| `--lch-uncolor-dark` | `57.09% 0.0676 60.5` | 40-100 |

### Semantic Colors

```css
/* Core Semantics */
--color-canvas: oklch(var(--lch-white));           /* Page background */
--color-ink: oklch(var(--lch-ink-darkest));        /* Primary text */
--color-link: oklch(var(--lch-blue-dark));         /* Links */
--color-negative: oklch(var(--lch-red-dark));      /* Errors, destructive */
--color-positive: oklch(var(--lch-green-dark));    /* Success, confirmation */

/* Interactive States */
--color-selected: oklch(var(--lch-blue-lighter));
--color-selected-light: oklch(var(--lch-blue-lightest));
--color-selected-dark: oklch(var(--lch-blue-light));
--color-highlight: oklch(var(--lch-yellow-lighter));
--color-marker: oklch(var(--lch-red-medium));      /* Alerts, badges */

/* Special */
--color-golden: oklch(89.1% 0.178 95.7);           /* Premium features */
--color-considering: oklch(var(--lch-blue-medium));
--color-terminal-bg: oklch(98% 0.002 252);
```

### Card Colors

```css
--color-card-default: oklch(var(--lch-blue-dark));
--color-card-complete: var(--color-ink-darker);
--color-card-1: oklch(var(--lch-ink-medium));      /* Gray */
--color-card-2: oklch(var(--lch-uncolor-medium));  /* Tan */
--color-card-3: oklch(var(--lch-yellow-medium));   /* Yellow */
--color-card-4: oklch(var(--lch-lime-medium));     /* Lime */
--color-card-5: oklch(var(--lch-aqua-medium));     /* Aqua */
--color-card-6: oklch(var(--lch-violet-medium));   /* Violet */
--color-card-7: oklch(var(--lch-purple-medium));   /* Purple */
--color-card-8: oklch(var(--lch-pink-medium));     /* Pink */
```

### Syntax Highlighting

```css
--color-code-token__att: oklch(var(--lch-blue-dark));
--color-code-token__comment: oklch(var(--lch-ink-medium));
--color-code-token__function: oklch(var(--lch-purple-dark));
--color-code-token__operator: oklch(var(--lch-red-dark));
--color-code-token__property: oklch(var(--lch-purple-dark));
--color-code-token__punctuation: oklch(var(--lch-ink-dark));
--color-code-token__selector: oklch(var(--lch-green-dark));
--color-code-token__variable: oklch(var(--lch-red-dark));
```

### Text Highlighter Colors

```css
/* Foreground colors */
--highlight-1: rgb(136, 118, 38);    /* Yellow */
--highlight-2: rgb(185, 94, 6);      /* Orange */
--highlight-3: rgb(207, 0, 0);       /* Red */
--highlight-4: rgb(216, 28, 170);    /* Magenta */
--highlight-5: rgb(144, 19, 254);    /* Purple */
--highlight-6: rgb(5, 98, 185);      /* Blue */
--highlight-7: rgb(17, 138, 15);     /* Green */
--highlight-8: rgb(148, 82, 22);     /* Brown */
--highlight-9: rgb(102, 102, 102);   /* Gray */

/* Background colors (30% opacity) */
--highlight-bg-1: rgba(229, 223, 6, 0.3);
--highlight-bg-2: rgba(255, 185, 87, 0.3);
/* ... etc */
```

### Dark Mode

All OKLCH colors automatically invert for dark mode with adjusted lightness values:

```css
@media (prefers-color-scheme: dark) {
  --lch-canvas: 20% 0.0195 232.58;
  --lch-ink-darkest: 96.02% 0.0034 260;
  /* All colors recalibrated for dark backgrounds */
}
```

---

## Typography

### Font Families

```css
--font-sans: system-ui;
--font-serif: ui-serif, serif;
--font-mono: ui-monospace, monospace;
```

### Type Scale

| Token | Desktop | Mobile (< 640px) |
|-------|---------|------------------|
| `--text-xx-small` | 0.55rem | 0.65rem |
| `--text-x-small` | 0.75rem | 0.85rem |
| `--text-small` | 0.85rem | 0.95rem |
| `--text-normal` | 1rem | 1.1rem |
| `--text-medium` | 1.1rem | 1.2rem |
| `--text-large` | 1.5rem | 1.5rem |
| `--text-x-large` | 1.8rem | 1.8rem |
| `--text-xx-large` | 2.5rem | 2.5rem |

### Base Typography Settings

```css
body {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  font-family: var(--font-sans);
  line-height: 1.375;
  text-rendering: optimizeLegibility;
}

/* Responsive base size */
html {
  font-size: 100%;
}

@media (min-width: 100ch) {
  html {
    font-size: 1.1875rem;
  }
}
```

### Typography Utilities

```css
.txt-xx-small     /* font-size: var(--text-xx-small) */
.txt-x-small      /* font-size: var(--text-x-small) */
.txt-small        /* font-size: var(--text-small) */
.txt-normal       /* font-size: var(--text-normal) */
.txt-medium       /* font-size: var(--text-medium) */
.txt-large        /* font-size: var(--text-large) */
.txt-x-large      /* font-size: var(--text-x-large) */
.txt-xx-large     /* font-size: var(--text-xx-large) */

.txt-align-center / .txt-align-start / .txt-align-end
.txt-uppercase / .txt-capitalize
.txt-nowrap / .txt-break
.txt-link         /* color + underline */
.txt-subtle       /* muted color */
.txt-negative     /* error color */

.font-weight-black  /* 900 */
.font-weight-normal /* 400 */
```

---

## Spacing

### Spacing Tokens

| Token | Value |
|-------|-------|
| `--inline-space` | 1ch |
| `--inline-space-half` | 0.5ch |
| `--inline-space-double` | 2ch |
| `--block-space` | 1rem |
| `--block-space-half` | 0.5rem |
| `--block-space-double` | 2rem |

### Padding Utilities

```css
.pad              /* block + inline */
.pad-double       /* double spacing */
.pad-block        /* vertical only */
.pad-block-half   /* half vertical */
.pad-inline       /* horizontal only */
.pad-inline-half  /* half horizontal */
.pad-inline-double
.unpad            /* remove all padding */
```

### Margin Utilities

```css
.margin           /* block + inline */
.margin-block     /* vertical */
.margin-block-half
.margin-block-double
.margin-block-start / .margin-block-end
.margin-inline    /* horizontal */
.margin-inline-half
.margin-inline-double
.margin-none      /* remove margins */
.center           /* margin-inline: auto */
```

---

## Components

### Buttons

Base button class with CSS variable customization:

```css
.btn {
  --btn-size: 2.65em;
  --btn-border-radius: 99rem;        /* Pill shape */
  --btn-padding: 0.5em 1.1em;
  --btn-background: var(--color-canvas);
  --btn-color: var(--color-ink);
  --btn-border-color: var(--color-ink-light);
  --btn-font-weight: 600;
  --btn-gap: 0.5em;
}
```

#### Button Variants

| Class | Purpose |
|-------|---------|
| `.btn--plain` | Transparent, no border |
| `.btn--link` | Primary action (blue) |
| `.btn--negative` | Destructive action (red) |
| `.btn--positive` | Confirmation (green) |
| `.btn--reversed` | Inverted colors |
| `.btn--circle` | Icon-only circular button |
| `.btn--back` | Back navigation |

#### Button States

```css
/* Disabled */
.btn[disabled] {
  cursor: not-allowed;
  opacity: 0.3;
  pointer-events: none;
}

/* Loading (with form[aria-busy]) */
form[aria-busy] .btn:disabled {
  /* Animated dots indicator */
}
```

### Cards

Card component with color theming via `--card-color`:

```css
.card {
  --card-color: var(--color-card-default);
  --card-bg-color: color-mix(in srgb, var(--card-color) 4%, var(--color-canvas));
  --card-text-color: color-mix(in srgb, var(--card-color) 75%, var(--color-ink));
  --card-border-radius: 0.2em;
}
```

**Structure:**
- `.card__header` - Top section with board name, tags
- `.card__body` - Main content area
- `.card__title` - Card headline
- `.card__description` - Rich text content
- `.card__meta` - Author, dates, assignees grid

### Avatars

```css
.avatar {
  --avatar-size: 5ch;
  --avatar-border-radius: 50%;
  aspect-ratio: 1;
}
```

### Dialogs

Modal dialogs with scale/fade animation:

```css
.dialog {
  --dialog-duration: 150ms;
  /* Opens with scale(0.2) to scale(1) */
  /* Backdrop fades from 0 to 0.5 opacity */
}
```

---

## Icons

### Icon System

Icons use CSS masks with SVG files:

```css
.icon {
  --icon-size: 1em;
  background-color: currentColor;
  mask-image: var(--svg);
  mask-size: var(--icon-size);
}
```

### Available Icons

```css
.icon--add              /* Plus sign */
.icon--arrow-left       /* Navigation */
.icon--arrow-right
.icon--bell             /* Notifications */
.icon--bell-off
.icon--board            /* Kanban board */
.icon--check            /* Completion */
.icon--check-circle
.icon--close            /* Dismiss */
.icon--comment          /* Discussion */
.icon--email            /* Mail */
.icon--expand           /* Expand/collapse */
.icon--collapse
.icon--filter           /* Filtering */
.icon--gear             /* Settings */
.icon--grid             /* Grid view */
.icon--home             /* Home */
.icon--lock             /* Security */
.icon--menu             /* Hamburger */
.icon--menu-dots-horizontal
.icon--menu-dots-vertical
.icon--pencil           /* Edit */
.icon--person           /* User */
.icon--person-add
.icon--search           /* Search */
.icon--settings
.icon--share            /* Share */
.icon--tag              /* Labels */
.icon--trash            /* Delete */
/* + 60 more icons */
```

---

## Animation

### Easing Functions

```css
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
--ease-out-overshoot: cubic-bezier(0.25, 1.75, 0.5, 1);
--ease-out-overshoot-subtle: cubic-bezier(0.25, 1.25, 0.5, 1);
```

### Keyframe Animations

```css
@keyframes shake        /* Error feedback */
@keyframes pulse        /* Loading/attention */
@keyframes slide-up     /* Entrance from bottom */
@keyframes slide-down   /* Exit to bottom */
@keyframes scale-fade-out
@keyframes react        /* Emoji reaction pop */
@keyframes wobble       /* Organic blob animation */
@keyframes blink        /* Blinking cursor/indicator */
@keyframes gradient     /* Animated gradient */
@keyframes submitting   /* Button loading dots */
@keyframes success      /* Success flash */
@keyframes zoom-fade    /* Check mark float-up */
```

### Animation Utilities

```css
.shake { animation: shake 400ms both; }
```

---

## Accessibility

### Focus Rings

```css
--focus-ring-color: var(--color-link);
--focus-ring-offset: 1px;
--focus-ring-size: 2px;
--focus-ring: var(--focus-ring-size) solid var(--focus-ring-color);
```

Applied to all interactive elements via `:focus-visible`:

```css
:is(a, button, input, textarea, .switch, .btn):focus-visible {
  border-radius: 0.25ch;
  outline: var(--focus-ring-size) solid var(--focus-ring-color);
  outline-offset: var(--focus-ring-offset);
}
```

### Screen Reader Utilities

```css
.visually-hidden,
.for-screen-reader {
  block-size: 1px;
  clip-path: inset(50%);
  inline-size: 1px;
  overflow: hidden;
  position: absolute;
  white-space: nowrap;
}
```

### Reduced Motion

Animations respect user preferences via `prefers-reduced-motion`.

---

## Responsive Design

### Breakpoints

| Query | Target |
|-------|--------|
| `max-width: 519px` | Small mobile |
| `max-width: 639px` | Mobile |
| `min-width: 640px` | Desktop+ |
| `max-width: 799px` | Tablet |
| `min-width: 100ch` | Large screens |

### Touch Detection

```css
@media (any-hover: none) { /* Touch devices */ }
@media (any-hover: hover) { /* Mouse devices */ }
@media (pointer: coarse)  { /* Touch pointer */ }
```

### Visibility Utilities

```css
.hide-on-touch    /* Hide on touch devices */
.show-on-touch    /* Show only on touch */
.hide-in-pwa      /* Hide in standalone PWA mode */
.hide-in-browser  /* Hide in browser mode */
```

### Safe Areas

Support for device notches/cutouts:

```css
padding-inline:
  calc(var(--main-padding) + env(safe-area-inset-left))
  calc(var(--main-padding) + env(safe-area-inset-right));
```

---

## Utilities

### Layout

```css
/* Flexbox */
.flex / .flex-inline / .flex-column / .flex-wrap
.flex-1 / .flex-item-grow / .flex-item-shrink / .flex-item-no-shrink

/* Alignment */
.justify-start / .justify-center / .justify-end / .justify-space-between
.align-start / .align-center / .align-end
.align-self-start / .align-self-center / .align-self-end

/* Gap */
.gap        /* Standard gap */
.gap-half   /* Half gap */
.gap-none   /* No gap */
```

### Sizing

```css
.full-width / .half-width / .max-width
.min-content / .fit-content
```

### Backgrounds

```css
.fill             /* Canvas color */
.fill-black       /* Ink color */
.fill-white       /* Inverted ink */
.fill-shade       /* Light background */
.fill-selected    /* Selection highlight */
.fill-highlight   /* Yellow highlight */
.fill-transparent
```

### Borders

```css
.border / .border-block / .border-top / .border-bottom
.borderless
.border-radius    /* 0.5em radius */
```

### Shadows

```css
--shadow: 0 0 0 1px oklch(var(--lch-black) / 5%),
          0 0.2em 0.2em oklch(var(--lch-black) / 5%),
          0 0.4em 0.4em oklch(var(--lch-black) / 5%),
          0 0.8em 0.8em oklch(var(--lch-black) / 5%);

.shadow { box-shadow: var(--shadow); }
```

### Overflow

```css
.overflow-x       /* Horizontal scroll with snap */
.overflow-y       /* Vertical scroll with snap */
.overflow-clip    /* Clip with nowrap */
.overflow-ellipsis /* Ellipsis truncation */
.overflow-line-clamp { --lines: 2; } /* Multi-line truncation */
.hide-scrollbar   /* Hide scrollbar visually */
```

### Position

```css
.position-relative
.position-sticky { --inset: 0 auto auto auto; --z: 1; }
```

---

## Z-Index Scale

```css
--z-events-column-header: 1;
--z-events-day-header: 3;
--z-popup: 10;
--z-nav: 30;
--z-flash: 40;
--z-tooltip: 50;
--z-bar: 60;
--z-tray: 61;
```

---

## Layout Tokens

```css
--main-width: 1400px;
--main-padding: clamp(var(--inline-space), 3vw, calc(var(--inline-space) * 3));
--tray-size: clamp(12rem, 25dvw, 24rem);
--footer-height: 2.65rem;
```

---

## File Organization

| Category | Files |
|----------|-------|
| **Foundation** | `_global.css`, `base.css`, `reset.css`, `layout.css` |
| **Components** | `buttons.css`, `cards.css`, `inputs.css`, `toggles.css`, `dialog.css` |
| **Content** | `comments.css`, `rich-text-content.css`, `markdown.css` |
| **Navigation** | `header.css`, `nav.css`, `bar.css`, `trays.css` |
| **Overlays** | `popup.css`, `lightbox.css`, `bubble.css`, `tooltips.css` |
| **Feedback** | `flash.css`, `notifications.css`, `reactions.css` |
| **UI Controls** | `avatars.css`, `icons.css`, `spinners.css`, `badges.css` |
| **Effects** | `animation.css`, `golden-effect.css` |
| **Utilities** | `utilities.css` |

---

## Best Practices

### 1. Use CSS Variables

Always use design tokens instead of hard-coded values:

```css
/* Good */
color: var(--color-ink);
padding: var(--block-space) var(--inline-space);

/* Avoid */
color: #1a1a1a;
padding: 16px 8px;
```

### 2. Leverage Cascade Layers

Place styles in appropriate layers for predictable specificity:

```css
@layer components {
  .my-component { ... }
}
```

### 3. Use OKLCH for Custom Colors

When creating new colors, use OKLCH for perceptual consistency:

```css
--my-color: oklch(55% 0.15 240);
```

### 4. Respect Dark Mode

Always define dark mode variants for new colors:

```css
:root {
  --my-color: oklch(55% 0.15 240);

  @media (prefers-color-scheme: dark) {
    --my-color: oklch(75% 0.12 240);
  }
}
```

### 5. Use Logical Properties

Prefer logical properties for internationalization:

```css
/* Good */
margin-inline-start: var(--inline-space);
padding-block: var(--block-space);

/* Avoid */
margin-left: 1ch;
padding-top: 1rem;
```

### 6. Mobile-First Approach

Write base styles for mobile, then enhance for larger screens:

```css
.component {
  flex-direction: column;

  @media (min-width: 640px) {
    flex-direction: row;
  }
}
```

---

## Quick Reference

### Common Patterns

**Centered Content:**
```css
.center .txt-align-center
```

**Card with Color:**
```css
<div class="card" style="--card-color: var(--color-card-3)">
```

**Button Variants:**
```css
<button class="btn btn--link">Primary</button>
<button class="btn btn--negative">Delete</button>
<button class="btn btn--positive">Confirm</button>
```

**Icon Button:**
```css
<button class="btn" aria-label="Close">
  <span class="icon icon--close"></span>
</button>
```

**Responsive Hide:**
```css
<span class="hide-on-touch">Desktop only</span>
<span class="show-on-touch">Touch only</span>
```

---

*This style guide reflects the Fizzy design system as of 2024. Keep design tokens synchronized across projects for brand consistency.*

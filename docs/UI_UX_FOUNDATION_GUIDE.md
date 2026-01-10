# Fizzy UI/UX Foundation Guide

**A comprehensive handover document for frontend developers**

This guide documents the UI/UX patterns, design system, and frontend architecture used in Fizzy. It serves as the foundation for building consistent, accessible, and performant Ruby on Rails applications.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Design Tokens & CSS Variables](#2-design-tokens--css-variables)
3. [Color System](#3-color-system)
4. [Typography](#4-typography)
5. [Spacing System](#5-spacing-system)
6. [CSS Architecture](#6-css-architecture)
7. [Component Library](#7-component-library)
8. [JavaScript & Stimulus](#8-javascript--stimulus)
9. [Responsive Design](#9-responsive-design)
10. [Accessibility](#10-accessibility)
11. [Animation & Transitions](#11-animation--transitions)
12. [Forms & Validation](#12-forms--validation)
13. [Icons](#13-icons)
14. [Dark Mode & Theming](#14-dark-mode--theming)
15. [Performance Patterns](#15-performance-patterns)
16. [View Layer Organization](#16-view-layer-organization)
17. [Quick Reference](#17-quick-reference)

---

## 1. Architecture Overview

### Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **CSS** | Vanilla CSS with CSS Layers | Styling without frameworks |
| **JavaScript** | Stimulus (Hotwired) | Interactive behavior |
| **Navigation** | Turbo (Hotwired) | SPA-like page transitions |
| **Rich Text** | Action Text + Lexxy | WYSIWYG editing |
| **File Uploads** | Active Storage | Attachments |
| **Module Loading** | Importmap | No build step for JS |

### Key Principles

1. **No CSS Framework** - Pure vanilla CSS with modern features
2. **No Build Tools** - Importmap for JS, native CSS
3. **Progressive Enhancement** - Works without JS, enhanced with Stimulus
4. **Native HTML First** - Use `<dialog>`, `<details>`, native form controls
5. **CSS Variables for Theming** - Single source of truth for design tokens
6. **Accessibility First** - ARIA, keyboard navigation, screen reader support

### File Structure

```
app/
├── assets/
│   └── stylesheets/
│       ├── _global.css          # Design tokens (import first)
│       ├── reset.css            # CSS reset
│       ├── base.css             # Base element styles
│       ├── buttons.css          # Button component
│       ├── inputs.css           # Form inputs
│       ├── dialog.css           # Modal/dialog
│       ├── utilities.css        # Utility classes
│       └── [component].css      # Feature-specific styles
├── javascript/
│   ├── application.js           # Entry point
│   ├── controllers/             # Stimulus controllers (58 total)
│   ├── helpers/                 # JS utility functions
│   └── initializers/            # Setup scripts
├── helpers/
│   ├── application_helper.rb    # Global helpers
│   ├── avatars_helper.rb        # Avatar rendering
│   ├── forms_helper.rb          # Form helpers
│   └── [feature]_helper.rb      # Feature-specific helpers
└── views/
    ├── layouts/
    │   ├── application.html.erb # Main layout
    │   └── shared/              # Shared partials
    └── [feature]/               # Feature views
```

---

## 2. Design Tokens & CSS Variables

All design tokens are defined in `app/assets/stylesheets/_global.css`. This file MUST be imported first.

### Declaring the Layer Order

```css
@layer reset, base, components, modules, utilities, native, platform;
```

This cascade order ensures:
1. **reset** - CSS reset (lowest specificity)
2. **base** - Element styles
3. **components** - Reusable components
4. **modules** - Feature-specific styles
5. **utilities** - Override utilities (highest specificity)
6. **native/platform** - Platform-specific overrides

### Core Variables

```css
:root {
  /* Spacing */
  --inline-space: 1ch;                              /* Horizontal spacing */
  --inline-space-half: calc(var(--inline-space) / 2);
  --inline-space-double: calc(var(--inline-space) * 2);
  --block-space: 1rem;                              /* Vertical spacing */
  --block-space-half: calc(var(--block-space) / 2);
  --block-space-double: calc(var(--block-space) * 2);

  /* Component sizing */
  --btn-size: 2.65em;
  --footer-height: 2.65rem;
  --tray-size: clamp(12rem, 25dvw, 24rem);
  --main-padding: clamp(var(--inline-space), 3vw, calc(var(--inline-space) * 3));
  --main-width: 1400px;

  /* Focus rings */
  --focus-ring-color: var(--color-link);
  --focus-ring-offset: 1px;
  --focus-ring-size: 2px;
  --focus-ring: var(--focus-ring-size) solid var(--focus-ring-color);

  /* Animation */
  --dialog-duration: 150ms;
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-out-overshoot: cubic-bezier(0.25, 1.75, 0.5, 1);
  --ease-out-overshoot-subtle: cubic-bezier(0.25, 1.25, 0.5, 1);
}
```

### Z-Index Scale

```css
:root {
  --z-events-column-header: 1;
  --z-events-day-header: 3;
  --z-popup: 10;
  --z-nav: 20;
  --z-flash: 30;
  --z-tooltip: 40;
  --z-bar: 50;
  --z-tray: 51;
  --z-welcome: 52;
  --z-nav-open: 100;
}
```

Always use these variables for z-index to maintain stacking order consistency.

---

## 3. Color System

### OKLCH Color Space

Fizzy uses the **OKLCH color space** for perceptually uniform colors. OKLCH provides better color manipulation than RGB/HSL.

```css
/* Format: lightness% chroma hue */
--lch-blue-dark: 57.02% 0.1895 260.46;

/* Usage */
color: oklch(var(--lch-blue-dark));
```

### Color Palette Structure

Each color has 7 shades following a consistent naming convention:

| Shade | Lightness (Light Mode) | Use Case |
|-------|------------------------|----------|
| `darkest` | 26% | Primary text, icons |
| `darker` | 40% | Secondary text |
| `dark` | 55-59% | Links, active states |
| `medium` | 62-74% | Tags, badges |
| `light` | 84% | Backgrounds |
| `lighter` | 92% | Hover backgrounds |
| `lightest` | 96% | Subtle backgrounds |

### Available Colors

```css
/* Grayscale */
--lch-ink-[darkest|darker|dark|medium|light|lighter|lightest]

/* Warm neutral */
--lch-uncolor-[darkest|darker|dark|medium|light|lighter|lightest]

/* Semantic colors (8 hues) */
--lch-red-[shade]      /* Hue: ~38 */
--lch-yellow-[shade]   /* Hue: ~70 */
--lch-lime-[shade]     /* Hue: ~112 */
--lch-green-[shade]    /* Hue: ~146 */
--lch-aqua-[shade]     /* Hue: ~208 */
--lch-blue-[shade]     /* Hue: ~260 */
--lch-violet-[shade]   /* Hue: ~286 */
--lch-purple-[shade]   /* Hue: ~308 */
--lch-pink-[shade]     /* Hue: ~342 */
```

### Named Color Abstractions

Use these semantic color names in your code:

```css
/* Core colors */
--color-ink: oklch(var(--lch-ink-darkest));        /* Primary text */
--color-canvas: oklch(var(--lch-canvas));          /* Background */
--color-ink-inverted: oklch(var(--lch-ink-inverted)); /* Text on dark bg */

/* Semantic colors */
--color-negative: oklch(var(--lch-red-dark));      /* Errors, destructive */
--color-positive: oklch(var(--lch-green-dark));    /* Success */
--color-link: oklch(var(--lch-blue-dark));         /* Links */
--color-selected: oklch(var(--lch-blue-lighter));  /* Selected state */
--color-highlight: oklch(var(--lch-yellow-lighter)); /* Highlights */
--color-marker: oklch(var(--lch-red-medium));      /* Alerts, badges */

/* Card colors (for categorization) */
--color-card-default: oklch(var(--lch-blue-dark));
--color-card-complete: var(--color-ink-darker);
--color-card-1 through --color-card-8             /* 8 category colors */
```

### Using Colors

```css
/* Direct usage */
.element {
  color: var(--color-ink);
  background: var(--color-canvas);
  border-color: var(--color-ink-lighter);
}

/* Dynamic color mixing */
.card {
  background: color-mix(in srgb, var(--card-color) 15%, transparent);
}

/* With opacity */
.overlay {
  background: oklch(var(--lch-black) / 50%);
}
```

---

## 4. Typography

### Font Stack

```css
:root {
  --font-sans: "Adwaita Sans", -apple-system, BlinkMacSystemFont,
               "Segoe UI Variable Fizzy", "Segoe UI", "Noto Sans",
               Helvetica, Arial, sans-serif,
               "Apple Color Emoji", "Segoe UI Emoji";
  --font-serif: ui-serif, serif;
  --font-mono: ui-monospace, monospace;
}
```

### Type Scale

```css
:root {
  --text-xx-small: 0.55rem;   /* 8.8px */
  --text-x-small: 0.75rem;    /* 12px */
  --text-small: 0.85rem;      /* 13.6px */
  --text-normal: 1rem;        /* 16px - base */
  --text-medium: 1.1rem;      /* 17.6px */
  --text-large: 1.5rem;       /* 24px */
  --text-x-large: 1.8rem;     /* 28.8px */
  --text-xx-large: 2.5rem;    /* 40px */
}
```

### Responsive Typography

Text sizes automatically increase on mobile for better readability:

```css
@media (max-width: 639px) {
  :root {
    --text-xx-small: 0.65rem;
    --text-x-small: 0.85rem;
    --text-small: 0.95rem;
    --text-normal: 1.1rem;
    --text-medium: 1.2rem;
  }
}
```

### Typography Utilities

```css
/* Size classes */
.txt-xx-small { font-size: var(--text-xx-small); }
.txt-x-small  { font-size: var(--text-x-small); }
.txt-small    { font-size: var(--text-small); }
.txt-normal   { font-size: var(--text-normal); }
.txt-medium   { font-size: var(--text-medium); }
.txt-large    { font-size: var(--text-large); }
.txt-x-large  { font-size: var(--text-x-large); }
.txt-xx-large { font-size: var(--text-xx-large); }

/* Alignment */
.txt-align-center { text-align: center; }
.txt-align-start  { text-align: start; }
.txt-align-end    { text-align: end; }

/* Color classes */
.txt-ink      { color: var(--color-ink); }
.txt-subtle   { color: var(--color-ink-dark); }
.txt-negative { color: var(--color-negative); }
.txt-positive { color: var(--color-positive); }
.txt-link     { color: var(--color-link); text-decoration: underline; }

/* Weight */
.font-weight-normal { font-weight: normal; }
.font-weight-bold   { font-weight: bold; }
.font-weight-black  { font-weight: 900; }

/* Formatting */
.txt-nowrap    { white-space: nowrap; }
.txt-break     { word-break: break-word; }
.txt-uppercase { text-transform: uppercase; }
```

### Base Typography Settings

```css
body {
  -moz-osx-font-smoothing: grayscale;
  -webkit-font-smoothing: antialiased;
  font-family: var(--font-sans);
  line-height: 1.375;
  text-rendering: optimizeLegibility;
}
```

---

## 5. Spacing System

### Spacing Variables

Fizzy uses a **dual-axis spacing system**:

- **Inline (horizontal)**: Based on `1ch` (character width)
- **Block (vertical)**: Based on `1rem` (root em)

```css
:root {
  /* Horizontal */
  --inline-space: 1ch;                                /* ~8px */
  --inline-space-half: calc(var(--inline-space) / 2); /* ~4px */
  --inline-space-double: calc(var(--inline-space) * 2); /* ~16px */

  /* Vertical */
  --block-space: 1rem;                               /* 16px */
  --block-space-half: calc(var(--block-space) / 2); /* 8px */
  --block-space-double: calc(var(--block-space) * 2); /* 32px */
}
```

### Why `ch` for Horizontal Spacing?

Using `ch` units aligns horizontal spacing with typographic rhythm, making UI elements feel more natural alongside text.

### Spacing Utilities

#### Padding

```css
.pad        { padding: var(--block-space) var(--inline-space); }
.pad-double { padding: var(--block-space-double) var(--inline-space-double); }

.pad-block       { padding-block: var(--block-space); }
.pad-block-start { padding-block-start: var(--block-space); }
.pad-block-end   { padding-block-end: var(--block-space); }
.pad-block-half  { padding-block: var(--block-space-half); }

.pad-inline        { padding-inline: var(--inline-space); }
.pad-inline-double { padding-inline: var(--inline-space-double); }

.unpad { padding: 0; }
```

#### Margin

```css
.margin            { margin: var(--block-space) var(--inline-space); }
.margin-block      { margin-block: var(--block-space); }
.margin-block-half { margin-block: var(--block-space-half); }
.margin-block-start { margin-block-start: var(--block-space); }
.margin-block-end   { margin-block-end: var(--block-space); }

.margin-inline      { margin-inline: var(--inline-space); }
.margin-inline-half { margin-inline: var(--inline-space-half); }

.margin-none { margin: 0; }
.center      { margin-inline: auto; }
```

#### Gap (for Flexbox/Grid)

```css
.gap {
  column-gap: var(--column-gap, var(--inline-space));
  row-gap: var(--row-gap, var(--block-space));
}

.gap-half {
  column-gap: var(--column-gap, var(--inline-space-half));
  row-gap: var(--row-gap, var(--block-space-half));
}

.gap-none { gap: 0; }
```

---

## 6. CSS Architecture

### Layer System

All CSS is organized into cascade layers for predictable specificity:

```css
/* In _global.css */
@layer reset, base, components, modules, utilities, native, platform;

/* In individual files */
@layer components {
  .btn { /* ... */ }
}

@layer utilities {
  .flex { display: flex; }
}
```

### File Organization

| File | Layer | Purpose |
|------|-------|---------|
| `_global.css` | (declares layers) | Design tokens, CSS variables |
| `reset.css` | reset | Modern CSS reset |
| `base.css` | base | HTML element styles |
| `buttons.css` | components | Button component |
| `inputs.css` | components | Form inputs |
| `dialog.css` | components | Modal dialogs |
| `cards.css` | components | Card component |
| `utilities.css` | utilities | Helper classes |
| `ios.css` | platform | iOS-specific |
| `android.css` | platform | Android-specific |

### Modern CSS Features Used

```css
/* Container queries */
.card-columns {
  container-type: inline-size;
}

@container (min-width: 800px) {
  .card { /* responsive styles */ }
}

/* :has() selector */
.btn:has(input:checked) {
  --btn-background: var(--color-ink);
}

/* :where() for zero specificity */
:where(.list-style-none) {
  list-style: none;
}

/* color-mix() */
background: color-mix(in srgb, var(--card-color) 15%, transparent);

/* @starting-style for animations */
@starting-style {
  dialog[open] {
    opacity: 0;
    transform: scale(0.2);
  }
}

/* Logical properties */
padding-inline: var(--inline-space);
margin-block-end: var(--block-space);
```

---

## 7. Component Library

### Buttons

**File:** `app/assets/stylesheets/buttons.css`

#### Base Button

```erb
<button class="btn">Default Button</button>
<button class="btn btn--link">Primary Action</button>
<button class="btn btn--negative">Destructive</button>
<button class="btn btn--positive">Success</button>
```

#### Button Variants

| Class | Use Case |
|-------|----------|
| `.btn` | Default button |
| `.btn--plain` | Text-only, no border |
| `.btn--link` | Primary action (blue) |
| `.btn--negative` | Destructive action (red) |
| `.btn--positive` | Success action (green) |
| `.btn--reversed` | Dark background |
| `.btn--circle` | Icon button (square) |
| `.btn--back` | Back navigation |

#### Icon Buttons

```erb
<!-- Icon-only button (requires aria-label) -->
<button class="btn" aria-label="Close">
  <%= icon_tag("close") %>
</button>

<!-- Button with icon and text -->
<button class="btn btn--link">
  <%= icon_tag("add") %>
  <span>Add Item</span>
</button>
```

#### Button Groups

```erb
<div class="btn__group flex">
  <form>
    <button class="btn">Option 1</button>
  </form>
  <form>
    <button class="btn">Option 2</button>
  </form>
</div>
```

#### Toggle Buttons (with checkbox/radio)

```erb
<label class="btn">
  <input type="checkbox" name="toggle">
  <span>Toggle Option</span>
</label>
```

### Inputs

**File:** `app/assets/stylesheets/inputs.css`

#### Text Inputs

```erb
<input type="text" class="input" placeholder="Enter text">
<input type="email" class="input" placeholder="Email address">
<textarea class="input" rows="4">Content</textarea>
```

#### Input Customization

```css
.input {
  --input-background: transparent;
  --input-border-color: var(--color-ink-medium);
  --input-border-radius: 0.5em;
  --input-border-size: 1px;
  --input-color: var(--color-ink);
  --input-padding: 0.5em 0.75em;
}
```

#### Switch Toggle

```erb
<label class="switch">
  <input type="checkbox" class="switch__input">
  <span class="switch__btn"></span>
  <span class="switch__label">Enable feature</span>
</label>
```

### Dialogs

**File:** `app/assets/stylesheets/dialog.css`

#### Native Dialog

```erb
<dialog class="dialog" data-controller="dialog">
  <header>
    <h2>Dialog Title</h2>
    <button data-action="click->dialog#close" aria-label="Close">
      <%= icon_tag("close") %>
    </button>
  </header>
  <main>
    <!-- Content -->
  </main>
  <footer>
    <button class="btn" data-action="click->dialog#close">Cancel</button>
    <button class="btn btn--link">Confirm</button>
  </footer>
</dialog>
```

### Panels

```erb
<div class="panel">
  <h2>Panel Title</h2>
  <p>Panel content...</p>
</div>

<div class="panel panel--centered">
  <!-- Centered content -->
</div>
```

### Flash Messages

```erb
<%= turbo_frame_tag :flash do %>
  <% if flash.any? %>
    <div class="flash" data-controller="element-removal"
         data-action="animationend->element-removal#remove">
      <div class="flash__inner">
        <%= flash[:notice] || flash[:alert] %>
      </div>
    </div>
  <% end %>
<% end %>
```

---

## 8. JavaScript & Stimulus

### Application Entry Point

**File:** `app/javascript/application.js`

```javascript
import "@hotwired/turbo-rails"
import "initializers"
import "controllers"
import "lexxy"
import "@rails/actiontext"
```

### Importmap Configuration

**File:** `config/importmap.rb`

```ruby
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/request.js", to: "@rails--request.js"

pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/helpers", under: "helpers"
pin_all_from "app/javascript/initializers", under: "initializers"
```

### Stimulus Controllers

**58 controllers** located in `app/javascript/controllers/`

#### Key Controllers

| Controller | Purpose |
|------------|---------|
| `dialog_controller.js` | Modal/non-modal dialog management |
| `form_controller.js` | Form validation, submission |
| `auto_submit_controller.js` | Auto-submit forms on connect |
| `hotkey_controller.js` | Keyboard shortcuts |
| `navigable_list_controller.js` | Arrow key navigation |
| `drag_and_drop_controller.js` | Drag and drop cards |
| `theme_controller.js` | Dark/light mode switching |
| `tooltip_controller.js` | Hover tooltips |
| `combobox_controller.js` | Accessible select replacement |
| `toggle_class_controller.js` | CSS class toggling |

### Controller Pattern

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "content"]
  static values = {
    modal: { type: Boolean, default: true },
    autoOpen: { type: Boolean, default: false }
  }
  static classes = ["active"]

  connect() {
    // Called when controller connects to DOM
    if (this.autoOpenValue) this.open()
  }

  open() {
    if (this.modalValue) {
      this.dialogTarget.showModal()
    } else {
      this.dialogTarget.show()
    }
    this.dialogTarget.setAttribute("aria-hidden", "false")
  }

  close() {
    this.dialogTarget.close()
    this.dialogTarget.setAttribute("aria-hidden", "true")
  }
}
```

### JavaScript Helpers

**Location:** `app/javascript/helpers/`

#### timing_helpers.js

```javascript
export function throttle(fn, delay) { /* ... */ }
export function debounce(fn, delay) { /* ... */ }
export function nextEventLoopTick() { /* ... */ }
export function nextFrame() { /* ... */ }
export function delay(ms) { /* ... */ }
```

#### platform_helpers.js

```javascript
export function isTouchDevice() {
  return "ontouchstart" in window && navigator.maxTouchPoints > 0
}

export function isIos() {
  return /iPhone|iPad/.test(navigator.userAgent)
}

export function isMobile() {
  return isIos() || isAndroid()
}
```

#### form_helpers.js

```javascript
export function submitForm(form) {
  // Uses @rails/request.js for fetch-based submission
}
```

### Using Stimulus in Views

```erb
<div data-controller="dialog tooltip"
     data-dialog-modal-value="true"
     data-action="click->dialog#open">

  <button data-dialog-target="trigger">Open</button>

  <dialog data-dialog-target="dialog">
    <p data-tooltip-target="content">Content with tooltip</p>
    <button data-action="click->dialog#close">Close</button>
  </dialog>
</div>
```

---

## 9. Responsive Design

### Breakpoints

```css
/* Mobile: 0 - 639px */
@media (max-width: 639px) { /* mobile styles */ }

/* Tablet/Desktop: 640px+ */
@media (min-width: 640px) { /* desktop styles */ }

/* Medium desktop: 800px+ */
@media (min-width: 800px) { /* wider desktop */ }

/* Large desktop: 960px+ */
@media (min-width: 960px) { /* extra wide */ }
```

### Touch Device Detection

```css
/* Devices with hover capability (mouse) */
@media (any-hover: hover) {
  .btn:hover {
    filter: brightness(0.9);
  }
}

/* Touch-only devices */
@media (any-hover: none) {
  .hide-on-touch { display: none; }
}
```

### Mobile-First Patterns

```css
/* Button size - larger on mobile for touch */
.btn--circle {
  --btn-size: 2.65em;

  @media (max-width: 639px) {
    --btn-size: 3em;  /* 48px touch target */
  }
}

/* Typography - larger on mobile */
:root {
  --text-normal: 1rem;

  @media (max-width: 639px) {
    --text-normal: 1.1rem;
  }
}
```

### Safe Area Insets (Notched Devices)

```css
.layout {
  padding-inline:
    calc(var(--main-padding) + env(safe-area-inset-left))
    calc(var(--main-padding) + env(safe-area-inset-right));
  padding-block-end: env(safe-area-inset-bottom);
}
```

### Container Queries

```css
.card-columns {
  container-type: inline-size;
}

@container (min-width: 800px) {
  .cards {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

### Responsive Utilities

```css
/* Hide on touch devices */
.hide-on-touch {
  @media (any-hover: none) {
    display: none;
  }
}

/* Show only on touch devices */
.show-on-touch {
  display: none;
  @media (any-hover: none) {
    display: unset;
  }
}

/* Hide in PWA mode */
.hide-in-pwa {
  @media (display-mode: standalone) {
    display: none;
  }
}
```

---

## 10. Accessibility

### Focus Management

```css
/* Default focus ring */
:focus-visible {
  outline: var(--focus-ring-size) solid var(--focus-ring-color);
  outline-offset: var(--focus-ring-offset);
}

/* Custom focus ring per component */
.btn--link {
  --focus-ring-color: var(--color-link);
}

.btn--negative {
  --focus-ring-color: var(--color-negative);
}
```

### Screen Reader Text

```erb
<!-- Visually hidden but accessible -->
<span class="for-screen-reader">Close dialog</span>
<span class="visually-hidden">Additional context</span>
```

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

### Skip Navigation

```erb
<!-- In layout -->
<a href="#main" class="header__skip-navigation btn" data-turbo="false">
  Skip to main content
</a>
```

### ARIA Attributes

```erb
<!-- Icon buttons need aria-label -->
<button class="btn" aria-label="Close dialog">
  <%= icon_tag("close") %>
</button>

<!-- Loading states -->
<form aria-busy="true">
  <button disabled>Saving...</button>
</form>

<!-- Expanded/collapsed -->
<button aria-expanded="false" aria-controls="menu-content">
  Menu
</button>

<!-- Role for custom components -->
<ul class="popup__list" role="listbox">
  <li role="option" aria-selected="true">Option 1</li>
</ul>
```

### Keyboard Navigation

```erb
<!-- Hotkey controller for keyboard shortcuts -->
<button data-controller="hotkey"
        data-action="keydown.left@document->hotkey#click
                     keydown.esc@document->hotkey#click">
  Back
</button>
```

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Color Contrast

The OKLCH color system ensures consistent contrast ratios:
- Text on light backgrounds: `--lch-ink-darkest` (26% lightness)
- Text on dark backgrounds: Uses inverted values (96% lightness)

---

## 11. Animation & Transitions

### Base Transitions

```css
:is(a, button, input, textarea, .switch, .btn) {
  transition: 100ms ease-out;
  transition-property: background-color, border-color, box-shadow,
                       filter, outline;
}
```

### Easing Functions

```css
:root {
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-out-overshoot: cubic-bezier(0.25, 1.75, 0.5, 1);
  --ease-out-overshoot-subtle: cubic-bezier(0.25, 1.25, 0.5, 1);
}
```

### Keyframe Animations

**File:** `app/assets/stylesheets/animation.css`

```css
/* Flash message appear and fade */
@keyframes appear-then-fade {
  0%, 100% { opacity: 0; }
  5%, 60%  { opacity: 1; }
}

/* Shake for validation errors */
@keyframes shake {
  0%  { transform: translateX(-2rem); }
  25% { transform: translateX(2rem); }
  50% { transform: translateX(-1rem); }
  75% { transform: translateX(1rem); }
}

/* Slide animations */
@keyframes slide-up-fade-in {
  from { transform: translateY(2rem); opacity: 0; }
  to   { transform: translateY(0); opacity: 1; }
}

/* Button loading spinner */
@keyframes submitting {
  0%    { -webkit-mask-position: 0% 0%, 50% 0%, 100% 0%; }
  /* ... animates three dots */
}

/* Success feedback */
@keyframes success {
  0%  { background-color: var(--color-border-darker); scale: 0.8; }
  33% { background-color: var(--color-border-darker); scale: 1; }
}

/* Reaction pop */
@keyframes react {
  0%   { transform: scale(0.85); opacity: 0; }
  50%  { transform: scale(1.15); opacity: 1; }
  100% { transform: scale(1); }
}
```

### Dialog Animation

```css
.dialog {
  opacity: 0;
  transform: scale(0.2);
  transform-origin: top center;
  transition: var(--dialog-duration) allow-discrete;
  transition-property: display, opacity, overlay, transform;

  &[open] {
    opacity: 1;
    transform: scale(1);
  }

  &::backdrop {
    opacity: 0;
    transition: var(--dialog-duration) allow-discrete;

    dialog[open] & {
      opacity: 0.5;
    }
  }

  @starting-style {
    &[open] {
      opacity: 0;
      transform: scale(0.2);
    }
  }
}
```

### View Transitions

For smooth page morphing with Turbo:

```css
.card {
  view-transition-name: var(--card-transition-name);
}
```

```erb
<article style="--card-transition-name: card-<%= card.id %>">
```

---

## 12. Forms & Validation

### Auto-Submit Forms

**Helper:** `app/helpers/forms_helper.rb`

```erb
<%= auto_submit_form_with model: @setting, url: setting_path do |f| %>
  <%= f.select :option, options %>
<% end %>
```

This adds `data-controller="auto-submit"` automatically.

### Form Validation

**Controller:** `app/javascript/controllers/form_controller.js`

```erb
<%= form_with model: @user, data: { controller: "form", action: "submit->form#preventEmptySubmit" } do |f| %>
  <%= f.text_field :name,
      data: {
        form_target: "input",
        validation_message: "Name is required"
      } %>
  <%= f.submit "Save", data: { form_target: "submit" } %>
<% end %>
```

### Error Display

```erb
<% if @user.errors.any? %>
  <div class="margin-block-half txt-negative txt-small">
    <p class="margin-block-none font-weight-bold">
      Your changes couldn't be saved:
    </p>
    <ul class="margin-block-none">
      <% @user.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

### Loading States

Forms automatically show loading state when `aria-busy="true"`:

```erb
<%= form_with url: path, data: { controller: "form" } do |f| %>
  <%= f.submit "Save", disabled: false %>
<% end %>
```

```javascript
// In controller
this.element.setAttribute("aria-busy", "true")
this.submitTarget.disabled = true
```

The button will show an animated spinner while disabled and form is busy.

### Input Styling Tips

```css
/* Prevent iOS zoom on input focus */
.input {
  font-size: max(16px, 1em);
}

/* Custom autofill styling */
.input:autofill {
  -webkit-text-fill-color: var(--color-ink);
  -webkit-box-shadow: 0 0 0px 1000px var(--color-selected) inset;
}
```

---

## 13. Icons

### Icon System

**File:** `app/assets/stylesheets/icons.css`

Icons are implemented as CSS masks, allowing them to inherit color from `currentColor`.

### Icon Helper

```ruby
# app/helpers/application_helper.rb
def icon_tag(name, **options)
  tag.span class: class_names("icon icon--#{name}", options.delete(:class)),
           "aria-hidden": true,
           **options
end
```

### Usage

```erb
<!-- Basic icon -->
<%= icon_tag("close") %>

<!-- With custom class -->
<%= icon_tag("check", class: "txt-positive") %>

<!-- In a button -->
<button class="btn" aria-label="Close">
  <%= icon_tag("close") %>
</button>
```

### Available Icons

100+ icons available, including:
- Navigation: `arrow-left`, `arrow-right`, `arrow-up`, `arrow-down`
- Actions: `add`, `close`, `check`, `edit`, `trash`, `search`
- UI: `menu`, `settings`, `bell`, `bookmark`, `pin`
- Content: `comment`, `attachment`, `image`, `link`

### Icon Sizing

```css
.icon {
  --icon-size: 1em;  /* Default: inherits font size */

  block-size: var(--icon-size);
  inline-size: var(--icon-size);
  background-color: currentColor;
  mask-image: var(--svg);
}
```

Override size with:

```erb
<%= icon_tag("check", style: "--icon-size: 2em") %>
```

---

## 14. Dark Mode & Theming

### Theme Modes

1. **Auto** (default): Follows system preference
2. **Light**: Forced light mode
3. **Dark**: Forced dark mode

### Implementation

**CSS Variables:** Dark mode redefines all OKLCH color values.

```css
/* Light mode (default) */
:root {
  --lch-canvas: var(--lch-white);
  --lch-ink-darkest: 26% 0.05 264;
  /* ... */
}

/* Dark mode - explicit choice */
html[data-theme="dark"] {
  --lch-canvas: 20% 0.0195 232.58;
  --lch-ink-darkest: 96.02% 0.0034 260;  /* Inverted */
  /* ... */
}

/* Dark mode - system preference fallback */
@media (prefers-color-scheme: dark) {
  html:not([data-theme]) {
    /* Same as above */
  }
}
```

### Theme Switching

**Controller:** `app/javascript/controllers/theme_controller.js`

```javascript
// Stores preference in localStorage
// Uses View Transitions API for smooth theme change
document.startViewTransition(() => {
  document.documentElement.dataset.theme = newTheme
})
```

### Theme Switcher UI

```erb
<div class="theme-switcher" data-controller="theme">
  <label class="theme-switcher__btn">
    <input type="radio" name="theme" value="light"
           data-action="change->theme#switch">
    Light
  </label>
  <label class="theme-switcher__btn">
    <input type="radio" name="theme" value="auto"
           data-action="change->theme#switch">
    Auto
  </label>
  <label class="theme-switcher__btn">
    <input type="radio" name="theme" value="dark"
           data-action="change->theme#switch">
    Dark
  </label>
</div>
```

### Theme-Aware Components

```css
.btn {
  /* Light mode hover: darken */
  --btn-hover-brightness: 0.9;

  /* Dark mode hover: brighten */
  html[data-theme="dark"] & {
    --btn-hover-brightness: 1.25;
  }

  @media (prefers-color-scheme: dark) {
    html:not([data-theme]) & {
      --btn-hover-brightness: 1.25;
    }
  }
}
```

### Theme Color Meta Tags

```erb
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#ffffff"
      media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0d181d"
      media="(prefers-color-scheme: dark)">
```

---

## 15. Performance Patterns

### No Build Step

- **CSS**: Native CSS, no preprocessors
- **JS**: Importmap, no bundling
- **Assets**: Asset pipeline for fingerprinting

### Lazy Loading

#### Turbo Frames

```erb
<%= turbo_frame_tag "comments", src: card_comments_path(@card), loading: :lazy do %>
  <div class="spinner">Loading...</div>
<% end %>
```

#### Dialog Content

```javascript
// Load frame content when dialog opens
loadLazyFrames() {
  this.dialogTarget.querySelectorAll("turbo-frame[loading=lazy]")
    .forEach(frame => frame.loading = "eager")
}
```

### Efficient Animations

```css
/* Use transform/opacity for GPU acceleration */
.card {
  transform: translateY(0);
  opacity: 1;
  transition: transform 150ms, opacity 150ms;
}

/* Avoid animating layout properties */
/* Bad: animating width, height, margin */
/* Good: animating transform, opacity */
```

### CSS Containment

```css
.contain { contain: inline-size; }

.card-columns {
  container-type: inline-size;  /* Creates containment context */
}
```

### Request Coalescing

Multiple Stimulus controllers can batch requests:

```javascript
import { throttle, debounce } from "helpers/timing_helpers"

export default class extends Controller {
  search = debounce(this.performSearch, 300)

  performSearch() {
    // Only fires after 300ms of inactivity
  }
}
```

---

## 16. View Layer Organization

### Layout Structure

**File:** `app/views/layouts/application.html.erb`

```erb
<!DOCTYPE html>
<html lang="en">
  <%= render "layouts/shared/head" %>

  <body class="<%= @body_class %>"
        data-controller="local-time timezone-cookie turbo-navigation theme"
        data-platform="<%= platform.type %>">

    <div id="global-container">
      <header class="header">
        <a href="#main" class="header__skip-navigation btn">
          Skip to main content
        </a>
        <%= render "my/menu" if Current.user %>
        <%= yield :header %>
      </header>

      <%= render "layouts/shared/flash" %>

      <main id="main">
        <%= yield %>
      </main>
    </div>

    <footer id="footer">
      <%= yield :footer %>

      <% if Current.user %>
        <div id="footer_frames" data-turbo-permanent="true">
          <%= render "bar/bar" %>
          <%= render "my/pins/tray" %>
          <%= render "notifications/tray" %>
        </div>
      <% end %>
    </footer>
  </body>
</html>
```

### Head Partial

**File:** `app/views/layouts/shared/_head.html.erb`

Includes:
- Viewport meta (with safe-area-inset support)
- Color scheme meta tags
- Theme color for browser UI
- Favicon and app icons
- PWA manifest
- Stylesheets
- Importmap/JavaScript

### Helper Patterns

#### Page Title

```ruby
# In controller
@page_title = "Board Settings"

# In helper
def page_title_tag
  tag.title [@page_title, Current.account&.name, "Fizzy"].compact.join(" | ")
end
```

#### Back Links

```ruby
def back_link_to(label, url, action, **options)
  link_to url, class: "btn btn--back",
          data: { controller: "hotkey", action: action } do
    icon_tag("arrow-left") +
    tag.strong("Back to #{label}") +
    tag.kbd("ESC", class: "hide-on-touch")
  end
end
```

### Content Sections

```erb
<%# In view %>
<% content_for :header do %>
  <h1>Page Title</h1>
  <%= back_link_to "Board", board_path(@board), "keydown.esc@document->hotkey#click" %>
<% end %>

<% content_for :footer do %>
  <nav class="footer-nav">...</nav>
<% end %>
```

---

## 17. Quick Reference

### CSS Class Naming

| Pattern | Example | Use |
|---------|---------|-----|
| `.component` | `.btn`, `.card` | Base component |
| `.component--variant` | `.btn--link` | Modifier |
| `.component__element` | `.card__header` | Child element |
| `.utility` | `.flex`, `.pad` | Single-purpose utility |

### Common Utilities

```css
/* Layout */
.flex, .flex-column, .flex-wrap
.gap, .gap-half, .gap-none
.justify-center, .justify-between, .align-center

/* Spacing */
.pad, .pad-block, .pad-inline
.margin, .margin-block, .margin-inline
.center /* margin-inline: auto */

/* Typography */
.txt-small, .txt-normal, .txt-large
.txt-subtle, .txt-negative, .txt-positive
.font-weight-bold

/* Visibility */
.visually-hidden, .for-screen-reader
.hide-on-touch, .show-on-touch
[hidden]
```

### Data Attributes

```html
<!-- Stimulus controller -->
data-controller="dialog"

<!-- Stimulus targets -->
data-dialog-target="trigger"

<!-- Stimulus values -->
data-dialog-modal-value="true"

<!-- Stimulus actions -->
data-action="click->dialog#open"

<!-- Platform detection -->
data-platform="ios|android|native|web"
```

### Semantic Colors

| Variable | Use |
|----------|-----|
| `--color-ink` | Primary text |
| `--color-canvas` | Background |
| `--color-negative` | Errors, destructive |
| `--color-positive` | Success |
| `--color-link` | Links, primary actions |
| `--color-selected` | Selected state |
| `--color-highlight` | Highlighted text |

### File Checklist for New Features

When adding a new feature:

1. [ ] CSS in `app/assets/stylesheets/[feature].css`
2. [ ] Use `@layer components` or `@layer modules`
3. [ ] Stimulus controller in `app/javascript/controllers/[feature]_controller.js`
4. [ ] View helper in `app/helpers/[feature]_helper.rb`
5. [ ] Partials in `app/views/[feature]/`
6. [ ] Use design tokens (CSS variables)
7. [ ] Mobile responsive (test at 639px breakpoint)
8. [ ] Keyboard accessible (ARIA, focus management)
9. [ ] Dark mode compatible (use semantic colors)

---

## Appendix: CSS Files Reference

| File | Purpose |
|------|---------|
| `_global.css` | Design tokens, CSS variables |
| `reset.css` | Modern CSS reset |
| `base.css` | HTML element defaults |
| `buttons.css` | Button component |
| `inputs.css` | Form inputs |
| `dialog.css` | Modal dialogs |
| `cards.css` | Card component |
| `card-columns.css` | Kanban columns layout |
| `utilities.css` | Utility classes |
| `animation.css` | Keyframe animations |
| `icons.css` | Icon definitions |
| `avatars.css` | User avatars |
| `flash.css` | Flash messages |
| `nav.css` | Navigation menu |
| `popup.css` | Dropdown menus |
| `tags.css` | Tag chips |
| `tooltips.css` | Hover tooltips |
| `trays.css` | Slide-out panels |

---

*This guide reflects the UI/UX patterns in Fizzy as of the current codebase. Keep it updated as patterns evolve.*

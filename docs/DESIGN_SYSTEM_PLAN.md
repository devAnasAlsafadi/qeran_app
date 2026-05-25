# Qeran Design-System Foundation Plan

> Status: proposal — pending review. No code changes will be made until this plan is approved.
>
> Source of truth for visuals: `Qeran identity.pdf` at the project root.

---

## Table of Contents

1. [What the brand identity says](#what-the-brand-identity-actually-says)
2. [Phase 1 — Visual audit](#phase-1--visual-audit)
3. [Phase 2 — Visual system proposal](#phase-2--visual-system-proposal)
4. [Phase 3 — Design-system folder structure](#phase-3--design-system-folder-structure)
5. [Phase 4 — CLAUDE.md "Qeran Visual System" section (proposed text)](#phase-4--claudemd-qeran-visual-system-section-proposed-text)
6. [Phase 5 — Safe migration plan](#phase-5--safe-migration-plan)
7. [Open decisions before starting Milestone A](#open-decisions-before-starting-milestone-a)

---

## What the brand identity actually says

Strict reading of the identity PDF — these are the rules, not interpretations.

**Palette (2 colours only, over warm cream):**

- `#431C33` Wine / burgundy — depth, voice, type
- `#E4C094` Champagne gold — accent, warmth, premium
- Warm cream (~`#F8EDDA`) is the canvas. **Not white.** Every reference surface in the PDF uses this cream as the base; white only appears as a lifted card on top of cream.

**Typography:** Noto Kufi Arabic + Montserrat (both already in pubspec).

**Motifs:**

- Ring-monogram brand glyph (intertwined Arabic qaf + ring) — hero moments only.
- Two overlapping circles (burgundy + gold) = the "match" emotional graphic.
- Thin outline ring pairs (gold/burgundy) floating on quiet surfaces — decorative.
- Tiled monogram pattern — for deep-burgundy hero backdrops.

**Component patterns shown in the application mockups (page 6 of the identity PDF):**

- Surface hierarchy: cream canvas → white cards on cream → deep-burgundy hero surfaces.
- Photo cards with ~24–28dp corners.
- Match badge: small burgundy pill, gold split, white text.
- Action triad: white circle (pass) / gold-filled circle (like, large) / white circle (super-like).
- Primary CTA: gold pill with burgundy text. Secondary CTA: burgundy outline pill.
- Bottom nav: deep burgundy bar with cream icons.
- Chat bubbles: gold (inbound) + white (outbound), burgundy text.

This is a confident two-colour system. The codebase doesn't reflect it yet.

---

## Phase 1 — Visual audit

### What exists today and how it scores against the identity

| Layer | Current state | Verdict |
|---|---|---|
| `AppColors` | Two brand colours present, but mixed with 13 generic colours (`red`, `green`, `pink`, `blue`, `yellow`, `grey`, `purple`, `black87/54`, `greyLight`, `fieldBackground`). `background` is pure white, not cream. `error` = Material red, `success` = Material green. `textSecondary/Muted` are cold greys. | **Off-brand** |
| `AppTextStyles` | Defined and consistent, **but hardcoded to `fontFamilyArabic` on every style** — the locale swap in `theme.dart` doesn't propagate because each style overrides. English text still renders in NotoKufiArabic in some surfaces. | **Bug + off-brand for English** |
| `AppDimens` | Spacing scale (4/8/12/16/20/24/32/48) is fine. **No shadow tokens, no motion tokens, no elevation tokens, no surface tokens. Only 3 radii (8/12/16).** | **Thin** |
| `AppTheme` | Material 3, sets ColorScheme correctly. `scaffoldBackgroundColor = white` (off-brand). CardTheme elevation=4 (heavy Material shadow). Has dark theme variant — brand identity does NOT define dark mode. | **Light-OK / dark out of scope** |
| `CustomButton` | One widget. White-on-primary only. No secondary / outline / gold-fill / destructive / ghost variants. Hardcodes `fontSize: 18`, `Colors.white`, no icon-side option. | **Insufficient** |
| `AppTextFormField` | Exists, presumably themed. Not audited deeply for this plan; assume usable. | **Stays** |
| `AppSnackBar` | Custom overlay with type (success/info/error). Decent surface. | **Wrap** |
| Logout dialog / Exit dialog | Custom dialogs with `BorderRadius.circular(14/24)` — close to identity but uncoordinated radii. | **Wrap** |
| `QuestionProgressBar` | Exists. | **Stays** |
| `LikeBlurredImage` | Auth-aware Bearer image. `BoxFit.cover`. Brand-agnostic. | **Stays** |
| Discovery image card | Dark translucent chips + gold-tinted verified badge — **most on-brand surface in the app**. | **Reference** |
| Like burst animation | Designed motion moment. | **Reference** |
| Auth screens | Believed close to brand (uses logo image, brand colours). | **Reference** |
| Profile feature screens (FullProfileDetails, MyProfile, share button, skeletons, error views) | **Built before the brand was clear. Generic Material output.** Grey skeletons, plain back arrow circle, flat score chip, default error state. | **Prototype** |
| Settings tab | Three white tiles stacked, 2018-era settings look. | **Prototype** |
| Packages screen | Long ListView of heavy `PlanCard`s. | **Prototype** |
| State widgets across the app (loading / empty / error) | Each feature reinvents. 21 raw `CircularProgressIndicator` callsites. Zero shared shimmer or branded skeleton. | **Prototype** |

### Duplication / inconsistency hot-spots (measured)

- **Radii**: 30+ ad-hoc `BorderRadius.circular(N)` callsites across the codebase using **at least 12 distinct values** (4, 8, 12, 14, 16, 18, 20, 22, 24, 28, 30, 999). The 3 radii in `AppDimens` are ignored.
- **Shadows**: 45+ ad-hoc `BoxShadow` / hex-alpha constructions across 15 files. Each feature invented its own elevation language.
- **Colours**: 12 ad-hoc semantic colours referenced from `AppColors` (`pink`, `blue`, `yellow`, etc.) that have no business in the identity.
- **Primary buttons**: `CustomButton` (auth/forms), `ShareWithMatchmakerButton` (profile pill), `_CircularActionButton` (Likes), `FilledButton` (subscription confirm), `OutlinedButton` (various). **5 different primary-action visual languages.**
- **Loading**: 21 callsites all using raw `CircularProgressIndicator`. No shared `QeranLoader`.
- **Empty / error views**: separate widgets per feature, no inheritance, no shared skeleton.

### What to keep untouched in this phase

- All cubits, repos, datasources, routing, DI — zero changes.
- Discovery deck animator + peek + swipe handler + like burst — these are reference-grade behaviour; do not refactor.
- Auth screens — believed close to brand; defer to migration phase.
- `LikeBlurredImage`, `AppLogger`, `AppSnackBar` core machinery — stays.
- The two existing fonts and the existing logo asset.

### What to wrap (not rewrite)

- `CustomButton` → wrapped/superseded by `QeranButton` variants. Migration phase moves callers; `CustomButton` stays as a deprecated alias initially.
- `AppSnackBar` → wrapped by `QeranSnackbar` with branded surfaces. Behaviour unchanged.
- Per-feature empty/error/skeleton views → replaced by `QeranEmptyState`, `QeranErrorState`, `QeranSkeleton` callsite by callsite.

### What to refactor in place

- `AppColors`: prune generic colours, add semantic roles, fix `background` to cream.
- `AppTextStyles`: remove hardcoded `fontFamily`; let the theme propagate.
- `AppTheme`: align `scaffoldBackgroundColor` to cream; soften `CardTheme` elevation; bind to new tokens.

### What NOT to touch right now

- Discovery card layout & body. Already redesigned in the recent batches.
- Chat conversation list + bubbles. Brand mapping is well-defined (gold/white) and worth a dedicated pass later; not in foundation.
- Subscription purchase screen + cubit. Polish-plan item #7 lives there; do separately.
- The dark theme. Brand has no dark spec. Mark it `@Deprecated` for now; revisit when the identity defines it.

---

## Phase 2 — Visual system proposal

### Colour roles (the only colours allowed in widget code)

Strict two-anchor palette + neutrals derived from them. **No more `pink`, `blue`, `yellow`, `red`, `green` constants.**

| Role | Hex | Use |
|---|---|---|
| `wine` | `#431C33` | Primary type, primary actions, deep surfaces, focus rings |
| `wine.shade90/80/60/40/20/8` | derived via opacity | Subdued type, hairline borders, soft tints |
| `gold` | `#E4C094` | Accent, premium chips, secondary CTAs, success-warm |
| `gold.shade80/60/40/20/12` | derived via opacity | Soft accents, badges, hover/pressed |
| `cream.canvas` | `#F8EDDA` | App background — replaces today's pure white |
| `cream.surface` | `#FBF4E6` | Slightly elevated cream tier |
| `paper` | `#FFFFFF` | Lifted cards on cream |
| `ink.strong` | `#431C33` | All headlines, primary text (same as wine — by design) |
| `ink.body` | `#5A3B4E` | Body text — wine-tinted neutral, NOT grey |
| `ink.muted` | `#8A7984` | Muted text — wine-tinted, NOT cold grey |
| `divider` | `wine @ 8% alpha` | Hairline separators |
| `success.warm` | gold-leaning green `#5F8F6C` | Used sparingly; primary success uses gold tones |
| `danger` | wine-leaning red `#A33949` | Wine-tinted, not Material red |
| `info` | wine | Information feedback = brand voice |
| `overlay.tintDark` | `wine @ 55% alpha` | Photo overlays, modal scrims |
| `overlay.tintLight` | `cream @ 70% alpha` | Glass-style lifts |

Material colours (`Colors.pink`, `Colors.blue`, etc.) become **forbidden in feature code**. Linter could enforce in a follow-up.

### Typography hierarchy

The brand uses two fonts. We define one set of roles; the font picks itself per locale via the theme's `fontFamily`. **Remove hardcoded `fontFamily` from every text style.**

| Role | Size / weight / line-height | Use |
|---|---|---|
| `displayLg` | 32 / 800 / 1.15 | Brand moments (splash, match-success, paywall hero) |
| `displaySm` | 26 / 800 / 1.20 | Screen heroes (PackagesScreen title, OnboardingTitle) |
| `headline` | 22 / 700 / 1.25 | Section heroes (profile name, conversation header) |
| `title` | 18 / 700 / 1.30 | Card titles, dialog titles |
| `subtitle` | 16 / 600 / 1.40 | Sub-headers, prominent labels |
| `body` | 15 / 500 / 1.55 | Paragraphs, list rows |
| `bodySm` | 13 / 500 / 1.55 | Secondary descriptions |
| `label` | 13 / 700 / 1.20 | Chip text, button text |
| `caption` | 11 / 600 / 1.40 | Tags, timestamps, badge text |
| `numeric` | 15 / 700 tabular | Prices, percentages, counters — Montserrat always |

Pricing / percent numerics force Montserrat (tabular figures) regardless of locale — Arabic Kufi doesn't have tabular numerals.

### Spacing system

Keep the existing 4/8/12/16/20/24/32/48 from `AppDimens`. Add: `64` for hero vertical rhythm, `2/6` for micro-adjustments. Document a usage rule:

- 8 = inside chip / dense control
- 12 = between related elements (icon + label, label + value)
- 16 = between siblings inside a card
- 20 = card inner padding (default)
- 24 = between sections in a body
- 32 = between major sections / above-below heroes
- 48 = hero top/bottom padding on splash-style surfaces

### Radius system

Three semantic radii, derived from photo treatment in the identity mockups.

| Token | Value | Use |
|---|---|---|
| `chip` | 999 (pill) | All chips, all small pills, score badges |
| `control` | 14 | Buttons, inputs, dialog action rows |
| `card` | 20 | Default lifted cards |
| `panel` | 28 | Photo cards, large hero containers, modal sheets |
| `dome` | 36 (top-only) | Bottom sheets, image-into-content overlap |

The 30+ ad-hoc radii in the codebase collapse to these five.

### Shadow / elevation system

Photo identity mockups use soft, warm shadows — never harsh Material. Define 4 tokens, all wine-tinted, not grey-tinted.

| Token | Spec | Use |
|---|---|---|
| `e0` | none | flat |
| `e1` | `Color(0x0A431C33)`, blur 12, y 2 | Hairline lift (chips, inputs at rest) |
| `e2` | `Color(0x12431C33)`, blur 20, y 6 | Cards, primary surfaces |
| `e3` | `Color(0x1A431C33)`, blur 28, y 10 | Floating CTAs, action bars, sheets |
| `eHero` | `Color(0x14E4C094)` outer-glow + `e3` underneath | Match-success hero, splash CTAs |

Wine-tinted shadows are the single biggest tonal upgrade from current grey shadows.

### Surface hierarchy (mandatory)

```
Tier 0  cream.canvas        — scaffold background, full screens
Tier 1  paper               — lifted cards on cream
Tier 2  paper + e2          — primary card surfaces
Tier 3  wine.deep           — hero moments, splash, paywall, match-success
Tier 4  gold.warmFill       — primary CTAs, headline badges
```

Today's app collapses Tier 0 → pure white, which kills the lift effect. Fixing this single token (`cream.canvas`) is the highest-leverage visual change.

### Motion language

Two duration tokens, three curves. **Every animation in the app should pick from this set.**

| Token | ms | Curve | Use |
|---|---|---|---|
| `fast` | 180 | `easeOutCubic` | Tap feedback, chip selection, micro-interactions |
| `standard` | 280 | `easeOutCubic` | Card swap, snackbar entry, content fade |
| `gentle` | 420 | `easeOutCubic` | Profile body cross-fade, sheet open |
| `hero` | 640 | `easeOutQuart` | Splash, match-success, premium banner reveal |
| `stagger` | 60ms between siblings | — | List/grid entry, chip wrap |

Add one signature motion: **soft scale-in (0.94 → 1.0) + fade (0 → 1)** for hero surfaces. Used on FullProfileDetails first paint, MatchSuccess, paywall opening. Becomes the "Qeran" entry feel.

### Loading / skeleton language

- **No grey blocks ever.** Skeletons use `cream.surface` with a slow shimmer pass in gold @ 18% alpha. Shimmer cycle = 1400 ms `easeInOut`.
- **No raw `CircularProgressIndicator`.** Replace with `QeranLoader`: a small ring-monogram-inspired dual-arc spinner (gold + wine), 2 ring strokes, indeterminate rotation, 1600ms cycle. For inline buttons, a 18×18 variant.
- Page-level loading uses skeleton; action-level loading uses inline `QeranLoader`.

### Empty / error / success state language

Identity-aligned visual recipe for every empty/error surface:

- Centered column, max-width 320dp.
- Top: a 96×96 circular **cream.surface** disc holding a wine icon at 36pt. For premium emphasis, swap the icon for the ring-monogram SVG glyph.
- Below: title in `headline`, ink.strong.
- Below: subtitle in `body`, ink.body.
- Below: a primary `QeranButton` (variant depends — retry / dismiss / cta).
- Behind the column on important surfaces: faint decorative gold ring outlines (~6% alpha) at corners — derived from the identity's circle motif.

For success (post-action moments like "profile shared", "subscription activated"):

- Two-circle brand mark (burgundy + gold) animates a 480ms scale-in.
- Title + supportive line.
- Continue CTA in gold.

### Button hierarchy

Five variants, no more:

| Variant | Fill | Text | Border | Use |
|---|---|---|---|---|
| `primary` | gold | wine | none | Headline CTA: Subscribe, Say Hi, Continue |
| `primaryWine` | wine | white | none | Inline primary inside cream contexts where gold would clash |
| `secondary` | transparent | wine | wine 1.5dp | Cancel-style, secondary CTAs |
| `ghost` | transparent | wine | none | Tertiary, list-row tap actions |
| `destructive` | transparent | danger | danger 1.5dp | Logout, decline like |

Sizes: `lg` (54h), `md` (46h), `sm` (36h). All radius = `control` (14). Leading or trailing icon supported. Loading state replaces label with `QeranLoader.inline`.

This collapses the current 5 different primary-action treatments to a single component.

### Chip / tag hierarchy

| Variant | Visual | Use |
|---|---|---|
| `score` | wine fill, gold split-end, white text, pill | Match % badges (matches the identity's "94% match") |
| `meta` | cream.surface, wine text, optional gold icon | Above-image chips, location, work, distance |
| `inside` | paper, wine 6% border, wine text | Profile insideCard chips |
| `interest` | gold 12% fill, wine 18% border, wine text | Interests, hobbies |
| `status` | colour-dependent (success.warm / danger / wine), pill | State chips |

All chips: radius `chip` (pill), padding 12h / 6v, label-size 13/600 or 11/600 for compact.

### Premium card style

Default `QeranCard`:

- background `paper`, radius `card` (20), shadow `e2`, internal padding 20.
- Optional `accentBar` (top, 3dp, gold) for "premium" emphasis.
- Optional `ringMotif` (decorative gold ring outline at 8% alpha, positioned at top-end corner — derived from the identity's circle motif).

`QeranCard.hero`: radius `panel` (28), shadow `e3`, internal padding 24, used for paywall hero, match-success, settings primary card.

---

## Phase 3 — Design-system folder structure

Thin scaffolding, scalable, no over-engineering. All under `lib/core/design_system/`:

```
lib/core/design_system/
├── tokens/
│   ├── qeran_colors.dart        # Wine, Gold, Cream, Ink, derived shades, semantic roles
│   ├── qeran_typography.dart    # Display / Headline / Title / Body / Label / Caption / Numeric
│   ├── qeran_spacing.dart       # Spacing scale (2/6/8/12/16/20/24/32/48/64) — re-exports / wraps AppDimens
│   ├── qeran_radii.dart         # chip / control / card / panel / dome
│   ├── qeran_shadows.dart       # e0 / e1 / e2 / e3 / eHero — wine-tinted
│   └── qeran_motion.dart        # Durations (fast/standard/gentle/hero) + curves
├── theme/
│   └── qeran_theme.dart         # ThemeData composition; locale-aware fontFamily
├── widgets/
│   ├── qeran_button.dart        # Variant-based primary/secondary/ghost/destructive
│   ├── qeran_card.dart          # Default + hero variants
│   ├── qeran_chip.dart          # score / meta / inside / interest / status
│   ├── qeran_section_header.dart
│   ├── qeran_app_bar.dart       # Cream-aware app bar with brand back button
│   ├── qeran_skeleton.dart      # Cream + gold shimmer
│   ├── qeran_loader.dart        # Dual-arc spinner (inline + page)
│   ├── qeran_empty_state.dart
│   ├── qeran_error_state.dart
│   ├── qeran_success_state.dart
│   ├── qeran_premium_banner.dart # Hero gold-on-wine banner for paywall/upgrade
│   └── qeran_surface.dart       # Tier-aware container (canvas/paper/wine.deep)
├── effects/
│   ├── ring_motif.dart          # Decorative thin ring outlines (CustomPaint)
│   ├── monogram_pattern.dart    # Tiled monogram backdrop (asset-driven)
│   └── two_circle_mark.dart     # The brand "match" overlap circles (animated)
└── motion/
    ├── soft_scale_in.dart       # Signature scale+fade entry
    └── staggered_children.dart  # List/wrap staggered reveal
```

**Notes on scaffolding strategy:**

- `tokens/` contains pure data — no Flutter widget code beyond `TextStyle` / `BoxDecoration` builders. Import-cheap, test-cheap.
- `widgets/` widgets are all const-constructible, accept `QeranButtonVariant` etc. enums, no behaviour beyond layout + theme.
- `effects/` are visual flourishes — only used in hero surfaces (splash, match-success, paywall). Optional everywhere else.
- `motion/` provides reusable animation primitives. Cubits/screens use them; they don't own state.
- Existing `AppColors` / `AppDimens` / `AppTextStyles` / `theme.dart` get **deprecated, not deleted** during migration. Each constant becomes `@Deprecated('Use Qeran<X> instead')` and forwards to the new token. Migration is callsite-by-callsite.

---

## Phase 4 — CLAUDE.md "Qeran Visual System" section (proposed text)

Add as a new section after §3 (State & UI). Drop in verbatim:

```
## 4. Qeran Visual System (mandatory)

### Brand emotion
Warm, premium, calm, trustworthy, marriage-focused. Luxurious without being
flashy. The app should feel restrained and confident, not loud.

### UI philosophy
- Two colours only: wine (#431C33) and gold (#E4C094), over warm cream
  canvas (#F8EDDA). No greys, no Material reds/greens/blues.
- Cream is the canvas. White is a lifted surface. Never put white on white.
- Shadows are wine-tinted, never grey.
- Type is wine, body is wine-tinted neutral. Muted text is wine-tinted,
  never cold grey.

### Component consistency rules
- Use `QeranButton` for every CTA. Five variants only (primary/primaryWine/
  secondary/ghost/destructive). Never construct ElevatedButton/FilledButton/
  OutlinedButton directly in feature code.
- Use `QeranCard` for every elevated container. Default radius 20, hero 28.
  Never construct a Container + BoxDecoration + BoxShadow ad-hoc in feature
  code.
- Use `QeranChip` variants for every pill/tag. Never construct chip-like
  containers ad-hoc.
- Use `QeranAppBar` for every screen-level header.
- Use `QeranLoader` for every loading indicator. Never use raw
  `CircularProgressIndicator`.
- Use `QeranSkeleton`, `QeranEmptyState`, `QeranErrorState`,
  `QeranSuccessState` for state surfaces. Never roll your own.

### Token rules
- Radii: only `QeranRadii.{chip|control|card|panel|dome}`. Numeric
  `BorderRadius.circular(N)` is forbidden in feature code.
- Shadows: only `QeranShadows.{e0|e1|e2|e3|eHero}`. Constructing `BoxShadow`
  in feature code is forbidden.
- Colours: only `QeranColors.{wine|gold|cream|ink|...}`. Constructing
  `Color(0x...)` in feature code is forbidden.
- Spacing: only `QeranSpacing.{s2..s64}`. Numeric literals in EdgeInsets are
  forbidden except inside design-system widgets.

### Motion rules
- Every animation picks duration from `QeranMotion.{fast|standard|gentle|hero}`
  and `Curves.easeOutCubic` (or `easeOutQuart` for hero).
- Hero surfaces (splash, match-success, paywall hero, profile-details first
  paint) use `SoftScaleIn` as their entry.
- Lists/grids of >4 items use `StaggeredChildren` for reveal.
- No spinners on hero surfaces — use skeletons.

### Premium-surface expectations
- All hero surfaces (paywall, match-success, splash, profile-details header)
  include at minimum: a soft motion entry, a decorative gold ring motif at
  6–10% alpha, and a wine-or-gold accent on the focal element.

### What to avoid visually
- Pure white scaffold backgrounds.
- Grey skeletons or grey loaders.
- Material default radii (4/16/24 picked at random).
- Material drop-shadows (grey, hard).
- Three different button styles on the same screen.
- More than two colours in any single composition (besides type).
- Loud animations, rotating spinners, bouncing CTAs.
- Cold neon accents, fluorescent gradients.

### How to handle UI tasks
- Tier A (new screen / hero surface): require a visual prompt + reference.
  Produce a layout sketch before code.
- Tier B (polish on existing surface): require a 3–5 sentence visual brief.
- Tier C (single-widget fix): implement directly.
- All UI tasks must use existing Qeran widgets and tokens. Inventing a new
  visual treatment requires explicit approval and goes through the design
  system, not into a feature folder.
```

This sits alongside the existing architecture rules — visual rules are now equally enforceable.

---

## Phase 5 — Safe migration plan

**Principle: token-first, screen-second, never mass-refactor.** The design system lands as new code in `core/design_system/`. Existing widgets stay green until each screen opts in.

### Migration ladder (5 milestones)

**Milestone A — Foundation (no UX visible to user)**

- Add all token files (`qeran_colors`, `qeran_typography`, `qeran_spacing`, `qeran_radii`, `qeran_shadows`, `qeran_motion`).
- Add `qeran_theme.dart` but do NOT swap the app to it yet — exists in parallel with current `AppTheme`.
- Add the design-system widgets (`QeranButton`, `QeranCard`, `QeranChip`, `QeranLoader`, `QeranSkeleton`, `QeranEmptyState`, `QeranErrorState`, `QeranSuccessState`, `QeranAppBar`, `QeranSectionHeader`, `QeranPremiumBanner`, `QeranSurface`).
- Add `effects/ring_motif.dart` and `motion/soft_scale_in.dart` + `staggered_children.dart`.
- Mark `AppColors.{pink,blue,yellow,red,green,grey,purple,black87,black54}` `@Deprecated`. Mark `AppColors.background` `@Deprecated('Use QeranColors.cream.canvas')`.
- Fix the `AppTextStyles` hardcoded `fontFamily` (remove it from each style; theme-level font swap takes over).
- Zero feature files touched. **Risk: near-zero.** Verification: `dart analyze` + all tests stay green.

**Milestone B — Quiet swap of scaffold + theme**

- Switch `qeran_app.dart` to use `QeranTheme.light()` instead of `AppTheme.lightTheme`.
- Switch `scaffoldBackgroundColor` to `QeranColors.cream.canvas`.
- Add `QeranColors.cream.canvas` to a single global `MaterialApp(theme:)` change.
- This will visually shift the *whole app* from white to cream. **High visual impact, low code risk** — only the canvas changes; every white card automatically lifts above it correctly.
- Verification: golden-test a handful of representative screens (Discovery, Likes, FullProfileDetails, Settings) — visual diff only. No functional change.

**Milestone C — Adopt design-system widgets, surface by surface**

Adoption order ranked by **visual impact ÷ regression risk**:

1. **State widgets across all features** (highest impact, lowest risk). Replace 21 `CircularProgressIndicator` callsites with `QeranLoader`, 4 empty-state custom widgets with `QeranEmptyState`, all error views with `QeranErrorState`. Skeleton in profile feature swaps to `QeranSkeleton`. This single sweep fixes the "prototype loading/empty/error" complaint in every feature simultaneously.
2. **My Profile screen** (high visual impact, isolated). New `QeranAppBar`, `QeranCard` for header, gallery wrapped, gender/age/email row using `QeranChip.meta`. No business logic touched.
3. **Profile feature share button + state widgets** — adopt `QeranButton.primary` and `QeranEmptyState`. Replace the inline pill.
4. **Settings tab** — replace tiles with `QeranCard` + `QeranSectionHeader`. Add `QeranPremiumBanner` showing active subscription.
5. **FullProfileDetails** — header gets `QeranAppBar`, score badge becomes `QeranChip.score` (matching the "94% match" identity badge), title row uses new typography, body uses `QeranCard.hero` for the placement panel. Adopt `SoftScaleIn` entry motion.
6. **Packages screen** — full rewrite using `QeranPremiumBanner`, tab layout, `QeranCard`, `QeranButton.primary` (gold-fill CTA). Highest-effort screen in the migration; do it last in Milestone C because all prior widgets are now battle-tested.

After each surface: run analyze + that feature's test suite + a quick manual smoke. No batch is multiple surfaces simultaneously.

**Milestone D — Hero moments**

- Add the splash brand entry (logo + dual-circle mark + ring motif) using `SoftScaleIn`.
- Add the match-success surface (currently doesn't exist as a designed moment — propose it now).
- Wire the `QeranPremiumBanner` into paywall sheets.

**Milestone E — Cleanup**

- Remove deprecated `AppColors` generic constants once all callsites migrated.
- Remove `CustomButton` once all callsites use `QeranButton`.
- Delete the dark theme (out of scope per brand) or mark it `@experimental`.
- Add lint rules (`avoid_color_literals`, custom analyzer warnings) to enforce token usage going forward.

### What we explicitly do NOT do during this phase

- No backend changes. None.
- No cubit / repo / datasource changes.
- No routing changes (besides splash entry if we add one).
- No new endpoints.
- No localization changes — except adding `qeran.*` keys for the design-system widgets' own copy (loader labels, generic error/empty messages).
- No test rewrites. New widget tests are added for the design-system widgets themselves; feature tests are only re-run, not modified.

### Estimated effort per milestone (one engineer)

- Milestone A: ~3–5 hours. Foundation only. Should be one focused session.
- Milestone B: ~1 hour. The theme swap. Test for visual regressions.
- Milestone C: ~2–4 hours per surface × 6 surfaces = ~16–24 hours total, spread across 2–4 sessions.
- Milestone D: ~3–5 hours.
- Milestone E: ~2 hours.

Total: ~30–40 hours of focused work, spread across ~6–8 sessions. Discovery deck + chat conversation are deliberately out of this scope and remain stable.

### Rollback strategy

Every milestone is a single PR. Milestone A introduces only additive code. Milestone B is one file diff (`qeran_app.dart`). Milestone C surfaces are independently revertible. If any milestone produces an unexpected regression, revert that PR; the rest stays.

---

## Open decisions before starting Milestone A

These are the only blockers. None require new files — just decisions:

1. **Canvas colour exact value.** The identity uses a warm cream — `#F8EDDA` is my read of it from the PDF. Do you want me to sample the exact pixel from the identity file, or is the proposed value acceptable?
2. **Dark theme.** Drop it entirely or freeze it `@experimental`? Identity has no dark spec.
3. **Numeric font for prices/percentages.** Force Montserrat tabular figures in Arabic locale, or accept NotoKufiArabic numerics? Identity mockups show numerics in Latin (Montserrat) even on Arabic surfaces — recommend forcing Montserrat for numerics.
4. **Ring motif and tile pattern.** I'd like SVG exports of the decorative ring outlines and the monogram tile from the identity PDF. Can you export those from the source file, or should I approximate them with `CustomPaint`?
5. **Match-success / splash surface.** Are these existing screens I'm replacing, or new screens introduced as part of Milestone D? If new, confirm we add them to the route graph.

Once those five are answered, Milestone A can land in the next session. No code yet — awaiting your sign-off on this plan.

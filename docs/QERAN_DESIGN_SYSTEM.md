# Qeran — Design System Reference (QERAN_DESIGN_SYSTEM.md)

> **الغرض:** المرجع الكامل لكل التوكنز والـ widgets. هذا **الكتالوج** — أما القواعد فموجودة في `DESIGN.md`.
> **Source of truth in code:** `lib/core/design_system/` — `tokens/`, `widgets/`, `motion/`, `effects/`, `theme/`.
> **Rule:** every UI value in feature code must come from a token below. No raw values.

---

## 1. Colors — `QeranColors`

### Brand anchors
| Token | Hex | Use |
|-------|-----|-----|
| `wine` | `#431C33` | Primary brand. Buttons, titles, icons, score chips. |
| `gold` | `#E4C094` | Accent / verified / success / celebrate. Disc, accent bar, shimmer. |
| `goldDeep` | `#B18454` | Stronger gold for pending/waiting accents (status text, countdown chips) needing contrast on light surfaces. |

### Canvas tier
| Token | Hex | Use |
|-------|-----|-----|
| `creamCanvas` | `#FEFCFA` ⭐ | Scaffold background (the canvas). **Soft white — locked final decision** (intentional override of the brand guide's warm cream `#FCEDDD`). |
| `creamSurface` | `#FBF4E6` | Lifted cream — meta chips, skeleton base, icon discs, nav cradle. |
| `paper` | `#FFFFFF` | White lifted surface — cards, bottom-nav bar. |

### Ink (wine-tinted neutrals — NEVER cold grey)
| Token | Hex | Use |
|-------|-----|-----|
| `inkStrong` | `#431C33` (= wine) | Primary text. Titles, headlines, labels. |
| `inkBody` | `#5A3B4E` | Body / paragraph text. |
| `inkMuted` | `#8A7984` | Muted / secondary text, captions, inactive nav. |

### Wine alpha shades (over `#431C33`)
| Token | ~Alpha | Used | Typical use |
|-------|--------|------|-------------|
| `wine90` | 90% | — | (unused) |
| `wine80` | 80% | ✅ | photo overlay gradients |
| `wine60` | 60% | — | (unused) |
| `wine40` | 40% | ✅ | icon tints on light, disabled outlines |
| `wine20` | 20% | ✅ | borders, privacy boxes, step indicator |
| `wine12` | 12% | ✅ | hairline borders |
| `wine08` | 8% | ✅ | divider, card borders, splashes |
| `wine06` | 6% | ✅ | faint fills, avatar bg, highlight |

### Gold alpha shades (over `#E4C094`)
| Token | ~Alpha | Used | Typical use |
|-------|--------|------|-------------|
| `gold80` | 80% | — | (unused) |
| `gold60` | 60% | — | (unused) |
| `gold40` | 40% | ✅ | interest-chip border, action-bar accent |
| `gold20` | 20% | ✅ | paywall/profile accents |
| `gold12` | 12% | ✅ | interest-chip fill, stat cards |
| `gold08` | 8% | — | (unused) |

### Semantic & overlays
| Token | Value | Used | Use |
|-------|-------|------|-----|
| `divider` | = wine08 | ✅ | list/section dividers |
| `hairline` | = wine12 | ✅ | hairline borders |
| `danger` | `#A33949` | ✅ | destructive actions, error disc/icon (only non-wine/gold hue) |
| `successWarm` | = gold | — | success-via-gold alias (brand has no green) |
| `info` | = wine | — | informational alias |
| `overlayTintDark` | wine @ ~55% | ✅ | scrim over imagery (privacy, sheets) |
| `overlayTintLight` | `#F8EDDA` @ ~70% | — | light cream scrim (unused) |
| `photoScrimTop` | black @ 20% | — | (unused) |
| `photoScrimBottom` | black @ 60% | — | (unused) |

> **Unused tokens** (defined, zero refs): `wine90, wine60, gold80, gold60, gold08, successWarm, info, overlayTintLight, photoScrimTop, photoScrimBottom`. Candidates for cleanup — don't add more dead tokens.

---

## 2. Typography — `QeranTypography`

> Font family is **not** hardcoded — the theme resolves **NotoKufiArabic** (ar) / **Montserrat** (Latin) by locale. `numeric` forces Montserrat for tabular figures.

| Token | Size | Weight | Default color | Use |
|-------|------|--------|---------------|-----|
| `displayLg` | 32 | w800 | inkStrong | Largest hero display |
| `displaySm` | 26 | w800 | inkStrong | Smaller hero display |
| `headline` | 22 | w700 | inkStrong | Screen/section headlines, empty/error/success titles |
| `title` | 18 | w700 | inkStrong | Card titles, app-bar title, section header |
| `subtitle` | 16 | w600 | inkStrong | Subtitles; default button label (lg/md) |
| `body` | 15 | w500 | inkBody | Paragraph / body copy |
| `bodySm` | 13 | w500 | inkBody | Dense secondary body, sub-labels |
| `label` | 13 | w700 | inkStrong | Chips, compact button labels (sm/xs) |
| `caption` | 11 | w600 | inkMuted | Captions, nav labels, badges |
| `numeric` | 15 | w700 | inkStrong | **Forces Montserrat + tabular figures** — prices, %, counters, timers |

---

## 3. Spacing — `QeranSpacing`

Multiples of 4 (+ 2/6 micro). Scale: `s2 s4 s6 s8 s12 s16 s20 s24 s32 s48 s64`.

| Token | px | Guideline |
|-------|----|-----------|
| `s8` | 8 | inside chip / dense control |
| `s12` | 12 | between related (icon+label) |
| `s16` | 16 | between siblings in a card |
| `s20` | 20 | card inner padding (default) |
| `s24` | 24 | between body sections |
| `s32` | 32 | between major sections / around heroes |
| `s48` | 48 | hero top/bottom padding |
| `s64` | 64 | max hero vertical rhythm |

- **Const SizedBox helpers:** vertical `vs4..vs48`, horizontal `hs4..hs24`.
- **Const insets:** `cardInner` (20), `cardInnerHero` (24), `screenH` (h20), `chipPad` (h12/v6).

---

## 4. Radii — `QeranRadii`

| Token | Value | Use |
|-------|-------|-----|
| `chip` | 999 | pill radius scalar |
| `control` | 14 | buttons, inputs |
| `card` | 20 | default card |
| `panel` | 28 | hero card / panel |
| `dome` | 36 | bottom sheets, image-overlap top |

**BorderRadius helpers:** `pill`, `controlR` (14), `cardR` (20), `panelR` (28), `domeTop` (top corners 36 only).

---

## 5. Shadows — `QeranShadows` (wine-tinted, never grey)

| Token | Color/alpha | Blur | Offset | Use |
|-------|-------------|------|--------|-----|
| `e0` | — | — | — | flat, no shadow |
| `e1` | wine ~4% | 12 | (0,2) | hairline lift — chips, inputs at rest |
| `e2` | wine ~7% | 20 | (0,6) | default card lift |
| `e3` | wine ~10% | 28 | (0,10) | floating CTAs, action bars, sheets |
| `eHero` | gold ~8% glow + e3 wine | 36/28 | (0,0)+(0,10) | hero surfaces (paywall, match-success) |

Also: `hairlineBorder` = wine08 (for borders where a shadow is inappropriate).

---

## 6. Motion — `QeranMotion` / `QeranCurves`

| Duration | ms | Use |
|----------|-----|-----|
| `fast` | 180 | tap feedback, chip select, micro-interactions |
| `standard` | 280 | card swap, snackbar, content fade |
| `gentle` | 420 | profile cross-fade, sheet open |
| `hero` | 640 | splash, match-success, premium reveal, bottom-nav slide |
| `staggerStep` | 60 | inter-child stagger interval |
| `shimmer` | 1400 | skeleton shimmer cycle |
| `loaderCycle` | 1600 | loader full rotation |

| Curve | Value | Use |
|-------|-------|-----|
| `QeranCurves.standard` | easeOutCubic | fast/standard/gentle default |
| `QeranCurves.hero` | easeOutQuart | signature scale-in |
| `QeranCurves.shimmer` | easeInOut | shimmer |

---

## 7. Widgets

### `QeranButton`
Params: `label, onPressed, variant, size, leadingIcon, trailingIcon, fullWidth (default true), loading`. Radius `controlR`; disabled → 50% opacity; loading → inline `QeranLoader` in fg color.

**6 variants** (`QeranButtonVariant`):
| Variant | BG | FG | Border | Use |
|---------|----|----|--------|-----|
| `primary` | gold | wine | — | default CTA |
| `primaryGold` | goldDeep | paper | — | paired with `primaryWine` in two-button match rows |
| `primaryWine` | wine | paper | — | primary wine CTA |
| `secondary` | transparent | wine | wine 1.5 | secondary |
| `ghost` | transparent | wine | — | low-emphasis |
| `destructive` | transparent | danger | danger 1.5 | destructive |

**4 sizes** (`QeranButtonSize`): `lg` h54 / `md` h46 / `sm` h36 / `xs` h40 (compact, tight pad for dense Arabic two-button rows). `sm`/`xs` use `label` type; `lg`/`md` use `subtitle`.

### `QeranCard`
Params: `child, variant, padding, margin, accentBar, onTap, background (default paper)`. Named ctors `.hero` / `.flat`.
| Variant | Radius | Shadow | Notes |
|---------|--------|--------|-------|
| `standard` | cardR 20 | e2 | default |
| `hero` | panelR 28 | e3 | accentBar on by default; hero padding 24 |
| `flat` | cardR 20 | e0 | wine08 border instead of shadow |

`accentBar` = 3px gold bar at top. Optional `onTap` adds InkWell (wine08 splash).

### `QeranChip`
Params: `label, variant, icon, statusColor (required for status), compact, onTap`. Pill radius; label/caption type.
| Variant | BG | FG | Border | Use |
|---------|----|----|--------|-----|
| `score` | wine | paper | — | match score |
| `meta` | creamSurface | wine | — | metadata (default) |
| `inside` | paper | wine | wine12 | "inside" tags |
| `interest` | gold12 | wine | gold40 | interests |
| `status` | statusColor @12% | statusColor | — | dynamic status |

### State & surface widgets
| Widget | What it is |
|--------|-----------|
| `QeranLoader` | Dual-arc spinner (wine+gold). Replaces every `CircularProgressIndicator`. `.inline({color})` → size 18 for buttons. |
| `QeranSkeleton` | Warm-cream base + gold shimmer (1400ms), never grey. Ctors: default (line), `.circle({size})`, `.box({w,h,radius})`. |
| `QeranEmptyState` | Centered column, 96px cream icon-disc (wine icon), headline title + optional message + optional CTA. |
| `QeranErrorState` | Same recipe; danger-tinted disc, default `error_outline`, optional retry CTA. |
| `QeranSuccessState` | Wrapped in SoftScaleIn. Two overlapping discs (wine+gold) over RingMotif, title + optional message + continue CTA. |
| `QeranSurface` | Tier-aware bg. `QeranSurfaceTier`: `canvas / creamLifted / paper / wineDeep`. |
| `QeranAppBar` | PreferredSizeWidget. Cream bg, wine title + icons, branded back button (auto-mirrors RTL). Params: `title, onBack, actions, background, centerTitle`. Never pops on its own. |
| `QeranSectionHeader` | Gold 3×22 accent bar + title + optional subtitle + optional trailing. |
| `QeranPremiumBanner` | Hero gold-on-wine banner (eHero, panelR). For paywalls / upgrade / active-sub. |
| `QeranBottomNav` | Premium curved-notch nav. `QeranNavItem = outlineIcon, filledIcon, label, badgeCount`. Floating gold disc + crossfade, RTL-aware. |

### Motion / effects helpers
| Helper | What it is |
|--------|-----------|
| `SoftScaleIn` | Signature entry: scale 0.94→1.0 + fade, hero duration, optional delay. For hero surfaces. |
| `StaggeredChildren` | Wraps children in SoftScaleIn with staggerStep×i delay. For lists/grids >4 items. |
| `RingMotif` | Decorative concentric gold rings (6–10% alpha), pure painter, IgnorePointer. Quiet flourish behind hero content. |

> `theme/qeran_theme.dart` builds the ThemeData/TextTheme (where the NotoKufiArabic↔Montserrat locale font resolution lives).

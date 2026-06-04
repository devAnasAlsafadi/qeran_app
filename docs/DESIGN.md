# Qeran — Design Rules (DESIGN.md)

> **الغرض:** كل قاعدة تخص التصميم والواجهات. اقرأه قبل أي مهمة UI.
> **Scope:** Every UI task — both the user app AND the matchmaker. Read this before any visual work.
> **Full token/widget reference:** see `QERAN_DESIGN_SYSTEM.md` (this file is the rules; that file is the catalog).

---

## 0. THE GOLDEN RULE — Figma = shape, identity = paint

**IMPORTANT.** This is the single most important design rule.

- **Figma gives us:** layout, shape, arrangement, placement, sizing, order of elements — **structure only**.
- **Our identity gives us:** every color, font, spacing, radius, shadow — **all visuals**.

> Match Figma's SHAPE exactly. PAINT it in OUR identity. Same structure as Figma, our colors — never the reverse.

The Figma is not literal on color. Where the current implementation is genuinely better than Figma (e.g. a compact control vs Figma's full-width row), deviate intentionally and say so.

---

## 1. ZERO TOLERANCE — nothing outside the design system

**YOU MUST NOT** ship any text, color, card, or element that is not drawn from the Qeran design system. The legacy designer built screens half-on, half-off the identity — that era is over.

- If you find ANYTHING not from our identity — a raw color, a legacy style, a hardcoded radius, a Material default — **STOP and rewire it to a token.**
- If the design system is **missing** something you need → **ADD it to the design system** (report the token name + value). NEVER fall back to the old/legacy system.
- **ONE design system, both roles.** The same tokens/widgets serve the user app and the matchmaker. No file may mix two systems. Shared widgets are fair game to edit — unify both apps at once.

The legacy system (`AppColors` / `AppTextStyles` / `AppDimens`) is being **retired**. On ANY file you touch, eliminate ALL legacy completely.

---

## 2. Brand emotion — how it should FEEL

Warm, premium, calm, trustworthy, marriage-focused. Luxurious without being flashy. **Restrained and confident, not loud.** This is a serious Islamic marriage app for people seeking a committed match — the tone is dignified, never playful or "dating-app loud."

---

## 3. Colors — use OUR identity only

> Full hex table + alpha shades + semantic map in `QERAN_DESIGN_SYSTEM.md`. The rules:

- **Two colors carry the brand:** wine `#431C33` (primary) + gold `#E4C094` (accent/verified/celebrate). Over a soft-white canvas.
- **Canvas = soft white `#FEFCFA`.** ⭐ **IMPORTANT — locked final decision.** This is an **intentional override** of the brand guide (which specifies warm cream `#FCEDDD`). We ship the soft white. Do not "correct" it back to cream.
- **Cream tier is for lifted surfaces** (`creamSurface #FBF4E6`) — meta chips, skeleton base, icon discs. **White (`paper #FFFFFF`)** is a lifted surface (cards, nav). Never white-on-white flatly.
- **No greys, ever.** Text neutrals are wine-tinted ink (`inkStrong/inkBody/inkMuted`), never cold grey. Shadows are wine-tinted, never grey.
- **Semantic overrides of the brand guide / intuition:**
  - **Success / verified / celebrate = GOLD, not green.** The brand has no green.
  - **Overlays / scrims = dark WINE, not black.**
  - **Destructive / error = `danger #A33949`** (the only non-wine/gold hue).
  - **Pending / waiting = `goldDeep #B18454`** (deeper gold for legible text/chips on light surfaces).

**FORBIDDEN in feature code:** `Color(0x...)`, Material colors, hardcoded hex, Material red/green/blue, cold neon, fluorescent gradients.

---

## 4. Token rules (mandatory)

All feature code uses tokens only. Constructing raw values in feature code is **forbidden**:

| Concern | Use ONLY | NEVER |
|---------|----------|-------|
| Color | `QeranColors.*` | `Color(0x...)`, Material colors |
| Type | `QeranTypography.*` | raw `TextStyle` with hardcoded size/weight, `AppTextStyles` |
| Spacing | `QeranSpacing.s2..s64` (+ hs/vs helpers) | numeric literals in `EdgeInsets`, `AppDimens` |
| Radius | `QeranRadii.{chip\|control\|card\|panel\|dome}` | `BorderRadius.circular(N)` |
| Shadow | `QeranShadows.{e0\|e1\|e2\|e3\|eHero}` | constructing `BoxShadow` |
| Motion | `QeranMotion.*` + `QeranCurves.*` | raw `Duration`/`Curve` |

- **Pricing / percent / counters / timers → `QeranTypography.numeric`** (forces Montserrat + tabular figures), regardless of locale.
- Numeric literals in `EdgeInsets` are allowed ONLY inside design-system widget files, never in feature code.

---

## 5. Widget consistency — never roll your own

**YOU MUST** use the shared Qeran widgets. Never construct the raw equivalent in feature code:

| Need | Use | NEVER construct |
|------|-----|-----------------|
| Any CTA / button | `QeranButton` | `ElevatedButton` / `FilledButton` / `OutlinedButton` |
| Elevated container | `QeranCard` (radius 20, hero 28) | ad-hoc `Container + BoxDecoration + BoxShadow` |
| Pill / tag | `QeranChip` variants | ad-hoc chip-like containers |
| Loading | `QeranLoader` | `CircularProgressIndicator` |
| Empty / error / skeleton | `QeranEmptyState` / `QeranErrorState` / `QeranSkeleton` | hand-rolled state views |
| Scaffold background | `QeranSurface` (canvas/creamLifted/paper/wineDeep) | raw colored container |
| Top bar | `QeranAppBar` | raw `AppBar` |

**`QeranButton` has 6 variants** (full catalog in `QERAN_DESIGN_SYSTEM.md`):
`primary` (gold/wine) · `primaryWine` (wine/white) · **`primaryGold` (goldDeep/white — for the two-button match rows)** · `secondary` (outline) · `ghost` · `destructive`.
Sizes: `lg / md / sm / xs` (xs = compact, for dense Arabic two-button rows).

> ⚠️ The old "five variants only" rule is superseded — `primaryGold` was added and is in active use. Both buttons in a two-button row use WHITE text; the difference is background (gold vs wine).

Inventing a new visual treatment requires **explicit approval** and goes through the design system — never into a feature folder.

---

## 6. Bidirectional / locale-aware — ALWAYS

**IMPORTANT.** This is **NOT** an "RTL-only" rule. The app supports two languages today — Arabic (RTL) + English (LTR) — and may add more. **Every element must mirror automatically with the language.**

- Design **direction-agnostic.** Never hardcode left/right. Layout must be correct in BOTH directions purely from locale.
- `EdgeInsetsDirectional.only(start/end)` — never `left/right`.
- `PositionedDirectional(start/end)` — never `Positioned(left/right)`.
- `AlignmentDirectional.centerStart/End` — never `Alignment.centerLeft/Right`.
- `TextAlign.start/end` — never `left/right`.
- Auto-flipping directional icons (e.g. `arrow_back_ios_new`) — they mirror on their own.
- **NEVER combine a manual `isRtl` swap WITH framework auto-mirroring** → double-flip bug. Let the `*Directional` widgets do the work. Do NOT use the `Directionality` widget.
- **Test every screen in BOTH Arabic and English** — layout mirrors, text aligns to the correct edge, icons point the right way, nothing double-flips.

---

## 7. Backend is the source of truth — render only what's backed

> Full philosophy is canonical in `ENGINEERING.md §4`. The **UI-specific** rule: if Figma shows something the backend doesn't back (a field, a button with no action) → **OMIT it**, or render it as status text — never fabricate or fake it. The data follows the backend; the LOOK follows our identity.

---

## 8. Motion

- Every animation: duration from `QeranMotion.{fast|standard|gentle|hero}` + curve from `QeranCurves`.
- **Hero surfaces** (splash, match-success, paywall hero, profile-details first paint): signature soft scale-in entry + a decorative gold ring motif (6–10% alpha) + a wine-or-gold accent on the focal element.
- Lists/grids of >4 items: staggered reveal.
- **No spinners on hero surfaces** — use `QeranSkeleton`.
- No loud animations, rotating spinners, or bouncing CTAs.

---

## 9. Refactor, reuse, simplicity

- **Any element that repeats → extract a reusable widget.** What's reusable, reuse — don't re-implement.
- **No complexity for its own sake.** Keep the visual layer simple and readable.
- Shared visual code lives in the design system / `core/`, never duplicated across features.

---

## 10. How to handle a UI task (kinds)

> These are UI **task kinds** (what the work is). How much *process* to apply (explore / plan / stop points) is governed by the ambiguity tiers in `CLAUDE_CODE.md §2` — don't conflate the two.

- **New-surface** (new screen / hero surface): require a visual brief + reference (Figma). Produce a layout sketch before code.
- **Polish** (refining an existing surface): require a 3–5 sentence visual brief.
- **Spot-fix** (single-widget change): implement directly.

All kinds: existing Qeran widgets + tokens only. Files < 200 lines (decompose). Scoped `flutter analyze` clean after each step.

---

## 11. What to avoid (negative rules)

**NEVER:**
- Pure-grey anything (skeletons, loaders, shadows, text). Wine-tinted always.
- Material default radii, Material hard grey drop-shadows.
- Three different button styles on one screen.
- More than two colors in a single composition (besides type).
- Emoji as UI.
- White-on-white flat surfaces.
- Loud/bouncy animation, cold neon, fluorescent gradients.
- Mixing the legacy style system with the design system in one file.

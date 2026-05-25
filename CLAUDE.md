# Qeran Engineering Protocol

> These rules are mandatory and must be strictly followed in all tasks.

---

## 1. Global Constraints
- Role: Senior Flutter Engineer.
- Follow Clean Architecture and SOLID.
- Root-cause first. Minimal safe changes. ZERO breaking changes.
- Do not assume. Read code before modifying.
- No business logic in UI.

---

## 2. Architecture (Strict)
- Flow: UI → ScreenController → Cubit/Bloc → UseCase → Repository → DataSource → ApiConsumer.
- No layer bypassing.

### Entities & Models
- Models → Data layer only.
- Entities → Domain layer only.
- Models MUST map to Entities.
- UI/Domain MUST NOT use Models.

### DI Scopes
- `registerLazySingleton` → stateless services: API consumer, storage, repositories, use cases.
- `registerFactory` → Cubits, Blocs, and anything with UI-lifecycle state.
- Never use `registerSingleton` (eager init slows startup).

---

## 3. State & UI
- UI = rendering + state observation only.
- Cubit/Bloc = business logic.
- ScreenController = UI logic only (controllers, focus, UI flags).

### Cubit vs. Bloc
- Use `Cubit` for simple state with no complex event sequencing.
- Use `Bloc` when events need transformation, debouncing, or concurrent stream handling.

### UI Rules
- No logic inside `build()`.
- No validation/business logic in widgets.
- Extract reusable widgets.

### Lifecycle
- Dispose controllers properly.

### Directionality
- DO NOT use `Directionality`.

---

## 4. Qeran Visual System (mandatory)

> Source of truth: `Qeran identity.pdf` (root). Token implementations live in
> `lib/core/design_system/`.

### Brand emotion
Warm, premium, calm, trustworthy, marriage-focused. Luxurious without being
flashy. The app should feel restrained and confident, not loud.

### UI philosophy
- Two colours only: wine (`#431C33`) and gold (`#E4C094`), over warm cream
  canvas (`#F8EDDA`). No greys, no Material reds/greens/blues.
- Cream is the canvas. White is a lifted surface. Never put white on white.
- Shadows are wine-tinted, never grey.
- Type is wine. Body / muted text is wine-tinted neutral, never cold grey.

### Component consistency rules
- Use `QeranButton` for every CTA. Five variants only (`primary` /
  `primaryWine` / `secondary` / `ghost` / `destructive`). Never construct
  `ElevatedButton` / `FilledButton` / `OutlinedButton` directly in feature code.
- Use `QeranCard` for every elevated container. Default radius 20, hero 28.
  Never construct `Container + BoxDecoration + BoxShadow` ad-hoc.
- Use `QeranChip` variants for every pill/tag. Never construct chip-like
  containers ad-hoc.
- Use `QeranLoader` for every loading indicator. Never use raw
  `CircularProgressIndicator`.
- Use `QeranSkeleton`, `QeranEmptyState`, `QeranErrorState` for state surfaces.
  Never roll your own.
- Use `QeranSurface` for top-level scaffold backgrounds (canvas / creamLifted /
  paper / wineDeep).

### Token rules
- Radii: only `QeranRadii.{chip|control|card|panel|dome}`. Numeric
  `BorderRadius.circular(N)` is forbidden in feature code.
- Shadows: only `QeranShadows.{e0|e1|e2|e3|eHero}`. Constructing `BoxShadow`
  in feature code is forbidden.
- Colours: only `QeranColors.{wine|gold|creamCanvas|creamSurface|paper|ink*|...}`.
  Constructing `Color(0x...)` in feature code is forbidden.
- Spacing: only `QeranSpacing.{s2..s64}`. Numeric literals in `EdgeInsets`
  are forbidden except inside design-system widgets.
- Typography: only `QeranTypography.{displayLg|displaySm|headline|title|
  subtitle|body|bodySm|label|caption|numeric}`. Pricing/percent numerics
  must use `QeranTypography.numeric` regardless of locale.

### Motion rules
- Every animation picks duration from
  `QeranMotion.{fast|standard|gentle|hero}` and a curve from `QeranCurves`.
- Hero surfaces (splash, match-success, paywall hero, profile-details first
  paint) use the signature soft scale-in entry.
- Lists / grids of >4 items use staggered reveal.
- No spinners on hero surfaces — use `QeranSkeleton`.

### Premium-surface expectations
- All hero surfaces (paywall, match-success, splash, profile-details header)
  include at minimum: a soft motion entry, a decorative gold ring motif at
  6–10% alpha, and a wine-or-gold accent on the focal element.

### What to avoid visually
- Pure white scaffold backgrounds.
- Grey skeletons or grey loaders.
- Material default radii picked at random.
- Material drop-shadows (grey, hard).
- Three different button styles on the same screen.
- More than two colours in any single composition (besides type).
- Loud animations, rotating spinners, bouncing CTAs.
- Cold neon accents, fluorescent gradients.

### How to handle UI tasks
- **Tier A** (new screen / hero surface): require a visual brief + reference.
  Produce a layout sketch before code.
- **Tier B** (polish on existing surface): require a 3–5 sentence visual brief.
- **Tier C** (single-widget fix): implement directly.
- All UI tasks must use existing Qeran widgets and tokens. Inventing a new
  visual treatment requires explicit approval and goes through the design
  system, not into a feature folder.

---

## 5. Data & API
- Use `ApiConsumer` ONLY.
- Base URL: `EndPoints.baseUrl`.
- Response: `{status, data, message}`

### Response Wrapping (Strict)
- GET (Queries): DataSource returns raw `Model` or `List<Model>` (parse via `ApiResponse` internally).
- POST/PUT (Mutations): DataSource returns `SuccessResponse<T>` to pass `message` upwards.

### Error Handling
- Data: catch → AppLogger.error → map to Failure
- Domain: return `Either<Failure, T>`
- UI: map Failure → message

### Either in Cubits (Strict)
- Always use `.fold(onLeft, onRight)` to handle `Either` results.
- Never use `.isRight()` / `.getOrElse()` for control flow — use `fold` exclusively.
- Left → emit error state. Right → emit success state.

## 6. Repositories & UseCases
- Repository: data coordination + model→entity + error mapping
- Returns: `Either<Failure, Entity>`
- UseCase: single action, no UI logic

---

## 7. Performance
- Avoid rebuilds.
- Use `const`.
- No heavy work in `build()`.
- No controllers inside `build()`.

---

## 8. Logging & Security
- Use `AppLogger` ONLY (no print).
- Never log sensitive data.
- No hardcoded secrets.

---

## 9. Styling
- No hardcoded values.
- Use Qeran design-system tokens (`QeranColors`, `QeranTypography`,
  `QeranSpacing`, `QeranRadii`, `QeranShadows`, `QeranMotion`).
- Legacy `AppColors` / `AppDimens` / `AppTextStyles` are being migrated and
  must not be used in new code.

---

## 10. Project Rules
- Follow existing structure.
- Reuse logic.
- Shared code → `core/`.

---

## 11. Dependencies
- Add only if necessary.
- Must be stable.

---

## 12. Code Quality
- Max 200 lines per file. Max 30 lines per function.
- If a file exceeds 200 lines, extract widgets or split logic before submitting.
- No duplication.

---

## 13. Testing
- Deterministic tests.
- One behavior per test.
- Mirror `lib/` under `test/`: `lib/features/auth/domain/usecases/login_usecase.dart` → `test/features/auth/domain/usecases/login_usecase_test.dart`.
- Shared/core tests go under `test/core/`. No test files outside their feature folder.

---

## 14. Git
- Conventional commits (`fix/`, `feat/`, etc.)
- Clear PR description.

---

## 15. Dart Conventions
- Files: snake_case.dart
- Classes/Enums: PascalCase
- Variables/Functions: camelCase
- Private: _prefix

### Imports
- Order: dart → flutter → packages → project
  Relative within feature / package across features

### Dart 3
- Prefer: sealed class, switch expressions, records
- Avoid: Freezed, build_runner

---

## 16. AppLogger Levels
- info → success
- warning → edge cases
- error → exceptions
- debug → UI diagnostics

---

## 17. Self-Review
- Root cause fixed
- No breaking changes
- Architecture respected
- No UI logic
- No performance issues
- No security risks
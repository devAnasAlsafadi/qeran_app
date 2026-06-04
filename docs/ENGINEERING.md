# Qeran — Engineering Protocol (ENGINEERING.md)

> Mandatory code rules for all tasks. **Strictly followed.**
> **UI / design rules are NOT here** → see `DESIGN.md`. This file is code only.

---

## 1. Global Constraints
- Role: **Senior Flutter Engineer.**
- Clean Architecture + SOLID.
- **Root-cause first. Minimal safe changes. ZERO breaking changes.**
- **Do not assume — read the code before modifying.**
- No business logic in UI.
- Code must be **readable, clear, and self-explanatory** — favour the simplest correct solution over clever complexity.

---

## 2. Architecture (strict)
- Flow: `UI → ScreenController → Cubit/Bloc → UseCase → Repository → DataSource → ApiConsumer`. **No layer bypassing.**

**Entities & Models**
- Models → **data layer only.** Entities → **domain layer only.**
- Models MUST map to Entities. UI/Domain MUST NOT use Models.

**DI scopes**
- `registerLazySingleton` → stateless services (ApiConsumer, storage, repositories, use cases).
- `registerFactory` → Cubits/Blocs and anything with UI-lifecycle state.
- **Never** `registerSingleton` (eager init slows startup).

---

## 3. State & UI
- UI = rendering + state observation only. Cubit/Bloc = business logic. ScreenController = UI logic only (controllers, focus, UI flags).
- **Cubit** for simple state; **Bloc** only when events need transformation, debouncing, or concurrent stream handling.
- No logic inside `build()`. No validation/business logic in widgets. Dispose controllers properly.

**Widget extraction rule (IMPORTANT)**
- A widget used in **more than one place** → extract it as its own reusable widget (its own file).
- A widget used **only inside one class** → keep it **private** (`_Name`) and local to that class — do NOT export it.
- Any element that repeats → refactor it out. Never duplicate widget code.

---

## 4. Data & API
- Use **`ApiConsumer` only.** Base URL: `EndPoints.baseUrl`. Envelope: `{status, data, message}` (status `1` = success).

**Backend-driven / DYNAMIC (IMPORTANT — project philosophy · CANONICAL — other docs point here)**
- Most of the app is **dynamic**: questions, plans, ordering, limits all come from the backend/dashboard. The client does **not** hardcode counts or ordering.
- **Follow the backend's flow.** Render **only what the backend/model supports** — never fabricate fields, states, or buttons. If a value isn't backed, omit it; don't fake it.

**Response wrapping (strict)**
- GET (queries): DataSource returns raw `Model` / `List<Model>` (parse via `ApiResponse` internally).
- POST/PUT (mutations): DataSource returns `SuccessResponse<T>` (to pass `message` upward).

**Error handling**
- Data: `catch` → `AppLogger.error` → map to `Failure`.
- Domain: return `Either<Failure, T>`.
- UI: map `Failure` → message.

**Either in Cubits (strict)**
- Always `.fold(onLeft, onRight)`. **Never** `.isRight()` / `.getOrElse()` for control flow.
- Left → emit error state. Right → emit success state.

---

## 5. Repositories & UseCases
- Repository: data coordination + model→entity + error mapping. Returns `Either<Failure, Entity>`.
- UseCase: single action, no UI logic.

---

## 6. Performance
- Avoid rebuilds. Use `const`. No heavy work or controllers inside `build()`.

---

## 7. Logging & Security
- **`AppLogger` only** (no `print`). Never log sensitive data. No hardcoded secrets.
- Levels: `info` → success · `warning` → edge cases · `error` → exceptions · `debug` → UI diagnostics.

---

## 8. Styling
- **No hardcoded values.** Use Qeran design-system tokens only. Legacy `AppColors` / `AppDimens` / `AppTextStyles` must not be used in new code (being retired).
- **All visual rules, tokens, and widget usage → `DESIGN.md` + `QERAN_DESIGN_SYSTEM.md`.**

---

## 9. Project Rules
- Follow the existing structure. Reuse logic. Shared code → `core/`.
- Dependencies: add only if necessary and stable.

---

## 10. Code Quality
- **Max 200 lines per file. Max 30 lines per function.** If a file exceeds 200 lines, extract widgets / split logic before submitting.
- **No duplication.** Scoped `flutter analyze` clean after each step (no new warnings).

---

## 11. Testing
- Deterministic. One behaviour per test.
- Mirror `lib/` under `test/` (e.g. `lib/features/auth/domain/usecases/login_usecase.dart` → `test/features/auth/domain/usecases/login_usecase_test.dart`). Shared/core tests → `test/core/`. No test files outside their feature folder.

---

## 12. Git & Dart 3
- Conventional commits (`feat/`, `fix/`, …). Clear PR description.
- Prefer Dart 3: **sealed classes, switch expressions, records.** Avoid Freezed / build_runner.
- Imports order: dart → flutter → packages → project. Relative within a feature; package import across features.

---

## 13. Self-Review (before submitting)
- [ ] Root cause fixed (not a patch)
- [ ] No breaking changes
- [ ] Architecture respected (no layer bypass, no Models in UI/Domain)
- [ ] No business logic in UI
- [ ] Backend-driven: only backed data rendered, nothing fabricated
- [ ] Reusable widgets extracted; single-use widgets private
- [ ] No performance issues (const, no build() work)
- [ ] No security risks; `AppLogger` only
- [ ] Files < 200 lines, functions < 30; analyze clean

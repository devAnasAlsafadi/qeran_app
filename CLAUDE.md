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

---

## 3. State & UI
- UI = rendering + state observation only.
- Cubit/Bloc = business logic.
- ScreenController = UI logic only (controllers, focus, UI flags).

### UI Rules
- No logic inside `build()`.
- No validation/business logic in widgets.
- Extract reusable widgets.

### Lifecycle
- Dispose controllers properly.

### Directionality
- DO NOT use `Directionality`.

---

## 4. Data & API
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

## 5. Repositories & UseCases
- Repository: data coordination + model→entity + error mapping
- Returns: `Either<Failure, Entity>`
- UseCase: single action, no UI logic

---

## 6. Performance
- Avoid rebuilds.
- Use `const`.
- No heavy work in `build()`.
- No controllers inside `build()`.

---

## 7. Logging & Security
- Use `AppLogger` ONLY (no print).
- Never log sensitive data.
- No hardcoded secrets.

---

## 8. Styling
- No hardcoded values.
- Use Theme / AppColors / AppDimens.

---

## 9. Project Rules
- Follow existing structure.
- Reuse logic.
- Shared code → `core/`.

---

## 10. Dependencies
- Add only if necessary.
- Must be stable.

---

## 11. Code Quality
- Small files/functions.
- No duplication.

---

## 12. Testing
- Deterministic tests.
- One behavior per test.

---

## 13. Git
- Conventional commits (`fix/`, `feat/`, etc.)
- Clear PR description.

---

## 14. Dart Conventions
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

## 15. AppLogger Levels
- info → success
- warning → edge cases
- error → exceptions
- debug → UI diagnostics

---

## 16. Self-Review
- Root cause fixed
- No breaking changes
- Architecture respected
- No UI logic
- No performance issues
- No security risks
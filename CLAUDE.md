# Qeran — Claude Code Project Memory (CLAUDE.md)

> Single Flutter APK, **two roles** (regular user + matchmaker/"Moderator"), branching at splash on the server `role`. Feature-based Clean Architecture, Cubit state, `easy_localization` (ar default + en). Islamic matrimony app — no direct user-to-user contact; the matchmaker mediates everything.

---

## ⭐ Read the right doc for the task (progressive disclosure)

This file is the index and is always loaded. The detail docs are **not** pre-loaded — **Read the specific doc when the task matches** (don't work from memory, don't assume it's already in context):

- **Any UI / design task** → Read `docs/DESIGN.md` (rules) + `docs/QERAN_DESIGN_SYSTEM.md` (token/widget catalog)
- **Any code task** → Read `docs/ENGINEERING.md` (architecture, state, API, testing, review)
- **How to approach a task** (plan vs. direct, stopping, staging) → Read `docs/CLAUDE_CODE.md`

---

## 🔑 Top rules (the load-bearing ones — full detail in the docs above)

1. **Figma = shape only. OUR identity = all colors/type/spacing/radii.** Match Figma's structure, paint in our identity. (`DESIGN.md`)
2. **Design system is law — ZERO tolerance.** No `Color(0x..)`, no Material colors/widgets, no legacy `AppColors`/`AppTextStyles`/`AppDimens`/`CustomButton`/`AppTextFormField`. Tokens + Qeran widgets only. If a token is missing, ADD it to the design system — never fall back to legacy. (`DESIGN.md`)
3. **Identity:** wine `#431C33` · gold `#E4C094` · soft-white canvas `#FEFCFA` (locked — intentional override of the brand guide's cream). Success/verified = gold (no green). Overlays = dark wine (no black). Danger = `#A33949`. **6** QeranButton variants (incl. `primaryGold`).
4. **Bidirectional / locale-aware ALWAYS** (ar RTL + en LTR, more later). `*Directional` everywhere; never hardcode left/right; never combine manual `isRtl` swap with auto-mirroring (double-flip). No `Directionality` widget.
5. **Backend-driven / DYNAMIC.** Render only what the backend backs — never fabricate fields/states/buttons; if unbacked, omit. (Canonical: `ENGINEERING.md §4`.)
6. **Architecture:** `UI → ScreenController → Cubit/Bloc → UseCase → Repository → DataSource → ApiConsumer`. No layer bypass. Models in data only, Entities in domain only. `Either` via `.fold` only. (`ENGINEERING.md`)
7. **Widgets:** reused in >1 place → extract to its own file. Used in one class only → keep private (`_Name`). Never duplicate.
8. **Files < 200 lines, functions < 30.** Scoped `flutter analyze` clean after each step.
9. **UI tasks = UI only** — never touch cubit logic / data flow / backend wiring unless explicitly authorised (then isolate + report it).
10. **ASK on anything you'd DECIDE.** Don't assume or guess. Ask on unclear requirements AND cosmetic/scaffolding calls alike — never auto-decide-and-report. Only truly trivial, fully-specified tweaks (nothing to decide) go direct. A question is cheaper than rework. (Detail: `CLAUDE_CODE.md §3`.)

---

## 🔄 Task workflow (`CLAUDE_CODE.md` for detail)

- **Explore → Plan → Code → Commit.** Don't jump straight to code on non-trivial work.
- **Size it:** *clear & specific with no ambiguous decisions?* → do it directly (even several small tweaks). *Decisions/states/new flow?* → plan first, STOP for approval, build sub-step by sub-step, STOP for review between steps, end with a summary.
- **Staging hygiene (strict):** never stage `qeran_colors.dart` (token file), `docs/`, `web/` without confirmation. Commit per logical group, only when confirmed.
- **Verify before "done":** *"Would a senior engineer approve this?"* Match Figma in our identity; mirror correctly in AR + EN.

---

## 🧭 Project state

**At the start of any non-trivial task, read `docs/HANDOFF.md`** — it's the single canonical "where we are" (current focus, recent decisions, next steps, gotchas, open backend asks). Per-screen done/partial status is **not** tracked there — derive it from code + the legacy-grep gate (`CLAUDE_CODE.md §5`). ⚠️ Don't trust commit messages claiming screens are "unified"; verify against code.

---

## 📁 Build / run

- `flutter pub get` · `flutter run` · scoped analyze: `flutter analyze lib/features/<feature>`
- Locale keys (after editing `assets/translations/{ar,en}.json`): `dart run easy_localization:generate -S assets/translations -O lib/generated -o locale_keys.g.dart -f keys`

---

## 📝 Self-improvement

When corrected, capture the lesson so it doesn't repeat — append a one-line rule to the **Lessons** section in `docs/CLAUDE_CODE.md`. These docs are living; refine them like a frequently-used prompt.

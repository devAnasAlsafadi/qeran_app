# Qeran — Working With Claude Code (CLAUDE_CODE.md)

> **How Claude Code should approach EVERY task.** Behaviour rules — not code style (see `ENGINEERING.md`) and not design (see `DESIGN.md`).
> **IMPORTANT:** these rules are advisory; treat them as priority constraints, not preferences.

---

## 1. The core workflow — Explore → Plan → Code → Commit

For any non-trivial task, follow the four phases. **Do NOT jump straight to writing code.**

1. **Explore** — read the relevant files and understand what exists. **No edits in this phase.**
2. **Plan** — propose the approach + a step breakdown, then **STOP and wait for approval.** The plan is a reviewed spec.
3. **Code** — implement the approved plan, step by step, verifying against it.
4. **Commit** — only when confirmed, with a clear conventional-commit message.

> **Why:** a feature has ~20 decision points. At 80% per decision, getting all right unplanned ≈ 1%. Planning turns 20 ambiguous calls into one reviewed spec where each is ~100% because the human already approved it.

---

## 2. Sizing the task — how much process to apply

**The deciding question (NOT "how many edits"):**
> **Is the task clear and specific with NO ambiguous decisions?**

- **Yes** (even if it's several small, fully-specified changes — e.g. enlarge a font, tighten padding, swap a token) → **execute directly. No analysis, no plan.**
- **No** (architectural choices, multiple states, a new flow, anything you'd have to *decide* rather than *apply*) → **plan first.**

It's about **ambiguity / number of decisions**, not the number of lines changed.

### The three tiers

**Tier C — Small / fully-specified** ("enlarge this text", "fix this spacing", "change this color", a few clear tweaks)
→ Go straight to the file and apply it. No exploration, no plan, no summary. Just do it, run scoped `flutter analyze`, done.

**Tier B — Medium** ("align this screen to Figma", "unify this widget", a contained change with a few choices)
→ Brief plan (a few lines) → apply → scoped `analyze` → **STOP for visual/review check.**

**Tier A — Full feature / new screen / cross-cutting change** ("build the profile-edit screen", "add the photo-exchange flow")
→ **Explore first (read code, report what exists).**
→ Produce a **plan + a to-do list of sub-steps**, mapping each step. **STOP for approval before any code.**
→ Implement **sub-step by sub-step.** After each: scoped `analyze` + **STOP for the human's check** before the next.
→ End with a **full summary** (see §5).

> When unsure which tier, ask — or default to the safer (higher) tier.

---

## 3. Collaboration rules (always)

- **ASK on anything you'd DECIDE, not just apply (IMPORTANT).** If the task needs information or a choice you don't have — an unclear requirement, a missing detail, an edge case, how a flow should behave, OR a cosmetic/scaffolding call (naming, placement, which token, a default value) — **STOP and ask.** This applies to **semantic AND cosmetic** decisions alike: the "just move on for cosmetic choices" default is **retired**. Do NOT assume, do NOT guess, and do NOT auto-decide-then-report. The ONLY thing that proceeds without asking is a **truly trivial, fully-specified tweak** (Tier C) where there is nothing to *decide*, only to *apply*. When in doubt, ask rather than invent — a question is far cheaper than rework.
- **STOP at the checkpoints.** Never run a whole multi-step feature start-to-finish without stopping for the human's review between sub-steps.
- **Don't fabricate.** If something needs a backend endpoint/field that doesn't exist, **flag exactly what's missing** — never fake data, states, or buttons. (Backend-driven philosophy: `ENGINEERING.md §4`.)
- **Stay in scope.** UI/styling task → do NOT change cubit logic, data flow, or backend wiring. If a logic change is genuinely required, **isolate it, call it out explicitly, and report exactly what changed.**
- **Verify, don't assume.** Re-check claims against the actual code before acting on them (a prior analysis can be wrong).
- **Report what you changed** — tokens/keys added, files touched, anything noteworthy — at every stop.

---

## 4. Staging hygiene (strict — zero tolerance)

- **NEVER stage** without explicit confirmation: the design-system token file (`qeran_colors.dart`), `docs/`, `web/`.
- If shipped code depends on a token addition to compile, stage **only that hunk** (`git add -p`) — leave unrelated experiments unstaged. Confirm via `git status` before committing.
- **Commit per logical group**, only when the human confirms — not per tiny edit, not one giant commit at the end. Commits are checkpoints + a revert safety net.

---

## 5. Verification before "done"

- **Never mark a task complete without proving it works.** Ask: *"Would a senior/staff engineer approve this?"*
- Scoped `flutter analyze` clean (no new warnings). Files < 200 lines. Logic untouched unless explicitly authorised.
- For UI: it must match the Figma reference **in our identity**, and mirror correctly in **both Arabic and English**.

**Objective gates — run on every migrated file (not optional):**
- **Legacy-grep gate → must be ZERO.** After migrating a file, grep it and confirm no legacy remains:
  `AppColors | AppTextStyles | AppDimens | CustomButton | AppTextFormField | Color(0x | BorderRadius.circular | CircularProgressIndicator`
  Any hit = not done. Missing a token? **Add it to the design system** — never leave legacy behind.
- **Styling-only-diff gate.** `git diff` the file: a UI / unification task must touch **only** styling. If any **cubit / datasource / usecase / repository** line changed, STOP and flag it (scope-leak — see §3 "stay in scope").

### Tier-A summary format (end of a full feature)
A clear closing summary with:
- **What changed** — the sub-steps completed + files touched.
- **Decisions made** — anything chosen along the way (flag for the human's eye).
- **Tokens / locale keys added** (if any).
- **Flags** — gaps, deferred items, backend asks, anything needing a decision.
- **What to check** — exactly what the human should verify (AR + EN).

---

## 6. Self-improvement loop (IMPORTANT)

**When Claude Code makes a mistake and the human corrects it, that lesson must be captured so it never repeats.**
- After any correction, add a one-line rule to the **Lessons** section below (or the relevant rules file) that would have prevented it.
- Ruthlessly iterate: the goal is a steadily dropping mistake rate. These files are living documents, refined like a frequently-used prompt.

### Lessons (append as they happen)
- **Stage field type mismatch:** backend may send an enum as a string (e.g. `"WaitingForPhotoExchange"`) while the client parses an int — a silent critical bug. Confirm types against the backend doc.
- **QeranAppBar double-flip:** never combine a manual `isRtl` swap with framework auto-mirroring — it double-flips. Let `*Directional` widgets handle it.
- **goldDeep token:** pending/waiting accents need `goldDeep` (#B18454), not light `gold`, for legible white text / contrast on light surfaces.
- **Buttons:** there are **6** `QeranButton` variants (incl. `primaryGold`), not five — don't assume the old count.
- _(add new lessons here as they occur)_

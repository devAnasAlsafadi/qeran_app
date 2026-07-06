# Piece 5 (lazy-mount) — cold-start burst BASELINE ("before")

> Uncommitted evidence note. Captured to compare against the post-Piece-5 HTTP log
> for that piece's HTTP-log verification gate. NOT part of any commit.

## Context
- **Scenario:** cold start, authenticated user (post-login shell entry).
- **Captured:** during F1 sub-step 2 verification on the emulator.
- **Cause:** both home shells use `IndexedStack` that eagerly mounts every tab's cubit
  at shell build, so all tabs fire their initial GET at once (Investigation §8.4).

## The 5 parallel GETs fired at once (the burst to eliminate)
1. `GET /subscriptions/current`
2. `GET /notifications`
3. `GET /Discovery`
4. `GET /likes/outgoing`
5. `GET /chat/my-matchmaker`

## Expected "after" (post Piece 5)
Entering Home should fire ONLY the Discovery (resp. Dashboard) GET; the other tabs'
GETs should fire on first visit, once each, and NOT re-fire on tab switch-back.
Compare this list against the post-Piece-5 `AppLogger 'HTTP'` log at that gate.

---

## AFTER — Piece 5 landed (lazy-mount IndexedStack)

Implemented via a `Set<int> _visited` in both `_HomeScreenState` and
`_MatchmakerHomeScreenState`: unvisited tab indices render `const SizedBox.shrink()`,
so their cubits (and initial GETs) don't spin up until first visit; once visited a
tab stays mounted (state survival intact).

**Expected cold-start log (to confirm on device):**
- **User shell:** `GET /Discovery` (tab 0) + the boot-level/badge calls that are NOT
  tab-owned (`/subscriptions/current` from `main.dart` hydrate, notification badge).
  NO `/likes/outgoing`, NO `/chat/my-matchmaker`, NO `/profile` until those tabs are
  opened.
- **Matchmaker shell:** `GET /matchmaker/dashboard` (tab 0) + notification `/count`
  (bell, primed in initState — not tab-owned). NO users/cases/conversations/explore
  fetches until visited.
- Visiting Likes → Chat → Profile fires each tab's GET exactly once; switching back to
  an already-visited tab fires nothing (state survives).

> ⚠️ Actual device log to be pasted here by Anas after the airplane-off cold-start run
> (this file stays uncommitted — evidence only).

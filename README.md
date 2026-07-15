# Zameen Clone — UI-only Flutter build

This is a **UI-only** version of the app: every screen, button, and flow
works, but it's all backed by in-memory mock data — no Django server, no
PostgreSQL, no network calls of any kind except fetching public OpenStreetMap
map tiles. Nothing here talks to the `backend/` folder in this project.

This is intentional, not a fallback — it's for testing layout, navigation,
and interaction flow quickly, without the setup overhead of running a
database and API server alongside it. When you're ready to connect the real
backend (Django + PostGIS, already built and tested — see `backend/`),
that's a separate, larger task: swapping the mock providers in
`lib/core/mock/mock_data.dart` for real repository classes that call the API.

## What works right now

- **Auth**: sign up as buyer or agent (any credentials "succeed" — there's
  no real account system), log in, log out. Role choice on signup determines
  whether you see agent-only features.
- **Listings feed**: 6 seeded mock properties across Islamabad, Rawalpindi,
  Lahore, and Karachi. Filter by city, purpose, type, price range, bedrooms.
- **Property detail**: full info, favorite toggle, contact-agent sheet
  (call/WhatsApp/message buttons are mocked — they show a confirmation
  snackbar instead of actually launching anything).
- **Map search**: real OpenStreetMap tiles, draggable center pin, radius
  slider. The distance filtering is genuinely correct (haversine formula),
  not just decorative — it's the same math a real backend would use, just
  run on-device against the mock list instead of in PostgreSQL.
- **Favorites**: save/unsave from any card, dedicated saved screen.
- **Post a property** (agent-only): full form with multi-photo picker
  (photos are shown locally via `Image.file`, never uploaded anywhere) —
  posting adds the listing to the in-memory list immediately, and it shows
  up in both the feed and your profile's "My listings."
- **Profile**: role badge, my listings (agents), logout.

## What's mocked / simplified vs. the full version

- No backend calls anywhere — `lib/core/mock/mock_data.dart` is the single
  source of truth for all data, held in Riverpod `Notifier`s.
- All data resets when you restart the app — nothing persists.
- "Use my location" on the map and in post-listing jumps to a fixed
  coordinate instead of asking for real GPS — there's no `geolocator`
  dependency in this build.
- City names in the post-listing form only geocode correctly for
  Islamabad, Rawalpindi, Lahore, and Karachi (a tiny hardcoded lookup) —
  anything else falls back to Islamabad's coordinates on the map.
- Call/WhatsApp/message buttons simulate the action with a snackbar instead
  of actually deep-linking out — no `url_launcher` dependency in this build.

## Running on Windows (phone-sized desktop window)

1. **One-time setup**, if you haven't built a Windows Flutter app before:
   ```bash
   flutter config --enable-windows-desktop
   ```
   You also need the "Desktop development with C++" workload installed via
   Visual Studio (the free Community edition works) — check with
   `flutter doctor`, it'll tell you if this is missing.

2. From `flutter_app/`, generate the native Windows project (this only
   needs to happen once — it fills in the `windows/` folder without
   touching your existing `lib/` or `pubspec.yaml`):
   ```bash
   cd flutter_app
   flutter create . --platforms=windows --org com.yourname --project-name zameen_clone
   ```

3. ```bash
   flutter pub get
   flutter analyze
   ```
   Run `flutter analyze` before anything else — this sandbox doesn't have
   the Flutter SDK to run it directly, so every file was checked by hand
   for import correctness and brace/paren/bracket balance, but a type-level
   check on your machine is still the real test.

4. ```bash
   flutter run -d windows
   ```

The window opens locked at 430×900 (no resizing) so it reads as a phone
screen rather than a normal resizable desktop window. Change
`_desktopWindowSize` near the top of `lib/main.dart` if you want different
dimensions.

## Running on Android/iOS instead

Same `flutter create .` step (drop `--platforms=windows`, or just run it
with no `--platforms` flag to generate everything), then `flutter run` with
an emulator/simulator running, or a connected device. No backend-specific
setup needed since this build doesn't talk to one.

## Project structure

```
lib/
├── core/
│   ├── mock/mock_data.dart     # single source of truth — all app data lives here
│   ├── routing/app_router.dart # go_router config, auth-aware redirects
│   ├── theme/                  # colors, app theme
│   └── widgets/                # splash screen, bottom-nav shell
├── features/
│   ├── auth/                   # signup/login screens + mock auth state
│   ├── listings/                # feed, detail, post-listing, filter sheet
│   ├── map_search/              # OpenStreetMap-based radius search
│   ├── favorites/                # saved properties screen
│   └── profile/                  # user info, my listings, logout
└── main.dart                    # entry point + Windows window sizing
```

## Connecting the real backend later

When you're ready to wire this up to the actual API:

1. Start the Django backend (`backend/` — see git history / earlier project
   notes for the full PostgreSQL + PostGIS setup walkthrough).
2. In `lib/core/mock/mock_data.dart`, the providers
   (`mockDataProvider`, `favoritesProvider`, `myListingIdsProvider`, etc.)
   are the seam to replace — swap their `Notifier`/`Provider` bodies for
   ones that call repository classes talking to Dio instead of holding
   data in memory. The screens themselves (`listings_screen.dart`,
   `property_detail_screen.dart`, etc.) were written against these same
   provider names and mostly won't need to change.
3. You'll want to bring back `dio`, `flutter_secure_storage`,
   `cached_network_image`, `geolocator`, and `url_launcher` in
   `pubspec.yaml` — all removed from this build since they were only there
   to support backend/network/device-API features.

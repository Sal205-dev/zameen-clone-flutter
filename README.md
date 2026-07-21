# DHA App — Flutter Frontend

The mobile client for the DHA App real-estate platform. Fully connected to
the live Django backend (see `dha-backend`, deployed on Railway) — real
accounts, real JWT auth, real property listings with photo/video uploads
to Cloudinary, real email verification and password reset. This is **not**
a mock/UI-only build anymore.

## What works

- **Auth**: sign up (username, email, password, phone, first/last name,
  role), log in, log out, JWT tokens stored in encrypted secure storage
  and auto-refreshed. Live username-availability check while typing.
- **Email verification & password reset**: a code is emailed on signup
  (via the backend's Brevo integration); the profile screen shows an
  unverified banner until confirmed. "Forgot password" flow on the login
  screen.
- **Signup validation**: debounced (not per-keystroke) live checks —
  email restricted to the 10 most common providers, phone capped at the
  ITU's 15-digit international limit, password strength meter.
- **Listings feed**: real properties fetched from the API, filterable by
  city, purpose, type, price range, bedrooms.
- **Post a property** (agent role): full form, multi-photo + video upload
  — files go straight to Cloudinary via the backend, with per-file error
  handling so one failed upload doesn't silently break the rest.
- **Property detail**: full info page, favorite toggle.
- **Profile**: view/edit profile, email verification banner, logout.
- **Full English/Urdu localization**: every screen, powered by
  `easy_localization` — a language toggle in the side drawer switches the
  whole app instantly.
- **Side drawer**: functional nav items (Home, Post a property, Favorites)
  plus "coming soon" feedback on the not-yet-built ones (Search, Projects,
  Saved Searches, DHA Tools, News, Blog, About Us) instead of doing
  nothing when tapped.

## Known limitations (not yet wired to the backend)

- **Map search** still runs on in-memory mock data
  (`lib/core/mock/mock_data.dart`), not the real API — the OpenStreetMap
  tiles and radius/haversine filtering are real, the listings behind them
  aren't.
- **Favorites** are local-only (not synced to your account server-side) —
  they reset if the app is reinstalled.
- **"Use my location"** jumps to a fixed coordinate instead of asking for
  real GPS — no `geolocator` dependency yet.
- **Call / WhatsApp / message buttons** on property detail show a
  confirmation snackbar instead of actually deep-linking out — no
  `url_launcher` dependency yet.
- **"Projects"** bottom-nav tab is a placeholder screen.
- No iOS project has been scaffolded, and there's no automated test suite.

## Tech stack

- Flutter + Riverpod (state management)
- `go_router` — routing, with auth-aware redirects
- `dio` — HTTP client, talks to the Django backend (15s timeouts)
- `flutter_secure_storage` — encrypted JWT token storage
- `easy_localization` — English/Urdu translations
  (`assets/translations/en.json`, `ur.json`)
- `flutter_map` + `latlong2` — OpenStreetMap-based map search
- `image_picker` / `video_player` — property media

## Backend connection

The API base URL is hardcoded in `lib/core/utils/app_constants.dart`:
```dart
static String get apiBaseUrl =>
    'https://dha-backend-production.up.railway.app/api';
```
This points at the live Railway deployment — the app works from any
device with internet access, no local server or matching Wi-Fi network
needed. Only change this if you're deliberately testing against a local
backend (see the backend repo's README for that setup), and revert it
before committing.

## Running the app

### One-time setup, if you haven't built for this platform before
```bash
flutter config --enable-windows-desktop   # only if targeting Windows
```
Windows also needs the "Desktop development with C++" workload via Visual
Studio — `flutter doctor` will flag it if missing.

### Generate the native project (first time only)
```bash
cd flutter_app
flutter create . --platforms=windows,android --org com.yourname --project-name zameen_clone
```
Drop `--platforms` (or list the ones you need) to target Android/iOS
instead — this only fills in the native `windows/`/`android/` folders
without touching `lib/` or `pubspec.yaml`.

### Install dependencies and run
```bash
flutter pub get
flutter analyze
flutter run
```
Pick a connected device or running emulator when prompted, or add `-d
windows` / `-d chrome` / etc. to target a specific one.

On Windows, the app window is locked at 430×900 (no resizing) to read as
a phone screen rather than a normal desktop window — change
`_desktopWindowSize` near the top of `lib/main.dart` if you want
different dimensions.

**If `flutter run` fails with "could not connect to server" but the app
works fine from an installed APK on a real phone**: this is almost always
the emulator's own networking, not the app — the API URL is identical for
debug and release builds. Try loading any website in the emulator's
browser first; if that fails too, it's a host-machine/emulator network or
VPN issue, or an old Android system image failing modern TLS handshakes.

## Project structure

```
lib/
├── core/
│   ├── network/                 # Dio client, token storage, base providers
│   ├── mock/mock_data.dart      # still used by map_search — not yet wired to the API
│   ├── routing/app_router.dart  # go_router config, auth-aware redirects
│   ├── theme/                   # colors, app theme
│   ├── utils/app_constants.dart # API base URL, storage keys
│   └── widgets/                 # side drawer, bottom-nav shell, splash screen
├── features/
│   ├── auth/                    # signup/login/forgot-password/verify-email + real repository
│   ├── listings/                 # feed, detail, post-listing (real API + Cloudinary uploads)
│   ├── map_search/               # OpenStreetMap radius search (mock data for now)
│   ├── favorites/                 # saved properties (local-only for now)
│   └── profile/                   # profile view/edit, email verification banner
└── main.dart                      # entry point, EasyLocalization + window sizing
```

## Localization

All user-facing strings live in `assets/translations/en.json` and
`ur.json`, kept in sync key-for-key. Add new UI text as a key in both
files and reference it with `'key_name'.tr()` — never hardcode strings
directly in a widget.

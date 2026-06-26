# Quicks — Flutter App

The Quicks mobile client: a dark, premium microlearning card feed and knowledge graph
("the Brain"). Cross-platform Flutter (Android + iOS, also runs on web/desktop), wired to
the deployed backend.

- **Backend:** `https://quicks-backend-api.onrender.com` (API docs at `/docs`)
- **Design:** dark theme — Playfair Display headings, Jost body, JetBrains Mono labels, with
  gold / teal / violet domain accents (from the wireframe).

---

## Architecture

Layered and feature-oriented, mirroring the backend's separation of concerns so it scales
cleanly:

```
lib/
├── core/
│   ├── config.dart          # API base URL, timeouts
│   └── theme.dart           # design tokens (colors, type) + ThemeData
├── models/                  # plain data classes with fromJson
│   ├── card.dart            # QuicksCard
│   ├── brain.dart           # BrainGraph, DomainNode, BridgeNode, BrainStats, BrainShare
│   └── profile.dart
├── services/
│   ├── auth_service.dart    # AuthService interface + MockAuthService (SSO-ready seam)
│   └── quicks_api.dart      # typed dio wrapper over the REST API
├── state/
│   └── providers.dart       # Riverpod: auth, userId, feed, brain, saved, profile, card, deepDive
├── widgets/
│   ├── glass_panel.dart     # frosted glass card treatment + DomainChip
│   ├── app_bottom_nav.dart  # 5-tab bar
│   └── brain_constellation.dart  # animated knowledge-graph CustomPainter
├── screens/
│   ├── splash_screen.dart       # 01 entry (wordmark + two paths)
│   ├── onboarding_screen.dart   # 02 paged intro
│   ├── signin_sheet.dart        # 03 Google / Apple / Email / Guest bottom sheet
│   ├── shell_screen.dart        # bottom-nav shell (IndexedStack)
│   ├── feed_screen.dart         # 04 vertical card feed + save/dwell engagement
│   ├── search_screen.dart       # 05 browse by domain
│   ├── brain_screen.dart        # 06 constellation
│   ├── card_detail_screen.dart  # 07 deep dive
│   └── profile_screen.dart      # 08 identity + saved grid
└── main.dart                # GoRouter wiring
```

**State:** `flutter_riverpod`. **Routing:** `go_router`. **Networking:** `dio`.
**Fonts:** `google_fonts` (no bundled files). **Images:** `cached_network_image`.
**Session:** `shared_preferences`.

### How auth is wired for SSO later

Authentication lives behind one interface, `AuthService`. The current build ships
`MockAuthService` (UI-only: it persists a local user id and exercises the whole app against
the dev backend). **Going live with real SSO is a one-file change** — implement `AuthService`
with `supabase_flutter`:

```dart
class SupabaseAuthService implements AuthService {
  Future<AuthUser> signInWithGoogle() => supabase.auth.signInWithOAuth(OAuthProvider.google) ...
  Future<AuthUser> signInWithApple()  => supabase.auth.signInWithOAuth(OAuthProvider.apple)  ...
  Future<AuthUser> signInWithEmail(e,p)=> supabase.auth.signInWithPassword(...) ...
}
```

then point `authServiceProvider` (in `state/providers.dart`) at it. The API layer already
centralises the user credential in `QuicksApi._q`, so switching from the dev `?user=` param to
an `Authorization: Bearer <jwt>` header is the only other change. No screens change.

> Real Google/Apple SSO also needs: Supabase Auth providers configured, the backend running in
> `BACKEND=supabase` mode (with migrations applied), and — for Apple — a paid Apple Developer
> account (iOS builds require macOS).

---

## Running it

The Flutter SDK is at `E:\flutter`. Add it to PATH so `flutter` works everywhere:

```powershell
# one-time, current session:
$env:Path = "E:\flutter\bin;" + $env:Path
# or permanently: System → Environment Variables → Path → add E:\flutter\bin
```

Then from this folder:

```bash
flutter pub get          # fetch packages
flutter run -d chrome    # run in the browser (works now)
```

`flutter devices` lists what you can target. This machine currently has **Chrome** and
**Edge** (web) ready.

### Android (needs Android Studio)

1. Install **Android Studio** → on first launch it installs the Android SDK + an emulator.
2. `flutter doctor --android-licenses` (accept them).
3. Start an emulator (or plug in a phone with USB debugging), then:
   ```bash
   flutter run            # picks the Android device
   flutter build apk      # release APK in build/app/outputs/flutter-apk/
   ```

### iOS (needs a Mac)

iOS apps can only be built on macOS with Xcode. On a Mac: `flutter build ios` /
`flutter run` with a simulator or device.

---

## Verify

```bash
flutter analyze     # static analysis (currently: 0 issues)
flutter test        # unit tests (model parsing)
flutter build web   # full compile to a deployable artifact
```

The app talks to the live backend out of the box — the feed, brain, saves, card detail, and
profile all load real data. (Render's free tier cold-starts after idle, so the first request
may take ~30s; the UI shows a "waking the feed…" state.)

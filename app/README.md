# MyDogs App

A Flutter app that fetches random dog photos with breed information from
[TheDogAPI](https://thedogapi.com), saves them locally, and displays them
offline in an in-app gallery.

## Features

- Fetch a random dog photo with breed information
- Display breed name, temperament, life span, breed group, origin, description,
  height, and weight
- Save photos and breed info to local storage for offline viewing
- Responsive grid gallery with pull-to-refresh
- Detail view for each saved dog with full-size local image
- Delete saved dogs with confirmation
- Dark mode and text-scaling support
- Accessible semantic labels on images and interactive elements

## Prerequisites

- Flutter SDK 3.44.x (Dart 3.12.x) — see `pubspec.yaml` for version constraint
- A TheDogAPI API key (obtain from https://thedogapi.com)
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

## Setup

### 1. Install dependencies

```bash
cd app
flutter pub get
```

### 2. Provide your API key

The API key is supplied at build/run time via `--dart-define` and is never
committed to source control.

**Option A — Command line:**

```bash
flutter run --dart-define=DOG_API_KEY=your-api-key-here
```

**Option B — Local defines file (recommended for development):**

Create `app/lib/config/local_defines.json` (git-ignored):

```json
{
  "DOG_API_KEY": "your-api-key-here"
}
```

> **Never commit your API key.** Secret-bearing files are listed in
> `.gitignore`.

### 3. Run the app

```bash
flutter run -d <device-id>
```

Use `flutter devices` to list available devices and emulators.

## Development

```bash
cd app
flutter analyze          # Static analysis
flutter test             # Run tests
dart format .            # Format code
```

## Architecture

The project follows a feature-first structure with clear boundaries between
UI, state, remote data, and local persistence:

```
lib/
  main.dart
  app/
    app.dart          # Root widget with MaterialApp.router
    router.dart       # Centralized go_router configuration
    theme.dart        # Material 3 light/dark themes
  core/
    config/           # AppConfig for API key injection
    error/            # AppException hierarchy + formatErrorMessage
    network/          # Dio API client and image Dio client
  features/
    dog_discovery/    # Fetch random dog with breed info
      data/
      domain/
      presentation/
    gallery/          # Local persistence and offline gallery
      data/
      domain/
      presentation/
```

- **State management:** Riverpod (`flutter_riverpod`)
- **Navigation:** `go_router`
- **HTTP:** `dio` (separate clients for API vs. image downloads)
- **Local storage:** `shared_preferences` (metadata) + `path_provider` (images)
- **Image loading:** `cached_network_image`

## API Integration

- **Base URL:** `https://api.thedogapi.com/v1`
- **Authentication:** `x-api-key` request header
- **Primary request:**
  `GET /images/search?limit=1&order=RANDOM&has_breeds=true&include_breeds=true`
- **Response:** Array of `ImageDto` objects with embedded `ProBreedDto` breed
  metadata

Image downloads use a separate Dio client that does **not** attach the API key,
preventing accidental leakage to third-party CDNs. Only HTTPS URLs are allowed.

## Platform Support

| Platform | Status |
|----------|--------|
| Android  | Supported |
| iOS     | Supported |

Minimum OS versions follow Flutter SDK defaults (`flutter.minSdkVersion` for
Android, iOS deployment target from Xcode project).

# MyDogs

A Flutter app that uses [TheDogAPI](https://thedogapi.com) to fetch random dog photos with breed information, save them locally, and view them offline in an in-app gallery.

## Features

- Fetch a random dog photo with breed information
- Save photos and breed info to local storage
- View saved dogs offline in an in-app gallery
- Delete saved dogs from the gallery

## Prerequisites

- Flutter SDK 3.44.x (Dart 3.12.x) — see `app/pubspec.yaml` for version constraint
- A TheDogAPI API key (obtain from https://thedogapi.com)
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

## Project Structure

```text
mydogs/
  README.md
  thedogapi.json              # TheDogAPI OpenAPI specification
  plan/
    implementation-plan.md   # Full implementation plan
  app/                       # Flutter project
    lib/
      main.dart
    android/
    ios/
    pubspec.yaml
```

## Setup

### 1. Install dependencies

```bash
cd app
flutter pub get
```

### 2. Provide your API key

The API key is supplied at build/run time via `--dart-define` and is never committed to source control.

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

> **Never commit your API key.** Secret-bearing files are listed in `.gitignore`.

### 3. Run the app

```bash
flutter run -d <device-id>
```

Use `flutter devices` to list available devices and emulators.

## API Integration

- **Base URL:** `https://api.thedogapi.com/v1`
- **Authentication:** `x-api-key` request header
- **Primary request:** `GET /images/search?limit=1&order=RANDOM&has_breeds=true&include_breeds=true`
- **Response:** Array of `ImageDto` objects with embedded `ProBreedDto` breed metadata

See `thedogapi.json` for the full OpenAPI specification and `plan/implementation-plan.md` for the complete implementation plan.

## Development

```bash
cd app
flutter analyze          # Static analysis
flutter test             # Run tests
dart format .            # Format code
```

## Platform Support

| Platform | Status |
|----------|--------|
| Android  | Supported |
| iOS     | Supported |

Minimum OS versions follow Flutter SDK defaults (`flutter.minSdkVersion` for Android, iOS deployment target from Xcode project).

## License

MPL-2.0

# Phase 0 — Toolchain and Product Contract Verification

## Verification Commands

### `flutter --version`

```
Flutter 3.44.9 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 6b182d2c75 (5 days ago) • 2026-08-05 10:04:07 -0700
Engine • hash b9499e4c25212536ba3a4eec4f5c1905fb3214fe (revision 5a2a6a42cc) (9 days ago) • 2026-07-31 18:31:59.000Z
Tools • Dart 3.12.2 • DevTools 2.57.0
```

### `flutter doctor -v`

```
[√] Flutter (Channel stable, 3.44.9, on Microsoft Windows [Version 10.0.22631.6199], locale sv-SE)
    • Flutter version 3.44.9 on channel stable at C:\Users\natha\flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision 6b182d2c75 (5 days ago), 2026-08-05 10:04:07 -0700
    • Engine revision 5a2a6a42cc
    • Dart version 3.12.2
    • DevTools version 2.57.0

[√] Windows Version (11 Home 64-bit, 23H2, 2009)

[√] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
    • Android SDK at C:\Users\natha\AppData\Local\Android\sdk
    • Platform android-37.0, build-tools 36.0.0
    • Java binary at: C:\Program Files\Android\Android Studio\jbr\bin\java
    • Java version OpenJDK Runtime Environment (build 25.0.2+-15348964-b329.117)
    • All Android licenses accepted.

[√] Chrome - develop for the web

[X] Visual Studio - develop Windows apps
    X Visual Studio not installed; this is necessary to develop Windows apps.
```

> **Note:** Visual Studio (for Windows desktop builds) is not installed. This
> does not affect iOS or Android development, which are the target platforms.

### `flutter devices`

> Skipped during verification — device scanning hangs when no devices are
> connected. Android and iOS platform support is confirmed via `flutter doctor`
> and the presence of `android/` and `ios/` directories.

### `flutter pub get`

```
Resolving dependencies...
Got dependencies!
```

### `flutter analyze`

```
No issues found! (ran in 40.2s)
```

### `flutter test`

```
00:07 +1: Counter increments smoke test
00:07 +1: All tests passed!
```

### `git status --short`

```
? app/
```

> The `app/` directory will be committed as part of Phase 0 completion.

## Project Identity

| Property | Value |
|----------|-------|
| Flutter project name | `mydogs` |
| Android application ID | `com.mydogs.app` |
| Android namespace | `com.mydogs.app` |
| iOS bundle identifier | (default from `flutter create`, to be customized in Phase 1) |
| Supported platforms | Android, iOS |
| Min Android SDK | `flutter.minSdkVersion` (Flutter default) |
| Min iOS version | iOS deployment target from Xcode project (Flutter default) |
| Dart SDK constraint | `^3.12.2` |

## API Contract Summary

| Property | Value |
|----------|-------|
| Base URL | `https://api.thedogapi.com/v1` |
| Authentication | `x-api-key` request header |
| Primary request | `GET /images/search?limit=1&order=RANDOM&has_breeds=true&include_breeds=true` |
| Response shape | Array of `ImageDto` with embedded `ProBreedDto` breed metadata |
| API key handling | `--dart-define=DOG_API_KEY=...` at run time; never committed |
| OpenAPI spec | `thedogapi.json` (committed) |

## Exit Criteria Checklist

- [x] `flutter --version` run and recorded
- [x] `flutter doctor -v` run and recorded
- [x] `flutter devices` attempted (skipped due to hang; platforms confirmed via doctor)
- [x] Project opens for both intended platforms (Android + iOS directories present)
- [x] No real API key present in the repository
- [x] `flutter pub get` succeeds
- [x] `flutter analyze` passes with no issues
- [x] `flutter test` passes
- [x] Acceptance scenarios written (`plan/acceptance-scenarios.md`)
- [x] README documents setup, API-key injection, and run commands
- [x] `.gitignore` covers secret-bearing files
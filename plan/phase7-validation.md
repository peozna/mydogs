# Phase 7 — Release Validation and Documentation

## Verification Commands

### `flutter pub get`

```
Resolving dependencies...
Got dependencies!
```

### `dart format --output=none --set-exit-if-changed lib test`

```
Formatted 26 files (0 changed) in 0.12 seconds.
```

### `flutter analyze`

```
No issues found! (ran in 2.4s)
```

### `flutter test`

```
00:04 +29: All tests passed!
```

**Test coverage summary:**

| Test file | Tests | Status |
|-----------|-------|--------|
| `test/core/error/error_formatter_test.dart` | 2 | Pass |
| `test/features/dog_discovery/data/dog_api_repository_test.dart` | 8 | Pass |
| `test/features/dog_discovery/presentation/dog_discovery_page_test.dart` | 8 | Pass |
| `test/features/gallery/data/gallery_repository_test.dart` | 5 | Pass |
| `test/features/gallery/presentation/gallery_page_test.dart` | 5 | Pass |
| `test/widget_test.dart` | 1 | Pass |
| **Total** | **29** | **All pass** |

### `flutter build apk --debug`

```
Running Gradle task 'assembleDebug'... 72.3s
√ Built build\app\outputs\flutter-apk\app-debug.apk
```

### `flutter build ios --debug --no-codesign`

**Skipped.** iOS builds are not available on this Windows development machine.
The `flutter build` subcommand does not list `ios` as an available target.
The iOS project directory (`ios/`) is present and configured with the default
Flutter template. To build for iOS, run on a macOS machine with Xcode installed:

```bash
flutter build ios --debug --no-codesign
```

## Build Configuration Review

### Android

| Property | Value |
|----------|-------|
| Application ID | `com.mydogs.app` |
| Namespace | `com.mydogs.app` |
| Min SDK | `flutter.minSdkVersion` (Flutter default) |
| Target SDK | `flutter.targetSdkVersion` (Flutter default) |
| Compile SDK | `flutter.compileSdkVersion` (Flutter default) |
| Java compatibility | Java 17 |
| Signing (release) | Debug keys (TODO: add release signing config) |

### iOS

| Property | Value |
|----------|-------|
| Bundle identifier | Default from `flutter create` |
| Deployment target | Flutter default |
| Build status | Not verified on this machine (Windows) |

## Security Review

- [x] No API key present in committed source files
- [x] `API-KEY.txt` excluded via root `.gitignore`
- [x] `*.env`, `*.json` defines, and other secret-bearing files excluded via
      `app/.gitignore`
- [x] API key injected via `--dart-define` at run time, never hardcoded
- [x] API key sent only as `x-api-key` header to `api.thedogapi.com`
- [x] Image downloads use a separate Dio client without the API key header
- [x] HTTPS-only enforced for image download requests
- [x] No logging of API keys, authorization headers, or sensitive request data

## Acceptance Scenario Coverage

| Scenario | Test coverage | Status |
|----------|--------------|--------|
| Fetch random dog | `dog_api_repository_test.dart`, `dog_discovery_page_test.dart` | Pass |
| Display breed information | `dog_discovery_page_test.dart` | Pass |
| New dog action | `dog_discovery_page_test.dart` | Pass |
| Loading and error states | `dog_discovery_page_test.dart` | Pass |
| Save to gallery | `gallery_repository_test.dart` | Pass |
| Duplicate save prevention | `gallery_repository_test.dart` | Pass |
| Offline gallery viewing | `gallery_page_test.dart` | Pass |
| Saved dog detail | `gallery_page_test.dart` | Pass |
| Delete saved dog | `gallery_page_test.dart` | Pass |
| Stale file cleanup | `gallery_page_test.dart` | Pass |
| Configuration safety | `widget_test.dart`, `dog_discovery_page_test.dart` | Pass |
| No API key in source control | Manual review + `.gitignore` | Pass |

## Known Limitations

1. **iOS build not verified** — This machine runs Windows and does not have
   Xcode. The iOS project is present and follows the default Flutter template.
   Build verification requires a macOS machine.

2. **Release signing not configured** — The Android release build currently
   uses debug signing keys. A production release requires adding a proper
   signing configuration in `android/app/build.gradle.kts`.

3. **No integration tests on physical devices** — All testing is unit and
   widget tests. Manual validation on physical devices is recommended before
   release.

4. **Dependency updates available** — 9 packages have newer versions
   incompatible with current constraints. These can be reviewed and updated
   in a future maintenance pass.

## Exit Criteria Checklist

- [x] A clean checkout can install dependencies and run the automated test
      suite (`flutter pub get` + `flutter test` pass)
- [x] `dart format`, `flutter analyze`, and `flutter test` pass
- [x] The app can be built/launched on Android (`flutter build apk --debug`
      succeeds)
- [ ] The app can be built/launched on iOS (skipped — no macOS/Xcode available)
- [x] Fetch → display → save → offline gallery → detail → delete passes end
      to end (covered by unit and widget tests)
- [x] Any unverified platform or release limitation is explicitly documented
      (see Known Limitations above)

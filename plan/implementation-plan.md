# MyDogs Flutter App — Implementation Plan

## 1. Goal

Build a cross-platform Flutter app for iOS and Android that uses TheDogAPI to:

1. Fetch a random dog photo.
2. Present the photo together with the related breed information.
3. Optionally save the photo and its breed information locally.
4. Provide an in-app gallery where saved dogs can be viewed offline and deleted.

The initial implementation will focus on the public image-search and breed data
capabilities described in `thedogapi.json`. API capabilities unrelated to this
experience—votes, favourites, pets, uploads, facts, health tips, and breed
legislation—are outside the first release.

## 2. Assumptions and Decisions

- Target platforms: iOS and Android.
- App type: maintainable MVP, designed so additional dog-related features can be
  added later.
- The app will use Material 3 and support light and dark themes.
- The API key is supplied at build/run time and is never committed to source
  control.
- Local gallery storage means app-private offline storage, not automatically
  exporting photos to the device's system Photos/Gallery application.
- The first version will use `shared_preferences` for a small JSON metadata index
  and `path_provider` for image files. A database can be introduced later if the
  gallery grows substantially.
- Riverpod will provide state management and dependency injection.
- `go_router` will provide centralized navigation.

## 3. API Integration

### Base URL and authentication

- Production base URL: `https://api.thedogapi.com/v1`
- Authentication: `x-api-key` request header.
- Configuration: read the key from `--dart-define=DOG_API_KEY=...` or a local,
  git-ignored defines file. No key belongs in Dart source, platform files, or
  committed configuration.

### Primary request

Use:

```text
GET /images/search?limit=1&order=RANDOM&has_breeds=true&include_breeds=true
```

The response is an array of `ImageDto` objects. The app will select the first
usable item and require a non-empty `url` and at least one breed. If the API
returns an image without breed metadata, the repository will treat it as an
unusable result and retry within a bounded policy or show a recoverable empty
state.

The response's embedded breed object should be sufficient for the first screen.
`GET /breeds/{id}` may be added as an optional follow-up when a complete breed
profile is needed or when the embedded response is incomplete.

### API models

Map the relevant portions of the OpenAPI schemas into null-safe Dart models:

- `ImageDto`: `id`, `url`, `width`, `height`, and `breeds`.
- `ProBreedDto`: `id`, `name`, `life_span`, `temperament`, `origin`,
  `description`, `breed_group`, height and weight fields, `bred_for`, and
  relevant friendliness/behavior scores.

Models should tolerate absent optional fields because the API schema only marks a
small number of fields as required. JSON parsing must not make nullable API data
non-null by using unchecked assertions.

## 4. Proposed Flutter Architecture

Use a feature-first structure with clear boundaries between UI, state, remote
data, and local persistence:

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  core/
    config/
      app_config.dart
    error/
      app_exception.dart
    network/
      api_client.dart
  features/
    dog_discovery/
      data/
        dog_api_repository.dart
        dog_dto.dart
      domain/
        dog_image.dart
        breed.dart
      presentation/
        dog_discovery_page.dart
        dog_discovery_controller.dart
    gallery/
      data/
        gallery_repository.dart
        local_gallery_storage.dart
      domain/
        saved_dog.dart
      presentation/
        gallery_page.dart
        saved_dog_detail_page.dart
        gallery_controller.dart
```

The exact number of files can remain small during the MVP, but widgets must not
make HTTP calls or know the storage format. Repositories will expose domain-level
operations to Riverpod controllers.

### Dependencies

Add only packages justified by the implementation and compatible with the
installed Flutter SDK:

- `flutter_riverpod` — asynchronous application state and dependency injection.
- `go_router` — named routes and gallery detail navigation.
- `dio` (or the existing project HTTP client if one is already selected) — API
  requests, status handling, and request configuration.
- `path_provider` — app-private documents directory for image files.
- `shared_preferences` — persisted metadata index for the small local gallery.
- `cached_network_image` — efficient remote image display and loading/error UI.

If dependency review shows that plain `http` or another existing client is more
appropriate, use the smallest compatible option while keeping network calls
behind the repository boundary.

## 5. Navigation and Screens

Use two primary routes and a detail route:

- `/` — Random Dog / discovery screen.
- `/gallery` — local gallery screen.
- `/gallery/:id` — saved dog detail screen.

Navigation can be presented as a bottom navigation bar or app-bar actions. Route
configuration should remain centralized in `lib/app/router.dart`.

### Random Dog screen

Behavior:

- Fetch a dog on initial load.
- Provide a `New dog` action and pull-to-refresh where practical.
- Display the photo prominently with an accessible semantic label.
- Display available breed information, including name and optional sections for
  temperament, life span, breed group, origin, description, height, and weight.
- Provide a `Save to gallery` action.
- Indicate when the current image is already saved.

States:

- Loading: progress indicator or skeleton while the request is in progress.
- Success: image and available breed data.
- Empty/unusable result: explanation and retry action.
- Error: user-friendly message, retry action, and no unhandled exception in the
  widget tree.

### Gallery screen

Behavior:

- Load the local metadata index at startup.
- Render saved items in a responsive grid or list with thumbnails.
- Read image files from local storage so saved items remain viewable offline.
- Show a clear empty state when no dogs have been saved.
- Allow deletion with confirmation and remove both metadata and image file.
- Handle missing/corrupt files gracefully by offering removal of the stale entry.

### Saved dog detail screen

- Show the locally stored full-size image.
- Show the breed information captured at save time, even without network access.
- Provide a delete action and return to the gallery after successful deletion.

## 6. Local Persistence Design

When the user saves a dog:

1. Download the image bytes from the API image URL.
2. Write the bytes to an app-private directory using a collision-resistant file
   name based on the API image ID.
3. Serialize the image ID, local file path, original URL, breed snapshot,
   dimensions, and saved timestamp into a `SavedDog` record.
4. Update the persisted metadata index atomically as far as the selected storage
   mechanism allows.
5. Update UI state only after both the file and metadata are successfully saved.

Deletion must remove the metadata entry and attempt to remove the corresponding
file. A missing file should not prevent metadata cleanup. The gallery should be
able to rebuild or discard stale records safely.

The initial version will not request Photos/Media Library permissions because it
stores files privately inside the app. If exporting to the system gallery becomes
a requirement, add a separate, platform-specific export feature with appropriate
permissions and privacy documentation.

## 7. Error Handling and Reliability

Define domain-friendly exceptions for:

- Missing API key/configuration.
- HTTP authentication, rate-limit, server, and connectivity failures.
- Invalid or incomplete API payloads.
- Image download failures.
- Local file and metadata persistence failures.

The UI should provide retry actions and preserve already loaded data when a later
refresh fails where appropriate. Network and file operations must run outside
`build` methods. Controllers must guard against disposed/unmounted UI contexts
when showing post-operation feedback.

## 8. Security and Configuration

- Read `DOG_API_KEY` through a centralized `AppConfig`.
- Document local setup with an example command, without including a real key.
- Add local defines files and other secret-bearing files to `.gitignore`.
- Do not log the API key, authorization headers, or full sensitive request data.
- Use HTTPS only for API and image requests.

Because a mobile API key can ultimately be extracted from a client binary, the
key should be scoped and rotated appropriately by the API account owner. If the
API provider supports a backend proxy with stronger protection, that can be
considered for a production release.

## 9. Testing Strategy

### Unit tests

- Parse representative `ImageDto` and `ProBreedDto` JSON, including missing
  optional fields.
- Verify the API repository constructs the expected request and maps responses.
- Verify no-breed/invalid-image filtering and bounded retry behavior.
- Verify local save, list, duplicate handling, and delete behavior.
- Verify metadata survives repository reinitialization.

### Widget tests

- Render loading, success, empty, and error states for the discovery screen.
- Verify the save action and already-saved state.
- Render an empty gallery and a populated gallery.
- Verify deletion confirmation and removal from the visible list.

### Integration/manual validation

- Run the app on at least one iOS or Android target.
- Fetch a dog with a real development API key.
- Save it, disable network access, restart the app, and verify the gallery/detail
  view remains available.
- Verify text scaling, dark mode, touch targets, image failures, and rotation or
  varying screen sizes where supported.

## 10. Verifiable Implementation Phases

Each phase is independently reviewable. A phase is complete only when its
deliverables and exit criteria are satisfied; later phases must not silently
compensate for an incomplete earlier phase.

### Phase 0 — Toolchain and product contract

**Purpose:** Confirm that implementation can start from a known Flutter
environment and that the API behavior used by the app is explicit.

**Deliverables:**

- Flutter project name, organization ID, supported platforms, and minimum OS
  versions recorded.
- API base URL, authentication mechanism, request parameters, response shapes,
  and API-key handling recorded in the project documentation.
- Initial feature acceptance scenarios written for fetch, display, save, offline
  gallery viewing, and delete.

**Exit criteria:**

- `flutter --version`, `flutter doctor -v`, and `flutter devices` have been run.
- The project can be created or opened successfully for both intended platforms.
- No real API key is present in the repository.

**Verification:**

```bash
flutter --version
flutter doctor -v
flutter devices
git status --short
```

### Phase 1 — Application foundation and configuration

**Purpose:** Establish a runnable, maintainable Flutter shell before feature work.

**Deliverables:**

- Flutter iOS/Android project with the agreed application identity.
- Material 3 light and dark themes.
- Centralized `AppConfig` using `DOG_API_KEY` from `--dart-define`.
- Riverpod dependency-injection setup and centralized `go_router` routes for `/`
  and `/gallery`.
- Initial feature-first directory structure and lint configuration.

**Exit criteria:**

- The app launches without an API key and shows a clear configuration state rather
  than crashing.
- Both primary routes are reachable and can navigate back correctly.
- Theme switching or system brightness produces readable light and dark UIs.
- Configuration files containing secrets are ignored by Git.

**Verification:**

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run -d <available-device>
```

### Phase 2 — Remote models, client, and repository

**Purpose:** Implement and isolate the TheDogAPI integration without coupling it
to widgets.

**Deliverables:**

- Null-safe `ImageDto`/domain image and breed models.
- API client that sends the `x-api-key` header and calls
  `/images/search?limit=1&order=RANDOM&has_breeds=true&include_breeds=true`.
- Repository mapping, validation, bounded retry/filtering, and typed error
  handling.
- Unit tests using mocked responses for success, invalid payloads, authentication
  failure, rate limiting, and connectivity failure.

**Exit criteria:**

- A fixture containing an `ImageDto` with a `ProBreedDto` maps to the domain model.
- Optional/missing breed fields do not cause parsing crashes.
- Images without a URL or breed are rejected or retried according to policy.
- Tests prove the API key is sent as a header and is not included in logs or URLs.
- Widgets have no direct HTTP-client dependency.

**Verification:**

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test test/features/dog_discovery/data
```

### Phase 3 — Random dog discovery experience

**Purpose:** Deliver the first complete user-visible vertical slice: fetch and
display a dog photo with related breed information.

**Deliverables:**

- Riverpod controller for initial load, refresh, retry, and request cancellation
  or stale-response protection where applicable.
- Discovery screen with photo, breed name, optional breed fields, and `New dog`
  action.
- Loading, success, empty/unusable, and recoverable error states.
- Widget tests for each state and for refresh behavior.

**Exit criteria:**

- With a valid development API key, a user can launch the app and see a dog photo
  and at least one breed name.
- Tapping `New dog` replaces the displayed result without restarting the app.
- A failed request leaves the user with a visible retry action.
- Long or missing breed fields do not break the layout.

**Verification:**

```bash
flutter test test/features/dog_discovery
flutter run -d <available-device> --dart-define=DOG_API_KEY=<development-key>
```

Manual check: launch, fetch, refresh, simulate offline mode, and confirm loading,
success, empty, and error states.

### Phase 4 — Local persistence and save workflow

**Purpose:** Make a displayed dog available offline with an atomic, recoverable
save operation.

**Deliverables:**

- `SavedDog` model containing the local image path, API image ID, URL, dimensions,
  breed snapshot, and saved timestamp.
- File storage service using `path_provider`.
- Metadata repository using `shared_preferences` (or the selected local store).
- Save action with progress, duplicate detection, success feedback, and cleanup
  if metadata persistence fails after a file write.
- Unit tests for save, duplicate save, restart/reload, and partial-failure cases.

**Exit criteria:**

- A save operation does not report success until both image bytes and metadata are
  available locally.
- Re-saving the same API image ID does not create duplicate gallery entries.
- A repository re-created in a new process/session can reload the saved record.
- A failed save does not leave an unusable metadata record or orphaned file where
  cleanup is possible.

**Verification:**

```bash
flutter test test/features/gallery/data
flutter analyze
```

Manual check: save a fetched dog, terminate and relaunch the app, then verify the
record remains available with network access disabled.

### Phase 5 — Offline gallery and saved-dog detail

**Purpose:** Expose persisted dogs as a complete in-app local gallery.

**Deliverables:**

- Gallery controller and `/gallery` screen with empty, loading, populated, and
  stale-file states.
- Responsive grid/list thumbnails loaded from local files.
- `/gallery/:id` detail screen showing the local image and saved breed snapshot.
- Delete confirmation, file cleanup, metadata cleanup, and navigation behavior.
- Widget tests for empty/populated gallery, detail navigation, stale records, and
  deletion.

**Exit criteria:**

- A saved dog appears in the gallery without another API request.
- The detail screen remains usable with network disabled.
- Deleting an item removes it from the UI and persistence layer.
- Missing local files are handled with a recoverable prompt or cleanup action,
  rather than an uncaught exception.
- Back navigation returns from detail to the gallery correctly.

**Verification:**

```bash
flutter test test/features/gallery
dart format --output=none --set-exit-if-changed .
flutter analyze
```

Manual check: save multiple dogs, browse each detail page offline, delete one,
restart, and confirm only the remaining records are shown.

### Phase 6 — UX, accessibility, reliability, and security hardening

**Purpose:** Make the vertical slice robust across normal device conditions and
  user interaction patterns.

**Deliverables:**

- Accessible labels, semantics, focus order, and minimum touch targets.
- Responsive layouts for small phones, large phones, and larger widths.
- Dark-theme and text-scaling review.
- Consistent error messages for HTTP status classes, timeout, malformed data,
  image download, and local storage failures.
- No API-key/header logging; HTTPS-only request validation; Git ignore review.
- Duplicate taps, concurrent refresh/save actions, and lifecycle edge cases handled.

**Exit criteria:**

- `flutter analyze` reports no warnings or errors.
- User-facing failures always provide a recovery path where one is possible.
- UI remains usable at increased text scale and does not overflow on supported
  device sizes.
- A code/configuration review finds no committed credentials or sensitive logs.

**Verification:**

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Manual check: test slow/offline network, API errors, failed image loads, dark mode,
large text, rotation, rapid button taps, and app restart during gallery use.

### Phase 7 — Release validation and documentation

**Purpose:** Confirm the app is reproducible and document the exact handoff state.

**Deliverables:**

- README setup instructions, including safe API-key injection and run commands.
- Final unit/widget/integration coverage for the agreed acceptance scenarios.
- iOS and Android build configuration review.
- A validation report noting tested devices, commands, and any unavailable
  toolchain components.

**Exit criteria:**

- A clean checkout can install dependencies and run the automated test suite.
- `dart format`, `flutter analyze`, and `flutter test` pass.
- The app can be built/launched on each available target platform.
- Fetch → display → save → offline gallery → detail → delete passes end to end.
- Any unverified platform or release limitation is explicitly documented.

**Verification:**

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

Run platform-specific build commands only when the corresponding SDK/toolchain is
available; record skipped commands and their reasons.

## 11. Definition of Done

The MVP is complete when:

- A user can fetch and view a dog photo with related breed information.
- Loading, empty, error, retry, and duplicate-save states are handled.
- A user can save a dog and later view its photo and breed snapshot offline in the
  in-app gallery.
- A user can delete saved items without leaving stale gallery entries.
- API credentials are externalized and not committed.
- Relevant unit/widget tests exist and pass.
- `dart format`, `flutter analyze`, and `flutter test` pass, with platform build
  limitations reported honestly if the local toolchain is incomplete.
# MyDogs — Phase 0 Acceptance Scenarios

These scenarios define the initial feature acceptance criteria for the MyDogs
MVP. Each scenario is written in a testable Given/When/Then format.

## 1. Fetch Random Dog

**Scenario:** User fetches a random dog photo

- **Given** the app is launched with a valid API key
- **When** the discovery screen loads
- **Then** a random dog photo is fetched from TheDogAPI
- **And** the photo is displayed with at least one breed name

## 2. Display Breed Information

**Scenario:** Breed information is shown with the photo

- **Given** a dog photo has been fetched successfully
- **When** the photo is displayed on the discovery screen
- **Then** the breed name is shown
- **And** optional fields (temperament, life span, breed group, origin,
  description, height, weight) are displayed when available
- **And** missing optional fields do not break the layout

## 3. New Dog Action

**Scenario:** User requests a new dog

- **Given** a dog photo is currently displayed
- **When** the user taps the "New dog" action
- **Then** a new random dog photo replaces the current one
- **And** the app does not restart

## 4. Loading and Error States

**Scenario:** Loading state is shown during fetch

- **Given** a fetch request is in progress
- **When** the user is waiting for the response
- **Then** a loading indicator is displayed

**Scenario:** Error state is shown on failure

- **Given** a fetch request fails (network error, API error, or invalid
  response)
- **When** the error is received
- **Then** a user-friendly error message is displayed
- **And** a retry action is available

**Scenario:** Empty/unusable result is handled

- **Given** the API returns an image without breed metadata or a valid URL
- **When** the response is processed
- **Then** an explanation and retry action are shown

## 5. Save to Gallery

**Scenario:** User saves a displayed dog

- **Given** a dog photo with breed info is displayed
- **When** the user taps "Save to gallery"
- **Then** the image bytes are downloaded and stored locally
- **And** the breed metadata is persisted
- **And** the save is not reported as successful until both file and metadata
  are saved

**Scenario:** Duplicate save is prevented

- **Given** a dog has already been saved
- **When** the user attempts to save the same dog again
- **Then** no duplicate gallery entry is created
- **And** the UI indicates the dog is already saved

## 6. Offline Gallery Viewing

**Scenario:** User views saved dogs offline

- **Given** one or more dogs have been saved
- **When** the user opens the gallery with no network connection
- **Then** saved dogs are displayed with thumbnails loaded from local storage
- **And** breed information captured at save time is visible

**Scenario:** Empty gallery state

- **Given** no dogs have been saved
- **When** the user opens the gallery
- **Then** a clear empty state is shown

## 7. Saved Dog Detail

**Scenario:** User views a saved dog's details

- **Given** a dog is saved in the gallery
- **When** the user taps on a gallery item
- **Then** the full-size local image is displayed
- **And** the saved breed information is shown
- **And** the detail screen works without network access

## 8. Delete Saved Dog

**Scenario:** User deletes a saved dog

- **Given** a dog is saved in the gallery
- **When** the user confirms deletion
- **Then** the metadata entry is removed
- **And** the corresponding local image file is removed
- **And** the item disappears from the gallery UI

**Scenario:** Stale file cleanup

- **Given** a saved dog's local image file is missing or corrupt
- **When** the gallery encounters the stale entry
- **Then** a recoverable prompt or cleanup action is offered
- **And** no uncaught exception occurs

## 9. Configuration Safety

**Scenario:** App launched without API key

- **Given** the app is launched without a `DOG_API_KEY`
- **When** the app starts
- **Then** a clear configuration state is shown
- **And** the app does not crash

**Scenario:** No API key in source control

- **Given** the repository is inspected
- **When** files are checked for credentials
- **Then** no real API key is present in any committed file
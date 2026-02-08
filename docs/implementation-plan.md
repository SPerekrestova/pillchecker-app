# PillChecker App — Implementation Plan

Step-by-step build guide for the Flutter iOS app. Each task is designed to be independently testable before moving on.

## Task 0: Environment Setup

**Goal:** Flutter SDK installed, Xcode configured, blank app runs on simulator.

```bash
# Install Flutter
brew install --cask flutter

# Verify installation
flutter doctor

# Accept Xcode license (if not already done)
sudo xcodebuild -license accept

# Open iOS simulator
open -a Simulator
```

Fix any issues reported by `flutter doctor` before proceeding.

### Create the Flutter project

```bash
cd ~/IdeaProjects/pillchecker-app
flutter create . --org com.pillchecker --platforms ios --project-name pillchecker_app
```

Note: We run `flutter create .` (with dot) inside the existing directory to preserve the `CLAUDE.md` and `docs/` files already present.

**Verify:** `flutter run` launches a default counter app on the iOS simulator.

---

## Task 1: Project Scaffold + Dependencies

**Goal:** Folder structure, dependencies, data models, and API client skeleton in place.

### 1a. Add dependencies

```bash
flutter pub add dio
flutter pub add flutter_riverpod
flutter pub add google_mlkit_text_recognition
flutter pub add image_picker
flutter pub add go_router
```

### 1b. Set up folder structure

```
lib/
├── models/
│   ├── drug_result.dart
│   ├── analyze_response.dart
│   ├── interaction_result.dart
│   └── interactions_response.dart
├── services/
│   ├── api_client.dart        # Dio client for PillChecker backend
│   └── rxnorm_client.dart     # Direct RxNorm autocomplete
├── providers/
│   └── providers.dart         # Riverpod providers
├── screens/
│   ├── drug_input_screen.dart # Main screen with two drug slots
│   ├── confirm_screen.dart    # Review identified drugs
│   └── results_screen.dart    # Interaction results
├── widgets/
│   └── drug_slot.dart         # Reusable drug input/scan widget
├── router.dart                # go_router configuration
└── main.dart                  # App entry point with ProviderScope
```

### 1c. Create data models

Models should mirror the backend schemas in `docs/openapi.json`. Key types:

**DrugResult** (from `POST /analyze` response):
- `rxcui`: `String?`
- `name`: `String`
- `dosage`: `String?`
- `form`: `String?`
- `source`: `String` ("ner" or "rxnorm_fallback")
- `confidence`: `double`

**AnalyzeResponse**:
- `drugs`: `List<DrugResult>`
- `rawText`: `String`

**InteractionResult** (from `POST /interactions` response):
- `drugA`: `String`
- `drugB`: `String`
- `severity`: `String`
- `description`: `String`
- `management`: `String`

**InteractionsResponse**:
- `interactions`: `List<InteractionResult>`
- `safe`: `bool`

### 1d. Create API client

`ApiClient` class wrapping Dio:
- Constructor takes `baseUrl` (default: `http://localhost:8000`)
- `Future<AnalyzeResponse> analyze(String text)` — POST to `/analyze`
- `Future<InteractionsResponse> checkInteractions(List<String> drugs)` — POST to `/interactions`
- Error handling: wrap DioExceptions, surface meaningful messages

### 1e. Create RxNorm client

`RxNormClient` class:
- `Future<List<String>> suggest(String query)` — calls `approximateTerm.json`, returns drug names
- Debounce is handled at the UI layer, not here

**Verify:** `flutter analyze` passes, `flutter test` runs (even if no tests yet).

---

## Task 2: Camera + OCR Screen

**Goal:** User can take a photo and see extracted text.

### Implementation
- Use `ImagePicker` to capture a photo from camera (or gallery for simulator testing)
- Run `TextRecognizer` (ML Kit) on the captured image
- Display the raw recognized text on screen

### Camera permission
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>PillChecker needs camera access to scan medication packaging</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PillChecker needs photo library access to select medication images</string>
```

**Verify:** Tap "Scan" → camera opens → take photo → text appears on screen.

---

## Task 3: Drug Input Screen (Main Screen)

**Goal:** Two medication slots that can be filled via scan or manual entry.

### Layout
- App bar: "PillChecker"
- Two `DrugSlot` widgets, each showing:
  - Drug name (once identified)
  - [Scan] button → camera → OCR → `POST /analyze` → show result
  - [Type] button → text field with RxNorm autocomplete
- [Check Interactions] button at bottom (enabled when both slots filled)

### Scan flow
1. User taps [Scan]
2. Camera opens → photo taken → OCR extracts text
3. Text sent to `POST /analyze`
4. If drugs found → navigate to Confirm screen
5. If no drugs found → show error with "Try again" option

### Type flow
1. User taps [Type]
2. Text field appears with autocomplete dropdown
3. As user types, debounced (300ms) calls to RxNorm `approximateTerm`
4. User selects a drug name from suggestions
5. Drug slot fills with selected name

**Verify:** Both scan and type flows work. Two drugs can be entered. "Check Interactions" button appears.

---

## Task 4: Confirmation Screen

**Goal:** User reviews and confirms identified drugs before checking interactions.

### Layout
- For each drug:
  - Scanned text (if from OCR)
  - Identified ingredient name
  - Dosage and form (if detected)
  - [Correct] button
  - [Edit] button → switches to manual entry with RxNorm autocomplete

### Navigation
- [Correct] on both → proceed to interaction check
- [Edit] → inline edit with autocomplete
- Back button → return to input screen

**Verify:** Drugs shown correctly, edit flow works, confirmation leads to results.

---

## Task 5: Interaction Results Screen

**Goal:** Show interaction check results with clear severity indicators.

### Implementation
1. Call `POST /interactions` with confirmed drug names
2. Display results:
   - **Safe** (green): "No known interactions found"
   - **Warning** (amber): Interaction with severity and description
   - **Danger** (red): Serious interaction with management advice
3. Each interaction card shows: drug pair, severity, description, management
4. [Start Over] button → navigate back to input screen

### Severity mapping
Map the `severity` string from the backend to colors:
- "Major" → red
- "Moderate" → amber/orange
- "Minor" → yellow
- No interactions (safe=true) → green

**Verify:** Full flow works end-to-end: scan two drugs → confirm → see interaction results.

---

## Task 6: Polish + Error Handling

**Goal:** Production-quality error states and UX polish.

### Error states
- **Network error:** "Can't reach server. Check your connection." + [Retry]
- **No drugs found:** "No medications detected. Try better lighting or enter manually."
- **API error:** "Something went wrong. Please try again." + [Retry]

### Loading states
- Spinner during OCR processing
- Spinner during API calls (`/analyze`, `/interactions`)
- Disabled buttons while loading

### Empty states
- Initial state: instruction text "Scan or type two medications to check interactions"
- No interactions: green checkmark + "No known interactions found"

### UX polish
- Haptic feedback on scan button
- Smooth transitions between screens
- Consistent spacing and typography
- App icon and launch screen (can be placeholder for MVP)

**Verify:** All error paths handled gracefully. No unhandled exceptions. App feels responsive.

---

## Architecture Notes

### State Management (Riverpod)
- `drugSlotsProvider` — holds the two drug slots state
- `analyzeProvider` — async provider for `/analyze` calls
- `interactionsProvider` — async provider for `/interactions` calls
- Use `AsyncValue` for loading/error/data states

### Navigation (go_router)
```
/              → DrugInputScreen (main)
/confirm       → ConfirmScreen
/results       → ResultsScreen
```

### Testing Strategy
- Unit tests: models (JSON parsing), API client (mock Dio), RxNorm client
- Widget tests: each screen with mocked providers
- Integration test: full flow with mocked backend

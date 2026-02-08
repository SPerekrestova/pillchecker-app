# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## What This Is

PillChecker App — a Flutter iOS application that lets users scan medication packaging with their camera, identify drugs via OCR, and check drug-drug interactions. This is the mobile frontend for the [PillChecker API](https://github.com/SPerekrestova/pillchecker-api) backend.

## Backend API

The canonical API contract is in `docs/openapi.json` (generated from FastAPI Pydantic schemas). Key endpoints:

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/analyze` | Send OCR text, get identified drugs with RxCUI, dosage, form |
| `POST` | `/interactions` | Send drug name list, get interaction results with severity |
| `GET` | `/health` | Health check (includes NER model status) |
| `GET` | `/health/data` | Data health check (interaction DB status) |

### Backend URLs
- **Local dev:** `http://localhost:8000` (run `docker compose up` in the backend repo)
- **Production:** TBD (Hetzner deployment planned)

### RxNorm Autocomplete (direct, not proxied)
For drug name autocomplete in manual entry, call the NLM RxNorm API directly from the app:
```
GET https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term={query}&maxEntries=5
```
This is a free, no-auth API. Debounce requests by 300ms to stay within the 20 req/sec limit.

## Development Workflow Rules

**IMPORTANT: Follow these rules strictly for all development work:**

1. **No commits without approval** — Never commit changes to git without explicit user approval
2. **Branch-based workflow** — Always create a new branch from `main` and make all changes through pull requests (PRs)
3. **No pushing without approval** — Never push commits to remote repositories without explicit user approval

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter (iOS only for MVP) | Cross-platform, fast iteration |
| State management | Riverpod | Testable, modern, right-sized for 4-5 screens |
| HTTP client | Dio | Interceptors, error handling, industry standard |
| OCR | google_mlkit_text_recognition | On-device, fast, actively maintained |
| Navigation | go_router | Declarative routing, official recommendation |
| Image capture | image_picker | Simpler than raw camera plugin, sufficient for MVP |
| Architecture | Layer-first folders | Simple for small app, easy to navigate |

## Commands

```bash
# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/some_test.dart

# Analyze code (lint)
flutter analyze

# Build iOS release
flutter build ios
```

## Project Structure

```
lib/
├── models/          # Data classes matching backend schemas (see docs/openapi.json)
├── services/        # API client (Dio), RxNorm client
├── providers/       # Riverpod providers
├── screens/         # UI screens (scan, confirm, results)
├── widgets/         # Reusable components
└── main.dart
```

## Key Constraints

- **iOS only for MVP** — Android support deferred. Only `--platforms ios` in project creation.
- **Backend must be running** — `/analyze` and `/interactions` require the backend. Use `docker compose up` in the backend repo.
- **NER model is backend-side** — The app does NOT run ML models. It sends raw OCR text to the backend, which runs the NER pipeline.
- **OCR is on-device** — ML Kit text recognition runs on the phone, no network call for OCR itself.
- **RxNorm autocomplete is direct** — Called from the app to NLM servers, not proxied through our backend.

## iOS Setup Notes

- Requires Xcode (install from App Store)
- Run `sudo xcodebuild -license accept` after installing
- Minimum deployment target: iOS 15.0
- Camera permission required — add `NSCameraUsageDescription` to `Info.plist`
- ML Kit requires: add `GoogleMLKit/TextRecognition` pod dependency (handled by the Flutter plugin)

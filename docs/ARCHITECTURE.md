# MaybeLater — Architecture

## Stack

Use the latest compatible stable Flutter/Dart environment available in the project.

Primary dependencies:

- Flutter
- Dart
- Riverpod
- go_router
- sqflite
- SQLite FTS5
- google_mlkit_text_recognition
- google_mlkit_image_labeling
- path_provider
- flutter_image_compress
- flutter_local_notifications for progress reporting only (no background execution logic)
- workmanager (for background processing, evaluate in Phase 10)

Do not blindly use old package versions. Inspect installed versions and APIs.

## Layers

### Presentation

Widgets and screens.

Responsibilities:

- render state
- receive user input
- trigger actions through providers
- display errors/loading states

Widgets must not contain raw SQL or heavy business logic.

### State

Riverpod providers.

Responsibilities:

- UI/application state
- search state
- import state
- collection state
- detail state

### Domain

Models and business rules.

### Repositories

Repositories coordinate data access.

Examples:

- ScreenshotRepository
- SearchRepository
- CollectionRepository
- ImportRepository

### Services

Services perform focused operations.

Examples:

- OcrService
- ImageLabelService
- ThumbnailService
- StorageService
- ImageHashService
- ImportService

### Database

SQLite DAOs, migrations, schema, FTS5.

## Recommended Structure

lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── database/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   ├── jobs/
│   ├── theme/
│   └── utils/
├── features/
│   ├── home/
│   ├── gallery/
│   ├── search/
│   ├── detail/
│   ├── import/
│   ├── collections/
│   ├── cleaner/
│   └── settings/
└── shared/

Do not create every possible file in advance. Create files when functionality requires them.

## State Rules

Avoid global mutable state.

Use Riverpod providers with clear ownership.

Do not make a single global provider responsible for the entire app.

## Navigation

Use go_router.

Suggested routes:

/
 /gallery
 /search
 /import
 /collections
 /collections/:id
 /screenshot/:id
 /cleaner
 /trash
 /settings

## Processing

Large work must not block the UI.

Use bounded background processing.

Do not create thousands of simultaneous Futures.

Default processing concurrency should be conservative, usually 1–2 workers, then tuned using real-device testing.

## Data Flow

Import:

Android MediaStore / Photo Picker
→ persistent import job
→ copy/validate
→ hash
→ thumbnail
→ OCR
→ labels
→ database
→ FTS
→ completed

Search:

query
→ normalize
→ FTS5
→ rank
→ fetch metadata
→ render top results

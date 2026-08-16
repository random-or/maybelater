# MaybeLater — Testing Strategy

## Required Checks

After implementation:

```bash
dart format .
flutter analyze
flutter test
```

Also run the app on a real Android device whenever possible.

## Unit Tests

Test:

- query normalization
- FTS query safety
- ranking
- tag normalization
- duplicate detection
- hashing
- processing state transitions
- migrations
- collection behavior
- trash behavior

## Database Tests

Test:

- fresh database
- every migration
- insert
- update
- delete
- FTS synchronization
- FTS rebuild
- indexes
- foreign-key behavior

## Import Tests

Test:

- one screenshot
- batch import
- duplicate file
- invalid file
- OCR failure
- labeling failure
- database failure
- cancellation
- retry
- recovery after stale job

## Crash Recovery

Simulate interruption during:

- copy
- hashing
- thumbnail
- OCR
- labeling
- database persistence

Restart and verify recovery.

## Dataset Testing

Use development-only generated database metadata for:

- 100
- 1,000
- 5,000
- 10,000

records.

Do not pretend generated metadata is real OCR.

## Search Benchmarks

Measure actual:

- query latency
- first result latency
- database size
- memory use where practical

Do not hardcode performance claims.

## Performance Benchmarks

Measure actual metrics on datasets of 10, 100, 500, and 2,000 screenshots:

- average processing time per screenshot
- total processing time
- peak memory use where practical
- failed jobs and retry count
- UI responsiveness
- device thermal/battery behavior where practical

Do not define an arbitrary promise such as "2,000 screenshots will finish in X minutes".
Use real-device measurements to establish realistic expectations.
The app must remain usable while processing.

## UI Testing

Test:

- empty states
- loading states
- errors
- long text
- large datasets
- multi-select
- cleaner gestures
- navigation

## Device Scenarios

On a real Android device test:

- fresh install
- import 10
- import 100
- import 2,000
- duplicate imports
- corrupted image
- permission denial
- partial media access where applicable
- low storage
- app backgrounded
- app killed
- app restarted
- airplane mode
- restore from trash

## Offline Acceptance Test

To ensure the core offline OCR promise:
1. Fresh installation
2. Enable Airplane mode
3. Import screenshots
4. OCR must succeed without network access

## Definition of Test Completion

Do not report "tested" merely because the code compiled.

Report exactly which tests ran and which scenarios were verified.

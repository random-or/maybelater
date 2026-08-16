# MaybeLater — Import Pipeline

## Goal

Import thousands of screenshots without freezing the UI, exhausting memory, duplicating files, or losing progress after interruption.

## Pipeline

MediaStore Discovery / Manual Photo Picker
→ create persistent jobs
→ validate
→ index
→ hash
→ thumbnail
→ OCR
→ image labels
→ database
→ FTS
→ completed

## Permissions

- Android 13+: Use Photo Picker for manual selection. If bulk discovering, handle READ_MEDIA_IMAGES gracefully.
- Android 14+: Correctly handle partial media access (selected-photo access). The app must only index media Android has actually granted access to.
- Android 12 and below: Use legacy external storage permissions where required.
- Do not request broad permissions when Photo Picker is sufficient.
- Handle permission denied, partial access, revoked, and changes gracefully.

## Queue

Never create one active Future per screenshot.

For 2,000 files, persist 2,000 jobs but execute only a small bounded number.

Default:

1–2 workers.

Tune only after real-device measurements.

## Job State

Each job must have an explicit state.

A failed job does not stop unrelated jobs.

Store an error message.

Support retry.

## Indexing MediaStore

Do NOT copy original images into app-managed storage.

The Android MediaStore (or original asset URI) is the canonical source of truth for the image.

MaybeLater simply indexes these existing images to save storage space.

Validate the original file before expensive processing.

## Deletion Flow

Because MaybeLater is an indexer that aims to reduce storage, deletion MUST be transactional with the OS.
1. User presses Delete.
2. App requests MediaStore deletion of the original.
3. Android OS confirms with the user (Android 10+).
4. If OS deletion succeeds, the app deletes the local thumbnail and updates the database.
5. If OS deletion fails or is cancelled, the app makes NO changes.

## Hash

Compute a content hash such as SHA-256.

If the exact same content was already imported:

- do not create another screenshot record
- do not duplicate the stored file

Do not implement perceptual hashing in MVP unless needed later.

## Thumbnail

Generate a separate thumbnail.

Target maximum dimension around 300px.

Never use full-resolution originals in the gallery.

Do not regenerate existing valid thumbnails.

## OCR

Use on-device ML Kit.
Verify that the selected ML Kit configuration does not require an active network connection to download the model dynamically, or fallback appropriately.

OCR failure must not crash the whole import.

An image with no recognized text is still a valid screenshot.

Never fabricate text.

## Image Labels

Image labels are supplementary.

They are generic visual labels, not semantic screenshot understanding.

Low-confidence labels should not dominate search ranking.

## Persistence

After every meaningful stage, persist state sufficiently for recovery.

If the app dies during OCR, the job should be recoverable.

## Crash Scenario

Test:

1. Start importing 2,000.
2. Kill app around the middle.
3. Restart.
4. Recover stale jobs.
5. Continue.
6. Do not duplicate completed screenshots.

## Cancellation

Canceling the queue must not remove already completed screenshots.

Pending jobs can remain resumable or be explicitly discarded.

## Background

Background work must respect Android restrictions.

Do not promise unlimited background execution.

Use Android WorkManager through the Flutter `workmanager` package where appropriate for persistent background tasks (to be evaluated in Phase 10).
Do not use `flutter_local_notifications` for execution.

For long-running user-visible work that requires foreground execution, use the appropriate Android foreground execution strategy.

## Notifications

Useful states:

- processing
- progress
- completed
- failed

Do not spam.

## Low Storage

Before large copies where practical, estimate space requirements.

If storage becomes insufficient:

- stop safely
- preserve completed work
- report the problem
- allow retry after space is freed

Never corrupt the library.

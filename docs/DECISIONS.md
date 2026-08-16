# MaybeLater — Architecture Decisions

Record important architectural decisions here.

Do not rewrite accepted decisions casually.

---

## ADR-001 — Offline-first

Status: ACCEPTED

Core functionality must work without internet access.

---

## ADR-002 — SQLite + FTS5

Status: ACCEPTED

SQLite is the canonical local database.

FTS5 is the primary search index.

The normal screenshot table remains the source of truth.

---

## ADR-003 — ML Kit OCR

Status: ACCEPTED

OCR runs locally using ML Kit.

No cloud OCR.

---

## ADR-004 — Image Labels Are Supplementary

Status: ACCEPTED

ML Kit image labels are generic visual metadata.

They are not treated as semantic screenshot understanding.

OCR remains the primary semantic search source.

---

## ADR-005 — Persistent Import Queue

Status: ACCEPTED

Large imports must survive app navigation and recover from interruption.

---

## ADR-006 — Bounded Processing

Status: ACCEPTED

Do not process thousands of screenshots concurrently.

Use a bounded worker queue.

Initial default should be conservative and tuned with real-device testing.

---

## ADR-007 — Trash Before Permanent Delete

Status: ACCEPTED

User deletion moves screenshots to recoverable trash unless the user explicitly chooses permanent deletion.

---

## ADR-008 — No Fake Functionality

Status: ACCEPTED

The application must never fabricate OCR, search results, progress, labels, or successful processing.

---

## ADR-009 — Dual Screenshot Acquisition

Status: ACCEPTED

Decision: The app will support both bulk screenshot discovery via Android MediaStore and manual selection via the system Photo Picker.
Reason: Relying solely on arbitrary filesystem scanning is brittle, and forcing users to manually select thousands of screenshots is bad UX. Both are needed.
Consequences: The import architecture must cleanly abstract the source of the files and handle varying permission scenarios.

---

## ADR-010 — Android Version-Specific Media Access

Status: ACCEPTED

Decision: The application will implement Android-version-specific permission handling.
Reason: Android 13+ introduced granular media permissions and the Photo Picker. Android 14+ introduced partial media access. A single legacy permission model does not work across modern devices.
Consequences: The app must gracefully handle permission denial, partial access, revoked permissions, and out-of-band permission changes.

---

## ADR-011 — Offline OCR and Model Verification

Status: ACCEPTED

Decision: The core OCR workflow using Google ML Kit must be fully offline.
Reason: Fulfilling the privacy-first, offline promise requires no network connectivity for core features.
Consequences: We must verify that the selected ML Kit configuration does not secretly download models dynamically during use, or we must provide explicit fallbacks. An airplane-mode acceptance test is required.

---

## ADR-012 — Local Backup / Export

Status: ACCEPTED

Decision: The app will eventually support local backup/export to a portable format.
Reason: Users need to own their data and move it across devices without relying on a cloud service.
Consequences: The backup system will be designed around SQLite and local image files (not FTS5 indexes). This is a Phase 13 roadmap item.

---

## ADR-013 — Background Execution (WorkManager)

Status: ACCEPTED

Decision: Android WorkManager (via `workmanager`) will be used for persistent background processing, while `flutter_local_notifications` will only be used for progress reporting.
Reason: Android strictly limits background execution. WorkManager is the correct system for long-running batch jobs.
Consequences: Implementation of WorkManager is deferred to Phase 10 to properly evaluate the actual OCR workload requirements.

---

## ADR-014 — Real-Device Benchmarks

Status: ACCEPTED

Decision: Performance expectations will be established through real-device measurements on datasets of 10, 100, 500, and 2,000 screenshots.
Reason: Arbitrary promises (e.g., "2,000 screenshots in X minutes") are unrealistic. We must measure average processing time, total time, peak memory, and UI responsiveness.
Consequences: Testing requires generating datasets and running them on a physical Android device to record baseline metrics.

---

## ADR-015 — Development and Build Workflow

Status: ACCEPTED

Decision: The development workflow uses the laptop for coding and lightweight static verification, GitHub Actions for cloud Android APK builds, and a physical Android phone for testing.
Reason: Local Gradle builds are prohibitively slow or unstable on the laptop environment.
Consequences: No Android emulator or Android Studio will be used on the laptop.

---

## ADR-016 — Import Job Storage via Screenshots Table

Status: ACCEPTED

Decision: Import jobs are tracked using the existing `screenshots` table rather than a separate `import_jobs` table. A screenshot record is created at discovery time with `processing_status = 'pending'` and progresses through states as the import pipeline processes it.
Reason: The `screenshots` table already has `processing_status`, `processing_error`, `original_uri`, `content_hash`, `thumbnail_path`, `filepath`, `file_size`, `width`, and `height` columns — all fields needed for import tracking. A separate table would duplicate this schema and require synchronization.
Consequences: The `processing_status` column serves dual purpose as import-job state. Workers query for records by status. Stale `importing` records on app restart indicate interrupted jobs and are reset to `pending` for retry.

---

## ADR-017 — Media Acquisition via photo_manager

Status: ACCEPTED

Decision: Use the `photo_manager` package (^3.12.0) for both bulk MediaStore discovery and manual photo selection. Do not use `image_picker` as the primary import mechanism.
Reason: ADR-009 requires bulk screenshot discovery via Android MediaStore. `photo_manager` provides direct MediaStore access with paginated asset queries, built-in permission handling (`PhotoManager.requestPermissionExtend()`), and support for Android 13+ granular permissions and Android 14+ partial access. `image_picker` only supports manual selection and cannot query MediaStore.
Consequences: `photo_manager` handles permission requests internally. Android permissions (`READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE`) are declared in the manifest but requested through photo_manager's API. The `AssetEntity` abstraction provides metadata (dimensions, size, creation date) and file access.

---

## ADR-018 — Processing State Machine

Status: ACCEPTED

Decision: The `processing_status` column uses five states derived from the import pipeline stages defined in IMPORT_PIPELINE.md:

| State | Meaning |
|-------|---------|
| `pending` | Discovered, queued for import. Not yet picked up by a worker. |
| `importing` | Worker is actively processing (copy → validate → hash → thumbnail). |
| `imported` | All Phase 2 steps complete. File copied, validated, hashed, thumbnailed. Ready for OCR in Phase 3. |
| `failed` | Processing error. `processing_error` column contains details. Retryable. |
| `duplicate` | Content hash matches an existing imported screenshot. Source file not stored. |

Reason: This is the smallest state machine that correctly supports the documented pipeline (copy → validate → hash → thumbnail), crash recovery (stale `importing` → `pending`), duplicate handling, failure/retry, and a clean Phase 3 handoff point (`imported` status).
Consequences: On app startup, any records in `importing` state are reset to `pending` (stale job recovery). OCR in Phase 3 will process `imported` records and transition them to a new terminal state.

---

# Future Decisions

Add new ADRs here when architecture changes materially.

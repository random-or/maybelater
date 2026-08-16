# MaybeLater — Product Specification

## Product

MaybeLater is an offline screenshot memory application.

It turns a large pile of screenshots into a searchable personal knowledge library.

Core promise:

> Take a screenshot. Find it instantly. Forever.

## Problem

Users accumulate hundreds or thousands of screenshots containing things they wanted to remember:

- errors
- code
- conversations
- receipts
- business ideas
- tutorials
- documents
- payment confirmations
- random useful information

The screenshots become impossible to find later.

## Core Workflow

Import screenshots
→ store them locally
→ generate thumbnails
→ OCR locally
→ optionally generate generic image labels
→ index searchable metadata
→ search
→ open the correct screenshot

## Privacy

Core functionality must work without:

- account
- login
- internet
- backend
- cloud database
- cloud OCR
- remote AI
- analytics
- telemetry
- advertising SDKs

Screenshot contents must not be uploaded by MaybeLater.

The core OCR workflow must be fully offline. Using an "on-device" ML Kit configuration that dynamically downloads models is not sufficient without explicit offline verification. 

Do not claim a stronger privacy guarantee than the implementation actually provides.

## Primary Features

### Gallery

- thumbnail grid
- lazy loading
- sorting
- multi-select
- favorites
- deletion

### Search

Search:

- OCR text
- manual tags
- generic image labels

Use SQLite FTS5.

Support human-friendly queries without requiring FTS syntax.

### Detail

- full screenshot viewer
- zoom
- OCR text
- copy OCR
- tags
- collection
- favorite
- share
- delete

### Import

- bulk screenshot discovery via Android MediaStore
- manual selection via system Photo Picker
- handle Android 13/14+ partial and full media permissions gracefully
- large batch imports
- persistent queue
- resumable processing
- progress
- failure reporting
- retry

### Collections

Optional organization for screenshots.

Deleting a collection must not delete its screenshots.

### Tags

Manual tags with autocomplete.

### Cleaner

Swipe left to trash.
Swipe right to keep.

Trash must be recoverable.

## Secondary Features

- local backup/export to a portable format
- image labels
- search history
- notifications
- settings
- storage verification
- search-index rebuild

## Not MVP

Do not add:

- social feed
- accounts
- cloud sync
- chatbot
- community
- server backend
- ads
- analytics
- subscription/payment infrastructure

unless explicitly requested.

## Product Quality

The app should feel:

- fast
- quiet
- deliberate
- professional
- reliable
- privacy-first

Visual polish matters, but correctness and search reliability come first.

## Definition of Done

On a real Android device:

1. Install.
2. Import 2,000 real screenshots.
3. App remains usable while processing.
4. Processing survives normal interruption/restart.
5. OCR is stored locally.
6. FTS5 indexes the data.
7. Search for a remembered term.
8. Correct screenshot appears quickly.
9. Open it.
10. Read/copy OCR.
11. Tag it.
12. Add it to a collection.
13. Favorite it.
14. Delete it.
15. Restore it.

No fake data or fake processing is acceptable.

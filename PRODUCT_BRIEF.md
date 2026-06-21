# Local Stitch Product Brief

## Overview

Local Stitch is a native macOS app for privately merging user-selected PDF files into one consolidated PDF. It is designed around a local-first workflow: users choose PDF files from their Mac, arrange them in the desired order, optionally unlock protected PDFs, optionally add AI-oriented manifest pages, and export a merged document to a location they choose.

The product is especially useful when a user needs to prepare many separate PDFs for review, archiving, or upload into AI tools that prefer or require a single file. All file inspection, password handling, hashing, metadata extraction, and PDF merging happen locally on the Mac.

## Core Value Proposition

Local Stitch helps users turn scattered PDFs into a single organized PDF while preserving privacy and source traceability. The app avoids cloud processing, uses only user-selected files, and can add provenance pages that make the merged output easier to understand, audit, and ingest into AI or retrieval workflows.

## Target Users

- Individuals preparing many personal documents for AI-assisted review, such as statements, bills, receipts, records, or forms.
- Professionals who need to consolidate PDFs while keeping sensitive material local.
- Researchers, analysts, operators, and knowledge workers who want a single AI-ready document with source boundaries and metadata.
- Users who want a simple Mac-native tool rather than a web upload workflow.

## Key Features

### 1. Local PDF Selection

Users can add PDFs through either drag and drop or the native macOS file picker.

- Drag PDF files into the main drop zone.
- Click "Browse Files" to open a native file picker.
- Click "Add More Files" after files have already been loaded.
- The picker accepts PDF files only.
- Directories are not selectable.

Local Stitch only works with files explicitly selected or dropped by the user.

### 2. 100-File Batch Limit

The app enforces a maximum of 100 loaded PDFs.

- The empty state shows the current loaded count out of 100.
- The active file list shows the count as files are added.
- When more files are supplied than remaining slots, the app only inspects files up to the remaining capacity.

This limit keeps the workflow bounded and helps protect app responsiveness during large merge jobs.

### 3. PDF Inspection

When files are added, Local Stitch inspects each PDF before it enters the merge list.

The inspection step detects:

- Whether the file has a `.pdf` extension.
- Whether PDFKit can parse the document.
- Whether the document is password-protected.
- The page count for unlocked PDFs.

Invalid, unsupported, or corrupted files trigger a user-facing alert.

### 4. Password-Protected PDF Support

Local Stitch can include password-protected PDFs once the user unlocks them.

When locked PDFs are detected:

- They appear in the file list with a "Locked" badge.
- The footer shows how many files remain protected.
- A secure password field appears.
- The user can enter one password and apply it to all remaining locked files.

If the password works, matching PDFs are unlocked and their page counts become available. If some files remain locked, the app reports how many are still protected. Merging is disabled until all locked files have been unlocked.

### 5. File Ordering

The merge order is controlled by the visible file list.

- Files appear in the order they were added.
- Users can reorder files in the list.
- The merged PDF follows the current list order.
- Users can remove individual files before merging.

This makes the app suitable for workflows where document order matters, such as chronological statements or sectioned evidence bundles.

### 6. Estimated Output Size

The footer shows an estimated final page count before export.

The estimate includes:

- The page count of all loaded source PDFs.
- Optional manifest page overhead when manifest insertion is enabled.

When manifest pages are enabled, the app adds one compilation summary page plus one manifest page for each source PDF.

### 7. Optional AI-Optimized Manifest Pages

Users can enable "Insert AI-Optimized Document Manifest Pages" before merging.

When enabled, Local Stitch inserts:

- A compilation manifest at the beginning of the output.
- One source document manifest before each source PDF.

The compilation manifest summarizes:

- Creation time.
- Local Stitch app version.
- Number of source PDFs.
- Original page count.
- Output page count.
- Manifest page count.
- A document index with source order, page ranges, short SHA-256 fingerprints, and filenames.

Each source document manifest records:

- Filename.
- Source order.
- Output page range.
- Original page count.
- File size.
- File creation and modification dates.
- SHA-256 hash of the original selected file.
- PDF metadata such as title, author, subject, keywords, creator, producer, creation date, and modification date.
- Whether the source file was encrypted.
- Whether it was unlocked for merge.
- Whether annotations were detected.
- Whether form widgets were detected.
- Whether bookmarks were detected.
- Page size and rotation profile.
- A machine-readable JSON-style context block.

This feature is designed to make the merged PDF more understandable to AI tools, retrieval systems, and human reviewers by preserving source identity and document boundaries inside the output itself.

### 8. SHA-256 Source Fingerprinting

When manifest pages are enabled, Local Stitch computes a SHA-256 hash for each original source PDF.

Implementation details:

- Hashing is performed from the original file bytes.
- Files are read in chunks rather than all at once.
- The hash is included in the source document manifest.
- A shortened hash appears in the compilation manifest index.

This provides a verification fingerprint for each original source document.

### 9. Local Merge Processing

The merge process runs off the main UI thread.

During merge:

- The app switches into a processing state.
- It shows the current file number.
- It shows a progress bar.
- It displays status text for the current operation.
- It inserts pages into a new PDF document in the chosen order.
- It writes the final document to the user-selected destination.

The app uses `autoreleasepool` while processing each document to reduce memory pressure during larger jobs.

### 10. Export Destination Picker

When the user clicks "Merge," Local Stitch opens a native macOS save panel.

- The default output name is `Merged_Document.pdf`.
- The user chooses the final filename and destination.
- The app writes the merged PDF only to the chosen path.
- If writing fails, the app displays a permission-related alert.

### 11. Success State and Finder Reveal

After a successful merge, Local Stitch shows a completion screen.

The success state includes:

- A confirmation message.
- The exported filename.
- The estimated page count.
- A "Show in Finder" button.
- A "Start New Merge" button.

"Show in Finder" opens the output folder and selects the merged file.

### 12. Start New Merge

After completion, users can reset the app and begin another merge.

Starting a new merge clears:

- Loaded files.
- Manifest setting.
- Password input.
- Current view state.

## How To Use Local Stitch

### Basic Merge

1. Open Local Stitch.
2. Drag PDFs into the drop zone, or click "Browse Files."
3. Review the loaded file list.
4. Reorder files if needed.
5. Remove any files that should not be included.
6. Confirm the estimated final page count.
7. Click "Merge."
8. Choose a filename and destination.
9. Wait for processing to complete.
10. Click "Show in Finder" to locate the merged PDF.

### Merge Password-Protected PDFs

1. Add PDFs as usual.
2. If locked PDFs are detected, enter the shared password in the secure password field.
3. Click "Apply to All" or press Return.
4. Repeat with other passwords if any files remain locked.
5. Once all files are unlocked, click "Merge."

Merging remains disabled while any loaded file is still locked.

### Create an AI-Ready Merged PDF

1. Add and order the source PDFs.
2. Unlock any protected files.
3. Enable "Insert AI-Optimized Document Manifest Pages."
4. Review the updated estimated page count.
5. Click "Merge."
6. Save the output PDF.

The exported PDF will include a compilation summary and per-document context pages before the original source pages.

## Product Boundaries

Local Stitch currently focuses on PDF consolidation, local privacy, and AI/RAG-friendly source context.

The current implementation does not include:

- Cloud upload or cloud processing.
- OCR.
- PDF compression.
- Page-level editing.
- Splitting PDFs.
- Selecting individual pages from a source PDF.
- Persistent merge history.
- Automatic folder watching.
- Network calls.

## Technical Foundation

Local Stitch is implemented as a native macOS SwiftUI app.

Key frameworks and technologies:

- SwiftUI for the application interface.
- AppKit panels for native file selection and save workflows.
- PDFKit for PDF parsing, unlocking, page inspection, and merge output.
- CryptoKit for SHA-256 hashing.
- OSLog for structured app logging.
- macOS App Sandbox with user-selected file read/write access.

The app uses a single main window with fixed content sizing and a hidden title bar. Its interaction model follows standard macOS conventions: drag and drop, native open/save panels, list reordering, secure password entry, progress feedback, alerts, and Finder reveal.

## Privacy and Local-First Behavior

Local Stitch is built around local-first privacy.

- Files are selected by the user.
- Processing happens on the Mac.
- There are no outgoing network connections in the app configuration.
- There are no incoming network connections in the app configuration.
- The app does not introduce cloud processing.
- Hashing and manifest creation use local file reads.
- The final PDF is written only to the user-selected destination.

## Current Product Positioning

Local Stitch is best described as:

> A private Mac utility for turning many PDFs into one AI-ready, source-aware PDF.

Its strongest differentiator is the combination of local PDF merging, password-protected document handling, and optional provenance manifests designed for AI ingestion.

## Distribution, Support, and Legal

Local Stitch is distributed by Mangla & Co LLC.

- Developer/Seller: Mangla & Co LLC.
- Privacy policy: https://moeed.com/privacy/
- Support page: https://moeed.com/project/mangla/
- Support email: developer@moeed.com
- Source license: MIT License.
- App category: Utilities.
- Minimum supported macOS for version 1.0: macOS 14.0 Sonoma.

Mac App Store distribution should use Apple's standard app installation and uninstall model. Local Stitch does not need a custom installer or uninstaller for App Store distribution.

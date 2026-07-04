# Local Stitch Product Brief

## Overview

Local Stitch is a free, native macOS app for privately merging user-selected PDF files and reducing PDF file size. It is designed around a local-first workflow: users choose PDFs from their Mac, unlock protected files when needed, arrange files, optionally add AI-friendly source summary pages, optionally reduce file size, and save the output only where they choose.

The product is especially useful when a user needs to prepare sensitive PDFs for review, sharing, legal context, archiving, or AI-assisted analysis without uploading documents to an online PDF service.

## Core Value Proposition

Local Stitch helps users turn scattered or oversized PDFs into organized, usable local outputs while preserving privacy. The app avoids cloud processing, uses only user-selected files, supports password-protected PDFs after local unlock, and can add source context pages that make merged output easier to understand, audit, and ingest into AI tools.

Current positioning:

> Free, private PDF stitching and file size reduction for your Mac.

## Target Users

- Individuals preparing personal documents for review, such as bank statements, bills, receipts, legal records, exported emails, or forms.
- People going through document-heavy situations such as divorce, custody disputes, financial review, insurance claims, immigration paperwork, or civil disputes.
- Small businesses consolidating statements, invoices, receipts, contracts, and customer records.
- AI users who need to prepare PDFs before uploading them into an AI tool for search, summarization, timeline building, or issue spotting.
- Privacy-conscious Mac users who want a simple native utility instead of an online PDF tool.

## Key Features

### 1. Local PDF Selection

Users can add PDFs through drag and drop or the native macOS file picker.

- Drag PDF files into the main drop zone.
- Click `Choose PDFs` to open the native file picker.
- Click `Add PDFs` after files have already been loaded.
- The picker accepts PDF files only.
- Directories are not selectable.

Local Stitch only works with files explicitly selected or dropped by the user.

### 2. 100-File Limit

The app enforces a maximum of 100 loaded PDFs.

- The empty and active states communicate the 100-PDF limit.
- The active file list shows how many PDFs are loaded.
- When more files are supplied than remaining slots, the app only inspects files up to the remaining capacity and reports the skipped count.

This limit keeps workflows bounded and helps protect responsiveness during large merge jobs.

### 3. PDF Inspection

When files are added, Local Stitch inspects each PDF before it enters the task list.

The inspection step detects:

- Whether the file has a `.pdf` extension.
- Whether PDFKit can parse the document.
- Whether the document is password-protected.
- The page count for unlocked PDFs.
- The source file size.

Invalid, unsupported, corrupted, or over-limit files are reported through a user-facing summary.

### 4. Password-Protected PDF Support

Local Stitch can process password-protected PDFs once the user unlocks them locally.

When locked PDFs are detected:

- They appear in the file list with a `Locked` badge.
- The footer shows how many protected PDFs need a password.
- A secure password field appears.
- The user can enter one password and apply it to all remaining locked files.

If the password works, matching PDFs are unlocked and their page counts become available. If some files remain locked, the app reports how many are still protected. Merge and compression actions stay disabled until all loaded files are unlocked.

Merged and compressed output copies are saved without preserving the original PDF password, matching the app's current output behavior.

### 5. File Ordering

The merge order is controlled by the visible file list.

- Files appear in the order they were added.
- Users can reorder files in the list.
- Users can remove individual files before processing.
- The merged PDF follows the current list order.

This is useful for chronological statements, email exports, case records, and sectioned evidence bundles.

### 6. Single-PDF File Size Reduction

Local Stitch supports file size reduction as a first-class single-file workflow.

With one PDF selected:

- The app shows filename, page count, and original file size.
- The primary action becomes `Reduce File Size`.
- Users can choose a compression level:
  - `Balanced`
  - `Smallest PDF`
- The app creates a temporary local reduced-size candidate.
- The app measures the actual candidate size.
- The app shows original size, estimated new size, and estimated savings.
- The user can save the compressed copy through a native macOS save panel.

If the reduced copy is not meaningfully smaller, the app says the PDF may already be optimized. If the reduced copy is larger, the app avoids presenting that as a successful reduction and lets the user keep the original or save a rewritten copy anyway.

### 7. Merge And Compress

With multiple PDFs selected, Local Stitch keeps the merge workflow primary and offers file size reduction as an output option.

Users can:

- Add and order multiple PDFs.
- Unlock protected PDFs.
- Optionally add source summary pages.
- Turn on `Reduce file size after merge`.
- Choose `Balanced` or `Smallest PDF`.
- Save one final merged and reduced-size PDF.

When enabled, Local Stitch merges first, then compresses the merged output locally. The success state shows the merged size, final size, and reduction result when available.

### 8. PDFKit-Based Compression

The MVP compression feature uses PDFKit only.

Implementation behavior:

- `Balanced` uses PDFKit image rewrite behavior where available.
- `Smallest PDF` uses PDFKit image rewrite plus screen-oriented image optimization.
- The app measures real temporary output instead of guessing a percentage.
- Some PDFs are already optimized, mostly text, vector-heavy, or structured in ways that do not shrink much.
- Advanced image recompression, OCR, and third-party PDF optimization are intentionally out of scope.

The feature should be described as `Reduce File Size`, not as guaranteed Smallpdf-grade compression.

### 9. Optional AI-Friendly Source Summary Pages

Users can enable `Add source summary pages for AI review` before merging.

When enabled, Local Stitch inserts:

- One compilation overview page at the beginning of the output.
- One source summary page before each source PDF.

The compilation overview summarizes:

- Creation time.
- Local Stitch app version.
- Number of source PDFs.
- Original page count.
- Output page count.
- Summary page count.
- A document index with source order, page ranges, short SHA-256 fingerprints, and filenames.

Each source summary page records:

- Filename.
- Source order.
- Output page range.
- Original page count.
- File size.
- File creation and modification dates.
- SHA-256 hash of the original selected file.
- PDF metadata such as title, author, subject, keywords, creator, producer, creation date, and modification date.
- Whether the source file was encrypted.
- Whether it was unlocked for processing.
- Whether annotations were detected.
- Whether form widgets were detected.
- Whether bookmarks were detected.
- Page size and rotation profile.
- A machine-readable JSON-style context block.

This feature helps humans and AI tools understand source identity and document boundaries inside a merged document.

### 10. SHA-256 Source Fingerprinting

When source summary pages are enabled, Local Stitch computes a SHA-256 hash for each original source PDF.

Implementation details:

- Hashing is performed from the original user-selected file bytes.
- Files are read in chunks rather than all at once.
- The hash is included in each source summary page.
- A shortened hash appears in the compilation overview.

The fingerprint identifies the original selected file, not a later compressed output.

### 11. Local Processing And Progress

Merge, compression, inspection, hashing, and file writes run off the main UI thread.

During processing, the app shows:

- Operation-specific status text.
- A progress indicator.
- Current file count during merge.
- Cancellation support where possible.
- Clear success or error feedback.

Temporary files are used for measured compression estimates and merge-and-compress staging, then cleaned up by the app.

### 12. Export Destination Picker

Local Stitch uses native macOS save panels.

- Merge output defaults to `Locally_Stitched_Document.pdf`.
- Compressed single-file output defaults to a `_compressed.pdf` filename.
- The user chooses the final filename and destination.
- The app writes output PDFs only to the chosen destination.
- If writing fails, the app displays a clear error.

### 13. Success State And Finder Reveal

After successful processing, Local Stitch shows operation-specific completion feedback.

Success states can include:

- `Compressed PDF saved`
- `Merged PDF saved`
- `Merged and compressed PDF saved`
- Exported filename.
- Page count where relevant.
- Original size, final size, and savings when compression ran.
- `Show in Finder`.
- `Start New Task`.

`Show in Finder` opens the output folder and selects the generated file.

## How To Use Local Stitch

### Reduce The Size Of One PDF

1. Open Local Stitch.
2. Drag one PDF into the window, or click `Choose PDFs`.
3. Choose `Balanced` or `Smallest PDF`.
4. Click `Reduce File Size`.
5. Review the measured local estimate.
6. Save the compressed copy, save a rewritten copy anyway, or keep the original.

### Basic Merge

1. Open Local Stitch.
2. Drag PDFs into the drop zone, or click `Choose PDFs`.
3. Review the loaded file list.
4. Reorder files if needed.
5. Remove any files that should not be included.
6. Unlock protected PDFs if prompted.
7. Choose whether to add source summary pages.
8. Click `Merge PDFs`.
9. Choose a filename and destination.
10. Wait for processing to complete.
11. Click `Show in Finder` to locate the merged PDF.

### Merge And Reduce File Size

1. Add two or more PDFs.
2. Arrange files in the desired order.
3. Unlock protected PDFs if prompted.
4. Optionally enable source summary pages.
5. Enable `Reduce file size after merge`.
6. Choose `Balanced` or `Smallest PDF`.
7. Click `Merge & Compress`.
8. Choose a filename and destination.

### Create An AI-Ready Merged PDF

1. Add and order the source PDFs.
2. Unlock any protected files.
3. Enable `Add source summary pages for AI review`.
4. Optionally enable `Reduce file size after merge`.
5. Review the estimated page count.
6. Click `Merge PDFs` or `Merge & Compress`.
7. Save the output PDF.

The exported PDF will include a compilation overview and per-document source summary pages before the original source pages.

## Product Boundaries

Local Stitch currently focuses on PDF consolidation, local file size reduction, local privacy, and AI-friendly source context.

The current implementation does not include:

- Cloud upload or cloud processing.
- OCR.
- Advanced image recompression beyond PDFKit options.
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
- PDFKit for PDF parsing, unlocking, page inspection, merging, writing, and PDFKit-based file size reduction.
- CryptoKit for SHA-256 hashing.
- OSLog for structured app logging.
- macOS App Sandbox with user-selected file read/write access.
- Hardened Runtime for signed and notarized distribution.

The app uses a single main window with a hidden title bar. Its interaction model follows standard macOS conventions: drag and drop, native open/save panels, list reordering, secure password entry, progress feedback, alerts, and Finder reveal.

## Privacy And Local-First Behavior

Local Stitch is built around local-first privacy.

- Files are selected by the user.
- Processing happens on the Mac.
- There are no outgoing network connections in the app configuration.
- There are no incoming network connections in the app configuration.
- The app does not introduce cloud processing.
- Hashing, summary-page creation, merging, and file size reduction use local file reads and writes.
- Temporary compression candidates stay local.
- Output PDFs are written only to the user-selected destination.

## Distribution, Support, And Legal

Local Stitch is distributed by Mangla & Co LLC.

- Developer/Seller: Mangla & Co LLC.
- Privacy policy: https://moeed.com/privacy/
- Support page: https://moeed.com/project/mangla/
- Support email: developer@moeed.com
- GitHub release: https://github.com/moeed80/Local-Stitch/releases/tag/v1.0.0
- Direct DMG: https://github.com/moeed80/Local-Stitch/releases/download/v1.0.0/Local-Stitch-1.0.dmg
- Source license: MIT License.
- App category: Utilities.
- Minimum supported macOS for version 1.0: macOS 14.0 Sonoma.

Mac App Store distribution should use Apple's standard app installation and uninstall model. Direct DMG distribution should use a signed, notarized, stapled disk image.

# Local Stitch Wireframes

These wireframes are for review before implementing PDF file size reduction. They are intentionally static and text-based so the product flow can be discussed before changing Swift code.

## Design Direction

Local Stitch should keep one calm, native macOS workflow instead of adding a heavy mode switch. Users add PDFs first, then the app adapts the available output action:

- One PDF: reduce file size.
- Multiple PDFs: merge PDFs.
- Multiple PDFs with compression enabled: merge and reduce file size.

Compression should be described honestly as PDFKit-based file size reduction, not as a promise of Smallpdf-level advanced compression.

## Shared App Shell

All primary screens keep the same shell.

```text
+----------------------------------------------------------------------------+
| [App Icon] Local Stitch                                      Version 1.0     |
|            Private PDF merging for your Mac. No uploads.                    |
+----------------------------------------------------------------------------+
|  1 Add PDFs  >  2 Arrange / Options  >  3 Save              [Up to 100 PDFs] |
+----------------------------------------------------------------------------+
|                                                                            |
|                              Main content                                  |
|                                                                            |
+----------------------------------------------------------------------------+
|                              Footer controls                               |
+----------------------------------------------------------------------------+
```

Notes:

- Step 2 should become "Arrange / Options" or "Choose Output" if compression becomes first-class.
- The shell should not introduce tabs or a landing page.
- The app should remain a single-window utility.

## Screen 1: Empty State

Purpose: let the user start either a merge or compression workflow by adding PDFs.

```text
+----------------------------------------------------------------------------+
| Local Stitch                                                    Version 1.0  |
+----------------------------------------------------------------------------+
|  1 Add PDFs  >  2 Arrange / Options  >  3 Save              [Up to 100 PDFs] |
+----------------------------------------------------------------------------+
|                                                                            |
|   . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          |
|   .                                                                      . |
|   .                         [doc.badge.plus]                              . |
|   .                                                                      . |
|   .                         Drop PDFs here                                . |
|   .                   or choose files from your Mac                       . |
|   .                                                                      . |
|   .                         [Choose PDFs]                                 . |
|   .                                                                      . |
|   . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .          |
|                                                                            |
|        Your PDFs are read locally and saved only where you choose.          |
|                                                                            |
+----------------------------------------------------------------------------+
| Estimated output: 0 pages                                      [Disabled]   |
+----------------------------------------------------------------------------+
```

Behavior:

- Drag-and-drop accepts user-selected PDF file URLs.
- "Choose PDFs" opens the native PDF file picker.
- No compression controls are visible yet because there is no file context.

## Screen 2: Single PDF Added

Purpose: support compression as a first-class single-file utility.

```text
+----------------------------------------------------------------------------+
|  1 Add PDFs  >  2 Arrange / Options  >  3 Save                              |
+----------------------------------------------------------------------------+
|  1 of 100 PDFs added                                      [+ Add PDFs]       |
+----------------------------------------------------------------------------+
|                                                                            |
|  #   Filename                                      Details         Remove    |
|  1   bank_statement_january.pdf                    12 pages        [x]       |
|      18.4 MB                                                               |
|                                                                            |
+----------------------------------------------------------------------------+
| Output Options                                                              |
| [x] Reduce file size                                                        |
|     Level:  [ Balanced v ]                                                  |
|     Estimate: click Reduce File Size to create a measured local estimate.   |
|                                                                            |
| Estimated output: 12 pages, 18.4 MB                         [Reduce File Size] |
+----------------------------------------------------------------------------+
```

Behavior:

- File row now includes file size.
- With one file, "Reduce file size" defaults on or is visually promoted.
- Primary action is "Reduce File Size."
- The app should not call this "Merge" when there is one file.

Open product question:

- Default compression on for one file, or let the user explicitly check it?
- Recommendation: default it on for one PDF, because the single-file path implies compression intent once this feature exists.

## Screen 3: Single Locked PDF Added

Purpose: preserve the existing unlock-first rule before compression.

```text
+----------------------------------------------------------------------------+
|  1 of 100 PDFs added                                      [+ Add PDFs]       |
+----------------------------------------------------------------------------+
|                                                                            |
|  #   Filename                                      Details         Remove    |
|  1   statement_locked.pdf                          [Locked]        [x]       |
|      2.1 MB                                                                |
|                                                                            |
+----------------------------------------------------------------------------+
| [lock] 1 protected PDF needs a password.                                    |
|        [Enter Password                         ] [Apply to All]             |
|                                                                            |
| Output Options                                                              |
| [x] Reduce file size                                      disabled until unlocked |
|                                                                            |
| Estimated output: locked PDF must be unlocked first             [Disabled]  |
+----------------------------------------------------------------------------+
```

Behavior:

- Compression is disabled while any file remains locked.
- After successful unlock, the row changes to pages + file size.
- If compressed output will not preserve the original password, the UI should say so clearly.

Suggested copy after unlock if needed:

```text
Compressed copies are saved without the original PDF password.
```

## Screen 4: Single PDF Estimate In Progress

Purpose: avoid fake predictions by generating a temporary local candidate and measuring actual size.

```text
+----------------------------------------------------------------------------+
|                                                                            |
|                         Estimating reduced file size...                     |
|                                                                            |
|                         [===========-------]                                |
|                                                                            |
|                Creating a temporary local copy. No files are uploaded.      |
|                                                                            |
+----------------------------------------------------------------------------+
| Original: 18.4 MB                                      [Cancel]             |
+----------------------------------------------------------------------------+
```

Behavior:

- Runs off the main thread.
- Writes only to a scoped temp directory.
- Cancel returns to the single-file options screen.
- Temp candidate is cleaned up on cancel/reset.

## Screen 5: Single PDF Estimate Ready

Purpose: show real measured savings before asking the user to save.

```text
+----------------------------------------------------------------------------+
|  1 of 100 PDFs added                                      [+ Add PDFs]       |
+----------------------------------------------------------------------------+
|                                                                            |
|  #   Filename                                      Details         Remove    |
|  1   bank_statement_january.pdf                    12 pages        [x]       |
|      18.4 MB                                                               |
|                                                                            |
+----------------------------------------------------------------------------+
| Output Options                                                              |
| [x] Reduce file size                                                        |
|     Level:  [ Balanced v ]                                                  |
|                                                                            |
|     Original size        18.4 MB                                            |
|     Estimated new size   12.1 MB                                            |
|     Estimated savings    6.3 MB (34%)                                      |
|                                                                            |
| Estimated output: 12 pages, about 12.1 MB              [Save Compressed Copy] |
+----------------------------------------------------------------------------+
```

Behavior:

- The estimate is the size of an actual temporary PDFKit output file.
- Changing compression level invalidates the estimate and generates a new one.
- Save panel appears after "Save Compressed Copy."

## Screen 6: Single PDF Already Optimized

Purpose: handle PDFKit no-op or size increase cases honestly.

```text
+----------------------------------------------------------------------------+
| Output Options                                                              |
| [x] Reduce file size                                                        |
|     Level:  [ Smallest PDF v ]                                              |
|                                                                            |
|     Original size        2.4 MB                                             |
|     Estimated new size   2.4 MB                                             |
|     Estimated savings    Less than 3%                                      |
|                                                                            |
|     This PDF may already be optimized. You can still save a rewritten copy. |
|                                                                            |
| Estimated output: little or no reduction                  [Save Copy Anyway] |
+----------------------------------------------------------------------------+
```

Behavior:

- Threshold recommendation: under 3% savings is "little or no reduction."
- If the compressed candidate is larger, show the larger size and recommend keeping the original.
- Primary button can become "Save Copy Anyway" or "Keep Original."

Recommendation:

- Prefer not to save a larger file by default.
- Make "Keep Original" the more prominent action when output is larger.

## Screen 7: Multiple PDFs Added

Purpose: preserve the current merge workflow.

```text
+----------------------------------------------------------------------------+
|  4 of 100 PDFs added                                      [+ Add PDFs]       |
+----------------------------------------------------------------------------+
|                                                                            |
|  #   Filename                                      Details         Remove    |
|  1   bank_statement_january.pdf                    12 pages        [x]       |
|      18.4 MB                                                               |
|  2   bank_statement_february.pdf                   11 pages        [x]       |
|      17.8 MB                                                               |
|  3   email_export_part_1.pdf                       80 pages        [x]       |
|      9.2 MB                                                                |
|  4   receipts.pdf                                  26 pages        [x]       |
|      31.5 MB                                                               |
|                                                                            |
+----------------------------------------------------------------------------+
| Output Options                                                              |
| [ ] Add source summary pages for AI review                                  |
|     Adds overview and per-document summary pages.                           |
|                                                                            |
| [ ] Reduce file size after merge                                            |
|                                                                            |
| Estimated output: 129 pages, about 76.9 MB                  [Merge PDFs]    |
+----------------------------------------------------------------------------+
```

Behavior:

- Multiple PDFs default to merge.
- File size sum is shown as a rough input-size reference, not a promised final output size.
- Compression is optional and off by default for multi-file merge.

## Screen 8: Multiple PDFs With AI Summary Pages

Purpose: keep current manifest behavior visible and compatible with compression.

```text
+----------------------------------------------------------------------------+
| Output Options                                                              |
| [x] Add source summary pages for AI review                                  |
|     Adds 1 overview page and 1 summary page before each PDF.                |
|                                                                            |
| [ ] Reduce file size after merge                                            |
|                                                                            |
| Estimated output: 134 pages including 5 summary pages       [Merge PDFs]    |
+----------------------------------------------------------------------------+
```

Behavior:

- Summary pages remain plain PDF pages.
- If compression runs after merge, it compresses the final output including summary pages.
- The app should not hash compressed output as if it were the source file; source SHA-256 still refers to original selected files.

## Screen 9: Merge And Compress Options

Purpose: let users reduce the final merged output size without making compression the whole workflow.

```text
+----------------------------------------------------------------------------+
| Output Options                                                              |
| [x] Add source summary pages for AI review                                  |
|                                                                            |
| [x] Reduce file size after merge                                            |
|     Level: [ Balanced v ]                                                   |
|     Size estimate will be measured after the merged PDF is created locally. |
|                                                                            |
| Estimated output: 134 pages including 5 summary pages   [Merge & Compress] |
+----------------------------------------------------------------------------+
```

Behavior:

- Button label changes to "Merge & Compress."
- The app should avoid promising final compressed size before creating the merged file.
- Processing should show two phases: merging, then reducing file size.

## Screen 10: Merge Processing

Purpose: current merge progress, with clearer operation label.

```text
+----------------------------------------------------------------------------+
|                                                                            |
|                              Merging PDFs...                                |
|                              File 2 of 4                                    |
|                                                                            |
|                              [======--------]                               |
|                                                                            |
|                 Stitching and structural alignment for                      |
|                 'bank_statement_february.pdf'...                            |
|                                                                            |
+----------------------------------------------------------------------------+
|                                                        [Cancel]             |
+----------------------------------------------------------------------------+
```

Behavior:

- Current cancellation behavior remains.
- If compression is enabled, this is phase 1.

## Screen 11: Compressing After Merge

Purpose: second processing phase after successful merge.

```text
+----------------------------------------------------------------------------+
|                                                                            |
|                         Reducing file size...                               |
|                                                                            |
|                         [==============----]                                |
|                                                                            |
|             Creating an optimized local copy of the merged PDF.             |
|                                                                            |
+----------------------------------------------------------------------------+
| Original merged size: 76.9 MB                           [Cancel]            |
+----------------------------------------------------------------------------+
```

Behavior:

- Runs after merge output exists in a temporary location.
- Final user-selected destination should receive the final compressed file.
- If cancelled after the temp merge but before final save, temp files are removed.

## Screen 12: Merge Success

Purpose: current success state when compression was not used.

```text
+----------------------------------------------------------------------------+
|                                                                            |
|                               [checkmark]                                   |
|                                                                            |
|                            Merged PDF saved                                 |
|                                                                            |
|         Saved 'Locally_Stitched_Document.pdf' with 134 pages.              |
|                            No files were uploaded.                          |
|                                                                            |
|                              [Show in Finder]                               |
|                                                                            |
+----------------------------------------------------------------------------+
| Operation Finished                                      [Start New Merge]   |
+----------------------------------------------------------------------------+
```

Behavior:

- Existing success screen remains valid.
- If file size is available, add a concise size line.

## Screen 13: Compress-Only Success

Purpose: show outcome for one-file file size reduction.

```text
+----------------------------------------------------------------------------+
|                                                                            |
|                               [checkmark]                                   |
|                                                                            |
|                         Compressed PDF saved                                |
|                                                                            |
|              Saved 'bank_statement_january_compressed.pdf'.                 |
|                                                                            |
|              Original: 18.4 MB   New: 12.1 MB   Saved: 34%                 |
|                            No files were uploaded.                          |
|                                                                            |
|                              [Show in Finder]                               |
|                                                                            |
+----------------------------------------------------------------------------+
| Operation Finished                                      [Start New Task]    |
+----------------------------------------------------------------------------+
```

Behavior:

- Button should say "Start New Task" rather than "Start New Merge" once compression is first-class.
- Success title should match the operation: compressed, merged, or merged and compressed.

## Screen 14: Merge And Compress Success

Purpose: show both merge and compression results.

```text
+----------------------------------------------------------------------------+
|                                                                            |
|                               [checkmark]                                   |
|                                                                            |
|                       Merged and compressed PDF saved                       |
|                                                                            |
|           Saved 'Locally_Stitched_Document.pdf' with 134 pages.            |
|                                                                            |
|              Merged size: 76.9 MB   Final: 44.2 MB   Saved: 43%            |
|                            No files were uploaded.                          |
|                                                                            |
|                              [Show in Finder]                               |
|                                                                            |
+----------------------------------------------------------------------------+
| Operation Finished                                      [Start New Task]    |
+----------------------------------------------------------------------------+
```

Behavior:

- If compression saves less than threshold, show "Little or no reduction" instead of a triumphant savings line.
- The final saved URL should point to the final output, not the temp merged file.

## Screen 15: Import Summary Alert

Purpose: current skipped/limit feedback should continue working.

```text
+----------------------------------------------+
| Local Stitch                                  |
+----------------------------------------------+
| Added 4 PDFs.                                 |
|                                              |
| Skipped 1 item:                               |
| 'notes.txt' is not a PDF file.                |
|                                              |
| Left out 3 items because Local Stitch can     |
| process up to 100 PDFs at a time.             |
|                                              |
|                                      [OK]     |
+----------------------------------------------+
```

Behavior:

- Keep alert text operation-neutral where possible.
- "Process up to 100 PDFs" may be better than "merge up to 100 PDFs" once compression exists.

## Screen 16: Compression Warning Alert

Purpose: warn about potentially lossy or behavior-changing output.

```text
+----------------------------------------------+
| Local Stitch                                  |
+----------------------------------------------+
| This PDF contains forms or annotations.        |
|                                              |
| Reducing file size may rewrite the PDF and     |
| could change interactive fields. Review the    |
| saved copy before sharing it.                  |
|                                              |
|                     [Cancel] [Continue]       |
+----------------------------------------------+
```

Behavior:

- Use when PDFKit rewrite may alter interactive content.
- Keep warning concise and practical.

## Screen 17: Compression Not Beneficial Alert

Purpose: avoid making no-op compression feel broken.

```text
+----------------------------------------------+
| Local Stitch                                  |
+----------------------------------------------+
| This PDF may already be optimized.             |
|                                              |
| The reduced copy is not meaningfully smaller   |
| than the original. You can keep the original   |
| or save the rewritten copy anyway.             |
|                                              |
|          [Keep Original] [Save Copy Anyway]   |
+----------------------------------------------+
```

Behavior:

- Prefer "Keep Original" when output is larger or barely smaller.
- This can be inline instead of an alert if the estimate panel is visible.

## Screen 18: App Info

Purpose: existing app info/help sheet remains mostly unchanged.

```text
+----------------------------------------------+
|                    [App Icon]                 |
|                  Local Stitch                 |
|                  Version 1.0                  |
|       Private PDF merging for your Mac.       |
|                  No uploads.                  |
|----------------------------------------------|
| Developer   Mangla & Co LLC                   |
| Support     developer@moeed.com               |
| Privacy     moeed.com/privacy                 |
| License     MIT License                       |
|                                              |
| [Privacy Policy] [Contact Support] [Company] |
|                                              |
|                                      [Done]  |
+----------------------------------------------+
```

Potential copy update:

```text
Private PDF merging and file size reduction for your Mac. No uploads.
```

## Recommended Compression Levels

Use names that set expectations without promising advanced compression.

```text
Balanced
- Best first choice.
- Uses PDFKit image rewrite where available.
- Aims to reduce size while preserving readability.

Smallest PDF
- More aggressive PDFKit image optimization.
- May reduce image quality.
- Useful for upload limits.
```

Implementation mapping to validate:

```text
Balanced:
  PDFDocumentWriteOption.saveImagesAsJPEG = true

Smallest PDF:
  PDFDocumentWriteOption.saveImagesAsJPEG = true
  PDFDocumentWriteOption.optimizeImagesForScreen = true
```

## Suggested Copy Updates

Current:

```text
Private PDF merging for your Mac. No uploads.
```

Proposed:

```text
Private PDF merging and file size reduction for your Mac. No uploads.
```

Current primary buttons:

```text
Merge PDFs
Start New Merge
```

Proposed adaptive buttons:

```text
Reduce File Size
Save Compressed Copy
Merge PDFs
Merge & Compress
Start New Task
```

## State Model Notes

The UI can still be a single-window workflow. The implementation may need a richer operation concept behind the scenes:

```text
Idle / Empty
Active list
Estimating compression
Processing merge
Processing compression
Success
```

The visible design should stay simple even if the internal operation state becomes more specific.

## Review Questions

Before implementation, decide:

1. Should one-file compression default to enabled?
2. Should compressed copies of password-protected PDFs be saved without password protection, matching current merge behavior?
3. Should "Balanced" and "Smallest PDF" both ship in MVP if PDFKit results are not clearly different?
4. Should compression warnings for forms/annotations be inline or modal?
5. Should "Start New Merge" become "Start New Task" across the app?

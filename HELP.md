# Local Stitch Help

## Merge PDFs

1. Open Local Stitch.
2. Drop PDFs into the window or choose `Choose PDFs`.
3. Arrange the files in the order you want.
4. Unlock any protected PDFs.
5. Choose whether to add source summary pages.
6. Optionally choose `Reduce file size after merge`.
7. Select `Merge PDFs` or `Merge & Compress`.
8. Pick a filename and destination.

The output PDF follows the order shown in the file list.

## Reduce File Size

1. Open Local Stitch.
2. Add one PDF.
3. Choose `Balanced` or `Smallest PDF`.
4. Select `Reduce File Size`.
5. Review the measured local estimate.
6. Save the compressed copy, save a rewritten copy anyway, or keep the original.

Local Stitch uses PDFKit to rewrite images where available. Some PDFs are already optimized, mostly text, or structured in a way that does not shrink much.

`Balanced` is the best first choice. `Smallest PDF` is more aggressive and may reduce image quality.

## Merge And Compress

1. Add two or more PDFs.
2. Arrange the files in the order you want.
3. Turn on `Reduce file size after merge`.
4. Select a compression level.
5. Select `Merge & Compress`.
6. Pick a filename and destination.

Local Stitch creates the merged PDF locally first, then compresses the merged output.

## Protected PDFs

When Local Stitch finds password-protected PDFs, processing stays disabled until they are unlocked.

Enter a password and choose `Apply to All`. If the password only unlocks some files, repeat the step with the next password.

Merged or compressed output copies are saved without preserving the original PDF password.

## Source Summary Pages

Source summary pages are optional. They add a compilation overview and one summary page before each source PDF. These pages include source filenames, page ranges, metadata, detected structure, and SHA-256 fingerprints.

Use them when you want the merged PDF to preserve source context for later human review or AI-assisted document review.

## File Limit

Local Stitch supports up to 100 PDFs in one task. This keeps the workflow bounded and helps the app stay responsive during large jobs.

## Privacy

Local Stitch processes selected PDFs locally on your Mac. It does not upload files, collect analytics, or require an account.

Privacy policy: https://moeed.com/privacy/

## Install And Uninstall

Install from the Mac App Store, or download the signed DMG from GitHub Releases:

https://github.com/moeed80/Local-Stitch/releases/tag/v1.0.0

For direct downloads, open the DMG and drag `Local Stitch.app` into the `Applications` folder.

To uninstall, delete `Local Stitch.app` from Launchpad or move it from `Applications` to the Trash.

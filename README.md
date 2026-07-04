# Local Stitch

Local Stitch is a free, local-first macOS app for merging user-selected PDF files and reducing PDF file size.

It is built for sensitive document workflows where uploading files to an online PDF tool is a bad fit. Local Stitch runs on your Mac, uses only the PDFs you choose, and saves output PDFs only to the destination you select.

## What It Does

- Merge up to 100 PDF files into one PDF.
- Reduce the file size of a single selected PDF.
- Optionally reduce file size after merging multiple PDFs.
- Add PDFs with drag and drop or the macOS file picker.
- Reorder files before merging.
- Remove files from the merge list.
- Unlock password-protected PDFs before merging.
- Optionally add source summary pages for AI review.
- Show merge and compression progress and reveal the exported PDF in Finder.

## Reduce File Size

With one PDF selected, Local Stitch offers `Reduce File Size`. It creates a temporary local candidate, measures the actual output size, then lets you save the copy with the native macOS save panel.

With multiple PDFs selected, you can turn on `Reduce file size after merge`. Local Stitch merges first, then uses PDFKit image rewrite options to reduce the final merged PDF where possible. Some PDFs are already optimized or mostly text, so the rewritten copy may save little space or even become larger.

Compressed copies are saved without preserving the original PDF password, matching the app's current merged-output behavior.

## Source Summary Pages

When enabled, Local Stitch adds:

- One compilation overview page at the beginning of the merged PDF.
- One source summary page before each selected PDF.

These pages record filenames, page ranges, PDF metadata, detected structure, and SHA-256 fingerprints of the original selected files. They are meant to help humans and AI tools understand where each section of a merged document came from.

## Privacy

Local Stitch is designed around local-first privacy:

- No account is required.
- No subscription is required.
- No files are uploaded by the app.
- No analytics or usage tracking is collected by the app.
- PDF inspection, password unlock, hashing, summary-page creation, merging, and file size reduction happen locally on your Mac.
- Output PDFs are written only to the destination you choose.

Privacy policy: https://moeed.com/privacy/

## Requirements

- macOS 14.0 Sonoma or later.
- Apple Silicon or Intel Mac.

## Install

### Mac App Store

After App Store distribution is live, install Local Stitch from the Mac App Store like any other macOS app.

### Direct Download

If a signed direct download is published through GitHub Releases, open the downloaded disk image or archive and drag `Local Stitch.app` into your `Applications` folder.

## Uninstall

### Mac App Store Install

Delete Local Stitch from Launchpad or remove `Local Stitch.app` from the `Applications` folder.

### Direct Download Install

Move `Local Stitch.app` from the `Applications` folder to the Trash.

Local Stitch does not create cloud accounts or store uploaded documents. macOS may keep standard sandbox container data for app preferences. Advanced users can remove that through Finder or Terminal if they want a fully clean local uninstall.

## Build From Source

1. Clone the repository:

   ```bash
   git clone https://github.com/moeed80/Local-Stitch.git
   cd Local-Stitch
   ```

2. Open `Local Stitch.xcodeproj` in Xcode.
3. Choose the `Local Stitch` scheme.
4. Build and run on macOS 14.0 or later.

Command-line build:

```bash
xcodebuild -project "Local Stitch.xcodeproj" -scheme "Local Stitch" -configuration Release build
```

## Support

Local Stitch is distributed by Mangla & Co LLC.

- Support email: developer@moeed.com
- Contact form: https://moeed.com/contact/
- Company page: https://moeed.com/project/mangla/

Please do not send passwords, private keys, financial records, legal records, or other sensitive files unless they are necessary for support and you are comfortable sharing them.

## License

The source code is distributed under the MIT License. See `LICENSE`.

Developer/Seller Name: Mangla & Co LLC
Legal Entity Type: Virginia limited liability company
Business Location: Clifton, Virginia, United States

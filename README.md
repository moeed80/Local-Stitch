# Local Stitch

Local Stitch is a free, local-first macOS app for merging user-selected PDF files into one organized PDF.

It is built for sensitive document workflows where uploading files to an online PDF tool is a bad fit. Local Stitch runs on your Mac, uses only the PDFs you choose, and saves the merged PDF only to the destination you select.

## What It Does

- Merge up to 100 PDF files into one PDF.
- Add PDFs with drag and drop or the macOS file picker.
- Reorder files before merging.
- Remove files from the merge list.
- Unlock password-protected PDFs before merging.
- Optionally add source summary pages for AI review.
- Show merge progress and reveal the exported PDF in Finder.

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
- PDF inspection, password unlock, hashing, summary-page creation, and merging happen locally on your Mac.
- The merged PDF is written only to the destination you choose.

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

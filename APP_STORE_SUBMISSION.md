# App Store Submission Notes

## App Identity

- App name: Local Stitch
- Developer/Seller: Mangla & Co LLC
- Category: Utilities
- Version: 1.0
- Build: 1
- Minimum macOS: 14.0 Sonoma
- License: MIT License for source code; standard Apple app terms can apply for App Store distribution unless a custom EULA is added.

## Required URLs

- Privacy policy: https://moeed.com/privacy/
- Support URL: https://moeed.com/project/mangla/
- Contact form: https://moeed.com/contact/
- Support email: developer@moeed.com

## Recommended App Store Positioning

Short message:

Private PDF stitching and file size reduction for Mac.

Longer message:

Local Stitch helps you combine sensitive PDFs, reduce PDF file size, and prepare source-aware documents on your Mac. Add files, arrange the order, unlock protected PDFs locally, reduce one PDF, merge many PDFs, optionally reduce the merged output, and optionally add source summary pages that preserve filenames, page ranges, metadata, and SHA-256 fingerprints. No account, no subscription, no upload.

Avoid legal claims. Say the app helps organize documents for review and analysis; do not imply it provides legal advice or guarantees legal sufficiency.

## App Privacy

The current app behavior supports:

- No data collected by the app.
- No analytics collected by the app.
- No user files transmitted by the app.
- Local processing only.
- PDF inspection, password unlock, source summary generation, merging, and file size reduction all happen on the user's Mac.

If future releases add analytics, cloud processing, external AI APIs, or support upload features, update App Privacy before release.

## Export Compliance

Local Stitch uses CryptoKit for SHA-256 hashing of user-selected files. It does not provide encrypted communications, VPN functionality, encrypted storage, or custom cryptography. Answer App Store Connect export-compliance questions according to Apple's current wording for the release being submitted.

## Screenshots To Capture

- Empty state with the drop zone and privacy reassurance.
- Single-PDF reduce file size workflow.
- Compression estimate showing original size, reduced size, and savings.
- Active file list with ordered PDFs.
- Protected PDF unlock state.
- Source summary pages toggle enabled.
- Merge and compress option enabled.
- Merge progress state.
- Compression progress state.
- Success state with `Show in Finder`.
- About window showing developer, version, privacy, support, and license.

## Manual QA Before Submit

- Add one valid PDF and reduce file size.
- Add one already-optimized or text-heavy PDF and verify the app explains little or no reduction.
- Add one valid PDF and save a rewritten copy anyway.
- Add one valid PDF and merge it only if the app allows a one-file merge path.
- Add several PDFs, reorder them, and verify output order.
- Add several PDFs, enable `Reduce file size after merge`, and verify final output.
- Add more than 100 PDFs and verify the limit message.
- Add a non-PDF file and verify it is skipped with a clear message.
- Add a corrupted or unsupported PDF and verify it is skipped with a clear message.
- Add password-protected PDFs with one shared password.
- Add password-protected PDFs with different passwords.
- Verify compressed and merged outputs do not preserve the original PDF password.
- Cancel a large merge and verify originals are unchanged.
- Cancel compression and verify originals are unchanged.
- Enable source summary pages and verify the output page count and summary pages.
- Use `Show in Finder` after a successful merge.
- Open About, Privacy Policy, and Contact Support menu items.

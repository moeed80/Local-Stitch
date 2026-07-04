# Local Stitch Product Strategy

## Strategic Position

Local Stitch is a free, open-source, local-first Mac utility for stitching PDFs, reducing PDF file size, and preparing sensitive document bundles for AI-assisted review. It is built for people who need to organize or shrink records quickly, privately, and without paying for a short-term need.

The product should not try to become a broad PDF editor first. Its strongest position is more specific:

> Local Stitch helps people prepare messy, sensitive PDF collections for AI review, legal context, personal record analysis, and upload-size limits without sending documents to an online PDF service.

This focus makes Local Stitch especially useful for small businesses, AI users, and individuals going through document-heavy personal situations such as divorce, disputes, financial reviews, insurance claims, immigration paperwork, or other legal matters.

## What The Product Does

Local Stitch solves a practical document preparation problem:

- A user has one oversized PDF or many related PDFs.
- Some PDFs may be bank statements or other password-protected records.
- The user may need one organized document, a smaller file, or both.
- The user may want to upload the final PDF into an AI tool for searching, summarization, timeline building, issue spotting, or evidence review.
- The user does not want to send sensitive documents through an online PDF merger or compressor.

The current app supports that workflow by letting users:

- Select PDFs from their Mac.
- Drag and drop PDFs into the app.
- Add up to 100 PDFs.
- Unlock protected PDFs locally.
- Reduce the file size of one selected PDF.
- Merge multiple PDFs into one output PDF.
- Optionally reduce file size after merging.
- Reorder files before merge.
- Remove unwanted files.
- Estimate page count and show file sizes.
- Add optional AI-friendly source summary pages.
- Export output PDFs to a chosen local destination.

The source summary feature remains strategically important. It turns Local Stitch from a basic merger into a source-aware AI preparation tool. The output can include document boundaries, page ranges, metadata, hashes, and machine-readable context. That matters when users need to understand where information came from after an AI tool has analyzed a large merged document.

File size reduction is now a second core utility. It helps with AI upload limits, court portals, email attachments, and large scanned documents while preserving the app's local-first promise.

## Target Users

### Primary Users

**People with legal or personal document burdens**

These users may be going through divorce, custody disputes, financial conflict, immigration processes, civil claims, insurance issues, estate matters, or other document-heavy situations. They often need to gather bank statements, emails, photos converted to PDFs, receipts, messages, forms, and records. They may only need this kind of tool for a short period, which makes paid PDF apps feel exploitative or poorly matched to the moment.

**AI-assisted document reviewers**

These users are already uploading PDFs to AI tools to ask questions, find patterns, summarize histories, extract timelines, locate relevant conversations, or prepare supporting context. They need a way to package documents so AI systems can ingest them more cleanly and stay within upload-size constraints.

**Small businesses**

Small businesses often have fragmented records across statements, invoices, receipts, customer files, contracts, and exported emails. They need simple document consolidation and file size reduction without enterprise software, recurring subscriptions, or cloud exposure.

### Secondary Users

- Researchers consolidating source documents.
- Accountants and bookkeepers preparing document bundles.
- Independent consultants organizing client-supplied PDFs.
- Privacy-conscious Mac users who avoid online PDF tools.

## Core Wedge

Local Stitch's wedge should be:

1. AI-ready PDF stitching.
2. Local file size reduction.
3. Simplicity.
4. Local privacy.

Password-protected PDF handling is a prerequisite rather than the main pitch. It is important because many bank statements and official records are protected, but users should experience it as part of the app "just working" for real-world documents.

The clearest promise is:

> Combine and shrink sensitive PDFs on your Mac, locally and for free.

## Opportunity

The opportunity comes from four overlapping shifts.

### 1. People Are Using AI For Personal Document Analysis

Users increasingly ask AI tools to analyze long histories of documents: bank statements, emails, contracts, message exports, receipts, and case records. But AI tools often prefer fewer files, have upload limits, or lose context across many separate uploads.

Local Stitch can become the preparation layer between a messy folder of documents and an AI conversation.

### 2. Upload Limits Create Friction

Even when a user successfully merges documents, the resulting PDF may be too large for an AI tool, court portal, email attachment, or business system. A local file size reduction option makes the app useful after the merge step and also valuable for single oversized PDFs.

### 3. Legal And Personal Cases Create Short-Term PDF Needs

Many people only need PDF tools during stressful life events. They may not want a subscription, may not know which paid app to trust, and may be working under time pressure. A free, simple, open-source Mac app has a humane advantage here.

Local Stitch can position itself as a public-interest utility: practical software for people who need help organizing and shrinking evidence or records.

### 4. Privacy Is More Important When Documents Are Sensitive

Online PDF mergers and compressors are convenient, but they are a poor fit for legal, financial, and personal records. Local Stitch can make privacy a default rather than an advanced setting.

The app should keep emphasizing:

- No cloud processing.
- No network calls.
- User-selected files only.
- Local export only.
- Open-source code that users can inspect.

## Distribution Strategy

Local Stitch should be distributed in three complementary ways.

### 1. GitHub Repository

The GitHub repo is the trust anchor.

Recommended GitHub positioning:

- Clear README with screenshots and usage steps.
- Prominent privacy statement.
- Downloadable signed and notarized DMG release.
- Explanation of file size reduction limits.
- Explanation of AI-friendly source summary pages.
- Simple build-from-source instructions.
- Statement that the app is free and open source.

GitHub is also where technically inclined users, advocates, and contributors can verify the local-first claims.

Current direct release:

- Release page: https://github.com/moeed80/Local-Stitch/releases/tag/v1.0.0
- DMG: https://github.com/moeed80/Local-Stitch/releases/download/v1.0.0/Local-Stitch-1.0.dmg

### 2. Free Mac App Store Download

The Mac App Store can make the app easier to discover and install for non-technical users.

The App Store listing should emphasize:

- Free.
- Private.
- Local.
- No account.
- No subscription.
- Merge PDFs.
- Reduce PDF file size.
- Prepare PDFs for AI-assisted review.
- Helpful for organizing and shrinking document bundles.

The listing should avoid sounding like legal advice. It can say the app helps organize documents for review, analysis, and sharing, but should not imply it prepares legally sufficient discovery packages by itself.

Distribution identity:

- Developer/Seller: Mangla & Co LLC.
- Category: Utilities.
- Privacy policy: https://moeed.com/privacy/
- Support page: https://moeed.com/project/mangla/
- Support email: developer@moeed.com
- Minimum macOS for version 1.0: macOS 14.0 Sonoma.

### 3. Direct DMG

A direct DMG on GitHub gives users an option outside the App Store and helps with faster releases.

This is useful for:

- Users on machines without App Store access.
- Early adopters.
- People who want the newest build.
- Open-source users who prefer GitHub releases.

## Product Principles

### Free For Basic Human Need

Local Stitch exists partly to undercut paid apps that charge for basic one-time PDF tasks. The product should preserve that stance. Avoid features or packaging that make users feel trapped during stressful situations.

### Local First, Always

Do not add network processing. Do not upload documents. Do not introduce cloud analysis. If future features use AI, they should either prepare documents for external tools or use explicitly local models only after careful consideration.

### Simple Before Powerful

The app should stay approachable for users who are not technical. Every feature should answer a visible document-prep need.

### Source Context Matters

AI-ready does not just mean "one big PDF." It means the combined file should preserve document boundaries, page ranges, provenance, and enough metadata to support later review.

### Be Honest About Compression

Local Stitch should say "reduce file size" rather than promise a guaranteed compression percentage. PDFKit-based reduction can help image-heavy PDFs, but already-optimized, text-heavy, or vector-heavy PDFs may shrink little or not at all.

### Stress-Case Design

Many users may be in difficult personal situations. The app should feel calm, direct, and trustworthy. Avoid cleverness, clutter, upsells, and ambiguous terminology.

## Current Feature Strategy

### Keep The Core Workflow Excellent

The current core is:

- Add PDFs.
- Unlock protected PDFs locally.
- Reduce a single PDF's file size.
- Merge multiple PDFs.
- Optionally reduce merged output size.
- Optionally add AI-friendly source summary pages.
- Save locally.

High-value improvements to the current core:

- Clearer file validation feedback for skipped files.
- Better explanation of PDFKit-only file size reduction limits.
- More visible explanation of what source summary pages do.
- Better progress and cancellation behavior for very large tasks.
- Better handling of multiple different passwords across protected PDFs.
- Save/load task drafts, if this can be done without compromising simplicity.

### File Size Reduction

File size reduction is now part of the product core.

Current behavior:

- Single selected PDF can be reduced directly.
- Multiple PDFs can be merged and then reduced.
- The app measures real local output rather than guessing.
- `Balanced` and `Smallest PDF` use PDFKit write options.
- If the result is not meaningfully smaller, the app tells the user.

Strategic value:

- Directly supports AI upload workflows.
- Helps with court and portal limits.
- Helps with email attachment limits.
- Makes Local Stitch useful even when the user does not need to merge anything.
- Keeps users away from online PDF compressors for sensitive files.

Future improvement:

- Explore advanced image recompression only if it can remain local, reliable, and simple.

### PDF Splitting By Summary Pages

This remains a natural companion feature.

If Local Stitch can create a merged PDF with source summary pages, it can later use those pages as markers to split the document back into separate PDFs. This would support users who receive a stitched bundle and need to recover the original structure.

Potential behavior:

- User selects a merged PDF.
- App detects Local Stitch summary pages.
- App previews the detected document sections.
- User chooses an output folder.
- App exports one PDF per detected source document.

Strategic value:

- Reinforces summary pages as durable document structure.
- Makes Local Stitch useful on both sides of the merge workflow.
- Helps users recover order and boundaries from large bundles.

### Page Rotation

Page rotation is a practical feature for scanned statements, receipts, photos, and exported records.

Potential behavior:

- Rotate selected file before merge.
- Rotate individual pages in a preview.
- Apply rotation to all pages in a source PDF.

Strategic value:

- Makes outputs more readable before AI upload or human review.
- Fits the document-prep mission.
- Avoids pushing users into a paid editor for a basic fix.

### AI-Oriented Enhancements

These should stay focused on preparing files for AI, not replacing AI tools.

Potential features:

- Copy a suggested AI prompt after merge.
- Export a companion text manifest.
- Export a document index as Markdown or CSV.
- Add optional section title pages.
- Add page labels or bookmarks based on source filenames.
- Generate a plain-language summary page from metadata only, without reading document content through AI.

Avoid:

- Sending documents to third-party AI APIs.
- Making legal judgments.
- Promising that AI output is complete or legally reliable.

## Messaging

### Primary Message

Free, private PDF stitching and file size reduction for Mac.

### Supporting Messages

- Combine up to 100 PDFs on your Mac.
- Reduce the size of one PDF without uploading it.
- Merge PDFs and reduce the final output size.
- Unlock protected bank statements locally.
- Add source summaries so AI tools and humans can understand document boundaries.
- No account, no subscription, no upload.
- Open source and free.

### Tone

The tone should be practical, calm, and respectful. Many users may be handling sensitive or stressful documents. The product should feel like a reliable utility, not a flashy productivity app.

## Competitive Context

Local Stitch undercuts three categories of alternatives.

### Online PDF Tools

Online merge and compression tools are convenient but require users to upload sensitive documents. Local Stitch wins on privacy and trust.

### Paid PDF Apps

Paid PDF apps may be powerful, but many users only need a simple merge, unlock, reduce-size, rotate, split, or compress workflow for a short period. Local Stitch wins on cost, simplicity, and empathy.

### General AI Tools

AI tools can analyze documents, but they do not always solve the preparation problem. Local Stitch wins by creating cleaner, smaller, more structured inputs for those tools.

## Risks

### Scope Creep

The app could become a broad PDF editor and lose its simple identity. The roadmap should prioritize document preparation for AI and sensitive-record workflows.

### Legal Misinterpretation

Because some users may use Local Stitch during legal matters, the product should avoid implying legal advice, legal sufficiency, or guaranteed discovery compliance.

### Compression Expectations

Users may expect Smallpdf-level advanced compression. The app should be honest that Local Stitch uses local PDFKit-based reduction and that some PDFs may already be optimized.

### PDF Complexity

PDFs are messy. Forms, annotations, encryption, bookmarks, images, rotations, and malformed files can behave unpredictably. The product should keep improving validation, warnings, and recovery paths.

### Trust Burden

Privacy claims must remain true. Any future feature that touches networking, telemetry, analytics, or AI APIs would weaken the product's trust position unless it is explicit, optional, and carefully justified.

## Roadmap

### Version 1 Focus

- Reliable PDF merge.
- Single-PDF file size reduction.
- Merge-and-compress workflow.
- Password-protected PDF unlock flow.
- AI-friendly source summary pages.
- Clear page count and file size communication.
- Free distribution through GitHub and the Mac App Store.
- Strong README, help, and trust messaging.

### Version 1.x Candidates

- Better locked-file password workflow.
- More refined compression warnings for forms and annotations.
- Improved progress cancellation for very large tasks.
- Better skipped-file reporting.
- App Store polish and screenshots.
- More examples of when file size reduction helps and when it does not.
- Source summary documentation in the README.

### Version 2 Candidates

- Split merged PDFs using Local Stitch summary-page markers.
- Rotate pages or whole documents before merge.
- Export manifest/index as Markdown or CSV.
- Add generated bookmarks for each source document.
- Advanced local-only compression if it remains trustworthy and simple.

## Strategic North Star

Local Stitch should become the trusted free Mac utility for preparing sensitive PDFs for AI-assisted review and practical sharing limits.

The product wins when a user with a stressful pile of documents can open the app, stitch or shrink what they need, preserve source context where useful, and move forward without paying, uploading private files, or learning a complicated PDF suite.

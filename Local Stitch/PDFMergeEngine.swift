import Foundation
import PDFKit
import CryptoKit
import UniformTypeIdentifiers
import AppKit
import Combine
import OSLog

// MARK: - 1. CORE APPARATUS DATA MODELS
struct PDFFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
    var pageCount: Int?
    var fileSizeBytes: UInt64
    var isLocked: Bool
    var isUnlockedSuccessfully: Bool = false
    var cachedPassword: String = ""
    var hasAnnotations: Bool = false
    var hasForms: Bool = false
}

enum AppViewMode {
    case empty
    case activeList
    case processing
    case success
}

enum PDFProcessingPhase {
    case estimatingCompression
    case merging
    case compressing
}

enum CompletedPDFOperation {
    case compressed
    case merged
    case mergedAndCompressed
}

// MARK: - 2. CUSTOM SYSTEM PDF MANIFEST PAGE OVERLAY
struct PDFManifestMetadata {
    let filename: String
    let sourceIndex: Int
    let sourceCount: Int
    let originalPageCount: Int
    let outputPageStart: Int
    let outputPageEnd: Int
    let fileSizeBytes: UInt64
    let fileCreated: Date
    let fileModified: Date
    let sha256: String
    let title: String
    let author: String
    let subject: String
    let keywords: String
    let creator: String
    let producer: String
    let pdfCreated: Date?
    let pdfModified: Date?
    let isEncrypted: Bool
    let wasUnlockedForMerge: Bool
    let hasAnnotations: Bool
    let hasForms: Bool
    let hasBookmarks: Bool
    let pageProfile: String
}

struct CompilationManifestMetadata {
    let createdAt: Date
    let appVersion: String
    let sourceCount: Int
    let originalPageCount: Int
    let outputPageCount: Int
    let manifestPageCount: Int
    let documents: [PDFManifestMetadata]
}

class BaseManifestPage: PDFPage {
    let letterWidth: CGFloat = 612
    let letterHeight: CGFloat = 792
    let horizontalMarginInset: CGFloat = 42

    override func bounds(for box: PDFDisplayBox) -> NSRect {
        return NSRect(x: 0, y: 0, width: letterWidth, height: letterHeight)
    }

    func drawManifestContent(to context: CGContext, render: (_ row: (String, NSFont, NSColor) -> Void, _ moveDown: (CGFloat) -> Void) -> Void) {
        let nsGraphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        let previousContext = NSGraphicsContext.current
        NSGraphicsContext.current = nsGraphicsContext

        var internalDrawingCursorY: CGFloat = letterHeight - 44
        let maxBoundaryWidth = letterWidth - (horizontalMarginInset * 2)

        let renderTextRow: (String, NSFont, NSColor) -> Void = { lineText, stringFont, stringColor in
            let textStyles = NSMutableParagraphStyle()
            textStyles.alignment = .left
            textStyles.lineBreakMode = .byWordWrapping

            let formattingAttributes: [NSAttributedString.Key: Any] = [
                .font: stringFont,
                .foregroundColor: stringColor,
                .paragraphStyle: textStyles
            ]

            let printString = NSAttributedString(string: lineText, attributes: formattingAttributes)
            let boundingFrameSize = printString.boundingRect(
                with: CGSize(width: maxBoundaryWidth, height: .infinity),
                options: [.usesLineFragmentOrigin, .usesFontLeading]
            )

            internalDrawingCursorY -= boundingFrameSize.height
            let paintBox = CGRect(
                x: self.horizontalMarginInset,
                y: internalDrawingCursorY,
                width: maxBoundaryWidth,
                height: boundingFrameSize.height
            )
            printString.draw(in: paintBox)
            internalDrawingCursorY -= 8
        }

        let moveDown: (CGFloat) -> Void = { distance in
            internalDrawingCursorY -= distance
        }

        render(renderTextRow, moveDown)
        NSGraphicsContext.current = previousContext
    }

    func iso8601String(from date: Date?) -> String {
        guard let date else { return "Unknown" }
        return ISO8601DateFormatter().string(from: date)
    }

    func jsonEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

class CompilationManifestPage: BaseManifestPage {
    let metadata: CompilationManifestMetadata

    init(metadata: CompilationManifestMetadata) {
        self.metadata = metadata
        super.init()
    }

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        super.draw(with: box, to: context)

        drawManifestContent(to: context) { renderTextRow, moveDown in
            renderTextRow("LOCAL STITCH COMPILATION MANIFEST", NSFont.systemFont(ofSize: 20, weight: .bold), NSColor.labelColor)
            renderTextRow("Source identity, document boundaries, and original-file integrity fingerprints for AI/RAG ingestion.", NSFont.systemFont(ofSize: 10.5, weight: .regular), NSColor.secondaryLabelColor)
            moveDown(8)

            renderTextRow("COMPILE SUMMARY", NSFont.systemFont(ofSize: 11, weight: .semibold), NSColor.secondaryLabelColor)
            renderTextRow("Created: \(iso8601String(from: metadata.createdAt))", NSFont.monospacedSystemFont(ofSize: 9.8, weight: .regular), NSColor.labelColor)
            renderTextRow("Application: Local Stitch \(metadata.appVersion)", NSFont.monospacedSystemFont(ofSize: 9.8, weight: .regular), NSColor.labelColor)
            renderTextRow("Source PDFs: \(metadata.sourceCount) | Original pages: \(metadata.originalPageCount) | Output pages: \(metadata.outputPageCount) | Manifest pages: \(metadata.manifestPageCount)", NSFont.monospacedSystemFont(ofSize: 9.8, weight: .regular), NSColor.labelColor)
            moveDown(8)

            renderTextRow("DOCUMENT INDEX", NSFont.systemFont(ofSize: 11, weight: .semibold), NSColor.secondaryLabelColor)
            renderTextRow("Order | Original pages | Output pages | SHA-256 | Filename", NSFont.monospacedSystemFont(ofSize: 8.8, weight: .semibold), NSColor.labelColor)

            for document in metadata.documents.prefix(18) {
                let shortHash = String(document.sha256.prefix(16))
                renderTextRow("\(document.sourceIndex)/\(metadata.sourceCount) | \(document.originalPageCount) | \(document.outputPageStart)-\(document.outputPageEnd) | \(shortHash)... | \(document.filename)", NSFont.monospacedSystemFont(ofSize: 8.2, weight: .regular), NSColor.labelColor)
            }

            if metadata.documents.count > 18 {
                renderTextRow("Additional source documents continue with full metadata on their per-document manifest pages.", NSFont.systemFont(ofSize: 9.5, weight: .regular), NSColor.secondaryLabelColor)
            }

            moveDown(8)
            renderTextRow("INTEGRITY NOTE", NSFont.systemFont(ofSize: 11, weight: .semibold), NSColor.secondaryLabelColor)
            renderTextRow("Each SHA-256 value is computed from the original user-selected PDF bytes before merge. The manifest records source identity, boundaries, metadata, detected structural features, and verification fingerprints; it does not claim to preserve every hidden PDF object.", NSFont.systemFont(ofSize: 9.6, weight: .regular), NSColor.labelColor)
        }
    }
}

class ManifestPage: BaseManifestPage {
    let metadata: PDFManifestMetadata

    init(metadata: PDFManifestMetadata) {
        self.metadata = metadata
        super.init()
    }

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        super.draw(with: box, to: context)

        drawManifestContent(to: context) { renderTextRow, moveDown in
            renderTextRow("SOURCE DOCUMENT MANIFEST", NSFont.systemFont(ofSize: 18, weight: .bold), NSColor.labelColor)
            renderTextRow("Original source context and verification record for AI/RAG ingestion.", NSFont.systemFont(ofSize: 10.5, weight: .regular), NSColor.secondaryLabelColor)
            moveDown(8)

            renderTextRow(metadata.filename, NSFont.systemFont(ofSize: 24, weight: .bold), NSColor.labelColor)
            renderTextRow("Document \(metadata.sourceIndex) of \(metadata.sourceCount) | Output pages \(metadata.outputPageStart)-\(metadata.outputPageEnd)", NSFont.systemFont(ofSize: 11.5, weight: .regular), NSColor.labelColor)
            moveDown(8)

            renderTextRow("FILE INTEGRITY", NSFont.systemFont(ofSize: 10.8, weight: .semibold), NSColor.secondaryLabelColor)
            renderTextRow("SHA-256 original file: \(metadata.sha256)", NSFont.monospacedSystemFont(ofSize: 8.8, weight: .regular), NSColor.labelColor)
            renderTextRow("Size: \(metadata.fileSizeBytes) bytes | Original pages: \(metadata.originalPageCount)", NSFont.monospacedSystemFont(ofSize: 9.4, weight: .regular), NSColor.labelColor)
            renderTextRow("File created: \(iso8601String(from: metadata.fileCreated)) | File modified: \(iso8601String(from: metadata.fileModified))", NSFont.monospacedSystemFont(ofSize: 9.4, weight: .regular), NSColor.labelColor)
            moveDown(6)

            renderTextRow("PDF METADATA", NSFont.systemFont(ofSize: 10.8, weight: .semibold), NSColor.secondaryLabelColor)
            renderTextRow("Title: \(metadata.title)", NSFont.systemFont(ofSize: 9.6, weight: .regular), NSColor.labelColor)
            renderTextRow("Author: \(metadata.author) | Subject: \(metadata.subject)", NSFont.systemFont(ofSize: 9.6, weight: .regular), NSColor.labelColor)
            renderTextRow("Keywords: \(metadata.keywords)", NSFont.systemFont(ofSize: 9.6, weight: .regular), NSColor.labelColor)
            renderTextRow("Creator: \(metadata.creator) | Producer: \(metadata.producer)", NSFont.systemFont(ofSize: 9.6, weight: .regular), NSColor.labelColor)
            renderTextRow("PDF created: \(iso8601String(from: metadata.pdfCreated)) | PDF modified: \(iso8601String(from: metadata.pdfModified))", NSFont.monospacedSystemFont(ofSize: 9.4, weight: .regular), NSColor.labelColor)
            moveDown(6)

            renderTextRow("DETECTED STRUCTURE", NSFont.systemFont(ofSize: 10.8, weight: .semibold), NSColor.secondaryLabelColor)
            renderTextRow("Encrypted: \(metadata.isEncrypted ? "true" : "false") | Unlocked for merge: \(metadata.wasUnlockedForMerge ? "true" : "false") | Annotations: \(metadata.hasAnnotations ? "true" : "false") | Forms: \(metadata.hasForms ? "true" : "false") | Bookmarks: \(metadata.hasBookmarks ? "true" : "false")", NSFont.monospacedSystemFont(ofSize: 9.2, weight: .regular), NSColor.labelColor)
            renderTextRow("Page profile: \(metadata.pageProfile)", NSFont.systemFont(ofSize: 9.6, weight: .regular), NSColor.labelColor)
            moveDown(8)

            renderTextRow("MACHINE-READABLE CONTEXT", NSFont.systemFont(ofSize: 10.8, weight: .semibold), NSColor.secondaryLabelColor)
            let json = """
            {"source_index":\(metadata.sourceIndex),"source_count":\(metadata.sourceCount),"filename":"\(jsonEscaped(metadata.filename))","original_pages":\(metadata.originalPageCount),"merged_output_page_range":"\(metadata.outputPageStart)-\(metadata.outputPageEnd)","sha256_original_file":"\(metadata.sha256)","file_size_bytes":\(metadata.fileSizeBytes),"pdf_metadata":{"title":"\(jsonEscaped(metadata.title))","author":"\(jsonEscaped(metadata.author))","subject":"\(jsonEscaped(metadata.subject))","keywords":"\(jsonEscaped(metadata.keywords))","creator":"\(jsonEscaped(metadata.creator))","producer":"\(jsonEscaped(metadata.producer))"},"detected_features":{"encrypted":\(metadata.isEncrypted),"unlocked_for_merge":\(metadata.wasUnlockedForMerge),"annotations":\(metadata.hasAnnotations),"forms":\(metadata.hasForms),"bookmarks":\(metadata.hasBookmarks)}}
            """
            renderTextRow(json, NSFont.monospacedSystemFont(ofSize: 7.9, weight: .regular), NSColor.labelColor)
        }
    }
}

// MARK: - 3. STORAGE CONTROLLER PIPELINE (VIEW MODEL)
class PDFMergeEngine: ObservableObject {

    @Published var loadedFiles: [PDFFile] = []
    @Published var viewMode: AppViewMode = .empty
    @Published var currentUIError: LocalStitchError? = nil
    @Published var insertManifestPages = false
    @Published var reduceSingleFileSize = true
    @Published var reduceMergedFileSize = false
    @Published var compressionLevel: PDFCompressionLevel = .balanced
    @Published var compressionEstimate: PDFCompressionMeasurement? = nil
    @Published var globalPasswordInput = ""

    @Published var processingProgress: Double = 0.0
    @Published var currentFileIndex: Int = 0
    @Published var totalFileCount: Int = 0
    @Published var processingPhase: PDFProcessingPhase = .merging
    @Published var processingTitle: String = ""
    @Published var processingStatusLine: String = ""
    @Published var processingSubtext: String = ""
    @Published var processingFooterSummary: String = ""
    @Published var generatedFilename: String = ""
    @Published var savedPageCount: Int = 0
    @Published var completedOperation: CompletedPDFOperation = .merged
    @Published var successSizeSummary: String = ""
    @Published var successAdditionalNote: String = ""
    @Published var passwordUnlockMessage: String = ""
    @Published var isCancellationRequested = false

    // Tracks the exact system storage path chosen by the user
    private var finalSavedURL: URL? = nil
    private let compressionService = PDFCompressionService()
    private var activeCompressionRequestID: UUID? = nil

    var estimatedPageCount: Int {
        let basePages = loadedFiles.compactMap { $0.pageCount }.reduce(0, +)
        let overhead = insertManifestPages && !loadedFiles.isEmpty ? loadedFiles.count + 1 : 0
        return basePages + overhead
    }

    var selectedInputSizeBytes: UInt64 {
        loadedFiles.reduce(0) { $0 + $1.fileSizeBytes }
    }

    var isSingleFileWorkflow: Bool {
        loadedFiles.count == 1
    }

    var hasUnlockedProtectedFiles: Bool {
        loadedFiles.contains { $0.isLocked && $0.isUnlockedSuccessfully }
    }

    var hasRewriteSensitivePDFs: Bool {
        loadedFiles.contains { $0.hasAnnotations || $0.hasForms }
    }

    var hasRemainingLockedFiles: Bool {
        loadedFiles.contains(where: { $0.isLocked && !$0.isUnlockedSuccessfully })
    }

    var remainingLockedFileCount: Int {
        loadedFiles.filter { $0.isLocked && !$0.isUnlockedSuccessfully }.count
    }

    var primaryActionTitle: String {
        guard !loadedFiles.isEmpty else { return "Merge PDFs" }

        if isSingleFileWorkflow {
            guard reduceSingleFileSize else { return "Reduce File Size" }
            guard let compressionEstimate else { return "Reduce File Size" }
            return compressionEstimate.hasMeaningfulSavings ? "Save Compressed Copy" : "Save Copy Anyway"
        }

        return reduceMergedFileSize ? "Merge & Compress" : "Merge PDFs"
    }

    var canPerformPrimaryAction: Bool {
        guard viewMode == .activeList, !loadedFiles.isEmpty, !hasRemainingLockedFiles else {
            return false
        }

        if isSingleFileWorkflow {
            return reduceSingleFileSize
        }

        return true
    }

    var shouldOfferKeepOriginal: Bool {
        guard isSingleFileWorkflow, let compressionEstimate else { return false }
        return compressionEstimate.isLargerThanOriginal || compressionEstimate.hasLittleOrNoSavings
    }

    var shouldPreferKeepOriginal: Bool {
        guard isSingleFileWorkflow, let compressionEstimate else { return false }
        return compressionEstimate.isLargerThanOriginal
    }

    var successTitle: String {
        switch completedOperation {
        case .compressed:
            return "Compressed PDF saved"
        case .merged:
            return "Merged PDF saved"
        case .mergedAndCompressed:
            return "Merged and compressed PDF saved"
        }
    }

    var successDetail: String {
        switch completedOperation {
        case .compressed:
            return "Saved '\(generatedFilename)'."
        case .merged, .mergedAndCompressed:
            return "Saved '\(generatedFilename)' with \(savedPageCount) pages."
        }
    }

    var footerEstimateText: String {
        guard !loadedFiles.isEmpty else {
            return "Estimated output: 0 pages"
        }

        if hasRemainingLockedFiles {
            return "Estimated output: locked PDF must be unlocked first"
        }

        if isSingleFileWorkflow {
            guard let file = loadedFiles.first else { return "Estimated output: 0 pages" }
            let pageText = "\(file.pageCount ?? 0) pages"

            if let compressionEstimate {
                if compressionEstimate.isLargerThanOriginal {
                    return "Estimated output: larger than original"
                }

                if compressionEstimate.hasLittleOrNoSavings {
                    return "Estimated output: little or no reduction"
                }

                return "Estimated output: \(pageText), about \(Self.formattedFileSize(compressionEstimate.compressedSizeBytes))"
            }

            return "Estimated output: \(pageText), \(Self.formattedFileSize(file.fileSizeBytes))"
        }

        let manifestPageCount = loadedFiles.count + 1
        let manifestOverheadText = insertManifestPages ? " including \(manifestPageCount) summary pages" : ""
        let sizeText = selectedInputSizeBytes > 0 ? ", about \(Self.formattedFileSize(selectedInputSizeBytes)) input" : ""
        return "Estimated output: \(estimatedPageCount) pages\(manifestOverheadText)\(sizeText)"
    }

    func selectLocalFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]

        if panel.runModal() == .OK {
            addPDFURLs(panel.urls)
        }
    }

    func checkPasswordUnlock() {
        let password = globalPasswordInput
        guard !password.isEmpty else { return }

        globalPasswordInput = ""
        let filesNeedingUnlock = loadedFiles.filter { $0.isLocked && !$0.isUnlockedSuccessfully }

        DispatchQueue.global(qos: .userInitiated).async {
            var unlockResults: [UUID: (pageCount: Int, hasAnnotations: Bool, hasForms: Bool)] = [:]

            for file in filesNeedingUnlock {
                autoreleasepool {
                    guard
                        let pdfDocument = PDFDocument(url: file.url),
                        pdfDocument.unlock(withPassword: password)
                    else {
                        return
                    }

                    unlockResults[file.id] = (
                        pageCount: pdfDocument.pageCount,
                        hasAnnotations: self.documentHasAnnotations(pdfDocument, shouldCancel: { false }),
                        hasForms: self.documentHasForms(pdfDocument, shouldCancel: { false })
                    )
                }
            }

            DispatchQueue.main.async {
                var unlockedCount = 0

                for index in self.loadedFiles.indices where self.loadedFiles[index].isLocked && !self.loadedFiles[index].isUnlockedSuccessfully {
                    guard let result = unlockResults[self.loadedFiles[index].id] else { continue }

                    self.loadedFiles[index].isUnlockedSuccessfully = true
                    self.loadedFiles[index].cachedPassword = password
                    self.loadedFiles[index].pageCount = result.pageCount
                    self.loadedFiles[index].hasAnnotations = result.hasAnnotations
                    self.loadedFiles[index].hasForms = result.hasForms
                    unlockedCount += 1
                }

                let remainingCount = self.remainingLockedFileCount
                if remainingCount == 0 {
                    self.passwordUnlockMessage = "All protected files are unlocked. Output copies are saved without the original PDF password."
                } else if unlockedCount == 0 {
                    self.passwordUnlockMessage = "That password did not unlock any remaining files."
                } else {
                    self.passwordUnlockMessage = "Unlocked \(unlockedCount) file\(unlockedCount == 1 ? "" : "s"). \(remainingCount) still locked."
                }
            }
        }
    }

    private func inspectPDFFile(at url: URL) -> Result<PDFFile, LocalStitchError> {
        guard url.pathExtension.lowercased() == "pdf" else {
            return .failure(.unsupportedFile(url.lastPathComponent))
        }

        guard let pdfDocument = PDFDocument(url: url) else {
            Logger.engine.error("Failed to parse a selected PDF document. File may be corrupted.")
            return .failure(.corruptedFile(url.lastPathComponent))
        }

        let fileIsEncrypted = pdfDocument.isLocked
        if fileIsEncrypted {
            Logger.engine.warning("Added password-protected file awaiting unlock.")
        }

        return .success(PDFFile(
            url: url,
            pageCount: fileIsEncrypted ? nil : pdfDocument.pageCount,
            fileSizeBytes: PDFCompressionService.fileSize(at: url) ?? 0,
            isLocked: fileIsEncrypted,
            hasAnnotations: fileIsEncrypted ? false : documentHasAnnotations(pdfDocument, shouldCancel: { false }),
            hasForms: fileIsEncrypted ? false : documentHasForms(pdfDocument, shouldCancel: { false })
        ))
    }

    private func addPDFURLs(_ urls: [URL]) {
        let remainingSlots = max(0, 100 - loadedFiles.count)
        let urlsToInspect = Array(urls.prefix(remainingSlots))
        let ignoredForLimitCount = max(0, urls.count - urlsToInspect.count)

        guard !urlsToInspect.isEmpty else {
            currentUIError = .fileLimitReached(100)
            return
        }

        Logger.engine.info("Inspecting \(urlsToInspect.count) PDF candidates.")

        DispatchQueue.global(qos: .userInitiated).async {
            var newlyAddedFiles: [PDFFile] = []
            var skippedFiles: [String] = []

            for url in urlsToInspect {
                switch self.inspectPDFFile(at: url) {
                case .success(let file):
                    newlyAddedFiles.append(file)
                case .failure(let error):
                    skippedFiles.append(error.errorDescription ?? "A file could not be added.")
                }
            }

            DispatchQueue.main.async {
                if !newlyAddedFiles.isEmpty {
                    self.clearCompressionEstimate()
                    self.loadedFiles.append(contentsOf: newlyAddedFiles)
                    self.passwordUnlockMessage = ""
                    self.reduceSingleFileSize = self.loadedFiles.count == 1
                    self.viewMode = .activeList
                }

                if !skippedFiles.isEmpty || ignoredForLimitCount > 0 {
                    self.currentUIError = .importSummary(
                        self.importSummaryMessage(
                            addedCount: newlyAddedFiles.count,
                            skippedFiles: skippedFiles,
                            ignoredForLimitCount: ignoredForLimitCount
                        ),
                        UUID()
                    )
                }
            }
        }
    }

    private func importSummaryMessage(
        addedCount: Int,
        skippedFiles: [String],
        ignoredForLimitCount: Int
    ) -> String {
        var lines: [String] = []

        if addedCount > 0 {
            lines.append("Added \(addedCount) PDF\(addedCount == 1 ? "" : "s").")
        }

        if !skippedFiles.isEmpty {
            let shownSkippedFiles = skippedFiles.prefix(3).joined(separator: "\n")
            let extraSkippedCount = skippedFiles.count - min(skippedFiles.count, 3)
            lines.append("Skipped \(skippedFiles.count) item\(skippedFiles.count == 1 ? "" : "s"):\n\(shownSkippedFiles)")

            if extraSkippedCount > 0 {
                lines.append("And \(extraSkippedCount) more.")
            }
        }

        if ignoredForLimitCount > 0 {
            lines.append("Left out \(ignoredForLimitCount) item\(ignoredForLimitCount == 1 ? "" : "s") because Local Stitch can process up to 100 PDFs at a time.")
        }

        return lines.joined(separator: "\n\n")
    }

    func performPrimaryAction() {
        guard canPerformPrimaryAction else { return }

        if isSingleFileWorkflow {
            if compressionEstimate == nil {
                startSingleFileCompressionEstimate()
            } else {
                saveSingleFileCompressedCopy()
            }
        } else {
            executeProductionMergePipeline()
        }
    }

    func setCompressionLevel(_ level: PDFCompressionLevel) {
        guard compressionLevel != level else { return }

        let shouldRefreshEstimate = compressionEstimate != nil
            && isSingleFileWorkflow
            && viewMode == .activeList
            && !hasRemainingLockedFiles

        compressionLevel = level
        clearCompressionEstimate()

        if shouldRefreshEstimate {
            startSingleFileCompressionEstimate()
        }
    }

    func setReduceSingleFileSize(_ isEnabled: Bool) {
        reduceSingleFileSize = isEnabled

        if !isEnabled {
            clearCompressionEstimate()
        }
    }

    func keepOriginalSingleFile() {
        clearCompressionEstimate()
    }

    func startSingleFileCompressionEstimate() {
        guard !hasRemainingLockedFiles else {
            currentUIError = .lockedFilesRemain
            return
        }

        guard isSingleFileWorkflow, let sourceFile = loadedFiles.first else { return }

        clearCompressionEstimate()

        let requestID = UUID()
        activeCompressionRequestID = requestID
        finalSavedURL = nil
        generatedFilename = ""
        currentFileIndex = 1
        totalFileCount = 1
        processingPhase = .estimatingCompression
        processingTitle = "Estimating reduced file size..."
        processingStatusLine = ""
        processingProgress = 0.2
        processingSubtext = "Creating a temporary local copy. No files are uploaded."
        processingFooterSummary = "Original: \(Self.formattedFileSize(sourceFile.fileSizeBytes))"
        isCancellationRequested = false
        viewMode = .processing

        let selectedLevel = compressionLevel

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let temporaryURL = try self.compressionService.temporaryPDFURL(prefix: "compression-estimate")
                let measurement = try self.compressionService.compressedCopy(
                    from: sourceFile.url,
                    to: temporaryURL,
                    password: sourceFile.isLocked ? sourceFile.cachedPassword : nil,
                    level: selectedLevel,
                    shouldCancel: self.isCancellationRequestedSnapshot
                )

                DispatchQueue.main.async {
                    guard self.activeCompressionRequestID == requestID else {
                        try? FileManager.default.removeItem(at: measurement.outputURL)
                        return
                    }

                    self.compressionEstimate = measurement
                    self.processingProgress = 1.0
                    self.processingSubtext = ""
                    self.processingFooterSummary = ""
                    self.isCancellationRequested = false
                    self.activeCompressionRequestID = nil
                    self.viewMode = .activeList
                }
            } catch let error as LocalStitchError {
                DispatchQueue.main.async {
                    guard self.activeCompressionRequestID == requestID else { return }

                    self.processingProgress = 0.0
                    self.processingSubtext = ""
                    self.processingFooterSummary = ""
                    self.isCancellationRequested = false
                    self.activeCompressionRequestID = nil
                    self.viewMode = .activeList

                    if case .compressionCancelled = error {
                        return
                    }

                    self.currentUIError = error
                }
            } catch {
                DispatchQueue.main.async {
                    guard self.activeCompressionRequestID == requestID else { return }

                    self.processingProgress = 0.0
                    self.processingSubtext = ""
                    self.processingFooterSummary = ""
                    self.isCancellationRequested = false
                    self.activeCompressionRequestID = nil
                    self.viewMode = .activeList
                    self.currentUIError = .compressionFailed(error.localizedDescription)
                }
            }
        }
    }

    func saveSingleFileCompressedCopy() {
        guard
            let sourceFile = loadedFiles.first,
            let measurement = compressionEstimate
        else {
            currentUIError = .compressionFailed("The measured reduced-size copy is no longer available.")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = Self.defaultCompressedFilename(for: sourceFile.url)
        savePanel.title = "Save Compressed Copy"

        guard savePanel.runModal() == .OK, let destinationURL = savePanel.url else { return }

        do {
            try copyFileReplacingExisting(from: measurement.outputURL, to: destinationURL)
            try? FileManager.default.removeItem(at: measurement.outputURL)

            finalSavedURL = destinationURL
            generatedFilename = destinationURL.lastPathComponent
            savedPageCount = sourceFile.pageCount ?? 0
            completedOperation = .compressed
            successSizeSummary = Self.compressionSummary(
                originalLabel: "Original",
                finalLabel: "New",
                measurement: measurement
            )
            successAdditionalNote = measurement.hasLittleOrNoSavings || measurement.isLargerThanOriginal
                ? "This PDF may already be optimized."
                : ""
            compressionEstimate = nil
            viewMode = .success
        } catch {
            currentUIError = .compressedCopySaveFailed
        }
    }

    func executeProductionMergePipeline() {
        guard !hasRemainingLockedFiles else {
            currentUIError = .lockedFilesRemain
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "Locally_Stitched_Document.pdf"
        savePanel.title = reduceMergedFileSize ? "Export Merged and Compressed PDF" : "Export Destination"

        guard savePanel.runModal() == .OK, let destinationURL = savePanel.url else { return }

        let targetFilesToMerge = loadedFiles
        let shouldInjectManifests = insertManifestPages
        let shouldCompressMergedOutput = reduceMergedFileSize
        let selectedLevel = compressionLevel
        let plannedPageCount = estimatedPageCount
        let mergedOutputURL: URL
        let compressedOutputURL: URL?

        do {
            if shouldCompressMergedOutput {
                mergedOutputURL = try compressionService.temporaryPDFURL(prefix: "merged-before-compression")
                compressedOutputURL = try compressionService.temporaryPDFURL(prefix: "merged-compressed")
            } else {
                mergedOutputURL = destinationURL
                compressedOutputURL = nil
            }
        } catch {
            currentUIError = .temporaryFileUnavailable
            return
        }

        finalSavedURL = destinationURL
        generatedFilename = destinationURL.lastPathComponent
        savedPageCount = plannedPageCount
        completedOperation = shouldCompressMergedOutput ? .mergedAndCompressed : .merged
        successSizeSummary = ""
        successAdditionalNote = ""
        totalFileCount = targetFilesToMerge.count
        currentFileIndex = 0
        processingPhase = .merging
        processingTitle = "Merging PDFs..."
        processingStatusLine = "File 0 of \(targetFilesToMerge.count)"
        processingProgress = 0.0
        processingSubtext = "Preparing selected PDFs..."
        processingFooterSummary = ""
        self.isCancellationRequested = false
        self.viewMode = .processing

        DispatchQueue.global(qos: .userInitiated).async {
            let mergeResult = self.buildAndWriteMergedDocument(
                targetFilesToMerge: targetFilesToMerge,
                shouldInjectManifests: shouldInjectManifests,
                destinationURL: mergedOutputURL
            )

            guard case .success(let mergedPageCount) = mergeResult else {
                if shouldCompressMergedOutput {
                    try? FileManager.default.removeItem(at: mergedOutputURL)
                    if let compressedOutputURL {
                        try? FileManager.default.removeItem(at: compressedOutputURL)
                    }
                }

                let failure: LocalStitchError
                if case .failure(let error) = mergeResult {
                    failure = error
                } else {
                    failure = .genericMergeFailure("The merge did not complete.")
                }

                DispatchQueue.main.async {
                    self.finalSavedURL = nil
                    self.processingProgress = 0.0
                    self.processingSubtext = ""
                    self.processingStatusLine = ""
                    self.processingFooterSummary = ""
                    self.isCancellationRequested = false
                    self.viewMode = .activeList
                    self.currentUIError = failure
                }
                return
            }

            if !shouldCompressMergedOutput {
                DispatchQueue.main.async {
                    self.isCancellationRequested = false
                    self.savedPageCount = mergedPageCount
                    self.processingProgress = 1.0
                    self.processingStatusLine = ""
                    self.processingSubtext = ""
                    self.processingFooterSummary = ""
                    self.completedOperation = .merged
                    self.successSizeSummary = Self.fileSizeSummary(label: "Final", bytes: PDFCompressionService.fileSize(at: destinationURL))
                    self.successAdditionalNote = ""
                    self.viewMode = .success
                }
                return
            }

            guard let compressedOutputURL else {
                DispatchQueue.main.async {
                    self.finalSavedURL = nil
                    self.processingProgress = 0.0
                    self.processingSubtext = ""
                    self.processingStatusLine = ""
                    self.processingFooterSummary = ""
                    self.isCancellationRequested = false
                    self.viewMode = .activeList
                    self.currentUIError = .temporaryFileUnavailable
                }
                return
            }

            let mergedSize = PDFCompressionService.fileSize(at: mergedOutputURL) ?? 0

            DispatchQueue.main.async {
                self.processingPhase = .compressing
                self.processingTitle = "Reducing file size..."
                self.processingStatusLine = ""
                self.processingProgress = 0.68
                self.processingSubtext = "Creating an optimized local copy of the merged PDF."
                self.processingFooterSummary = "Original merged size: \(Self.formattedFileSize(mergedSize))"
            }

            do {
                let measurement = try self.compressionService.compressedCopy(
                    from: mergedOutputURL,
                    to: compressedOutputURL,
                    password: nil,
                    level: selectedLevel,
                    shouldCancel: self.isCancellationRequestedSnapshot
                )

                let outputSourceURL: URL
                let completedOperation: CompletedPDFOperation
                let sizeSummary: String
                let additionalNote: String

                if measurement.isLargerThanOriginal {
                    outputSourceURL = mergedOutputURL
                    completedOperation = .merged
                    sizeSummary = "Merged size: \(Self.formattedFileSize(measurement.originalSizeBytes))   Compression would be larger: \(Self.formattedFileSize(measurement.compressedSizeBytes))"
                    additionalNote = "Compression made the file larger, so Local Stitch saved the merged PDF without file size reduction."
                } else {
                    outputSourceURL = compressedOutputURL
                    completedOperation = .mergedAndCompressed
                    sizeSummary = Self.compressionSummary(
                        originalLabel: "Merged size",
                        finalLabel: "Final",
                        measurement: measurement
                    )
                    additionalNote = measurement.hasLittleOrNoSavings
                        ? "Little or no reduction. This merged PDF may already be optimized."
                        : ""
                }

                try self.copyFileReplacingExisting(from: outputSourceURL, to: destinationURL)

                try? FileManager.default.removeItem(at: mergedOutputURL)
                try? FileManager.default.removeItem(at: compressedOutputURL)

                DispatchQueue.main.async {
                    self.isCancellationRequested = false
                    self.savedPageCount = mergedPageCount
                    self.processingProgress = 1.0
                    self.processingStatusLine = ""
                    self.processingSubtext = ""
                    self.processingFooterSummary = ""
                    self.completedOperation = completedOperation
                    self.successSizeSummary = sizeSummary
                    self.successAdditionalNote = additionalNote
                    self.viewMode = .success
                }
            } catch let error as LocalStitchError {
                try? FileManager.default.removeItem(at: mergedOutputURL)
                try? FileManager.default.removeItem(at: compressedOutputURL)

                DispatchQueue.main.async {
                    self.finalSavedURL = nil
                    self.processingProgress = 0.0
                    self.processingSubtext = ""
                    self.processingStatusLine = ""
                    self.processingFooterSummary = ""
                    self.viewMode = .activeList
                    self.isCancellationRequested = false

                    if case .compressionCancelled = error {
                        self.currentUIError = .mergeCancelled
                    } else {
                        self.currentUIError = error
                    }
                }
            } catch {
                try? FileManager.default.removeItem(at: mergedOutputURL)
                try? FileManager.default.removeItem(at: compressedOutputURL)

                DispatchQueue.main.async {
                    self.finalSavedURL = nil
                    self.processingProgress = 0.0
                    self.processingSubtext = ""
                    self.processingStatusLine = ""
                    self.processingFooterSummary = ""
                    self.viewMode = .activeList
                    self.isCancellationRequested = false
                    self.currentUIError = .compressionFailed(error.localizedDescription)
                }
            }
        }
    }

    private func buildAndWriteMergedDocument(
        targetFilesToMerge: [PDFFile],
        shouldInjectManifests: Bool,
        destinationURL: URL
    ) -> Result<Int, LocalStitchError> {
        let masterDocument = PDFDocument()
        var manifestMetadataByID: [UUID: PDFManifestMetadata] = [:]

        if shouldInjectManifests {
            DispatchQueue.main.async {
                self.processingSubtext = "Computing original-file fingerprints and document context..."
            }

            var nextOutputPage = 2
            for (index, targetFile) in targetFilesToMerge.enumerated() {
                if isCancellationRequestedSnapshot() {
                    return .failure(.mergeCancelled)
                }

                guard let currentDoc = PDFDocument(url: targetFile.url) else {
                    return .failure(.corruptedFile(targetFile.name))
                }

                if targetFile.isLocked && !currentDoc.unlock(withPassword: targetFile.cachedPassword) {
                    return .failure(.lockedFilesRemain)
                }

                let outputStart = nextOutputPage + 1
                let outputEnd = outputStart + currentDoc.pageCount - 1

                guard let manifestMetadata = buildManifestMetadata(
                    for: targetFile,
                    document: currentDoc,
                    sourceIndex: index + 1,
                    sourceCount: targetFilesToMerge.count,
                    outputPageStart: outputStart,
                    outputPageEnd: outputEnd
                ) else {
                    return .failure(isCancellationRequestedSnapshot() ? .mergeCancelled : .genericMergeFailure("Source summary pages could not be created."))
                }

                manifestMetadataByID[targetFile.id] = manifestMetadata
                nextOutputPage = outputEnd + 1
            }

            let manifestDocuments = targetFilesToMerge.compactMap { manifestMetadataByID[$0.id] }
            let compilationMetadata = CompilationManifestMetadata(
                createdAt: Date(),
                appVersion: appVersionForManifest(),
                sourceCount: targetFilesToMerge.count,
                originalPageCount: manifestDocuments.reduce(0) { $0 + $1.originalPageCount },
                outputPageCount: manifestDocuments.reduce(0) { $0 + $1.originalPageCount } + manifestDocuments.count + 1,
                manifestPageCount: manifestDocuments.count + 1,
                documents: manifestDocuments
            )
            masterDocument.insert(CompilationManifestPage(metadata: compilationMetadata), at: masterDocument.pageCount)
        }

        for (index, targetFile) in targetFilesToMerge.enumerated() {
            guard case .processing = currentViewModeSnapshot(), !isCancellationRequestedSnapshot() else {
                return .failure(.mergeCancelled)
            }

            DispatchQueue.main.async {
                self.currentFileIndex = index + 1
                self.processingStatusLine = "File \(index + 1) of \(targetFilesToMerge.count)"
                self.processingProgress = Double(index) / Double(max(targetFilesToMerge.count, 1))
                self.processingSubtext = "Stitching and structural alignment for '\(targetFile.name)'..."
            }

            let fileError = autoreleasepool { () -> LocalStitchError? in
                guard let currentDoc = PDFDocument(url: targetFile.url) else {
                    return .corruptedFile(targetFile.name)
                }

                if targetFile.isLocked && !currentDoc.unlock(withPassword: targetFile.cachedPassword) {
                    return .lockedFilesRemain
                }

                if shouldInjectManifests {
                    DispatchQueue.main.async {
                        self.processingSubtext = "Adding document context and integrity manifest..."
                    }

                    if let manifestMetadata = manifestMetadataByID[targetFile.id] {
                        let manifestSheet = ManifestPage(metadata: manifestMetadata)
                        masterDocument.insert(manifestSheet, at: masterDocument.pageCount)
                    }
                }

                for pageIndex in 0..<currentDoc.pageCount {
                    if isCancellationRequestedSnapshot() {
                        return .mergeCancelled
                    }

                    if let extractedPage = currentDoc.page(at: pageIndex) {
                        masterDocument.insert(extractedPage, at: masterDocument.pageCount)
                    }
                }

                return nil
            }

            if let fileError {
                return .failure(fileError)
            }
        }

        if isCancellationRequestedSnapshot() {
            return .failure(.mergeCancelled)
        }

        let didWriteMergedDocument = masterDocument.write(to: destinationURL)
        let wasCancelledAfterWrite = isCancellationRequestedSnapshot()

        if didWriteMergedDocument && wasCancelledAfterWrite {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        if wasCancelledAfterWrite {
            return .failure(.mergeCancelled)
        }

        guard didWriteMergedDocument else {
            return .failure(.writePermissionDenied)
        }

        return .success(masterDocument.pageCount)
    }

    private func copyFileReplacingExisting(from sourceURL: URL, to destinationURL: URL) throws {
        guard FileManager.default.fileExists(atPath: destinationURL.path) else {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return
        }

        let stagedURL = destinationURL
            .deletingLastPathComponent()
            .appendingPathComponent(".LocalStitch-\(UUID().uuidString).pdf")
        defer {
            try? FileManager.default.removeItem(at: stagedURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: stagedURL)
        _ = try FileManager.default.replaceItemAt(destinationURL, withItemAt: stagedURL)
    }

    private func clearCompressionEstimate() {
        if let compressionEstimate {
            try? FileManager.default.removeItem(at: compressionEstimate.outputURL)
        }

        compressionEstimate = nil
        activeCompressionRequestID = nil
    }

    func cancelMerge() {
        guard viewMode == .processing else { return }
        isCancellationRequested = true
        switch processingPhase {
        case .estimatingCompression:
            processingTitle = "Cancelling estimate..."
        case .merging:
            processingTitle = "Cancelling merge..."
        case .compressing:
            processingTitle = "Cancelling compression..."
        }
        processingSubtext = "Stopping after the current PDF operation..."
    }

    func cancelProcessing() {
        cancelMerge()
    }

    func removeFile(_ file: PDFFile) {
        if let index = loadedFiles.firstIndex(of: file) {
            clearCompressionEstimate()
            loadedFiles.remove(at: index)
            passwordUnlockMessage = ""
            reduceSingleFileSize = loadedFiles.count <= 1

            if loadedFiles.isEmpty {
                viewMode = .empty
            }
        }
    }

    func moveFiles(fromOffsets indices: IndexSet, toOffset newOffset: Int) {
        clearCompressionEstimate()

        let movingFiles = indices.sorted().map { loadedFiles[$0] }
        for index in indices.sorted(by: >) {
            loadedFiles.remove(at: index)
        }

        let removedBeforeDestination = indices.filter { $0 < newOffset }.count
        let adjustedOffset = max(0, min(newOffset - removedBeforeDestination, loadedFiles.count))
        loadedFiles.insert(contentsOf: movingFiles, at: adjustedOffset)
    }

    func resetForNewMerge() {
        clearCompressionEstimate()
        loadedFiles.removeAll()
        insertManifestPages = false
        reduceSingleFileSize = true
        reduceMergedFileSize = false
        compressionLevel = .balanced
        globalPasswordInput = ""
        passwordUnlockMessage = ""
        processingSubtext = ""
        processingStatusLine = ""
        processingFooterSummary = ""
        generatedFilename = ""
        savedPageCount = 0
        successSizeSummary = ""
        successAdditionalNote = ""
        finalSavedURL = nil
        isCancellationRequested = false
        viewMode = .empty
    }

    /// Opens the exact parent directory and highlights the merged document natively
    func openOutputLocation() {
        if let targetURL = finalSavedURL {
            // Tells Finder to open the custom directory and select the specific file path element
            NSWorkspace.shared.activateFileViewerSelecting([targetURL])
        } else {
            // Safe fallback defaults to system profile if a path execution state isn't registered yet
            if let defaultFallbackURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                NSWorkspace.shared.open(defaultFallbackURL)
            }
        }
    }

    /// Processes paths captured from system drag-and-drop events
    func handleDroppedURLs(_ urls: [URL]) {
        Logger.engine.info("Successfully received \(urls.count) drop targets.")
        addPDFURLs(urls)
    }

    static func formattedFileSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    static func defaultCompressedFilename(for sourceURL: URL) -> String {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        return "\(baseName)_compressed.pdf"
    }

    static func fileSizeSummary(label: String, bytes: UInt64?) -> String {
        guard let bytes else { return "" }
        return "\(label): \(formattedFileSize(bytes))"
    }

    static func compressionSummary(
        originalLabel: String,
        finalLabel: String,
        measurement: PDFCompressionMeasurement
    ) -> String {
        if measurement.isLargerThanOriginal {
            return "\(originalLabel): \(formattedFileSize(measurement.originalSizeBytes))   \(finalLabel): \(formattedFileSize(measurement.compressedSizeBytes))   Larger than original"
        }

        if measurement.hasLittleOrNoSavings {
            return "\(originalLabel): \(formattedFileSize(measurement.originalSizeBytes))   \(finalLabel): \(formattedFileSize(measurement.compressedSizeBytes))   Little or no reduction"
        }

        return "\(originalLabel): \(formattedFileSize(measurement.originalSizeBytes))   \(finalLabel): \(formattedFileSize(measurement.compressedSizeBytes))   Saved: \(measurement.percentSaved)%"
    }

    private func buildManifestMetadata(
        for file: PDFFile,
        document: PDFDocument,
        sourceIndex: Int,
        sourceCount: Int,
        outputPageStart: Int,
        outputPageEnd: Int
    ) -> PDFManifestMetadata? {
        let systemAttributes = try? FileManager.default.attributesOfItem(atPath: file.url.path)
        let createdDate = systemAttributes?[.creationDate] as? Date ?? Date()
        let modifiedDate = systemAttributes?[.modificationDate] as? Date ?? Date()
        let fileSize = (systemAttributes?[.size] as? NSNumber)?.uint64Value ?? 0
        let metadataDictionary = document.documentAttributes
        guard let sha256 = calculateSHA256Hash(at: file.url, shouldCancel: isCancellationRequestedSnapshot) else {
            return nil
        }

        if isCancellationRequestedSnapshot() {
            return nil
        }

        return PDFManifestMetadata(
            filename: file.name,
            sourceIndex: sourceIndex,
            sourceCount: sourceCount,
            originalPageCount: document.pageCount,
            outputPageStart: outputPageStart,
            outputPageEnd: outputPageEnd,
            fileSizeBytes: fileSize,
            fileCreated: createdDate,
            fileModified: modifiedDate,
            sha256: sha256,
            title: pdfStringAttribute(.titleAttribute, from: metadataDictionary),
            author: pdfStringAttribute(.authorAttribute, from: metadataDictionary),
            subject: pdfStringAttribute(.subjectAttribute, from: metadataDictionary),
            keywords: pdfStringAttribute(.keywordsAttribute, from: metadataDictionary),
            creator: pdfStringAttribute(.creatorAttribute, from: metadataDictionary),
            producer: pdfStringAttribute(.producerAttribute, from: metadataDictionary),
            pdfCreated: metadataDictionary?[PDFDocumentAttribute.creationDateAttribute] as? Date,
            pdfModified: metadataDictionary?[PDFDocumentAttribute.modificationDateAttribute] as? Date,
            isEncrypted: file.isLocked,
            wasUnlockedForMerge: !file.isLocked || file.isUnlockedSuccessfully,
            hasAnnotations: documentHasAnnotations(document, shouldCancel: isCancellationRequestedSnapshot),
            hasForms: documentHasForms(document, shouldCancel: isCancellationRequestedSnapshot),
            hasBookmarks: (document.outlineRoot?.numberOfChildren ?? 0) > 0,
            pageProfile: pageProfile(for: document, shouldCancel: isCancellationRequestedSnapshot)
        )
    }

    private func pdfStringAttribute(_ key: PDFDocumentAttribute, from attributes: [AnyHashable: Any]?) -> String {
        guard let value = attributes?[key] else { return "Unknown" }

        if let stringValue = value as? String, !stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return stringValue
        }

        if let arrayValue = value as? [String], !arrayValue.isEmpty {
            return arrayValue.joined(separator: ", ")
        }

        return "\(value)"
    }

    private func documentHasAnnotations(_ document: PDFDocument, shouldCancel: () -> Bool) -> Bool {
        for pageIndex in 0..<document.pageCount {
            if shouldCancel() { return false }

            if let page = document.page(at: pageIndex), !page.annotations.isEmpty {
                return true
            }
        }

        return false
    }

    private func documentHasForms(_ document: PDFDocument, shouldCancel: () -> Bool) -> Bool {
        for pageIndex in 0..<document.pageCount {
            if shouldCancel() { return false }

            guard let page = document.page(at: pageIndex) else { continue }

            if page.annotations.contains(where: { $0.type == "Widget" }) {
                return true
            }
        }

        return false
    }

    private func pageProfile(for document: PDFDocument, shouldCancel: () -> Bool) -> String {
        var profiles = Set<String>()

        for pageIndex in 0..<document.pageCount {
            if shouldCancel() { return "Cancelled" }

            guard let page = document.page(at: pageIndex) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            let width = Int(bounds.width.rounded())
            let height = Int(bounds.height.rounded())
            profiles.insert("\(width)x\(height)pt rotation \(page.rotation)")

            if profiles.count > 3 {
                return "Mixed page sizes/rotations"
            }
        }

        if profiles.isEmpty {
            return "Unknown"
        }

        return profiles.sorted().joined(separator: "; ")
    }

    private func appVersionForManifest() -> String {
        guard
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            !version.isEmpty
        else {
            return "1.0"
        }

        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, !build.isEmpty {
            return "\(version) (\(build))"
        }

        return version
    }

    private func calculateSHA256Hash(at fileURL: URL, shouldCancel: () -> Bool = { false }) -> String? {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return "Reading Error" }
        defer {
            try? fileHandle.close()
        }

        var hasher = SHA256()

        while true {
            if shouldCancel() { return nil }

            do {
                guard let chunk = try fileHandle.read(upToCount: 1024 * 1024), !chunk.isEmpty else {
                    break
                }
                hasher.update(data: chunk)
            } catch {
                return "Reading Error"
            }
        }

        let digest = hasher.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func currentViewModeSnapshot() -> AppViewMode {
        if Thread.isMainThread {
            return viewMode
        }

        return DispatchQueue.main.sync { viewMode }
    }

    private func isCancellationRequestedSnapshot() -> Bool {
        if Thread.isMainThread {
            return isCancellationRequested
        }

        return DispatchQueue.main.sync { isCancellationRequested }
    }

}

enum LocalStitchError: LocalizedError, Identifiable {
    case compressedCopySaveFailed
    case compressionCancelled
    case compressionFailed(String)
    case corruptedFile(String)
    case fileLimitReached(Int)
    case importSummary(String, UUID)
    case lockedFilesRemain
    case mergeCancelled
    case temporaryFileUnavailable
    case unsupportedFile(String)
    case writePermissionDenied
    case genericMergeFailure(String)

    var id: String {
        switch self {
        case .importSummary(_, let id):
            return id.uuidString
        default:
            return errorDescription ?? "unknown"
        }
    }

    var errorDescription: String? {
        switch self {
        case .compressedCopySaveFailed:
            return "The reduced-size PDF could not be saved to that location. Choose another folder and try again."
        case .compressionCancelled:
            return "File size reduction was cancelled. Your original PDFs were not changed."
        case .compressionFailed(let message):
            return "Local Stitch could not reduce the PDF file size. \(message)"
        case .corruptedFile(let fileName):
            return "The file '\(fileName)' appears to be corrupted or isn't a structured PDF document."
        case .fileLimitReached(let limit):
            return "Local Stitch can process up to \(limit) PDFs at a time. Remove some files before adding more."
        case .importSummary(let message, _):
            return message
        case .lockedFilesRemain:
            return "Unlock every password-protected PDF before continuing."
        case .mergeCancelled:
            return "The operation was cancelled. Your original PDFs were not changed."
        case .temporaryFileUnavailable:
            return "Local Stitch could not create a temporary local PDF for this operation."
        case .unsupportedFile(let fileName):
            return "'\(fileName)' is not a PDF file."
        case .writePermissionDenied:
            return "The PDF could not be saved to that location. Choose another folder and try again."
        case .genericMergeFailure(let message):
            return "An unexpected error occurred during execution: \(message)"
        }
    }
}

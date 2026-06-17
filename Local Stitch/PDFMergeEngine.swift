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
    var isLocked: Bool
    var isUnlockedSuccessfully: Bool = false
    var cachedPassword: String = ""
}

enum AppViewMode {
    case empty
    case activeList
    case processing
    case success
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
    @Published var globalPasswordInput = ""
    
    @Published var processingProgress: Double = 0.0
    @Published var currentFileIndex: Int = 0
    @Published var totalFileCount: Int = 0
    @Published var processingSubtext: String = ""
    @Published var generatedFilename: String = ""
    @Published var passwordUnlockMessage: String = ""
    
    // Tracks the exact system storage path chosen by the user
    private var finalSavedURL: URL? = nil
    
    var estimatedPageCount: Int {
        let basePages = loadedFiles.compactMap { $0.pageCount }.reduce(0, +)
        let overhead = insertManifestPages && !loadedFiles.isEmpty ? loadedFiles.count + 1 : 0
        return basePages + overhead
    }
    
    var hasRemainingLockedFiles: Bool {
        loadedFiles.contains(where: { $0.isLocked && !$0.isUnlockedSuccessfully })
    }
    
    var remainingLockedFileCount: Int {
        loadedFiles.filter { $0.isLocked && !$0.isUnlockedSuccessfully }.count
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
        
        var unlockedCount = 0
        
        for index in loadedFiles.indices where loadedFiles[index].isLocked && !loadedFiles[index].isUnlockedSuccessfully {
            if let pdfDocument = PDFDocument(url: loadedFiles[index].url), pdfDocument.unlock(withPassword: password) {
                loadedFiles[index].isUnlockedSuccessfully = true
                loadedFiles[index].cachedPassword = password
                loadedFiles[index].pageCount = pdfDocument.pageCount
                unlockedCount += 1
            }
        }
        
        let remainingCount = remainingLockedFileCount
        if remainingCount == 0 {
            passwordUnlockMessage = "All protected files are unlocked."
        } else if unlockedCount == 0 {
            passwordUnlockMessage = "That password did not unlock any remaining files."
        } else {
            passwordUnlockMessage = "Unlocked \(unlockedCount) file\(unlockedCount == 1 ? "" : "s"). \(remainingCount) still locked."
        }
        
        globalPasswordInput = ""
    }
    
    private func inspectPDFFile(at url: URL) -> Result<PDFFile, LocalStitchError> {
        guard url.pathExtension.lowercased() == "pdf" else {
            return .failure(.unsupportedFile(url.lastPathComponent))
        }
        
        guard let pdfDocument = PDFDocument(url: url) else {
            Logger.engine.error("Failed to parse PDF document structure for: \(url.lastPathComponent). File may be corrupted.")
            return .failure(.corruptedFile(url.lastPathComponent))
        }
        
        let fileIsEncrypted = pdfDocument.isLocked
        if fileIsEncrypted {
            Logger.engine.warning("Added password-protected file awaiting unlock: \(url.lastPathComponent)")
        }
        
        return .success(PDFFile(
            url: url,
            pageCount: fileIsEncrypted ? nil : pdfDocument.pageCount,
            isLocked: fileIsEncrypted
        ))
    }
    
    private func addPDFURLs(_ urls: [URL]) {
        let remainingSlots = max(0, 100 - loadedFiles.count)
        let urlsToInspect = Array(urls.prefix(remainingSlots))
        guard !urlsToInspect.isEmpty else { return }
        
        Logger.engine.info("Inspecting \(urlsToInspect.count) PDF candidates.")
        
        DispatchQueue.global(qos: .userInitiated).async {
            var newlyAddedFiles: [PDFFile] = []
            var firstError: LocalStitchError?
            
            for url in urlsToInspect {
                switch self.inspectPDFFile(at: url) {
                case .success(let file):
                    newlyAddedFiles.append(file)
                case .failure(let error):
                    if firstError == nil {
                        firstError = error
                    }
                }
            }
            
            DispatchQueue.main.async {
                if !newlyAddedFiles.isEmpty {
                    self.loadedFiles.append(contentsOf: newlyAddedFiles)
                    self.passwordUnlockMessage = ""
                    self.viewMode = .activeList
                }
                
                if let firstError {
                    self.currentUIError = firstError
                }
            }
        }
    }
    
    func executeProductionMergePipeline() {
        guard !hasRemainingLockedFiles else {
            currentUIError = .lockedFilesRemain
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "Merged_Document.pdf"
        savePanel.title = "Export Destination"
        
        guard savePanel.runModal() == .OK, let destinationURL = savePanel.url else { return }
        
        // Retain the URL path state locally for the Finder reveal action later
        self.finalSavedURL = destinationURL
        self.generatedFilename = savePanel.nameFieldStringValue
        self.totalFileCount = loadedFiles.count
        self.currentFileIndex = 0
        self.processingProgress = 0.0
        self.viewMode = .processing
        
        let targetFilesToMerge = loadedFiles
        let shouldInjectManifests = insertManifestPages
        
        DispatchQueue.global(qos: .userInitiated).async {
            let masterDocument = PDFDocument()
            var didAbortMerge = false
            var manifestMetadataByID: [UUID: PDFManifestMetadata] = [:]
            
            if shouldInjectManifests {
                DispatchQueue.main.async {
                    self.processingSubtext = "Computing original-file fingerprints and document context..."
                }
                
                var nextOutputPage = 2
                for (index, targetFile) in targetFilesToMerge.enumerated() {
                    guard let currentDoc = PDFDocument(url: targetFile.url) else { continue }
                    
                    if targetFile.isLocked && !currentDoc.unlock(withPassword: targetFile.cachedPassword) {
                        didAbortMerge = true
                        DispatchQueue.main.async {
                            self.finalSavedURL = nil
                            self.processingProgress = 0.0
                            self.viewMode = .activeList
                            self.currentUIError = .lockedFilesRemain
                        }
                        break
                    }
                    
                    let outputStart = nextOutputPage + 1
                    let outputEnd = outputStart + currentDoc.pageCount - 1
                    
                    manifestMetadataByID[targetFile.id] = self.buildManifestMetadata(
                        for: targetFile,
                        document: currentDoc,
                        sourceIndex: index + 1,
                        sourceCount: targetFilesToMerge.count,
                        outputPageStart: outputStart,
                        outputPageEnd: outputEnd
                    )
                    
                    nextOutputPage = outputEnd + 1
                }
                
                if !didAbortMerge {
                    let manifestDocuments = targetFilesToMerge.compactMap { manifestMetadataByID[$0.id] }
                    let compilationMetadata = CompilationManifestMetadata(
                        createdAt: Date(),
                        appVersion: self.appVersionForManifest(),
                        sourceCount: targetFilesToMerge.count,
                        originalPageCount: manifestDocuments.reduce(0) { $0 + $1.originalPageCount },
                        outputPageCount: manifestDocuments.reduce(0) { $0 + $1.originalPageCount } + manifestDocuments.count + 1,
                        manifestPageCount: manifestDocuments.count + 1,
                        documents: manifestDocuments
                    )
                    masterDocument.insert(CompilationManifestPage(metadata: compilationMetadata), at: masterDocument.pageCount)
                }
            }
            
            for (index, targetFile) in targetFilesToMerge.enumerated() {
                if didAbortMerge { break }
                
                guard case .processing = DispatchQueue.main.sync(execute: { self.viewMode }) else { return }
                
                DispatchQueue.main.async {
                    self.currentFileIndex = index + 1
                    self.processingProgress = Double(index) / Double(targetFilesToMerge.count)
                    self.processingSubtext = "Stitching and structural alignment for '\(targetFile.name)'..."
                }
                
                autoreleasepool {
                    guard let currentDoc = PDFDocument(url: targetFile.url) else { return }
                    
                    if targetFile.isLocked && !currentDoc.unlock(withPassword: targetFile.cachedPassword) {
                        didAbortMerge = true
                        DispatchQueue.main.async {
                            self.finalSavedURL = nil
                            self.processingProgress = 0.0
                            self.viewMode = .activeList
                            self.currentUIError = .lockedFilesRemain
                        }
                        return
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
                        if let extractedPage = currentDoc.page(at: pageIndex) {
                            masterDocument.insert(extractedPage, at: masterDocument.pageCount)
                        }
                    }
                }
            }
            
            if didAbortMerge { return }
            
            let didWriteMergedDocument = masterDocument.write(to: destinationURL)
            
            DispatchQueue.main.async {
                if didWriteMergedDocument {
                    self.processingProgress = 1.0
                    self.viewMode = .success
                } else {
                    self.finalSavedURL = nil
                    self.processingProgress = 0.0
                    self.viewMode = .activeList
                    self.currentUIError = .writePermissionDenied
                }
            }
        }
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
    
    private func buildManifestMetadata(
        for file: PDFFile,
        document: PDFDocument,
        sourceIndex: Int,
        sourceCount: Int,
        outputPageStart: Int,
        outputPageEnd: Int
    ) -> PDFManifestMetadata {
        let systemAttributes = try? FileManager.default.attributesOfItem(atPath: file.url.path)
        let createdDate = systemAttributes?[.creationDate] as? Date ?? Date()
        let modifiedDate = systemAttributes?[.modificationDate] as? Date ?? Date()
        let fileSize = (systemAttributes?[.size] as? NSNumber)?.uint64Value ?? 0
        let metadataDictionary = document.documentAttributes
        
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
            sha256: calculateSHA256Hash(at: file.url),
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
            hasAnnotations: documentHasAnnotations(document),
            hasForms: documentHasForms(document),
            hasBookmarks: (document.outlineRoot?.numberOfChildren ?? 0) > 0,
            pageProfile: pageProfile(for: document)
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
    
    private func documentHasAnnotations(_ document: PDFDocument) -> Bool {
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex), !page.annotations.isEmpty {
                return true
            }
        }
        
        return false
    }
    
    private func documentHasForms(_ document: PDFDocument) -> Bool {
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            if page.annotations.contains(where: { $0.type == "Widget" }) {
                return true
            }
        }
        
        return false
    }
    
    private func pageProfile(for document: PDFDocument) -> String {
        var profiles = Set<String>()
        
        for pageIndex in 0..<document.pageCount {
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
    
    private func calculateSHA256Hash(at fileURL: URL) -> String {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return "Reading Error" }
        defer {
            try? fileHandle.close()
        }
        
        var hasher = SHA256()
        
        while true {
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
    
}

enum LocalStitchError: LocalizedError, Identifiable {
    case corruptedFile(String)
    case lockedFilesRemain
    case unsupportedFile(String)
    case writePermissionDenied
    case genericMergeFailure(String)
    
    var id: String { errorDescription ?? "unknown" }
    
    var errorDescription: String? {
        switch self {
        case .corruptedFile(let fileName):
            return "The file '\(fileName)' appears to be corrupted or isn't a structured PDF document."
        case .lockedFilesRemain:
            return "Unlock every password-protected PDF before merging."
        case .unsupportedFile(let fileName):
            return "'\(fileName)' is not a PDF file."
        case .writePermissionDenied:
            return "Local Stitch doesn't have permission to write to your chosen directory. Check your Mac Sandbox file access rules."
        case .genericMergeFailure(let message):
            return "An unexpected error occurred during execution: \(message)"
        }
    }
}

import Foundation
import PDFKit
import CryptoKit
import UniformTypeIdentifiers
import AppKit
import Combine

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
class ManifestPage: PDFPage {
    let filename: String
    let index: Int
    let total: Int
    let created: Date
    let modified: Date
    let pages: Int
    let software: String
    let author: String
    let shaSignature: String
    
    init(filename: String, index: Int, total: Int, created: Date, modified: Date, pages: Int, software: String, author: String, shaSignature: String) {
        self.filename = filename
        self.index = index
        self.total = total
        self.created = created
        self.modified = modified
        self.pages = pages
        self.software = software
        self.author = author
        self.shaSignature = shaSignature
        super.init()
    }
    
    override func bounds(for box: PDFDisplayBox) -> NSRect {
        return NSRect(x: 0, y: 0, width: 612, height: 792)
    }
    
    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        super.draw(with: box, to: context)
        
        let nsGraphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        let previousContext = NSGraphicsContext.current
        NSGraphicsContext.current = nsGraphicsContext
        
        let letterWidth: CGFloat = 612
        let letterHeight: CGFloat = 792
        let horizontalMarginInset: CGFloat = 54
        var internalDrawingCursorY: CGFloat = letterHeight - 60
        
        let dateFormattingService = DateFormatter()
        dateFormattingService.dateStyle = .medium
        dateFormattingService.timeStyle = .short
        
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
            let maxBoundaryWidth = letterWidth - (horizontalMarginInset * 2)
            
            let boundingFrameSize = printString.boundingRect(
                with: CGSize(width: maxBoundaryWidth, height: .infinity),
                options: [.usesLineFragmentOrigin, .usesFontLeading]
            )
            
            internalDrawingCursorY -= boundingFrameSize.height
            let paintBox = CGRect(
                x: horizontalMarginInset,
                y: internalDrawingCursorY,
                width: maxBoundaryWidth,
                height: boundingFrameSize.height
            )
            printString.draw(in: paintBox)
            internalDrawingCursorY -= 12
        }
        
        renderTextRow("=========================================================================", NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), NSColor.disabledControlTextColor)
        renderTextRow("SOURCE DOCUMENT CONTEXT MANIFEST CARD (AI INFRASTRUCTURE OPTIMIZED)", NSFont.systemFont(ofSize: 11, weight: .bold), NSColor.labelColor)
        renderTextRow("=========================================================================", NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), NSColor.disabledControlTextColor)
        internalDrawingCursorY -= 16
        
        renderTextRow(filename, NSFont.systemFont(ofSize: 36, weight: .bold), NSColor.labelColor)
        internalDrawingCursorY -= 16
        
        renderTextRow("COMPILATION ALIGNMENT SEQUENCE TRACKING:", NSFont.systemFont(ofSize: 11, weight: .semibold), NSColor.secondaryLabelColor)
        renderTextRow("Document \(index) of \(total) in target merge configuration.", NSFont.systemFont(ofSize: 13, weight: .regular), NSColor.labelColor)
        internalDrawingCursorY -= 10
        
        renderTextRow("TEMPORAL PROFILE ARCHIVE DATE TIMESTAMPS:", NSFont.systemFont(ofSize: 11, weight: .semibold), NSColor.secondaryLabelColor)
        renderTextRow("• System Initial Creation Timestamp:  \(dateFormattingService.string(from: created))", NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), NSColor.labelColor)
        renderTextRow("• System Last Modification Timestamp: \(dateFormattingService.string(from: modified))", NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), NSColor.labelColor)
        internalDrawingCursorY -= 10
        
        renderTextRow("STRUCTURAL METADATA BOUNDARIES FOOTPRINT:", NSFont.systemFont(ofSize: 11, weight: .semibold), NSColor.secondaryLabelColor)
        renderTextRow("Original Unaltered Source Document Size: \(pages) Pages.", NSFont.systemFont(ofSize: 13, weight: .regular), NSColor.labelColor)
        internalDrawingCursorY -= 10
        
        renderTextRow("PROVENANCE SYSTEM SOURCE METADATA IDENTIFIERS:", NSFont.systemFont(ofSize: 11, weight: .semibold), NSColor.secondaryLabelColor)
        renderTextRow("• Document Original Creator Application: \(software)", NSFont.systemFont(ofSize: 12, weight: .regular), NSColor.labelColor)
        renderTextRow("• Assigned File Author Attribute: \(author)", NSFont.systemFont(ofSize: 12, weight: .regular), NSColor.labelColor)
        internalDrawingCursorY -= 10
        
        renderTextRow("INTEGRITY FINGERPRINT AUDIT HASH (SHA-256):", NSFont.systemFont(ofSize: 11, weight: .semibold), NSColor.secondaryLabelColor)
        renderTextRow(shaSignature, NSFont.monospacedSystemFont(ofSize: 11, weight: .medium), NSColor.labelColor)
        internalDrawingCursorY -= 10
        
        renderTextRow("=========================================================================", NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), NSColor.disabledControlTextColor)
        
        NSGraphicsContext.current = previousContext
    }
}

// MARK: - 3. STORAGE CONTROLLER PIPELINE (VIEW MODEL)
class PDFMergeEngine: ObservableObject {
    
    @Published var loadedFiles: [PDFFile] = []
    @Published var viewMode: AppViewMode = .empty
    @Published var insertManifestPages = false
    @Published var globalPasswordInput = ""
    
    @Published var processingProgress: Double = 0.0
    @Published var currentFileIndex: Int = 0
    @Published var totalFileCount: Int = 0
    @Published var processingSubtext: String = ""
    @Published var generatedFilename: String = ""
    
    // Tracks the exact system storage path chosen by the user
    private var finalSavedURL: URL? = nil
    
    var estimatedPageCount: Int {
        let basePages = loadedFiles.compactMap { $0.pageCount }.reduce(0, +)
        let overhead = insertManifestPages ? loadedFiles.count : 0
        return basePages + overhead
    }
    
    var hasRemainingLockedFiles: Bool {
        loadedFiles.contains(where: { $0.isLocked && !$0.isUnlockedSuccessfully })
    }
    
    func selectLocalFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        
        if panel.runModal() == .OK {
            var newlyAddedFiles: [PDFFile] = []
            for url in panel.urls {
                if (loadedFiles.count + newlyAddedFiles.count) >= 100 { break }
                
                if let pdfDocument = PDFDocument(url: url) {
                    let fileIsEncrypted = pdfDocument.isLocked
                    let pageCount = fileIsEncrypted ? nil : pdfDocument.pageCount
                    
                    let discoveredFile = PDFFile(
                        url: url,
                        pageCount: pageCount,
                        isLocked: fileIsEncrypted
                    )
                    newlyAddedFiles.append(discoveredFile)
                }
            }
            loadedFiles.append(contentsOf: newlyAddedFiles)
            if !loadedFiles.isEmpty { viewMode = .activeList }
        }
    }
    
    func checkPasswordUnlock() {
        for index in loadedFiles.indices {
            if loadedFiles[index].isLocked && !loadedFiles[index].isUnlockedSuccessfully {
                if let pdfDocument = PDFDocument(url: loadedFiles[index].url) {
                    if pdfDocument.unlock(withPassword: globalPasswordInput) {
                        loadedFiles[index].isUnlockedSuccessfully = true
                        loadedFiles[index].cachedPassword = globalPasswordInput
                        loadedFiles[index].pageCount = pdfDocument.pageCount
                    }
                }
            }
        }
        globalPasswordInput = ""
    }
    
    func executeProductionMergePipeline() {
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
            
            for (index, targetFile) in targetFilesToMerge.enumerated() {
                guard case .processing = DispatchQueue.main.sync(execute: { self.viewMode }) else { return }
                
                DispatchQueue.main.async {
                    self.currentFileIndex = index + 1
                    self.processingProgress = Double(index) / Double(targetFilesToMerge.count)
                    self.processingSubtext = "Stitching and structural alignment for '\(targetFile.name)'..."
                }
                
                autoreleasepool {
                    guard let currentDoc = PDFDocument(url: targetFile.url) else { return }
                    
                    if targetFile.isLocked {
                        _ = currentDoc.unlock(withPassword: targetFile.cachedPassword)
                    }
                    
                    if shouldInjectManifests {
                        DispatchQueue.main.async {
                            self.processingSubtext = "Computing SHA-256 digital fingerprint and building context card..."
                        }
                        
                        let fingerprint = self.calculateSHA256Hash(at: targetFile.url)
                        let systemAttributes = try? FileManager.default.attributesOfItem(atPath: targetFile.url.path)
                        let createdDate = systemAttributes?[.creationDate] as? Date ?? Date()
                        let modifiedDate = systemAttributes?[.modificationDate] as? Date ?? Date()
                        
                        let metadataDictionary = currentDoc.documentAttributes
                        let creatorSoftware = metadataDictionary?[PDFDocumentAttribute.creatorAttribute] as? String ?? "Unknown System Application"
                        let fileAuthor = metadataDictionary?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unspecified Author"
                        
                        let manifestSheet = ManifestPage(
                            filename: targetFile.name,
                            index: index + 1,
                            total: targetFilesToMerge.count,
                            created: createdDate,
                            modified: modifiedDate,
                            pages: currentDoc.pageCount,
                            software: creatorSoftware,
                            author: fileAuthor,
                            shaSignature: fingerprint
                        )
                        masterDocument.insert(manifestSheet, at: masterDocument.pageCount)
                    }
                    
                    for pageIndex in 0..<currentDoc.pageCount {
                        if let extractedPage = currentDoc.page(at: pageIndex) {
                            masterDocument.insert(extractedPage, at: masterDocument.pageCount)
                        }
                    }
                }
            }
            
            masterDocument.write(to: destinationURL)
            
            DispatchQueue.main.async {
                self.processingProgress = 1.0
                self.viewMode = .success
            }
        }
    }
    
    private func calculateSHA256Hash(at fileURL: URL) -> String {
        guard let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe) else { return "Reading Error" }
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
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
        var newlyAddedFiles: [PDFFile] = []
        
        for url in urls {
            // Enforce hard constraint limitation of 100 files max
            if (loadedFiles.count + newlyAddedFiles.count) >= 100 { break }
            
            // Validate that the file dropped is actually a PDF extension
            guard url.pathExtension.lowercased() == "pdf" else { continue }
            
            if let pdfDocument = PDFDocument(url: url) {
                let fileIsEncrypted = pdfDocument.isLocked
                let pageCount = fileIsEncrypted ? nil : pdfDocument.pageCount
                
                let discoveredFile = PDFFile(
                    url: url,
                    pageCount: pageCount,
                    isLocked: fileIsEncrypted
                )
                newlyAddedFiles.append(discoveredFile)
            }
        }
        
        // Append the valid files and transition the view state automatically
        if !newlyAddedFiles.isEmpty {
            loadedFiles.append(contentsOf: newlyAddedFiles)
            viewMode = .activeList
        }
    }
    
}

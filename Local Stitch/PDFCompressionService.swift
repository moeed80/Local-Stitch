import Foundation
import PDFKit

enum PDFCompressionLevel: String, CaseIterable, Identifiable {
    case balanced
    case smallestPDF

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .balanced:
            return "Balanced"
        case .smallestPDF:
            return "Smallest PDF"
        }
    }

    var detailText: String {
        switch self {
        case .balanced:
            return "Best first choice for reducing image-heavy PDFs while preserving readability."
        case .smallestPDF:
            return "More aggressive PDFKit image optimization. Image quality may be reduced."
        }
    }

    var writeOptions: [PDFDocumentWriteOption: Any] {
        switch self {
        case .balanced:
            return [
                .saveImagesAsJPEGOption: true
            ]
        case .smallestPDF:
            return [
                .saveImagesAsJPEGOption: true,
                .optimizeImagesForScreenOption: true
            ]
        }
    }
}

struct PDFCompressionMeasurement {
    let originalSizeBytes: UInt64
    let compressedSizeBytes: UInt64
    let outputURL: URL
    let level: PDFCompressionLevel

    var bytesSaved: Int64 {
        Int64(originalSizeBytes) - Int64(compressedSizeBytes)
    }

    var savingsRatio: Double {
        guard originalSizeBytes > 0, compressedSizeBytes < originalSizeBytes else { return 0 }
        return Double(originalSizeBytes - compressedSizeBytes) / Double(originalSizeBytes)
    }

    var percentSaved: Int {
        Int((savingsRatio * 100).rounded())
    }

    var isLargerThanOriginal: Bool {
        compressedSizeBytes > originalSizeBytes
    }

    var hasMeaningfulSavings: Bool {
        savingsRatio >= 0.03
    }

    var hasLittleOrNoSavings: Bool {
        !isLargerThanOriginal && !hasMeaningfulSavings
    }
}

final class PDFCompressionService {
    static func fileSize(at url: URL) -> UInt64? {
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let fileSize = attributes[.size] as? NSNumber
        else {
            return nil
        }

        return fileSize.uint64Value
    }

    func temporaryPDFURL(prefix: String) throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalStitch", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let safePrefix = prefix
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        return directoryURL.appendingPathComponent("\(safePrefix)-\(UUID().uuidString).pdf")
    }

    func compressedCopy(
        from sourceURL: URL,
        to destinationURL: URL,
        password: String?,
        level: PDFCompressionLevel,
        shouldCancel: () -> Bool
    ) throws -> PDFCompressionMeasurement {
        if shouldCancel() {
            throw LocalStitchError.compressionCancelled
        }

        let originalSize = Self.fileSize(at: sourceURL) ?? 0

        guard let document = PDFDocument(url: sourceURL) else {
            throw LocalStitchError.compressionFailed("The source PDF could not be opened.")
        }

        if document.isLocked {
            guard let password, document.unlock(withPassword: password) else {
                throw LocalStitchError.lockedFilesRemain
            }
        }

        if shouldCancel() {
            throw LocalStitchError.compressionCancelled
        }

        try? FileManager.default.removeItem(at: destinationURL)

        guard document.write(to: destinationURL, withOptions: level.writeOptions) else {
            throw LocalStitchError.compressionFailed("PDFKit could not write a reduced-size copy.")
        }

        if shouldCancel() {
            try? FileManager.default.removeItem(at: destinationURL)
            throw LocalStitchError.compressionCancelled
        }

        guard let compressedSize = Self.fileSize(at: destinationURL), compressedSize > 0 else {
            try? FileManager.default.removeItem(at: destinationURL)
            throw LocalStitchError.compressionFailed("The reduced-size copy could not be measured.")
        }

        return PDFCompressionMeasurement(
            originalSizeBytes: originalSize,
            compressedSizeBytes: compressedSize,
            outputURL: destinationURL,
            level: level
        )
    }
}

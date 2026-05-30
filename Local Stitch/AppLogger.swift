import Foundation
import OSLog

extension Logger {
    // Dynamically captures your clean bundle identity
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.moeed.local-stitch"
    
    // Categorize logs so they are easy to filter in the macOS Console App
    static let ui = Logger(subsystem: subsystem, category: "UserInterface")
    static let engine = Logger(subsystem: subsystem, category: "MergeEngine")
}

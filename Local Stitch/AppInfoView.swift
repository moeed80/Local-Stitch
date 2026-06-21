import AppKit
import SwiftUI

enum SupportLinks {
    static let companyURL = URL(string: "https://moeed.com/project/mangla/")!
    static let contactURL = URL(string: "https://moeed.com/contact/")!
    static let privacyURL = URL(string: "https://moeed.com/privacy/")!
    static let supportEmailURL = URL(string: "mailto:developer@moeed.com")!
    
    static func openHelp() {
        NSWorkspace.shared.open(companyURL)
    }
    
    static func openPrivacyPolicy() {
        NSWorkspace.shared.open(privacyURL)
    }
    
    static func openContactForm() {
        NSWorkspace.shared.open(contactURL)
    }
    
    static func openSupportEmail() {
        NSWorkspace.shared.open(supportEmailURL)
    }
}

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
            
            VStack(spacing: 4) {
                Text("Local Stitch")
                    .font(.system(size: 24, weight: .semibold))
                
                Text(appVersionLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("Private PDF merging for your Mac. No uploads.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                infoRow("Developer", "Mangla & Co LLC")
                infoRow("Support", "developer@moeed.com")
                infoRow("Privacy", "moeed.com/privacy")
                infoRow("License", "MIT License")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Button("Privacy Policy") {
                    SupportLinks.openPrivacyPolicy()
                }
                
                Button("Contact Support") {
                    SupportLinks.openSupportEmail()
                }
                
                Button("Company Page") {
                    SupportLinks.openHelp()
                }
            }
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 420)
    }
    
    private var appVersionLabel: String {
        guard
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            !version.isEmpty
        else {
            return "Version 1.0"
        }
        
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, !build.isEmpty {
            return "Version \(version) (\(build))"
        }
        
        return "Version \(version)"
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 72, alignment: .leading)
            
            Text(value)
                .font(.system(size: 12))
                .textSelection(.enabled)
        }
    }
}

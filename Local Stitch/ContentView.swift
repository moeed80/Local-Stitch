import SwiftUI
import UniformTypeIdentifiers

// MARK: - PRIMARY DISPLAY VIEW LAYER
struct ContentView: View {
    @StateObject private var engine = PDFMergeEngine()
    
    var body: some View {
        VStack(spacing: 0) {
            
            headerComponent
            
            Group {
                switch engine.viewMode {
                case .processing:
                    processingComponent
                case .success:
                    successComponent
                case .empty, .activeList:
                    if engine.loadedFiles.isEmpty {
                        emptyDropzoneComponent
                    } else {
                        fileListComponent
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
            
            footerControlComponent
        }
        .frame(width: 700, height: 500)
        .alert(item: $engine.currentUIError) { error in
            Alert(
                title: Text("Process Interrupted"),
                message: Text(error.errorDescription ?? "An unknown processing error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var acceptedDrop = false
        
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            acceptedDrop = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let droppedURL: URL?
                
                if let url = item as? URL {
                    droppedURL = url
                } else if let data = item as? Data {
                    droppedURL = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    droppedURL = nil
                }
                
                if let droppedURL {
                    DispatchQueue.main.async {
                        engine.handleDroppedURLs([droppedURL])
                    }
                }
            }
        }
        
        return acceptedDrop
    }
}

// MARK: - LAYOUT COMPONENT EXPANSIONS
extension ContentView {
    
    private var headerComponent: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Local Stitch")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("Private PDF merging for your Mac")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(appVersionLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
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
    
    private var emptyDropzoneComponent: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 6]))
                    .frame(height: 220)
                
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Text("Drag & Drop PDFs here or")
                            .foregroundColor(.secondary)
                        Button("Browse Files") {
                            engine.selectLocalFiles()
                        }
                        .buttonStyle(.link)
                        .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, 30)
            
            Text("Loaded Files: \(engine.loadedFiles.count) / 100")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    private var fileListComponent: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "plus")
                Text("Add More Files (\(engine.loadedFiles.count)/100 added)")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.05))
            .onTapGesture {
                engine.selectLocalFiles()
            }
            
            Divider()
            
            List {
                ForEach(engine.loadedFiles) { file in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        Text(file.name)
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        if file.isLocked && !file.isUnlockedSuccessfully {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                Text("Locked")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                        } else {
                            Text("\(file.pageCount ?? 0) Pages")
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(file.isLocked ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1))
                                .foregroundColor(file.isLocked ? .green : .primary)
                                .cornerRadius(4)
                        }
                        
                        Button(action: {
                            if let index = engine.loadedFiles.firstIndex(of: file) {
                                engine.loadedFiles.remove(at: index)
                                engine.passwordUnlockMessage = ""
                                if engine.loadedFiles.isEmpty { engine.viewMode = .empty }
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(file.isLocked && !file.isUnlockedSuccessfully ? Color.orange.opacity(0.03) : (file.isUnlockedSuccessfully ? Color.green.opacity(0.02) : Color.clear))
                    )
                }
                .onMove { indices, newOffset in
                    engine.loadedFiles.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .listStyle(.sidebar)
        }
    }
    
    private var processingComponent: some View {
        VStack(spacing: 20) {
            Text("Processing file \(engine.currentFileIndex) of \(engine.totalFileCount)...")
                .font(.system(size: 14, weight: .medium))
            
            ProgressView(value: engine.processingProgress, total: 1.0)
                .progressViewStyle(.linear)
                .frame(width: 320)
            
            Text(engine.processingSubtext)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 400)
                .lineLimit(2)
        }
    }
    
    private var successComponent: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            VStack(spacing: 6) {
                Text("Merge Complete!")
                    .font(.system(size: 18, weight: .bold))
                
                Text("Successfully exported '\(engine.generatedFilename)' (\(engine.estimatedPageCount) Pages).")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 450)
            }
            
            Button(action: { engine.openOutputLocation() }) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text("Show in Finder")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
    }
    
    private var footerControlComponent: some View {
        VStack(spacing: 14) {
            if engine.hasRemainingLockedFiles && engine.viewMode == .activeList {
                let lockedCount = engine.remainingLockedFileCount
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    
                    Text("\(lockedCount) files remain password-protected.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter Password", text: $engine.globalPasswordInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .onSubmit {
                            engine.checkPasswordUnlock()
                        }
                    
                    Button("Apply to All") {
                        engine.checkPasswordUnlock()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(engine.globalPasswordInput.isEmpty)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.06))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
                
                if !engine.passwordUnlockMessage.isEmpty {
                    Text(engine.passwordUnlockMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Insert AI-Optimized Document Manifest Pages", isOn: $engine.insertManifestPages)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(engine.viewMode == .processing || engine.viewMode == .success)
                
                Text("Injects context cards containing timestamps, index, boundaries, and SHA-256 fingerprints before each document for seamless LLM/RAG parsing.")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            HStack {
                if engine.viewMode == .success {
                    Text("Operation Finished")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    let manifestOverheadText = (engine.insertManifestPages && !engine.loadedFiles.isEmpty ? " (Includes \(engine.loadedFiles.count) manifest pages)" : "")
                    Text("Estimated Final Footprint: \(engine.estimatedPageCount) Pages" + manifestOverheadText)
                        .font(.system(size: 12, weight: engine.viewMode == .activeList && !engine.hasRemainingLockedFiles ? .bold : .regular))
                        .foregroundColor(engine.viewMode == .activeList && !engine.hasRemainingLockedFiles ? .primary : .secondary)
                }
                
                Spacer()
                
                if engine.viewMode == .processing {
                    Button("Cancel") {
                        engine.viewMode = .activeList
                    }
                    .controlSize(.large)
                } else if engine.viewMode == .success {
                    Button("Start New Merge") {
                        engine.loadedFiles.removeAll()
                        engine.insertManifestPages = false
                        engine.globalPasswordInput = ""
                        engine.viewMode = .empty
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Merge") {
                        engine.executeProductionMergePipeline()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(engine.loadedFiles.isEmpty || engine.hasRemainingLockedFiles)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - CANVAS DRAWING VIEWER PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

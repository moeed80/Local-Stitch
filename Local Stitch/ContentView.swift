import SwiftUI
import UniformTypeIdentifiers

// MARK: - PRIMARY DISPLAY VIEW LAYER
struct ContentView: View {
    @StateObject private var engine = PDFMergeEngine()

    var body: some View {
        VStack(spacing: 0) {

            headerComponent
            workflowStepComponent

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
        .frame(minWidth: 760, idealWidth: 820, minHeight: 560, idealHeight: 620)
        .alert(item: $engine.currentUIError) { error in
            Alert(
                title: Text("Local Stitch"),
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

                Text("Private PDF merging for your Mac. No uploads.")
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

    private var workflowStepComponent: some View {
        HStack(spacing: 12) {
            workflowStep(number: 1, label: "Add PDFs", isActive: engine.loadedFiles.isEmpty)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            workflowStep(number: 2, label: "Arrange Order", isActive: !engine.loadedFiles.isEmpty && engine.viewMode == .activeList)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            workflowStep(number: 3, label: "Merge", isActive: engine.viewMode == .processing || engine.viewMode == .success)

            Spacer()

            Label("Up to 100 PDFs", systemImage: "doc.on.doc")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.05))
    }

    private func workflowStep(number: Int, label: String, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            Text("\(number)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isActive ? .white : .secondary)
                .frame(width: 18, height: 18)
                .background(Circle().fill(isActive ? Color.accentColor : Color.secondary.opacity(0.15)))

            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .primary : .secondary)
        }
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
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 6]))
                    .frame(height: 240)

                VStack(spacing: 14) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.8))

                    VStack(spacing: 4) {
                        Text("Drop PDFs here")
                            .font(.system(size: 18, weight: .semibold))
                        Text("or choose files from your Mac")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Button {
                        engine.selectLocalFiles()
                    } label: {
                        Label("Choose PDFs", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 30)

            Text("Your PDFs are read locally and the merged file is saved only where you choose.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var fileListComponent: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(engine.loadedFiles.count) of 100 PDFs added")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    engine.selectLocalFiles()
                } label: {
                    Label("Add PDFs", systemImage: "plus")
                }
                .controlSize(.small)
                .disabled(engine.loadedFiles.count >= 100)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))

            Divider()

            List {
                ForEach(Array(engine.loadedFiles.enumerated()), id: \.element.id) { index, file in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 24, alignment: .trailing)

                        Text(file.name)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .truncationMode(.middle)

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
                            engine.removeFile(file)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .help("Remove this PDF")
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
            VStack(spacing: 4) {
                Text(engine.isCancellationRequested ? "Cancelling merge..." : "Merging PDFs...")
                    .font(.system(size: 18, weight: .semibold))

                Text("File \(engine.currentFileIndex) of \(engine.totalFileCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

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
                Text("Merged PDF saved")
                    .font(.system(size: 18, weight: .bold))

                Text("Saved '\(engine.generatedFilename)' with \(engine.estimatedPageCount) pages. No files were uploaded.")
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

                    Text("\(lockedCount) protected PDF\(lockedCount == 1 ? "" : "s") need a password.")
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
                Toggle("Add source summary pages for AI review", isOn: $engine.insertManifestPages)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(engine.viewMode == .processing || engine.viewMode == .success)

                Text("Adds a first-page overview and one summary page before each PDF with filename, page range, metadata, and SHA-256 fingerprint.")
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
                    let manifestPageCount = engine.loadedFiles.count + 1
                    let manifestOverheadText = (engine.insertManifestPages && !engine.loadedFiles.isEmpty ? " including \(manifestPageCount) summary pages" : "")
                    Text("Estimated output: \(engine.estimatedPageCount) pages" + manifestOverheadText)
                        .font(.system(size: 12, weight: engine.viewMode == .activeList && !engine.hasRemainingLockedFiles ? .bold : .regular))
                        .foregroundColor(engine.viewMode == .activeList && !engine.hasRemainingLockedFiles ? .primary : .secondary)
                }

                Spacer()

                if engine.viewMode == .processing {
                    Button("Cancel") {
                        engine.cancelMerge()
                    }
                    .controlSize(.large)
                    .disabled(engine.isCancellationRequested)
                } else if engine.viewMode == .success {
                    Button("Start New Merge") {
                        engine.resetForNewMerge()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Merge PDFs") {
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

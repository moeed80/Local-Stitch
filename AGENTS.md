# AGENTS.md

This is a native macOS Swift/SwiftUI app built with Xcode.

Rules:
- Prefer small, reversible changes.
- One task should produce one clean Git diff.
- Do not change signing, bundle IDs, entitlements, App Sandbox settings, Info.plist privacy strings, or release configuration without calling it out clearly.
- After changing Swift code, run the project build action or an appropriate xcodebuild command.
- Keep UI work native to SwiftUI/AppKit conventions.
- Do not add network calls unless explicitly required.
- Do not introduce cloud processing; this app’s value proposition is local-first privacy.

Local Stitch implementation rules:
- Use user-selected files only.
- Avoid loading all PDFs into memory at once.
- Keep PDF inspection, SHA-256 hashing, and merge work off the main thread.
- Preserve UI responsiveness during large merges.
- Enforce the 100-file limit.
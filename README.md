# 🧵 Local Stitch

**Local Stitch** is a secure, privacy-first macOS utility designed to merge multiple PDF documents—including password-locked files—into a single, consolidated payload tailored for flawless AI ingestion.

When handling massive document batches (like months of bank statements or corporate records), modern LLMs like ChatGPT often throttle or reject uploads due to file number limits. Local Stitch strips away those roadblocks completely local to your machine, keeping your sensitive data 100% private.

---

## ✨ Features

* **Zero Cloud Reliance:** All processing, decryption handshakes, and file compilation happen exclusively on your Mac's CPU. Your data never touches a third-party server.
* **Bulk Password Handling:** Automatically handles password-locked files, unlocking and restitching them into a unified, unprotected document ready for AI parsers.
* **Modern macOS Identity:** Fully native interface built with SwiftUI, matching the desktop squircle human interface architecture perfectly.
* **Enterprise Telemetry:** Leverages Apple's native `Unified Logging System (OSLog)` to handle corrupted, structured data anomalies gracefully without application crashes.

---

## 🛠️ Requirements & Architecture

* **Operating System:** macOS 14.0 (Sonoma) or later
* **Frameworks:** SwiftUI, PDFKit, CryptoKit, OSLog
* **Hardware Support:** Universal binary optimized for Apple Silicon (M1/M2/M3/M4) and Intel architectures.

---

## 🚀 Building from Source

To run or modify Local Stitch on your own machine:

1. Clone this repository locally:
   ```bash
   git clone [https://github.com/moeed80/Local-Stitch.git](https://github.com/moeed80/Local-Stitch.git)
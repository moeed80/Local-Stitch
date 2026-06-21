//
//  LocalStitchApp.swift
//  Local Stitch
//
//  Created by Moeed Ahmad on 5/29/26.
//

import SwiftUI

@main
struct LocalStitchApp: App {
    @State private var isShowingAboutWindow = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $isShowingAboutWindow) {
                    AppInfoView()
                }
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Local Stitch") {
                    isShowingAboutWindow = true
                }
            }

            CommandGroup(replacing: .help) {
                Button("Local Stitch Help") {
                    SupportLinks.openHelp()
                }

                Button("Privacy Policy") {
                    SupportLinks.openPrivacyPolicy()
                }

                Button("Contact Support") {
                    SupportLinks.openSupportEmail()
                }
            }
        }
    }
}

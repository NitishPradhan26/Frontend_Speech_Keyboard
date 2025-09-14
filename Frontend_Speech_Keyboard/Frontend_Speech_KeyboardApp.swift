//
//  Frontend_Speech_KeyboardApp.swift
//  Frontend_Speech_Keyboard
//
//  Created by Nitish Pradhan on 2025-09-11.
//

import SwiftUI

@main
struct Frontend_Speech_KeyboardApp: App {
    private let keyboardActionHandler = KeyboardActionHandler.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    keyboardActionHandler.handleURL(url)
                }
                .onAppear {
                    _ = RecordingManager.shared
                }
        }
    }
}

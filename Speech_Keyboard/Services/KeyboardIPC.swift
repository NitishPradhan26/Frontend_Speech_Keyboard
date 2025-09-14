//
//  KeyboardIPC.swift
//  Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import Foundation
import UIKit
import Combine

enum KeyboardAction: String, CaseIterable {
    case startRecording = "start_recording"
    case pauseRecording = "pause_recording"
    case resumeRecording = "resume_recording"
    case stopRecording = "stop_recording"
    case checkStatus = "check_status"
    
    var urlString: String {
        return "speechkeyboard://action/\(self.rawValue)"
    }
}

enum KeyboardIPCError: Error, LocalizedError {
    case fullAccessRequired
    case urlSchemeNotSupported
    case actionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fullAccessRequired:
            return "Full Access permission is required to communicate with the main app"
        case .urlSchemeNotSupported:
            return "URL scheme communication is not available"
        case .actionFailed(let message):
            return "Action failed: \(message)"
        }
    }
}

class KeyboardIPC: ObservableObject {
    static let shared = KeyboardIPC()
    
    @Published var recordingStatus: RecordingStatus = .idle
    private let appGroupIdentifier = "group.com.geniusinnovationlab.speechkb"
    private weak var extensionContext: NSExtensionContext?
    
    private init() {
        setupStatusListener()
    }
    
    func configure(with extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }
    
    var hasFullAccess: Bool {
        // Try to access UserDefaults with app group - this requires full access
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return false
        }
        
        // If we can write to and read from shared UserDefaults, we have full access
        let testKey = "full_access_test"
        let testValue = "test_\(Date().timeIntervalSince1970)"
        
        userDefaults.set(testValue, forKey: testKey)
        let canWrite = userDefaults.synchronize()
        let readValue = userDefaults.string(forKey: testKey)
        
        // Clean up test data
        userDefaults.removeObject(forKey: testKey)
        userDefaults.synchronize()
        
        return canWrite && readValue == testValue
    }
    
    func sendAction(_ action: KeyboardAction, parameters: [String: Any] = [:]) {
        guard hasFullAccess else {
            handleError(.fullAccessRequired)
            return
        }
        
        guard let url = createActionURL(action: action, parameters: parameters) else {
            handleError(.urlSchemeNotSupported)
            return
        }
        
        // Store action metadata in shared container for the main app
        storeActionMetadata(action: action, parameters: parameters)
        
        // Use extension context to open URL
        openURLInKeyboardExtension(url)
    }
    
    private func createActionURL(action: KeyboardAction, parameters: [String: Any]) -> URL? {
        var components = URLComponents(string: action.urlString)
        
        var queryItems: [URLQueryItem] = []
        
        if !parameters.isEmpty {
            let parameterItems = parameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            queryItems.append(contentsOf: parameterItems)
        }
        
        // Add timestamp for uniqueness
        let timestampQuery = URLQueryItem(name: "timestamp", value: "\(Date().timeIntervalSince1970)")
        queryItems.append(timestampQuery)
        
        components?.queryItems = queryItems
        
        return components?.url
    }
    
    private func openURLInKeyboardExtension(_ url: URL) {
        // Primary approach: Use shared UserDefaults for reliable communication
        postActionViaUserDefaults(url: url)
        
        // Secondary attempt: Try to open URL using extension context if available
        if let extensionContext = self.extensionContext {
            extensionContext.open(url, completionHandler: { _ in })
        }
    }
    
    private func postActionViaUserDefaults(url: URL) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            handleError(.actionFailed("Cannot access shared container"))
            return
        }
        
        let actionData: [String: Any] = [
            "url": url.absoluteString,
            "timestamp": Date().timeIntervalSince1970,
            "source": "keyboard_extension"
        ]
        
        userDefaults.set(actionData, forKey: "pending_keyboard_action")
        userDefaults.synchronize()
        
        userDefaults.set(Date().timeIntervalSince1970, forKey: "keyboard_action_trigger")
        userDefaults.synchronize()
        
        NotificationCenter.default.post(
            name: NSNotification.Name("KeyboardActionPosted"),
            object: nil,
            userInfo: actionData
        )
    }
    
    private func storeActionMetadata(action: KeyboardAction, parameters: [String: Any]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        let metadata: [String: Any] = [
            "action": action.rawValue,
            "parameters": parameters,
            "timestamp": Date().timeIntervalSince1970,
            "status": "initiated"
        ]
        
        userDefaults.set(metadata, forKey: "current_action_metadata")
        userDefaults.synchronize()
    }
    
    private func setupStatusListener() {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        // Observe changes to recording status from main app
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: userDefaults,
            queue: .main
        ) { [weak self] _ in
            self?.checkRecordingStatus()
        }
        
        // Initial status check
        checkRecordingStatus()
    }
    
    private func checkRecordingStatus() {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        if let statusString = userDefaults.string(forKey: "recording_status") {
            updateRecordingStatus(from: statusString)
        }
        
        // Check for completed transcriptions
        if let transcriptionData = userDefaults.data(forKey: "completed_transcription") {
            handleCompletedTranscription(data: transcriptionData)
            userDefaults.removeObject(forKey: "completed_transcription")
            userDefaults.synchronize()
        }
    }
    
    private func updateRecordingStatus(from statusString: String) {
        let newStatus: RecordingStatus
        
        switch statusString {
        case "idle":
            newStatus = .idle
        case "recording":
            newStatus = .recording
        case "paused":
            newStatus = .paused
        case "processing":
            newStatus = .processing
        case "completed":
            newStatus = .completed
        case "error":
            newStatus = .error
        default:
            newStatus = .idle
        }
        
        if recordingStatus != newStatus {
            recordingStatus = newStatus
        }
    }
    
    private func handleCompletedTranscription(data: Data) {
        do {
            if let transcriptionInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let transcribedText = transcriptionInfo["text"] as? String {
                insertTranscribedText(transcribedText)
            }
        } catch {
            // Silently handle parsing errors
        }
    }
    
    private func insertTranscribedText(_ text: String) {
        // This would be implemented in the actual keyboard extension context
        // For now, we'll store it for the keyboard to pick up
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        userDefaults.set(text, forKey: "text_to_insert")
        userDefaults.synchronize()
        
        recordingStatus = .completed
        
        // Auto-reset to idle after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.recordingStatus = .idle
        }
    }
    
    private func handleError(_ error: KeyboardIPCError) {
        recordingStatus = .error
        
        // Auto-reset to idle after error display
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.recordingStatus = .idle
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
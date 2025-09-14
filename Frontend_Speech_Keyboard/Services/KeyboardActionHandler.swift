//
//  KeyboardActionHandler.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import Foundation
import SwiftUI
import Combine

class KeyboardActionHandler: ObservableObject {
    static let shared = KeyboardActionHandler()
    
    private let recordingManager = RecordingManager.shared
    private let appGroupIdentifier = "group.com.geniusinnovationlab.speechkb"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupUserDefaultsObserver()
        setupApplicationLifecycleObserver()
        Task { @MainActor in
            setupRecordingStateBinding()
        }
    }
    
    // MARK: - URL Scheme Handling
    
    func handleURL(_ url: URL) {
        print("Handling URL: \(url.absoluteString)")
        
        guard url.scheme == "speechkeyboard" else {
            print("Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let action = extractAction(from: url) else {
            print("Could not extract action from URL")
            return
        }
        
        Task { @MainActor in
            await executeAction(action, parameters: extractParameters(from: components))
        }
    }
    
    private func extractAction(from url: URL) -> String? {
        // URL format: speechkeyboard://action/start_recording
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 2,
              pathComponents[0] == "/",
              pathComponents[1] == "action",
              pathComponents.count >= 3 else {
            return nil
        }
        return pathComponents[2]
    }
    
    private func extractParameters(from components: URLComponents?) -> [String: String] {
        guard let queryItems = components?.queryItems else { return [:] }
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                parameters[item.name] = value
            }
        }
        return parameters
    }
    
    // MARK: - Action Execution
    
    @MainActor
    private func executeAction(_ action: String, parameters: [String: String]) async {
        print("Executing action: \(action) with parameters: \(parameters)")
        
        switch action {
        case "start_recording":
            await handleStartRecording()
            
        case "pause_recording":
            handlePauseRecording()
            
        case "resume_recording":
            handleResumeRecording()
            
        case "stop_recording":
            handleStopRecording()
            
        case "check_status":
            handleCheckStatus()
            
        default:
            print("Unknown action: \(action)")
            updateSharedError("Unknown action: \(action)")
        }
    }
    
    @MainActor
    private func handleStartRecording() async {
        do {
            // Request permission if needed
            let hasPermission = await recordingManager.requestMicrophonePermission()
            guard hasPermission else {
                updateSharedError("Microphone permission denied")
                return
            }
            
            try await recordingManager.startRecording()
            print("Recording started successfully")
        } catch {
            print("Failed to start recording: \(error)")
            updateSharedError(error.localizedDescription)
        }
    }
    
    @MainActor
    private func handlePauseRecording() {
        recordingManager.pauseRecording()
        print("Recording paused")
    }
    
    @MainActor
    private func handleResumeRecording() {
        recordingManager.resumeRecording()
        print("Recording resumed")
    }
    
    @MainActor
    private func handleStopRecording() {
        recordingManager.stopRecording()
        print("Recording stopped")
    }
    
    @MainActor
    private func handleCheckStatus() {
        // Force update shared state
        updateSharedRecordingState()
    }
    
    // MARK: - Application Lifecycle
    
    private func setupApplicationLifecycleObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkForPendingActions()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkForPendingActions()
        }
    }
    
    // MARK: - UserDefaults Observer
    
    private func setupUserDefaultsObserver() {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        // Monitor keyboard actions posted via UserDefaults
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: userDefaults)
            .sink { [weak self] _ in
                self?.checkForPendingActions()
            }
            .store(in: &cancellables)
        
        // Initial check
        checkForPendingActions()
    }
    
    private func checkForPendingActions() {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        guard let actionData = userDefaults.dictionary(forKey: "pending_keyboard_action"),
              let urlString = actionData["url"] as? String,
              let url = URL(string: urlString) else {
            return
        }
        
        print("🎯 Found pending action: \(actionData)")
        
        // Clear the pending action to avoid duplicate processing
        userDefaults.removeObject(forKey: "pending_keyboard_action")
        userDefaults.removeObject(forKey: "keyboard_action_trigger")
        userDefaults.synchronize()
        
        print("🚀 Processing keyboard action URL: \(url)")
        
        // Handle the action
        handleURL(url)
    }
    
    // MARK: - Recording State Management
    
    @MainActor
    private func setupRecordingStateBinding() {
        recordingManager.$recordingState
            .sink { [weak self] state in
                self?.updateSharedRecordingState()
            }
            .store(in: &cancellables)
        
        recordingManager.$currentFilePath
            .sink { [weak self] _ in
                self?.updateSharedRecordingState()
            }
            .store(in: &cancellables)
        
        recordingManager.$recordingDuration
            .sink { [weak self] _ in
                self?.updateSharedRecordingState()
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func updateSharedRecordingState() {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        let state = recordingManager.recordingState
        let filePath = recordingManager.currentFilePath?.path ?? ""
        let duration = recordingManager.recordingDuration
        
        userDefaults.set(state.rawValue, forKey: "recording_status")
        userDefaults.set(filePath, forKey: "current_recording_file")
        userDefaults.set(duration, forKey: "recording_duration")
        userDefaults.synchronize()
        
        print("Updated shared state: \(state.rawValue), file: \(filePath), duration: \(duration)")
    }
    
    @MainActor
    private func updateSharedError(_ message: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        userDefaults.set("error", forKey: "recording_status")
        userDefaults.set(message, forKey: "recording_error")
        userDefaults.synchronize()
        
        print("Updated shared error: \(message)")
    }
}
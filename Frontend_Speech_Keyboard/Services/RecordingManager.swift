//
//  RecordingManager.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import Foundation
import AVFoundation
import Combine

enum RecordingError: Error, LocalizedError {
    case permissionDenied
    case audioSessionSetupFailed
    case recordingStartFailed
    case recordingStopFailed
    case fileAccessError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required"
        case .audioSessionSetupFailed:
            return "Failed to setup audio session"
        case .recordingStartFailed:
            return "Failed to start recording"
        case .recordingStopFailed:
            return "Failed to stop recording"
        case .fileAccessError:
            return "Failed to access recording file"
        }
    }
}

enum RecordingState: String {
    case idle = "idle"
    case recording = "recording"
    case paused = "paused"
    case processing = "processing"
    case completed = "completed"
    case error = "error"
}

@MainActor
class RecordingManager: NSObject, ObservableObject {
    static let shared = RecordingManager()
    
    @Published var recordingState: RecordingState = .idle
    @Published var recordingDuration: TimeInterval = 0
    @Published var currentFilePath: URL?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession = AVAudioSession.sharedInstance()
    private var recordingTimer: Timer?
    private let appGroupIdentifier = "group.com.geniusinnovationlab.speechkb"
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(false)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Permission Management
    
    func requestMicrophonePermission() async -> Bool {
        let currentStatus = audioSession.recordPermission
        print("🎤 Current microphone permission status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .granted:
            print("✅ Microphone permission already granted")
            return true
        case .denied:
            print("❌ Microphone permission denied")
            return false
        case .undetermined:
            print("❓ Requesting microphone permission...")
            let granted = await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    print("🎤 Permission request result: \(granted)")
                    continuation.resume(returning: granted)
                }
            }
            return granted
        @unknown default:
            print("⚠️ Unknown permission status")
            return false
        }
    }
    
    private func checkMicrophonePermission() -> Bool {
        return audioSession.recordPermission == .granted
    }
    
    // MARK: - Recording Controls
    
    func startRecording() async throws {
        print("🎯 Starting recording process...")
        
        guard checkMicrophonePermission() else {
            print("❌ No microphone permission")
            throw RecordingError.permissionDenied
        }
        
        guard recordingState == .idle || recordingState == .completed else {
            print("⚠️ Cannot start recording - current state: \(recordingState)")
            return // Already recording or in another state
        }
        
        print("🔧 Setting up recording session...")
        try await setupRecordingSession()
        
        let audioURL = createAudioFileURL()
        currentFilePath = audioURL
        print("📁 Audio will be saved to: \(audioURL.path)")
        
        let settings = createAudioSettings()
        print("⚙️ Audio settings: \(settings)")
        
        do {
            print("🎙️ Creating AVAudioRecorder...")
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            
            print("🔊 Activating audio session...")
            try audioSession.setActive(true)
            
            print("🔴 Starting recording...")
            if audioRecorder?.record() == true {
                recordingState = .recording
                updateSharedRecordingState()
                startRecordingTimer()
                print("✅ Recording started successfully!")
            } else {
                print("❌ Failed to start recording - recorder.record() returned false")
                throw RecordingError.recordingStartFailed
            }
        } catch {
            print("❌ Recording setup failed: \(error)")
            recordingState = .error
            updateSharedRecordingState()
            throw RecordingError.recordingStartFailed
        }
    }
    
    func pauseRecording() {
        guard recordingState == .recording else { return }
        
        audioRecorder?.pause()
        recordingState = .paused
        updateSharedRecordingState()
        stopRecordingTimer()
    }
    
    func resumeRecording() {
        guard recordingState == .paused else { return }
        
        audioRecorder?.record()
        recordingState = .recording
        updateSharedRecordingState()
        startRecordingTimer()
    }
    
    func stopRecording() {
        guard recordingState == .recording || recordingState == .paused else { return }
        
        audioRecorder?.stop()
        recordingState = .processing
        updateSharedRecordingState()
        stopRecordingTimer()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Audio Configuration
    
    private func setupRecordingSession() async throws {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            throw RecordingError.audioSessionSetupFailed
        }
    }
    
    private func createAudioFileURL() -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Cannot access app group container: \(appGroupIdentifier)")
        }
        
        let recordingsDirectory = containerURL.appendingPathComponent("Recordings", isDirectory: true)
        
        // Create recordings directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true, attributes: nil)
            print("📁 Created/verified recordings directory at: \(recordingsDirectory.path)")
        } catch {
            print("❌ Failed to create recordings directory: \(error)")
        }
        
        let timestamp = Date().timeIntervalSince1970
        let filename = "recording_\(Int(timestamp)).m4a"
        
        return recordingsDirectory.appendingPathComponent(filename)
    }
    
    private func createAudioSettings() -> [String: Any] {
        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    // MARK: - Timer Management
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRecordingDuration()
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateRecordingDuration() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recordingDuration = recorder.currentTime
    }
    
    // MARK: - Shared State Management
    
    private func updateSharedRecordingState() {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        
        userDefaults.set(recordingState.rawValue, forKey: "recording_status")
        
        if let filePath = currentFilePath {
            userDefaults.set(filePath.path, forKey: "current_recording_file")
        }
        
        userDefaults.set(recordingDuration, forKey: "recording_duration")
        userDefaults.synchronize()
        
        // Post notification for immediate UI updates
        NotificationCenter.default.post(
            name: NSNotification.Name("RecordingStateChanged"),
            object: nil,
            userInfo: [
                "state": recordingState.rawValue,
                "duration": recordingDuration,
                "filePath": currentFilePath?.path ?? ""
            ]
        )
    }
    
    // MARK: - File Management
    
    func getRecordingFileURL() -> URL? {
        return currentFilePath
    }
    
    func deleteRecording(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
        
        if currentFilePath == url {
            currentFilePath = nil
            recordingState = .idle
            updateSharedRecordingState()
        }
    }
    
    func getAllRecordings() -> [URL] {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("❌ Cannot access app group container")
            return []
        }
        
        let recordingsDirectory = containerURL.appendingPathComponent("Recordings", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true, attributes: nil)
                print("📁 Created recordings directory for getAllRecordings")
            } catch {
                print("❌ Failed to create recordings directory: \(error)")
                return []
            }
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: recordingsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            let recordings = contents
                .filter { $0.pathExtension == "m4a" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
            
            print("📂 Found \(recordings.count) recordings")
            return recordings
        } catch {
            print("❌ Failed to get recordings: \(error)")
            return []
        }
    }
    
    // MARK: - Cleanup
    
    func reset() {
        stopRecording()
        recordingDuration = 0
        currentFilePath = nil
        recordingState = .idle
        updateSharedRecordingState()
    }
}

// MARK: - AVAudioRecorderDelegate

extension RecordingManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                recordingState = .completed
                
                // Auto-transcribe the completed recording
                if let audioURL = currentFilePath {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RecordingCompleted"),
                        object: nil,
                        userInfo: ["audioURL": audioURL]
                    )
                }
            } else {
                recordingState = .error
            }
            updateSharedRecordingState()
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            recordingState = .error
            updateSharedRecordingState()
            print("Recording encode error: \(error?.localizedDescription ?? "unknown")")
        }
    }
}
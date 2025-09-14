//
//  KeyboardViewModel.swift
//  Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import SwiftUI
import Combine

enum RecordingStatus {
    case idle
    case recording
    case paused
    case processing
    case completed
    case error
}

@MainActor
class KeyboardViewModel: ObservableObject {
    @Published var recordingStatus: RecordingStatus = .idle
    @Published var hasFullAccess: Bool = false
    
    private let keyboardIPC = KeyboardIPC.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        keyboardIPC.$recordingStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.recordingStatus, on: self)
            .store(in: &cancellables)
    }
    
    func checkFullAccess() {
        hasFullAccess = keyboardIPC.hasFullAccess
    }
    
    func handleRecordAction() {
        switch recordingStatus {
        case .idle, .completed, .error:
            startRecording()
        case .recording:
            stopRecording()
        case .paused:
            resumeRecording()
        case .processing:
            break
        }
    }
    
    func handlePauseAction() {
        switch recordingStatus {
        case .recording:
            pauseRecording()
        case .paused:
            resumeRecording()
        default:
            break
        }
    }
    
    func handleStopAction() {
        stopRecording()
    }
    
    private func startRecording() {
        guard hasFullAccess else {
            recordingStatus = .error
            return
        }
        
        keyboardIPC.sendAction(.startRecording)
        recordingStatus = .recording
    }
    
    private func pauseRecording() {
        keyboardIPC.sendAction(.pauseRecording)
        recordingStatus = .paused
    }
    
    private func resumeRecording() {
        keyboardIPC.sendAction(.resumeRecording)
        recordingStatus = .recording
    }
    
    private func stopRecording() {
        keyboardIPC.sendAction(.stopRecording)
        recordingStatus = .processing
    }
}
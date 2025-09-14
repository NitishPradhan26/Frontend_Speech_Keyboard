//
//  ContentView.swift
//  Frontend_Speech_Keyboard
//
//  Created by Nitish Pradhan on 2025-09-11.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var recordingManager = RecordingManager.shared
    @StateObject private var transcriptionViewModel = TranscriptionViewModel()
    @State private var recordings: [URL] = []
    
    var body: some View {
        TabView {
            // Current Recording View
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // App Icon only
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                            .padding(.top)
                        
                        // Recording Status
                        GroupBox("Recording Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("State:")
                            Spacer()
                            Text(recordingManager.recordingState.rawValue.capitalized)
                                .fontWeight(.medium)
                                .foregroundColor(stateColor)
                        }
                        
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Text(formatDuration(recordingManager.recordingDuration))
                                .fontWeight(.medium)
                        }
                        
                        if let filePath = recordingManager.currentFilePath {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current File:")
                                Text(filePath.lastPathComponent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Manual Recording Controls (for testing)
                GroupBox("Test Recording") {
                    HStack(spacing: 16) {
                        Button("Start") {
                            print("🎯 Start button pressed")
                            Task {
                                do {
                                    print("🎙️ Requesting microphone permission...")
                                    let hasPermission = await recordingManager.requestMicrophonePermission()
                                    if hasPermission {
                                        print("✅ Permission granted, starting recording...")
                                        try await recordingManager.startRecording()
                                        print("🔴 Recording started successfully")
                                    } else {
                                        print("❌ Microphone permission denied")
                                    }
                                } catch {
                                    print("❌ Recording failed: \(error)")
                                }
                            }
                        }
                        .disabled(recordingManager.recordingState == .recording)
                        
                        Button("Pause") {
                            print("⏸️ Pause button pressed")
                            recordingManager.pauseRecording()
                        }
                        .disabled(recordingManager.recordingState != .recording)
                        
                        Button("Resume") {
                            print("▶️ Resume button pressed")
                            recordingManager.resumeRecording()
                        }
                        .disabled(recordingManager.recordingState != .paused)
                        
                        Button("Stop") {
                            print("⏹️ Stop button pressed")
                            recordingManager.stopRecording()
                        }
                        .disabled(recordingManager.recordingState != .recording && recordingManager.recordingState != .paused)
                    }
                }
                
                // Transcription Results
                GroupBox("Transcription Results") {
                    if transcriptionViewModel.isTranscribing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Transcribing audio...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if transcriptionViewModel.transcriptionResults.isEmpty {
                        Text("No transcriptions yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(transcriptionViewModel.transcriptionResults) { result in
                                TranscriptionResultCard(result: result) { id, finalText in
                                    transcriptionViewModel.updateTranscript(id: id, finalText: finalText)
                                }
                            }
                        }
                    }
                    
                    if let error = transcriptionViewModel.transcriptionError {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
                
                // Recordings List
                GroupBox("Recent Recordings") {
                    if recordings.isEmpty {
                        Text("No recordings yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        LazyVStack {
                            ForEach(recordings, id: \.self) { url in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(url.lastPathComponent)
                                            .font(.caption)
                                        Text(formatFileDate(url))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Transcribe") {
                                        transcriptionViewModel.transcribeAudio(at: url)
                                    }
                                    .foregroundColor(.blue)
                                    .disabled(transcriptionViewModel.isTranscribing)
                                    
                                    Button("Delete") {
                                        try? recordingManager.deleteRecording(at: url)
                                        refreshRecordings()
                                    }
                                    .foregroundColor(.red)
                                }
                                .padding(.vertical, 4)
                                
                                if url != recordings.last {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                
                // Instructions
                Text("Use the Speech Keyboard in any app to start recording!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20) // Extra padding for tab bar
                    }
                    .padding()
                }
                .navigationTitle("Speech Keyboard")
                .navigationBarTitleDisplayMode(.large)
            }
            .onAppear {
                refreshRecordings()
            }
            .onChange(of: recordingManager.recordingState) { _ in
                refreshRecordings()
            }
            .tabItem {
                Image(systemName: "mic")
                Text("Recording")
            }
            
            // Transcription History Tab
            TranscriptionHistoryView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("History")
                }
        }
    }
    
    private var stateColor: Color {
        switch recordingManager.recordingState {
        case .idle, .completed:
            return .primary
        case .recording:
            return .red
        case .paused:
            return .orange
        case .processing:
            return .blue
        case .error:
            return .red
        }
    }
    
    private func refreshRecordings() {
        recordings = recordingManager.getAllRecordings()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatFileDate(_ url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let date = attributes[.creationDate] as? Date else {
            return "Unknown date"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}

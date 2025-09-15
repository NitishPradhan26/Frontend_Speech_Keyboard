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
    @StateObject private var promptViewModel = PromptViewModel()
    @State private var showingAddPrompt = false
    
    private let userId: String = "1" // TODO: Get from authentication system
    
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
                        
                        // Prompt Selector
                        GroupBox("Select Prompt") {
                            VStack(alignment: .leading, spacing: 12) {
                                if promptViewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading prompts...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else if promptViewModel.prompts.isEmpty {
                                    VStack(spacing: 8) {
                                        Text("No prompts available")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Button("Create First Prompt") {
                                            showingAddPrompt = true
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                } else {
                                    HStack {
                                        Menu {
                                            ForEach(promptViewModel.prompts) { prompt in
                                                Button(prompt.title) {
                                                    promptViewModel.selectPrompt(prompt)
                                                }
                                            }
                                            
                                            Divider()
                                            
                                            Button("Add New Prompt") {
                                                showingAddPrompt = true
                                            }
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(promptViewModel.selectedPromptTitle ?? "Select a prompt")
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                    
                                                    if let content = promptViewModel.selectedPromptContent {
                                                        Text(content)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(2)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.down")
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                        }
                                        
                                        Button(action: {
                                            showingAddPrompt = true
                                        }) {
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                if let error = promptViewModel.errorMessage {
                                    Text("Error: \(error)")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                        }
                        
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
                Task {
                    await promptViewModel.loadPrompts(userId: userId)
                    updateRecordingPrompt()
                }
            }
            .onChange(of: promptViewModel.selectedPrompt) { selectedPrompt in
                // Update the current prompt for auto-transcription
                updateRecordingPrompt()
            }
            .sheet(isPresented: $showingAddPrompt) {
                AddPromptView(promptViewModel: promptViewModel, userId: Int(userId) ?? 1)
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateRecordingPrompt() {
        // Store current prompt info in UserDefaults for the RecordingManager to use
        let defaults = UserDefaults.standard
        if let selectedPrompt = promptViewModel.selectedPrompt {
            defaults.set(selectedPrompt.content, forKey: "currentPromptContent")
            defaults.set(userId, forKey: "currentUserId")
        } else {
            defaults.removeObject(forKey: "currentPromptContent")
            defaults.removeObject(forKey: "currentUserId")
        }
    }
}

#Preview {
    ContentView()
}

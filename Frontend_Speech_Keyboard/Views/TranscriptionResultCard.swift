//
//  TranscriptionResultCard.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import SwiftUI

struct TranscriptionResultCard: View {
    let result: TranscriptionViewModel.TranscriptionResult
    @State private var isExpanded = false
    @State private var editedText: String
    @State private var isEditing = false
    @State private var isSaving = false
    
    let onSave: (Int, String) -> Void
    
    init(result: TranscriptionViewModel.TranscriptionResult, onSave: @escaping (Int, String) -> Void) {
        self.result = result
        self.onSave = onSave
        self._editedText = State(initialValue: result.data.finalText)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Transcription")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formatTimestamp(result.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Final Text (editable)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Final Text:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Show save button when text has changed
                    if hasTextChanged && !isSaving {
                        Button("Save") {
                            saveChanges()
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                    
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                
                TextEditor(text: $editedText)
                    .font(.body)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(hasTextChanged ? Color.blue.opacity(0.5) : Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .frame(minHeight: 60)
                    .onChange(of: editedText) { _ in
                        isEditing = true
                    }
            }
            
            // Expandable details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    // Raw Transcript
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Raw Transcript:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(result.data.rawTranscript)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                    }
                    
                    // Metadata
                    HStack {
                        if let duration = result.data.duration {
                            Label("\(String(format: "%.1f", duration))s", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let promptUsed = result.data.promptUsed {
                            Text("Prompt: \(promptUsed)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Audio file info
                    Text("Audio: \(result.audioURL.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
    
    private var hasTextChanged: Bool {
        editedText != result.data.finalText
    }
    
    private func saveChanges() {
        guard let transcriptId = result.data.transcriptId else { return }
        
        isSaving = true
        onSave(transcriptId, editedText)
        
        // Reset saving state after a delay (will be handled by parent view model)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSaving = false
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleData = TranscriptionData(
        transcriptId: 123,
        rawTranscript: "hello world this is a test",
        finalText: "Hello world, this is a test.",
        duration: 3.2,
        promptUsed: "Clean up speech"
    )
    
    let sampleResult = TranscriptionViewModel.TranscriptionResult(
        audioURL: URL(string: "file:///test/recording.m4a")!,
        data: sampleData,
        timestamp: Date()
    )
    
    TranscriptionResultCard(result: sampleResult) { id, text in
        print("Save transcript \(id) with text: \(text)")
    }
    .padding()
}
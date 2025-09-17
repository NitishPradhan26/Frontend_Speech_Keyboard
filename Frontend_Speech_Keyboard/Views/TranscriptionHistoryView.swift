//
//  TranscriptionHistoryView.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-13.
//

import SwiftUI

// Extension to dismiss keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct TranscriptionHistoryView: View {
    @StateObject private var viewModel = TranscriptionViewModel()
    private let userId: String = "1" // TODO: Get from authentication system
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoadingHistory {
                    VStack {
                        ProgressView()
                        Text("Loading transcription history...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.transcriptionHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No transcriptions yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Your transcription history will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.transcriptionHistory, id: \.id) { transcript in
                                TranscriptionHistoryCard(
                                    transcript: transcript,
                                    onUpdate: { id, finalText in
                                        Task {
                                            await viewModel.updateHistoryTranscript(id: id, finalText: finalText)
                                        }
                                    },
                                    onDelete: { id in
                                        Task {
                                            await viewModel.deleteHistoryTranscript(id: id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                
                if let error = viewModel.transcriptionError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Transcription History")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                Task {
                    await viewModel.refreshHistory(userId: userId)
                }
            }
        }
        .task {
            await viewModel.loadTranscriptionHistory(userId: userId)
        }
    }
}

struct TranscriptionHistoryCard: View {
    let transcript: TranscriptionData
    let onUpdate: (Int, String) -> Void
    let onDelete: (Int) -> Void
    
    @State private var isEditing = false
    @State private var editedText: String
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    init(transcript: TranscriptionData, onUpdate: @escaping (Int, String) -> Void, onDelete: @escaping (Int) -> Void) {
        self.transcript = transcript
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editedText = State(initialValue: transcript.textFinal ?? transcript.finalText)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and edit button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let createdAt = transcript.createdAt {
                        Text(formatDate(createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let duration = transcript.durationSecs,
                       let durationDouble = Double(duration) {
                        Text("Duration: \(formatDuration(durationDouble))s")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            // Raw transcript
            let rawText = transcript.textRaw ?? transcript.rawTranscript
            if !rawText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(rawText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            // Final text
            VStack(alignment: .leading, spacing: 4) {
                Text("Final Text")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(transcript.textFinal ?? transcript.finalText)
                    .font(.body)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // Prompt used (if available)
            if let prompt = transcript.promptUsedBackend ?? transcript.promptUsed, !prompt.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prompt Used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(prompt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Delete Transcription", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = transcript.id {
                    onDelete(id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this transcription? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Edit Transcription")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Final Text")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $editedText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .onTapGesture {
                            // This helps focus the TextEditor
                        }
                    
                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingEditSheet = false
                            editedText = transcript.textFinal ?? transcript.finalText
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            if let id = transcript.id {
                                onUpdate(id, editedText)
                            }
                            showingEditSheet = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        return String(format: "%.1f", seconds)
    }
}

#Preview {
    TranscriptionHistoryView()
}

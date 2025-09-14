//
//  TranscriptionViewModel.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import Foundation
import Combine

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var transcriptionResults: [TranscriptionResult] = []
    @Published var isTranscribing = false
    @Published var transcriptionError: String?
    
    // History functionality
    @Published var transcriptionHistory: [TranscriptionData] = []
    @Published var isLoadingHistory = false
    @Published var hasLoadedHistoryOnce = false
    
    private let transcriptionService = TranscriptionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupRecordingObserver()
    }
    
    private func setupRecordingObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RecordingCompleted"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let audioURL = notification.userInfo?["audioURL"] as? URL else { return }
            self?.transcribeAudio(at: audioURL)
        }
    }
    
    struct TranscriptionResult: Identifiable {
        let id = UUID()
        let audioURL: URL
        let data: TranscriptionData
        let timestamp: Date
    }
    
    func transcribeAudio(at url: URL, prompt: String? = nil, userId: String = "1") {
        Task {
            await performTranscription(audioURL: url, prompt: prompt, userId: userId)
        }
    }
    
    private func performTranscription(audioURL: URL, prompt: String?, userId: String = "1") async {
        isTranscribing = true
        transcriptionError = nil
        
        do {
            let transcriptionData = try await transcriptionService.transcribeAudio(audioURL, prompt: prompt, userId: userId)
            
            let result = TranscriptionResult(
                audioURL: audioURL,
                data: transcriptionData,
                timestamp: Date()
            )
            
            transcriptionResults.insert(result, at: 0)
            
        } catch {
            transcriptionError = error.localizedDescription
        }
        
        isTranscribing = false
    }
    
    func clearResults() {
        transcriptionResults.removeAll()
    }
    
    func removeResult(at indices: IndexSet) {
        transcriptionResults.remove(atOffsets: indices)
    }
    
    func updateTranscript(id: Int, finalText: String) {
        Task {
            await performTranscriptUpdate(id: id, finalText: finalText)
        }
    }
    
    private func performTranscriptUpdate(id: Int, finalText: String) async {
        do {
            let updatedData = try await transcriptionService.updateTranscript(id: id, finalText: finalText)
            
            // Find and update the result in our local array
            if let index = transcriptionResults.firstIndex(where: { $0.data.transcriptId == id }) {
                let originalResult = transcriptionResults[index]
                let updatedResult = TranscriptionResult(
                    audioURL: originalResult.audioURL,
                    data: updatedData,
                    timestamp: originalResult.timestamp
                )
                transcriptionResults[index] = updatedResult
            }
            
        } catch {
            transcriptionError = "Failed to update transcript: \(error.localizedDescription)"
        }
    }
    
    // MARK: - History Management
    
    func loadTranscriptionHistory(userId: String) async {
        // Only load if we haven't loaded once or if explicitly refreshing
        guard !hasLoadedHistoryOnce || !isLoadingHistory else { return }
        
        isLoadingHistory = true
        transcriptionError = nil
        
        do {
            let fetchedTranscripts = try await transcriptionService.getUserTranscripts(userId: userId)
            transcriptionHistory = fetchedTranscripts.sorted { (first, second) in
                // Sort by created date if available, otherwise by ID descending
                if let firstDate = first.createdAt, let secondDate = second.createdAt {
                    return firstDate > secondDate
                }
                return (first.id ?? 0) > (second.id ?? 0)
            }
            hasLoadedHistoryOnce = true
        } catch {
            transcriptionError = error.localizedDescription
        }
        
        isLoadingHistory = false
    }
    
    func updateHistoryTranscript(id: Int, finalText: String) async {
        do {
            let updatedTranscript = try await transcriptionService.updateTranscript(id: id, finalText: finalText)
            
            // Update the history array
            if let index = transcriptionHistory.firstIndex(where: { $0.id == id }) {
                transcriptionHistory[index] = updatedTranscript
            }
        } catch {
            transcriptionError = "Failed to update transcript: \(error.localizedDescription)"
        }
    }
    
    func refreshHistory(userId: String) async {
        hasLoadedHistoryOnce = false
        await loadTranscriptionHistory(userId: userId)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
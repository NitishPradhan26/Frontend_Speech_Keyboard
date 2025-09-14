//
//  APIModels.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import Foundation

// MARK: - Request Models
struct TranscriptionRequest: Codable {
    let audioFile: Data
    let promptText: String?
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case audioFile = "audio"
        case promptText = "prompt"
        case userId = "user_id"
    }
}

struct UpdateTranscriptRequest: Codable {
    let textFinal: String
    
    enum CodingKeys: String, CodingKey {
        case textFinal = "text_final"
    }
}

// MARK: - Response Models
struct TranscriptionResponse: Codable {
    let success: Bool
    let data: TranscriptionData?
    let error: String?
    let message: String? // Backend sometimes returns 'message' instead of 'error'
}

struct UpdateTranscriptResponse: Codable {
    let success: Bool
    let message: String?
    let data: TranscriptionData?
}

struct TranscriptHistoryResponse: Codable {
    let success: Bool
    let count: Int
    let data: [TranscriptionData]
}

struct TranscriptionData: Codable {
    let transcriptId: Int? // Backend returns savedTranscript?.id (number)
    let rawTranscript: String
    let finalText: String
    let duration: Double?
    let promptUsed: String?
    
    // Backend fields (from update endpoint)
    let id: Int?
    let userId: Int?
    let audioUrl: String?
    let durationSecs: String?
    let textRaw: String?
    let textFinal: String?
    let promptUsedBackend: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case transcriptId
        case rawTranscript
        case finalText
        case duration
        case promptUsed
        
        // Backend fields
        case id
        case userId = "user_id"
        case audioUrl = "audio_url"
        case durationSecs = "duration_secs"
        case textRaw = "text_raw"
        case textFinal = "text_final"
        case promptUsedBackend = "prompt_used"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Regular initializer for creating instances in code
    init(transcriptId: Int?, rawTranscript: String, finalText: String, duration: Double?, promptUsed: String?) {
        self.transcriptId = transcriptId
        self.rawTranscript = rawTranscript
        self.finalText = finalText
        self.duration = duration
        self.promptUsed = promptUsed
        
        // Backend fields default to nil
        self.id = nil
        self.userId = nil
        self.audioUrl = nil
        self.durationSecs = nil
        self.textRaw = nil
        self.textFinal = nil
        self.promptUsedBackend = nil
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Always decode backend-specific fields first
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.userId = try container.decodeIfPresent(Int.self, forKey: .userId)
        self.audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)
        self.durationSecs = try container.decodeIfPresent(String.self, forKey: .durationSecs)
        self.textRaw = try container.decodeIfPresent(String.self, forKey: .textRaw)
        self.textFinal = try container.decodeIfPresent(String.self, forKey: .textFinal)
        self.promptUsedBackend = try container.decodeIfPresent(String.self, forKey: .promptUsedBackend)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        // Try both formats (transcribe vs update response)
        if let id = self.id {
            // Update response format - use backend fields
            self.transcriptId = id
            self.rawTranscript = self.textRaw ?? ""
            self.finalText = self.textFinal ?? ""
            self.promptUsed = self.promptUsedBackend
            
            // Convert string duration to double
            if let durationString = self.durationSecs,
               let durationDouble = Double(durationString) {
                self.duration = durationDouble
            } else {
                self.duration = nil
            }
        } else {
            // Transcribe response format - use original fields
            self.transcriptId = try container.decodeIfPresent(Int.self, forKey: .transcriptId)
            self.rawTranscript = try container.decode(String.self, forKey: .rawTranscript)
            self.finalText = try container.decode(String.self, forKey: .finalText)
            self.duration = try container.decodeIfPresent(Double.self, forKey: .duration)
            self.promptUsed = try container.decodeIfPresent(String.self, forKey: .promptUsed)
        }
    }
}

// MARK: - Error Models
enum TranscriptionError: Error, LocalizedError {
    case invalidURL
    case noAudioData
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noAudioData:
            return "No audio data to transcribe"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
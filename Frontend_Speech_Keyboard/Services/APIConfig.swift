//
//  APIConfig.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import Foundation

struct APIConfig {
    static let baseURL = "Your backend url"
    
    enum Endpoints {
        case transcribe
        case prompts
        case userProfile
        case createPrompt
        case updatePrompt(String)
        case deletePrompt(String)
        case updateTranscript(Int)
        case deleteTranscript(Int)
        case userTranscripts(String)
        case userPrompts(String)
        case getPromptById(String)
        
        var path: String {
            switch self {
            case .transcribe:
                return "/transcripts/transcribeAndCorrect"
            case .prompts:
                return "/prompts"
            case .userProfile:
                return "/users/profile"
            case .createPrompt:
                return "/prompts"
            case .updatePrompt(let id):
                return "/prompts/\(id)"
            case .deletePrompt(let id):
                return "/prompts/\(id)"
            case .updateTranscript(let id):
                return "/transcripts/\(id)"
            case .deleteTranscript(let id):
                return "/transcripts/\(id)"
            case .userTranscripts(let userId):
                return "/transcripts/user/\(userId)"
            case .userPrompts(let userId):
                return "/prompts/user/\(userId)"
            case .getPromptById(let id):
                return "/prompts/\(id)"
            }
        }
        
        var fullURL: URL? {
            URL(string: APIConfig.baseURL + path)
        }
    }
    
    // HTTP Methods
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
    }
    
    // Common headers
    static var defaultHeaders: [String: String] {
        return [
            "Accept": "application/json",
            "User-Agent": "SpeechKeyboard-iOS/1.0"
        ]
    }
    
    // Request timeout
    static let requestTimeout: TimeInterval = 30.0
    static let uploadTimeout: TimeInterval = 60.0 // Longer for audio uploads
}

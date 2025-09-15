//
//  TranscriptionService.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import Foundation
import AVFoundation

protocol TranscriptionServiceProtocol {
    func transcribeAudio(_ audioURL: URL, prompt: String?, userId: String) async throws -> TranscriptionData
    func updateTranscript(id: Int, finalText: String) async throws -> TranscriptionData
    func deleteTranscript(id: Int) async throws -> Bool
    func getUserTranscripts(userId: String) async throws -> [TranscriptionData]
}

class TranscriptionService: TranscriptionServiceProtocol {
    static let shared = TranscriptionService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.timeoutIntervalForResource = APIConfig.uploadTimeout
        self.session = URLSession(configuration: config)
    }
    
    func transcribeAudio(_ audioURL: URL, prompt: String? = nil, userId: String = "1") async throws -> TranscriptionData {
        guard let url = APIConfig.Endpoints.transcribe.fullURL else {
            throw TranscriptionError.invalidURL
        }
        
        // Read audio file data
        guard let audioData = try? Data(contentsOf: audioURL) else {
            throw TranscriptionError.noAudioData
        }
        
        // Create multipart form data request
        let request = try createMultipartRequest(url: url, audioData: audioData, prompt: prompt, userId: userId)
        
        print("Request URL: \(request.url?.absoluteString ?? "nil")")
        print("Request method: \(request.httpMethod ?? "nil")")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Audio data size: \(audioData.count) bytes")
        print("Prompt: \(prompt ?? "nil")")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response and log details for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    // Try to parse error response
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Error response: \(responseString)")
                    }
                    throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw API response: \(responseString)")
            }
            
            // Decode response
            let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            
            if transcriptionResponse.success, let data = transcriptionResponse.data {
                return data
            } else {
                throw TranscriptionError.serverError(transcriptionResponse.error ?? "Unknown server error")
            }
            
        } catch let error as TranscriptionError {
            throw error
        } catch let decodingError as DecodingError {
            throw TranscriptionError.decodingError(decodingError)
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func createMultipartRequest(url: URL, audioData: Data, prompt: String?, userId: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = APIConfig.HTTPMethod.POST.rawValue
        
        // Add default headers
        for (key, value) in APIConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create multipart boundary
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        let body = createMultipartBody(boundary: boundary, audioData: audioData, prompt: prompt, userId: userId)
        request.httpBody = body
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        
        return request
    }
    
    private func createMultipartBody(boundary: String, audioData: Data, prompt: String?, userId: String) -> Data {
        var body = Data()
        
        // Add audio file part (backend expects req.file)
        body.append(createFormDataPart(
            boundary: boundary,
            name: "audio", // Multer is configured for 'audio' field with upload.single('audio')
            filename: "recording.m4a", 
            contentType: "audio/mp4",
            data: audioData
        ))
        
        // Add required user_id
        body.append(createFormDataPart(
            boundary: boundary,
            name: "user_id",
            data: userId.data(using: .utf8) ?? Data()
        ))
        
        // Add prompt part if provided
        if let prompt = prompt, !prompt.isEmpty {
            body.append(createFormDataPart(
                boundary: boundary,
                name: "prompt",
                data: prompt.data(using: .utf8) ?? Data()
            ))
        }
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())
        
        return body
    }
    
    private func createFormDataPart(
        boundary: String,
        name: String,
        filename: String? = nil,
        contentType: String? = nil,
        data: Data
    ) -> Data {
        var part = Data()
        
        part.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        
        if let filename = filename {
            part.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8) ?? Data())
        } else {
            part.append("Content-Disposition: form-data; name=\"\(name)\"\r\n".data(using: .utf8) ?? Data())
        }
        
        if let contentType = contentType {
            part.append("Content-Type: \(contentType)\r\n".data(using: .utf8) ?? Data())
        }
        
        part.append("\r\n".data(using: .utf8) ?? Data())
        part.append(data)
        part.append("\r\n".data(using: .utf8) ?? Data())
        
        return part
    }
    
    // MARK: - Update Transcript
    
    func updateTranscript(id: Int, finalText: String) async throws -> TranscriptionData {
        guard let url = APIConfig.Endpoints.updateTranscript(id).fullURL else {
            throw TranscriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = APIConfig.HTTPMethod.PUT.rawValue
        
        // Add default headers
        for (key, value) in APIConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let updateRequest = UpdateTranscriptRequest(textFinal: finalText)
        request.httpBody = try JSONEncoder().encode(updateRequest)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Update error response: \(responseString)")
                    }
                    throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Update API response: \(responseString)")
            }
            
            // Decode response
            let updateResponse = try JSONDecoder().decode(UpdateTranscriptResponse.self, from: data)
            
            if updateResponse.success, let data = updateResponse.data {
                return data
            } else {
                throw TranscriptionError.serverError(updateResponse.message ?? "Update failed")
            }
            
        } catch let error as TranscriptionError {
            throw error
        } catch let decodingError as DecodingError {
            throw TranscriptionError.decodingError(decodingError)
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
    
    // MARK: - Delete Transcript
    
    func deleteTranscript(id: Int) async throws -> Bool {
        guard let url = APIConfig.Endpoints.deleteTranscript(id).fullURL else {
            throw TranscriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = APIConfig.HTTPMethod.DELETE.rawValue
        
        // Add default headers
        for (key, value) in APIConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Delete transcript error response: \(responseString)")
                    }
                    throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Delete transcript API response: \(responseString)")
            }
            
            // Decode response
            let deleteResponse = try JSONDecoder().decode(DeleteTranscriptResponse.self, from: data)
            
            if deleteResponse.success {
                return true
            } else {
                throw TranscriptionError.serverError(deleteResponse.message ?? "Delete failed")
            }
            
        } catch let error as TranscriptionError {
            throw error
        } catch let decodingError as DecodingError {
            throw TranscriptionError.decodingError(decodingError)
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
    
    // MARK: - Get User Transcripts
    
    func getUserTranscripts(userId: String) async throws -> [TranscriptionData] {
        guard let url = APIConfig.Endpoints.userTranscripts(userId).fullURL else {
            throw TranscriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = APIConfig.HTTPMethod.GET.rawValue
        
        // Add default headers
        for (key, value) in APIConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Get transcripts error response: \(responseString)")
                    }
                    throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Get transcripts API response: \(responseString)")
            }
            
            // Decode response
            let historyResponse = try JSONDecoder().decode(TranscriptHistoryResponse.self, from: data)
            
            if historyResponse.success {
                return historyResponse.data
            } else {
                throw TranscriptionError.serverError("Failed to fetch transcripts")
            }
            
        } catch let error as TranscriptionError {
            throw error
        } catch let decodingError as DecodingError {
            throw TranscriptionError.decodingError(decodingError)
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
}
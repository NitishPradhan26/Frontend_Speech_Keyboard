//
//  PromptService.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-13.
//

import Foundation

protocol PromptServiceProtocol {
    func getUserPrompts(userId: String) async throws -> [PromptData]
    func createPrompt(userId: Int, title: String, content: String, isDefault: Bool?) async throws -> PromptData
    func updatePrompt(id: String, title: String?, content: String?, isDefault: Bool?) async throws -> PromptData
    func deletePrompt(id: String) async throws -> Bool
    func getPromptById(id: String) async throws -> PromptData
}

class PromptService: PromptServiceProtocol {
    static let shared = PromptService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.timeoutIntervalForResource = APIConfig.uploadTimeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Get User Prompts
    
    func getUserPrompts(userId: String) async throws -> [PromptData] {
        guard let url = APIConfig.Endpoints.userPrompts(userId).fullURL else {
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
                        print("Get user prompts error response: \(responseString)")
                    }
                    throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Get user prompts API response: \(responseString)")
            }
            
            // Decode response
            let promptsResponse = try JSONDecoder().decode(PromptsListResponse.self, from: data)
            
            if promptsResponse.success {
                return promptsResponse.data
            } else {
                throw TranscriptionError.promptError(promptsResponse.error ?? "Failed to fetch prompts")
            }
            
        } catch let error as TranscriptionError {
            throw error
        } catch let decodingError as DecodingError {
            throw TranscriptionError.decodingError(decodingError)
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
    
    // MARK: - Create Prompt
    
    func createPrompt(userId: Int, title: String, content: String, isDefault: Bool? = false) async throws -> PromptData {
        guard let url = APIConfig.Endpoints.createPrompt.fullURL else {
            throw TranscriptionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = APIConfig.HTTPMethod.POST.rawValue
        
        // Add default headers
        for (key, value) in APIConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let createRequest = CreatePromptRequest(
            userId: userId,
            title: title,
            content: content,
            isDefault: isDefault
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(createRequest)
        
        // Debug: Print request details
        print("Create prompt request URL: \(url)")
        print("Create prompt request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
        print("Create prompt headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("Create prompt HTTP status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 201 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Create prompt error response: \(responseString)")
                        
                        // Try to parse error response for better error message
                        if let errorData = try? JSONDecoder().decode(PromptResponse.self, from: data),
                           let errorMessage = errorData.error ?? errorData.message {
                            throw TranscriptionError.promptError(errorMessage)
                        }
                    }
                    
                    // Provide more specific error messages
                    switch httpResponse.statusCode {
                    case 400:
                        throw TranscriptionError.promptError("Invalid prompt data")
                    case 401:
                        throw TranscriptionError.promptError("Authentication required")
                    case 403:
                        throw TranscriptionError.promptError("Permission denied")
                    case 404:
                        throw TranscriptionError.promptError("Endpoint not found")
                    case 500:
                        throw TranscriptionError.promptError("Server internal error")
                    case 503:
                        throw TranscriptionError.promptError("Server temporarily unavailable. Please try again later.")
                    default:
                        throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                    }
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Create prompt API response: \(responseString)")
            }
            
            // Decode response
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            if promptResponse.success, let promptData = promptResponse.data {
                return promptData
            } else {
                throw TranscriptionError.promptError(promptResponse.error ?? "Failed to create prompt")
            }
            
        } catch let error as TranscriptionError {
            throw error
        } catch let decodingError as DecodingError {
            throw TranscriptionError.decodingError(decodingError)
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
    
    // MARK: - Update Prompt
    
    func updatePrompt(id: String, title: String? = nil, content: String? = nil, isDefault: Bool? = nil) async throws -> PromptData {
        guard let url = APIConfig.Endpoints.updatePrompt(id).fullURL else {
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
        let updateRequest = UpdatePromptRequest(
            title: title,
            content: content,
            isDefault: isDefault
        )
        request.httpBody = try JSONEncoder().encode(updateRequest)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Update prompt error response: \(responseString)")
                    }
                    throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Update prompt API response: \(responseString)")
            }
            
            // Decode response
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            if promptResponse.success, let promptData = promptResponse.data {
                return promptData
            } else {
                throw TranscriptionError.promptError(promptResponse.error ?? "Failed to update prompt")
            }
            
        } catch let error as TranscriptionError {
            throw error
        } catch let decodingError as DecodingError {
            throw TranscriptionError.decodingError(decodingError)
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
    
    // MARK: - Delete Prompt
    
    func deletePrompt(id: String) async throws -> Bool {
        guard let url = APIConfig.Endpoints.deletePrompt(id).fullURL else {
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
                        print("Delete prompt error response: \(responseString)")
                    }
                    throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Delete prompt API response: \(responseString)")
            }
            
            // For delete, we just return success if no error occurred
            return true
            
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
    
    // MARK: - Get Prompt By ID
    
    func getPromptById(id: String) async throws -> PromptData {
        guard let url = APIConfig.Endpoints.getPromptById(id).fullURL else {
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
                        print("Get prompt by ID error response: \(responseString)")
                    }
                    throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Get prompt by ID API response: \(responseString)")
            }
            
            // Decode response
            let promptResponse = try JSONDecoder().decode(PromptResponse.self, from: data)
            
            if promptResponse.success, let promptData = promptResponse.data {
                return promptData
            } else {
                throw TranscriptionError.promptError(promptResponse.error ?? "Failed to get prompt")
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
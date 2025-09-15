//
//  PromptViewModel.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-13.
//

import Foundation
import Combine

@MainActor
class PromptViewModel: ObservableObject {
    @Published var prompts: [PromptData] = []
    @Published var selectedPrompt: PromptData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedOnce = false
    
    private let promptService: PromptServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(promptService: PromptServiceProtocol = PromptService.shared) {
        self.promptService = promptService
    }
    
    // MARK: - Load Prompts
    
    func loadPrompts(userId: String) async {
        // Only load if we haven't loaded once or if explicitly refreshing
        guard !hasLoadedOnce || !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPrompts = try await promptService.getUserPrompts(userId: userId)
            prompts = fetchedPrompts.sorted { (first, second) in
                // Sort by: default prompts first, then by creation date
                if let firstDefault = first.isDefault, let secondDefault = second.isDefault {
                    if firstDefault != secondDefault {
                        return firstDefault && !secondDefault
                    }
                }
                
                if let firstDate = first.createdAt, let secondDate = second.createdAt {
                    return firstDate > secondDate
                }
                return first.id > second.id
            }
            
            // Set default selected prompt if none selected
            if selectedPrompt == nil {
                selectedPrompt = prompts.first { $0.isDefault == true } ?? prompts.first
            }
            
            hasLoadedOnce = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Create Prompt
    
    func createPrompt(userId: Int, title: String, content: String, isDefault: Bool = false) async {
        do {
            let newPrompt = try await promptService.createPrompt(
                userId: userId,
                title: title,
                content: content,
                isDefault: isDefault
            )
            
            // Add new prompt to the list and sort
            prompts.append(newPrompt)
            prompts.sort { (first, second) in
                if let firstDefault = first.isDefault, let secondDefault = second.isDefault {
                    if firstDefault != secondDefault {
                        return firstDefault && !secondDefault
                    }
                }
                
                if let firstDate = first.createdAt, let secondDate = second.createdAt {
                    return firstDate > secondDate
                }
                return first.id > second.id
            }
            
            // If this is the first prompt or it's marked as default, select it
            if prompts.count == 1 || isDefault {
                selectedPrompt = newPrompt
            }
            
        } catch {
            errorMessage = "Failed to create prompt: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Update Prompt
    
    func updatePrompt(id: String, title: String?, content: String?, isDefault: Bool? = nil) async {
        do {
            let updatedPrompt = try await promptService.updatePrompt(
                id: id,
                title: title,
                content: content,
                isDefault: isDefault
            )
            
            // Update the local array
            if let index = prompts.firstIndex(where: { $0.id == Int(id) }) {
                prompts[index] = updatedPrompt
                
                // Update selected prompt if it's the one we just updated
                if selectedPrompt?.id == updatedPrompt.id {
                    selectedPrompt = updatedPrompt
                }
            }
            
        } catch {
            errorMessage = "Failed to update prompt: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Delete Prompt
    
    func deletePrompt(id: String) async {
        do {
            let success = try await promptService.deletePrompt(id: id)
            
            if success {
                // Remove from local array
                prompts.removeAll { $0.id == Int(id) }
                
                // If we deleted the selected prompt, select another one
                if selectedPrompt?.id == Int(id) {
                    selectedPrompt = prompts.first { $0.isDefault == true } ?? prompts.first
                }
            }
            
        } catch {
            errorMessage = "Failed to delete prompt: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    
    func refreshPrompts(userId: String) async {
        hasLoadedOnce = false
        await loadPrompts(userId: userId)
    }
    
    func selectPrompt(_ prompt: PromptData) {
        selectedPrompt = prompt
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    var selectedPromptContent: String? {
        return selectedPrompt?.content
    }
    
    var selectedPromptTitle: String? {
        return selectedPrompt?.title
    }
}
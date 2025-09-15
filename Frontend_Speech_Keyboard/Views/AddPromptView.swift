//
//  AddPromptView.swift
//  Frontend_Speech_Keyboard
//
//  Created by Claude on 2025-09-13.
//

import SwiftUI

struct AddPromptView: View {
    @ObservedObject var promptViewModel: PromptViewModel
    let userId: Int
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isDefault: Bool = false
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt Title")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextField("Enter a descriptive title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onTapGesture {
                            // Keep keyboard focused
                        }
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt Content")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("This will be used to improve transcription accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .onTapGesture {
                            // This helps focus the TextEditor
                        }
                    
                    if content.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Example prompts:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            Text("• \"Make this text more professional and formal\"")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("• \"Fix grammar and spelling errors\"")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("• \"Convert to bullet points\"")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Default Toggle
                HStack {
                    Toggle("Set as default prompt", isOn: $isDefault)
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Error Display
                if let error = promptViewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("New Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await createPrompt()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                             content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             isCreating)
                }
            }
            .disabled(isCreating)
        }
        .onAppear {
            promptViewModel.clearError()
        }
    }
    
    private func createPrompt() async {
        isCreating = true
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        await promptViewModel.createPrompt(
            userId: userId,
            title: trimmedTitle,
            content: trimmedContent,
            isDefault: isDefault
        )
        
        isCreating = false
        
        // Dismiss if successful (no error message)
        if promptViewModel.errorMessage == nil {
            dismiss()
        }
    }
}

// Extension to dismiss keyboard (reusing from TranscriptionHistoryView)
extension AddPromptView {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    AddPromptView(promptViewModel: PromptViewModel(), userId: 1)
}
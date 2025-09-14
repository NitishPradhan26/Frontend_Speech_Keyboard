//
//  KeyboardViewController.swift
//  Speech_Keyboard
//
//  Created by Nitish Pradhan on 2025-09-11.
//

import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    
    private var keyboardHostingController: UIHostingController<KeyboardView>?
    private var nextKeyboardButton: UIButton?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Set keyboard height
        let keyboardHeight: CGFloat = 150
        if let heightConstraint = view.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.constant = keyboardHeight
        } else {
            view.heightAnchor.constraint(equalToConstant: keyboardHeight).isActive = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure KeyboardIPC with extension context
        if let extensionContext = self.extensionContext {
            KeyboardIPC.shared.configure(with: extensionContext)
        }
        
        setupKeyboardUI()
        setupNextKeyboardButton()
        setupTextInsertionListener()
    }
    
    private func setupKeyboardUI() {
        // Create SwiftUI keyboard view
        let keyboardView = KeyboardView()
        let hostingController = UIHostingController(rootView: keyboardView)
        
        // Configure hosting controller
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        keyboardHostingController = hostingController
    }
    
    private func setupNextKeyboardButton() {
        // Defer the check until after view is fully loaded
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.needsInputModeSwitchKey else { return }
            
            self.nextKeyboardButton = UIButton(type: .system)
            self.nextKeyboardButton?.setTitle("🌐", for: [])
            self.nextKeyboardButton?.titleLabel?.font = UIFont.systemFont(ofSize: 20)
            self.nextKeyboardButton?.translatesAutoresizingMaskIntoConstraints = false
            self.nextKeyboardButton?.addTarget(self, action: #selector(self.handleInputModeList(from:with:)), for: .allTouchEvents)
            
            if let button = self.nextKeyboardButton {
                self.view.addSubview(button)
                NSLayoutConstraint.activate([
                    button.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 12),
                    button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -12),
                    button.widthAnchor.constraint(equalToConstant: 30),
                    button.heightAnchor.constraint(equalToConstant: 30)
                ])
            }
        }
    }
    
    private func setupTextInsertionListener() {
        // Listen for completed transcriptions to insert
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("InsertTranscribedText"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let text = notification.userInfo?["text"] as? String {
                self?.insertText(text)
            }
        }
        
        // Check for pending text insertion on load
        checkForPendingTextInsertion()
    }
    
    private func checkForPendingTextInsertion() {
        guard let userDefaults = UserDefaults(suiteName: "group.com.geniusinnovationlab.speechkb"),
              let textToInsert = userDefaults.string(forKey: "text_to_insert") else { return }
        
        // Insert the text
        textDocumentProxy.insertText(textToInsert)
        
        // Clean up
        userDefaults.removeObject(forKey: "text_to_insert")
        userDefaults.synchronize()
    }
    
    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateButtonAppearance()
    }
    
    private func updateButtonAppearance() {
        guard let button = nextKeyboardButton else { return }
        
        let textColor: UIColor = textDocumentProxy.keyboardAppearance == .dark ? .white : .black
        button.setTitleColor(textColor, for: [])
        
        // Check needsInputModeSwitchKey safely
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            button.isHidden = !self.needsInputModeSwitchKey
        }
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents
        super.textWillChange(textInput)
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents
        super.textDidChange(textInput)
        updateButtonAppearance()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

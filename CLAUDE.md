# iOS Speech Keyboard - Frontend Project

## General Description

An iOS speech-to-text keyboard extension that provides system-wide voice dictation capabilities. The project consists of a main iOS app and a custom keyboard extension that work together to capture audio, transcribe speech using AI, and intelligently insert cleaned text into any text field across iOS.

### Key Features
- Custom iOS keyboard extension with voice recording controls
- Background audio recording through main app (bypassing keyboard extension limitations)
- AI-powered speech transcription with prompt-based text cleaning
- Intelligent text editing with tap-to-correct and suggestion features
- User prompt library management
- Transcription history with playback and editing capabilities
- Firebase Authentication with Sign in with Apple
- Subscription management with StoreKit integration

## Tech Stack

### iOS Frontend
- **Language**: Swift 5.8+
- **UI Framework**: SwiftUI (iOS 15+)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Authentication**: Firebase Auth with Sign in with Apple
- **Audio**: AVFoundation
- **Networking**: URLSession with async/await
- **Data Persistence**: Core Data + UserDefaults (App Groups)
- **In-App Purchases**: StoreKit 2
- **Minimum iOS Version**: iOS 15.0

### Development Tools
- **IDE**: Xcode 14+
- **Dependency Management**: Swift Package Manager
- **Testing**: XCTest, XCUITest
- **Code Quality**: SwiftLint, SwiftFormat
- **CI/CD**: Xcode Cloud (when available)

## Project Structure

```
Frontend_Speech_Keyboard/
├── SpeechKeyboard/                 # Main iOS App Target
│   ├── App/
│   │   ├── SpeechKeyboardApp.swift # App entry point
│   │   └── AppDelegate.swift       # App lifecycle management
│   ├── Views/                      # SwiftUI Views
│   │   ├── Authentication/         # Login/signup screens
│   │   ├── Home/                   # Main dashboard
│   │   ├── Prompts/               # Prompt management UI
│   │   ├── History/               # Transcription history
│   │   ├── Settings/              # App settings & account
│   │   └── Components/            # Reusable UI components
│   ├── ViewModels/                # MVVM ViewModels
│   │   ├── AuthenticationViewModel.swift
│   │   ├── PromptsViewModel.swift
│   │   ├── HistoryViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Models/                    # Data models
│   │   ├── User.swift
│   │   ├── Prompt.swift
│   │   ├── Transcription.swift
│   │   └── APIModels/            # API request/response models
│   ├── Services/                 # Business logic & API clients
│   │   ├── AudioService.swift    # Audio recording management
│   │   ├── TranscriptionService.swift # API communication
│   │   ├── AuthService.swift     # Firebase Auth wrapper
│   │   └── StorageService.swift  # Data persistence
│   ├── Utilities/                # Helper functions & extensions
│   │   ├── Extensions/           # Swift extensions
│   │   ├── Constants.swift       # App constants
│   │   └── Helpers.swift         # Utility functions
│   └── Resources/                # Assets, localizations, etc.
│       ├── Assets.xcassets
│       ├── Localizable.strings
│       └── Info.plist
│
├── KeyboardExtension/             # Custom Keyboard Extension Target
│   ├── KeyboardViewController.swift # Main keyboard controller
│   ├── Views/                    # Keyboard UI components
│   │   ├── RecordingView.swift   # Recording controls
│   │   ├── PromptSelectorView.swift # Quick prompt selection
│   │   └── StatusIndicatorView.swift # Recording status
│   ├── ViewModels/               # Keyboard-specific ViewModels
│   │   └── KeyboardViewModel.swift
│   ├── Services/                 # Keyboard services
│   │   ├── KeyboardCommunicationService.swift # App communication
│   │   ├── TextEditingService.swift # Text manipulation
│   │   └── CorrectionService.swift # Auto-correction logic
│   ├── Models/                   # Keyboard-specific models
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
│
├── Shared/                       # Shared code between targets
│   ├── Models/                   # Common data models
│   ├── Services/                 # Shared services
│   ├── Extensions/               # Common extensions
│   └── Constants.swift           # Shared constants
│
├── Tests/                        # Unit tests
│   ├── SpeechKeyboardTests/      # Main app tests
│   ├── KeyboardExtensionTests/   # Keyboard extension tests
│   └── SharedTests/              # Shared code tests
│
├── UITests/                      # UI automation tests
│   └── SpeechKeyboardUITests/
│
├── Packages/                     # Local Swift Packages (if any)
│
└── Configuration/                # Build configuration
    ├── Debug.xcconfig
    ├── Release.xcconfig
    └── Shared.xcconfig
```

### Folder Usage Comments

- **SpeechKeyboard/**: Main app target containing core functionality, UI, and business logic
- **KeyboardExtension/**: Lightweight keyboard extension with minimal UI and communication logic
- **Shared/**: Code shared between main app and extension (models, utilities, constants)
- **Tests/**: Comprehensive unit tests for all components
- **UITests/**: End-to-end automation tests for user workflows
- **Configuration/**: Build settings and environment-specific configurations

## Data Architecture

### Core Data Models

```swift
// User authentication and profile
struct User {
    let uid: String              // Firebase UID
    let email: String?           // May be anonymized by Apple
    let displayName: String?
    let subscriptionStatus: SubscriptionStatus
    let createdAt: Date
}

// User-defined prompts for text cleaning
struct Prompt {
    let id: UUID
    let title: String
    let content: String          // AI prompt text
    let isDefault: Bool
    let category: PromptCategory
    let createdAt: Date
}

// Transcription records
struct Transcription {
    let id: UUID
    let userId: String
    let audioFileURL: URL?       // Local storage path
    let originalText: String     // Raw transcription
    let cleanedText: String      // AI-processed text
    let promptUsed: Prompt?
    let duration: TimeInterval
    let createdAt: Date
    let corrections: [TextCorrection] // User corrections
}

// User text corrections for learning
struct TextCorrection {
    let original: String
    let corrected: String
    let frequency: Int           // How often this correction was made
    let confidence: Double       // Fuzzy match threshold
}
```

### Data Flow

1. **Authentication**: Firebase Auth → UserDefaults (App Group) → Keyboard Extension
2. **Audio Recording**: Main App (AVFoundation) → Shared Container → Keyboard Extension
3. **Transcription**: Keyboard Extension → API → Core Data → UI Update
4. **Corrections**: User Input → Local Dictionary → Backend Sync
5. **Prompts**: Core Data ↔ API ↔ Keyboard Extension (via App Group)

### Storage Strategy

- **Core Data**: Main app database for prompts, transcriptions, user corrections
- **App Group Container**: Shared storage for audio files and communication between app and extension
- **UserDefaults (App Group)**: Lightweight data sharing (auth tokens, settings)
- **Keychain**: Secure storage for sensitive data (API keys, tokens)

## Styling Guidelines

### Design System

```swift
// Colors
struct AppColors {
    static let primary = Color("PrimaryBlue")      // #007AFF
    static let secondary = Color("SecondaryGray")  // #8E8E93
    static let accent = Color("AccentGreen")       // #34C759
    static let background = Color("Background")    // Dynamic: White/Black
    static let surface = Color("Surface")          // Dynamic: Gray variations
}

// Typography
struct AppFonts {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline.weight(.medium)
    static let body = Font.body
    static let caption = Font.caption
}

// Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

### UI Patterns

- **Consistent Navigation**: NavigationView with uniform styling
- **Form Inputs**: Standardized text fields with validation states
- **Buttons**: Primary, secondary, and destructive action styles
- **Loading States**: Unified loading indicators and skeleton screens
- **Error Handling**: Consistent error message presentation
- **Accessibility**: VoiceOver support, Dynamic Type, high contrast modes

## Testing Setup

### Unit Testing (XCTest)

```swift
// Test structure
Tests/
├── ViewModelTests/           # Business logic testing
├── ServiceTests/             # API and data service testing
├── ModelTests/               # Data model validation
├── UtilityTests/             # Helper function testing
└── MockObjects/              # Test doubles and mocks
```

### UI Testing (XCUITest)

```swift
// Key user flows to test
- Authentication flow (Sign in with Apple)
- Recording and transcription workflow
- Prompt creation and management
- Text correction and editing
- Settings and subscription management
```

### Test Configuration

- **Test Targets**: Separate test bundles for main app and keyboard extension
- **Mock Services**: Stubbed network responses for reliable testing
- **Test Data**: Predefined test datasets for consistent testing
- **CI/CD Integration**: Automated test runs on commit/PR

### Testing Commands

```bash
# Run all tests
xcodebuild test -scheme SpeechKeyboard -destination 'platform=iOS Simulator,name=iPhone 14'

# Run specific test bundle
xcodebuild test -scheme SpeechKeyboard -only-testing:SpeechKeyboardTests

# Generate code coverage
xcodebuild test -scheme SpeechKeyboard -enableCodeCoverage YES
```

## Coding Principles & Swift Best Practices

### Clean Code Principles

1. **Single Responsibility**: Each class/struct has one reason to change
2. **Open/Closed**: Open for extension, closed for modification
3. **Liskov Substitution**: Subtypes must be substitutable for base types
4. **Interface Segregation**: Depend on abstractions, not concretions
5. **Dependency Inversion**: High-level modules shouldn't depend on low-level modules

### Swift-Specific Best Practices

#### Code Organization
```swift
// MARK: - Protocol definitions at top
protocol AudioServiceProtocol {
    func startRecording() async throws
    func stopRecording() async throws -> URL
}

// MARK: - Implementation
class AudioService: AudioServiceProtocol {
    // MARK: - Properties
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Public Methods
    func startRecording() async throws {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func configureAudioSession() throws {
        // Implementation
    }
}
```

#### Error Handling
```swift
// Use Swift's Result type for clear error handling
enum AudioError: Error, LocalizedError {
    case permissionDenied
    case recordingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required"
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        }
    }
}
```

#### Async/Await Usage
```swift
// Prefer async/await over completion handlers
class TranscriptionService {
    func transcribeAudio(_ audioURL: URL) async throws -> TranscriptionResult {
        let request = createTranscriptionRequest(audioURL)
        let (data, response) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TranscriptionResult.self, from: data)
    }
}
```

#### SwiftUI Best Practices
```swift
// Extract subviews for better readability
struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            RecordingButton(isRecording: viewModel.isRecording) {
                Task {
                    await viewModel.toggleRecording()
                }
            }
            
            StatusIndicator(status: viewModel.status)
        }
        .padding(AppSpacing.lg)
    }
}

// Separate ViewModels for testability
@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var status: RecordingStatus = .idle
    
    private let audioService: AudioServiceProtocol
    
    init(audioService: AudioServiceProtocol = AudioService()) {
        self.audioService = audioService
    }
}
```

### Architecture Guidelines

- **MVVM Pattern**: Views bind to ViewModels, ViewModels interact with Services
- **Dependency Injection**: Use protocols and inject dependencies for testability
- **Repository Pattern**: Abstract data sources behind repository interfaces
- **Coordinator Pattern**: For complex navigation flows
- **Observer Pattern**: Use Combine/SwiftUI for reactive programming

### Performance Optimization

- **Lazy Loading**: Load data and views on-demand
- **Memory Management**: Use weak references to break retain cycles
- **Background Processing**: Move heavy operations off the main thread
- **Caching**: Implement appropriate caching strategies for API responses
- **Image Optimization**: Use appropriate image sizes and compression

### Security Best Practices

- **Secure Storage**: Use Keychain for sensitive data
- **API Security**: Implement proper authentication and token refresh
- **Input Validation**: Validate all user inputs
- **Encryption**: Encrypt audio files and sensitive data in transit
- **Permission Handling**: Request minimal necessary permissions

This project follows Apple's Human Interface Guidelines and adheres to App Store Review Guidelines, ensuring a native iOS experience with robust functionality and maintainable code architecture.
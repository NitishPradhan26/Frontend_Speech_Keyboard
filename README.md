# iOS Speech Keyboard
A native iOS application featuring a custom keyboard extension with AI-powered speech-to-text capabilities, intelligent transcription processing, and seamless system-wide voice dictation integration.

## ✨ Features

### 🎙️ Advanced Speech Recognition & Processing
- **High-Quality Recording**: Native AVFoundation integration for crystal-clear audio capture
- **AI-Powered Transcription**: Seamless integration with backend speech-to-text services
- **Intelligent Text Enhancement**: Custom prompts for personalized text processing and grammar correction
- **Real-Time Processing**: Live recording status and instant transcription feedback
- **Audio Management**: Complete recording lifecycle with play, pause, resume, and delete capabilities

### 📱 Native iOS Keyboard Extension
- **System-Wide Integration**: Custom keyboard that works in any iOS app
- **Background Audio Processing**: Leverages main app for recording while maintaining keyboard functionality
- **Inter-Process Communication**: Seamless data sharing between keyboard extension and main app
- **Native iOS Design**: Follows Apple's Human Interface Guidelines for optimal user experience
- **Accessibility Support**: Full VoiceOver and Dynamic Type compatibility

### 🔧 User Management & Customization
- **Custom Prompts**: Create and manage personalized text processing prompts
- **Transcription History**: Complete history with search, edit, and playback capabilities
- **User Preferences**: Configurable settings for recording quality and processing options
- **App Group Storage**: Secure data sharing between app and keyboard extension
- **Offline Capability**: Core functionality works without network connectivity

### 🛡️ Security & Privacy
- **App Group Container**: Secure data isolation and sharing
- **Keychain Integration**: Secure storage for sensitive authentication data
- **Permission Management**: Proper microphone and storage permission handling
- **Data Encryption**: Secure transmission of audio files and transcriptions
- **Privacy Compliance**: Follows Apple's privacy guidelines and App Store requirements

### 📊 Performance & Reliability
- **Memory Optimization**: Efficient audio buffer management and memory usage
- **Background Processing**: Handles long recordings without UI interruption
- **Error Handling**: Comprehensive error recovery and user feedback
- **Audio Session Management**: Proper handling of audio interruptions and route changes
- **Battery Optimization**: Power-efficient recording and processing algorithms

## 🛠️ Tech Stack

### iOS Frontend
- **Language**: Swift 5.8+
- **UI Framework**: SwiftUI (iOS 15+)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Audio Processing**: AVFoundation
- **Networking**: URLSession with async/await
- **Authentication**: Firebase Auth with Sign in with Apple
- **Data Persistence**: Core Data + UserDefaults (App Groups)
- **In-App Purchases**: StoreKit 2 (subscription management)
- **Minimum iOS Version**: iOS 15.0

### Backend Integration
- **API Communication**: RESTful APIs with JSON
- **Audio Upload**: Multipart form data with audio files
- **Real-time Updates**: Automatic data synchronization
- **Error Handling**: Comprehensive error management
- **Network Resilience**: Retry logic and offline capabilities

### Development Tools
- **IDE**: Xcode 14+
- **Dependency Management**: Swift Package Manager
- **Testing**: XCTest, XCUITest
- **Code Quality**: SwiftLint, SwiftFormat
- **Version Control**: Git with branching strategy

## 🚀 Quick Start

### Prerequisites
- **Xcode 14+** - Latest version recommended
- **iOS 15.0+** device or simulator
- **Apple Developer Account** - For keyboard extension capabilities
- **Backend API access** - Transcription service endpoint

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd Frontend_Speech_Keyboard
```

2. **Open in Xcode**
```bash
open Frontend_Speech_Keyboard.xcodeproj
```

3. **Configure API endpoints**
⚠️ **IMPORTANT**: Set up the backend server first, then update the API URL.
Update `Frontend_Speech_Keyboard/Services/APIConfig.swift` with your deployed backend URL:
```swift
struct APIConfig {
    static let baseURL = "https://your-backend-url.com/api"
}
```
**Backend Setup**: See the companion [Backend Speech Keyboard](../Backend_Speech_Keyboard) repository for complete backend deployment instructions.

4. **Set up App Groups**
- Create App Group in Apple Developer Console
- Add App Group capability to both main app and keyboard extension
- Update shared container identifiers in project settings

5. **Configure Firebase**
- Add `GoogleService-Info.plist` to the project
- Configure Firebase Authentication
- Set up Sign in with Apple

6. **Build and run**
- Select your target device
- Build and install the main app
- Enable the keyboard extension in iOS Settings

## 🔧 Configuration

### Backend API Setup
⚠️ **Backend Server Required**: This iOS app requires a backend server to be deployed and configured before use.

**Configuration Steps:**
1. Deploy the backend server (see [Backend Speech Keyboard](../Backend_Speech_Keyboard) repository)
2. Update `Frontend_Speech_Keyboard/Services/APIConfig.swift` with your backend URL

The app communicates with the backend using these endpoints:

**Transcription**
- `POST /transcripts/transcribeAndCorrect` - Audio transcription with prompt processing
- `PUT /transcripts/:id` - Update transcript text
- `DELETE /transcripts/:id` - Delete transcript
- `GET /transcripts/user/:userId` - Get user transcription history

**Prompt Management**
- `GET /prompts/user/:userId` - Get user prompts
- `POST /prompts` - Create new prompt
- `PUT /prompts/:id` - Update prompt
- `DELETE /prompts/:id` - Delete prompt

### App Groups Configuration
Required for sharing data between main app and keyboard extension:
```
Group ID: group.com.yourcompany.speechkeyboard
```

### Firebase Configuration
1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create new project
   - Enable Authentication and Firestore

2. **Configure Authentication**
   - Enable Sign in with Apple provider
   - Add your app's bundle ID
   - Configure Apple Developer Console

3. **Download Configuration**
   - Download `GoogleService-Info.plist`
   - Add to Xcode project (both targets)

## 📖 Usage

### Setting Up the Keyboard
1. **Install the app** from the App Store or build from source
2. **Open iOS Settings** → General → Keyboard → Keyboards
3. **Add New Keyboard** → Select "Speech Keyboard"
4. **Allow Full Access** - Required for audio recording and API communication
5. **Grant permissions** - Microphone access for recording

### Recording and Transcription
1. **Open any app** with text input (Messages, Notes, etc.)
2. **Switch to Speech Keyboard** - Tap the globe icon
3. **Select a prompt** - Choose from your custom prompts or use default
4. **Start recording** - Tap the microphone button
5. **Speak clearly** - Audio is processed in real-time
6. **Review and edit** - Text appears with edit options
7. **Insert text** - Tap to insert into the active text field

### Managing Prompts
1. **Open main app** → Navigate to Prompts tab
2. **Create prompt** - Tap "+" to add new prompt
3. **Edit existing** - Tap on any prompt to modify
4. **Set as default** - Mark frequently used prompts
5. **Organize** - Delete unused prompts

### Viewing History
1. **Open main app** → Navigate to History tab
2. **View transcriptions** - See all past recordings
3. **Edit text** - Tap "Edit" to modify transcriptions
4. **Delete entries** - Tap "Delete" with confirmation
5. **Search and filter** - Find specific transcriptions

## 🏗️ Project Structure

```
Frontend_Speech_Keyboard/
├── SpeechKeyboard/                 # Main iOS App Target
│   ├── App/
│   │   ├── SpeechKeyboardApp.swift # App entry point
│   │   └── ContentView.swift       # Main app interface
│   ├── Views/                      # SwiftUI Views
│   │   ├── TranscriptionHistoryView.swift
│   │   ├── AddPromptView.swift
│   │   └── TranscriptionResultCard.swift
│   ├── ViewModels/                # MVVM ViewModels
│   │   ├── TranscriptionViewModel.swift
│   │   └── PromptViewModel.swift
│   ├── Models/                    # Data models
│   ├── Services/                 # Business logic & API clients
│   │   ├── TranscriptionService.swift
│   │   ├── PromptService.swift
│   │   ├── APIConfig.swift
│   │   ├── APIModels.swift
│   │   └── RecordingManager.swift
│   └── Resources/                # Assets, localizations
│
├── KeyboardExtension/             # Custom Keyboard Extension Target
│   ├── KeyboardViewController.swift # Main keyboard controller
│   ├── Views/                    # Keyboard UI components
│   └── Services/                 # Keyboard-specific services
│
├── Shared/                       # Shared code between targets
│   ├── Models/                   # Common data models
│   ├── Services/                 # Shared services
│   └── Constants.swift           # Shared constants
│
├── Tests/                        # Unit tests
└── UITests/                      # UI automation tests
```

## 🧪 Testing

### Running Tests
```bash
# Run all unit tests
xcodebuild test -scheme SpeechKeyboard -destination 'platform=iOS Simulator,name=iPhone 14'

# Run specific test bundle
xcodebuild test -scheme SpeechKeyboard -only-testing:SpeechKeyboardTests

# Generate code coverage
xcodebuild test -scheme SpeechKeyboard -enableCodeCoverage YES
```

### Test Coverage
- **Unit Tests**: ViewModel logic, service methods, data models
- **Integration Tests**: API communication, data persistence
- **UI Tests**: User workflows, keyboard extension behavior
- **Mock Services**: Stubbed network responses for reliable testing

## 🚀 Deployment

### App Store Deployment
1. **Archive the app** in Xcode
2. **Validate** - Check for issues and warnings
3. **Upload to App Store Connect**
4. **Configure metadata** - Screenshots, description, keywords
5. **Submit for review** - Apple's review process

### TestFlight Beta Testing
1. **Upload build** to App Store Connect
2. **Enable TestFlight** - Configure beta testing
3. **Invite testers** - Internal and external testing
4. **Collect feedback** - Iterate based on user feedback

### Enterprise Distribution
1. **Configure enterprise certificates**
2. **Build with enterprise profile**
3. **Distribute internally** - Through MDM or direct download

## 🛡️ Security

### Privacy & Security Features
- **Local audio processing** - Audio stays on device during recording
- **Secure transmission** - HTTPS for all API communications
- **User data encryption** - Sensitive data encrypted at rest
- **Permission-based access** - Granular iOS permissions
- **No audio storage** - Temporary audio files deleted after processing

### Data Protection
- **App Groups isolation** - Secure data sharing between app and extension
- **Keychain storage** - Secure storage for sensitive credentials
- **Network security** - Certificate pinning and secure protocols
- **User consent** - Clear permission requests and data usage

## 🔍 API Integration

### Authentication Headers
```swift
// Default headers for API requests
static var defaultHeaders: [String: String] {
    return [
        "Accept": "application/json",
        "User-Agent": "SpeechKeyboard-iOS/1.0"
    ]
}
```

### Audio Upload Format
```swift
// Multipart form data structure
- Field: "audio" (audio file as .m4a)
- Field: "user_id" (string)
- Field: "prompt" (optional string)
```

### Response Format
```json
{
  "success": true,
  "data": {
    "transcriptId": 123,
    "rawTranscript": "original speech text",
    "finalText": "cleaned and formatted text",
    "duration": 3.2,
    "promptUsed": "grammar correction prompt"
  }
}
```

## 🤝 Contributing

### Development Setup
1. **Fork the repository**
2. **Create feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Follow coding standards**
   - SwiftLint configuration
   - MVVM architecture patterns
   - Comprehensive documentation

4. **Add tests**
   - Unit tests for new functionality
   - UI tests for user workflows
   - Mock external dependencies

5. **Submit pull request**
   - Clear description of changes
   - Test coverage report
   - Screenshots for UI changes

### Code Style Guidelines
- **Swift naming conventions** - Follow Apple's Swift API guidelines
- **MVVM architecture** - Separate concerns between Views, ViewModels, and Models
- **Dependency injection** - Use protocols and inject dependencies for testability
- **Error handling** - Comprehensive error handling with user-friendly messages
- **Documentation** - Inline documentation for public APIs

## 📱 Requirements

### Device Requirements
- **iOS 15.0 or later**
- **iPhone or iPad** - Universal app support
- **Microphone access** - Required for voice recording
- **Internet connection** - For transcription API calls
- **Storage space** - Minimal, temporary audio files only

### Permissions Required
- **Microphone** - Audio recording for transcription
- **Network** - API communication
- **Full Keyboard Access** - Required for keyboard extension functionality

## 🛠️ Troubleshooting

### Common Issues

**Keyboard not appearing**
- Check iOS Settings → Keyboards → Speech Keyboard is enabled
- Verify Full Access is granted
- Restart the app and try again

**Transcription not working**
- Verify microphone permissions are granted
- Check internet connection
- Ensure backend API is accessible

**Prompts not syncing**
- Check user authentication status
- Verify Firebase configuration
- Check network connectivity

### Support
For technical support and bug reports:
- Create an issue in the repository
- Provide device information and iOS version
- Include steps to reproduce the problem
- Attach relevant logs or screenshots

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple** - For iOS SDK and development tools
- **Firebase** - For authentication and cloud services
- **SwiftUI** - For modern iOS user interface development
- **AVFoundation** - For audio recording and processing capabilities
- **Open source community** - For inspiration and code examples

---

**Built with ❤️ for seamless speech-to-text experiences on iOS**

*Turn your voice into text, anywhere on your iPhone or iPad*
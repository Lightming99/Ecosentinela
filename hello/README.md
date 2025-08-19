# 🌱 EcoBot - Eco-Friendly AI Assistant

A comprehensive Flutter application that serves as an intelligent eco-friendly assistant, combining multiple AI services to provide enhanced environmental guidance and support.

## 📱 Project Overview

EcoBot is a cross-platform Flutter application designed to help users make eco-friendly decisions through intelligent conversations. The app integrates with multiple AI services including Rasa chatbot, Google Gemini AI, and a Flask feedback API to provide comprehensive environmental assistance.

### ✨ Key Features

- 🤖 **Dual AI Integration**: Rasa chatbot + Google Gemini AI enhancement
- 🌟 **Star-based Feedback System**: Rate responses and provide detailed feedback
- 📊 **Live Analytics**: Real-time chat statistics and performance metrics
- 🎨 **Beautiful UI**: Modern Material Design 3 with animations
- 💾 **Local Storage**: Persistent chat history and user preferences
- 🔗 **API Testing**: Built-in connection testing for all services
- 📱 **Cross-platform**: Works on Android, iOS, Windows, Linux, macOS, and Web

## 🏗️ Architecture

This project follows a clean, feature-based architecture with separation of concerns:

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart              # Material Design 3 theme
│   │   └── app_colors.dart             # Color palette
│   ├── services/
│   │   ├── api_service.dart            # Multi-AI integration service
│   │   └── storage_service.dart        # Hive local storage
│   ├── models/
│   │   ├── chat_message.dart           # Chat message data model
│   │   └── message_metadata.dart       # Message metadata model
│   └── providers/
│       ├── chat_provider.dart          # Chat state management
│       ├── settings_provider.dart      # App settings
│       └── analytics_provider.dart     # Analytics tracking
├── features/
│   ├── chat/
│   │   ├── chat_screen.dart            # Main chat interface
│   │   ├── widgets/
│   │   │   ├── chat_message.dart       # Individual message widget
│   │   │   ├── chat_input.dart         # Message input field
│   │   │   ├── typing_indicator.dart   # Bot typing animation
│   │   │   └── enhanced_feedback_dialog.dart # Star rating dialog
│   │   └── providers/
│   │       └── chat_state_provider.dart # Chat-specific state
│   ├── profile/
│   │   ├── profile_screen.dart         # User profile screen
│   │   └── widgets/
│   │       ├── profile_header.dart     # User info section
│   │       ├── settings_section.dart   # App settings
│   │       ├── analytics_section.dart  # Live analytics
│   │       ├── history_section.dart    # Chat history
│   │       ├── connection_test_section.dart # API testing
│   │       └── rasa_test_widget.dart   # Rasa response testing
│   └── splash/
│       └── splash_screen.dart          # App startup screen
└── main.dart                           # Application entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.32.8 or later)
- Dart SDK
- Android Studio / VS Code
- **Backend Services**:
  - Rasa server running on `localhost:5005`
  - Flask feedback API on `localhost:8000`
  - Google Gemini API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hello
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   - Update `lib/core/services/api_service.dart` with your Google Gemini API key
   - Ensure Rasa server is running on `localhost:5005`
   - Ensure Flask feedback API is running on `localhost:8000`

4. **Run the application**
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9           # State management
  hive_flutter: ^1.1.0               # Local database
  http: ^1.1.2                       # API requests
  google_generative_ai: ^0.2.3       # Gemini AI integration
  
  # UI & Animations
  flutter_staggered_animations: ^1.1.1
  lottie: ^3.0.0
  flutter_animate: ^4.5.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.5.4
  hive_generator: ^2.0.1
  json_annotation: ^4.8.1
```

## 🌟 Features Deep Dive

### 🤖 AI Integration System

**Multi-Response Handling**
```dart
// Enhanced Rasa integration with response merging
static Future<Map<String, dynamic>> sendToRasa(String message) async {
  // Merges multiple Rasa responses into comprehensive output
  // Calculates average confidence across responses
  // Preserves ALL information (no data loss)
}
```

**Gemini AI Enhancement**
```dart
// Enhances Rasa responses with Gemini AI
static Future<Map<String, dynamic>> enhanceWithGemini(
  String userQuery, 
  String rasaResponse,
  bool isEnhancementEnabled,
) async {
  // Improves grammar, clarity, and adds eco-friendly context
  // Preserves all factual information
  // Formats for mobile readability
}
```

### 🌟 Advanced Feedback System

**Star-based Rating**
- 5-star rating system with automatic positive/negative classification
- Detailed category selection (Accuracy, Helpfulness, Relevance, etc.)
- Two-page feedback dialog for comprehensive input
- Flask API integration with proper schema matching

**Feedback Data Structure**
```dart
{
  'user_query': String,
  'bot_response': String, 
  'feedback_type': 'positive'|'negative',
  'user_comment': String,
  'rating_stars': int (1-5),
  'categories': List<String>,
  'timestamp': String,
  'message_id': String
}
```

### 📊 Live Analytics Dashboard

**Real-time Metrics**
- Total messages exchanged
- Average response confidence
- Enhancement usage statistics
- Response time tracking
- User satisfaction ratings

**Analytics Features**
- Automatic metric updates
- Historical data visualization
- Performance insights
- Usage pattern analysis

### 💾 Data Persistence

**Hive Database Integration**
```dart
// Type-safe storage operations
class StorageService {
  static Future<void> saveMessage(Map<String, dynamic> message);
  static Future<List<Map<String, dynamic>>> getMessages();
  static Future<void> clearHistory();
  static Future<void> updateSettings(Map<String, dynamic> settings);
}
```

## 🛠️ API Services

### Backend Requirements

1. **Rasa Server** (`localhost:5005`)
   ```bash
   # Example Rasa endpoint
   POST /webhooks/rest/webhook
   GET /version
   ```

2. **Flask Feedback API** (`localhost:8000`)
   ```bash
   # Feedback submission
   POST /api/feedback
   
   # Health check
   GET /api/health
   ```

3. **Google Gemini AI**
   - API Key required in `api_service.dart`
   - Model: `gemini-1.5-flash`

### API Service Features

**Connection Testing**
```dart
static Future<Map<String, bool>> testConnections() async {
  // Tests all three services
  // Returns connection status for each
  // Automatic timeout handling
}
```

**Error Handling**
- Comprehensive error catching
- Fallback responses
- Connection timeout management
- User-friendly error messages

## 🎨 UI/UX Features

### Design System
- **Material Design 3** components
- **Dynamic theming** with custom color palette
- **Responsive layouts** for all screen sizes
- **Smooth animations** using Staggered Animations
- **Loading states** and progress indicators

### Key UI Components

**Chat Interface**
- Bubble-style message layout
- Typing indicators
- Message timestamps
- Confidence score display
- Star rating buttons

**Profile Dashboard**
- User statistics cards
- Settings toggles
- Connection status indicators
- Analytics charts
- History management

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Windows** (Windows 10+)
- ✅ **Linux** (GTK 3.0+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Web** (Chrome, Firefox, Safari, Edge)

## 🧪 Testing & Debugging

### Built-in Testing Tools

**Rasa Test Widget**
- Compare raw vs enhanced responses
- Response count tracking
- Side-by-side comparison
- Debug multi-response scenarios

**Connection Testing**
- Real-time API status monitoring
- Individual service testing
- Connection diagnostics
- Error logging

### Development Commands

```bash
# Run with hot reload
flutter run --hot

# Clean build
flutter clean && flutter pub get

# Run tests
flutter test

# Build for production
flutter build apk          # Android
flutter build web          # Web
flutter build windows      # Windows
```

## 🔧 Configuration

### Environment Setup

1. **Google Gemini API**
   ```dart
   // lib/core/services/api_service.dart
   static const String _geminiApiKey = 'your-api-key-here';
   ```

2. **Backend URLs**
   ```dart
   // lib/core/services/api_service.dart
   static const String _rasaUrl = 'http://localhost:5005';
   static const String _feedbackUrl = 'http://localhost:8000';
   ```

### App Settings
- AI Enhancement toggle
- Theme selection (auto/light/dark)
- Chat history management
- Notification preferences

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Flutter/Dart conventions
- Use meaningful variable names
- Add comments for complex logic
- Maintain consistent formatting

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Riverpod** for excellent state management
- **Google Gemini AI** for enhanced responses  
- **Rasa** for conversational AI capabilities
- **Material Design** for beautiful UI components

## 📞 Support

For support and questions:
- Open an issue on GitHub
- Check the Flutter documentation
- Review the Riverpod documentation

## 🚀 Future Enhancements

- [ ] Voice input/output support
- [ ] Multi-language support
- [ ] Cloud synchronization
- [ ] Advanced analytics dashboard
- [ ] Plugin system for custom eco-tips
- [ ] Integration with more AI services

---

Built with ❤️ and 🌱 for a sustainable future!
